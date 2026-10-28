import assert from 'node:assert/strict';
import {readFile} from 'node:fs/promises';
import {loadNetworkPopulation,validateNetworkSelection,assertSelectedNetworkReport} from '../../tools/lib/network-population.mjs';
const pack=JSON.parse(await readFile('art/timetables/kerala-coast-network-v2.json'));
const selection=JSON.parse(await readFile('art/timetables/kerala-coast-network-service-selection.json'));
const population=await loadNetworkPopulation();let positive=0,negative=0;
assert.equal(population.count,193);positive++;
const report={audit:{dispatcher:'predictive',operating_day:'network',total:193,finished:193,pack_sha256:population.pack_sha256},services:Object.fromEntries(population.ids.map(id=>[id,{}]))};
assertSelectedNetworkReport(report,population);positive++;
for(const mutate of [r=>r.audit.finished=192,r=>r.audit.total=192,r=>r.audit.total=208,r=>{r.audit.total=196;r.audit.finished=196},r=>{r.audit.total=200;r.audit.finished=200},r=>r.audit.dispatcher='classic',r=>r.audit.operating_day='standard',r=>r.audit.pack_sha256='stale',r=>delete r.services.K1,r=>{delete r.services.M001;r.services.M021={};}]){
 const bad=structuredClone(report);mutate(bad);assert.throws(()=>assertSelectedNetworkReport(bad,population));negative++;
}
for(const mutate of [p=>p.services.find(s=>s.id==='M001').id='M999',p=>p.services.find(s=>s.id==='M001').id='M043',p=>p.services.find(s=>s.id==='M001').id='M089',p=>p.services.find(s=>s.id==='M001').id='M099',p=>p.services.find(s=>s.id==='M001').id='M032',p=>p.services.pop(),p=>p.services[1].id=p.services[0].id,p=>p.services.find(s=>s.id==='K1').departure='06:05',p=>p.dispatcher='classic',p=>p.services.find(s=>s.journey.category==='mail').journey.category='local']){
 const bad=structuredClone(pack);mutate(bad);assert.throws(()=>validateNetworkSelection(bad,selection));negative++;
}
for(const mutate of [s=>s.selected_count=200,s=>s.selected_count=196,s=>s.selected_count=192,s=>s.source_count=200,s=>s.excluded.pop(),s=>s.excluded[0].service='K1']){
 const bad=structuredClone(selection);mutate(bad);assert.throws(()=>validateNetworkSelection(pack,bad));negative++;
}
console.log(JSON.stringify({population_contract_positive:positive,population_contract_negative:negative,note:'Synthetic population guards only; not a completed simulation or acceptance certificate.'}));
