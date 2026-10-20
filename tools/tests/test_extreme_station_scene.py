"""Review-tool contract tests. Mock metadata is never published as render evidence."""
import hashlib
import json
from pathlib import Path
import sys
import tempfile
import unittest
from unittest.mock import patch

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
import prepare_extreme_station_scene as prepare
import check_extreme_station_manifest as validator


class PrepareStationTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.root = Path(self.temp.name)
        self.source = self.root / "source"
        for name in prepare.ROOTS + prepare.TEXTURES + ["game/shaders/sample.gdshader", "game/shaders/sample.gdshader.uid"]:
            path = self.source / name
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_text("source fixture data\n")

    def tearDown(self):
        self.temp.cleanup()

    def test_exact_source_copy_and_hashes(self):
        output = self.root / "output"
        result = prepare.prepare(self.source, output)
        for entry in result["files"]:
            self.assertEqual((output / entry["path"]).read_bytes(), (self.source / entry["path"]).read_bytes())
            self.assertEqual(hashlib.sha256((output / entry["path"]).read_bytes()).hexdigest(), entry["sha256"])
        self.assertEqual(result["simulation_step_calls"], 0)
        self.assertIn("import/use_multiple_threads=false", (output / "project.godot").read_text())
        self.assertIn("worker_pool/max_threads=1", (output / "project.godot").read_text())
        self.assertFalse((output / ".godot").exists())
        self.assertEqual(sum(entry["path"] == "game/shaders/sample.gdshader.uid" for entry in result["files"]), 1)

    def test_reject_checkout_output(self):
        with self.assertRaisesRegex(ValueError, "outside"):
            prepare.prepare(self.source, self.source / "fixture")

    def test_reject_nonempty_output(self):
        output = self.root / "output"
        output.mkdir()
        (output / "preserve.txt").write_text("keep")
        with self.assertRaisesRegex(ValueError, "empty"):
            prepare.prepare(self.source, output)
        self.assertEqual((output / "preserve.txt").read_text(), "keep")

    def test_reject_unpinned_baseline(self):
        with self.assertRaisesRegex(ValueError, "full pinned"):
            prepare.prepare(self.source, self.root / "output", "main")

    def test_reject_unbounded_authored_preload(self):
        (self.source / prepare.ROOTS[0]).write_text('const BIG = preload("res://assets/models/large.glb")\n')
        with self.assertRaisesRegex(ValueError, "Unbounded static"):
            prepare.prepare(self.source, self.root / "output")
        self.assertFalse((self.root / "output").exists())

    def test_reject_missing_dependency(self):
        (self.source / prepare.ROOTS[0]).write_text('const REQUIRED = preload("res://game/missing.gd")\n')
        with self.assertRaisesRegex(FileNotFoundError, "missing.gd"):
            prepare.prepare(self.source, self.root / "output")


class StationManifestTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.root = Path(self.temp.name)
        self.baseline_path = self.root / "baseline.json"
        self.patched_path = self.root / "patched.json"
        self.baseline = self.make_manifest(True)
        self.patched = self.make_manifest(False)
        self.png_check = patch.object(validator, "verify_png")
        self.png_check.start()  # PNG validation is shared with the independently tested source validator.

    def tearDown(self):
        self.png_check.stop()
        self.temp.cleanup()

    @staticmethod
    def measurement():
        return dict(exact_equal=True, total_pixels=4, changed_rgb_pixels=0,
                    changed_rgb_fraction=0, mean_absolute_rgb_error_255=0, max_rgb_error_255=0)

    def make_manifest(self, baseline):
        ids = validator.HIGH_IDS if baseline else validator.PATCHED_IDS
        source = {"res://sim/rail_world.gd": "c" * 64}
        data = dict(capture_status="captured_requires_visual_review", capture_scope="bounded_synthetic_station",
                    renderer="forward_plus", rendering_device_available=True, display_server="x11", device="test metadata",
                    presets=["High"] if baseline else list(validator.PRESETS), shader_time_frozen=True,
                    simulation_step_calls=0, world_unchanged=True, static_geometry_unchanged=True,
                    source_files_unchanged=True, resolution=[2, 2], world_sha256_before="a" * 64,
                    geometry_sha256_before="b" * 64, station_nameboards=4, station_light_sites=4,
                    track_stats={"sleepers": 996}, source_sha256=source, source_provenance={
                        "baseline_ref": "d" * 40 if baseline else "",
                        "files": [{"path": "sim/rail_world.gd", "sha256": "c" * 64}]},
                    captures=[], invariant_checks=[], comparisons=[], high_baseline_comparisons=[],
                    godot={"major": 4, "minor": 7}, rendering_driver="vulkan", fixture_overrides={},
                    settle_frames=12, frame_samples=4, synthetic_station={"code": "EXTREME_REVIEW"})
        for identity in sorted(ids):
            period = identity.split("-", 1)[0]
            view = next(view for view in validator.VIEWS if f"-{view}-" in identity)
            preset = next(preset for preset in validator.PRESETS if identity.endswith("-" + preset.lower()))
            data["captures"].append(dict(id=identity, file=identity + ".png", png_sha256="e" * 64,
                capture_status="captured", resolution=[2, 2], shader_time_frozen=True, draw_calls=10,
                period=period, view=view, preset=preset, station_visible_fixtures=4,
                station_active_lights=4 if period == "dusk" else 0, camera_eye=[0, 2, 0],
                camera_target=[0, 2, -1], camera_fov=58, hour=12 if period == "daylight" else 18.65))
        for identity in sorted(ids | {"after_build"}):
            data["invariant_checks"].append(dict(id=identity, world_unchanged=True, geometry_unchanged=True,
                                                  world_sha256="a" * 64, geometry_sha256="b" * 64))
        if not baseline:
            data.update(baseline_source_sha256=source, all_baseline_high_pixels_equal=True, all_high_restored_pixels_equal=True)
            for period, view in validator.PAIRS:
                identity = f"{period}-{view}-high"
                data["high_baseline_comparisons"].append(dict(id=identity, baseline_file=identity + ".png",
                    baseline_png_sha256="e" * 64, high_vs_baseline=self.measurement()))
                data["comparisons"].append(dict(period=period, view=view, high_vs_restored=self.measurement(),
                                                high_vs_extreme=self.measurement()))
        return data

    def validate(self):
        self.baseline_path.write_text(json.dumps(self.baseline))
        self.patched_path.write_text(json.dumps(self.patched))
        validator.validate(self.baseline_path, self.patched_path)

    def test_complete_metadata(self):
        self.validate()

    def test_reject_partial_capture(self):
        self.patched["captures"].pop()
        with self.assertRaisesRegex(validator.InvalidCapture, "missing IDs"):
            self.validate()

    def test_reject_structural_only_as_capture(self):
        self.patched["capture_status"] = "structural_validation_only_not_rendered"
        with self.assertRaisesRegex(validator.InvalidCapture, "completed rendering"):
            self.validate()

    def test_reject_headless_renderer(self):
        self.patched["display_server"] = "headless"
        with self.assertRaisesRegex(validator.InvalidCapture, "real Forward"):
            self.validate()

    def test_reject_missing_invariant(self):
        self.patched["invariant_checks"].pop()
        with self.assertRaisesRegex(validator.InvalidCapture, "missing IDs"):
            self.validate()

    def test_reject_state_mutation(self):
        self.patched["invariant_checks"][0]["world_sha256"] = "f" * 64
        with self.assertRaisesRegex(validator.InvalidCapture, "state changed"):
            self.validate()

    def test_reject_simulation_source_change(self):
        self.patched["source_sha256"] = {"res://sim/rail_world.gd": "f" * 64}
        self.patched["source_provenance"]["files"][0]["sha256"] = "f" * 64
        with self.assertRaisesRegex(validator.InvalidCapture, "simulation source differs"):
            self.validate()

    def test_reject_false_exact_equality(self):
        self.patched["captures"][0]["png_sha256"] = "f" * 64
        # Select a High capture, not Extreme, so equality is relevant.
        next(entry for entry in self.patched["captures"] if entry["preset"] == "High")["png_sha256"] = "f" * 64
        with self.assertRaisesRegex(validator.InvalidCapture, "PNG bytes contradict"):
            self.validate()

    def test_reject_changed_camera(self):
        self.patched["captures"][0]["camera_eye"] = [2, 3, 4]
        with self.assertRaisesRegex(validator.InvalidCapture, "fixed camera"):
            self.validate()


if __name__ == "__main__":
    unittest.main()
