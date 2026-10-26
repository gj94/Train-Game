"""Strict isolated-profile feasibility search. Emits evidence, never edits a pack.

This is an authoring model, not the interlocking or a complete-day certificate.
Runtime traffic must independently validate any resulting departure proposal.
"""
from pathlib import Path
import sys, json, math, hashlib, argparse
root=Path('D:/ClaudeWS/train-game'); local=root/'.local/realism-2026-10-26'
sys.path.insert(0,str(root/'.local/realism-planning-deps'))
import ortools
from ortools.sat.python import cp_model

parser=argparse.ArgumentParser()
parser.add_argument('--seconds',type=int,default=180)
parser.add_argument('--output',default='network-constraint-proposal-v1.json')
parser.add_argument('--full-range',action='store_true')
args=parser.parse_args()
output=local/args.output
assert not output.exists(), 'Preserve previous solver evidence; choose a fresh output'
pack_path=root/'art/timetables/kerala-coast-network.json'
pack=json.loads(pack_path.read_text(encoding='utf-8'));services=pack['services']
section_data=json.loads((local/'planning-sections.json').read_text(encoding='utf-8'))
profiles={}; profile_index={}; profile_rows=[]
for part in [0,1]:
    data=json.loads((local/f'solo-profiles-{part}.json').read_text(encoding='utf-8'))
    for row in data['profiles']:
        assert row['finished'] and not row['events']
        pi=len(profile_rows);profile_rows.append(row)
        for id in row['ids']:profiles[id]=row;profile_index[id]=pi
assert len(profiles)==208

# Physical head/tail occupancy between passing yards, with one minute around
# each end as an approach allowance. This does not change authored dwell.
envelopes=[]
for row in profile_rows:
    spans={}
    for key,value in row['intervals'].items():
        group=section_data['sections'][key]['group']
        if not group:continue
        a=value['start']/60-1; b=value['finish']/60+1
        if group in spans:a=min(a,spans[group][0]);b=max(b,spans[group][1])
        spans[group]=(a,b)
    envelopes.append(spans)

def intervals_from_values(values):
    ranges=[]
    for v in sorted(values):
        if ranges and v==ranges[-1][1]+1:ranges[-1][1]=v
        else:ranges.append([v,v])
    return ranges

domain_cache={}
def separation_domain(pi,pj):
    key=(pi,pj)
    if key in domain_cache:return domain_cache[key]
    a=envelopes[pi];b=envelopes[pj];shared=set(a)&set(b)
    if not shared:return None
    forbidden=set()
    opposite=profile_rows[pi]['direction']!=profile_rows[pj]['direction']
    for group in shared:
        ai,bi=a[group];aj,bj=b[group]
        if opposite:lo,hi=aj-bi,bj-ai
        else:
            # Entrance and exit separation, including a faster follower
            # reversing order within a section that has no passing road.
            x,y=aj-ai,bj-bi;lo,hi=min(x,y)-3,max(x,y)+3
        for day in [-1440,0,1440]:
            forbidden.update(range(max(-1439,math.floor(lo+day)+1),min(1439,math.ceil(hi+day)-1)+1))
    allowed=set(range(-1439,1440))-forbidden
    domain_cache[key]=intervals_from_values(allowed)
    return domain_cache[key]

model=cp_model.CpModel(); starts=[]; original=[]; domains=[]
for s in services:
    h,m=map(int,s['departure'].split(':'));origin=h*60+m;original.append(origin)
    limit=0 if s['id']=='K1' else 720 if args.full_range else 90 if s['journey']['category'] in ['local','vb'] else 240
    values=sorted({(origin+d)%1440 for d in range(-limit,limit+1)})
    dep=model.new_int_var_from_domain(cp_model.Domain.from_values(values),s['id'])
    model.add_hint(dep,origin); starts.append(dep);domains.append(values)

pair_constraints=0
for i,s in enumerate(services):
    for j in range(i):
        allowed=separation_domain(profile_index[s['id']],profile_index[services[j]['id']])
        if allowed is None:continue
        model.add_linear_expression_in_domain(starts[i]-starts[j],cp_model.Domain.from_intervals(allowed))
        pair_constraints+=1

# Spread trains across all 24 hours; hold K1's established departure fixed.
hourly=[[] for _ in range(24)]
for i,dep in enumerate(starts):
    choices=[]
    for hour in sorted({d//60 for d in domains[i]}):
        present=model.new_bool_var(f'{i}_hour_{hour}');choices.append(present)
        model.add(dep>=hour*60).only_enforce_if(present)
        model.add(dep<(hour+1)*60).only_enforce_if(present)
        hourly[hour].append(present)
    model.add_exactly_one(choices)
for row in hourly:model.add(sum(row)>=3);model.add(sum(row)<=13)

# Recurring-day concentration bound includes overnight trains on both sides
# of midnight. Isolated trip duration has a two-minute release allowance.
fleet=[]
for i,s in enumerate(services):
    duration=math.ceil((profiles[s['id']]['arrivals'][-1]-180)/60+2)
    for day in [-1440,0,1440]:
        fleet.append(model.new_interval_var(starts[i]+day,duration,starts[i]+day+duration,f'fleet_{i}_{day}'))
model.add_cumulative(fleet,[1]*len(fleet),34)

solver=cp_model.CpSolver();solver.parameters.max_time_in_seconds=args.seconds
solver.parameters.num_search_workers=8;solver.parameters.random_seed=260926
solver.parameters.log_search_progress=True
print('MODEL',len(starts),'departures',pair_constraints,'pair separation constraints',flush=True)
status=solver.solve(model)
result=dict(kind='strict isolated-profile authoring model; not accepted railway traffic',solver_version=ortools.__version__,status=solver.status_name(status),wall_seconds=solver.wall_time,pair_constraints=pair_constraints,full_range=args.full_range,pack_sha256=hashlib.sha256(pack_path.read_bytes()).hexdigest(),limits=['One-minute section-end planning allowance; not authored dwell.','Three-minute entrance/exit separation and no catching inside a shared section.','Isolated profiles exclude dispatch and receiving-road delays.','A feasible plan still needs genuine baseline/disturbance acceptance; UNKNOWN is not an infeasibility proof.'],search_statistics=solver.response_stats())
if status in [cp_model.FEASIBLE,cp_model.OPTIMAL]:
    plan=[solver.value(x) for x in starts]
    for i,s in enumerate(services):
        for j in range(i):
            allowed=separation_domain(profile_index[s['id']],profile_index[services[j]['id']])
            assert allowed is None or any(a<=plan[i]-plan[j]<=b for a,b in allowed)
    result['departures']={s['id']:f'{plan[i]//60:02}:{plan[i]%60:02}' for i,s in enumerate(services)}
    result['hourly_departures']=[sum(d//60==h for d in plan) for h in range(24)]
    result['changed_departures']=sum(a!=b for a,b in zip(plan,original))
output.write_text(json.dumps(result,indent=2)+'\n',encoding='utf-8')
print('RESULT',result['status'],result.get('changed_departures'),flush=True)
