from pathlib import Path
import json,hashlib,shutil
root=Path('D:/ClaudeWS/train-game');base=root/'.local/realism-2026-10-26';archive=base/'candidate-ten-before'
assert not archive.exists(),'Candidate-ten application already started; inspect rather than repeat'
proposal=json.loads((base/'network-spacing-proposal-v5-polished.json').read_text(encoding='utf-8'))
for name,digest in proposal['inputs'].items():
    p=root/'art/timetables'/name if name.startswith('kerala-coast') else base/name
    assert hashlib.sha256(p.read_bytes()).hexdigest()==digest,name
paths=[root/'art/timetables'/name for name in ['kerala-coast-network.json','kerala-coast-network-v2.json','kerala-coast-network-departure-overrides.json']]
packs=[json.loads(p.read_text(encoding='utf-8')) for p in paths[:2]]
assert packs[0]['services']==packs[1]['services']
existing=json.loads(paths[2].read_text(encoding='utf-8'));original={r['service']:r['from'] for r in existing['changes']}
services={s['id']:s for s in packs[0]['services']};new_times={s['id']:s['departure'] for s in packs[0]['services']}
for edit in proposal['changes']:
    assert services[edit['service']]['departure']==edit['before']
    new_times[edit['service']]=edit['after']
assert new_times['K1']=='06:00'
reason='Network candidate ten: departure-only plan using isolated physical section profiles, static compatible receiving roads, following separation and express approach spacing. One nominal berth-minute and increased opposing overlaps remain explicit model limits; genuine baseline and disturbance acceptance required. Calls, dwell, stock, priorities and speeds unchanged.'
changes=[]
for sid,s in services.items():
    origin=original.get(sid,s['departure'])
    if new_times[sid]!=origin:changes.append(dict(service=sid,**{'from':origin,'to':new_times[sid]},reason=reason))
archive.mkdir()
for p in paths:shutil.copyfile(p,archive/p.name)
paths[2].write_text(json.dumps(dict(format=existing['format'],version=existing['version'],changes=changes),indent=2,ensure_ascii=False)+'\n',encoding='utf-8')
(base/'candidate-ten-expected-times.json').write_text(json.dumps(new_times,indent=2)+'\n',encoding='utf-8')
print('Wrote',len(changes),'author-source departure overrides; packs await normal authoring')
