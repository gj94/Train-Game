"""Independent Shapely clearance checks for village approaches from the source audit."""
import argparse
import json
import sys
from pathlib import Path
from collections import Counter
ROOT=Path(__file__).resolve().parents[2]
sys.path.insert(0,str(ROOT/'.local/kerala-route/python'))
from shapely.geometry import Polygon,LineString,shape
from shapely.strtree import STRtree
from shapely import affinity

def audit(report,context):
    rail_lines=[LineString([(p[0],p[2]) for p in r['points']]) for r in context['rails']]
    rails=STRtree(rail_lines)
    station_shapes=[Polygon(z['ring']) for z in context['zones']]+[Polygon(p['ring']) for p in context['platforms']]
    stations=STRtree(station_shapes)
    tiles={};counts=Counter();failures=[]
    for row in report['paths']:
        x,z=row['tile'];offset=(x*512,z*512)
        if (x,z) not in tiles:
            features=json.loads((ROOT/f'data/routes/kerala_coast/tiles/{x}_{z}.json').read_text(encoding='utf-8'))['features']
            obstacles=[];ids=[];labels=[];roads={}
            for f in features:
                geom=affinity.translate(shape(f['geometry']),*offset).buffer(0) if f['kind'] in ('water','building') else affinity.translate(shape(f['geometry']),*offset)
                if f['kind'] in ('building','water'):
                    obstacles.append(geom);ids.append(f['id']);labels.append(f['kind'])
                elif f['kind']=='stream' and f['tags'].get('tunnel','no')=='no' and f['tags'].get('covered','no')!='yes':
                    obstacles.append(geom.buffer(4 if f['tags'].get('waterway')=='river' else 1.2,cap_style=2));ids.append(f['id']);labels.append('stream')
                elif f['kind']=='road':roads[f['id']]=(geom,f['tags'])
            tiles[x,z]=(STRtree(obstacles),obstacles,ids,labels,roads)
        tree,obstacles,ids,labels,roads=tiles[x,z]
        line=LineString([(row['a'][0],row['a'][2]),(row['b'][0],row['b'][2])]);path=line.buffer(.65,cap_style=2)
        counts['paths']+=1;counts['steps']+=row['steps']
        for index in tree.query(path,predicate='intersects'):
            if ids[index]==row['building']:continue
            if path.intersection(obstacles[index]).area>.015:
                failures.append(dict(building=row['building'],obstacle=ids[index],kind=labels[index]))
        for index in rails.query(path.buffer(3.5),predicate='intersects'):
            failures.append(dict(building=row['building'],obstacle=context['rails'][index]['id'],kind='rail_clearance'))
        for index in stations.query(path,predicate='intersects'):
            if path.intersection(station_shapes[index]).area>.015:failures.append(dict(building=row['building'],kind='station_clearance'))
        road,tags=roads[row['road']]
        half={'residential':2.25,'service':1.8,'tertiary':2.75,'secondary':3.25,'track':1.4,'path':.5,'footway':.75}.get(tags.get('highway'),2)
        from shapely.geometry import Point
        distance=road.distance(Point(row['b'][0],row['b'][2]))
        if distance>half+.04:failures.append(dict(building=row['building'],kind='road_join',distance=distance,expected=half-.1))
        if row['steps'] and not (.089<=row['rise']<=.191 and row['run']<=line.length*.65+.01):failures.append(dict(building=row['building'],kind='stair_proportions'))
    return dict(passed=not failures,counts=dict(counts),tiles=len(tiles),failures=failures[:100],failure_count=len(failures))

if __name__=='__main__':
    parser=argparse.ArgumentParser()
    parser.add_argument('--input',type=Path,default=ROOT/'.local/map-2026-10-24/village-audit.json')
    parser.add_argument('--context',type=Path,default=ROOT/'.local/scenery-context.json')
    parser.add_argument('--output',type=Path,default=ROOT/'.local/map-2026-10-24/village-clearance.json')
    args=parser.parse_args()
    result=audit(json.loads(args.input.read_text(encoding='utf-8')),json.loads(args.context.read_text(encoding='utf-8')))
    args.output.write_text(json.dumps(result,indent=2)+'\n',encoding='utf-8')
    print(json.dumps(result))
    sys.exit(0 if result['passed'] else 1)
