from pathlib import Path
from datetime import datetime, timezone, timedelta
import hashlib, json, subprocess
root=Path('D:/ClaudeWS/train-game')
local=root/'.local/realism-2026-10-26'
jobs=json.loads((local/'rehearsal-jobs-v34.json').read_text(encoding='utf-8-sig'))
assert len({j['output'] for j in jobs})==2
assert len(jobs)==2 and {j['day'] for j in jobs}=={'predictive-network','predictive-network-delayed'}
shell='C:/Users/Gokul/.cache/codex-runtimes/codex-primary-runtime/dependencies/native/powershell/pwsh.exe'
raw=subprocess.check_output([shell,'-NoProfile','-Command',"Get-CimInstance Win32_Process | Where-Object { $_.Name -like 'Godot*' } | Select-Object ProcessId,ParentProcessId,CommandLine | ConvertTo-Json -Depth 3"],text=True,encoding='utf-8')
processes=json.loads(raw);rows=[];hashes={}
for job in jobs:
    expected='--output=res://'+job['output']
    selected=[p for p in processes if p['ProcessId']==job['pid'] or p['ParentProcessId']==job['pid']]
    assert len(selected)==2,(job['day'],selected)
    for p in selected:
        cmd=p['CommandLine'];assert expected in cmd and cmd.count('--output=')==1 and '--output= ' not in cmd
        assert 'res://tools/prepare_timetable_variant.gd' in cmd
        for arg in job['options']:assert arg in cmd,(job['day'],arg)
    folder=root/job['output'];assert not (folder/'run.err').read_text(encoding='utf-8-sig').strip()
    cat=folder/'starts/catalogue.json'
    if '--snapshots' in job['options']:
        data=json.loads(cat.read_text(encoding='utf-8-sig'))
        expected_mode='predictive' if job['day'].startswith('predictive') else 'classic'
        assert data['dispatcher']==expected_mode
        expected_ids=sorted(s['id'] for s in json.loads((root/'art/timetables/kerala-coast-network-v2.json').read_text())['services'])
        assert len(expected_ids)==200
        assert hashlib.sha256((root/'art/timetables/kerala-coast-network-v2.json').read_bytes()).hexdigest()==job['pack_sha256']
        for name,digest in data['sources'].items():
            if name not in hashes:
                p=root/name
                raw=p.read_bytes() if name.endswith('.bin') else p.read_text(encoding='utf-8').replace('\r\n','\n').encode('utf-8')
                hashes[name]=hashlib.sha256(raw).hexdigest()
            assert hashes[name]==digest,name
        count=len(data['sources']);assert count==4836
    else:count=None
    job['child_pid']=next(p['ProcessId'] for p in selected if p['ParentProcessId']==job['pid'])
    rows.append(dict(day=job['day'],processes=selected,source_hashes=count,stderr_empty=True))
observers=['tools/prepare_timetable_variant.gd','tools/wait_quality.gd','tools/lib/wait-quality.mjs','tools/record_service_traffic.gd','tools/lib/traffic-encounters.mjs','tools/finalize_timetable_variant.mjs']
report=dict(checked_at=datetime.now(timezone(timedelta(hours=8))).isoformat(),jobs=rows,observer_hashes={p:hashlib.sha256((root/p).read_text(encoding='utf-8').replace('\r\n','\n').encode('utf-8')).hexdigest() for p in observers})
report['acceptance_hashes']={p:hashlib.sha256((root/p).read_text(encoding='utf-8').replace('\r\n','\n').encode()).hexdigest() for p in ['tools/finalize_network_timetable.mjs','tools/lib/network-population.mjs','tools/verify_disturbed_timetable.mjs','tools/verify-timetable-variants.mjs','art/timetables/kerala-coast-network-service-selection.json']}
report['population']=200
previous=json.loads((local/'launch-v33-verification.json').read_text())
assert report['observer_hashes']==previous['observer_hashes'],'Original observer bytes changed'
assert report['acceptance_hashes']==previous['acceptance_hashes'],'Acceptance/selection bytes changed'
assert not (local/'launch-v34-verification.json').exists(),'Launch verification already exists'
(local/'rehearsal-jobs-v34.json').write_text(json.dumps(jobs,indent=2)+'\n',encoding='utf-8')
(local/'launch-v34-verification.json').write_text(json.dumps(report,indent=2)+'\n',encoding='utf-8')
(local/'owned-processes.json').write_text(json.dumps(processes,indent=2)+'\n',encoding='utf-8')
print(json.dumps(dict(verified_jobs=len(rows),wrappers_and_children=sum(len(r['processes']) for r in rows),unique_source_hashes=len(hashes),observer_hashes=len(observers))))
