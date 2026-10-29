// Read a completed incremental construction trial once. This is not the
// installed179 contract or a release certificate for a larger population.
import {readFile, writeFile, readdir} from 'node:fs/promises';
import {createReadStream} from 'node:fs';
import {createHash} from 'node:crypto';
import {createInterface} from 'node:readline';
import assert from 'node:assert/strict';
import {TrafficEncounters, locationAt} from './lib/traffic-encounters.mjs';

const [folder, packPath, output] = process.argv.slice(2);
assert(folder && packPath && output, 'Provide completed run, exact candidate pack, and new report path');
const sha = bytes => createHash('sha256').update(bytes).digest('hex');
const auditBytes = await readFile(folder + '/audit.json');
const raw = JSON.parse(auditBytes), audit = raw.audit;
const packBytes = await readFile(packPath), pack = JSON.parse(packBytes);
assert.equal(audit.pack_sha256, sha(packBytes), 'Wrong candidate pack');
assert.equal(audit.dispatcher, 'predictive');
assert.equal(audit.operating_day, 'network');
assert.deepEqual(Object.keys(raw.services).sort(), pack.services.map(s => s.id).sort());
const inventory = [];
async function collect(directory) {
  for (const item of await readdir(directory, {withFileTypes: true})) {
    const name = directory + '/' + item.name;
    if (item.isDirectory()) await collect(name);
    else if (/\.(gd|json|bin|csv)$/.test(name)) inventory.push(name);
  }
}
await collect('sim'); await collect('data/routes/kerala_coast');
inventory.push(packPath.replaceAll('\\', '/').replace(/^\.\//, ''));
assert.deepEqual(Object.keys(raw.sources).sort(), inventory.sort(), 'Source inventory differs');
for (const [path, expected] of Object.entries(raw.sources)) {
  const bytes = await readFile(path);
  assert.equal(sha(path.endsWith('.bin') ? bytes : bytes.toString('utf8').replaceAll('\r\n', '\n')), expected, 'Changed source ' + path);
}
const issues = [], services = {};
let arrivals = 0, departures = 0;
for (const source of pack.services) {
  const s = raw.services[source.id], n = source.stops.length;
  const calls = [];
  if (s.actual_arrivals.length !== n || s.actual_departures.length !== n) issues.push(source.id + ': call count mismatch');
  if (!s.stabled) issues.push(source.id + ': terminal working incomplete');
  const expectedTerminal = source.stops.at(-1).boundary === 'exit' ? 'boundary_exit' : 'depot';
  if (s.terminal_kind !== expectedTerminal) issues.push(source.id + ': terminal kind differs');
  for (let i = 0; i < n; i++) {
    if (i > 0) {
      if (Number.isFinite(s.actual_arrivals[i]) && s.actual_arrivals[i] >= 0) arrivals++;
      else issues.push(source.id + ': missing arrival ' + i);
    }
    if (i < n - 1) {
      if (Number.isFinite(s.actual_departures[i]) && s.actual_departures[i] >= 0) departures++;
      else issues.push(source.id + ': missing departure ' + i);
    }
    calls.push({index: i, name: source.stops[i].name, block: source.stops[i].block,
      boundary: source.stops[i].boundary ?? '',
      planned_arrival: s.departure + source.stops[i].minutes_from_origin * 60,
      actual_arrival: s.actual_arrivals[i], actual_departure: s.actual_departures[i]});
  }
  for (let i = 0; i < n - 1; i++) if (s.actual_arrivals[i + 1] < s.actual_departures[i]) issues.push(source.id + ': reversed travel time');
  for (let i = 1; i < n - 1; i++) if (s.actual_departures[i] < s.actual_arrivals[i]) issues.push(source.id + ': reversed dwell');
  services[source.id] = {category: source.journey.category, complete: s.stabled,
    terminal_kind: s.terminal_kind, arrival_delay: s.arrival_delay, calls,
    total_extra_wait: s.wait_seconds, maximum_continuous_wait: s.max_wait_seconds};
}
if (audit.finished !== pack.services.length || audit.total !== pack.services.length) issues.push('Incomplete population');
if (audit.events.length) issues.push('Safety events');
const detector = new TrafficEncounters(), trafficHash = createHash('sha256');
const stream = createReadStream(folder + '/traffic.jsonl');
stream.on('data', bytes => trafficHash.update(bytes));
let first, samples = 0;
for await (const line of createInterface({input: stream, crlfDelay: Infinity})) {
  if (!line) continue;
  const frame = JSON.parse(line); first ??= frame[0]; detector.sample(frame); samples++;
}
assert(Math.abs(detector.clock - audit.clock) < .001, 'Trajectory ends before final audit');
assert.equal(samples, Math.round((detector.clock - first) / 2) + 1);
const events = detector.events.map(e => ({...e, ...locationAt(e.chainage_m, raw.stations)}));
const report = {scope: 'actual incremental prefix trial; no larger-population readiness claim',
  checked_at: new Date().toISOString(), pack_sha256: sha(packBytes), audit_sha256: sha(auditBytes),
  traffic_sha256: trafficHash.digest('hex'), source_count: inventory.length, samples,
  all_calls_and_terminals_complete: issues.length === 0, issues, arrivals_checked: arrivals,
  departures_checked: departures, services, events, audit,
  station_waits: raw.station_waits, signal_waits: raw.signal_waits};
await writeFile(output, JSON.stringify(report, null, 2) + '\n', {flag: 'wx'});
console.log(JSON.stringify({output, finished: audit.finished, total: audit.total, issues,
  strict_wait_audit_ok: audit.ok, overtakes: events.filter(e => e.kind === 'overtake'),
  arrivals, departures, sources: inventory.length, samples}));
