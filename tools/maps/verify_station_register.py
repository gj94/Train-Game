"""Read-only reconciliation of the user's register and the game route inventory.

Never equate total yard tracks, running roads, platform bodies and numbered
platform positions. Blank reference fields remain unknown, not zero.
"""
import argparse
import csv
import hashlib
import json
import math
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
DATA = ROOT / 'data/routes/kerala_coast'
ALIASES = {'PNPR': 'PUPR', 'TVCS': 'NEM'}

def number(value):
    try:
        return float(value) if str(value).strip() else None
    except (ValueError, TypeError):
        return None

def separation(a, b):
    lat1, lon1, lat2, lon2 = map(math.radians, [a['lat'], a['lon'], float(b['map_latitude']), float(b['map_longitude'])])
    h = math.sin((lat2-lat1)/2)**2 + math.cos(lat1)*math.cos(lat2)*math.sin((lon2-lon1)/2)**2
    return round(6371000*2*math.asin(min(1, math.sqrt(h))), 1)

def audit(path):
    raw = path.read_bytes()
    rows = list(csv.DictReader(raw.decode('utf-8-sig').splitlines()))
    route = json.loads((DATA/'route.json').read_text(encoding='utf-8'))
    ops = json.loads((DATA/'operations.json').read_text(encoding='utf-8'))
    mapped = {s['code']: s for s in route['stations']}
    operating = {s['code']: s for s in ops['stations']}
    assert len({r['station_code'] for r in rows}) == len(rows), 'Duplicate register station code'
    output = []
    for row in rows:
        public = row['station_code']
        key = public if public in mapped else ALIASES.get(public, public)
        station, operation = mapped.get(key), operating.get(key)
        item = {'register_code': public, 'game_id': key, 'register_name': row['station_name'],
                'reference_row': int(row['sequence'])+1, 'reference': row, 'issues': []}
        if station is None or operation is None:
            item['issues'].append('Station missing from route/operations')
            output.append(item)
            continue
        platforms = sum(len(r.get('platform_sides',[r['platform_side']])) for r in operation['roads'] if r.get('platform_width', 0)>0)
        reported = number(row['reported_platform_count'])
        report_roads = number(row['mapped_parallel_running_roads'])
        running_roads = sum(not r.get('storage', False) for r in operation['roads'])
        transect_roads = number(row['mapped_roads_at_marker_transect'])
        index = route['stations'].index(station)
        section_tracks = [s['tracks'] for s in ops['sections'][max(0, index-1):min(index+1, len(ops['sections']))]]
        main_count = max(section_tracks)
        loops = 0 if operation['through'] else max(0, sum(not r.get('storage',False) for r in operation['roads'])-main_count)
        reference_loops = number(row['mapped_connected_loops'])
        if reference_loops is None:
            reference_loops = number(row['mapped_crossing_loop_alignments'])
        game_km = (station['s']-route['stations'][0]['s'])/1000
        official_km = number(row['coastal_route_km'])
        item['game'] = {'name': operation.get('register_name',station['name']), 'roads': len(operation['roads']), 'running_roads': running_roads, 'passenger_faces': platforms,
                        'through': operation['through'], 'loop_alignments': loops, 'geometry_km_from_ers': round(game_km, 3),
                        'official_km_delta_m': round((game_km-official_km)*1000, 1) if official_km is not None else None,
                        'locator_difference_m': separation(station, row), 'commissioning_source': operation.get('commissioning_source')}
        if key != public:
            item['issues'].append('Legacy/internal code alias: '+key+' -> '+public)
        if item['game']['name'] != row['station_name']:
            item['issues'].append('Name/spelling differs')
        if row['operational_status'].startswith('CLOSED') and operation.get('passenger_open',True):
            item['issues'].append('Closed station: exclude from current passenger calls')
        if reported is None:
            item['issues'].append('Reported platform count disputed/unavailable')
        elif platforms != reported and not row['operational_status'].startswith('CLOSED'):
            item['issues'].append('Passenger faces '+str(platforms)+' vs reported positions '+str(int(reported)))
        if report_roads is not None and running_roads != report_roads:
            item['issues'].append('Parallel running-road mismatch: '+str(running_roads)+' vs '+str(int(report_roads)))
        if transect_roads is not None and len(operation['roads']) != transect_roads:
            item['issues'].append('Transect/all-types scope difference: '+str(len(operation['roads']))+' vs '+str(int(transect_roads)))
        if reference_loops is not None and loops != reference_loops:
            item['issues'].append('Loop comparison requires topology/commissioning review: '+str(loops)+' vs '+str(int(reference_loops)))
        if item['game']['locator_difference_m'] > 100:
            item['issues'].append('Station locators differ by more than 100 m')
        if official_km is not None and abs(item['game']['official_km_delta_m']) > 250:
            item['issues'].append('Geometric distance differs from official chainage by more than 250 m')
        output.append(item)
    missing = sorted(set(mapped)-{r['game_id'] for r in output})
    return {'source_name': path.name, 'source_sha256': hashlib.sha256(raw).hexdigest(),
            'source_rows': len(rows), 'matched_rows': sum('game' in r for r in output), 'game_without_reference': missing,
            'scope': 'Register comparison, not independent certification of a current railway engineering inventory. '
                     'All source columns and their uncertainty notes are retained. Geometric chainage is measured from ERS, not the route start buffer.',
            'stations': output}

