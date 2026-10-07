"""Reproducible Ernakulam–Alappuzha–TVC–Nagercoil route conversion.

OSM-derived outputs are ODbL 1.0; this converter is project code. Raw downloads
stay in .local/kerala-route. No proprietary map tiles or traced imagery.
"""
from __future__ import annotations
import argparse, base64, hashlib, heapq, json, math, sys
from collections import defaultdict
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
CACHE = ROOT / '.local/kerala-route'
sys.path.insert(0, str(CACHE / 'python'))
import osmium
from pyproj import Transformer
import numpy as np
from scipy.spatial import cKDTree
from scipy.interpolate import CubicSpline
from scipy.ndimage import gaussian_filter1d
from shapely.geometry import LineString, Point, Polygon, MultiPolygon, box, mapping, shape
from shapely.ops import transform, unary_union, polygonize
from shapely.prepared import prep
from PIL import Image, ImageDraw
from scipy.ndimage import map_coordinates

OUT = ROOT/'data/routes/kerala_coast'

PROJECT = Transformer.from_crs('EPSG:4326', 'EPSG:32643', always_xy=True)
INVERSE = Transformer.from_crs('EPSG:32643', 'EPSG:4326', always_xy=True)
# Easting/northing origin is fixed, not the first point in a mutable download.
ORIGIN = (642000.0, 1102000.0)
BBOX = (76.15, 8.10, 77.60, 10.05)
PBF = CACHE / 'southern-zone-261006.osm.pbf'

def xy(lon, lat):
    e, n = PROJECT.transform(lon, lat)
    return [round(e-ORIGIN[0], 3), round(ORIGIN[1]-n, 3)]

def inside(lon, lat):
    return BBOX[0] <= lon <= BBOX[2] and BBOX[1] <= lat <= BBOX[3]

def write_json(path, data):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(data, ensure_ascii=False, separators=(',', ':'))+'\n', encoding='utf-8')

class RailExtract(osmium.SimpleHandler):
    def __init__(self):
        super().__init__()
        self.ways, self.stations = [], []

    def node(self, n):
        if n.tags.get('railway') not in ('station','halt'): return
        if inside(n.location.lon, n.location.lat):
            self.stations.append(dict(id=n.id, tags=dict(n.tags), lon=n.location.lon,
                                      lat=n.location.lat, point=xy(n.location.lon,n.location.lat)))

    def way(self, w):
        if w.tags.get('railway') not in ('rail','construction','platform'): return
        if not any(n.location.valid() and inside(n.lon,n.lat) for n in w.nodes): return
        if not all(n.location.valid() for n in w.nodes): return
        self.ways.append(dict(id=w.id, tags=dict(w.tags), nodes=[n.ref for n in w.nodes],
                             ll=[[n.lon,n.lat] for n in w.nodes], points=[xy(n.lon,n.lat) for n in w.nodes]))

def extract():
    checksum = hashlib.md5(PBF.read_bytes()).hexdigest()
    expected = PBF.with_suffix('.pbf.md5').read_text().split()[0]
    if checksum != expected: raise ValueError('OSM download checksum mismatch')
    handler = RailExtract()
    handler.apply_file(str(PBF), locations=True, idx='flex_mem', filters=[osmium.filter.KeyFilter('railway')])
    write_json(CACHE/'rails.json', dict(source=PBF.name, md5=checksum, ways=handler.ways,stations=handler.stations))
    print(f'{len(handler.ways)} railway/platform ways; {len(handler.stations)} stations', flush=True)
    for s in sorted(handler.stations, key=lambda s:-s['lat']):
        print(s['tags'].get('ref','?'), s['tags'].get('name:en',s['tags'].get('name','?')), s['lat'],s['lon'])

