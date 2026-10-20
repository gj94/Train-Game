"""Synthetic validator tests only: no GPU, rendered screenshots or visual proof.

Run: python3 -m unittest discover -s tools/tests -p 'test_extreme_capture_manifest.py'
"""

import copy
import hashlib
import importlib.util
import json
from pathlib import Path
import struct
import subprocess
import sys
import tempfile
import unittest
import zlib


SCRIPT = Path(__file__).resolve().parents[1] / "check_extreme_capture_manifest.py"
SPEC = importlib.util.spec_from_file_location("capture_validator", SCRIPT)
VALIDATOR = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(VALIDATOR)


def synthetic_png(alternate=False):
    def chunk(kind, data):
        return struct.pack(">I", len(data)) + kind + data + struct.pack(">I", zlib.crc32(kind + data))
    row = bytes([40 + int(alternate), 60, 80, 255, 140, 160, 180, 255])
    return (b"\x89PNG\r\n\x1a\n" +
            chunk(b"IHDR", struct.pack(">IIBBBBB", 2, 2, 8, 6, 0, 0, 0)) +
            chunk(b"IDAT", zlib.compress((b"\0" + row) * 2)) + chunk(b"IEND", b""))


def measurement(equal=True):
    return dict(exact_equal=equal, total_pixels=4, changed_rgb_pixels=0 if equal else 2,
                changed_rgb_fraction=0 if equal else .5,
                mean_absolute_rgb_error_255=0 if equal else 1 / 6, max_rgb_error_255=0 if equal else 1)


class CaptureManifestTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix="synthetic-capture-validator-test-")
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.baseline_path = self.root / "baseline/manifest.json"
        self.patched_path = self.root / "patched/manifest.json"
        self.baseline_path.parent.mkdir()
        self.patched_path.parent.mkdir()
        self.baseline = dict(
            capture_status="captured_requires_visual_review", renderer="forward_plus",
            rendering_device_available=True, ssr_supported=True, display_server="SYNTHETIC_TEST",
            device="SYNTHETIC_TEST_NOT_A_GPU", capture_scope="full_fixture", selected_views=[],
            selected_periods=[], presets=["High"], check_rebase=False, shader_time_frozen=True,
            resolution=[2, 2], godot={"string": "SYNTHETIC"}, rendering_driver="SYNTHETIC",
            fixture_overrides={"taa": False}, settle_frames=8, frame_samples=4,
            fixture_provenance={"baseline_ref": "1" * 40, "baseline_files": ["synthetic"]},
            source_sha256={"synthetic": "2" * 64}, captures=[], comparisons=[],
            high_baseline_comparisons=[], rebase_comparisons=[])
        self.patched = copy.deepcopy(self.baseline)
        self.patched.update(
            presets=list(VALIDATOR.PRESETS), check_rebase=True,
            baseline_fixture_provenance=self.baseline["fixture_provenance"],
            baseline_source_sha256=self.baseline["source_sha256"],
            all_high_restored_pixels_equal=True, all_baseline_high_pixels_equal=True)
        for period, view in sorted(VALIDATOR.PAIRS):
            identity = f"{period}-{view}-high"
            old = self.add_capture(self.baseline, self.baseline_path, identity, period, "High")
            for preset in VALIDATOR.PRESETS:
                self.add_capture(self.patched, self.patched_path, f"{period}-{view}-{preset.lower()}",
                                 period, preset, preset == "Extreme")
            self.patched["comparisons"].append(dict(
                period=period, view=view, high_vs_extreme=measurement(False), high_vs_restored=measurement()))
            self.patched["high_baseline_comparisons"].append(dict(
                id=identity, baseline_file=old["file"], baseline_png_sha256=old["png_sha256"],
                high_vs_baseline=measurement()))
        for view in ("road", "station", "water"):
            for phase, origin, shift in (
                ("before", [300000, 0, -300000], [0, 0, 0]),
                ("after", [301024, 0, -298976], [-1024, 0, -1024]),
            ):
                self.add_capture(self.patched, self.patched_path, f"far-route-{view}-{phase}",
                                 "daylight", "Extreme", phase == "after", origin, shift)
            self.patched["rebase_comparisons"].append(dict(
                view=view, same_absolute_point=True, origin_before=[300000, 0, -300000],
                origin_after=[301024, 0, -298976], local_translation=[-1024, 0, -1024],
                before_vs_after=measurement(False)))

    def add_capture(self, manifest, path, identity, period, preset, alternate=False, origin=None, shift=None):
        data = synthetic_png(alternate)
        entry = dict(
            id=identity, file=identity + ".png", preset=preset, period=period,
            hour={"daylight": 12, "dusk": 18.25, "night": 22}[period],
            capture_status="captured", resolution=[2, 2], shader_time_frozen=True, draw_calls=1,
            camera_eye=[0, 1, 1], camera_target=[0, 0, 0], camera_fov=55,
            route_origin=origin or [0, 0, 0], scene_local_translation=shift or [0, 0, 0],
            png_sha256=hashlib.sha256(data).hexdigest())
        manifest["captures"].append(entry)
        (path.parent / entry["file"]).write_bytes(data)
        return entry

    def save(self):
        self.baseline_path.write_text(json.dumps(self.baseline))
        self.patched_path.write_text(json.dumps(self.patched))

    def reject(self, message):
        self.save()
        with self.assertRaisesRegex(VALIDATOR.InvalidCapture, message):
            VALIDATOR.validate(self.baseline_path, self.patched_path)

    def test_complete_synthetic_run_accepts_nonexact_rebase(self):
        self.save()
        VALIDATOR.validate(self.baseline_path, self.patched_path)

    def test_partial_watchdog_run_exits_one(self):
        self.patched.update(capture_status="blocked", failure="Capture timed out before completion.")
        self.patched["captures"] = self.patched["captures"][:33]
        self.save()
        result = subprocess.run(
            [sys.executable, str(SCRIPT), "--baseline", str(self.baseline_path),
             "--patched", str(self.patched_path)], capture_output=True, text=True)
        self.assertEqual(result.returncode, 1)
        self.assertIn("33 captures; Capture timed out", result.stderr)
        self.assertNotIn("EXTREME_CAPTURE_VALID:", result.stdout)

    def test_missing_capture_id(self):
        self.patched["captures"].pop()
        self.reject("missing IDs")

    def test_duplicate_capture_id(self):
        self.patched["captures"][-1] = copy.deepcopy(self.patched["captures"][0])
        self.reject("duplicate ID")

    def test_hash_mismatch(self):
        self.patched["captures"][0]["png_sha256"] = "0" * 64
        self.reject("PNG hash mismatch")

    def test_missing_png(self):
        (self.patched_path.parent / self.patched["captures"][0]["file"]).unlink()
        self.reject("missing PNG")

    def test_nonexact_legacy_high(self):
        self.patched["high_baseline_comparisons"][0]["high_vs_baseline"] = measurement(False)
        self.reject("pixels are not exactly equal")

    def test_nonexact_restored_high(self):
        self.patched["comparisons"][0]["high_vs_restored"] = measurement(False)
        self.reject("pixels are not exactly equal")

    def test_missing_restoration_comparison(self):
        self.patched["comparisons"].pop()
        self.reject("High-restored comparisons: missing IDs")

    def test_missing_rebase_measurement(self):
        self.patched["rebase_comparisons"].pop()
        self.reject("rebase comparisons: missing IDs")

    def test_unsupported_capture_status(self):
        self.patched["capture_status"] = "captured_unsupported_ssr"
        self.reject("capture is not complete")

    def test_unsupported_renderer(self):
        self.patched["renderer"] = "gl_compatibility"
        self.reject("real Forward\\+")

    def test_subset_capture(self):
        self.patched["capture_scope"] = "subset_smoke"
        self.reject("subset captures")

    def test_mismatched_camera(self):
        self.patched["captures"][0]["camera_eye"] = [9, 9, 9]
        self.reject("camera, lighting or origin differs")

    def test_wrong_rebase_origin(self):
        self.patched["captures"][-1]["route_origin"] = [300000, 0, -300000]
        self.reject("captured origins disagree")

    def test_false_exact_flag_despite_valid_hash(self):
        entry = self.patched["captures"][0]
        data = synthetic_png(True)
        entry["png_sha256"] = hashlib.sha256(data).hexdigest()
        (self.patched_path.parent / entry["file"]).write_bytes(data)
        self.reject("exact equality reported but PNG bytes differ")

    def test_truncated_png_despite_valid_hash(self):
        entry = self.patched["captures"][0]
        data = synthetic_png()[:-12]
        entry["png_sha256"] = hashlib.sha256(data).hexdigest()
        (self.patched_path.parent / entry["file"]).write_bytes(data)
        self.reject("incomplete PNG")


