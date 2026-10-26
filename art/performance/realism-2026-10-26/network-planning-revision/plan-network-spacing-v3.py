"""Departure-only planning heuristic, never a traffic acceptance certificate.

Use measured isolated-train section traversal envelopes. Opposing trains may
not share a single-line section. Following trains need entrance/exit headway;
do not treat a direction-locked section as one block for same-direction trains.
The full simulation remains authoritative for routes, stations, overtakes and
all wait/safety/call gates. Output is a proposal; it does not edit any pack.
"""
from pathlib import Path
import json, hashlib, numpy as np

root=Path('D:/ClaudeWS/train-game'); local=root/'.local/realism-2026-10-26'
pack=json.loads((root/'art/timetables/kerala-coast-network.json').read_text(encoding='utf-8'))
section_data=json.loads((local/'planning-sections.json').read_text(encoding='utf-8'))
profiles={}
for part in [0,1]:
    data=json.loads((local/f'solo-profiles-{part}.json').read_text(encoding='utf-8'))
    assert len(data['profiles'])==22, 'Wait for all original physical-profile measurements'
    for row in data['profiles']:
        assert row['finished'] and not row['events']
        for id in row['ids']: profiles[id]=row
assert len(profiles)==208
services=pack['services']; n=len(services)
groups=sorted(section_data['groups']); g=len(groups)
origin=np.array([int(s['departure'][:2])*60+int(s['departure'][3:]) for s in services],dtype=float)
direction=np.array([s['stops'][0]['direction'] for s in services])
starts=np.full((n,g),np.nan); ends=np.full((n,g),np.nan)
for i,s in enumerate(services):
    p=profiles[s['id']]
    for key,v in p['intervals'].items():
        group=section_data['sections'][key]['group']
        if not group:continue
        j=groups.index(group)
        a=v['start']/60; b=v['finish']/60
        starts[i,j]=a if np.isnan(starts[i,j]) else min(starts[i,j],a)
        ends[i,j]=b if np.isnan(ends[i,j]) else max(ends[i,j],b)
# One minute on each side is a planning allowance for approach claims/yard
# leads absent from the between-station position envelope, not extra dwell.
starts-=1;ends+=1
present=np.isfinite(starts)
starts=np.nan_to_num(starts);ends=np.nan_to_num(ends)
limits=np.array([0 if s['id']=='K1' else 90 if s['journey']['category'] in ['local','vb'] else 240 for s in services])
fast_class=np.array([s['journey']['category'] in ['superfast','vb'] for s in services])
durations=np.array([(profiles[s['id']]['arrivals'][-1]-180)/60+2 for s in services])
fleet_times=np.arange(0,1440,5)
def fleet_load(plan):
    result=np.zeros(len(fleet_times))
    for day in [-1440,0,1440]:
        result+=np.sum((fleet_times[:,None]>=plan[None,:]+day)&(fleet_times[:,None]<plan[None,:]+durations[None,:]+day),axis=1)
    return result