def plan():
    data=json.loads((CACHE/'rails.json').read_text(encoding='utf-8'))
    graph=defaultdict(list); points={}; segments={}; main_nodes=set()
    for w in data['ways']:
        if w['tags'].get('railway')!='rail' or w['tags'].get('gauge','1676')!='1676': continue
        penalty=5.0 if w['tags'].get('service') else 1.0
        for node,p in zip(w['nodes'],w['points']):
            points[node]=p
            if penalty==1: main_nodes.add(node)
        for a,b in zip(w['nodes'],w['nodes'][1:]):
            d=math.dist(points[a],points[b])
            graph[a].append((b,d*penalty)); graph[b].append((a,d*penalty))
            segments[min(a,b),max(a,b)]=w
    ids=sorted(main_nodes); tree=cKDTree([points[n] for n in ids])
    refs=['ERN','ERS','TNU','KUMM','AROR','EZP','TUVR','SRTL','ALLP','AMPA','HAD','KYJ','QLN','VAK','TVC','NYY','KZT','ERL','NJT','NCJ','SUCH']
    anchors=[]
    for ref in refs:
        choices=[s for s in data['stations'] if s['tags'].get('ref')==ref and s['tags'].get('station')!='subway']
        if ref=='ERS': choices=[s for s in choices if 'Junction' in s['tags'].get('name','')]
        assert len(choices)==1,(ref,choices)
        anchors.append(ids[tree.query(choices[0]['point'])[1]])
    route=[]
    for start,end in zip(anchors,anchors[1:]):
        queue=[(0,start)]; distances={start:0}; previous={}
        while queue:
            d,n=heapq.heappop(queue)
            if n==end: break
            if d>distances[n]: continue
            for nxt,cost in graph[n]:
                if d+cost < distances.get(nxt,float('inf')):
                    distances[nxt]=d+cost; previous[nxt]=n; heapq.heappush(queue,(d+cost,nxt))
        if end not in distances: raise ValueError(f'Disconnected OSM railway: {start} to {end}')
        part=[end]
        while part[-1]!=start: part.append(previous[part[-1]])
        route.extend(list(reversed(part))[0 if not route else 1:])
    original=LineString([points[n] for n in route])
    terminals={code:next(s for s in data['stations'] if s['tags'].get('ref')==code and 'Junction' in s['tags'].get('name','')) for code in ['ERS','NCJ']}
    start=original.project(Point(terminals['ERS']['point']))-700
    end=original.project(Point(terminals['NCJ']['point']))+700
    raw=np.array([points[n] for n in route]); cum=np.r_[0,np.cumsum(np.linalg.norm(np.diff(raw,axis=0),axis=1))]
    lo=max(0,int(np.searchsorted(cum,start))-1); hi=min(len(route),int(np.searchsorted(cum,end))+1)
    route=route[lo:hi]
    raw=np.array([points[n] for n in route]); lengths=np.linalg.norm(np.diff(raw,axis=0),axis=1)
    assert np.all(lengths>0)
    cum=np.r_[0,np.cumsum(lengths)]
    # A gently smoothed horizontal polyline: no large radii invented across yards.
    # Densification and smoothing are limited to 0.6 m departure from the source.
    samples=np.arange(0,cum[-1],5.0); samples=np.r_[samples,cum[-1]]
    linear=np.stack([np.interp(samples,cum,raw[:,i]) for i in range(2)],axis=1)
    smooth=np.stack([gaussian_filter1d(linear[:,i],2.0,mode='nearest') for i in range(2)],axis=1)
    delta=smooth-linear; norm=np.linalg.norm(delta,axis=1)
    smooth=linear+delta*np.minimum(1,.6/np.maximum(norm,1e-10))[:,None]
    smooth[0]=raw[0]; smooth[-1]=raw[-1]
    line=LineString(smooth); stations=[]
    for s in data['stations']:
        if s['tags'].get('station')=='subway': continue
        p=Point(s['point']); d=line.distance(p)
        if d>(450 if s['tags'].get('ref')=='TVCN' else 120): continue
        chain=line.project(p)
        if chain<1 and s['tags'].get('ref')!='ERS': continue
        if chain>line.length-1 and s['tags'].get('ref')!='NCJ': continue
        stations.append(dict(code=s['tags'].get('ref',''),name=s['tags'].get('name:en',s['tags'].get('name','')),
            local_name=s['tags'].get('name:ml',s['tags'].get('name:ta','')),osm_id=s['id'],lon=s['lon'],lat=s['lat'],s=round(chain,3),distance=round(d,2),point=s['point']))
    stations.sort(key=lambda s:s['s'])
    # Record exact OSM source ways and bridge/tunnel spans along the selected path.
    spans=[]
    for i,(a,b) in enumerate(zip(route,route[1:])):
        w=segments[min(a,b),max(a,b)]
        if spans and spans[-1]['osm_id']==w['id']: spans[-1]['end']=round(float(cum[i+1]),3)
        else: spans.append(dict(start=round(float(cum[i]),3),end=round(float(cum[i+1]),3),osm_id=w['id'],tags=w['tags']))
    result=dict(name='Kerala Coast · Ernakulam–Alappuzha–TVC–Nagercoil',id='kerala_coast',
        crs='EPSG:32643',origin=list(ORIGIN),source=data['source'],source_md5=data['md5'],
        raw_length_m=round(float(cum[-1]),3),length_m=round(line.length,3),stations=stations,spans=spans,
        alignment=[[round(float(v),3) for v in p] for p in smooth])
    write_json(CACHE/'alignment.json',result)
    print(f'Alignment {line.length/1000:.3f} km; {len(stations)} stations; {len(smooth)} samples',flush=True)
    for s in stations: print(s['code'],s['name'],round(s['s']/1000,3),s['distance'])

