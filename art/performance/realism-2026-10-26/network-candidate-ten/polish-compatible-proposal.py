"""Small departure-only repair of the three residual nominal berth clashes.

Produces a candidate for real replay, never a traffic acceptance certificate.
"""
from pathlib import Path
import json, numpy as np, hashlib
base=Path('D:/ClaudeWS/train-game/.local/realism-2026-10-26')
c={};source=(base/'plan-network-spacing-v5.py').read_text(encoding='utf-8').split('rng=np.random.default_rng')[0];exec(compile(source,'static-planning-input','exec'),c)
seed=json.loads((base/'network-spacing-proposal-v5.json').read_text(encoding='utf-8'))
services=c['services'];index={s['id']:i for i,s in enumerate(services)}
plan=c['origin'].copy()
for row in seed['changes']:
    assert services[index[row['service']]]['departure']==row['before']
    plan[index[row['service']]]=int(row['after'][:2])*60+int(row['after'][3:])
initial=plan.copy();fixes=[]
def safe_following(i,minute):
    for j in range(len(services)):
        if i==j or c['direction'][i]!=c['direction'][j]:continue
        shared=c['present'][i]&c['present'][j]
        if not np.any(shared):continue
        for day in [-1440,0,1440]:
            ds=minute+c['starts'][i,shared]-plan[j]-day-c['starts'][j,shared]
            de=minute+c['ends'][i,shared]-plan[j]-day-c['ends'][j,shared]
            if np.any(ds*de<0):return False
            if c['fast_class'][i] and c['fast_class'][j] and np.any(np.minimum(abs(ds),abs(de))<30):return False
    return True
for iteration in range(12):
    current=c['yard_cost'](plan)
    if current==0:break
    load=c['yard_load'](plan);resources=np.where(np.any(load>c['yard_caps'][:,None],axis=1))[0]
    implicated=set()
    for j in resources:
        bad=np.where(load[j]>c['yard_caps'][j])[0]
        for i in np.where(c['yard_present'][:,j])[0]:
            for day in [-1440,0,1440]:
                lo=int(np.floor(plan[i]+c['yard_a'][i,j]+day));hi=int(np.ceil(plan[i]+c['yard_b'][i,j]+day))
                if np.any((bad>=lo)&(bad<hi)):implicated.add(i)
    best=None
    for i in sorted(implicated):
        if services[i]['id']=='K1':continue
        options=(plan[i]+np.arange(-15,16))%1440
        delta=c['yard_cost_options'](i,options,plan)-c['yard_cost_options'](i,np.array([plan[i]]),plan)[0]
        scores=c['costs'](i,options,plan)
        for k,minute in enumerate(options):
            if delta[k]>=0 or not safe_following(i,minute):continue
            distance=abs((minute-c['origin'][i]+720)%1440-720)
            if distance>c['limits'][i]:continue
            trial=plan.copy();trial[i]=minute;hours=np.bincount((trial//60).astype(int),minlength=24)
            if min(hours)<3 or max(hours)>13:continue
            key=(current+delta[k],float(scores[k]),abs(minute-plan[i]))
            if best is None or key<best[0]:best=(key,i,minute)
    print('repair iteration',iteration,'current penalty',current,'previous repairs',fixes,flush=True)
    if best is None:break # Retain explicit residual estimate; real wait gates remain unchanged.
    key,i,minute=best;fixes.append(dict(service=services[i]['id'],before_minutes=int(plan[i]),after_minutes=int(minute),remaining_nominal_yard_penalty=key[0]));plan[i]=minute
assert c['yard_cost'](plan)<=80 # At most one nominal yard-minute, not a traffic gate.
changes=[]
for i,s in enumerate(services):
    if plan[i]==c['origin'][i]:continue
    m=int(plan[i]);changes.append(dict(service=s['id'],before=s['departure'],after=f'{m//60:02}:{m%60:02}',minutes_shift=int((m-c['origin'][i]+720)%1440-720)))
result=dict(kind='Departure-only candidate for genuine replay; not accepted traffic',inputs=dict(seed['inputs']),changes=changes,local_repairs=fixes,initial_yard_penalty=c['yard_cost'](initial),proposed_yard_penalty=c['yard_cost'](plan),proposed_peak_isolated_fleet=float(max(c['fleet_load'](plan))),hourly_departures=np.bincount((plan//60).astype(int),minlength=24).tolist(),limits=seed['limitations']+['Opposing overlap increased versus candidate nine; no claim of improved actual performance.','One nominal TVC yard-minute remains after two small origin repairs; real full-day wait gates are unchanged.', 'Compatible-yard estimates do not cover interaction-induced queues, escape or protected routes.'])
result['inputs']['network-spacing-proposal-v5.json']=hashlib.sha256((base/'network-spacing-proposal-v5.json').read_bytes()).hexdigest()
(base/'network-spacing-proposal-v5-polished.json').write_text(json.dumps(result,indent=2)+'\n',encoding='utf-8');print('REPAIRS',json.dumps(fixes),'TOTAL CHANGES',len(changes))
