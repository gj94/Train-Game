"""Recover the changed render dependencies for the October 24 formation audit.

The remaining dependencies and protected route inputs are identical between
a329f51 and this increment. This is an archived comparison, not a general
historical-version runner. It only writes ignored .local audit copies.
"""
import subprocess
from pathlib import Path

ROOT=Path(__file__).resolve().parents[2]
OUT=ROOT/'.local/map-2026-10-24'
NAMES={'geo':'geographic_data','chunk':'geographic_scenery_chunk','shore':'geographic_shore_cells','ribbon':'geographic_ground_ribbon','support':'geographic_road_support'}

def main():
    OUT.mkdir(parents=True,exist_ok=True)
    for key,name in NAMES.items():
        source=subprocess.check_output(['git','-c',f'safe.directory={ROOT.as_posix()}','show',f'a329f51:game/{name}.gd'],cwd=ROOT,text=True,encoding='utf8')
        if key in ('ribbon','chunk'):
            source=source.replace('res://game/geographic_shore_cells.gd','res://.local/map-2026-10-24/formation-baseline-shore.gd')
        if key=='support':
            source=source.replace('res://game/geographic_ground_ribbon.gd','res://.local/map-2026-10-24/formation-baseline-ribbon.gd')
        (OUT/f'formation-baseline-{key}.gd').write_text(source,encoding='utf8')
    print('Prepared five render-only baseline scripts from a329f51')

if __name__=='__main__':main()