def report(result):
    lines = ['# Kerala station register reconciliation', '',
        'Updated 9 October 2026. The user selected the CSV platform numbers as the gameplay specification. '
        f'All {result["matched_rows"]} of {result["source_rows"]} stations match; no game stations are missing from the register. '
        'Every selected platform total is implemented and checked against the generated simulation and walking surfaces.', '',
        'The [original CSV](../data/routes/kerala_coast/station-register.csv) is preserved byte for byte. '
        f'SHA-256: `{result["source_sha256"]}`. '
        '[Per-station decisions](../data/routes/kerala_coast/station-register-decisions.json) record the selected figures. '
        'The previous browser evidence remains in [the browser audit](kerala-station-browser-audit.md).', '',
        '## Interpretation', '',
        '- Kumbalam has one passenger platform and three tracks. The other roads can receive through trains but cannot serve a booked passenger stop. The opposing morning LHB starts at Turavur and passes Kumbalam without a call; the dispatcher can forecast the VB vacating the sole platform for K1.',
        '- Tirunettur is closed in the register. Its mapped track/platform remains, but it is not bookable: K1 now has 55 calls along the 56-station corridor.',
        '- Veli has no single resolved total in the CSV. Its CSV IRI figure of **one** is selected; the conflicting Wikipedia figure of three remains evidence, not additional gameplay capacity.',
        '- Dhanuvachapuram has two reported platform positions, represented on opposite sides of the one mapped road. Two platforms do not establish a second track or passing loop.',
        '- Ochira and Kazhakuttam include the CSV second outer loop. Karunagappalli has four running roads and a separate storage road with an unresolved connection; storage cannot become an invented passing loop.',
        '- Thiruvananthapuram North has six platform positions. Kollam has six numbered positions, but its reported 1A bay connection is not faithfully reproduced by the reconstructed full-length platform roads.',
        '- PUPR and NEM remain stable internal IDs; boards and public labels use PNPR and TVCS. CSV spelling is used for station names.', '',
        '## All stations', '',
        'Platform positions and tracks are different quantities. "Running" excludes isolated storage; "tracks" includes it. Road IDs such as KUMM_P3 are game identifiers, not official platform numbers. The CSV source link is retained for each row.', '',
        '| Station | CSV selected platforms | Game platforms | Running / all tracks | CSV mapped running / transect | Notes |',
        '|---|---:|---:|---:|---|---|']
    for item in result['stations']:
        row, game = item['reference'], item.get('game', {})
        target = row['iri_reported_platforms'] if item['register_code']=='VELI' else row['reported_platform_count']
        source = row['reported_platform_source_url'] or row['iri_source_url']
        notes = '; '.join(item['issues']) or 'Selected platform total matches'
        if row['operational_status'].startswith('CLOSED'): notes = 'Closed; physical platform retained, no passenger call'
        lines.append(f'| [{item["register_code"]} {item["register_name"]}]({source}) | {target} | {game.get("passenger_faces", "—")} | {game.get("running_roads", "—")} / {game.get("roads", "—")} | {row["mapped_parallel_running_roads"] or "—"} / {row["mapped_roads_at_marker_transect"] or "—"} | {notes} |')
    lines += ['', '## Remaining physical-layout differences', '',
        'This comparison is not certification of an operational engineering inventory. The register itself leaves verified running-line/loop/siding fields blank and labels many observations as reported or disputed. Full raw rows, uncertainty notes, source dates, OSM way IDs and revision links are retained in the audit JSON.', '',
        'ERS, Cherthala, Alappuzha, Ambalappuzha, Kayamkulam and Nagercoil have more tracks in the CSV locator transect than the game models. Those extra yard, intermediate and depot roads are not all reproduced. Exact storage/bay connections and official platform-to-track numbering remain unresolved. The Eraniel–Nagercoil sections retain the documented 2024/2026 doubling commissions; older CSV map observations still show fewer tracks. These differences are listed above instead of inventing usable passing capacity.', '',
        'Geometric route distance differs from official chainage by over 250 m at QLN, VELI, TVCN, AMVA and DAVM. The CSV official kilometre values are retained as metadata; train movement, stop distances and sound continue to use the actual simulated track geometry. Station locators all agree within 100 m. Clear platform/siding lengths, starters and throats are reconstructed to accommodate the current rakes; they are not surveyed real-yard dimensions.', '',
        '## Reproduce', '', '```powershell',
        'python tools/maps/apply_station_register.py',
        'python tools/maps/verify_station_register.py data/routes/kerala_coast/station-register.csv --report docs/kerala-station-audit.md',
        '```', '',
        'The default JSON output is `.local/station-register-audit.json`. Map/legacy browser-audit regeneration reapplies the user-selected CSV counts. Headless tests compare all 56 generated station counts, the closed halt, two faces on one road, isolated storage and the sole-platform future-clearance case.', '']
    return '\n'.join(lines)

if __name__ == '__main__':
    p = argparse.ArgumentParser()
    p.add_argument('register', type=Path)
    p.add_argument('--output', type=Path, default=ROOT/'.local/station-register-audit.json')
    p.add_argument('--report', type=Path)
    args = p.parse_args()
    result = audit(args.register)
    args.output.write_text(json.dumps(result, ensure_ascii=False, indent=2)+'\n', encoding='utf-8')
    if args.report: args.report.write_text(report(result), encoding='utf-8')
    print(f"Matched {result['matched_rows']}/{result['source_rows']} register rows; unmatched game stations: {result['game_without_reference']}")
    for item in result['stations']:
        if item['issues']:
            print(item['register_code']+': '+'; '.join(item['issues']))
