// Network-only population contract. Never infer the target from a partial audit.
import assert from 'node:assert/strict';
import {readFile} from 'node:fs/promises';
import {createHash} from 'node:crypto';
export const NETWORK_PACK='art/timetables/kerala-coast-network-v2.json';
export const NETWORK_SELECTION='art/timetables/kerala-coast-network-service-selection.json';
export const NETWORK_OBSERVERS=['tools/finalize_network_timetable.mjs','tools/lib/network-population.mjs',NETWORK_SELECTION];
export function validateNetworkSelection(pack,selection){
  assert.equal(selection.format,'train-game-network-service-selection');assert.equal(selection.version,1);
  assert.equal(selection.source_count,208);assert.equal(selection.selected_count,184);
  const removed=selection.excluded.map(e=>e.service);
  assert.deepEqual([...removed].sort(),['M003','M021','M025','M029','M031','M032','M043','M052','M055','M056','M057','M058','M062','M066','M067','M069','M087','M089','M090','M098','M099','S021','S041','S055']);
  assert.equal(pack.dispatcher,'predictive');assert.equal(pack.services.length,184);
  const ids=pack.services.map(s=>s.id).sort();assert.equal(new Set(ids).size,184);
  const rawIds=['K1',...Array.from({length:39},(_,i)=>'L'+String(i+2).padStart(3,'0')),...Array.from({length:104},(_,i)=>'M'+String(i+1).padStart(3,'0')),...Array.from({length:56},(_,i)=>'S'+String(i+1).padStart(3,'0')),...Array.from({length:8},(_,i)=>'V'+String(i+1).padStart(3,'0'))];
  assert.deepEqual(ids,rawIds.filter(id=>!removed.includes(id)).sort(),'Wrong exact selected Network IDs');
  assert.ok(removed.every(id=>!ids.includes(id)));assert.equal(pack.services.find(s=>s.id==='K1')?.departure,'06:00');
  const categories={};for(const s of pack.services)categories[s.journey.category]=(categories[s.journey.category]??0)+1;
  assert.deepEqual(categories,{local:40,mail:83,superfast:53,vb:8});
  assert.equal(pack.services.filter(s=>s.stops.some(c=>c.boundary)).length,144);
  return {count:184,ids};
}
export async function loadNetworkPopulation(){
  const bytes=await readFile(NETWORK_PACK),pack=JSON.parse(bytes),selection=JSON.parse(await readFile(NETWORK_SELECTION));
  return {...validateNetworkSelection(pack,selection),pack_sha256:createHash('sha256').update(bytes).digest('hex')};
}
export function assertSelectedNetworkReport(report,population){
  assert.equal(report.audit.dispatcher,'predictive');assert.equal(report.audit.operating_day,'network');
  assert.equal(report.audit.total,population.count);assert.equal(report.audit.finished,population.count);
  assert.equal(report.audit.pack_sha256,population.pack_sha256,'Wrong selected Network pack');
  assert.deepEqual(Object.keys(report.services).sort(),population.ids,'Incomplete or substituted Network population');
}
