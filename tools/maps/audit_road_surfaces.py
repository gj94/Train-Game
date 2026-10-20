"""Independent intersection audit of triangles emitted by the real road renderer."""
import argparse
from collections import Counter
import json
from pathlib import Path
import sys
ROOT=Path(__file__).resolve().parents[2]
sys.path.insert(0,str(ROOT/".local/kerala-route/python"))
from shapely.geometry import Polygon,LineString,Point,shape
from shapely.strtree import STRtree
from shapely import affinity

def plane_height(triangle, x, z):
    a,b,c=triangle
    determinant=(b[0]-a[0])*(c[2]-a[2])-(c[0]-a[0])*(b[2]-a[2])
    u=((x-a[0])*(c[2]-a[2])-(c[0]-a[0])*(z-a[2]))/determinant
    v=((b[0]-a[0])*(z-a[2])-(x-a[0])*(b[2]-a[2]))/determinant
    return a[1]+u*(b[1]-a[1])+v*(c[1]-a[1])


def audit(context, path):
    reservations, labels, ceilings = [], [], []
    for p in context["platforms"]:
        reservations.append(Polygon(p["ring"]).buffer(-.03))
        labels.append("platform:"+p["station"]);ceilings.append(p["height"]-1.26+7.3)
    for z in context["zones"]:
        for ring, ceiling, label in [(z["ring"],z["height"]+5,"forecourt"),(z["building"],float("inf"),"building")]:
            reservations.append(Polygon(ring).buffer(-.03));ceilings.append(ceiling);labels.append(label+":"+z["id"])
    tree=STRtree(reservations)
    rail_lines=[LineString([(p[0],p[2],p[1]) for p in e["points"]]) for e in context["rails"]]
    rails=STRtree(rail_lines)
    posts=[Point(o[key]) for o in context.get("overhead",[]) for key in ("a","b")]
    post_tree=STRtree(posts)
    waters={}
    counts=Counter();failures=[]
    for raw in path.open(encoding="utf8"):
        row=json.loads(raw);x,z=row["tile"];ox,oz=x*512,z*512
        tile=(x,z)
        if tile not in waters:
            source=ROOT/f"data/routes/kerala_coast/tiles/{x}_{z}.json"
            wet=[];levels=[]
            for f in json.loads(source.read_text(encoding="utf8")).get("features",[]):
                if f["kind"]!="water":continue
                geometry=affinity.translate(shape(f["geometry"]),ox,oz).buffer(0)
                wet.append(geometry);levels.append(f.get("water_height",0))
            waters[tile]=(STRtree(wet),wet,levels)
        wt, wet, levels=waters[tile]
        for record in row["triangles"]:
            triangle = record["points"] if isinstance(record, dict) else record
            kind = record.get("kind", "road") if isinstance(record, dict) else "road"
            counts["triangles"]+=1
            counts[kind+"_triangles"]+=1
            polygon=Polygon([(p[0]+ox,p[2]+oz) for p in triangle])
            if polygon.area<.0001:continue
            bottom=min(p[1] for p in triangle)-.45
            for index in tree.query(polygon,predicate="intersects"):
                index=int(index)
                if bottom>ceilings[index]:continue
                overlap=polygon.intersection(reservations[index]).area
                if overlap>.025:
                    counts["station_conflicts"]+=1
                    if len(failures)<100:failures.append(dict(tile=tile,way=row["way"],kind=labels[index],area=overlap,triangle=triangle))
            for index in wt.query(polygon,predicate="intersects"):
                index=int(index)
                if min(p[1] for p in triangle)>levels[index]+.55:continue
                overlap=polygon.intersection(wet[index]).area
                if overlap>.025:
                    counts["water_conflicts"]+=1
                    if len(failures)<100:failures.append(dict(tile=tile,way=row["way"],kind="water",area=overlap,triangle=triangle))
            if kind=="road":
                absolute=[(p[0]+ox,p[1],p[2]+oz) for p in triangle]
                for index in rails.query(polygon,predicate="intersects"):
                    index=int(index);line=rail_lines[index];cut=line.intersection(polygon)
                    for part in getattr(cut,"geoms",[cut]):
                        if part.length<.1:continue
                        counts["rail_crossing_checks"]+=1
                        for t in (.05,.5,.95):
                            point=part.interpolate(t,normalized=True)
                            rail_y=line.interpolate(line.project(point)).z
                            clearance=plane_height(absolute,point.x,point.y)-rail_y
                            if .55<clearance<9.45:
                                counts["rail_height_conflicts"]+=1
                                if len(failures)<100:failures.append(dict(tile=tile,way=row["way"],kind="rail_height",
                                    edge=context["rails"][index]["id"],clearance=clearance))
                                break
        for p in row["piers"]:
            counts["piers"]+=1
            point=Point(p[0]+ox,p[2]+oz);index=int(rails.nearest(point))
            distance=point.distance(rail_lines[index])
            if distance<4:
                counts["pier_conflicts"]+=1
                if len(failures)<100:failures.append(dict(tile=tile,way=row["way"],kind="pier",clearance=distance))
            if posts:
                distance=point.distance(posts[int(post_tree.nearest(point))])
                if distance<1.25:
                    counts["pier_ohe_conflicts"]+=1
                    if len(failures)<100:failures.append(dict(tile=tile,way=row["way"],kind="pier_ohe",clearance=distance))
    return dict(ok=not failures,counts=dict(counts),tiles=len(waters),failures=failures,
                note="Independent Shapely check of actual rendered triangles, 3 cm station tolerance; no timetable simulation.")

if __name__=="__main__":
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--context",type=Path,default=ROOT/".local/scenery-context.json")
    parser.add_argument("--triangles",type=Path,default=ROOT/".local/road-render-triangles.jsonl")
    parser.add_argument("--output",type=Path,default=ROOT/".local/road-render-audit.json")
    args=parser.parse_args()
    result=audit(json.loads(args.context.read_text(encoding="utf8")),args.triangles)
    args.output.write_text(json.dumps(result,indent=2)+"\n",encoding="utf8")
    print(json.dumps({k:v for k,v in result.items() if k!="failures"}))
    sys.exit(0 if result["ok"] else 1)
