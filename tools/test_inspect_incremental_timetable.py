import json
import sys
import tempfile
import unittest
from pathlib import Path

from inspect_incremental_timetable import once, write_new


class OnceOnlyAssessmentTests(unittest.TestCase):
    def test_completed_assessment_is_not_run_twice(self):
        with tempfile.TemporaryDirectory() as temporary:
            folder = Path(temporary)
            once(folder, "proof", [sys.executable, "-c", "print('actual first execution')"])
            before = (folder / "proof.log").read_bytes()
            once(folder, "proof", [sys.executable, "-c", "raise RuntimeError('must never run')"])
            self.assertEqual((folder / "proof.log").read_bytes(), before)

    def test_interrupted_and_failed_commands_are_not_retried(self):
        with tempfile.TemporaryDirectory() as temporary:
            folder = Path(temporary)
            write_new(folder / "proof-execution.json", {"exit_code": None})
            with self.assertRaisesRegex(RuntimeError, "Prior"):
                once(folder, "proof", [sys.executable, "-c", "print('must never run')"])
            (folder / "proof-execution.json").write_text(json.dumps({"exit_code": 1}), encoding="utf-8")
            with self.assertRaisesRegex(RuntimeError, "Prior"):
                once(folder, "proof", [sys.executable, "-c", "print('must never run')"])

    def test_unreceipted_output_is_preserved(self):
        with tempfile.TemporaryDirectory() as temporary:
            folder = Path(temporary)
            (folder / "proof.json").write_text("existing evidence", encoding="utf-8")
            with self.assertRaisesRegex(RuntimeError, "Unreceipted"):
                once(folder, "proof", [sys.executable, "-c", "print('must never run')"])
            self.assertEqual((folder / "proof.json").read_text(encoding="utf-8"), "existing evidence")


if __name__ == "__main__":
    unittest.main()
