"""Geometry conversion regressions; run with the project's cached map dependencies."""
import copy
import importlib.util
import json
from pathlib import Path
import sys
import unittest

ROOT = next(p for p in Path(__file__).resolve().parents if (p/'project.godot').exists())
sys.path.insert(0,str(ROOT/'.local/kerala-route/python'))
spec=importlib.util.spec_from_file_location('rail_geometry',Path(__file__).with_name('rail_geometry.py'))
geometry=importlib.util.module_from_spec(spec);spec.loader.exec_module(geometry)

class RailGeometryTests(unittest.TestCase):
    def test_route_preserves_datums_and_elevations_and_is_idempotent(self):
        source=json.loads((ROOT/'data/routes/kerala_coast/route.json').read_text(encoding='utf8'))
        result=geometry.smooth_route(source)
        self.assertEqual(result['chainage'],source['chainage'])
        self.assertEqual(result['stations'],source['stations'])
        self.assertEqual([p[1] for p in result['alignment']],[p[1] for p in source['alignment']])
        self.assertEqual(result['alignment'][0],source['alignment'][0])
        self.assertEqual(result['alignment'][-1],source['alignment'][-1])
        self.assertEqual(geometry.smooth_route(result),result)

    def test_real_operations_keep_csv_totals_and_stable_road_ids(self):
        source=json.loads((ROOT/'data/routes/kerala_coast/operations.json').read_text(encoding='utf8'))
        unchanged=copy.deepcopy(source)
        result=geometry.normalize_operations(source)
        self.assertEqual(source,unchanged)
        self.assertEqual(geometry.normalize_operations(result),result)
        for before,after in zip(source['stations'],result['stations']):
            self.assertEqual(geometry.face_count(after['roads']),after['register_platforms'],after['code'])
            self.assertEqual([r['road'] for r in after['roads']],[r['road'] for r in before['roads']])
        for section in result['sections']:
            if section['tracks']==2:self.assertLess(section['down_offset'],section['up_offset'])

    def test_single_track_is_not_invented_into_double_track(self):
        source=json.loads((ROOT/'data/routes/kerala_coast/operations.json').read_text(encoding='utf8'))
        result=geometry.normalize_operations(source)
        self.assertEqual([(s['a'],s['b'],s['tracks']) for s in source['sections']],[(s['a'],s['b'],s['tracks']) for s in result['sections']])

    def test_gentle_polyline_corner_is_smoothed_without_moving_endpoints(self):
        import numpy as np
        chain=list(range(0,1005,5))
        route={'chainage':chain,'alignment':[[s,3,max(0,s-500)*.1] for s in chain],'stations':[]}
        result=geometry.smooth_route(route)
        self.assertNotEqual(result['alignment'][100],route['alignment'][100])
        self.assertEqual(result['alignment'][0],route['alignment'][0])
        self.assertEqual(result['alignment'][-1],route['alignment'][-1])
        points=np.array(result['alignment'])[:,[0,2]]
        headings=np.arctan2(*(np.diff(points,axis=0).T[::-1]))
        self.assertLess(np.max(np.abs(np.diff(headings))),.01)

    def test_swapped_main_roads_keep_logical_faces_and_running_directions(self):
        source={'sections':[{'a':'A','b':'B','tracks':2,'parallel_offset':-5}],
                'stations':[{'code':'A','register_platforms':2,'roads':[
                    {'road':1,'offset':0,'lane':'D','platform_width':3},
                    {'road':2,'offset':-5,'lane':'U','platform_width':0},
                    {'road':3,'offset':10,'lane':'D','platform_width':3}]}]}
        result=geometry.normalize_operations(source)
        roads=result['stations'][0]['roads']
        self.assertEqual([(r['road'],r['lane'],r['offset'],r['platform_width']) for r in roads],
                         [(1,'D',-5,3),(2,'U',0,0),(3,'U',10,3)])
        self.assertEqual(geometry.face_count(roads),2)

    def test_unreasonably_large_alignment_change_needs_review(self):
        # A 90-degree kink must not silently move the railway tens of metres.
        chain=list(range(0,1005,5))
        route={'chainage':chain,'alignment':[[min(s,500),3,max(0,s-500)] for s in chain],'stations':[]}
        with self.assertRaises(AssertionError):geometry.smooth_route(route)

if __name__=='__main__':unittest.main()