def features():
    route=json.loads((CACHE/'alignment.json').read_text(encoding='utf-8'))
    corridor=LineString(route['alignment']).simplify(2).buffer(1800,quad_segs=4)
    region=prep(corridor)
    factory=osmium.geom.GeoJSONFactory()
    processor=osmium.FileProcessor(str(PBF)).with_locations().with_areas(
        osmium.filter.KeyFilter('natural','landuse','water','waterway','building','railway','leisure'))
    processor.with_filter(osmium.filter.KeyFilter('natural','landuse','water','waterway','building','railway','leisure','highway','man_made'))
    output=[]; coastline=[]
    def project(x,y,z=None):
        a,b=PROJECT.transform(x,y)
        return np.asarray(a)-ORIGIN[0],ORIGIN[1]-np.asarray(b)
    def save(geom,kind,obj,tags):
        if not geom.is_valid: geom=geom.buffer(0)
        if geom.is_empty or not region.intersects(geom): return
        clipped=geom if region.contains(geom) else geom.intersection(corridor)
        if not clipped.is_empty:
            kept={k:v for k,v in tags.items() if k in ('name','name:en','name:ml','name:ta','ref','building','building:levels','height','roof:shape','roof:colour','building:colour','natural','landuse','water','waterway','highway','bridge','tunnel','layer','railway','service','gauge','electrified','voltage','operator','man_made','leisure')}
            output.append(dict(id=f'{obj.type_str()}{obj.id}',kind=kind,tags=kept,geometry=mapping(clipped.simplify(.15,preserve_topology=True))))
    for obj in processor:
        tags=dict(obj.tags)
        if obj.is_way():
            kind='road' if 'highway' in tags else ('stream' if 'waterway' in tags and tags['waterway']!='riverbank' else ('rail' if tags.get('railway') in ('rail','construction') else ('coast' if tags.get('natural')=='coastline' else '')))
            if not kind or len(obj.nodes)<2 or not all(n.location.valid() for n in obj.nodes): continue
            if not any(inside(n.lon,n.lat) for n in obj.nodes): continue
            geom=LineString([xy(n.lon,n.lat) for n in obj.nodes])
            if kind=='coast': coastline.append(geom); continue
            save(geom,kind,obj,tags)
        elif obj.is_area():
            kind='building' if 'building' in tags else ('water' if tags.get('natural')=='water' or 'water' in tags or tags.get('waterway')=='riverbank' else ('platform' if tags.get('railway')=='platform' else ('land' if 'landuse' in tags or tags.get('natural') in ('wood','wetland','scrub','beach') or 'leisure' in tags else '')))
            if not kind: continue
            if not any(inside(n.lon,n.lat) for ring in obj.outer_rings() for n in ring if n.location.valid()): continue
            try: geom=transform(project,shape(json.loads(factory.create_multipolygon(obj))))
            except (RuntimeError,ValueError): continue
            save(geom,kind,obj,tags)
    # Coastline separates Arabian Sea from land; coastline stays a linear source.
    bounds=box(*corridor.bounds).buffer(1000).envelope
    coast=unary_union(coastline)
    network=unary_union([coast.intersection(bounds),bounds.boundary])
    sea=[]
    from shapely.ops import nearest_points
    for poly in polygonize(network):
        p=poly.representative_point(); nearest=nearest_points(p,coast)[1]
        if p.x<nearest.x and poly.area>100000:
            sea.append(poly.intersection(corridor))
    if sea: output.append(dict(id='osm-coastline-derived',kind='water',tags={'name':'Arabian Sea','water':'sea'},geometry=mapping(unary_union(sea))))
    write_json(CACHE/'features.json',dict(features=output))
    from collections import Counter
    print('FEATURES',dict(Counter(f['kind'] for f in output)),flush=True)

