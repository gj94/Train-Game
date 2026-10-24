// Call-level comparison exposes delays that a later recovery hides at destination.
import assert from 'node:assert/strict';
const station=stop=>stop.block.split('_P')[0];
const stats=rows=>({calls:rows.length,
  mean_before_seconds:rows.reduce((sum,r)=>sum+r.before_seconds,0)/rows.length,
  mean_after_seconds:rows.reduce((sum,r)=>sum+r.after_seconds,0)/rows.length,
  improved_over_15s:rows.filter(r=>r.change_seconds<-15).length,
  worsened_over_15s:rows.filter(r=>r.change_seconds>15).length,
  within_15s:rows.filter(r=>Math.abs(r.change_seconds)<=15).length});

export function compareCalls(before,after){
  const rows=[],unavailable=[],changedSchedules=[];
  for(const [id,a]of Object.entries(before.services)){
    const b=after.services[id];if(!b)continue;
    if(!Array.isArray(a.booked_stops)||!Array.isArray(b.booked_stops)){
      unavailable.push({id,reason:'Missing booked calls'});continue;
    }
    const same=a.booked_stops.length===b.booked_stops.length&&a.booked_stops.every((s,i)=>
      station(s)===station(b.booked_stops[i])&&s.direction===b.booked_stops[i].direction);
    if(!same){unavailable.push({id,reason:'Changed calling pattern; no indexed call comparison'});continue;}
    for(const [kind,field]of [['arrival','actual_arrivals'],['departure','actual_departures']]){
      for(const s of [a,b])assert.equal(s[field]?.length,s.booked_stops.length,`Missing ${kind} records for ${id}`);
      for(let i=0;i<a.booked_stops.length;i++){
        if((kind==='arrival'&&i===0)||(kind==='departure'&&i===a.booked_stops.length-1))continue;
        const planned=s=>s.departure+60*(s.booked_stops[i].minutes_from_origin+(kind==='departure'?s.booked_stops[i].dwell_minutes:0));
        const plannedA=planned(a),plannedB=planned(b),actualA=a[field][i],actualB=b[field][i];
        assert.ok([plannedA,plannedB,actualA,actualB].every(Number.isFinite)&&actualA>=0&&actualB>=0,`Incomplete ${id} call ${i} ${kind}`);
        const delayA=Math.max(0,actualA-plannedA),delayB=Math.max(0,actualB-plannedB);
        const row={id,priority:a.priority,call:i,station:station(a.booked_stops[i]),kind,
          before_seconds:delayA,after_seconds:delayB,change_seconds:delayB-delayA};
        rows.push(row);
        if(Math.abs(plannedB-plannedA)>1e-6)changedSchedules.push({id,call:i,kind,seconds:plannedB-plannedA});
      }
    }
  }
  const priorities=[...new Set(rows.map(r=>r.priority))].sort((a,b)=>b-a);
  const groups=Object.fromEntries(priorities.map(p=>[p,Object.fromEntries(['arrival','departure'].map(kind=>{
    const matched=rows.filter(r=>r.priority===p&&r.kind===kind);return [kind,matched.length?stats(matched):null];
  }))]));
  const ordered=rows.toSorted((a,b)=>b.change_seconds-a.change_seconds||a.id.localeCompare(b.id)||a.call-b.call||a.kind.localeCompare(b.kind));
  return {available:rows.length>0,interpretation:'Each booked arrival/departure is one observation, grouped by service priority; early arrivals count as zero lateness. Absolute operating-day times are retained.',
    compared_calls:rows.length,unavailable_services:unavailable,changed_call_times:changedSchedules,
    priority_groups:groups,largest_regressions:ordered.filter(r=>r.change_seconds>15).slice(0,12),
    largest_improvements:ordered.toReversed().filter(r=>r.change_seconds<-15).slice(0,12)};
}