class WaterTemporalManifestTests(unittest.TestCase):
    """Only synthetic fixed-time fixtures, never rendered animation evidence."""

    add_capture = CaptureManifestTests.add_capture

    def setUp(self):
        CaptureManifestTests.setUp(self)
        self.path = self.root / "temporal/manifest.json"
        self.path.parent.mkdir()
        self.data = copy.deepcopy(self.baseline)
        self.data.update(capture_status="temporal_diagnostic_captured_requires_review",
                         capture_scope="water_temporal_diagnostic", captures=[], temporal_comparisons=[])
        source = 'shader_type spatial;\n#include "extreme_surface_detail.gdshaderinc"\nvoid fragment(){ ALBEDO=vec3(TIME); }\n'
        files = {"source": "temporal_source_water.gdshader", "fixed_time": "temporal_fixed_time_water.gdshader"}
        hashes = {}
        for kind, code in (("source", source), ("fixed_time", VALIDATOR.fixed_time_shader_code(source))):
            (self.path.parent / files[kind]).write_bytes(code.encode())
            hashes[kind] = hashlib.sha256(code.encode()).hexdigest()
        source_path = "res://game/shaders/geographic_water.gdshader"
        self.data["source_sha256"] = {source_path: hashes["source"]}
        self.data["temporal_shader"] = dict(source_path=source_path, files=files, sha256=hashes,
                                           uniform="fixture_water_time", rollover_seconds=3600,
                                           endpoint_is_unwrapped=True)
        self.by_sample = {}
        for sample, seconds in VALIDATOR.TEMPORAL_TIMES.items():
            alternate = sample in ("t1-60", "t0-5", "t3600-minus-1-60")
            entry = self.add_capture(self.data, self.path, "temporal-water-" + sample, "dusk",
                                     "Diagnostic-Extreme-temporal", alternate)
            entry.update(preset_values={"surface_detail": True}, ssr_enabled=False, radiance_size_enum=4)
            entry["diagnostic"] = dict(
                kind="water_temporal", requested_time_seconds=seconds,
                shader_uniform_time_seconds=struct.unpack("f", struct.pack("f", seconds))[0],
                production_time_seconds=seconds % 3600, global_time_frozen=True, surface_detail=1.0,
                source_shader_sha256=hashes["source"], fixed_time_shader_sha256=hashes["fixed_time"])
            self.by_sample[sample] = entry
        self.update_comparisons()

    def update_comparisons(self):
        self.data["temporal_comparisons"] = [dict(
            id=label, **{"from": "temporal-water-" + left, "to": "temporal-water-" + right},
            pixel_difference=measurement(self.by_sample[left]["png_sha256"] == self.by_sample[right]["png_sha256"]))
            for label, (left, right) in VALIDATOR.TEMPORAL_PAIRS.items()]

    def save(self):
        self.path.write_text(json.dumps(self.data))

    def reject(self, message):
        self.save()
        with self.assertRaisesRegex(VALIDATOR.InvalidCapture, message):
            VALIDATOR.validate_temporal(self.path)

    def test_complete_temporal_cli_is_distinct(self):
        self.save()
        result = subprocess.run([sys.executable, str(SCRIPT), "--temporal", str(self.path)],
                                capture_output=True, text=True)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("EXTREME_TEMPORAL_VALID:", result.stdout)
        self.assertNotIn("EXTREME_CAPTURE_VALID:", result.stdout)

    def test_blocked_temporal_rejected(self):
        self.data["capture_status"] = "blocked"
        self.reject("incomplete or wrong diagnostic mode")

    def test_temporal_missing_frame(self):
        self.data["captures"].pop()
        self.reject("missing IDs")

    def test_temporal_duplicate_frame(self):
        self.data["captures"][-1] = copy.deepcopy(self.data["captures"][0])
        self.reject("duplicate ID")

    def test_temporal_png_hash_mismatch(self):
        self.by_sample["t0"]["png_sha256"] = "0" * 64
        self.reject("PNG hash mismatch")

    def test_temporal_source_hash_mismatch(self):
        (self.path.parent / "temporal_source_water.gdshader").write_text("changed")
        self.reject("source shader hash mismatch")

    def test_temporal_unexpected_shader_change(self):
        file = self.path.parent / "temporal_fixed_time_water.gdshader"
        file.write_text(file.read_text() + "// Unexpected extra modification\n")
        self.data["temporal_shader"]["sha256"]["fixed_time"] = hashlib.sha256(file.read_bytes()).hexdigest()
        self.reject("unexpected change")

    def test_temporal_requires_actual_float32_upload_value(self):
        self.by_sample["t3600-minus-1-60"]["diagnostic"]["shader_uniform_time_seconds"] = 3600 - 1 / 60
        self.reject("incorrect shader_uniform_time_seconds")

    def test_temporal_requires_unwrapped_endpoint(self):
        self.by_sample["t3600"]["diagnostic"]["shader_uniform_time_seconds"] = 0
        self.reject("incorrect shader_uniform_time_seconds")

    def test_temporal_requires_frozen_global_clock(self):
        self.by_sample["t0"]["diagnostic"]["global_time_frozen"] = False
        self.reject("invalid shader or detail metadata")

    def test_temporal_requires_fixed_camera(self):
        self.by_sample["t1-60"]["camera_eye"] = [9, 9, 9]
        self.reject("camera_eye changed")

    def test_temporal_missing_measurement(self):
        self.data["temporal_comparisons"].pop()
        self.reject("missing IDs")

    def test_temporal_false_equality_claim(self):
        self.data["temporal_comparisons"][0]["pixel_difference"] = measurement()
        self.reject("equality metric disagrees")

    def test_temporal_nonexact_rollover_is_reported_not_artistic_failure(self):
        entry = self.by_sample["t3600"]
        image = synthetic_png(True)
        (self.path.parent / entry["file"]).write_bytes(image)
        entry["png_sha256"] = hashlib.sha256(image).hexdigest()
        self.update_comparisons()
        self.save()
        result = VALIDATOR.validate_temporal(self.path)
        self.assertFalse(result["rollover-closure"]["exact_equal"])


if __name__ == "__main__":
    unittest.main()
