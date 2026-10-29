import copy
import json
import tempfile
import unittest
from pathlib import Path

from author_incremental_timetable import author, running_schedule, validate_increment, validate_previous, digest


class IncrementalAuthorTests(unittest.TestCase):
    def setUp(self):
        self.local = {"id": "K1", "stock": "icf", "rake": "passenger", "departure": "06:00",
                      "stops": [{"block": "ERS_P1", "direction": 1, "minutes_from_origin": 0, "dwell_minutes": 0},
                                {"block": "ALLP_P1", "direction": 1, "minutes_from_origin": 40, "dwell_minutes": 1},
                                {"block": "TVC_P1", "direction": 1, "minutes_from_origin": 80, "dwell_minutes": 0}]}
        self.fast = copy.deepcopy(self.local)
        self.fast.update(id="FAST", stock="lhb", rake="express")
        self.profiles = {"k": {"service": self.local, "arrivals": [-1, 600, 1300], "departures": [5, 705, -1]},
                         "f": {"service": self.fast, "arrivals": [-1, 400, 900], "departures": [5, 465, -1]}}
        self.inputs = {"K1": {"profile": "k", "passenger_exchange_seconds": [40, 100, 40]},
                       "FAST": {"profile": "f", "passenger_exchange_seconds": [40, 50, 40]}}
        self.source = {"services": [self.local, self.fast], "dispatcher": "predictive"}

    def test_follower_uses_departure_at_shared_station(self):
        before = copy.deepcopy(self.source)
        pack, times = author(self.source, [{"id": "K1", "departure": "06:00"},
            {"id": "FAST", "follows": "K1", "at": "ALLP", "gap_seconds": 900}], self.profiles, self.inputs)
        gap = times["FAST"]["origin"] + times["FAST"]["departures"][1] - times["K1"]["origin"] - times["K1"]["departures"][1]
        self.assertEqual(gap, 900)
        self.assertEqual(self.source, before)
        self.assertEqual(pack["services"][0]["stops"][1]["dwell_minutes"], 1)
        self.assertEqual(pack["services"][0]["stops"][1]["minutes_from_origin"], 10)

    def test_individual_passenger_demand_changes_departure_not_running_leg(self):
        other = copy.deepcopy(self.local)
        other["id"] = "OTHER"
        self.inputs["OTHER"] = {"passenger_exchange_seconds": [40, 80, 40]}
        timing = running_schedule(other, self.profiles["k"], self.inputs)
        self.assertEqual(timing["arrivals"], [0, 600, 1280])
        self.assertEqual(timing["leg_seconds"], [595, 595])

    def test_reject_wrong_calls_or_unexplained_probe_wait(self):
        other = copy.deepcopy(self.local)
        other["stops"][1]["block"] = "DIFFERENT_P1"
        with self.assertRaisesRegex(ValueError, "different calls"):
            running_schedule(other, self.profiles["k"], self.inputs)
        bad = copy.deepcopy(self.profiles["k"])
        bad["departures"][1] += 100
        with self.assertRaisesRegex(ValueError, "unexplained"):
            running_schedule(self.local, bad, self.inputs)

    def test_reject_unplaced_predecessor_and_zero_gap(self):
        with self.assertRaisesRegex(ValueError, "predecessor"):
            author(self.source, [{"id": "FAST", "follows": "K1", "at": "ERS", "gap_seconds": 900}], self.profiles, self.inputs)
        with self.assertRaisesRegex(ValueError, "positive"):
            author(self.source, [{"id": "K1", "departure": "06:00"},
                {"id": "FAST", "follows": "K1", "at": "ERS", "gap_seconds": 0}], self.profiles, self.inputs)

    def test_only_one_train_added_or_one_placement_revised(self):
        first = [{"id": "K1", "departure": "06:00"}]
        pair = first + [{"id": "FAST", "departure": "06:15"}]
        self.assertEqual(validate_increment(first, pair)["service"], "FAST")
        revised = first + [{"id": "FAST", "departure": "06:10"}]
        self.assertEqual(validate_increment(pair, revised)["kind"], "one placement revised")
        for invalid in [pair, first, pair + [{"id": "A"}, {"id": "B"}],
                        [{"id": "K1", "departure": "06:01"}] + revised[1:]]:
            with self.assertRaises(ValueError):
                validate_increment(pair, invalid)

    def test_previous_outcomes_must_be_preserved_complete_safe_and_matching(self):
        previous = [{"id": "K1", "departure": "06:00"}]
        current = previous + [{"id": "FAST", "departure": "06:15"}]
        with tempfile.TemporaryDirectory() as temporary:
            directory = Path(temporary)
            (directory / "construction.json").write_text(json.dumps({"services": previous}), encoding="utf-8")
            (directory / "pack.json").write_text("original candidate", encoding="utf-8")
            with self.assertRaisesRegex(ValueError, "Preserve"):
                validate_previous(directory, current)
            (directory / "preservation.json").write_text("{}", encoding="utf-8")
            valid = {"pack_sha256": digest(directory / "pack.json"),
                     "all_calls_and_terminals_complete": True, "audit": {"events": []}}
            for name in ["normal", "delayed"]:
                (directory / name).mkdir()
                (directory / name / "assessment.json").write_text(json.dumps(valid), encoding="utf-8")
            self.assertEqual(validate_previous(directory, current)["service"], "FAST")
            for invalid in [{**valid, "pack_sha256": "stale"},
                            {**valid, "all_calls_and_terminals_complete": False},
                            {**valid, "audit": {"events": [{"kind": "unsafe"}]}}]:
                (directory / "delayed/assessment.json").write_text(json.dumps(invalid), encoding="utf-8")
                with self.assertRaisesRegex(ValueError, "safely complete"):
                    validate_previous(directory, current)


if __name__ == "__main__":
    unittest.main()
