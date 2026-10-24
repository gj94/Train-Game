// Diagnostic comparison only: never certifies or writes prepared railway data.
import {readFile,writeFile} from 'node:fs/promises';
import {pathToFileURL} from 'node:url';
import assert from 'node:assert/strict';

export function compareRuns(before,after){
  for(const report of [before,after]){
    assert.ok(report.audit&&report.services,'Expected a completed rehearsal report');
    assert.equal(report.audit.finished,Object.keys(report.services).length,'Incomplete replay');
    for(const [id,s]of Object.entries(report.services)){
      assert.ok(s.stabled,`${id} did not clear its service`);
      assert.ok(Number.isFinite(s.arrival_delay)&&s.arrival_delay>=0,`${id} has no destination result`);
    }
  }
  const unmatched={before:[],after:[]},changes=[],byPriority={};
  for(const [id,a]of Object.entries(before.services)){
    const b=after.services[id];
    if(!b){unmatched.before.push(id);continue;}
    assert.equal(a.priority,b.priority,`Priority changed for ${id}; not a comparable service`);
    const row={id,priority:a.priority,before_seconds:a.arrival_delay,after_seconds:b.arrival_delay,
      change_seconds:b.arrival_delay-a.arrival_delay,departure_change_seconds:b.departure-a.departure,
      before_maximum_wait_seconds:a.max_wait_seconds,after_maximum_wait_seconds:b.max_wait_seconds};
    changes.push(row);(byPriority[a.priority]??=[]).push(row);
  }
  for(const id of Object.keys(after.services))if(!before.services[id])unmatched.after.push(id);
  const stats=rows=>({services:rows.length,
    mean_before_seconds:rows.reduce((sum,r)=>sum+r.before_seconds,0)/rows.length,
    mean_after_seconds:rows.reduce((sum,r)=>sum+r.after_seconds,0)/rows.length,
    total_change_seconds:rows.reduce((sum,r)=>sum+r.change_seconds,0),
    improved_over_15s:rows.filter(r=>r.change_seconds<-15).length,
    worsened_over_15s:rows.filter(r=>r.change_seconds>15).length,
    within_15s:rows.filter(r=>Math.abs(r.change_seconds)<=15).length});
  const order=changes.toSorted((a,b)=>b.change_seconds-a.change_seconds||a.id.localeCompare(b.id));
  const changedDepartures=changes.filter(r=>r.departure_change_seconds!==0);
  return {interpretation:changedDepartures.length?
    'Dispatcher AND authored-departure comparison; differences cannot be attributed to the planner alone.':
    'Matched services retain their departure times; compare other source/configuration differences separately.',
    before_mode:before.audit.dispatcher??'classic',after_mode:after.audit.dispatcher??'classic',
    before_audit_ok:before.audit.ok,after_audit_ok:after.audit.ok,unmatched,
    matched:changes.length,changed_departures:changedDepartures.map(r=>({id:r.id,seconds:r.departure_change_seconds})),
    priority_groups:Object.fromEntries(Object.entries(byPriority).map(([priority,rows])=>[priority,stats(rows)])),
    largest_regressions:order.filter(r=>r.change_seconds>15).slice(0,12),
    largest_improvements:order.toReversed().filter(r=>r.change_seconds<-15).slice(0,12),
    k1:changes.find(r=>r.id==='K1')??null,
    wait_quality:{before:before.audit.wait_quality,after:after.audit.wait_quality},
    station_wait_quality:{before:before.audit.station_wait_quality,after:after.audit.station_wait_quality}};
}

if(process.argv[1]&&import.meta.url===pathToFileURL(process.argv[1]).href){
  const [left,right]=process.argv.slice(2,4);
  if(!left||!right)throw Error('Pass two completed rehearsal folders');
  const reports=await Promise.all([left,right].map(async folder=>JSON.parse(await readFile(folder+'/audit.json','utf8'))));
  const result=compareRuns(...reports),text=JSON.stringify(result,null,2)+'\n';
  const output=process.argv.find(a=>a.startsWith('--output='))?.slice(9);
  if(output)await writeFile(output,text);
  console.log(text);
}
