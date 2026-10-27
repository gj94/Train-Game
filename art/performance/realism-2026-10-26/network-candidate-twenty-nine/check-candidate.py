from pathlib import Path
from collections import Counter
import json,copy,hashlib
root=Path('D:/ClaudeWS/train-game');local=root/'.local/realism-2026-10-26'
proof=dict(identical_modes=True,K1='06:00',packs=[])
expected={'V003': ('15:50', '16:35'), 'S033': ('16:00', '16:45'), 'M015': ('15:50', '16:55'), 'M021': ('16:00', '17:10'), 'M025': ('16:25', '17:25'), 'S017': ('16:35', '17:40'), 'S035': ('17:45', '18:00'), 'M067': ('17:50', '18:15'), 'M057': ('18:00', '18:30'), 'M069': ('18:15', '18:45'), 'S019': ('18:40', '19:00'), 'L003': ('16:50', '19:20'), 'L011': ('16:55', '19:40'), 'L009': ('17:15', '20:00'), 'M055': ('18:45', '20:15'), 'M033': ('18:55', '20:30'), 'M027': ('19:05', '20:45'), 'M031': ('19:20', '21:00'), 'M029': ('19:30', '21:15'), 'M035': ('19:40', '21:30')}
current=[]
for name in ['kerala-coast-network.json','kerala-coast-network-v2.json']:
 p=root/'art/timetables'/name;before=local/'candidate-twenty-nine-before'/name
 new=json.loads(p.read_text(encoding='utf-8'));old=json.loads(before.read_text(encoding='utf-8'));restored=copy.deepcopy(new)
 byid={s['id']:s for s in old['services']};changes=[]
 for s in restored['services']:
  prev=byid[s['id']]['departure']
  if prev!=s['departure']:
   assert expected[s['id']]==(prev,s['departure'])
   changes.append(dict(id=s['id'],before=prev,after=s['departure']));s['departure']=prev
 assert restored==old and len(changes)==20
 assert len(new['services'])==208 and next(s for s in new['services'] if s['id']=='K1')['departure']=='06:00'
 hourly=Counter(int(s['departure'][:2]) for s in new['services']);assert min(hourly.values())>=3 and max(hourly.values())<=13 and len(hourly)==24
 proof['packs'].append(dict(pack=name,sha256=hashlib.sha256(p.read_bytes()).hexdigest(),predecessor_sha256=hashlib.sha256(before.read_bytes()).hexdigest(),only_departures_changed=True,changes=changes,services=len(new['services']),categories=dict(Counter(s['journey']['category'] for s in new['services'])),overnight=sum(int(s['departure'][:2])<6 or int(s['departure'][:2])>=22 for s in new['services']),hourly=[hourly[h] for h in range(24)]))
 current.append(new)
assert current[0]['services']==current[1]['services']
(local/'candidate-twenty-nine-field-proof.json').write_text(json.dumps(proof,indent=2)+'\n',encoding='utf-8')
print(json.dumps(proof))
