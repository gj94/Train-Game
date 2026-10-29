// Explicit optional-day release policy. Never changes the recorded strict audit.
import assert from 'node:assert/strict';
import {readFile} from 'node:fs/promises';
import {createHash} from 'node:crypto';
import {assertSelectedNetworkReport} from './network-population.mjs';
import {waitQuality} from './wait-quality.mjs';
export const RELEASE_POLICY='network-v2-long-waits-2026-10-29';
export const RELEASE_OBSERVERS=['tools/install_network_release.mjs','tools/lib/network-release.mjs'];
export const sha=bytes=>createHash('sha256').update(bytes).digest('hex');
export function assertReleaseReport(report,population,delay){
  assertSelectedNetworkReport(report,population);
  assert.equal(report.audit.delay,delay);assert.deepEqual(report.audit.events,[]);
  if(delay){assert.equal(report.audit.delay_at,27000);assert.equal(report.audit.delay_service,'K1');}
  let arrivals=0,departures=0,boundary=0,depot=0;
  for(const [id,s] of Object.entries(report.services)){
    assert.equal(s.stabled,true,id+' not cleared');
    const n=s.booked_stops.length;assert.ok(n>=2);
    assert.equal(s.actual_arrivals.length,n);assert.equal(s.actual_departures.length,n);
    for(let i=0;i<n-1;i++){
      const departure=s.actual_departures[i],arrival=s.actual_arrivals[i+1];
      assert.ok(Number.isFinite(departure)&&departure>=0,id+' missing departure');
      assert.ok(Number.isFinite(arrival)&&arrival>=departure,id+' missing/reversed arrival');
      if(i>0)assert.ok(departure>=s.actual_arrivals[i],id+' reversed dwell');
      arrivals++;departures++;
    }
    const terminal=s.booked_stops.at(-1).boundary==='exit'?'boundary_exit':'depot';
    assert.equal(s.terminal_kind,terminal,id+' unfinished terminal');
    terminal==='boundary_exit'?boundary++:depot++;
  }
  for(const row of [...report.station_waits,...report.signal_waits]){
    assert.ok(report.services[row.id]&&Number.isInteger(row.call)&&row.call>=0&&row.call<report.services[row.id].booked_stops.length);
    assert.ok(Number.isFinite(row.seconds)&&row.seconds>=0);
    assert.ok(Object.values(row.reasons).every(n=>Number.isFinite(n)&&n>=0));
    assert.equal(Object.values(row.reasons).reduce((a,b)=>a+b,0),row.seconds,'Wait accounting differs');
  }
  const all=waitQuality([...report.station_waits,...report.signal_waits]),stations=waitQuality(report.station_waits);
  for(const [actual,expected] of [[report.audit.wait_quality,all],[report.audit.station_wait_quality,stations]]){
    for(const key of ['ok','minimum_seconds','count','brief_count','bins','maximum'])assert.deepEqual(actual[key],expected[key]);
    assert.equal(actual.cumulative.length,expected.cumulative.length);
    expected.cumulative.forEach((row,i)=>{
      for(const key of ['under_seconds','required','count','met'])assert.equal(actual.cumulative[i][key],row[key]);
      assert.ok(Math.abs(actual.cumulative[i].fraction-row.fraction)<1e-12);
    });
  }
  assert.ok(Number.isFinite(report.audit.maximum_wait)&&report.audit.maximum_wait>=0);
  const strict=all.ok&&stations.ok&&report.audit.maximum_wait<2700;
  assert.equal(report.audit.ok,strict,'Audit rejection is not explained by the waived wait gates');
  return {services:population.count,arrivals,departures,boundary_exits:boundary,depot_completions:depot,safety_events:0,
    strict_quality_ok:strict,all_wait_quality:all,station_wait_quality:stations,maximum_continuous_wait:report.audit.maximum_wait};
}
export async function assertInstalledRelease(folder,report,population){
  const certificate=JSON.parse(await readFile(folder+'/release.json','utf8'));
  assert.equal(certificate.policy,RELEASE_POLICY);assert.equal(certificate.wait_targets_waived,true);
  assert.equal(certificate.disclosure,'Long waits can occur. This optional timetable exceeds the usual wait targets.');
  assert.equal(certificate.pack_sha256,population.pack_sha256);
  const normal=await readFile(folder+'/audit.json'),delayed=await readFile(folder+'/disturbed-audit.json');
  assert.equal(certificate.baseline_audit_sha256,sha(normal));assert.equal(certificate.delayed_audit_sha256,sha(delayed));
  assert.deepEqual(certificate.normal,assertReleaseReport(report,population,0));
  assert.deepEqual(certificate.delayed,assertReleaseReport(JSON.parse(delayed),population,600));
  return certificate;
}
