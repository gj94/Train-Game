"""Independent near-railhead, shallow-angle road overlap audit of emitted meshes."""
import argparse,json,sys,math
from pathlib import Path
ROOT=Path(__file__).resolve().parents[2]
sys.path.insert(0,str(ROOT/'.local/kerala-route/python'))
from shapely.geometry import LineString,Polygon,shape
from shapely.strtree import STRtree
from shapely import affinity
from shapely.ops import unary_union
from audit_road_surfaces import plane_height

def records(path):
    with path.open(encoding='utf-8') as stream:
        for raw in stream:yield json.loads(raw)

def tangent(line,point):
    s=line.project(point);a=line.interpolate(max(0,s-.1));b=line.interpolate(min(line.length,s+.1))
    dx,dz=b.x-a.x,b.y-a.y;length=math.hypot(dx,dz)
    return (dx/length,dz/length) if length else (0,0)

def crossing_bends(sources,width,rail_axis):
    """A sharp bend's transverse segment can cover its neighbouring segment.
    Attribute its actual miter footprint, rather than only the nearest tangent.
    """
    result=[]
    for line in sources:
        coords=list(line.coords)
        directions=[]
        for a,b in zip(coords,coords[1:]):
            dx,dz=b[0]-a[0],b[1]-a[1];length=math.hypot(dx,dz)
            directions.append((dx/length,dz/length) if length else (0,0))
        miters=[]
        for i in range(len(coords)):
            before=directions[max(0,i-1)];after=directions[min(len(directions)-1,i)]
            nx,nz=-after[1],after[0];mx,mz=-before[1]+nx,before[0]+nz;length=math.hypot(mx,mz)
            if length<.1:mx,mz=nx,nz
            else:mx,mz=mx/length,mz/length
            scale=width/max(.5,mx*nx+mz*nz);miters.append((mx*scale,mz*scale))
        for i,axis in enumerate(directions):
            if abs(axis[0]*rail_axis[0]+axis[1]*rail_axis[1])>.9396926:continue
            a,b=coords[i:i+2];u,v=miters[i:i+2]
            # A source hairpin can fold its miter quadrilateral. Keep its valid
            # filled area before unioning; GEOS otherwise aborts the audit.
            result.append(Polygon([(a[0]-u[0],a[1]-u[1]),(b[0]-v[0],b[1]-v[1]),(b[0]+v[0],b[1]+v[1]),(a[0]+u[0],a[1]+u[1])]).buffer(0))
    return result

