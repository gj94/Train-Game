"""Check exported actual rail centrelines for crossings outside protected points.
Run check_route_geometry.gd first; geometry inputs are never modified.
"""
import argparse
import json
from pathlib import Path
import sys
ROOT=Path(__file__).resolve().parents[2]
sys.path.insert(0,str(ROOT/'.local/kerala-route/python'))
from shapely.geometry import LineString,Point
from shapely.strtree import STRtree

def check(edges):
    lines=[LineString(edge['points']) for edge in edges]
    tree=STRtree(lines)
    crossings=[]
    for i,(edge,line) in enumerate(zip(edges,lines)):
        for j in tree.query(line,predicate='intersects'):
            if j<=i:continue
            other=edges[j]
            crossing=line.intersection(lines[j])
            shared={edge['a'],edge['b']}&{other['a'],other['b']}
            for node in shared:
                # The runtime protects 195 m on every branch of these points.
                point=Point(edge['points'][0 if edge['a']==node else -1])
                crossing=crossing.difference(point.buffer(195))
            if not crossing.is_empty:
                crossings.append(dict(first=edge['id'],second=other['id'],shape=crossing.geom_type,length_m=crossing.length))
    return crossings

if __name__=='__main__':
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('graph',type=Path)
    parser.add_argument('--output',type=Path,required=True)
    args=parser.parse_args()
    edges=json.loads(args.graph.read_text(encoding='utf8'))
    crossings=check(edges)
    result=dict(ok=not crossings,edges=len(edges),crossings=crossings)
    args.output.write_text(json.dumps(result,indent=2)+'\n',encoding='utf8')
    print(f"{len(edges)} roads; {len(crossings)} unprotected centreline intersections")
    sys.exit(1 if crossings else 0)
