from pathlib import Path
base=Path('D:/ClaudeWS/train-game/.local/realism-2026-10-26')
source=(base/'plan-network-spacing-v3.py').read_text(encoding='utf-8')
yard_code='''
# Receiving-yard upper-bound screen. This is an isolated-profile estimate;
# real road connectivity, protected routes and held trains remain authoritative.
yard_data=[y for y in json.loads((local/'planning-yards.json').read_text(encoding='utf-8'))['stations'] if not y['through_halt']]
yard_caps=np.array([len(y['roads']) for y in yard_data])
yard_a=np.full((n,len(yard_data)),np.nan);yard_b=yard_a.copy()
for i,s in enumerate(services):
    p=profiles[s['id']]
    for j,y in enumerate(yard_data):
        inbound=[];outbound=[];code=y['code']
        for key,v in p['intervals'].items():
            f,t=key.split('-')
            if p['direction']<0:f,t=t,f
            if t==code:inbound.append(v['finish']/60)
            if f==code:outbound.append(v['start']/60)
        for k,call in enumerate(s['stops']):
            if call['block'].split('_P')[0]!=code:continue
            if p['arrivals'][k]>=0:inbound.append((p['arrivals'][k]-180)/60)
            if p['departures'][k]>=0:outbound.append((p['departures'][k]-180)/60)
        if not inbound and not outbound:continue
        yard_a[i,j]=(min(inbound) if inbound else min(outbound))-1
        yard_b[i,j]=(max(outbound) if outbound else max(inbound))+1
yard_present=np.isfinite(yard_a)
yard_a=np.nan_to_num(yard_a);yard_b=np.nan_to_num(yard_b)
def yard_load(plan,omit=-1):
    # Minute cells conservatively include any occupied portion of a minute.
    counts=np.zeros((len(yard_data),1441),dtype=np.int16)
    rows,columns=np.where(yard_present)
    keep=rows!=omit;rows=rows[keep];columns=columns[keep]
    for day in [-1440,0,1440]:
        lo=np.clip(np.floor(plan[rows]+yard_a[rows,columns]+day),0,1440).astype(int)
        hi=np.clip(np.ceil(plan[rows]+yard_b[rows,columns]+day),0,1440).astype(int)
        np.add.at(counts,(columns,lo),1);np.add.at(counts,(columns,hi),-1)
    return counts.cumsum(axis=1)[:,:1440]
def yard_cost_options(i,options,plan):
    counts=yard_load(plan,omit=i)
    incremental=np.maximum(0,counts+1-yard_caps[:,None])**2-np.maximum(0,counts-yard_caps[:,None])**2
    prefix=np.pad(incremental.cumsum(axis=1),((0,0),(1,0)))
    cols=np.where(yard_present[i])[0];total=np.zeros(len(options))
    for day in [-1440,0,1440]:
        lo=np.clip(np.floor(options[:,None]+yard_a[i,cols][None,:]+day),0,1440).astype(int)
        hi=np.clip(np.ceil(options[:,None]+yard_b[i,cols][None,:]+day),0,1440).astype(int)
        total+=(prefix[cols[None,:],hi]-prefix[cols[None,:],lo]).sum(axis=1)*80
    return total
def yard_cost(plan):return float(np.sum(np.maximum(0,yard_load(plan)-yard_caps[:,None])**2)*80)
'''
assert 'def costs(' in source
source=source.replace('def costs(',yard_code+'\ndef costs(',1)
source=source.replace('opposing=(overlap+overlap*overlap/8)*opposite','opposing=(overlap+overlap*overlap/8)*opposite*3')
source=source.replace('if global_limits:\n        # Opposing','if global_limits:\n        out+=yard_cost_options(i,options,plan)\n        # Opposing')
source=source.replace('return float(sum(costs','return yard_cost(plan)+float(sum(costs')
source=source.replace('rng=np.random.default_rng(260926)','rng=np.random.default_rng(260927)')
source=source.replace('best=origin.copy(); initial=objective(best); score=initial', '''seed=json.loads((local/'network-spacing-proposal-v3.json').read_text(encoding='utf-8'))
assert seed['inputs']['kerala-coast-network.json']==hashlib.sha256((root/'art/timetables/kerala-coast-network.json').read_bytes()).hexdigest()
best=origin.copy()
for change in seed['changes']:
    i=next(i for i,s in enumerate(services) if s['id']==change['service'])
    assert services[i]['departure']==change['before']
    best[i]=int(change['after'][:2])*60+int(change['after'][3:])
initial=objective(origin);score=objective(best)
print('seed cost',score,'yard penalty',yard_cost(best),flush=True)''')
source=source.replace('range(7):','range(4):').replace('range(20):','range(16):')
source=source.replace("root/'art/timetables/kerala-coast-network.json']", "root/'art/timetables/kerala-coast-network.json',local/'planning-yards.json',local/'network-spacing-proposal-v3.json']")
source=source.replace("result['express_spacing_planning_target_minutes']=35", "result['express_spacing_planning_target_minutes']=35\nresult['yard_model']='One-minute conservative isolated-profile yard cells; total physical road count is an upper bound, not receiving admission.'\nresult['initial_yard_penalty']=yard_cost(origin)\nresult['proposed_yard_penalty']=yard_cost(best)\nresult['seed_cost']=objective(np.array([next((int(c['after'][:2])*60+int(c['after'][3:]) for c in seed['changes'] if c['service']==s['id']),origin[i]) for i,s in enumerate(services)]))")
source=source.replace("local/'network-spacing-proposal-v3.json').write_text", "local/'network-spacing-proposal-v4.json').write_text")
(base/'plan-network-spacing-v4.py').write_text(source,encoding='utf-8')
compile(source,'plan-network-spacing-v4.py','exec')
print('Prepared v4 authoring search; no timetable edits')
