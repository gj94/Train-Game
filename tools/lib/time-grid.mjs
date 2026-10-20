import assert from 'node:assert/strict';

// Simulation accumulation can leave 03:20:00 as 98400.0000000001.
// Ignore sub-microsecond residue without rounding away a real later sample.
export function ceilFiveMinute(clock) {
  assert.ok(Number.isFinite(clock) && clock >= 0, 'Invalid railway clock');
  return Math.max(0, Math.ceil((clock - 1e-6) / 300) * 300);
}
