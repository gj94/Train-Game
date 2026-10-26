"""Independent arithmetic review; no traffic or receiving-admission certificate."""
import json, hashlib, itertools
from pathlib import Path
root=Path('D:/ClaudeWS/train-game'); base=root/'.local/realism-2026-10-26'
read=lambda p:json.loads(p.read_text(encoding='utf-8'))
proposal=read(base/'network-spacing-proposal-v5.json')
pack=read(root/'art/timetables/kerala-coast-network.json')
for name,sha in proposal['inputs'].items():
    p=root/'art/timetables'/name if name.startswith('kerala') else base/name
    assert hashlib.sha256(p.read_bytes()).hexdigest()==sha
sections=read(base/'planning-sections.json')['sections']
yards=read(base/'planning-yards.json')['stations']
profiles={sid:p for part in range(2) for p in read(base/f'solo-profiles-{part}.json')['profiles'] for sid in p['ids']}
services={s['id']:s for s in pack['services']}
minutes=lambda s:int(s[:2])*60+int(s[3:])
before={sid:minutes(s['departure']) for sid,s in services.items()}; after=before.copy()
assert len({c['service'] for c in proposal['changes']})==len(proposal['changes'])
for c in proposal['changes']:
    assert services[c['service']]['departure']==c['before']; after[c['service']]=minutes(c['after'])
assert before['K1']==after['K1']==360
envelopes={}
for sid,p in profiles.items():
    e={}
    for key,v in p['intervals'].items():
        group=sections[key]['group']
        if not group:continue
        a,b=v['start']/60-1,v['finish']/60+1
        if group in e:a,b=min(a,e[group][0]),max(b,e[group][1])
        e[group]=(a,b)
    envelopes[sid]=e
def summarize(plan):
    overlaps=[]; following=[]; express=[]
    for x,y in itertools.combinations(services,2):
        same=profiles[x]['direction']==profiles[y]['direction']
        fast=all(services[i]['journey']['category'] in ['superfast','vb'] for i in [x,y])
        for group in envelopes[x].keys()&envelopes[y].keys():
            a,b=[v+plan[x] for v in envelopes[x][group]]
            for day in [-1440,0,1440]:
                c,d=[v+plan[y]+day for v in envelopes[y][group]]
                overlap=max(0,min(b,d)-max(a,c)); ds=a-c; de=b-d
                if not same and overlap>1e-7: overlaps.append(dict(group=group,trains=[x,y],minutes=overlap))
                if same and (min(abs(ds),abs(de))<3 or ds*de<0):following.append(dict(group=group,trains=[x,y],entry_gap=abs(ds),exit_gap=abs(de),order_reversal=ds*de<0))
                if same and fast and min(abs(ds),abs(de))<35:express.append(dict(group=group,trains=[x,y],minimum_gap=min(abs(ds),abs(de))))
    # Nominal yard time estimates: last-tail arrival at yard minus 60 seconds,
    # first-head exit plus 60 seconds. Call timestamps supply start/end cases.
    # These estimates cannot represent held/queued trains or route conflicts.
    yard_review=[]
    for yard in yards:
        if yard['through_halt']:continue
        code=yard['code']; visits=[]; stopping_ids=set()
        for sid,p in profiles.items():
            inbound=[]; outbound=[]
            for key,v in p['intervals'].items():
                f,t=key.split('-')
                if p['direction']<0:f,t=t,f
                if t==code:inbound.append(v['finish']/60)
                if f==code:outbound.append(v['start']/60)
            calls=[i for i,s in enumerate(services[sid]['stops']) if s['block'].split('_P')[0]==code]
            if calls:stopping_ids.add(sid)
            for i in calls:
                if p['arrivals'][i]>=0:inbound.append((p['arrivals'][i]-180)/60)
                if p['departures'][i]>=0:outbound.append((p['departures'][i]-180)/60)
            if not inbound and not outbound:continue
            a=(min(inbound) if inbound else min(outbound))-1+plan[sid]
            b=(max(outbound) if outbound else max(inbound))+1+plan[sid]
            assert b>=a,(sid,code,a,b)
            for day in [-1440,0,1440]:
                if a+day<1440 and b+day>0:visits.append((max(0,a+day),min(1440,b+day),sid))
        events=sorted([(a,1,sid) for a,b,sid in visits]+[(b,-1,sid) for a,b,sid in visits])
        active=set();peak=[];peak_at=None;stopping_peak=[]
        for t,kind,sid in events:
            if kind<0:active.discard(sid)
            else:active.add(sid)
            if len(active)>len(peak):peak=sorted(active);peak_at=t
            if len(active&stopping_ids)>len(stopping_peak):stopping_peak=sorted(active&stopping_ids)
        passenger=[r for r in yard['roads'] if r['details'].get('platform_width',0)>0]
        yard_review.append(dict(station=code,total_physical_roads=len(yard['roads']),passenger_roads=len(passenger),lane_labels={lane:sum(r['details'].get('lane')==lane for r in passenger) for lane in ['D','U','M']},nominal_peak=len(peak),nominal_peak_at=peak_at,nominal_peak_trains=peak,exceeds_total_road_count=len(peak)>len(yard['roads']),nominal_stopping_peak=len(stopping_peak),stopping_peak_trains=stopping_peak,exceeds_passenger_road_count=len(stopping_peak)>len(passenger)))
    hourly=[sum(m//60==h for m in plan.values()) for h in range(24)]
    return dict(hourly=hourly,overnight=sum(m<360 or m>=1320 for m in plan.values()),opposing_overlap_pairs=len(overlaps),opposing_overlap_minutes=sum(x['minutes'] for x in overlaps),largest_opposing_overlaps=sorted(overlaps,key=lambda x:-x['minutes'])[:20],following_conflicts=len(following),following_order_reversals=sum(x['order_reversal'] for x in following),express_gap_below_35_count=len(express),express_gap_min=min([x['minimum_gap'] for x in express],default=35),express_gap_shortfalls=sorted(express,key=lambda x:x['minimum_gap'])[:20],yard_estimates=yard_review)
out=dict(kind='independent departure-proposal arithmetic review, not validated traffic',proposal_sha256=hashlib.sha256((base/'network-spacing-proposal-v5.json').read_bytes()).hexdigest(),before=summarize(before),after=summarize(after),limits=['One-minute section padding is a planning allowance only.','Yard estimates are isolated-profile approximations, not actual simultaneous occupancy.','Passenger lane labels do not establish directional connectivity, full-rake berth fit, escape roads or route admission. Total road count is only an upper bound.','Repeated holds, changed passing plans and resulting opposing queues require real complete-day validation.'])
(base/'spacing-proposal-v5-review.json').write_text(json.dumps(out,indent=2)+'\n',encoding='utf-8')
for label in ['before','after']:
    print(label,json.dumps({k:v for k,v in out[label].items() if k not in ['yard_estimates','largest_opposing_overlaps','express_gap_shortfalls']}))
    print('nominal yards above physical count',json.dumps([x for x in out[label]['yard_estimates'] if x['exceeds_total_road_count']]))
    print('passenger-face warnings',json.dumps([x for x in out[label]['yard_estimates'] if x['exceeds_passenger_road_count']]))
    print('key yards',json.dumps([x for x in out[label]['yard_estimates'] if x['station'] in ['ALLP','AMPA','KUMM','TUVR','ERS']]))
