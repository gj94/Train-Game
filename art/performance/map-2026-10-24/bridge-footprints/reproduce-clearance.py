import sys,json,pathlib
sys.path.insert(0,str(pathlib.Path('.local/kerala-route/python').resolve()))
from shapely.geometry import LineString,Polygon,box
from shapely.strtree import STRtree
context=json.loads(pathlib.Path('.local/scenery-context.json').read_text(encoding='utf-8'))
rails=[LineString([(p[0],p[2]) for p in e['points']]) for e in context['rails']]
tree=STRtree(rails);failures=[];guards=0;minimum=1e6;piers=[];shapes=[]
for line in pathlib.Path('.local/map-2026-10-24/bridge-decks.jsonl').open(encoding='utf-8'):
    row=json.loads(line);ox,oy,oz=row['origin']
    for endpoints in row['guards']:
        if endpoints[0][0]==endpoints[1][0] and endpoints[0][2]==endpoints[1][2]:continue
        guard=LineString([(p[0]+ox,p[2]+oz) for p in endpoints]);d=guard.distance(rails[tree.nearest(guard)])
        guards+=1;minimum=min(minimum,d)
        if d<2.8:failures.append(dict(kind='guard',span=row['span']['start'],distance=d))
    for pier in row['piers']:
        shape=Polygon([(p[0]+ox,p[2]+oz) for p in pier['ring']])
        piers.append(pier);shapes.append(shape)
pier_tree=STRtree(shapes);checks=0
path=pathlib.Path('.local/map-2026-10-24/bank-road-triangles.jsonl')
first=json.loads(path.open(encoding='utf-8').readline())
print('Checking actual road triangles against',len(piers),'new pier footprints',flush=True)
for line in path.open(encoding='utf-8'):
    row=json.loads(line);ox,oz=(v*512 for v in row['tile'])
    if not len(pier_tree.query(box(ox-20,oz-20,ox+532,oz+532))):continue
    for tri in row['triangles']:
        points=tri['points'];poly=Polygon([(p[0]+ox,p[2]+oz) for p in points])
        if poly.area<1e-7:continue
        for idx in pier_tree.query(poly,predicate='intersects'):
            overlap=poly.intersection(shapes[idx])
            if overlap.area<.0001:continue
            checks+=1;pier=piers[idx]
            coords=list(overlap.exterior.coords)
            a,b,c=points;ux,uz=b[0]-a[0],b[2]-a[2];vx,vz=c[0]-a[0],c[2]-a[2];det=ux*vz-uz*vx
            if abs(det)<1e-9:continue
            for x,z in coords:
                px,pz=x-ox-a[0],z-oz-a[2];u=(px*vz-pz*vx)/det;v=(ux*pz-uz*px)/det
                y=a[1]+u*(b[1]-a[1])+v*(c[1]-a[1])
                if y<pier['top']-.05 and y+4>pier['bottom']:
                    failures.append(dict(kind='pier_road',way=row['way'],road_height=y,pier=pier));break
pathlib.Path('.local/map-2026-10-24/deck-guard-clearance.json').write_text(json.dumps(dict(passed=not failures,guards=guards,minimum_distance=minimum,piers=len(piers),actual_road_triangle_overlaps=checks,failures=failures),indent=2),encoding='utf-8')
print('guards',guards,'minimum',minimum,'failures',len(failures),'piers',len(piers))
