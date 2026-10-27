import {loadNetworkPopulation,assertSelectedNetworkReport} from './lib/network-population.mjs';
// Independently validate a completed 600-second K1 disturbance audit.
// This exports evidence only; it must never install departure or time states.
import {readFile,writeFile,mkdir,readdir} from 'node:fs/promises';
import {createHash} from 'node:crypto';
import {createReadStream} from 'node:fs';
import {createInterface} from 'node:readline';
import {TrafficEncounters,locationAt} from './lib/traffic-encounters.mjs';
import {gzipSync,gunzipSync} from 'node:zlib';
import assert from 'node:assert/strict';
import {assertWaitQuality} from './lib/wait-quality.mjs';
const [folder,output,mode]=process.argv.slice(2);
const network=process.argv.includes('--network');
const population=network?await loadNetworkPopulation():null;
if(network)assert.equal(mode,'predictive','Network readiness is V2 only');
const count=network?population.count:140,day=network?'network':'intensive',delayAt=network?27000:11000;
assert.ok(folder&&output&&['classic','predictive'].includes(mode));
const bytes=await readFile(folder+'/audit.json'),report=JSON.parse(bytes),audit=report.audit;
if(network)assertSelectedNetworkReport(report,population);

assert.equal(audit.ok,true);assert.equal(audit.finished,count);assert.equal(audit.total,count);
assert.equal(audit.delay,600);assert.equal(audit.delay_at,delayAt);assert.equal(audit.delay_service,'K1');
assert.equal(audit.dispatcher,mode);assert.equal(audit.operating_day,day);assert.deepEqual(audit.events,[]);
assert.equal(Object.keys(report.services).length,count);
let arrivals=0,departures=0;
for(const [id,service]of Object.entries(report.services)){
 assert.equal(service.stabled,true,id+' not stabled');
 if(network)assert.equal(service.terminal_kind,service.booked_stops.at(-1).boundary==='exit'?'boundary_exit':'depot');
 const n=service.booked_stops.length;assert.ok(n>=2);
 assert.equal(service.actual_arrivals.length,n);assert.equal(service.actual_departures.length,n);
 for(let i=1;i<n;i++){assert.ok(Number.isFinite(service.actual_arrivals[i])&&service.actual_arrivals[i]>=0,id+' missed arrival');arrivals++;}
 for(let i=0;i<n-1;i++){assert.ok(Number.isFinite(service.actual_departures[i])&&service.actual_departures[i]>=0,id+' missed departure');departures++;}
 for(let i=0;i<n-1;i++)assert.ok(service.actual_arrivals[i+1]>=service.actual_departures[i],id+' reversed travel time');
 for(let i=1;i<n-1;i++)assert.ok(service.actual_departures[i]>=service.actual_arrivals[i],id+' reversed dwell');
}
const sha=b=>createHash('sha256').update(b).digest('hex');
for(const[path,digest]of Object.entries(report.sources)){
 const b=await readFile(path);assert.equal(sha(path.endsWith('.bin')?b:b.toString('utf8').replaceAll('\r\n','\n')),digest,'Changed source '+path);
}
// Recorded source fingerprints normalise CRLF; the pack identity is raw bytes
// (FileAccess.get_sha256 in prepare_timetable_variant.gd). Check both.
const pack=`art/timetables/kerala-coast-${day}${mode==='classic'?'':'-v2'}.json`;
assert.equal(audit.pack_sha256,sha(await readFile(pack)));
const inputs=[];
async function collect(folder){
 for(const entry of await readdir(folder,{withFileTypes:true})){
  const path=folder+'/'+entry.name;
  if(entry.isDirectory())await collect(path);
  else if(/\.(gd|json|bin|csv)$/.test(path))inputs.push(path);
 }
}
await collect('sim');await collect('data/routes/kerala_coast');inputs.push(pack);
assert.deepEqual(Object.keys(report.sources).sort(),inputs.sort(),'Incomplete railway fingerprint inventory');
const wait_quality=assertWaitQuality(report);
// Recompute encounter evidence from this run, never trust an unrelated summary.
const detector=new TrafficEncounters(),trafficHash=createHash('sha256');
const stream=createReadStream(folder+'/traffic.jsonl');stream.on('data',chunk=>trafficHash.update(chunk));
let first,samples=0;
for await(const line of createInterface({input:stream,crlfDelay:Infinity})){
 if(!line)continue;const frame=JSON.parse(line);first??=frame[0];detector.sample(frame);samples++;
}
assert.ok(Math.abs(detector.clock-audit.clock)<.001,'Traffic ends before audit');
assert.equal(samples,Math.round((detector.clock-first)/2)+1,'Traffic has missing samples');
if(network){
 const passes=detector.events.filter(e=>e.kind==='overtake').map(e=>({...e,...locationAt(e.chainage_m,report.stations)}));
 assert.ok(passes.length>=2&&new Set(passes.map(e=>e.station||e.location)).size>=2,'Network disturbance requires actual overtakes at multiple locations');
}
const events=detector.events.filter(e=>e.kind==='overtake'&&[e.a,e.b].includes('K1')&&e.overtaker!=='K1')
 .sort((a,b)=>a.time-b.time).map(e=>({...e,...locationAt(e.chainage_m,report.stations)}));
const by_station={};for(const e of events)(by_station[e.station||e.location]??=[]).push({train:e.overtaker,time:e.time});
const counts=Object.values(by_station).map(rows=>rows.length);
const encounters={distinct_k1_overtakers:[...new Set(events.map(e=>e.overtaker))],by_station,
 distribution:{stations:counts.length,passes:events.length,maximum_at_one_station:Math.max(0,...counts),
 concentration:events.length?counts.reduce((sum,n)=>sum+(n/events.length)**2,0):0}};
const summary={description:`${day} with 600-second manual K1 brake at simulation time ${delayAt}; validation only, never a prepared baseline`,dispatcher:mode,audit_sha256:sha(bytes),traffic_sha256:trafficHash.digest('hex'),traffic_samples:samples,input_sha256_count:Object.keys(report.sources).length,pack_sha256:audit.pack_sha256,finished:audit.finished,clock:audit.clock,delay:audit.delay,delay_at:audit.delay_at,events:audit.events,wait_quality,maximum_continuous_wait_seconds:audit.maximum_wait,k1_arrival_delay_seconds:report.services.K1.arrival_delay,distinct_k1_overtakers:encounters.distinct_k1_overtakers,by_station:encounters.by_station,distribution:encounters.distribution,all_calls_and_departures_verified:true,arrivals_checked:arrivals,departures_checked:departures,all_services_cleared:true,...(!network?{all_services_stabled:true}:{boundary_exits:Object.values(report.services).filter(s=>s.terminal_kind==='boundary_exit').length})};
const gzip=gzipSync(bytes,{level:9});assert.ok(gunzipSync(gzip).equals(bytes));
await mkdir(output,{recursive:true});
await writeFile(output+'/'+mode+'-delayed-audit.json.gz',gzip);
await writeFile(output+'/'+mode+'-pack.json.gz',gzipSync(await readFile(pack),{level:9}));
await writeFile(output+'/'+mode+'-delayed-summary.json',JSON.stringify(summary,null,2)+'\n');
console.log(JSON.stringify(summary,null,2));
