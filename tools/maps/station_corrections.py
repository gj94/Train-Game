"""Explicit dated corrections; never infer commissioned loops from platform totals."""
COMMISSIONING_SOURCE='https://www.newindianexpress.com/states/kerala/2026/Oct/04/thiruvananthapuram-kanyakumari-third-railway-lines-dpr-to-be-submitted-by-march-2027'
def apply(operations):
    by_code={s['code']:s for s in operations['stations']}
    # The pinned OSM file still labels the March 2026 opened line construction.
    # Offsets below come from its surveyed construction ways/platform polygon.
    additions={
        'ERL':[(1180712997,-21.6,'U',0,-1)],
        'VRLR':[(1180712994,11.2,'U',0,1)],
        'NJT':[(1180712994,6.0,'U',3.43,1),(None,22.3,'U',3.43,-1)],
    }
    for code,extra in additions.items():
        station=by_code[code]
        if station.get('commissioning_review')=='2026-10-08':continue
        for way,offset,lane,width,side in extra:
            station['roads'].append(dict(road=len(station['roads'])+1,osm_way=way,offset=offset,lane=lane,service='main',platform_width=width,platform_side=side,
                evidence='Mapped construction way, opened by dated commissioning report' if way else 'Third road reported by both station sources; position reconstructed from platform polygon 1180712996'))
        station['through']=code=='VRLR'
        station['commissioning_review']='2026-10-08'
        station['commissioning_source']=COMMISSIONING_SOURCE
    for section in operations['sections']:
        if section['a'] in ['ERL','VRLR','NJT']:
            section['tracks']=2
            section['parallel_offset']=11.2 if section['a']=='ERL' else 6.0
            section['note']='Commissioned double line; prior OSM construction classification superseded by dated report.'
            section['commissioning_source']=COMMISSIONING_SOURCE
    # Explicit goods roads at Kollam must not acquire passenger platforms merely
    # because their neighbours are far apart. The separate 1A bay is not modeled.
    for road in by_code['QLN']['roads']:
        if road['road']>=6:road['platform_width']=0
    # Nagercoil's western yard roads have no mapped passenger platform.
    for road in by_code['NCJ']['roads']:
        if road['road'] in [3,6]:road['platform_width']=0
    return operations

if __name__=='__main__':
    import json
    from pathlib import Path
    path=Path(__file__).resolve().parents[2]/'data/routes/kerala_coast/operations.json'
    path.write_text(json.dumps(apply(json.loads(path.read_text(encoding='utf8'))),ensure_ascii=False,indent=2)+'\n',encoding='utf8')
