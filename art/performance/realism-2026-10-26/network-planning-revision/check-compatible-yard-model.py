"""Compare direct bipartite berth matching with authoring subset constraints.

This uses the same conservative isolated visit envelopes, not actual traffic.
The assignment check is independent of the cumulative cost implementation.
"""
from pathlib import Path
import json, numpy as np, hashlib, argparse
base=Path('D:/ClaudeWS/train-game/.local/realism-2026-10-26')
args=argparse.ArgumentParser();args.add_argument('--proposal',default='network-spacing-proposal-v4.json');args.add_argument('--output',default='compatible-yard-v4-review.json');a=args.parse_args()
source=(base/'plan-network-spacing-v5.py').read_text(encoding='utf-8').split('rng=np.random.default_rng')[0]
c={};exec(compile(source,'static-yard-inputs','exec'),c)
proposal=json.loads((base/a.proposal).read_text(encoding='utf-8'))
assert proposal['inputs']['kerala-coast-network.json']==c['berth_data']['pack_sha256']
before=c['origin'].copy();after=before.copy()
for row in proposal['changes']:
    i=next(i for i,s in enumerate(c['services']) if s['id']==row['service'])
    assert c['services'][i]['departure']==row['before']
    after[i]=int(row['after'][:2])*60+int(row['after'][3:])
def matching(claims):
    owners={}
    def assign(i,seen):
        for road in sorted(claims[i]):
            if road in seen:continue
            seen.add(road)
            if road not in owners or assign(owners[road],seen):owners[road]=i;return True
        return False
    return all(assign(i,set()) for i in sorted(claims,key=lambda i:len(claims[i])))
def review(plan):
    load=c['yard_load'](plan);rows=[];checks=0
    for yard in c['yard_data']:
        code=yard['code'];indices=[i for i,s in enumerate(c['services']) if (i,code) in c['visits']]
        occupied=np.zeros((len(indices),1440),dtype=bool)
        for k,i in enumerate(indices):
            start,end,roads=c['visits'][(i,code)]
            for day in [-1440,0,1440]:
                lo=max(0,min(1440,int(np.floor(plan[i]+start+day))));hi=max(0,min(1440,int(np.ceil(plan[i]+end+day))))
                occupied[k,lo:hi]=True
        resources=[j for j,r in enumerate(c['resources']) if r['station']==code]
        constraint_failure=np.any(load[resources]>c['yard_caps'][resources,None],axis=0) if resources else np.zeros(1440,dtype=bool)
        failed=[];examples=[]
        for minute in range(1440):
            claims={indices[k]:c['visits'][(indices[k],code)][2] for k in np.where(occupied[:,minute])[0]}
            matched=matching(claims)
            assert matched!=bool(constraint_failure[minute]),(code,minute,claims,'Hall/matching disagreement')
            checks+=1
            if not matched:
                failed.append(minute)
                if len(examples)<3 and (not examples or minute>examples[-1]['minute']+10):examples.append(dict(minute=minute,claims={c['services'][i]['id']:sorted(roads) for i,roads in claims.items()}))
        rows.append(dict(station=code,failed_nominal_minute_cells=len(failed),examples=examples))
    return dict(direct_matching_vs_subset_checks=checks,failed_yard_minute_cells=sum(r['failed_nominal_minute_cells'] for r in rows),yards_with_failures=sum(r['failed_nominal_minute_cells']>0 for r in rows),yards=rows)
out=dict(kind='Direct static berth matching against isolated-profile minute envelopes, not traffic acceptance',proposal=a.proposal,proposal_sha256=hashlib.sha256((base/a.proposal).read_bytes()).hexdigest(),road_inventory_sha256=hashlib.sha256((base/'planning-berths-v2.json').read_bytes()).hexdigest(),origin_upper_bound_fallbacks=len(c['fallback']),before=review(before),after=review(after),limitations=['Minute cells include any occupied fraction; they are conservative planning estimates.','No interaction-induced holds, route reservations or escape guarantees are represented.','Origin supply uses physical passenger-road upper bounds; static receiving compatibility applies to other visits.','Summed failed yard-minute cells are not observed train waiting time.'])
(base/a.output).write_text(json.dumps(out,indent=2)+'\n',encoding='utf-8')
for label in ['before','after']:print(label,{k:v for k,v in out[label].items() if k!='yards'})
