// Validate one complete serial rehearsal and derive reciprocal traffic previews.
// Publication into data/ happens only after every quality gate succeeds.
import {readFile, writeFile, mkdir, copyFile, readdir} from 'node:fs/promises';
import {createReadStream} from 'node:fs';
import {createInterface} from 'node:readline';
import {createHash} from 'node:crypto';
import assert from 'node:assert/strict';
import {join} from 'node:path';
import {TrafficEncounters, locationAt} from './lib/traffic-encounters.mjs';
const folder=process.argv[2]??'.local/intensive-v2';
const standard=process.argv.includes('--standard');
const destination=process.argv[3]?.startsWith('--')?undefined:process.argv[3];
const expected=standard?100:140;
const sha=b=>createHash('sha256').update(b).digest('hex');
const audit=JSON.parse(await readFile(folder+'/audit.json','utf8'));
assert.ok(audit.audit.ok);assert.equal(audit.audit.finished,expected);
assert.equal(audit.audit.operating_day,standard?'standard':'intensive');
assert.equal(audit.audit.events.length,0);assert.ok(audit.audit.maximum_wait<=1800);
assert.equal(Object.keys(audit.services).length,expected);
for(const [id,service] of Object.entries(audit.services)){
  assert.equal(service.stabled,true,`${id} has not cleared its working`);
  assert.equal(service.actual_arrivals.length,service.booked_stops.length);
  assert.equal(service.actual_departures.length,service.booked_stops.length);
  assert.ok(service.actual_arrivals.slice(1).every(t=>Number.isFinite(t)&&t>=0),`${id} missed a call`);
  assert.ok(service.actual_departures.slice(0,-1).every(t=>Number.isFinite(t)&&t>=0),`${id} has an uncompleted call`);
}
const detector=new TrafficEncounters();let samples=0,first;
for await(const line of createInterface({input:createReadStream(folder+'/traffic.jsonl'),crlfDelay:Infinity})){
  if(!line)continue;
  const frame=JSON.parse(line);first??=frame[0];detector.sample(frame);samples++;
}
const events=detector.events.sort((a,b)=>a.time-b.time||a.a.localeCompare(b.a)||a.b.localeCompare(b.b))
  .map(e=>({...e,...locationAt(e.chainage_m,audit.stations)}));
const overtakers=[...new Set(events.filter(e=>e.kind==='overtake'&&[e.a,e.b].includes('K1')&&e.overtaker!=='K1').map(e=>e.overtaker))];
const reverse=events.filter(e=>e.kind==='overtake'&&[e.a,e.b].includes('B042')&&[e.a,e.b].includes('B002')&&e.overtaker==='B042');
console.log(JSON.stringify({clock:detector.clock,services:audit.audit.finished,overtakers,
  crossings:events.filter(e=>e.kind==='crossing').length,overtakes:events.filter(e=>e.kind==='overtake').length,
  b042_reverse_overtakes:reverse,max_wait:audit.audit.maximum_wait},null,2));
if(!standard){
  assert.ok(overtakers.length>=10,'K1 requires at least ten DISTINCT overtaking trains');
  assert.equal(reverse.length,0,'B042 must not be sent back ahead of B002 in this baseline');
}
if(!destination)process.exit();
assert.equal(audit.audit.delay,0,'Never publish a delayed audit as the baseline');
const startBytes=await readFile(folder+'/starts/catalogue.json');
const timeBytes=await readFile(folder+'/times/catalogue.json');
const starts=JSON.parse(startBytes),times=JSON.parse(timeBytes);
assert.ok(starts.complete&&times.complete&&starts.audit.ok&&times.audit.ok);
assert.equal(starts.services.length,expected);
assert.equal(times.departure_catalogue_sha256,sha(startBytes));
assert.equal(times.states[0].clock,Math.round(first));
assert.equal(times.states.at(-1).clock,Math.round(detector.clock));
assert.equal(samples,Math.round((detector.clock-first)/2)+1);
for(const [path,digest]of Object.entries(starts.sources)){
  const bytes=await readFile(path);
  assert.equal(sha(path.endsWith('.bin')?bytes:bytes.toString('utf8').replaceAll('\r\n','\n')),digest,'Changed railway input '+path);
}
for(const [sub,rows]of [['starts',starts.services],['times',times.states]]){
  const seen=new Set();
  for(const row of rows){
    assert.equal(row.file,row.id+'.bin');assert.ok(!seen.has(row.id));seen.add(row.id);
    assert.equal(sha(await readFile(join(folder,sub,row.file))),row.sha256);
  }
}
const observer_sources={};
for(const path of ['tools/prepare_timetable_variant.gd','tools/record_service_traffic.gd','tools/lib/traffic-encounters.mjs','tools/finalize_timetable_variant.mjs']){
  observer_sources[path]=sha((await readFile(path,'utf8')).replaceAll('\r\n','\n'));
}
const traffic={version:1,complete:true,preparation:'serial-operating-day',engine:starts.engine,start_sha256:sha(startBytes),timeline_sha256:sha(timeBytes),
  observer_sources,services:starts.services.map(s=>s.id),events,
  audit:{ok:true,sample_seconds:2,samples,safety_events:[],distinct_k1_overtakers:overtakers,
    partitions:[{first,last:detector.clock,steps:samples-1,boundary_error_m:0}],
    crossing_count:events.filter(e=>e.kind==='crossing').length,overtake_count:events.filter(e=>e.kind==='overtake').length}};
await writeFile(folder+'/starts/traffic.json',JSON.stringify(traffic,null,2)+'\n');
for(const sub of ['starts','times']){
  const target=join(destination,standard?(sub==='starts'?'service_starts':'railway_times'):sub);
  await mkdir(target,{recursive:true});
  // Copy only the validated inventory, never leftovers from an earlier attempt.
  const rows=sub==='starts'?starts.services:times.states;
  const files=['catalogue.json',...rows.map(r=>r.file),...(sub==='starts'?['traffic.json']:[])];
  for(const file of files)await copyFile(join(folder,sub,file),join(target,file));
}
await copyFile(folder+'/audit.json',join(destination,standard?'service_starts/audit.json':'audit.json'));
console.log('Prepared variant copied to '+destination);
