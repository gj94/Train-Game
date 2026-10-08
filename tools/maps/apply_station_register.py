"""Apply the user-selected CSV platform inventory without inventing yard totals.

Counts are the requested gameplay specification. Track-side positions/throats
remain reconstructed; the CSV does not supply a complete engineering plan.
"""
import csv
import hashlib
import json
from pathlib import Path
ROOT = Path(__file__).resolve().parents[2]
DATA = ROOT/'data/routes/kerala_coast'
ALIASES = {'PNPR': 'PUPR', 'TVCS': 'NEM'}
# Preserve accessible roads for both directions and the scenario's termini.
FACES = {'ERS':[1,2,3,4,5,6], 'KUMM':[3], 'TZH':[1], 'CHPD':[1,2,3],
         'OCR':[1,3], 'KPY':[1,3,4], 'PVU':[1,3,4], 'KVU':[1,3,4],
         'KZK':[1,2,3], 'VELI':[1], 'TVCN':[1,2,3,4,5,6],
         'QLN':[1,2,3,4,5,6], 'NCJ':[1,4,5,6]}

def build():
    raw=(DATA/'station-register.csv').read_bytes()
    rows=list(csv.DictReader(raw.decode('utf-8-sig').splitlines()))
    path=DATA/'operations.json'
    ops=json.loads(path.read_text(encoding='utf-8'))
    signs=json.loads((DATA/'station-signs.json').read_text(encoding='utf-8'))
    by_code={s['code']:s for s in ops['stations']}
    decisions=[]
    for row in rows:
        key=ALIASES.get(row['station_code'],row['station_code'])
        station=by_code[key]
        target=int(row['iri_reported_platforms'] if key=='VELI' else row['reported_platform_count'])
        station['passenger_open']=not row['operational_status'].startswith('CLOSED')
        station['register_platforms']=target
        station['register_code']=row['station_code']
        station['register_name']=row['station_name']
        station['register_km']=float(row['coastal_route_km']) if row['coastal_route_km'] else None
        station['register_scope']=row['reported_count_scope']
        signs[key]['board_name']=row['station_name']
        signs[key]['display_code']=row['station_code']
        additions={'OCR':[(4,-10,'D')], 'KZK':[(4,10,'D')],
                   'TVCN':[(4,-18,'U'),(5,18,'D'),(6,-27,'U')]}.get(key,[])
        for number,offset,lane in additions:
            if any(r['road']==number for r in station['roads']):continue
            station['roads'].append(dict(road=number,offset=offset,lane=lane,service='siding',osm_way=None,
                                        platform_width=0,platform_side=1,
                                        evidence='Reconstructed position for CSV running-loop/platform inventory'))
        if key=='KPY':
            station['roads'][4]['storage']=True
            station['roads'][4]['evidence']='CSV maps four running roads plus industrial spurs/stubs; this fifth road is storage, not a passing loop. Connection unresolved.'
        if key in FACES:
            wanted=FACES[key]
            assert len(wanted)==target,(key,target,wanted)
            for road in station['roads']:
                road['platform_width']=3.43 if road['road'] in wanted else 0
                road.pop('platform_sides',None)
            # Keep clear walking surfaces on the reconstructed cross section.
            ordered=sorted(station['roads'],key=lambda r:r.get('register_original_offset',r['offset']))
            last=None
            for road in ordered:
                road.setdefault('register_original_offset',road['offset'])
                road['offset']=road['register_original_offset'] if last is None else max(road['register_original_offset'],last['offset']+8)
                road['platform_side']=1
                last=road
            anchor=station['roads'][0]['offset']
            for road in station['roads']:road['offset']=round(road['offset']-anchor,3)
            station['geometry_scope']='CSV platform counts; clear platform positions and throats reconstructed. Stable road IDs are not official platform numbers.'
        if key=='DAVM':
            # Two reported positions do not establish a second running line.
            station['roads'][0]['platform_sides']=[-1,1]
            station['geometry_scope']='Two CSV platform positions on opposite sides of the single mapped road. Track commissioning and exact positions unresolved.'
        actual=sum(len(r.get('platform_sides',[r['platform_side']])) for r in station['roads'] if r['platform_width']>0)
        assert actual==target,(key,actual,target)
        decisions.append(dict(code=key,public_code=row['station_code'],platform_positions=target,passenger_open=station['passenger_open'],
                              source=row['reported_platform_source_url'],resolution='IRI 1 selected; Wikipedia 3 retained as disputed evidence' if key=='VELI' else 'User requested CSV reported platform count',
                              track_scope='Operating roads and storage are kept distinct from total yard-track figures'))
    ops['station_register']={'file':'station-register.csv','sha256':hashlib.sha256(raw).hexdigest(),'applied':'2026-10-09',
                             'authority':'User requested CSV platform counts, including reported/disputed figures.'}
    path.write_text(json.dumps(ops,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
    (DATA/'station-signs.json').write_text(json.dumps(signs,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
    (DATA/'station-register-decisions.json').write_text(json.dumps(decisions,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
    print(f'Applied all {len(rows)} platform inventories; TNU closed, VELI uses the CSV IRI count.')

if __name__=='__main__':build()
