from pathlib import Path
import json,hashlib
root=Path('D:/ClaudeWS/train-game');local=root/'.local/realism-2026-10-26'
old=json.loads((local/'candidate-twenty-five-sampled-groups.json').read_text(encoding='utf-8'))
south=json.loads((local/'candidate-twenty-three-sampled-groups.json').read_text(encoding='utf-8'))
old['bounds'].update({g:south['bounds'][g] for g in ['TVC_single','NEM_single','NYY_single','PASA_single','KZT_single']})
out=dict(kind=old['kind'],bounds=old['bounds'],additional_bound_basis=old['additional_bound_basis']+' Southern static bounds retained from candidate23 sampled-groups.json; geometric envelopes, not legal ownership.',source_candidate='782997ea1e3abf3f6e0f27de3f08c49388b33671',source_evidence='b3f5b3eb96042390ebe6ad32e47d6baa8d596fa3 both original39 failures',formula='At each actual traffic sample, overlap iff max(front,tail)>=bound.start and min(front,tail)<=bound.finish. Each continuous observed overlap is retained separately. Times are first/last overlapping samples, not exact ownership or clearance times.',runs=[])
for name in ['predictive-network','predictive-network-delayed']:
 folder=local/'rehearsals-v39'/name
 active={};intervals=[];first=None;last=None;gap=0;start=0
 for line in (folder/'traffic.jsonl').open(encoding='utf-8'):
  t,positions=json.loads(line)
  if t<start:continue
  if first is None:first=t
  if last is not None:gap=max(gap,t-last)
  last=t;present=set()
  for p in positions:
   for group,b in out['bounds'].items():
    if max(p[2],p[3])<b['start'] or min(p[2],p[3])>b['finish']:continue
    key=(p[0],group);present.add(key)
    if key not in active:active[key]=dict(id=p[0],group=group,direction=p[4],first_sample=t,last_sample=t,samples=0,left_censored=t==first,right_censored=False)
    active[key]['last_sample']=t;active[key]['samples']+=1
  for key in list(active):
   if key not in present:intervals.append(active.pop(key))
 for v in active.values():v['right_censored']=True;intervals.append(v)
 out['runs'].append(dict(run=name,window_start=start,first_sample=first,last_clock=last,max_sample_interval_seconds=gap,traffic_sha256=hashlib.sha256((folder/'traffic.jsonl').read_bytes()).hexdigest(),audit_sha256=hashlib.sha256((folder/'audit.json').read_bytes()).hexdigest(),intervals=sorted(intervals,key=lambda x:(x['first_sample'],x['id'],x['group']))))
(local/'candidate-forty-sampled-groups.json').write_text(json.dumps(out,indent=2)+'\n',encoding='utf-8')