import {assertWaitQuality} from './lib/wait-quality.mjs';
import {readFile,readdir} from 'node:fs/promises';
import {createHash} from 'node:crypto';
import assert from 'node:assert/strict';
const sha=b=>createHash('sha256').update(b).digest('hex');
const folder='data/timetables/intensive';
const bytes=await readFile(folder+'/starts/catalogue.json');
const timeBytes=await readFile(folder+'/times/catalogue.json');
const starts=JSON.parse(bytes),times=JSON.parse(timeBytes);
const traffic=JSON.parse(await readFile(folder+'/starts/traffic.json'));
assert.ok(starts.complete&&starts.audit.ok&&times.complete&&times.audit.ok&&traffic.complete&&traffic.audit.ok);
assert.equal(starts.services.length,140);assert.equal(starts.audit.finished,140);
assert.deepEqual(starts.audit.events,[]);const fullAudit=JSON.parse(await readFile(folder+'/audit.json','utf8'));assertWaitQuality(fullAudit);assert.deepEqual(starts.audit,fullAudit.audit);
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
found.push('art/timetables/kerala-coast-intensive.json');
assert.deepEqual(found.sort(),Object.keys(starts.sources).sort());
for(const [path,digest]of Object.entries(starts.sources)){
  const value=await readFile(path);
  assert.equal(sha(path.endsWith('.bin')?value:value.toString('utf8').replaceAll('\r\n','\n')),digest,'Stale alternate day: '+path);
}
const observers=['tools/prepare_timetable_variant.gd','tools/wait_quality.gd','tools/lib/wait-quality.mjs','tools/record_service_traffic.gd','tools/lib/traffic-encounters.mjs','tools/finalize_timetable_variant.mjs'];
assert.deepEqual(Object.keys(traffic.observer_sources).sort(),observers.sort());
for(const [path,digest]of Object.entries(traffic.observer_sources)){
  assert.equal(sha((await readFile(path,'utf8')).replaceAll('\r\n','\n')),digest,'Stale alternate preview: '+path);
}
let previous=-1;
assert.equal(times.states[0].clock,Math.ceil(Math.min(...starts.services.map(s=>s.start_clock))/300)*300);
assert.equal(times.states.at(-1).clock,Math.ceil(starts.audit.clock/300)*300);
assert.equal(traffic.audit.sample_seconds,2);
assert.equal(traffic.audit.samples,(times.states.at(-1).clock-times.states[0].clock)/2+1);
for(const row of times.states){
  assert.equal(row.clock%300,0);if(previous>=0)assert.equal(row.clock-previous,300);previous=row.clock;
}
const ids=starts.services.map(s=>s.id);
assert.equal(new Set(ids).size,140);
for(const row of starts.services){
  assert.equal(row.calls.length,row.stops);
  assert.equal(row.calls.at(-1).arrival-row.departure,row.duration);
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
    assert.ok(!([e.a,e.b].includes('B042')&&[e.a,e.b].includes('B002')&&e.overtaker==='B042'));
  }else assert.equal(e.kind,'crossing');
}
assert.ok(overtakers.size>=10);
assert.deepEqual([...overtakers].sort(),[...traffic.audit.distinct_k1_overtakers].sort());
assert.equal(traffic.audit.crossing_count,traffic.events.filter(e=>e.kind==='crossing').length);
assert.equal(traffic.audit.overtake_count,traffic.events.filter(e=>e.kind==='overtake').length);
for(const [sub,rows]of [['starts',starts.services],['times',times.states]]){
  for(const row of rows){
    assert.equal(row.file,row.id+'.bin');
    assert.equal(sha(await readFile(`${folder}/${sub}/${row.file}`)),row.sha256);
  }
}
console.log(`Intensive day verified: ${ids.length} services, ${times.states.length} time states, ${overtakers.size} distinct K1 overtakers.`);
