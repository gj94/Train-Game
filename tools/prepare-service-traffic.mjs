// Merge continuous offline trajectories; no gameplay or timetable mutations.
import {readFile, writeFile, rename} from 'node:fs/promises';
import {createReadStream} from 'node:fs';
import {createInterface} from 'node:readline';
import {createHash} from 'node:crypto';
import {fileURLToPath} from 'node:url';
import {join} from 'node:path';
import assert from 'node:assert/strict';
import {TrafficEncounters, locationAt} from './lib/traffic-encounters.mjs';
const root = fileURLToPath(new URL('../', import.meta.url));
const parts = Number(process.argv[2] ?? 4);
assert.ok(Number.isInteger(parts) && parts >= 1 && parts <= 8);
const sha = b => createHash('sha256').update(b).digest('hex');
const startBytes = await readFile(join(root, 'data/service_starts/catalogue.json'));
const timelineBytes = await readFile(join(root, 'data/railway_times/catalogue.json'));
const starts = JSON.parse(startBytes), timeline = JSON.parse(timelineBytes);
assert.ok(starts.complete && starts.audit.ok && timeline.complete && timeline.audit.ok);
const detector = new TrafficEncounters(), audit = [];
let previous = null, stations, samples = 0;
for (let part = 0; part < parts; part++) {
  const stem = join(root, '.local/service-traffic', String(part));
  const report = JSON.parse(await readFile(stem + '.json', 'utf8'));
  assert.equal(report.complete, true); assert.equal(report.part, part); assert.equal(report.parts, parts);
  assert.equal(report.start_sha256, sha(startBytes)); assert.equal(report.timeline_sha256, sha(timelineBytes));
  assert.equal(report.engine, starts.engine); assert.equal(report.events.length, 0); assert.ok(report.boundary_error_m <= .1);
  assert.equal(report.recording_sha256, sha(await readFile(stem + '.jsonl')));
  if (!stations) stations = report.stations; else assert.deepEqual(report.stations, stations);
  let count = 0, lastTime = null;
  for await (const line of createInterface({input: createReadStream(stem + '.jsonl'), crlfDelay: Infinity})) {
    if (!line) continue;
    const frame = JSON.parse(line);
    if (count++ === 0) {
      assert.ok(Math.abs(frame[0] - report.first) < .001);
      if (previous) {
        assert.ok(Math.abs(frame[0] - previous[0]) < .001, 'Missing partition boundary');
        assert.equal(frame[1].length, previous[1].length);
        for (let i = 0; i < frame[1].length; i++) {
          assert.equal(frame[1][i][0], previous[1][i][0]);
          for (const column of [1, 2, 3]) assert.ok(Math.abs(frame[1][i][column] - previous[1][i][column]) <= .1);
          assert.equal(frame[1][i][4], previous[1][i][4]);
        }
        lastTime = frame[0]; continue; // Observer carries pair history across partitions.
      }
    }
    detector.sample(frame); previous = frame; lastTime = frame[0]; samples++;
  }
  assert.ok(Math.abs(lastTime - report.last) < .001); assert.equal(count, report.steps + 1);
  audit.push({first: report.first, last: report.last, steps: report.steps, boundary_error_m: report.boundary_error_m, wall_seconds: report.wall_seconds});
}
assert.ok(Math.abs(audit[0].first - timeline.states[0].clock) < .001);
assert.ok(Math.abs(previous[0] - timeline.states.at(-1).clock) < .001);
const ids = starts.services.map(s => s.id);
const events = detector.events.sort((a, b) => a.time - b.time || a.a.localeCompare(b.a) || a.b.localeCompare(b.b))
  .map(event => ({...event, ...locationAt(event.chainage_m, stations)}));
for (const event of events) {
  assert.ok(ids.includes(event.a) && ids.includes(event.b));
  for (const id of [event.a, event.b]) assert.ok(event.time >= starts.services.find(s => s.id === id).start_clock - .001);
}
const observer_sources = {};
for (const path of ['tools/record_service_traffic.gd', 'tools/lib/traffic-encounters.mjs', 'tools/prepare-service-traffic.mjs']) observer_sources[path] = sha((await readFile(join(root, path), 'utf8')).replaceAll('\r\n', '\n'));
const data = {version: 1, complete: true, engine: starts.engine, start_sha256: sha(startBytes), timeline_sha256: sha(timelineBytes),
  observer_sources, services: ids, events, audit: {ok: true, sample_seconds: 2, samples, partitions: audit, safety_events: [],
    crossing_count: events.filter(e => e.kind === 'crossing').length, overtake_count: events.filter(e => e.kind === 'overtake').length}};
const output = join(root, 'data/service_starts/traffic.json');
await writeFile(output + '.tmp', JSON.stringify(data, null, 2) + '\n'); await rename(output + '.tmp', output);
console.log(JSON.stringify({services: ids.length, events: events.length, ...data.audit}, null, 2));