class Elevation:
    def __init__(self):
        self.tiles={}
        for path in sorted(CACHE.glob('N??E???.tif')):
            lat=int(path.stem[1:3]); lon=int(path.stem[4:7])
            raster=np.array(Image.open(path),dtype=float)
            raster[raster<-1000]=0
            self.tiles[lon,lat]=raster

    def sample(self,x,z):
        lon,lat=INVERSE.transform(np.asarray(x)+ORIGIN[0],ORIGIN[1]-np.asarray(z))
        lon=np.asarray(lon); lat=np.asarray(lat)
        result=np.zeros(lon.shape)
        for (lo,la),raster in self.tiles.items():
            mask=(lon>=lo)&(lon<=lo+1)&(lat>=la)&(lat<=la+1)
            if np.any(mask):
                result[mask]=map_coordinates(raster,[(la+1-lat[mask])*3600,(lon[mask]-lo)*3600],order=1,mode='nearest')
        return result

def terrain():
    data=json.loads((CACHE/'alignment.json').read_text(encoding='utf-8'))
    points=np.array(data['alignment']); line=LineString(points)
    dem=Elevation()
    raw=dem.sample(points[:,0],points[:,1])
    # Radar canopy/building returns are not railway gradients. Median-scale
    # smoothing + a 1.25% grade envelope provides an explicitly approximate rail
    # profile; never publish these heights as a surveyed longitudinal section.
    from scipy.ndimage import percentile_filter
    rail=gaussian_filter1d(percentile_filter(raw,25,size=81),45,mode='nearest')+1.2
    rail=np.maximum(rail,4.5)
    for _ in range(2):
        for i in range(1,len(rail)): rail[i]=min(rail[i],rail[i-1]+.0625)
        for i in range(len(rail)-2,-1,-1): rail[i]=min(rail[i],rail[i+1]+.0625)
    cum=np.r_[0,np.cumsum(np.linalg.norm(np.diff(points,axis=0),axis=1))]
    data['alignment']=[[round(float(p[0]),3),round(float(y),3),round(float(p[1]),3)] for p,y in zip(points,rail)]
    data['chainage']=[round(float(s),3) for s in cum]
    for st in data['stations']:
        st['height']=round(float(np.interp(st['s'],cum,rail)),2)
        st['km_from_ers']=round((st['s']-data['stations'][0]['s'])/1000,3)
    data['rail_profile']='SRTM-derived, smoothed and grade-limited approximation; not surveyed track elevations'
    data['source_url']='https://download.geofabrik.de/asia/india/southern-zone-261006.osm.pbf'
    data['snapshot']='2026-10-06T20:21:06Z'
    data['attribution']='Map data © OpenStreetMap contributors, ODbL 1.0. Terrain: NASA/USGS SRTM GL1 via OpenTopography.'
    tiles=[]; area=prep(line.buffer(11000,quad_segs=4))
    (OUT/'elevation').mkdir(parents=True,exist_ok=True)
    lowx,lowz,highx,highz=line.buffer(11000).bounds
    for tx in range(math.floor(lowx/4096),math.floor(highx/4096)+1):
        for tz in range(math.floor(lowz/4096),math.floor(highz/4096)+1):
            if not area.intersects(box(tx*4096,tz*4096,(tx+1)*4096,(tz+1)*4096)): continue
            xx,zz=np.meshgrid(np.arange(129)*32+tx*4096,np.arange(129)*32+tz*4096)
            y=np.rint(dem.sample(xx,zz)*10).clip(-32767,32767).astype('<i2')
            (OUT/'elevation'/f'{tx}_{tz}.bin').write_bytes(b'KDEM'+y.tobytes())
            tiles.append([tx,tz])
    data['elevation_tiles']=tiles
    write_json(OUT/'route.json',data)
    print('TERRAIN',len(tiles),'tiles; rail elevation',float(rail.min()),float(rail.max()),flush=True)

