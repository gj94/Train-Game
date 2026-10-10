"""Reconstruct continuous railway curves and consistent double-line sides.

The user CSV remains the authority for platform totals. This reconstructs
operating geometry; it does not claim surveyed points or official road numbers.
"""
from __future__ import annotations
import argparse
import copy
import hashlib
import json
from pathlib import Path
import sys

REVISION = 'continuous-curves-lht-v1'
LHT_SOURCE = 'https://indianrailways.gov.in/railwayboard/uploads/directorate/safety/SR_SR/SR_SR_CHAP4.pdf'


def smooth_route(route):
    if route.get('geometry_revision') == REVISION:
        return copy.deepcopy(route)
    import numpy as np
    from scipy.ndimage import gaussian_filter1d
    result = copy.deepcopy(route)
    points = np.asarray(route['alignment'], dtype=float)
    chain = np.asarray(route['chainage'], dtype=float)
    step = float(np.median(np.diff(chain)))
    assert 4.9 < step < 5.1, 'Review smoothing for a different source sample spacing'
    original = points[:, [0, 2]].copy()
    target = gaussian_filter1d(original, 40.0 / step, axis=0, mode='nearest')
    taper = np.clip(np.minimum(chain / 300, (chain[-1] - chain) / 300), 0, 1)
    taper = taper * taper * (3 - 2 * taper)
    points[:, [0, 2]] += (target - original) * taper[:, None]
    movement = np.linalg.norm(points[:, [0, 2]] - original, axis=1)
    assert movement.max() < 6, 'Alignment correction needs manual review beyond six metres'
    result['alignment'] = np.round(points, 3).tolist()
    result['geometry_revision'] = REVISION
    result['curve_reconstruction'] = dict(
        method='40 m Gaussian plan smoothing; 300 m endpoint taper; continuous Hermite sampling in runtime',
        maximum_horizontal_change_m=round(float(movement.max()), 4),
        chainage='Original route chainage, elevations, station and bridge references preserved',
        source_alignment_sha256=hashlib.sha256(json.dumps(route['alignment'], separators=(',', ':')).encode()).hexdigest(),
        scope='Reconstructed smooth alignment, not surveyed engineering curve radii')
    return result


def normalize_operations(operations):
    if operations.get('geometry_revision') == REVISION:
        return copy.deepcopy(operations)
    result = copy.deepcopy(operations)
    paired = set()
    for section in result['sections']:
        if section['tracks'] == 2:
            paired.update((section['a'], section['b']))
            offset = section['parallel_offset']
            section['down_offset'], section['up_offset'] = min(0, offset), max(0, offset)
    for station in result['stations']:
        roads = station['roads']
        count = face_count(roads)
        if len(roads) < 2:
            continue
        if station['code'] in paired and roads[0]['offset'] > roads[1]['offset']:
            # Retain stable game road IDs and CSV faces while fixing which
            # physical source way carries each logical running direction.
            faces = [{k: r[k] for k in ('platform_width', 'platform_sides') if k in r} for r in roads[:2]]
            roads[0], roads[1] = roads[1], roads[0]
            for index, road in enumerate(roads[:2]):
                road['road'], road['lane'] = index + 1, ('D', 'U')[index]
                road.pop('platform_sides', None)
                road.update(faces[index])
        for road in roads[2:]:
            road['lane'] = 'D' if abs(road['offset'] - roads[0]['offset']) <= abs(road['offset'] - roads[1]['offset']) else 'U'
        if station['code'] == 'MQU':
            # Two CSV faces need access in both directions. Their precise track
            # assignment is reconstructed because no working diagram is supplied.
            roads[0]['platform_width'], roads[2]['platform_width'] = roads[2]['platform_width'], roads[0]['platform_width']
            station['geometry_scope'] += ' Two faces placed on the running roads for directional access; precise platform numbering unresolved.'
        for road in roads:
            if road.get('platform_width', 0) <= 0 or road.get('platform_sides'):
                continue
            left = min((road['offset'] - other['offset'] for other in roads if other['offset'] < road['offset'] - 1), default=100)
            right = min((other['offset'] - road['offset'] for other in roads if other['offset'] > road['offset'] + 1), default=100)
            road['platform_side'] = -1 if left > right else 1
        assert face_count(roads) == count, station['code']
        if 'register_platforms' in station:
            assert face_count(roads) == station['register_platforms'], station['code']
    result['geometry_revision'] = REVISION
    result['running_side'] = dict(rule='Left-hand running on paired lines', source=LHT_SOURCE,
                                  scope='General rule 4.06; local exceptions and precise pointwork not independently surveyed')
    return result


def face_count(roads):
    return sum(len(road.get('platform_sides', [road.get('platform_side', 1)])) for road in roads if road.get('platform_width', 0) > 0)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--source', type=Path, required=True)
    parser.add_argument('--output', type=Path, required=True)
    parser.add_argument('--dependencies', type=Path)
    args = parser.parse_args()
    if args.dependencies:
        sys.path.insert(0, str(args.dependencies.resolve()))
    args.output.mkdir(parents=True, exist_ok=True)
    for name, convert in [('route.json', smooth_route), ('operations.json', normalize_operations)]:
        data = json.loads((args.source / name).read_text(encoding='utf8'))
        result = convert(data)
        (args.output / name).write_text((json.dumps(result, ensure_ascii=False, separators=(',', ':')) if name == 'route.json' else json.dumps(result, ensure_ascii=False, indent=2)) + '\n', encoding='utf8')
    print('Prepared smooth alignment and consistent running-line sides; CSV totals preserved.')


if __name__ == '__main__':
    main()
