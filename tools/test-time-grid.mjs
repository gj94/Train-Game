import test from 'node:test';
import assert from 'node:assert/strict';
import {ceilFiveMinute} from './lib/time-grid.mjs';

test('recorded end-of-day floating residue stays on its snapshot', () => {
  assert.equal(ceilFiveMinute(98400.0000000001), 98400);
  assert.equal(ceilFiveMinute(98399.9999999999), 98400);
  assert.equal(ceilFiveMinute(98400), 98400);
});
test('a genuinely later sample still requires the next snapshot', () => {
  assert.equal(ceilFiveMinute(98400.001), 98700);
  assert.equal(ceilFiveMinute(98402), 98700);
});
test('origin and intermediate times retain the five-minute grid', () => {
  assert.equal(ceilFiveMinute(0), 0);
  assert.equal(ceilFiveMinute(28800.0000000001), 28800);
  assert.equal(ceilFiveMinute(29570), 29700);
});
test('invalid clocks cannot pass publication validation', () => {
  for (const clock of [NaN, Infinity, -1, '98400']) {
    assert.throws(() => ceilFiveMinute(clock));
  }
});
