"""Read-only clearance check of landward rail abutment footprints."""
import argparse,json,sys,math
from pathlib import Path
from collections import defaultdict
from road_surfaces import ROOT,Ground,WIDTHS
from shapely.geometry import Polygon,Point,shape
from shapely import affinity

def audit(report,context):
    ground=Ground(context,ROOT/'data/routes/kerala_coast')
    profiles=defaultdict(list)
    for r in json.loads((ROOT/'assets/models/scenery/road-surfaces.json').read_text(encoding='utf8'))['segments']:profiles[r[0]].append(r)
    tiles={};failures=[];road_checks=0
    def height(way,p):
        for _,ax,az,ay,bx,bz,by,_ in profiles[way]:
            dx,dz=bx-ax,bz-az;t=max(0,min(1,((p.x-ax)*dx+(p.y-az)*dz)/max(.00001,dx*dx+dz*dz)))
            if (p.x-ax-t*dx)**2+(p.y-az-t*dz)**2<.06**2:return ay+(by-ay)*t
        return ground.height(p)+.07
    for record in report['abutments']:
        foot=Polygon(record['ring']);x0,z0,x1,z1=foot.bounds
        if any(s['start']<record['chain']<s['end'] for s in context['bridges']):failures.append(dict(kind='bridge_opening',**record))
        for tx in range(math.floor(x0/512),math.floor(x1/512)+1):
            for tz in range(math.floor(z0/512),math.floor(z1/512)+1):
                key=(tx,tz)
                if key not in tiles:
                    path=ROOT/f'data/routes/kerala_coast/tiles/{tx}_{tz}.json';rows=[]
                    if path.exists():
                        for f in json.loads(path.read_text(encoding='utf8')).get('features',[]):
                            if f['kind']!='road' or f['tags'].get('tunnel','no')!='no' or f['tags'].get('highway') in ('proposed','construction'):continue
                            line=affinity.translate(shape(f['geometry']),tx*512,tz*512)
                            # Runtime roads are flat-ended ribbons, not capsules
                            # extending half a carriageway beyond source endpoints.
                            rows.append((f['id'],line,line.buffer(WIDTHS.get(f['tags'].get('highway'),4)*.5,cap_style=2)))
                    tiles[key]=rows
                for way,line,ribbon in tiles[key]:
                    overlap=foot.intersection(ribbon)
                    if overlap.area<.025:continue
                    p=line.interpolate(line.project(overlap.representative_point()));y=height(way,p);road_checks+=1
                    if record['bottom']-4<y<record['top']-.05:failures.append(dict(kind='road',edge=record['edge'],way=way,road_height=y,top=record['top'],bottom=record['bottom'],area=overlap.area,ring=record['ring']))
    return dict(ok=not failures,abutments=len(report['abutments']),road_checks=road_checks,failures=failures,note='Independent Shapely footprint/road-height audit; genuine bridge intervals kept open; no simulation advanced.')

if __name__=='__main__':
    p=argparse.ArgumentParser();p.add_argument('--report',type=Path,required=True);p.add_argument('--output',type=Path,required=True);a=p.parse_args()
    r=audit(json.loads(a.report.read_text(encoding='utf8')),json.loads((ROOT/'.local/scenery-context.json').read_text(encoding='utf8')))
    a.output.write_text(json.dumps(r,indent=2)+'\n',encoding='utf8');print(json.dumps({k:v for k,v in r.items() if k!='failures'}));sys.exit(not r['ok'])
