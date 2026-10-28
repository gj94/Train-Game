import {loadNetworkPopulation,assertSelectedNetworkReport,NETWORK_OBSERVERS} from './lib/network-population.mjs';
import {assertWaitQuality} from './lib/wait-quality.mjs';
import {ceilFiveMinute} from './lib/time-grid.mjs';
import {readFile,readdir} from 'node:fs/promises';
import {createHash} from 'node:crypto';
import assert from 'node:assert/strict';
const sha=b=>createHash('sha256').update(b).digest('hex');
const variants=[
  {id:'intensive',folder:'data/timetables/intensive',count:140,mode:'classic',pack:'art/timetables/kerala-coast-intensive.json'},
  {id:'standard_v2',folder:'data/timetables/standard_v2',count:100,mode:'predictive',pack:null},
  {id:'intensive_v2',folder:'data/timetables/intensive_v2',count:140,mode:'predictive',pack:'art/timetables/kerala-coast-intensive-v2.json'},
  {id:'network',folder:'data/timetables/network',count:208,mode:'classic',pack:'art/timetables/kerala-coast-network.json'},
  {id:'network_v2',folder:'data/timetables/network_v2',count:193,mode:'predictive',pack:'art/timetables/kerala-coast-network-v2.json'},
];
const requested=process.argv.find(a=>a.startsWith('--day='))?.slice(6);
if(requested)assert.ok(variants.some(v=>v.id===requested),'Unknown alternate operating day');
assert.notEqual(requested,'network','Classic Network readiness is outside the requested scope');
for(const variant of variants.filter(v=>v.id!=='network'&&(!requested||v.id===requested))){
const {folder,count,mode,pack}=variant;
const network=variant.id==='network_v2';
const population=network?await loadNetworkPopulation():null;
if(network)assert.equal(count,population.count);
const bytes=await readFile(folder+'/starts/catalogue.json');
const timeBytes=await readFile(folder+'/times/catalogue.json');
const starts=JSON.parse(bytes),times=JSON.parse(timeBytes);
const traffic=JSON.parse(await readFile(folder+'/starts/traffic.json'));
assert.ok(starts.complete&&starts.audit.ok&&times.complete&&times.audit.ok&&traffic.complete&&traffic.audit.ok);
assert.equal(starts.services.length,count);assert.equal(starts.audit.finished,count);
assert.deepEqual(starts.audit.events,[]);const fullAudit=JSON.parse(await readFile(folder+'/audit.json','utf8'));assertWaitQuality(fullAudit);if(network)assertSelectedNetworkReport(fullAudit,population);assert.deepEqual(starts.audit,fullAudit.audit);
assert.equal(starts.dispatcher??'classic',mode);assert.equal(times.dispatcher??'classic',mode);
assert.equal(starts.audit.dispatcher??'classic',mode);assert.equal(traffic.dispatcher??'classic',mode);
assert.equal(starts.audit.operating_day,network?'network':(count===100?'standard':'intensive'));assert.equal(starts.audit.delay,0);
assert.equal(traffic.start_sha256,sha(bytes));assert.equal(traffic.timeline_sha256,sha(timeBytes));
assert.equal(times.departure_catalogue_sha256,sha(bytes));
assert.deepEqual(times.sources,starts.sources);
assert.equal(times.layout_signature,starts.layout_signature);
assert.equal(times.audit.round_trips,times.states.length);
assert.deepEqual(times.audit.events,[]);
const found=[];
async function walk(folder){
  for(const e of await readdir(folder,{withFileTypes:true})){
    const path=folder+'/'+e.name;
    if(e.isDirectory())await walk(path);
    else if(/\.(gd|json|bin|csv)$/.test(path))found.push(path);
  }
}
await walk('sim');await walk('data/routes/kerala_coast');
if(pack)found.push(pack);
assert.deepEqual(found.sort(),Object.keys(starts.sources).sort());
for(const [path,digest]of Object.entries(starts.sources)){
  const value=await readFile(path);
  assert.equal(sha(path.endsWith('.bin')?value:value.toString('utf8').replaceAll('\r\n','\n')),digest,'Stale alternate day: '+path);
}
const observers=['tools/prepare_timetable_variant.gd','tools/wait_quality.gd','tools/lib/wait-quality.mjs','tools/record_service_traffic.gd','tools/lib/traffic-encounters.mjs','tools/finalize_timetable_variant.mjs',...(network?NETWORK_OBSERVERS:[])];
assert.deepEqual(Object.keys(traffic.observer_sources).sort(),observers.sort());
for(const [path,digest]of Object.entries(traffic.observer_sources)){
  assert.equal(sha((await readFile(path,'utf8')).replaceAll('\r\n','\n')),digest,'Stale alternate preview: '+path);
}
let previous=-1;
// The network day starts at midnight, before its first 00:05 departure.
// Its empty initial railway is a real checkpoint, not a missing service.
assert.equal(times.states[0].clock,network?0:ceilFiveMinute(Math.min(...starts.services.map(s=>s.start_clock))));
assert.equal(times.states.at(-1).clock,ceilFiveMinute(starts.audit.clock));
assert.equal(traffic.audit.sample_seconds,2);
assert.equal(traffic.audit.samples,(times.states.at(-1).clock-times.states[0].clock)/2+1);
for(const row of times.states){
  assert.equal(row.clock%300,0);if(previous>=0)assert.equal(row.clock-previous,300);previous=row.clock;
}
const ids=starts.services.map(s=>s.id);
assert.equal(new Set(ids).size,count);
if(network)assert.deepEqual([...ids].sort(),population.ids);
for(const row of starts.services){
  assert.equal(row.calls.length,row.stops);
  // JSON decimals can differ by a few ulps after subtracting clock times.
  assert.ok(Math.abs(row.calls.at(-1).arrival-row.departure-row.duration)<1e-6,'Scheduled duration differs for '+row.id);
  assert.ok(Math.abs(row.average_kmh-row.distance_m/row.duration*3.6)<1e-8);
}
assert.deepEqual([...traffic.services].sort(),[...ids].sort());
assert.deepEqual(traffic.audit.safety_events,[]);
const overtakers=new Set();let clock=-1;
for(const e of traffic.events){
  assert.ok(e.time>=clock&&e.time<=previous);clock=e.time;
  assert.ok(ids.includes(e.a)&&ids.includes(e.b)&&e.a!==e.b&&e.location);
  if(e.kind==='overtake'){
    assert.ok([e.a,e.b].includes(e.overtaker)&&e.cleared>=e.time);
    if([e.a,e.b].includes('K1')&&e.overtaker!=='K1')overtakers.add(e.overtaker);
    if(count===140)assert.ok(!([e.a,e.b].includes('B042')&&[e.a,e.b].includes('B002')&&e.overtaker==='B042'));
  }else assert.equal(e.kind,'crossing');
}
if(count===140)assert.ok(overtakers.size>=10);
if(network){
  const passes=traffic.events.filter(e=>e.kind==='overtake');
  assert.ok(passes.length>=2&&new Set(passes.map(e=>e.station||e.location)).size>=2);
  for(const service of Object.values(fullAudit.services))assert.equal(service.terminal_kind,service.booked_stops.at(-1).boundary==='exit'?'boundary_exit':'depot');
}
assert.deepEqual([...overtakers].sort(),[...traffic.audit.distinct_k1_overtakers].sort());
assert.equal(traffic.audit.crossing_count,traffic.events.filter(e=>e.kind==='crossing').length);
assert.equal(traffic.audit.overtake_count,traffic.events.filter(e=>e.kind==='overtake').length);
for(const [sub,rows]of [['starts',starts.services],['times',times.states]]){
  for(const row of rows){
    assert.equal(row.file,row.id+'.bin');
    assert.equal(sha(await readFile(`${folder}/${sub}/${row.file}`)),row.sha256);
  }
}
console.log(`${variant.id} (${mode}) verified: ${ids.length} services, ${times.states.length} time states, ${overtakers.size} distinct K1 overtakers.`);

}
