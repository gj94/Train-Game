"""Derive operating-road evidence from the pinned OSM railway snapshot.

Passenger loops include service=siding, but exclude yard/spur storage tracks.
This is a map interpretation, not an official signalling/commissioning diagram.
"""
import json,sys
from pathlib import Path
ROOT=Path(__file__).resolve().parents[2]
sys.path.insert(0,str(ROOT/'.local/kerala-route/python'))
from shapely.geometry import LineString,Point
from shapely.strtree import STRtree
import numpy as np

def build():
    raw=json.loads((ROOT/'.local/kerala-route/rails.json').read_text(encoding='utf-8'))
    route=json.loads((ROOT/'data/routes/kerala_coast/route.json').read_text(encoding='utf-8'))
    line=LineString([(p[0],p[2]) for p in route['alignment']])
    ways=[w for w in raw['ways'] if w['tags'].get('railway')=='rail' and w['tags'].get('station')!='subway' and w['tags'].get('service') not in ['yard','spur']]
    geoms=[LineString(w['points']) for w in ways];tree=STRtree(geoms)
    def cross(s):
        p=np.array(line.interpolate(s).coords[0]);v=np.array(line.interpolate(s+10).coords[0])-np.array(line.interpolate(s-10).coords[0]);v/=np.linalg.norm(v);n=np.array([-v[1],v[0]])
        axis=LineString([p-n*100,p+n*100]);out=[]
        for ix in tree.query(axis,predicate='intersects'):
            g=geoms[ix].intersection(axis)
            if g.geom_type!='Point':continue
            offset=float(np.dot(np.array(g.coords[0])-p,n))
            out.append(dict(offset=round(offset,3),osm_way=ways[ix]['id'],service=ways[ix]['tags'].get('service','main')))
        result=[]
        for r in sorted(out,key=lambda r:(r['service']!='main',abs(r['offset']))):
            if all(abs(r['offset']-other['offset'])>2 for other in result):result.append(r)
        return sorted(result,key=lambda r:abs(r['offset']))
    sections=[]
    for i,sec in enumerate(route['sections']):
        a,b=route['stations'][i:i+2]
        parallels=[r['offset'] for r in cross((a['s']+b['s'])/2) if r['service']=='main' and 3<abs(r['offset'])<20]
        section=dict(**sec,parallel_offset=round(parallels[0],3) if parallels else -6.0)
        if i==0:
            section['tracks']=1
            section['note']='ERS–Kumbalam doubling remains under construction in Ministry of Railways March 2026 project status; TNU has one mapped road.'
        sections.append(section)
    stations=[]
    for i,st in enumerate(route['stations']):
        roads=cross(st['s'])
        # KZK's east siding is a mapped dead-end rather than a passing loop.
        if st['code']=='KZK':roads=[r for r in roads if r['offset']<8]
        prior=sections[max(0,i-1)];following=sections[min(i,len(sections)-1)]
        through=len(roads)<=max(prior['tracks'],following['tracks']) and prior['tracks']==following['tracks']
        desired=following['parallel_offset'] if following['tracks']==2 else prior['parallel_offset']
        if len(roads)>1:
            # Retain the mapped main road at zero; the parallel main is P2.
            mains=[r for r in roads[1:] if r['service']=='main']
            second=min(mains or roads[1:],key=lambda r:abs(r['offset']-desired))
            roads.remove(second);roads.insert(1,second)
        for r in roads:
            if 0<abs(r['offset'])<4.5 and abs(r['offset'])>2:
                r['mapped_offset']=r['offset'];r['offset']=4.5 if r['offset']>0 else -4.5
        for j,r in enumerate(roads):
            r['road']=j+1
            r['lane']='D' if j==0 else ('U' if j==1 else ('D' if abs(r['offset']-roads[0]['offset'])<=abs(r['offset']-roads[1]['offset']) else 'U'))
            # A platform must never project over the adjacent running line.
            left=[r['offset']-o['offset'] for o in roads if o['offset']<r['offset']-1]
            right=[o['offset']-r['offset'] for o in roads if o['offset']>r['offset']+1]
            gaps=[min(left,default=20),min(right,default=20)]
            side=-1 if gaps[0]>=gaps[1] else 1
            r['platform_side']=side
            r['platform_width']=round(min(3.43,max(gaps)-4.1),2) if max(gaps)>=6.1 else 0
        stations.append(dict(code=st['code'],through=through,roads=roads,source='OSM 2026-10-06 operating rail/siding cross-section; yard/spur excluded',geometry_scope='Mapped road count and side; throat geometry reconstructed. Road IDs are game IDs, not official platform numbers.'))
    out=dict(source='southern-zone-261006.osm.pbf',signalling_scope='Game automatic blocks at approximately 1 km, not surveyed real signal positions.',stations=stations,sections=sections)
    from station_corrections import apply
    out=apply(out)
    (ROOT/'data/routes/kerala_coast/operations.json').write_text(json.dumps(out,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
    for st in stations:print(st['code'],len(st['roads']),'through' if st['through'] else 'loops',[(r['road'],r['offset'],r['lane']) for r in st['roads']])

if __name__=='__main__':build()
