import assert from 'node:assert/strict';
import {compareCalls} from './lib/call-punctuality.mjs';
const a={services:{X:{priority:100,departure:85800,
  booked_stops:[{block:'ERS_P1',direction:1,minutes_from_origin:0,dwell_minutes:0},
    {block:'ALLP_P1',direction:1,minutes_from_origin:60,dwell_minutes:2},
    {block:'NCJ_P1',direction:1,minutes_from_origin:180,dwell_minutes:4}],
  actual_arrivals:[-1,89520,96600],actual_departures:[85804,89640,-1]}}};
const b=structuredClone(a);b.services.X.actual_arrivals[1]-=120;b.services.X.actual_departures[1]-=120;
const r=compareCalls(a,b);
assert.equal(r.compared_calls,4);assert.equal(r.priority_groups[100].arrival.mean_before_seconds,60);
assert.equal(r.priority_groups[100].arrival.mean_after_seconds,0);
assert.equal(r.priority_groups[100].arrival.improved_over_15s,1);
assert.equal(r.priority_groups[100].departure.improved_over_15s,1);
assert.equal(r.largest_improvements[0].change_seconds,-120);
assert.equal(r.largest_regressions.length,0);assert.equal(r.changed_call_times.length,0);
assert.equal(r.largest_improvements[0].station,'ALLP');
// Changing platforms is not a changed calling pattern.
const platform=structuredClone(b);platform.services.X.booked_stops[1].block='ALLP_P3';
assert.deepEqual(compareCalls(a,platform),r);
// Shift both the schedule and actual movement: lateness is unchanged, and the
// authored shift is explicit. Crossing midnight never wraps the absolute clock.
const shifted=structuredClone(a);shifted.services.X.departure+=600;
for(const field of ['actual_arrivals','actual_departures'])shifted.services.X[field]=shifted.services.X[field].map(t=>t<0?t:t+600);
const shiftedResult=compareCalls(a,shifted);
assert.equal(shiftedResult.largest_improvements.length,0);assert.equal(shiftedResult.largest_regressions.length,0);
assert.equal(shiftedResult.changed_call_times.length,4);assert.ok(shiftedResult.changed_call_times.every(r=>r.seconds===600));
const early=structuredClone(b);early.services.X.actual_arrivals[1]-=60;
assert.equal(compareCalls(b,early).priority_groups[100].arrival.mean_after_seconds,0);
const changed=structuredClone(b);changed.services.X.booked_stops[1].block='KYJ_P1';
assert.equal(compareCalls(a,changed).available,false);assert.match(compareCalls(a,changed).unavailable_services[0].reason,/Changed calling pattern/);
const missing=structuredClone(b);missing.services.X.actual_arrivals[1]=-1;
assert.throws(()=>compareCalls(a,missing),/Incomplete X call 1 arrival/);
const absent=structuredClone(b);delete absent.services.X.actual_departures;
assert.throws(()=>compareCalls(a,absent),/Missing departure records/);
assert.equal(compareCalls({services:{X:{}}},{services:{X:{}}}).available,false);
assert.equal(compareCalls(a,{services:{}}).compared_calls,0);
console.log('21 call punctuality assertions passed');
