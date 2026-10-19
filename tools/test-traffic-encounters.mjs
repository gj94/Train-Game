import {test} from 'node:test';
import assert from 'node:assert/strict';
import {TrafficEncounters, locationAt} from './lib/traffic-encounters.mjs';
const row = (id, center, direction = 1, length = 100) => [id, center, center + direction * length / 2, center - direction * length / 2, direction];
test('opposing crossing uses actual movement and interpolated time, once', () => {
  const d = new TrafficEncounters();
  d.sample([0, [row('A', 0), row('B', 100, -1)]]);
  d.sample([2, [row('A', 80), row('B', 60, -1)]]);
  d.sample([4, [row('A', 150), row('B', 20, -1)]]);
  assert.equal(d.events.length, 1); assert.equal(d.events[0].kind, 'crossing');
  assert.ok(Math.abs(d.events[0].time - 5 / 3) < 1e-10);
  assert.ok(Math.abs(d.events[0].chainage_m - 200 / 3) < 1e-10);
});
test('full formation overtake in either direction, correct overtaker', () => {
  for (const dir of [1, -1]) {
    const d = new TrafficEncounters();
    for (const [i, position] of [-200, -20, 20, 80, 160].entries()) d.sample([i * 2, [row('slow', 0, dir, 300), row('fast', position * dir, dir, 20)]]);
    assert.equal(d.events.length, 0, 'must clear both formations plus tolerance');
    d.sample([10, [row('slow', 0, dir, 300), row('fast', 180 * dir, dir, 20)]]);
    assert.equal(d.events.length, 1); assert.equal(d.events[0].overtaker, 'fast'); assert.equal(d.events[0].time, 3); assert.equal(d.events[0].cleared, 10);
  }
});
test('centre shuffle and abandoned pass are not completed overtakes', () => {
  const d = new TrafficEncounters();
  for (const [i, position] of [-200, -10, 10, -10, -200].entries()) d.sample([i * 2, [row('A', 0), row('B', position)]]);
  assert.equal(d.events.length, 0);
});
test('spawn, removal and direction change cannot fabricate a pass', () => {
  const d = new TrafficEncounters();
  d.sample([0, [row('A', 0), row('B', -200)]]);
  d.sample([2, [row('A', 0)]]);
  d.sample([4, [row('A', 0), row('B', 200)]]);
  d.sample([6, [row('A', 0), row('B', -200, -1)]]);
  assert.equal(d.events.length, 0);
});
test('an already-overlapping spawn has no proven overtake order', () => {
  const d = new TrafficEncounters();
  d.sample([0, [row('A', 0), row('B', -20)]]);
  d.sample([2, [row('A', 0), row('B', 20)]]);
  d.sample([4, [row('A', 0), row('B', 200)]]);
  assert.equal(d.events.length, 0);
});
test('same pair can genuinely overtake again later, with reversed roles', () => {
  const d = new TrafficEncounters();
  for (const [i, position] of [-200, -20, 20, 200, 20, -20, -200].entries()) d.sample([i * 2, [row('A', 0), row('B', position)]]);
  assert.deepEqual(d.events.map(e => e.overtaker), ['B', 'A']);
});
test('a sample exactly on alignment does not double count', () => {
  const d = new TrafficEncounters();
  for (const [i, position] of [-100, 0, 0, 100].entries()) d.sample([i * 2, [row('A', position), row('B', 0, -1)]]);
  assert.equal(d.events.length, 1); assert.equal(d.events[0].time, 2);
});
test('midnight is absolute and long/missing samples are rejected', () => {
  const d = new TrafficEncounters();
  d.sample([86399, [row('A', -50), row('B', 50, -1)]]);
  d.sample([86401, [row('A', 50), row('B', -50, -1)]]);
  assert.equal(d.events[0].time, 86400);
  assert.throws(() => d.sample([86405, []]), /Discontinuous/);
});
test('location distinguishes station yard and interstation pass', () => {
  const stations = [{code: 'A', name: 'Alpha', s: 1000, half: 600}, {code: 'B', name: 'Beta', s: 5000, half: 500}];
  assert.equal(locationAt(1400, stations).station, 'A');
  assert.deepEqual(locationAt(3000, stations), {station: '', location: 'Between Alpha and Beta'});
});
