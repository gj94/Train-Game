import unittest
from road_finishes import export


class RoadFinishesTest(unittest.TestCase):
    def data(self):
        return dict(source="fixture.osm.pbf", source_sha256="a"*64, wanted=1, found=1,
                    ways={"w1": dict(surface="Concrete", width="8", lanes="2", highway="primary")})

    def test_only_appearance_survives_and_export_is_deterministic(self):
        result = export(self.data(), {"w1"})
        self.assertEqual(result["ways"], {"w1": {"surface": "concrete"}})
        self.assertEqual(result, export(self.data(), {"w1"}))
        self.assertEqual(len(result["road_ids_sha256"]), 64)

    def test_missing_ways_cannot_silently_publish_partial_overlay(self):
        data = self.data()
        data["found"] = 0
        with self.assertRaises(ValueError):
            export(data, {"w1"})

    def test_wrong_route_and_missing_provenance_are_rejected(self):
        with self.assertRaises(ValueError):
            export(self.data(), {"w2"})
        data = self.data()
        data["source_sha256"] = ""
        with self.assertRaises(ValueError):
            export(data, {"w1"})


if __name__ == "__main__":
    unittest.main()
