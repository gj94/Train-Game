from pathlib import Path
from collections import Counter
import json,copy,hashlib
root=Path('D:/ClaudeWS/train-game');local=root/'.local/realism-2026-10-26'
proof=dict(identical_modes=True,K1='06:00',packs=[])
expected={'M072': ('18:05', '18:50'), 'M054': ('18:20', '19:05'), 'M098': ('18:50', '19:20'), 'M090': ('19:05', '19:35'), 'M104': ('19:20', '19:50'), 'M088': ('19:35', '20:05'), 'M058': ('19:50', '20:20'), 'M056': ('20:05', '20:35'), 'L028': ('20:20', '20:50'), 'L030': ('20:40', '21:10'), 'L038': ('21:00', '21:30'), 'L032': ('21:20', '21:50'), 'S051': ('18:30', '19:30'), 'S049': ('18:50', '19:50'), 'S053': ('19:10', '20:10'), 'M081': ('19:40', '20:40'), 'M085': ('20:00', '21:00'), 'M087': ('20:20', '21:20'), 'M083': ('20:40', '21:40'), 'M091': ('21:00', '22:15'), 'M073': ('21:10', '22:30'), 'M089': ('21:20', '22:45'), 'L037': ('21:00', '23:15')}
current=[]
for name in ['kerala-coast-network.json','kerala-coast-network-v2.json']:
 p=root/'art/timetables'/name;before=local/'candidate-thirty-one-before'/name
 new=json.loads(p.read_text(encoding='utf-8'));old=json.loads(before.read_text(encoding='utf-8'));restored=copy.deepcopy(new)
 byid={s['id']:s for s in old['services']};changes=[]
 for s in restored['services']:
  prev=byid[s['id']]['departure']
  if prev!=s['departure']:
   assert expected[s['id']]==(prev,s['departure'])
   changes.append(dict(id=s['id'],before=prev,after=s['departure']));s['departure']=prev
 assert restored==old and len(changes)==23
 assert len(new['services'])==208 and next(s for s in new['services'] if s['id']=='K1')['departure']=='06:00'
 hourly=Counter(int(s['departure'][:2]) for s in new['services']);assert min(hourly.values())>=3 and max(hourly.values())<=13 and len(hourly)==24
 proof['packs'].append(dict(pack=name,sha256=hashlib.sha256(p.read_bytes()).hexdigest(),predecessor_sha256=hashlib.sha256(before.read_bytes()).hexdigest(),only_departures_changed=True,changes=changes,services=len(new['services']),categories=dict(Counter(s['journey']['category'] for s in new['services'])),overnight=sum(int(s['departure'][:2])<6 or int(s['departure'][:2])>=22 for s in new['services']),hourly=[hourly[h] for h in range(24)]))
 current.append(new)
assert current[0]['services']==current[1]['services']
(local/'candidate-thirty-one-field-proof.json').write_text(json.dumps(proof,indent=2)+'\n',encoding='utf-8')
print(json.dumps(proof))
