"""The independent mesh audit must reject hidden parallel encroachment without
rejecting a legitimate same-level crossing mouth or another vertical level."""
import json,tempfile,unittest
from pathlib import Path
from unittest.mock import patch
import audit_parallel_roads as audit

class ParallelRoadAuditTests(unittest.TestCase):
    def run_case(self,cross_height=None,patch_only=False,main_height=-.1,beyond_end=False):
        with tempfile.TemporaryDirectory() as folder:
            root=Path(folder);tiles=root/'data/routes/kerala_coast/tiles';tiles.mkdir(parents=True)
            features=[dict(id='main',kind='road',tags={'highway':'residential'},geometry={'type':'LineString','coordinates':[[0,1],[50,1]]})]
            if cross_height is not None:features.append(dict(id='cross',kind='road',tags={'highway':'residential'},geometry={'type':'LineString','coordinates':[[20,-10],[20,10]]}))
            (tiles/'0_0.json').write_text(json.dumps({'features':features}))
            def road(way,x0,x1,z0,z1,y):
                a,b,c,d=[x0,y,z0],[x1,y,z0],[x1,y,z1],[x0,y,z1]
                return dict(tile=[0,0],way=way,triangles=[dict(kind='road',points=[a,b,c]),dict(kind='road',points=[a,c,d])])
            rows=[road('main',18 if patch_only else 2,22 if patch_only else 38,.5,2,main_height)]
            if beyond_end:rows=[road('main',41.2,42.2,.5,2,main_height)]
            if cross_height is not None:rows.append(road('cross',18,22,-10,10,cross_height))
            path=root/'triangles.jsonl';path.write_text('\n'.join(json.dumps(r) for r in rows))
            with patch.object(audit,'ROOT',root):return audit.audit({'rails':[{'id':'track','points':[[0,0,0],[40,0,0]]}]},path)
    def test_long_parallel_road_is_rejected_even_with_one_crossroad(self):
        self.assertFalse(self.run_case(-.1)['passed'])
    def test_actual_crossing_mouth_is_retained(self):
        report=self.run_case(-.1,True)
        self.assertTrue(report['passed'],report);self.assertGreater(report['genuine_crossing_aprons'],0)
    def test_high_flyover_does_not_excuse_a_parallel_road_below(self):
        self.assertFalse(self.run_case(10,True)['passed'])
    def test_low_underpass_is_allowed(self):
        self.assertTrue(self.run_case(main_height=-5)['passed'])
    def test_road_past_buffer_stop_is_not_mistaken_for_live_track(self):
        self.assertTrue(self.run_case(beyond_end=True)['passed'])
    def test_folded_source_bends_produce_valid_audit_footprints(self):
        from shapely.geometry import LineString
        shapes=audit.crossing_bends([LineString([(0,0),(1,0),(.1,.1),(1,.2)])],4,(0,1))
        self.assertTrue(shapes);self.assertTrue(all(p.is_valid for p in shapes))

if __name__=='__main__':unittest.main()
