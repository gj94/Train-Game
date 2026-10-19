// Never ship a preview from another timetable, snapshot set or detector version.
import {readFile} from 'node:fs/promises';
import {createHash} from 'node:crypto';
import {fileURLToPath} from 'node:url';
import {join} from 'node:path';
import assert from 'node:assert/strict';
const root = fileURLToPath(new URL('../', import.meta.url));
const sha = b => createHash('sha256').update(b).digest('hex');
const bytes = await readFile(join(root, 'data/service_starts/catalogue.json'));
const starts = JSON.parse(bytes);
const traffic = JSON.parse(await readFile(join(root, 'data/service_starts/traffic.json')));
const timelineBytes = await readFile(join(root, 'data/railway_times/catalogue.json'));
const timeline = JSON.parse(timelineBytes);
assert.equal(traffic.version, 1); assert.equal(traffic.complete, true); assert.equal(traffic.audit.ok, true);
assert.equal(traffic.engine, starts.engine); assert.equal(traffic.start_sha256, sha(bytes)); assert.equal(traffic.timeline_sha256, sha(timelineBytes));
assert.deepEqual([...traffic.services].sort(), starts.services.map(s => s.id).sort());
for (const path of ['tools/record_service_traffic.gd', 'tools/lib/traffic-encounters.mjs', 'tools/prepare-service-traffic.mjs']) {
  assert.equal(sha((await readFile(join(root, path), 'utf8')).replaceAll('\r\n', '\n')), traffic.observer_sources[path], `Traffic observer changed: ${path}. Regenerate preview.`);
}
assert.equal(traffic.audit.sample_seconds, 2); assert.deepEqual(traffic.audit.safety_events, []);
let boundary = timeline.states[0].clock, steps = 0;
for (const part of traffic.audit.partitions) {
  assert.ok(Math.abs(boundary - part.first) < .001); assert.ok(part.last > part.first);
  assert.equal(part.steps, Math.round((part.last - part.first) / 2)); assert.ok(part.boundary_error_m <= .1);
  boundary = part.last; steps += part.steps;
}
assert.ok(Math.abs(boundary - timeline.states.at(-1).clock) < .001); assert.equal(traffic.audit.samples, steps + 1);
const unique = new Set(); let previous = -1;
for (const event of traffic.events) {
  assert.ok(['crossing', 'overtake'].includes(event.kind));
  assert.ok(traffic.services.includes(event.a) && traffic.services.includes(event.b) && event.a !== event.b);
  assert.ok(Number.isFinite(event.time) && event.time >= previous && event.time <= boundary); previous = event.time;
  assert.ok(Number.isFinite(event.chainage_m)); assert.ok(typeof event.location === 'string' && event.location.length > 0); assert.equal(typeof event.station, 'string');
  for (const id of [event.a, event.b]) assert.ok(event.time >= starts.services.find(s => s.id === id).start_clock - .001);
  if (event.kind === 'overtake') { assert.ok([event.a, event.b].includes(event.overtaker)); assert.ok(Number.isFinite(event.cleared) && event.cleared >= event.time); }
  const key = [event.a, event.b, event.kind, event.time].join('|'); assert.ok(!unique.has(key)); unique.add(key);
}
assert.equal(traffic.audit.crossing_count, traffic.events.filter(e => e.kind === 'crossing').length);
assert.equal(traffic.audit.overtake_count, traffic.events.filter(e => e.kind === 'overtake').length);
console.log(`Traffic preview verified: ${traffic.services.length} services; ${traffic.audit.crossing_count} crossings, ${traffic.audit.overtake_count} completed overtakes; entire baseline covered.`);
