import json
import tempfile
import unittest
from pathlib import Path

from launch_incremental_timetable import check_new, sha


class LaunchGuardsTests(unittest.TestCase):
    def candidate(self, parent, name, text):
        candidate = parent / name
        candidate.mkdir()
        (candidate / "pack.json").write_text(text, encoding="utf-8")
        (candidate / "authoring.json").write_text(json.dumps({"pack_sha256": sha(candidate / "pack.json")}), encoding="utf-8")
        return candidate

    def test_reject_partial_intent_and_existing_run(self):
        with tempfile.TemporaryDirectory() as temporary:
            candidate = self.candidate(Path(temporary), "one", "candidate")
            check_new(candidate)
            (candidate / "launch-intent.json").write_text("{}", encoding="utf-8")
            with self.assertRaisesRegex(ValueError, "Original"):
                check_new(candidate)

    def test_reject_identical_candidate_in_another_output(self):
        with tempfile.TemporaryDirectory() as temporary:
            parent = Path(temporary)
            first = self.candidate(parent, "first", "same bytes")
            (first / "jobs.json").write_text("{}", encoding="utf-8")
            second = self.candidate(parent, "second", "same bytes")
            with self.assertRaisesRegex(ValueError, "Identical"):
                check_new(second)
            third = self.candidate(parent, "third", "changed candidate")
            check_new(third)

    def test_reject_post_authoring_edit(self):
        with tempfile.TemporaryDirectory() as temporary:
            candidate = self.candidate(Path(temporary), "one", "original")
            (candidate / "pack.json").write_text("changed", encoding="utf-8")
            with self.assertRaisesRegex(ValueError, "bytes changed"):
                check_new(candidate)


if __name__ == "__main__":
    unittest.main()
