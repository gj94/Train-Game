"""Independent emitted bridge mesh audit. Does not advance the railway."""
import argparse,json,sys
from pathlib import Path
sys.path.insert(0,str(Path(__file__).resolve().parents[2]/'.local/kerala-route/python'))
from shapely.geometry import Polygon,Point
from shapely.ops import unary_union
from shapely.strtree import STRtree

def check(path):
    report=dict(spans=0,triangles=0,probes=0,guards=0,piers=0,unsupported=[],height_failures=[],duplicate_area_m2=0.0,degenerate_triangles=0)
    for line in Path(path).read_text(encoding='utf-8').splitlines():
        row=json.loads(line); report['spans']+=1
        polygons=[]; triangles=[]
        for tri in row['tops']:
            poly=Polygon([(p[0],p[2]) for p in tri])
            if poly.area<1e-8:
                report['degenerate_triangles']+=1;continue
            polygons.append(poly);triangles.append(tri)
        report['triangles']+=len(triangles)
        report['guards']+=len(row['guards']);report['piers']+=len(row['piers'])
        if not polygons:continue
        union=unary_union(polygons)
        report['duplicate_area_m2']+=sum(p.area for p in polygons)-union.area
        tree=STRtree(polygons)
        for probe in row['probes']:
            report['probes']+=1
            x,y,z=probe['p'];point=Point(x,z)
            candidates=tree.query(point.buffer(.001),predicate='intersects')
            heights=[]
            for index in candidates:
                if polygons[index].distance(point)>.001:continue
                a,b,c=triangles[index]
                ux,uz=b[0]-a[0],b[2]-a[2];vx,vz=c[0]-a[0],c[2]-a[2]
                determinant=ux*vz-uz*vx
                if abs(determinant)<1e-10:continue
                u=((x-a[0])*vz-(z-a[2])*vx)/determinant
                v=(ux*(z-a[2])-uz*(x-a[0]))/determinant
                heights.append(a[1]+u*(b[1]-a[1])+v*(c[1]-a[1]))
            if not heights:
                report['unsupported'].append(dict(span=row['span']['start'],**probe,distance=union.distance(point)))
            elif not any(-.6<=h-y<=.05 for h in heights):
                report['height_failures'].append(dict(span=row['span']['start'],**probe,heights=heights))
    report['passed']=not report['unsupported'] and not report['height_failures']
    return report

if __name__=='__main__':
    parser=argparse.ArgumentParser();parser.add_argument('--input',required=True);parser.add_argument('--output',required=True)
    args=parser.parse_args();result=check(args.input)
    Path(args.output).write_text(json.dumps(result,indent=2)+'\n',encoding='utf-8')
    print(json.dumps({k:len(v) if isinstance(v,list) else v for k,v in result.items()},indent=2))
    sys.exit(0 if result['passed'] else 1)
