"""Focused geometry/grade regressions; no railway timetable simulation."""
import math
from pathlib import Path
import struct
import tempfile
import unittest
from road_surfaces import Ground, propagate, water_edge_seeds, railway_edge_seeds, station_walkway, formation_grade
from road_network import build_road_network, junction_aprons, junction_seeds
from shapely.geometry import LineString, box
from shapely.strtree import STRtree


class RoadProfilesTest(unittest.TestCase):
    def test_raised_junction_is_level_across_full_width_but_ground_roads_are_not_flattened(self):
        nodes,edges,contacts=build_road_network([
            ('main',dict(highway='residential'),LineString([(-12,0),(12,0)])),
            ('branch',dict(highway='residential'),LineString([(0,0),(0,18)]))])
        links={i:[] for i in range(len(nodes))}
        for _,_,a,b in edges:
            length=math.dist(nodes[a],nodes[b]);links[a].append((b,length));links[b].append((a,length))
        aprons=junction_aprons(nodes,edges,links,contacts,{'residential':4.5})
        self.assertEqual(len(aprons),1)
        base=[0]*len(nodes)
        self.assertEqual(junction_seeds(aprons,base,{}),{})
        seed={contacts[0]['node']:8}
        heights=propagate(nodes,links,base,seed)
        extra=junction_seeds(aprons,base,heights)
        heights=propagate(nodes,links,base,seed|extra)
        self.assertTrue(all(abs(heights[n]-8)<.00001 for n in aprons[0]))
        self.assertTrue(any(math.dist(nodes[n],(0,0))>=4.5 for n in aprons[0]))

    def test_adjacent_junction_aprons_merge_without_extending_to_other_level(self):
        nodes,edges,contacts=build_road_network([
            ('main',{},LineString([(-12,0),(24,0)])),
            ('one',{},LineString([(0,0),(0,12)])),
            ('two',{},LineString([(4,0),(4,-12)])),
            ('flyover',dict(layer='1',bridge='yes'),LineString([(0,-12),(0,0),(0,12)]))])
        links={i:[] for i in range(len(nodes))}
        for _,_,a,b in edges:
            length=math.dist(nodes[a],nodes[b]);links[a].append((b,length));links[b].append((a,length))
        regions=junction_aprons(nodes,edges,links,contacts,{})
        self.assertEqual(len(regions),1)
        flyover={n for way,_,a,b in edges if way=='flyover' for n in (a,b)}
        self.assertFalse(flyover & regions[0])

    def test_ground_junction_at_profile_boundary_keeps_a_single_cross_slope(self):
        # The approach reaches natural ground just before this junction. The
        # boundary itself has no uplift, but its road mesh is still profiled.
        self.assertEqual(junction_seeds([{0,1,2}],[16.5,15.7,17.0],{}),{})
        self.assertEqual(junction_seeds([{0,1,2}],[16.5,15.7,17.0],{3:15.6},{1}),{0:17.0,1:17.0})

    def network_heights(self, features, seed_way):
        nodes, edges, contacts = build_road_network(features)
        links = {i: [] for i in range(len(nodes))}
        for _, _, a, b in edges:
            length = math.dist(nodes[a], nodes[b])
            links[a].append((b, length)); links[b].append((a, length))
        seeds = {n: 8.0 for way, _, a, b in edges if way == seed_way for n in (a, b)}
        return nodes, edges, propagate(nodes, links, [0]*len(nodes), seeds), contacts

    def test_simplified_kumbalam_t_junction_shares_approach_height(self):
        features = [
            ('branch', {}, LineString([(2084.405,7729.302),(2089.415,7727.937)])),
            ('through', {}, LineString([(2066.215,7705.021),(2087.249,7733.095)]))]
        nodes, edges, heights, contacts = self.network_heights(features, 'branch')
        self.assertEqual(len(contacts), 1)
        self.assertAlmostEqual(contacts[0]['gap'], .001724477836, places=8)
        branch = {n for w, _, a, b in edges if w == 'branch' for n in (a,b)}
        through = {n for w, _, a, b in edges if w == 'through' for n in (a,b)}
        shared = branch & through
        self.assertEqual(len(shared), 1)
        self.assertEqual(heights[next(iter(shared))], 8)
        self.assertTrue(all(n in heights for n in through))
        reverse = self.network_heights(list(reversed(features)), 'branch')
        self.assertEqual(sorted((nodes[n], h) for n,h in heights.items()),
                         sorted((reverse[0][n], h) for n,h in reverse[2].items()))

    def test_junction_tolerance_does_not_connect_parallel_or_distant_roads(self):
        for other in ([(0,.01),(20,.01)], [(5,.021),(5,10)]):
            nodes, edges, heights, contacts = self.network_heights([
                ('main', {}, LineString([(-5,0),(25,0)])),
                ('other', {}, LineString(other))], 'main')
            self.assertFalse(contacts)
            self.assertTrue(all(n not in heights for w,_,a,b in edges if w=='other' for n in (a,b)))

    def test_grade_separation_includes_existing_vertices_and_subdivision_crossings(self):
        for over in ([(-6,0),(0,0),(6,0)], [(-6,0),(6,0)]):
            _, edges, heights, contacts = self.network_heights([
                ('over', dict(layer='1', bridge='yes'), LineString(over)),
                ('under', {}, LineString([(0,-6),(0,0),(0,6)]))], 'over')
            self.assertFalse(contacts)
            self.assertTrue(all(n not in heights for w,_,a,b in edges if w=='under' for n in (a,b)))
        _, edges, heights, _ = self.network_heights([
            ('horizontal', {}, LineString([(-6,0),(6,0)])),
            ('vertical', {}, LineString([(0,-6),(0,6)]))], 'horizontal')
        self.assertTrue(all(n not in heights for w,_,a,b in edges if w=='vertical' for n in (a,b)))

    def test_bridge_layer_transition_and_clipped_tile_seam_connect(self):
        _, edges, heights, _ = self.network_heights([
            ('bridge', dict(layer='1',bridge='yes'), LineString([(500,0),(512,0)])),
            ('ramp', {}, LineString([(512,0),(524,0)])),
            ('ramp', {}, LineString([(524,0),(536,0)]))], 'bridge')
        self.assertTrue(all(n in heights for w,_,a,b in edges if w=='ramp' for n in (a,b)))

    def test_low_embankment_and_cutting_rejoin_dem_without_changing_formation(self):
        for natural in (-2,12):
            for distance in (0,7,14):
                self.assertAlmostEqual(formation_grade(natural,5.15,distance,14),5)
            self.assertAlmostEqual(formation_grade(natural,5.15,100,14),natural)
        self.assertLess(formation_grade(-2,5.15,24,14),4)
        self.assertGreater(formation_grade(12,5.15,24,14),6)
        self.assertEqual(formation_grade(-4,8,0,14,True),-4)

    def test_only_duplicate_station_pedestrian_bridges_are_omitted(self):
        station = STRtree([box(0,0,100,30)])
        crossing = LineString([(50,-20),(50,50)])
        self.assertTrue(station_walkway(dict(highway="footway",bridge="yes"),crossing,station))
        self.assertTrue(station_walkway(dict(highway="path",bridge="yes"),crossing,station))
        self.assertFalse(station_walkway(dict(highway="trunk",bridge="yes"),crossing,station))
        self.assertFalse(station_walkway(dict(highway="footway"),crossing,station))
        self.assertFalse(station_walkway(dict(highway="footway",bridge="yes"),LineString([(500,0),(600,0)]),station))

    def test_connected_approach_tapers_but_unconnected_road_stays_unchanged(self):
        nodes = [(0,0),(20,0),(40,0),(60,0),(20,1)]
        links = {0:[(1,20)],1:[(0,20),(2,20)],2:[(1,20),(3,20)],3:[(2,20)],4:[]}
        h = propagate(nodes,links,[0]*5,{0:4})
        self.assertAlmostEqual(h[1],2.5)
        self.assertAlmostEqual(h[2],1)
        self.assertNotIn(3,h)
        self.assertNotIn(4,h)

    def test_two_bridge_constraints_merge_without_a_height_step(self):
        links = {0:[(1,20)],1:[(0,20),(2,20)],2:[(1,20)]}
        h = propagate([(0,0),(20,0),(40,0)],links,[0]*3,{0:4,2:5})
        self.assertAlmostEqual(h[1],3.5)
        for a, pairs in links.items():
            for b, distance in pairs:
                self.assertLessEqual(abs(h[a]-h[b])/distance,.075000001)

    def test_elevation_interpolation_handles_negative_tile_and_signed_samples(self):
        with tempfile.TemporaryDirectory() as temp:
            folder = Path(temp);(folder/"elevation").mkdir()
            values = [int(-100+x*2+z*3) for z in range(129) for x in range(129)]
            (folder/"elevation/-1_0.bin").write_bytes(b"\0"*4+struct.pack("<"+"h"*len(values),*values))
            ground = object.__new__(Ground);ground.source=folder;ground.tiles={}
            self.assertAlmostEqual(ground.dem(-4096+32*.25,32*.75),(-100+2*.25+3*.75)*.1)
            self.assertTrue(math.isfinite(ground.dem(-1,1)))

    def test_raised_road_corner_clears_water_after_centreline_leaves_bank(self):
        wet = [box(2,1.5,5,5)]
        edge = dict(a=0,b=1,width=4,line=LineString([(0,0),(6,0)]))
        self.assertFalse(edge["line"].intersects(wet[0]))
        extra = water_edge_seeds([edge],[0,0],{0:2,1:1.5},wet,[1],STRtree(wet))
        self.assertEqual(extra,{0:2.2,1:2.2})
        self.assertEqual(water_edge_seeds([edge],[0,0],{},wet,[1],STRtree(wet)),{})

    def test_existing_flyover_approach_clears_widened_track_and_overhead_portal(self):
        edge = dict(a=0,b=1,width=4,line=LineString([(0,0),(6,0)]))
        rails = STRtree([LineString([(3,-10),(3,10)])])
        portals = STRtree([LineString([(5,-20),(5,20)])])
        extra = railway_edge_seeds([edge],[0,0],{0:4,1:3.5},rails,[(1,1)],portals,[11])
        self.assertEqual(extra,{0:11.85,1:11.85})
        self.assertEqual(railway_edge_seeds([edge],[0,0],{},rails,[(1,1)],portals,[11]),{})


if __name__ == "__main__":
    unittest.main()
