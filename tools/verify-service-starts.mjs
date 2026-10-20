import {assertWaitQuality} from './lib/wait-quality.mjs';
// Release gate: stale or incomplete prepared railways must never be exported.
import {readFile, readdir} from 'node:fs/promises';
import {createHash} from 'node:crypto';
import {fileURLToPath} from 'node:url';
import {join} from 'node:path';
import assert from 'node:assert/strict';
const root=fileURLToPath(new URL('../',import.meta.url));
const folder=join(root,'data/service_starts');
const data=JSON.parse(await readFile(join(folder,'catalogue.json'),'utf8'));
assert.equal(data.version,1);assert.equal(data.complete,true);assert.equal(data.audit.ok,true);
assert.equal(data.services.length,100);assert.equal(data.audit.finished,100);
assert.equal(data.audit.events.length,0);const fullAudit=JSON.parse(await readFile(join(folder,'audit.json'),'utf8'));assertWaitQuality(fullAudit);assert.deepEqual(data.audit,fullAudit.audit);
const sha=b=>createHash('sha256').update(b).digest('hex');
const found=[];
async function walk(relative){
  for(const entry of await readdir(join(root,relative),{withFileTypes:true})){
    const path=relative+'/'+entry.name;
    if(entry.isDirectory())await walk(path);
    else if(/\.(gd|json|bin|csv)$/.test(entry.name)){
      found.push(path);
      const bytes=await readFile(join(root,path));
      assert.equal(sha(path.endsWith('.bin')?bytes:bytes.toString('utf8').replaceAll('\r\n','\n')),data.sources[path],`Railway changed: ${path}. Regenerate starts.`);
    }
  }
}
await walk('sim');await walk('data/routes/kerala_coast');assert.equal(found.length,Object.keys(data.sources).length);
const ids=new Set();
for(const row of data.services){
  assert.match(row.id,/^[A-Za-z0-9_]+$/);assert.equal(row.file,row.id+'.bin');assert.ok(!ids.has(row.id));ids.add(row.id);
  assert.equal(row.calls.length,row.stops);assert.ok(row.calls.length>=2);
  assert.ok(Number.isFinite(row.distance_m)&&row.distance_m>0);
  assert.ok(Number.isFinite(row.average_kmh)&&row.average_kmh>0);
  assert.ok(Math.abs(row.average_kmh-row.distance_m/row.duration*3.6)<1e-8);
  assert.equal(row.calls[0].departure,row.departure);
  assert.equal(row.calls.at(-1).arrival-row.departure,row.duration);
  assert.equal(sha(await readFile(join(folder,row.file))),row.sha256,`Changed checkpoint ${row.id}`);
}
console.log(`Prepared starts verified: ${ids.size} services; ${found.length} railway inputs; full-day audit passed.`);
