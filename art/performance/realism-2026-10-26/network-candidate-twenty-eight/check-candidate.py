from pathlib import Path
from collections import Counter
import json,copy,hashlib
root=Path('D:/ClaudeWS/train-game');local=root/'.local/realism-2026-10-26'
proof=dict(identical_modes=True,K1='06:00',packs=[])
expected={'M053': ('15:00', '15:40'), 'M015': ('15:15', '15:50'), 'M021': ('15:30', '16:00'), 'M025': ('16:05', '16:25'), 'L003': ('16:20', '16:50'), 'L011': ('16:45', '16:55'), 'L009': ('17:00', '17:15'), 'M097': ('14:45', '15:30'), 'S051': ('15:40', '17:20'), 'S049': ('16:10', '17:40'), 'S053': ('16:10', '18:00'), 'M081': ('17:10', '19:00'), 'M085': ('17:30', '19:20'), 'M087': ('18:00', '19:40'), 'M083': ('19:00', '20:00'), 'L037': ('19:20', '20:20')}
current=[]
for name in ['kerala-coast-network.json','kerala-coast-network-v2.json']:
 p=root/'art/timetables'/name;before=local/'candidate-twenty-eight-before'/name
 new=json.loads(p.read_text(encoding='utf-8'));old=json.loads(before.read_text(encoding='utf-8'));restored=copy.deepcopy(new)
 byid={s['id']:s for s in old['services']};changes=[]
 for s in restored['services']:
  prev=byid[s['id']]['departure']
  if prev!=s['departure']:
   assert expected[s['id']]==(prev,s['departure'])
   changes.append(dict(id=s['id'],before=prev,after=s['departure']));s['departure']=prev
 assert restored==old and len(changes)==16
 assert len(new['services'])==208 and next(s for s in new['services'] if s['id']=='K1')['departure']=='06:00'
 hourly=Counter(int(s['departure'][:2]) for s in new['services']);assert min(hourly.values())>=3 and max(hourly.values())<=13 and len(hourly)==24
 proof['packs'].append(dict(pack=name,sha256=hashlib.sha256(p.read_bytes()).hexdigest(),predecessor_sha256=hashlib.sha256(before.read_bytes()).hexdigest(),only_departures_changed=True,changes=changes,services=len(new['services']),categories=dict(Counter(s['journey']['category'] for s in new['services'])),overnight=sum(int(s['departure'][:2])<6 or int(s['departure'][:2])>=22 for s in new['services']),hourly=[hourly[h] for h in range(24)]))
 current.append(new)
assert current[0]['services']==current[1]['services']
(local/'candidate-twenty-eight-field-proof.json').write_text(json.dumps(proof,indent=2)+'\n',encoding='utf-8')
print(json.dumps(proof))
