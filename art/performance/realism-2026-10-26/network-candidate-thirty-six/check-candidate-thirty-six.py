from pathlib import Path
from collections import Counter
import json,copy,hashlib
root=Path('D:/ClaudeWS/train-game');local=root/'.local/realism-2026-10-26'
proof=dict(identical_modes=True,K1='06:00',unchanged_selection=True,maximum_hourly_is_descriptive_not_acceptance_gate=True,packs=[])
assert (root/'art/timetables/kerala-coast-network-service-selection.json').read_bytes()==(local/'candidate-thirty-six-before/kerala-coast-network-service-selection.json').read_bytes()
expected={'M033':('20:30','21:25')}
current=[]
for name in ['kerala-coast-network.json','kerala-coast-network-v2.json']:
 p=root/'art/timetables'/name;before=local/'candidate-thirty-six-before'/name
 new=json.loads(p.read_text(encoding='utf-8'));old=json.loads(before.read_text(encoding='utf-8'));restored=copy.deepcopy(new)
 byid={s['id']:s for s in old['services']};changes=[]
 for s in restored['services']:
  prev=byid[s['id']]['departure']
  if prev!=s['departure']:
   assert expected[s['id']]==(prev,s['departure'])
   changes.append(dict(id=s['id'],before=prev,after=s['departure']));s['departure']=prev
 assert restored==old and len(changes)==1
 assert len(new['services'])==200 and next(s for s in new['services'] if s['id']=='K1')['departure']=='06:00'
 hourly=Counter(int(s['departure'][:2]) for s in new['services']);assert min(hourly.values())>=3 and len(hourly)==24
 proof['packs'].append(dict(pack=name,sha256=hashlib.sha256(p.read_bytes()).hexdigest(),predecessor_sha256=hashlib.sha256(before.read_bytes()).hexdigest(),only_departures_changed=True,changes=changes,services=len(new['services']),categories=dict(Counter(s['journey']['category'] for s in new['services'])),overnight=sum(int(s['departure'][:2])<6 or int(s['departure'][:2])>=22 for s in new['services']),hourly=[hourly[h] for h in range(24)]))
 current.append(new)
assert current[0]['services']==current[1]['services']
(local/'candidate-thirty-six-field-proof.json').write_text(json.dumps(proof,indent=2)+'\n',encoding='utf-8')
print(json.dumps(proof))
