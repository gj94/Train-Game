from pathlib import Path
from collections import Counter
import json,copy,hashlib
root=Path('D:/ClaudeWS/train-game');local=root/'.local/realism-2026-10-26'
proof=dict(identical_modes=True,K1='06:00',packs=[])
expected={'S038': ('17:10', '17:50'), 'M072': ('16:55', '18:05'), 'M054': ('17:00', '18:20'), 'V008': ('18:25', '18:35'), 'M098': ('17:50', '18:50'), 'M090': ('18:00', '19:05'), 'M104': ('18:30', '19:20'), 'M088': ('18:40', '19:35'), 'M058': ('18:55', '19:50'), 'M056': ('19:10', '20:05'), 'L028': ('17:20', '20:20'), 'L030': ('17:25', '20:40'), 'L038': ('17:35', '21:00'), 'L032': ('19:25', '21:20'), 'S051': ('17:20', '18:30'), 'S049': ('17:40', '18:50'), 'S053': ('18:00', '19:10'), 'M081': ('19:00', '19:40'), 'M085': ('19:20', '20:00'), 'M087': ('19:40', '20:20'), 'M083': ('20:00', '20:40'), 'L037': ('20:20', '21:00')}
current=[]
for name in ['kerala-coast-network.json','kerala-coast-network-v2.json']:
 p=root/'art/timetables'/name;before=local/'candidate-thirty-before'/name
 new=json.loads(p.read_text(encoding='utf-8'));old=json.loads(before.read_text(encoding='utf-8'));restored=copy.deepcopy(new)
 byid={s['id']:s for s in old['services']};changes=[]
 for s in restored['services']:
  prev=byid[s['id']]['departure']
  if prev!=s['departure']:
   assert expected[s['id']]==(prev,s['departure'])
   changes.append(dict(id=s['id'],before=prev,after=s['departure']));s['departure']=prev
 assert restored==old and len(changes)==22
 assert len(new['services'])==208 and next(s for s in new['services'] if s['id']=='K1')['departure']=='06:00'
 hourly=Counter(int(s['departure'][:2]) for s in new['services']);assert min(hourly.values())>=3 and max(hourly.values())<=13 and len(hourly)==24
 proof['packs'].append(dict(pack=name,sha256=hashlib.sha256(p.read_bytes()).hexdigest(),predecessor_sha256=hashlib.sha256(before.read_bytes()).hexdigest(),only_departures_changed=True,changes=changes,services=len(new['services']),categories=dict(Counter(s['journey']['category'] for s in new['services'])),overnight=sum(int(s['departure'][:2])<6 or int(s['departure'][:2])>=22 for s in new['services']),hourly=[hourly[h] for h in range(24)]))
 current.append(new)
assert current[0]['services']==current[1]['services']
(local/'candidate-thirty-field-proof.json').write_text(json.dumps(proof,indent=2)+'\n',encoding='utf-8')
print(json.dumps(proof))
