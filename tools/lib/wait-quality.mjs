import assert from 'node:assert/strict';
export function waitQuality(rows){
  const waits=rows.filter(r=>r.seconds>=30), limits=[600,1200,1800,2700], fractions=[.7,.9,.98,1];
  const bins=[0,0,0,0,0];let maximum=0;
  for(const row of waits){
    assert.ok(Number.isFinite(row.seconds)&&row.seconds>=0);
    maximum=Math.max(maximum,row.seconds);
    const i=limits.findIndex(limit=>row.seconds<limit);bins[i<0?4:i]++;
  }
  let count=0;
  const cumulative=limits.map((under_seconds,i)=>{
    count+=bins[i];return {under_seconds,required:fractions[i],count,
      fraction:waits.length?count/waits.length:1,met:count>=Math.ceil(waits.length*fractions[i]-1e-9)};
  });
  return {ok:cumulative.every(r=>r.met),minimum_seconds:30,count:waits.length,brief_count:rows.length-waits.length,bins,cumulative,maximum};
}
function compareSummary(actual,expected,label){
  assert.ok(actual,'Missing '+label);
  for(const key of ['ok','minimum_seconds','count','brief_count','bins','maximum'])assert.deepEqual(actual[key],expected[key],label+' does not match recorded episodes');
  assert.equal(actual.cumulative.length,expected.cumulative.length);
  expected.cumulative.forEach((row,i)=>{
    for(const key of ['under_seconds','required','count','met'])assert.equal(actual.cumulative[i][key],row[key]);
    assert.ok(Math.abs(actual.cumulative[i].fraction-row.fraction)<1e-12,'Rounded JSON fraction differs');
  });
}
export function assertWaitQuality(report){
  assert.ok(Array.isArray(report.station_waits)&&Array.isArray(report.signal_waits),'Missing per-stop wait measurement');
  for(const row of [...report.station_waits,...report.signal_waits]){
    assert.ok(report.services[row.id]&&Number.isInteger(row.call)&&row.call>=0);
    assert.ok(row.call<report.services[row.id].booked_stops.length);
    assert.ok(Number.isFinite(row.seconds)&&row.seconds>=0);
    assert.equal(Object.values(row.reasons).reduce((a,b)=>a+b,0),row.seconds,'Wait reason accounting differs');
  }
  const all=waitQuality([...report.station_waits,...report.signal_waits]), stations=waitQuality(report.station_waits);
  compareSummary(report.audit.wait_quality,all,'Wait distribution');
  compareSummary(report.audit.station_wait_quality,stations,'Station distribution');
  assert.ok(all.ok,'Combined waits miss the 70/20/8/2 target');
  assert.ok(stations.ok,'Station waits miss the 70/20/8/2 target');
  assert.ok(report.audit.maximum_wait<2700,'Continuous wait reached 45 minutes');
  return {all,stations};
}
