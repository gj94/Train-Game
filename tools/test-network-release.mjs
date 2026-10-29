import assert from 'node:assert/strict';
import {readFile} from 'node:fs/promises';
import {loadNetworkPopulation} from './lib/network-population.mjs';
import {assertReleaseReport,assertInstalledRelease} from './lib/network-release.mjs';
const folder='data/timetables/network_v2',population=await loadNetworkPopulation();
const normal=JSON.parse(await readFile(folder+'/audit.json')),delayed=JSON.parse(await readFile(folder+'/disturbed-audit.json'));
assertReleaseReport(normal,population,0);assertReleaseReport(delayed,population,600);
await assertInstalledRelease(folder,normal,population);
const edits=[
 r=>r.audit.events.push({kind:'collision'}),r=>r.audit.finished--,
 r=>r.services.K1.stabled=false,r=>r.services.K1.actual_arrivals[2]=-1,
 r=>r.services.K1.actual_departures[2]=-1,r=>r.services.K1.terminal_kind='boundary_exit',
 r=>delete r.services.K1,r=>r.audit.pack_sha256='stale',
 r=>r.audit.wait_quality.cumulative[2].met=true,r=>r.station_waits[0].seconds++,
 r=>r.audit.ok=true,r=>r.audit.delay=600,
];
for(const edit of edits){const report=structuredClone(normal);edit(report);assert.throws(()=>assertReleaseReport(report,population,0));}
assert.throws(()=>assertReleaseReport({...delayed,audit:{...delayed.audit,delay_at:1}},population,600));
console.log('Network release: both actual reports and installed certificate pass; 13 invalid safety/completion/identity/accounting/disturbance fixtures rejected. Wait failures remain recorded.');
