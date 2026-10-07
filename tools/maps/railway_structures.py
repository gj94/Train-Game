"""Reconstruct supported rail crossings from the same OSM snapshot as the route.

Bridge geometry is interpretive; water intersections are not a railway survey.
The output is OSM-derived data under the route's existing ODbL attribution.
"""
import json
from kerala_route import CACHE, OUT, Elevation, write_json
import numpy as np
from shapely.geometry import LineString, Point, shape

route = json.loads((OUT / 'route.json').read_text(encoding='utf-8'))
line = LineString([(p[0], p[2]) for p in route['alignment']])
intervals = [dict(start=s['start'], end=s['end'], mapped_bridge=True,
                  sources=[str(s['osm_id'])], water_height=None)
             for s in route['spans'] if s['tags'].get('bridge', 'no') != 'no']
features = json.loads((CACHE / 'features.json').read_text(encoding='utf-8'))['features']
dem = Elevation()
for feature in features:
    if feature['kind'] not in ('water', 'stream'):
        continue
    geometry = shape(feature['geometry'])
    water_level = None
    if feature['kind'] == 'water':
        polygons = list(geometry.geoms) if geometry.geom_type == 'MultiPolygon' else [geometry]
        coordinates = np.array([p for polygon in polygons for p in polygon.exterior.coords])
        if len(coordinates) > 500:
            coordinates = coordinates[::max(1, len(coordinates) // 500)]
        water_level = round(float(np.percentile(dem.sample(coordinates[:, 0], coordinates[:, 1]), 10)), 1)
    if feature['kind'] == 'stream':
        geometry = geometry.buffer(4 if feature['tags'].get('waterway') == 'river' else 1.2)
    crossing = line.intersection(geometry)
    pieces = list(crossing.geoms) if hasattr(crossing, 'geoms') else [crossing]
    for piece in pieces:
        if piece.geom_type != 'LineString' or piece.length < .5:
            continue
        ends = [line.project(Point(p)) for p in [piece.coords[0], piece.coords[-1]]]
        coords = np.array(piece.coords)
        water = water_level if water_level is not None else float(np.percentile(dem.sample(coords[:, 0], coords[:, 1]), 10))
        if feature['tags'].get('water') == 'sea':
            water = 0.0
        intervals.append(dict(start=min(ends), end=max(ends), mapped_bridge=False,
                              sources=[str(feature['id'])], water_height=round(water, 2)))
intervals.sort(key=lambda item: item['start'])
merged = []
for item in intervals:
    item = item.copy()
    item['start'] = max(0, item['start'] - 6)
    item['end'] = min(route['length_m'], item['end'] + 6)
    if merged and item['start'] <= merged[-1]['end'] + 2:
        target = merged[-1]
        target['end'] = max(target['end'], item['end'])
        target['mapped_bridge'] |= item['mapped_bridge']
        target['sources'] = sorted(set(target['sources'] + item['sources']))
        values = [v for v in [target['water_height'], item['water_height']] if v is not None]
        target['water_height'] = min(values) if values else None
    else:
        merged.append(item)
for item in merged:
    item['start'] = round(item['start'], 3)
    item['end'] = round(item['end'], 3)
write_json(OUT / 'structures.json', dict(description='Reconstructed bridge envelopes from tagged OSM bridges and mapped water crossings, with 6 m bank overlap.', bridges=merged))
print('BRIDGES', len(merged), 'water-inferred-only', sum(not x['mapped_bridge'] for x in merged))
print('FIRST_12_KM', json.dumps([x for x in merged if x['start'] < 12000]))
