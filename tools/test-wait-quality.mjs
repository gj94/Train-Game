import test from 'node:test';
import assert from 'node:assert/strict';
import {waitQuality,assertWaitQuality} from './lib/wait-quality.mjs';
const requested=()=>Array.from({length:100},(_,i)=>({seconds:i<70?500:i<90?1100:i<98?1700:2600}));
test('70/20/8/2 bands, without adding long waits to a better timetable',()=>{
  assert.equal(waitQuality(requested()).ok,true);
  assert.deepEqual(waitQuality(requested()).bins,[70,20,8,2,0]);
  assert.equal(waitQuality([{seconds:60}]).ok,true);
});
test('each boundary is strictly under the requested threshold',()=>{
  for(const [i,seconds] of [[69,600],[89,1200],[97,1800],[99,2700]]){
    const rows=requested();rows[i].seconds=seconds;assert.equal(waitQuality(rows).ok,false);
  }
});
test('tiny pauses cannot dilute a long hold',()=>{
  const report=waitQuality([...Array(100).fill({seconds:2}),{seconds:2600}]);
  assert.equal(report.ok,false);assert.equal(report.count,1);assert.equal(report.brief_count,100);
});
test('publication recalculates recorded waits instead of trusting a passing flag',()=>{
  const row={id:'K1',call:0,seconds:600,reasons:{crossing:600}};
  const report={services:{K1:{booked_stops:[{}]}},station_waits:[row],signal_waits:[],audit:{wait_quality:waitQuality([]),station_wait_quality:waitQuality([]),maximum_wait:600}};
  assert.throws(()=>assertWaitQuality(report),/does not match/);
});