def sections():
    from shapely import STRtree
    route=json.loads((OUT/'route.json').read_text(encoding='utf-8'))
    raw=json.loads((CACHE/'rails.json').read_text(encoding='utf-8'))
    ways=[w for w in raw['ways'] if w['tags'].get('railway')=='rail' and not w['tags'].get('service') and w['tags'].get('gauge','1676')=='1676']
    lines=[LineString(w['points']) for w in ways]; tree=STRtree(lines)
    main=LineString([[p[0],p[2]] for p in route['alignment']]); output=[]
    for a,b in zip(route['stations'],route['stations'][1:]):
        observations=[]
        for s in np.arange(a['s']+700,b['s']-700,125):
            p=main.interpolate(s); parallel=False
            tangent=np.array(main.interpolate(s+5).coords[0])-np.array(main.interpolate(s-5).coords[0]); tangent/=np.linalg.norm(tangent)
            for idx in tree.query(p.buffer(55)):
                line=lines[idx]; along=line.project(p); q=line.interpolate(along); d=p.distance(q)
                if not 3.8<d<50: continue
                other=np.array(line.interpolate(min(line.length,along+5)).coords[0])-np.array(line.interpolate(max(0,along-5)).coords[0])
                if np.linalg.norm(other)>0 and abs(np.dot(tangent,other/np.linalg.norm(other)))>.96: parallel=True; break
            observations.append(parallel)
        coverage=sum(observations)/max(1,len(observations))
        output.append(dict(a=a['code'],b=b['code'],start=a['s']+500,end=b['s']-500,
            mapped_parallel_fraction=round(coverage,3),tracks=2 if coverage>.6 else 1))
    route['sections']=output
    for station in route['stations']:
        raw_station=next(s for s in raw['stations'] if s['id']==station['osm_id'])
        station['halt']=raw_station['tags'].get('railway')=='halt'
        station['major']=station['code'] in ['ERS','ALLP','KYJ','QLN','TVCN','TVC','NCJ']
    route['operational_geometry']='Mapped main alignment with reconstructed station loops and signalling; track count inferred from mapped parallel running lines, not a current railway engineering survey.'
    write_json(OUT/'route.json',route)
    print('SECTIONS',len(output),'single',sum(s['tracks']==1 for s in output),'double',sum(s['tracks']==2 for s in output),flush=True)
    print([(s['a'],s['b'],s['tracks'],s['mapped_parallel_fraction']) for s in output])

