"""Compare the actual road-mesh heights on both sides of mapped T-junctions."""
import argparse
from collections import defaultdict
import json
import math
from pathlib import Path


def triangle_height(vertices, point):
    a,b,c = vertices
    u,v = (b[0]-a[0],b[2]-a[2]),(c[0]-a[0],c[2]-a[2])
    w = (point[0]-a[0],point[1]-a[2])
    cross = u[0]*v[1]-u[1]*v[0]
    if abs(cross)<1e-9:
        return None
    t,s = (w[0]*v[1]-w[1]*v[0])/cross,(u[0]*w[1]-u[1]*w[0])/cross
    # Native world coordinates are float32; allow 4 cm at triangle boundaries.
    tolerance = .04*max(math.hypot(*u),math.hypot(*v),math.dist(u,v))/abs(cross)
    if min(t,s,1-t-s)<-tolerance:
        return None
    return a[1]+t*(b[1]-a[1])+s*(c[1]-a[1])


def audit(triangles, junctions):
    rows,by_way,seen = [],defaultdict(list),set()
    for j in junctions:
        key = (*sorted([j['way'],j['other']]),*[round(v,3) for v in j['point']])
        if key in seen:
            continue
        seen.add(key)
        offsets=[(0,0),(1,0),(-1,0),(0,1),(0,-1),(1,1),(1,-1),(-1,1),(-1,-1),(2,0),(-2,0),(0,2),(0,-2)]
        rows.append(dict(**j,probes=[dict(point=[j['point'][0]+dx,j['point'][1]+dz],samples=defaultdict(list)) for dx,dz in offsets]))
        for way in (j['way'],j['other']):
            by_way[way].append(rows[-1])
    with triangles.open(encoding='utf8') as stream:
        for line in stream:
            row = json.loads(line)
            if row['way'] not in by_way:
                continue
            ox,oz = [v*512 for v in row['tile']]
            for j in by_way[row['way']]:
                for probe in j['probes']:
                    p = (probe['point'][0]-ox,probe['point'][1]-oz)
                    if not (-8<=p[0]<=520 and -8<=p[1]<=520):
                        continue
                    for tri in row['triangles']:
                        if tri['kind']!='road':
                            continue
                        points = tri['points']
                        if not (min(v[0] for v in points)-.04<=p[0]<=max(v[0] for v in points)+.04
                                and min(v[2] for v in points)-.04<=p[1]<=max(v[2] for v in points)+.04):
                            continue
                        height = triangle_height(points,p)
                        if height is not None:
                            probe['samples'][row['way']].append(height)
    failures,paired,one_side,largest,probe_count = [],0,[],0.0,0
    for row in rows:
        shared=0;worst=None
        if len(row['probes'][0]['samples'])==1:
            one_side.append(dict(way=row['way'],other=row['other'],point=row['point'],
                                 visible=list(row['probes'][0]['samples'])))
        for probe in row['probes']:
            samples=probe['samples']
            if len(samples)!=2:
                continue
            heights=[sum(values)/len(values) for values in samples.values()]
            delta=abs(heights[0]-heights[1]);largest=max(largest,delta);shared+=1;probe_count+=1
            if delta>.08 and (worst is None or delta>worst['difference']):
                worst=dict(way=row['way'],other=row['other'],point=row['point'],probe=probe['point'],heights=heights,difference=delta)
        if shared:
            paired+=1
        if worst is not None:
            failures.append(worst)
    return dict(paired=paired,probes_checked=probe_count,one_side_visible=len(one_side),unpaired=one_side,maximum_difference=largest,
                failure_count=len(failures),failures=sorted(failures,key=lambda r:r['difference'],reverse=True),
                note='Actual road triangles, centre and 1/2 m offsets across junction; 4 cm horizontal sampling tolerance, 8 cm height tolerance; no railway simulation.')



if __name__=='__main__':
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--triangles',type=Path,required=True)
    parser.add_argument('--report',type=Path,required=True)
    parser.add_argument('--output',type=Path,required=True)
    args=parser.parse_args()
    report=audit(args.triangles,json.loads(args.report.read_text(encoding='utf8'))['junctions'])
    args.output.write_text(json.dumps(report,indent=2)+'\n',encoding='utf8')
    print(json.dumps({k:v for k,v in report.items() if k not in ('failures','unpaired')}))
    raise SystemExit(1 if report['failure_count'] else 0)
