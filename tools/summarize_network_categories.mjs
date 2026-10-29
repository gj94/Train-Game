import {loadNetworkPopulation} from './lib/network-population.mjs';
import {assertInstalledRelease} from './lib/network-release.mjs';
// Read-only, completed-baseline analysis. Compare like-for-like corridor rides,
// not a short local's end-to-end duration with a through express's longer trip.
import assert from 'node:assert/strict';
import {readFile, writeFile} from 'node:fs/promises';
import {createReadStream} from 'node:fs';
import {createInterface} from 'node:readline';
import {createHash} from 'node:crypto';
import {TrafficEncounters, locationAt} from './lib/traffic-encounters.mjs';

const [folder, output] = process.argv.slice(2);
assert.ok(folder && output, 'Usage: node tools/summarize_network_categories.mjs REPLAY OUTPUT.json');
const sha = bytes => createHash('sha256').update(bytes).digest('hex');
const auditBytes = await readFile(folder + '/audit.json');
const report = JSON.parse(auditBytes), audit = report.audit;
const population=await loadNetworkPopulation();
await assertInstalledRelease(folder,report,population);
assert.equal(audit.operating_day, 'network');
assert.equal(audit.delay, 0, 'Disturbed days are not baseline category comparisons');
assert.equal(audit.finished,population.count); assert.equal(audit.total,population.count);
assert.deepEqual(audit.events, []);
assert.equal(audit.dispatcher,'predictive');
const packPath = `art/timetables/kerala-coast-network${audit.dispatcher === 'classic' ? '' : '-v2'}.json`;
const packBytes = await readFile(packPath), pack = JSON.parse(packBytes);
assert.equal(sha(packBytes), audit.pack_sha256, 'Authored pack no longer matches replay');
for (const [path, hash] of Object.entries(report.sources)) {
  const bytes = await readFile(path);
  assert.equal(sha(path.endsWith('.bin') ? bytes : bytes.toString('utf8').replaceAll('\r\n', '\n')), hash, 'Changed replay source: ' + path);
}
const authors = Object.fromEntries(pack.services.map(service => [service.id, service]));
assert.deepEqual(Object.keys(report.services).sort(), Object.keys(authors).sort());
for (const [id, service] of Object.entries(report.services)) {
  assert.equal(service.stabled, true, id + ' has not cleared the railway');
  assert.deepEqual(service.journey, authors[id].journey);
  const n = service.booked_stops.length;
  assert.equal(n, authors[id].stops.length);
  assert.equal(service.actual_arrivals.length, n); assert.equal(service.actual_departures.length, n);
  for (let i = 0; i < n - 1; i++) {
    assert.ok(service.actual_departures[i] >= 0 && service.actual_arrivals[i + 1] >= service.actual_departures[i], id + ' incomplete or reversed call');
    if (i > 0) assert.ok(service.actual_departures[i] >= service.actual_arrivals[i], id + ' reversed dwell');
  }
}
function stats(values) {
  const sorted = [...values].sort((a, b) => a - b), n = sorted.length;
  if (!n) return {samples: 0};
  return {samples: n, minimum: sorted[0], median: n % 2 ? sorted[(n - 1) / 2] : (sorted[n / 2 - 1] + sorted[n / 2]) / 2,
    mean: sorted.reduce((sum, value) => sum + value, 0) / n,
    p90: sorted[Math.ceil(n * .9) - 1], maximum: sorted.at(-1)};
}
const categoryOf = id => authors[id].journey.category;
const categories = {};
for (const [id, service] of Object.entries(report.services)) (categories[categoryOf(id)] ??= []).push({
  id, arrival_delay_seconds: service.arrival_delay,
  on_map_passenger_calls: service.booked_stops.filter(stop => !stop.boundary).length,
  terminal_kind: service.terminal_kind, stock: authors[id].stock,
});
const categorySummary = Object.fromEntries(Object.entries(categories).map(([category, services]) => [category, {
  services: services.length, arrival_delay_seconds: stats(services.map(s => s.arrival_delay_seconds)),
  on_map_passenger_calls: stats(services.map(s => s.on_map_passenger_calls)), records: services,
}]));
const corridors = [];
for (const [from, to] of [['ERS', 'TVC'], ['TVC', 'ERS'], ['TVC', 'NCJ'], ['NCJ', 'TVC'], ['QLN', 'TVC'], ['TVC', 'QLN']]) {
  const rides = {};
  for (const [id, service] of Object.entries(report.services)) {
    const stops = service.booked_stops;
    const i = stops.findIndex(stop => !stop.boundary && stop.block.startsWith(from + '_P'));
    const j = stops.findIndex(stop => !stop.boundary && stop.block.startsWith(to + '_P'));
    if (i < 0 || j <= i) continue;
    (rides[categoryOf(id)] ??= []).push({id,
      actual_seconds: service.actual_arrivals[j] - service.actual_departures[i],
      booked_seconds: (stops[j].minutes_from_origin - stops[i].minutes_from_origin - stops[i].dwell_minutes) * 60,
      intermediate_calls: j - i - 1, departure_clock: service.actual_departures[i], arrival_clock: service.actual_arrivals[j],
    });
  }
  corridors.push({from, to, categories: Object.fromEntries(Object.entries(rides).map(([category, records]) => [category, {
    actual_seconds: stats(records.map(r => r.actual_seconds)), booked_seconds: stats(records.map(r => r.booked_seconds)),
    intermediate_calls: stats(records.map(r => r.intermediate_calls)), records,
  }]))});
}
const trafficBytes=await readFile(folder+'/starts/traffic.json');
const traffic=JSON.parse(trafficBytes);
const first=traffic.audit.partitions[0].first,samples=traffic.audit.samples,finalClock=traffic.audit.partitions.at(-1).last;
const overtakes=traffic.events.filter(event=>event.kind==='overtake').map(event=>{
  const overtaken=event.overtaker===event.a?event.b:event.a;
  return {...event,overtaken,overtaker_category:categoryOf(event.overtaker),overtaken_category:categoryOf(overtaken)};
});
const passCounts = {};
for (const event of overtakes) {
  const key = event.overtaker_category + ' passes ' + event.overtaken_category;
  passCounts[key] = (passCounts[key] ?? 0) + 1;
}
const result = {
  description: 'Actual completed optional Network 179 baseline (wait targets waived); matched corridor rides include intermediate dwell and traffic waits, exclude initial-platform detention.',
  limitations: ['Different departures encounter different traffic; category medians do not prove a stock-only causal effect.',
    'These authored representative services are not a published Indian Railways timetable.',
    'This describes completed traffic; the release explicitly accepts failed cumulative wait targets while retaining safety and completion checks.',
    'Full-formation traffic passes are observed results, never forced passing locations.'],
  dispatcher: audit.dispatcher, audit_sha256: sha(auditBytes), pack_sha256: sha(packBytes),
  prepared_traffic_sha256: sha(trafficBytes), source_hashes_checked: Object.keys(report.sources).length,
  first_clock: first, final_clock: finalClock, traffic_samples: samples,
  categories: categorySummary, corridors, pass_counts: passCounts, overtakes,
};
await writeFile(output, JSON.stringify(result, null, 2) + '\n');
console.log(JSON.stringify({output, dispatcher: audit.dispatcher, services: audit.finished, overtakes: overtakes.length, pass_counts: passCounts}));