def tiles():
    from shapely import STRtree
    from shapely import constrained_delaunay_triangles
    source=json.loads((CACHE/'features.json').read_text(encoding='utf-8'))['features']
    geometries=[shape(f['geometry']) for f in source]; tree=STRtree(geometries)
    route=json.loads((OUT/'route.json').read_text(encoding='utf-8'))
    line=LineString([[p[0],p[2]] for p in route['alignment']]); area=prep(line.buffer(1700,quad_segs=4))
    lowx,lowz,highx,highz=line.buffer(1700).bounds; keys=[]; counts=defaultdict(int)
    dem=Elevation()
    for f,geom in zip(source,geometries):
        if f['kind']!='water': continue
        polygons=list(geom.geoms) if geom.geom_type=='MultiPolygon' else ([geom] if geom.geom_type=='Polygon' else [])
        coords=np.array([p for poly in polygons for p in poly.exterior.coords])
        if len(coords)>500: coords=coords[::max(1,len(coords)//500)]
        f['water_height']=0.0 if f['tags'].get('water')=='sea' else (round(float(np.percentile(dem.sample(coords[:,0],coords[:,1]),10)),1) if len(coords) else 0.0)
    for tx in range(math.floor(lowx/512),math.floor(highx/512)+1):
        for tz in range(math.floor(lowz/512),math.floor(highz/512)+1):
            bounds=box(tx*512,tz*512,(tx+1)*512,(tz+1)*512)
            if not area.intersects(bounds): continue
            features=[]
            for i in tree.query(bounds):
                f=source[i]; geom=geometries[i]
                if f['kind'] in ('building','platform'):
                    centre=geom.centroid
                    if (math.floor(centre.x/512),math.floor(centre.y/512))!=(tx,tz): continue
                else: geom=geom.intersection(bounds)
                if geom.is_empty: continue
                # Keep polygon holes: islands/courtyards must not be flooded/filled.
                local=transform(lambda x,y,z=None:(np.asarray(x)-tx*512,np.asarray(y)-tz*512),geom)
                features.append(dict(id=f['id'],kind=f['kind'],tags=f['tags'],geometry=mapping(local),water_height=f.get('water_height',0.0)))
                counts[f['kind']]+=1
            key=f'{tx}_{tz}'
            mask=Image.new('L',(64,64),0)
            for kind in ['land','water','road','stream','building','platform']:
                for f in features:
                    if f['kind']!=kind: continue
                    geom=shape(f['geometry']); tags=f['tags']
                    code={'land':3 if tags.get('natural') in ['wood','scrub'] or tags.get('landuse') in ['forest','orchard'] else (2 if tags.get('landuse') in ['farmland','meadow','grass','farmyard'] else (5 if tags.get('natural')=='beach' else 1)), 'water':4,'stream':4,'road':6,'building':7,'platform':8}[kind]
                    polygons=list(geom.geoms) if geom.geom_type=='MultiPolygon' else ([geom] if geom.geom_type=='Polygon' else [])
                    layer=Image.new('L',(64,64),0); draw=ImageDraw.Draw(layer)
                    for poly in polygons:
                        draw.polygon([(x/8,y/8) for x,y in poly.exterior.coords],fill=255)
                        for ring in poly.interiors: draw.polygon([(x/8,y/8) for x,y in ring.coords],fill=0)
                    lines=list(geom.geoms) if geom.geom_type=='MultiLineString' else ([geom] if geom.geom_type=='LineString' else [])
                    for ln in lines: draw.line([(x/8,y/8) for x,y in ln.coords],fill=255,width=2 if kind=='road' else 1)
                    mask.paste(code,mask=layer)
                    if kind in ['water','platform']:
                        tris=[]
                        for poly in polygons:
                            for tri in constrained_delaunay_triangles(poly).geoms:
                                tris.append([[round(x,3),round(z,3)] for x,z in list(tri.exterior.coords)[:3]])
                        f['triangles']=tris
            write_json(OUT/'tiles'/f'{key}.json',dict(origin=[tx*512,tz*512],mask=base64.b64encode(mask.tobytes()).decode(),features=features))
            keys.append([tx,tz])
    route['scenery_tiles']=keys
    route['feature_counts']={kind:sum(f['kind']==kind for f in source) for kind in sorted(counts)}
    write_json(OUT/'route.json',route)
    print('SCENERY TILES',len(keys),dict(counts),flush=True)

if __name__ == '__main__':
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('step', choices=['extract','plan','features','terrain','sections','tiles'])
    args=parser.parse_args()
    if args.step=='extract': extract()
    elif args.step=='plan': plan()
    elif args.step=='features': features()
    elif args.step=='terrain': terrain()
    elif args.step=='sections': sections()
    elif args.step=='tiles': tiles()
