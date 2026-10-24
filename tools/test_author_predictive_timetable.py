"""Guard the authorized departure-only V2 authoring boundary."""
import copy
import json
import unittest
from pathlib import Path

from author_predictive_timetable import DEPARTURES, author

ROOT = Path(__file__).resolve().parents[1]

def load(name):
    return json.loads((ROOT / "art/timetables" / name).read_text(encoding="utf-8"))

class PredictiveAuthoringTests(unittest.TestCase):
    def setUp(self):
        self.standard = load("kerala-coast-100-through-services.json")
        self.intensive = load("kerala-coast-intensive.json")
        self.original = copy.deepcopy((self.standard, self.intensive))
        self.regular, self.busy = author(self.standard, self.intensive)

    def test_classic_inputs_and_standard_times_remain_unchanged(self):
        self.assertEqual((self.standard, self.intensive), self.original)
        self.assertEqual(self.regular["services"], self.standard["services"])
        self.assertEqual(len(self.regular["services"]), 100)
        for key, value in self.standard.items():
            if key not in {"name", "dispatcher"}:
                self.assertEqual(self.regular[key], value, key)
        self.assertEqual(self.regular["dispatcher"], "predictive")

    def test_intensive_changes_only_declared_departures_and_names(self):
        self.assertEqual(len(self.busy["services"]), 140)
        originals = {s["id"]: s for s in self.intensive["services"]}
        self.assertEqual(set(DEPARTURES) - set(originals), set())
        self.assertEqual([s["id"] for s in self.busy["services"]],
                         [s["id"] for s in self.intensive["services"]])
        for service in self.busy["services"]:
            old = originals[service["id"]]
            if service["id"] not in DEPARTURES:
                self.assertEqual(service, old, service["id"])
                continue
            self.assertRegex(DEPARTURES[service["id"]], r"^(?:[01]\d|2[0-3]):[0-5]\d$")
            self.assertEqual(service["departure"], DEPARTURES[service["id"]])
            self.assertIn(service["departure"], service["name"])
            self.assertEqual(set(service), set(old))
            for key, value in old.items():
                if key not in {"name", "departure"}:
                    self.assertEqual(service[key], value, (service["id"], key))
        for key, value in self.intensive.items():
            if key not in {"name", "dispatcher", "services"}:
                self.assertEqual(self.busy[key], value, key)
        self.assertEqual(self.busy["dispatcher"], "predictive")

    def test_passenger_working_is_not_padded_to_manufacture_passes(self):
        baseline = next(s for s in self.intensive["services"] if s["id"] == "K1")
        candidate = next(s for s in self.busy["services"] if s["id"] == "K1")
        self.assertNotIn("K1", DEPARTURES)
        self.assertEqual(candidate, baseline)
        self.assertGreater(len(candidate["stops"]), 40)

    def test_committed_outputs_match_authoring_source(self):
        self.assertEqual(load("kerala-coast-predictive.json"), self.regular)
        self.assertEqual(load("kerala-coast-intensive-v2.json"), self.busy)

if __name__ == "__main__":
    unittest.main()