def audit(context,path):
    rails=[LineString([(p[0],p[2],p[1]) for p in e['points']]) for e in context['rails']]
    # The road may run past a buffer stop; a round buffer would invent track
    # beyond the actual edge endpoint and falsely flag such roads.
    envelopes=[r.buffer(2.75,cap_style=2) for r in rails];tree=STRtree(envelopes)
    cached={};count=0;checked=0;failures=[];by_kind={};widths={}
    for row in records(path):
        key=tuple(row['tile']);ox,oz=(v*512 for v in key)
        if key not in cached:
            ways={}
            for f in json.loads((ROOT/f'data/routes/kerala_coast/tiles/{key[0]}_{key[1]}.json').read_text(encoding='utf-8')).get('features',[]):
                if f['kind']!='road':continue
                geometry=affinity.translate(shape(f['geometry']),ox,oz)
                if geometry.geom_type not in ('LineString','MultiLineString'):continue
                ways[f['id']]=list(getattr(geometry,'geoms',[geometry]))
                widths[f['id']]={'motorway':10,'trunk':9,'primary':8,'secondary':6.5,'tertiary':5.5,'residential':4.5,'service':3.6,'footway':1.5,'path':1,'track':2.8}.get(f['tags'].get('highway'),4)*.5
            cached[key]=ways
        sources=cached[key].get(row['way'],[])
        if not sources:continue
        for record in row['triangles']:
            count+=1;kind=record['kind'];by_kind[kind]=by_kind.get(kind,0)+1
            points=[(p[0]+ox,p[1],p[2]+oz) for p in record['points']]
            poly=Polygon([(p[0],p[2]) for p in points])
            if poly.area<.00001:continue
            for index in tree.query(poly,predicate='intersects'):
                overlap=poly.intersection(envelopes[index])
                if overlap.area<.025:continue
                point=overlap.representative_point();rail=rails[index]
                y=plane_height(points,point.x,point.y);rail_y=rail.interpolate(rail.project(point)).z
                if y-rail_y<-.45 or y-rail_y>.5:continue
                road=min(sources,key=lambda r:r.distance(point));u=tangent(road,point);v=tangent(rail,point)
                cosine=abs(u[0]*v[0]+u[1]*v[1]);checked+=1
                if cosine>.95:
                    failures.append(dict(tile=key,way=row['way'],edge=context['rails'][index]['id'],kind=kind,cosine=cosine,area=overlap.area,height_delta=y-rail_y,_overlap=overlap,_height=y,_axis=v,_aprons=[]))
    # Independently accept only the immediate junction apron of an ACTUALLY
    # emitted, same-level crossroad. No runtime reservation decisions are read.
    candidates={}
    for item in failures:
        x,z=item['tile']
        for dx in (-1,0,1):
            for dz in (-1,0,1):candidates.setdefault((x+dx,z+dz),[]).append(item)
    for row in records(path):
        key=tuple(row['tile'])
        if key not in candidates:continue
        ox,oz=(v*512 for v in key);sources=cached[key].get(row['way'],[])
        if not sources:continue
        for item in candidates[key]:
            if item['way']==row['way']:continue
            point=item['_overlap'].representative_point();source=min(sources,key=lambda r:r.distance(point))
            extension=widths[item['way']]+.65
            if source.distance(item['_overlap'])>extension+widths[row['way']]+1:continue
            axis=tangent(source,point);rail_axis=item['_axis']
            source_aprons=[]
            for line in sources:
                for a,b in zip(line.coords,list(line.coords)[1:]):
                    dx,dz=b[0]-a[0],b[1]-a[1];length=math.hypot(dx,dz)
                    if length<.0001:continue
                    u=(dx/length,dz/length)
                    if abs(u[0]*rail_axis[0]+u[1]*rail_axis[1])>.85:continue
                    extended=LineString([(a[0]-u[0]*extension,a[1]-u[1]*extension),(b[0]+u[0]*extension,b[1]+u[1]*extension)])
                    apron=extended.buffer(widths[row['way']],cap_style=2)
                    if apron.distance(item['_overlap'])<.02:source_aprons.append(apron)
            if not source_aprons:continue
            actual_near=[]
            for tri in row['triangles']:
                if tri['kind'] not in ('road','road_earth','road_gravel','road_concrete','road_pavers'):continue
                points=[(p[0]+ox,p[1],p[2]+oz) for p in tri['points']]
                poly=Polygon([(p[0],p[2]) for p in points])
                if poly.distance(item['_overlap'])>extension+.05:continue
                if abs(plane_height(points,point.x,point.y)-item['_height'])>.4:continue
                actual_near.append(poly)
                if abs(axis[0]*rail_axis[0]+axis[1]*rail_axis[1])<=.85:
                    apron=unary_union([affinity.translate(poly,axis[0]*extension,axis[1]*extension),affinity.translate(poly,-axis[0]*extension,-axis[1]*extension)]).convex_hull
                    item['_aprons'].append(apron)
            if actual_near:
                # At a curved T mouth, the source's adjoining segment and its
                # miter can have different tangents. Permit its short mapped
                # apron only where a real same-level crossroad is also present.
                vicinity=unary_union(actual_near).buffer(extension+.02)
                item['_aprons'] += [apron.intersection(vicinity) for apron in source_aprons]
    genuine=0;remaining=[]
    for item in failures:
        item['_aprons']+=crossing_bends(cached[item['tile']][item['way']],widths[item['way']]+(.65 if item['kind']=='road_shoulder' else 0),item['_axis'])
        remainder=item['_overlap'].difference(unary_union(item['_aprons']).buffer(.02))
        unresolved=remainder.area
        item['unresolved_area']=unresolved
        if unresolved>.025:
            point=remainder.representative_point();item['position']=[point.x,point.y];item['bounds']=list(remainder.bounds)
            remaining.append({k:v for k,v in item.items() if not k.startswith('_')})
        else:genuine+=1
    return dict(passed=not remaining,triangles=count,by_kind=by_kind,near_level_overlaps=checked,genuine_crossing_aprons=genuine,failures=remaining)

if __name__=='__main__':
    parser=argparse.ArgumentParser();parser.add_argument('--context',type=Path,default=ROOT/'.local/scenery-context.json');parser.add_argument('--triangles',type=Path,required=True);parser.add_argument('--output',type=Path,required=True)
    args=parser.parse_args();report=audit(json.loads(args.context.read_text(encoding='utf-8')),args.triangles)
    args.output.write_text(json.dumps(report,indent=2)+'\n',encoding='utf-8')
    print(json.dumps({k:len(v) if k=='failures' else v for k,v in report.items()}))
    sys.exit(0 if report['passed'] else 1)
