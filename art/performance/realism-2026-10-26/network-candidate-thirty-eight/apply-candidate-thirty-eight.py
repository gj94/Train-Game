from pathlib import Path
import json,subprocess,hashlib
root=Path('D:/ClaudeWS/train-game');local=root/'.local/realism-2026-10-26';archive=local/'candidate-thirty-eight-before'
shell='C:/Users/Gokul/.cache/codex-runtimes/codex-primary-runtime/dependencies/native/powershell/pwsh.exe'
assert subprocess.check_output([shell,'-NoProfile','-Command',"@(Get-CimInstance Win32_Process | Where-Object {$_.Name -like 'Godot*'}).Count"],text=True).strip()=='0'
plan=json.loads((local/'candidate-thirty-eight-plan.json').read_text())
for name,digest in plan['predecessors'].items():
 p=root/'art/timetables'/name
 assert hashlib.sha256(p.read_bytes()).hexdigest()==digest
 assert p.read_bytes()==(archive/name).read_bytes()
 committed=subprocess.check_output(['git','-c','safe.directory=D:/ClaudeWS/train-game','show','HEAD:'+p.relative_to(root).as_posix()])
 assert json.loads(committed)==json.loads(p.read_bytes())
services={s['id']:s for s in json.loads((archive/'kerala-coast-network-v2.json').read_text())['services']}
p=root/'art/timetables/kerala-coast-network-departure-overrides.json';data=json.loads(p.read_text())
for c in plan['changes']:
 assert services[c['service']]['departure']==c['before']
 rows=[r for r in data['changes'] if r['service']==c['service']];assert len(rows)==1
 rows[0]['to']=c['after'];rows[0]['reason']='Network candidate thirty-eight, V2-only: '+c['reason']+' Departure-only hypothesis; both complete V2 tests remain required.'
p.write_bytes((json.dumps(data,ensure_ascii=False,indent=2)+'\n').encode('utf-8'))
print('Two coordinated departure changes prepared; no non-departure or population change')
