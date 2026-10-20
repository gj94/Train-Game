"""Focused geometry/grade regressions; no railway timetable simulation."""
import math
from pathlib import Path
import struct
import tempfile
import unittest
from road_surfaces import Ground, propagate, water_edge_seeds, railway_edge_seeds
from shapely.geometry import LineString, box
from shapely.strtree import STRtree


class RoadProfilesTest(unittest.TestCase):
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
