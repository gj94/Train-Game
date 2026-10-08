"""Reproducible station-sign and infrastructure audit from browser-read evidence.

Counts are facts reported by the linked pages, not proof of commissioned layouts.
Keep mapped operating roads distinct from total yard tracks and platform faces.
"""
import csv,json
from pathlib import Path
ROOT=Path(__file__).resolve().parents[2]
DATA=ROOT/'data/routes/kerala_coast'
def rows(name):
    with (DATA/name).open(encoding='utf8',newline='') as f:return {r['code']:r for r in csv.DictReader(f,delimiter='\t')}
def build():
    iri=rows('station-browser-evidence.tsv');wiki=rows('station-wikipedia-evidence.tsv')
    route=json.loads((DATA/'route.json').read_text(encoding='utf8'))
    ops=json.loads((DATA/'operations.json').read_text(encoding='utf8'))
    names={'KPY':'Karunagappalli','CHPD':'Cheppad','MQO':'Munroturuttu','CRY':'Chirayinkeezhu','NEM':'Thiruvananthapuram South','KZTW':'Kuzhithurai West','KZT':'Kuzhithurai','VRLR':'Virani Alur'}
    audit=[];signs={}
    for station,op in zip(route['stations'],ops['stations']):
        code=station['code'];entry=iri[code];ency=wiki.get(code,{})
        # Retain legacy internal codes so existing references remain intelligible.
        display_code={'PUPR':'PNPR','NEM':'TVCS'}.get(code,code)
        signs[code]={'board_name':names.get(code,station['name']),'board_local_name':entry['regional'],'board_hindi':entry['hindi'],'display_code':display_code}
        source='https://indiarailinfo.com/station/map/kumbalam-kumm/'+entry['iri_id']
        record={'code':code,'name':signs[code]['board_name'],'reviewed':'2026-10-08','browser_source':source,'reported_platforms':int(entry['platforms']),'mapped_operating_roads':len(op['roads']),'modeled_platform_roads':sum(r['platform_width']>0 for r in op['roads']),'road_source':op['source'],'track_count_status':'Mapped operating cross-section; total commissioned track count not independently certified'}
        if ency:
            record['second_source']='https://en.wikipedia.org/wiki/'+ency['page']
            record['second_platform_count']=int(ency['platforms'])
            if ency['tracks']:record['reported_total_tracks']=int(ency['tracks'])
        notes=[]
        if record['reported_platforms']!=record['modeled_platform_roads']:notes.append('Platform-face count differs from rendered through-road platforms; terminal bays and construction require a current station plan.')
        if ency and int(ency['platforms'])!=int(entry['platforms']):notes.append('Browser sources disagree on platform count.')
        if record.get('reported_total_tracks',len(op['roads']))!=len(op['roads']):notes.append('Reported total includes a different scope from mapped operating roads; do not add through loops to force equality.')
        if code in ['KUMM','MAKM','DAVM','VELI']:notes.append('Mapping/listing conflict or incomplete platform geometry; unresolved pending commissioning/site evidence.')
        if code in ['ERL','VRLR','NJT','NCJ']:notes.append('Eraniel–Nagercoil Town commissioned March 2026; Nagercoil Town–Junction commissioned March 2024. Older OSM construction tags lag commissioning.')
        record['notes']=notes;audit.append(record)
    (DATA/'station-signs.json').write_text(json.dumps(signs,ensure_ascii=False,indent=2)+'\n',encoding='utf8')
    (DATA/'station-audit.json').write_text(json.dumps({'reviewed':'2026-10-08','method':'Codex in-app Browser: all 56 station pages; 34 Wikipedia station infoboxes; pinned OSM geometry. No official current station working plans were available.','stations':audit},ensure_ascii=False,indent=2)+'\n',encoding='utf8')
    lines=['# Kerala station infrastructure audit','', 'Reviewed in the requested in-app Browser on 8 October 2026. All 56 stations have a linked station entry; 34 also have a second count source. This is **not** certification of every current track count. Published totals mix yard tracks, bays and through roads; some disagree or lag commissioning. The game must not turn these totals into fictitious passing loops.','', 'Regional and Hindi station names are stored separately from stable internal station IDs. Non-name parenthetical aliases and machine-translated “halt” suffixes are omitted on signs. PUPR and NEM remain internal aliases for PNPR and TVCS.','', '| Station | Mapped operating roads | Rendered platform roads | Listed platform faces | Listed total tracks | Evidence / discrepancy |','|---|---:|---:|---:|---:|---|']
    for r in audit:
        evidence=f'[Station entry]({r["browser_source"]})'
        if 'second_source' in r:evidence+=f' · [Second source]({r["second_source"]})'
        if r['notes']:evidence+=' · '+' '.join(r['notes'])
        lines.append(f'| {r["code"]} {r["name"]} | {r["mapped_operating_roads"]} | {r["modeled_platform_roads"]} | {r["reported_platforms"]} | {r.get("reported_total_tracks","—")} | {evidence} |')
    lines+=['','The [4 October 2026 commissioning report](https://www.newindianexpress.com/states/kerala/2026/Oct/04/thiruvananthapuram-kanyakumari-third-railway-lines-dpr-to-be-submitted-by-march-2027) identifies the completed Eraniel–Nagercoil Town and Nagercoil Town–Junction double sections. Remaining northern doubling is still in progress.','', 'Platform locations and throat geometry remain reconstructed. Exact bay connections, storage roads and all present-day commissioned changes need official station working diagrams or dated site evidence. Keep uncertainties visible in this audit rather than silently inventing capacity.','']
    (ROOT/'docs/kerala-station-browser-audit.md').write_text('\n'.join(lines),encoding='utf8')
    if (DATA/'station-register.csv').exists():
        from apply_station_register import build as apply_register
        apply_register()
if __name__=='__main__':build()
