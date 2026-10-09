"""Port reviewed coastal architecture without decimation or source script execution.

Keep original metric geometry and material coordinates. Placement is a rigid
rotation/translation, aligning the source platform floor to the game's floor.
Operational platforms/rails/signals remain owned by the game's CSV-based graph.
"""
import json
import sys
from pathlib import Path

ROOT=Path(__file__).resolve().parents[2]
sys.path.insert(0,str(ROOT/'tools'))
sys.path.insert(0,str(ROOT/'tools/blender'))
from inspect_coastal_sources import sources
from port_station_sources import export

manifest=json.loads((ROOT/'tools/coastal_station_sources.json').read_text())
codes=sys.argv[sys.argv.index('--')+1:] if '--' in sys.argv else None
for station in sources(codes):
    folder=Path(station['source']).parent
    code=station['code']
    extra={}
    if station['historical']:
        prefixes=['H2016 |']; placement=dict(axis='x',outward_sign=-1,floor_height=.07,historical=True)
    elif '/north/' in station['path']:
        plan=json.loads((folder/'references/plan.json').read_text())
        prefixes=['04','05 |']; placement=dict(axis='y',outward_sign=plan['main_building']['public_side'],floor_height=1.45)
    elif '/middle/' in station['path']:
        plan=json.loads((folder/'source/adopted_geometry.json').read_text())
        prefixes=['05_','06','07_','08_','08B_']; placement=dict(axis='x',outward_sign=plan['spec']['side'],floor_height=1.018)
    else:
        prefixes=['30_','31_','32_','33_','34_','35_','36_','37_','38_','39_']
        placement=dict(axis='x',outward_sign=-1,floor_height=.95)
        if code=='VRLR':
            # This station has photographed open shelters, no enclosed hall.
            prefixes=['21_']; placement['open_shelters']=True
            extra['maximum_source_y']=12
    export(code.lower(),dict(station,collections=prefixes,placement=placement,revision=manifest['revision'],**extra))