def costs(i, options, plan, global_limits=True):
    a=options[:,None,None]+starts[i][None,None,:]
    b=options[:,None,None]+ends[i][None,None,:]
    c=plan[None,:,None]+starts[None,:,:]
    d=plan[None,:,None]+ends[None,:,:]
    valid=present[i][None,None,:]&present[None,:,:]
    valid[:,i,:]=False
    opposite=(direction!=direction[i])[None,:,None]
    out=np.zeros(len(options))
    for day in [-1440,0,1440]:
        overlap=np.maximum(0,np.minimum(b,d+day)-np.maximum(a,c+day))
        # Penalize sustained opposing occupation most, while allowing the
        # heuristic to place a crossing at the real intervening passing yard.
        opposing=(overlap+overlap*overlap/8)*opposite
        ds=a-(c+day);de=b-(d+day)
        headway=np.maximum(0,3-np.minimum(np.abs(ds),np.abs(de)))
        catching=np.where(ds*de<0,np.minimum(np.abs(ds),np.abs(de))+3,0)
        following=(headway*2+catching*4)*(~opposite)
        # Failed v9 traffic held the same mail for successive expresses. Space
        # higher-priority arrivals so the first pass can release its followers
        # before a second higher-priority approach starts another long hold.
        # This is origin planning only, never a forced runtime passing site.
        express_gap=np.maximum(0,35-np.minimum(np.abs(ds),np.abs(de)))
        following+=express_gap**2*fast_class[i]*fast_class[None,:,None]*(~opposite)
        out+=np.sum(np.where(valid,opposing+following,0),axis=(1,2))
        for fraction in [.05,.5,.95]:
            at=a+(b-a)*fraction
            same_count=np.sum(valid&(~opposite)&(c+day<=at)&(d+day>=at),axis=1)
            out+=np.sum(np.maximum(0,same_count-1)**2,axis=1)*5
    delta=np.minimum(np.abs(options-origin[i]),1440-np.abs(options-origin[i]))
    out+=delta*.025
    # Preserve the day/night coverage contract during every coordinate move.
    hourly=np.bincount((plan//60).astype(int),minlength=24)
    old_hour=int(plan[i]//60)
    if hourly[old_hour]<=3:
        out+=np.where((options//60).astype(int)==old_hour,0,100000)
    if global_limits:
        # Opposing-conflict minimization alone can create oversized directional
        # batches. Bound overall traffic concentration as well as section use.
        load=fleet_load(plan)
        replacement=np.zeros((len(options),len(fleet_times)))
        for day in [-1440,0,1440]:
            load-=((fleet_times>=plan[i]+day)&(fleet_times<plan[i]+durations[i]+day))
            replacement+=((fleet_times[None,:]>=options[:,None]+day)&(fleet_times[None,:]<options[:,None]+durations[i]+day))
        out+=np.sum(np.maximum(0,load[None,:]+replacement-34)**2,axis=1)*15
        base_hours=hourly.copy();base_hours[old_hour]-=1
        new_hours=(options//60).astype(int)
        out+=np.maximum(0,base_hours[new_hours]+1-13)**2*200
    return out
def objective(plan):
    return float(sum(costs(i,np.array([plan[i]]),plan,False)[0] for i in range(n))/2 + np.sum(np.maximum(0,fleet_load(plan)-34)**2)*15 + np.sum(np.maximum(0,np.bincount((plan//60).astype(int),minlength=24)-13)**2)*200)
rng=np.random.default_rng(260926)
best=origin.copy(); initial=objective(best); score=initial
for restart in range(7):
    plan=best.copy()
    if restart:
        for i in rng.permutation(n):
            if not limits[i]:continue
            candidate=(plan[i]+int(rng.integers(-3,4))*5)%1440
            dist=(candidate-origin[i]+720)%1440-720
            hourly=np.bincount((plan//60).astype(int),minlength=24)
            if abs(dist)<=limits[i] and (int(candidate//60)==int(plan[i]//60) or hourly[int(plan[i]//60)]>3):
                plan[i]=candidate
    for iteration in range(20):
        changes=0
        for i in rng.permutation(n):
            if not limits[i]:continue
            options=(origin[i]+np.arange(-limits[i],limits[i]+.1,5))%1440
            values=costs(i,options,plan)
            selected=float(options[np.argmin(values)])
            if selected!=plan[i]:changes+=1;plan[i]=selected
        value=objective(plan)
        print('search',restart,iteration,'cost',round(value,2),'changes',changes,flush=True)
        if value<score:best=plan.copy();score=value
        if not changes:break
changes=[]
assert min(np.bincount((best//60).astype(int),minlength=24))>=3
for i,s in enumerate(services):
    if best[i]==origin[i]:continue
    minute=int(best[i]);changes.append(dict(service=s['id'],before=s['departure'],after=f'{minute//60:02}:{minute%60:02}',minutes_shift=int((best[i]-origin[i]+720)%1440-720)))
groups_report=[]
for j,name in enumerate(groups):
    ids=np.where(present[:,j])[0]
    groups_report.append(dict(section=name,trains=len(ids),southbound=int(sum(direction[ids]>0)),northbound=int(sum(direction[ids]<0)),sum_individual_envelope_minutes=float(sum(ends[ids,j]-starts[ids,j])),note='Sum includes overlapping permitted same-direction operation; not a one-train capacity limit.'))
result=dict(kind='departure spacing proposal, not validated traffic',inputs={p.name:hashlib.sha256(p.read_bytes()).hexdigest() for p in [local/'planning-sections.json',local/'solo-profiles-0.json',local/'solo-profiles-1.json',root/'art/timetables/kerala-coast-network.json']},initial_cost=initial,proposed_cost=score,changes=changes,sections=groups_report,limitations=['Isolated profiles exclude interaction-induced running delays.','Approach allowance is a planning estimate; full simulation owns actual route and tail clearance.','No calls, dwell, stock, priority, speed or forced passing changes.','A lower heuristic cost does not certify wait distributions or completion.'])
result['express_spacing_planning_target_minutes']=35
result['initial_peak_isolated_fleet']=float(max(fleet_load(origin)))
result['proposed_peak_isolated_fleet']=float(max(fleet_load(best)))
result['hourly_departures']=np.bincount((best//60).astype(int),minlength=24).tolist()
(local/'network-spacing-proposal-v3.json').write_text(json.dumps(result,indent=2)+'\n',encoding='utf-8')
print('PROPOSAL',len(changes),'departure changes',initial,'->',score,flush=True)
