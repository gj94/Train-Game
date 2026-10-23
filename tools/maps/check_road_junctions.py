"""Independently sample generated profiles at simplified road T-junctions."""
import argparse
from collections import defaultdict
import json
import math
from pathlib import Path

from road_surfaces import ROOT, Ground
from shapely.geometry import Point


class Profiles:
    def __init__(self, path):
        self.cells = defaultdict(list)
        for row in json.loads(path.read_text(encoding="utf8"))["segments"]:
            for x in range(math.floor((min(row[1],row[4])-.06)/64), math.floor((max(row[1],row[4])+.06)/64)+1):
                for z in range(math.floor((min(row[2],row[5])-.06)/64), math.floor((max(row[2],row[5])+.06)/64)+1):
                    self.cells[(row[0],x,z)].append(row)

    def sample(self, way, p):
        best, height = .06**2, None
        for row in self.cells[(way,math.floor(p[0]/64),math.floor(p[1]/64))]:
            dx,dz = row[4]-row[1],row[5]-row[2]
            t = max(0,min(1,((p[0]-row[1])*dx+(p[1]-row[2])*dz)/max(.000001,dx*dx+dz*dz)))
            distance = (p[0]-row[1]-dx*t)**2+(p[1]-row[2]-dz*t)**2
            if distance <= best:
                best,height = distance,row[3]+(row[6]-row[3])*t
        return height


def audit(profiles, junctions, ground):
    checked, seen, failures, largest = 0,set(),[],0.0
    for junction in junctions:
        p = junction["point"]
        key = (*sorted((junction["way"],junction["other"])), *[round(v,3) for v in p])
        if key in seen:
            continue
        seen.add(key)
        a,b = (profiles.sample(junction[k],p) for k in ("way","other"))
        if a is None and b is None:
            continue
        fallback = ground.height(Point(p))+.07 if a is None or b is None else 0
        a,b = fallback if a is None else a, fallback if b is None else b
        delta = abs(a-b)
        largest = max(largest,delta);checked+=1
        if delta > .025:
            failures.append(dict(**junction,heights=[a,b],difference=delta))
    failures.sort(key=lambda row:row["difference"],reverse=True)
    return dict(checked=checked,maximum_difference=largest,failure_count=len(failures),failures=failures)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--profiles",type=Path,default=ROOT/"assets/models/scenery/road-surfaces.json")
    parser.add_argument("--report",type=Path,default=ROOT/".local/road-surfaces-report.json")
    parser.add_argument("--context",type=Path,default=ROOT/".local/scenery-context.json")
    parser.add_argument("--output",type=Path,required=True)
    args = parser.parse_args()
    ground = Ground(json.loads(args.context.read_text(encoding="utf8")),ROOT/"data/routes/kerala_coast")
    report = audit(Profiles(args.profiles),json.loads(args.report.read_text(encoding="utf8"))["junctions"],ground)
    args.output.write_text(json.dumps(report,indent=2)+"\n",encoding="utf8")
    print(json.dumps({k:v for k,v in report.items() if k!="failures"}))
    raise SystemExit(1 if report["failure_count"] else 0)
