// Read-only analysis of real replay samples, independent of the dispatcher.
// A sample is [clock, [[id, centre chainage, head chainage, tail chainage, direction], ...]].
// Crossings are opposing train-centre passes. An overtake must reverse the
// order of TWO FULL formations; nose/centre shuffling in a yard is insufficient.
export class TrafficEncounters {
  pairs = new Map();
  events = [];
  clock = null;
  sample([clock, rows]) {
    if (!Number.isFinite(clock) || this.clock !== null && (clock <= this.clock || clock - this.clock > 2.01)) throw Error('Discontinuous traffic recording');
    this.clock = clock;
    const present = new Set();
    const sorted = [...rows].sort((a, b) => a[0].localeCompare(b[0], 'en'));
    for (let i = 0; i < sorted.length; i++) for (let j = i + 1; j < sorted.length; j++) {
      const a = sorted[i], b = sorted[j], key = a[0] + '|' + b[0];
      present.add(key);
      const old = this.pairs.get(key);
      const extentOrder = Math.min(a[2], a[3]) > Math.max(b[2], b[3]) + 1 ? 1
        : Math.max(a[2], a[3]) < Math.min(b[2], b[3]) - 1 ? -1 : 0;
      let state = old;
      if (!state || a[4] !== state.a[4] || b[4] !== state.b[4]) {
        state = {a, b, clock, order: extentOrder, candidate: null, crossed: false};
        this.pairs.set(key, state);
        continue;
      }
      const before = state.a[1] - state.b[1], after = a[1] - b[1];
      const aligned = () => {
        const ratio = Math.max(0, Math.min(1, before / (before - after)));
        return {time: state.clock + ratio * (clock - state.clock), chainage_m: state.a[1] + ratio * (a[1] - state.a[1]), a: a[0], b: b[0]};
      };
      if (a[4] !== b[4]) {
        if (!state.crossed && before * a[4] < 0 && after * a[4] >= 0) {
          this.events.push({...aligned(), kind: 'crossing'});
          state.crossed = true;
        }
      } else {
        if (!state.order && extentOrder) state.order = extentOrder;
        if (state.order && before * state.order > 0 && after * state.order <= 0) state.candidate = aligned();
        if (after * state.order > 0) state.candidate = null;
        if (extentOrder && state.order && extentOrder !== state.order && state.candidate) {
          this.events.push({...state.candidate, kind: 'overtake', overtaker: extentOrder * a[4] > 0 ? a[0] : b[0], cleared: clock});
          state.order = extentOrder;
          state.candidate = null;
        }
      }
      state.a = a; state.b = b; state.clock = clock;
    }
    // Spawning, terminating and depot entry reset comparisons, not fabricate passes.
    for (const key of this.pairs.keys()) if (!present.has(key)) this.pairs.delete(key);
  }
}

export function locationAt(chainage, stations) {
  const nearest = [...stations].sort((a, b) => Math.abs(a.s - chainage) - Math.abs(b.s - chainage))[0];
  if (nearest && Math.abs(nearest.s - chainage) <= nearest.half) return {station: nearest.code, location: nearest.name};
  const before = stations.findLast(s => s.s <= chainage), after = stations.find(s => s.s > chainage);
  if (before && after) return {station: '', location: `Between ${before.name} and ${after.name}`};
  return {station: '', location: `Near ${nearest?.name ?? 'route boundary'}`};
}
