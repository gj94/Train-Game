from pathlib import Path
base=Path('D:/ClaudeWS/train-game/.local/realism-2026-10-26')
s=(base/'plan-network-spacing-v4.py').read_text(encoding='utf-8')
begin=s.index('# Receiving-yard upper-bound screen.')
end=s.index('def costs(',begin)
yard_code='''# Static compatible-road subsets, measured through the runtime receiving rule.
# Hall subset counts are necessary for simultaneous berth assignment. They
# exclude live route reservations, receiving escape and interaction delays.
yard_data=[y for y in json.loads((local/'planning-yards.json').read_text(encoding='utf-8'))['stations'] if not y['through_halt']]
berth_data=json.loads((local/'planning-berths-v2.json').read_text(encoding='utf-8'))
assert len(berth_data['profiles'])==44
assert berth_data['pack_sha256']==hashlib.sha256((root/'art/timetables/kerala-coast-network.json').read_bytes()).hexdigest()
eligible={sid:{y['code']:frozenset(y['roads']) for y in p['stations']} for p in berth_data['profiles'] for sid in p['ids']}
visits={};fallback=[]
for i,s in enumerate(services):
    p=profiles[s['id']]
    for y in yard_data:
        inbound=[];outbound=[];code=y['code'];stopping=False
        for key,v in p['intervals'].items():
            f,t=key.split('-')
            if p['direction']<0:f,t=t,f
            if t==code:inbound.append(v['finish']/60)
            if f==code:outbound.append(v['start']/60)
        for k,call in enumerate(s['stops']):
            if call['block'].split('_P')[0]!=code:continue
            stopping=True
            if p['arrivals'][k]>=0:inbound.append((p['arrivals'][k]-180)/60)
            if p['departures'][k]>=0:outbound.append((p['departures'][k]-180)/60)
        if not inbound and not outbound:continue
        roads=eligible[s['id']].get(code)
        if roads is None:
            # Origin supply is not a receiving movement. Use all physical
            # passenger roads as a documented upper bound, never claim matching.
            assert s['stops'][0]['block'] in [r['id'] for r in y['roads']],(s['id'],code,'missing non-origin compatibility')
            roads=frozenset(r['id'] for r in y['roads'] if not stopping or r['details'].get('platform_width',0)>0)
            fallback.append(dict(service=s['id'],station=code,reason='Origin supply; physical passenger-road upper bound'))
        assert roads,(s['id'],code)
        visits[(i,code)]=((min(inbound) if inbound else min(outbound))-1,(max(outbound) if outbound else max(inbound))+1,roads)
resources=[]
for y in yard_data:
    code=y['code'];sets={v[2] for (i,c),v in visits.items() if c==code}
    # Generate unions of compatible sets. Every Hall-deficient collection is
    # detected by the union of the roads its trains can use.
    unions={frozenset()}
    for roads in sets:unions|={u|roads for u in list(unions)}
    unions.discard(frozenset())
    for roads in sorted(unions,key=lambda r:(len(r),sorted(r))):resources.append(dict(station=code,roads=sorted(roads),capacity=len(roads)))
yard_caps=np.array([r['capacity'] for r in resources])
yard_a=np.zeros((n,len(resources)));yard_b=yard_a.copy();yard_present=np.zeros_like(yard_a,dtype=bool)
for j,res in enumerate(resources):
    roads=frozenset(res['roads'])
    for i in range(n):
        visit=visits.get((i,res['station']))
        if visit is None or not visit[2]<=roads:continue
        yard_a[i,j],yard_b[i,j]=visit[:2];yard_present[i,j]=True
def yard_load(plan,omit=-1):
    counts=np.zeros((len(resources),1441),dtype=np.int16)
    rows,columns=np.where(yard_present);keep=rows!=omit;rows=rows[keep];columns=columns[keep]
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
print('Compatible-road resources',len(resources),'origin upper bounds',len(fallback),flush=True)

'''
s=s[:begin]+yard_code+s[end:]
s=s.replace('following=(headway*2+catching*4)*(~opposite)','following=(headway*2+catching*4)*(~opposite)*8')
s=s.replace('default_rng(260927)','default_rng(260928)')
s=s.replace("seed=json.loads((local/'network-spacing-proposal-v3.json')", "seed=json.loads((local/'network-spacing-proposal-v4.json')")
s=s.replace("local/'planning-yards.json',local/'network-spacing-proposal-v3.json'", "local/'planning-yards.json',local/'planning-berths-v2.json',local/'network-spacing-proposal-v4.json'")
s=s.replace("result['yard_model']='One-minute conservative isolated-profile yard cells; total physical road count is an upper bound, not receiving admission.'", "result['yard_model']='Conservative isolated-profile minute cells with static compatible-road subset capacities; not live receiving admission.'\nresult['receiving_resources']=resources\nresult['origin_upper_bound_fallbacks']=fallback")
s=s.replace("local/'network-spacing-proposal-v4.json').write_text", "local/'network-spacing-proposal-v5.json').write_text")
(base/'plan-network-spacing-v5.py').write_text(s,encoding='utf-8');compile(s,'plan-network-spacing-v5.py','exec')
print('Prepared v5 authoring search; no packs edited')
