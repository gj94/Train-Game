"""Independent full-footprint audit of road earthworks emitted by Godot."""
import argparse
from collections import Counter
import json
from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / '.local/kerala-route/python'))
from shapely import affinity
from shapely.geometry import Polygon, LineString, Point, shape
from shapely.strtree import STRtree
from road_surfaces import Ground

WIDTHS = dict(motorway=10, trunk=9, primary=8, secondary=6.5, tertiary=5.5,
              residential=4.5, service=3.6, footway=1.5, path=1, track=2.8)

def audit(context, path):
    ground = Ground(context, ROOT/'data/routes/kerala_coast')
    rails = [LineString([(p[0], p[2]) for p in e['points']]).buffer(3.5)
             for e in context['rails']]
    stations = [Polygon(p['ring']) for p in context['platforms']]
    stations += [Polygon(z['ring']) for z in context['zones']]
    rail_tree, station_tree = STRtree(rails), STRtree(stations)
    posts=[Point(span[end]).buffer(.7) for span in context.get('overhead',[]) for end in ('a','b')]
    post_tree=STRtree(posts)
    cached, counts, failures = {}, Counter(), []
    profiles = {}
    for row in json.loads((ROOT / 'assets/models/scenery/road-surfaces.json').read_text(encoding='utf8'))['segments']:
        profiles.setdefault(row[0], []).append(row)

    def height(way, point):
        for row in profiles.get(way, []):
            _, ax, az, ay, bx, bz, by, _ = row
            dx, dz = bx-ax, bz-az
            t = max(0, min(1, ((point.x-ax)*dx+(point.y-az)*dz)/max(1e-9, dx*dx+dz*dz)))
            if (point.x-ax-t*dx)**2+(point.y-az-t*dz)**2 <= .06**2:
                return ay+(by-ay)*t
        return None

    def fail(row, kind, **detail):
        counts[kind] += 1
        if len(failures) < 100:
            failures.append(dict(tile=row['tile'], way=row['way'], kind=kind, **detail))

    def features(tx,tz):
        # Support feet may extend beyond a clipped road's tile. Inspect the
        # neighbouring mapped footprints too, not only the tile owning it.
        for x in range(tx-1,tx+2):
            for z in range(tz-1,tz+2):
                source=ROOT/f'data/routes/kerala_coast/tiles/{x}_{z}.json'
                if not source.exists():continue
                for f in json.loads(source.read_text(encoding='utf8')).get('features',[]):
                    yield f,x*512,z*512

    for raw in path.open(encoding='utf8'):
        row = json.loads(raw)
        if not row.get('supports'):continue
        tx, tz = row['tile']; ox, oz = tx*512, tz*512
        key = (tx, tz)
        if key not in cached:
            obstacles, labels, roads = [], [], []
            for f,fx,fz in features(tx,tz):
                kind, tags = f['kind'], f.get('tags', {})
                g = affinity.translate(shape(f['geometry']), fx, fz)
                if kind in ('water', 'building'):
                    obstacles.append(g.buffer(0)); labels.append(kind)
                elif kind == 'rail' and tags.get('railway') == 'rail':
                    obstacles.append(g.buffer(3.1)); labels.append('mapped_rail')
                elif kind == 'stream' and tags.get('tunnel', 'no') == 'no' and tags.get('covered') != 'yes':
                    obstacles.append(g.buffer(4 if tags.get('waterway') == 'river' else 1.2, cap_style=2)); labels.append('stream')
                elif kind == 'road' and tags.get('tunnel', 'no') == 'no' and tags.get('highway') not in ('proposed', 'construction'):
                    roads.append((f['id'], g, WIDTHS.get(tags.get('highway'), 4)*.5))
            road_shapes=[line.buffer(width) for _,line,width in roads]
            cached[key] = (obstacles, labels, STRtree(obstacles), roads, road_shapes, STRtree(road_shapes))
        obstacles, labels, tree, roads, road_shapes, road_tree = cached[key]
        for support in row['supports']:
            counts['supports'] += 1; counts[support['kind']] += 1
            foot = Polygon([(p[0]+ox, p[2]+oz) for p in support['foot']])
            if not foot.is_valid or foot.area < .001:
                fail(row, 'invalid_footprint'); continue
            for geoms, index, label in [(rails, rail_tree, 'rail'), (stations, station_tree, 'station'), (posts,post_tree,'ohe')]:
                for i in index.query(foot, predicate='intersects'):
                    overlap = foot.intersection(geoms[int(i)]).area
                    if overlap > .02:fail(row, label+'_conflict', area=overlap)
            for i in tree.query(foot, predicate='intersects'):
                i = int(i); overlap = foot.intersection(obstacles[i]).area
                if overlap > .02:fail(row, labels[i]+'_conflict', area=overlap)
            top = support['top']
            # The top record is the underside of the slab, 40 cm below the road.
            top_min = min(p[1] for p in top)+.4
            for index in road_tree.query(foot,predicate='intersects'):
                index=int(index);other,line,width=roads[index]
                if other == row['way']:continue
                overlap = foot.intersection(road_shapes[index])
                if overlap.area < .02:continue
                point = line.interpolate(line.project(overlap.representative_point()))
                y = height(other, point)
                if y is None:y=ground.height(point)+.07
                if y < top_min-.85:
                    fail(row, 'lower_road_conflict', other=other, road_height=y, approach_height=top_min)
            # Earth batters must be useful slopes, not tall walls painted brown.
            if support['kind'] == 'earth':
                for a, b in zip(support.get('bank',support['top']), support['foot']):
                    run = ((b[0]-a[0])**2+(b[2]-a[2])**2)**.5
                    if a[1]-b[1] > run/1.35+.21:
                        fail(row, 'steep_batter', rise=a[1]-b[1], run=run)
    return dict(ok=not failures, counts=dict(counts), tiles=len(cached), failures=failures,
                note='Actual support footprints; independent Shapely rail/station/building/water/road audit. No railway advancement.')

if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--context', type=Path, default=ROOT/'.local/scenery-context.json')
    parser.add_argument('--triangles', type=Path, required=True)
    parser.add_argument('--output', type=Path, required=True)
    args = parser.parse_args()
    result = audit(json.loads(args.context.read_text(encoding='utf8')), args.triangles)
    args.output.write_text(json.dumps(result, indent=2)+'\n', encoding='utf8')
    print(json.dumps({k:v for k,v in result.items() if k != 'failures'}))
    sys.exit(0 if result['ok'] else 1)
