import {readFile} from 'node:fs/promises';
import {createHash} from 'node:crypto';
import assert from 'node:assert/strict';
import {ceilFiveMinute} from './lib/time-grid.mjs';
const root=new URL('../',import.meta.url);
const sha=b=>createHash('sha256').update(b).digest('hex');
const departure=await readFile(new URL('data/service_starts/catalogue.json',root));
const source=JSON.parse(departure);
const data=JSON.parse(await readFile(new URL('data/railway_times/catalogue.json',root)));
assert.equal(data.version,1);assert.equal(data.complete,true);assert.equal(data.audit.ok,true);
assert.equal(data.departure_catalogue_sha256,sha(departure));
assert.deepEqual(data.sources,source.sources);assert.equal(data.layout_signature,source.layout_signature);
assert.equal(data.audit.round_trips,data.states.length);assert.equal(data.audit.events.length,0);
assert.ok(data.states.length>100);const ids=new Set();let previous=null;
for(const row of data.states){
  assert.match(row.id,/^T[0-9]+$/);assert.equal(row.file,row.id+'.bin');assert.ok(!ids.has(row.id));ids.add(row.id);
  assert.ok(Number.isFinite(row.clock)&&row.clock>=0);assert.equal(row.clock%300,0);
  if(previous!==null)assert.equal(row.clock-previous,300);previous=row.clock;
  assert.equal(sha(await readFile(new URL('data/railway_times/'+row.file,root))),row.sha256,`Changed time state: ${row.id}`);
}
assert.equal(data.states[0].clock,ceilFiveMinute(Math.min(...source.services.map(r=>r.start_clock))));
assert.equal(data.states.at(-1).clock,ceilFiveMinute(source.audit.clock));
console.log(`Five-minute railway verified: ${data.states.length} exact restored states; full operating day; no safety events.`);
