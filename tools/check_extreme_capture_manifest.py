#!/usr/bin/env python3
"""Fail closed unless a full parent-High / patched Epic review is complete.

Usage: python3 tools/check_extreme_capture_manifest.py \
    --baseline /path/to/baseline/manifest.json --patched /path/to/manifest.json
Or: python3 tools/check_extreme_capture_manifest.py --temporal /path/to/manifest.json

This validates evidence completeness and legacy pixel preservation, not artistic
quality or target-GPU performance. Exact comparisons also require identical PNG
bytes: these captures use the same Godot PNG writer, with no per-file metadata.
Rebase differences are required measurements, not automatic pass/fail thresholds.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import math
from pathlib import Path
import re
import struct
import sys
import zlib


VIEWS = ("overview", "ground", "road", "station", "water")
PERIODS = ("daylight", "dusk", "night")
PRESETS = ("High", "Epic", "High-restored")
PAIRS = {(period, view) for period in PERIODS for view in VIEWS}
HIGH_IDS = {f"{period}-{view}-high" for period, view in PAIRS}
PATCHED_IDS = {
    f"{period}-{view}-{preset.lower()}"
    for period, view in PAIRS
    for preset in PRESETS
} | {f"far-route-{view}-{phase}" for view in ("road", "station", "water") for phase in ("before", "after")}
TEMPORAL_TIMES = {
    "t0": 0.0, "t1-60": 1 / 60, "t2-60": 2 / 60, "t0-5": .5,
    "t3600-minus-1-60": 3600 - 1 / 60, "t3600": 3600.0,
}
TEMPORAL_PAIRS = {
    "adjacent-first": ("t0", "t1-60"), "adjacent-second": ("t1-60", "t2-60"),
    "half-second": ("t0", "t0-5"), "rollover-adjacent": ("t3600-minus-1-60", "t3600"),
    "rollover-closure": ("t0", "t3600"),
}


class InvalidCapture(ValueError):
    pass


def require(condition: bool, message: str) -> None:
    if not condition:
        raise InvalidCapture(message)


def indexed(entries: object, key, expected: set, label: str) -> dict:
    require(isinstance(entries, list), f"{label}: expected a list")
    result = {}
    for entry in entries:
        require(isinstance(entry, dict), f"{label}: entry is not an object")
        identity = key(entry)
        require(identity in expected, f"{label}: unexpected or missing ID {identity!r}")
        require(identity not in result, f"{label}: duplicate ID {identity!r}")
        result[identity] = entry
    missing = sorted(expected - result.keys())
    require(not missing, f"{label}: missing IDs {missing}")
    return result


def verify_png(path: Path, capture: dict, resolution: list) -> None:
    filename = capture.get("file")
    require(isinstance(filename, str) and filename == capture["id"] + ".png",
            f"{capture['id']}: invalid PNG filename")
    image_path = path.parent / filename
    require(image_path.is_file() and image_path.resolve().parent == path.parent.resolve(),
            f"{capture['id']}: missing PNG or file outside capture directory")
    data = image_path.read_bytes()
    digest = capture.get("png_sha256")
    require(isinstance(digest, str) and re.fullmatch(r"[0-9a-f]{64}", digest) is not None,
            f"{capture['id']}: invalid PNG SHA-256")
    require(hashlib.sha256(data).hexdigest() == digest, f"{capture['id']}: PNG hash mismatch")
    require(len(data) >= 33 and data[:16] == b"\x89PNG\r\n\x1a\n\x00\x00\x00\rIHDR",
            f"{capture['id']}: not a PNG with an IHDR header")
    require(list(struct.unpack(">II", data[16:24])) == resolution,
            f"{capture['id']}: PNG dimensions differ from manifest")
    require(zlib.crc32(data[12:29]) == struct.unpack(">I", data[29:33])[0],
            f"{capture['id']}: invalid PNG header checksum")
    require(data[24:29] in (b"\x08\x02\x00\x00\x00", b"\x08\x06\x00\x00\x00"),
            f"{capture['id']}: expected Godot 8-bit RGB/RGBA PNG")
    position, image_data, ended = 33, False, False
    while position + 12 <= len(data):
        length = struct.unpack(">I", data[position:position + 4])[0]
        end = position + 12 + length
        require(end <= len(data), f"{capture['id']}: truncated PNG chunk")
        chunk = data[position + 4:end - 4]
        require(zlib.crc32(chunk) == struct.unpack(">I", data[end - 4:end])[0],
                f"{capture['id']}: PNG chunk checksum mismatch")
        image_data |= chunk[:4] == b"IDAT" and length > 0
        position = end
        if chunk[:4] == b"IEND":
            ended = length == 0 and end == len(data)
            break
    require(image_data and ended, f"{capture['id']}: incomplete PNG")


def load_manifest(path: Path, baseline: bool) -> tuple[dict, dict]:
    data = json.loads(path.read_text())
    role = "baseline" if baseline else "patched"
    require(isinstance(data, dict), f"{role}: manifest is not an object")
    require(data.get("capture_status") == "captured_requires_visual_review",
            f"{role}: capture is not complete ({data.get('capture_status')!r}); "
            f"{len(data.get('captures', []))} captures; {data.get('failure', '')}")
    require(data.get("renderer") == "forward_plus" and
            data.get("rendering_device_available") is True and data.get("ssr_supported") is True,
            f"{role}: real Forward+ RenderingDevice and SSR support required")
    require(data.get("display_server") not in (None, "", "headless") and bool(data.get("device")),
            f"{role}: real display and rendering adapter required")
    require(data.get("capture_scope") == "full_fixture" and
            data.get("selected_views") == [] and data.get("selected_periods") == [],
            f"{role}: subset captures cannot satisfy the full review")
    require(data.get("presets") == (["High"] if baseline else list(PRESETS)) and
            data.get("check_rebase") is (not baseline), f"{role}: wrong presets or rebase mode")
    require(data.get("shader_time_frozen") is True, f"{role}: shader time was not frozen")
    size = data.get("resolution")
    require(isinstance(size, list) and len(size) == 2 and
            all(type(value) is int and value > 0 for value in size), f"{role}: invalid resolution")
    captures = indexed(data.get("captures"), lambda entry: entry.get("id"),
                       HIGH_IDS if baseline else PATCHED_IDS, f"{role} captures")
    for identity, entry in captures.items():
        require(entry.get("capture_status") == "captured" and entry.get("resolution") == size and
                entry.get("shader_time_frozen") is True, f"{identity}: invalid capture metadata")
        require(isinstance(entry.get("draw_calls"), (int, float)) and entry["draw_calls"] > 0,
                f"{identity}: no rendered geometry")
        expected_preset = ("Epic" if identity.startswith("far-route-") else
                           next(preset for preset in PRESETS if identity.endswith("-" + preset.lower())))
        require(entry.get("preset") == expected_preset, f"{identity}: mismatched preset")
        verify_png(path, entry, size)
    return data, captures


def pixel_measurement(measurement: object, pixels: int, label: str, exact: bool = False) -> None:
    require(isinstance(measurement, dict), f"{label}: missing pixel measurement")
    require(type(measurement.get("exact_equal")) is bool and measurement.get("total_pixels") == pixels,
            f"{label}: invalid pixel measurement")
    for key, maximum in (("changed_rgb_pixels", pixels), ("changed_rgb_fraction", 1),
                         ("mean_absolute_rgb_error_255", 255), ("max_rgb_error_255", 255)):
        value = measurement.get(key)
        require(type(value) in (int, float) and math.isfinite(value) and 0 <= value <= maximum,
                f"{label}: invalid {key}")
        if exact or measurement["exact_equal"]:
            require(value == 0, f"{label}: pixels are not exactly equal")
    require(math.isclose(measurement["changed_rgb_fraction"],
                         measurement["changed_rgb_pixels"] / pixels, abs_tol=1e-12),
            f"{label}: inconsistent changed-pixel fraction")
    if exact:
        require(measurement["exact_equal"] is True, f"{label}: pixels are not exactly equal")


def validate(baseline_path: Path, patched_path: Path) -> None:
    baseline, old = load_manifest(baseline_path, True)
    patched, new = load_manifest(patched_path, False)
    for key in ("resolution", "godot", "renderer", "rendering_driver", "device",
                "fixture_overrides", "settle_frames", "frame_samples"):
        require(key in baseline and baseline[key] == patched.get(key),
                f"baseline and patched {key} differ or are missing")
    provenance = baseline.get("fixture_provenance", {})
    require(isinstance(provenance, dict) and isinstance(provenance.get("baseline_ref"), str) and
            re.fullmatch(r"(?:[0-9a-f]{40}|[0-9a-f]{64})", provenance["baseline_ref"]) is not None,
            "baseline: missing pinned parent commit provenance")
    require(bool(baseline.get("source_sha256")) and
            patched.get("baseline_source_sha256") == baseline["source_sha256"] and
            patched.get("baseline_fixture_provenance") == provenance,
            "patched manifest does not identify the supplied baseline sources")
    require(baseline.get("comparisons") == [] and baseline.get("high_baseline_comparisons") == [] and
            baseline.get("rebase_comparisons") == [], "baseline has unexpected comparison entries")
    require(patched.get("all_baseline_high_pixels_equal") is True and
            patched.get("all_high_restored_pixels_equal") is True,
            "patched manifest does not report exact parent-High and restored-High preservation")
    parent_comparisons = indexed(patched.get("high_baseline_comparisons"), lambda entry: entry.get("id"),
                                 HIGH_IDS, "parent-High comparisons")
    restored = indexed(patched.get("comparisons"), lambda entry: (entry.get("period"), entry.get("view")),
                       PAIRS, "High-restored comparisons")
    pixels = baseline["resolution"][0] * baseline["resolution"][1]
    for period, view in sorted(PAIRS):
        identity = f"{period}-{view}-high"
        original, current, returned = old[identity], new[identity], new[identity + "-restored"]
        extreme = new[f"{period}-{view}-epic"]
        comparison = parent_comparisons[identity]
        require(comparison.get("baseline_file") == original["file"] and
                comparison.get("baseline_png_sha256") == original["png_sha256"],
                f"{identity}: wrong baseline image reference")
        for key in ("camera_eye", "camera_target", "camera_fov", "period", "hour",
                    "route_origin", "scene_local_translation"):
            require(key in original and original[key] == current.get(key) == returned.get(key) == extreme.get(key),
                    f"{identity}: camera, lighting or origin differs ({key})")
        pixel_measurement(comparison.get("high_vs_baseline"), pixels, identity + " vs parent", exact=True)
        pixel_measurement(restored[(period, view)].get("high_vs_restored"), pixels, identity + " restored", exact=True)
        pixel_measurement(restored[(period, view)].get("high_vs_extreme"), pixels, identity + " vs Epic")
        require(original["png_sha256"] == current["png_sha256"] == returned["png_sha256"],
                f"{identity}: exact equality reported but PNG bytes differ")
    rebase = indexed(patched.get("rebase_comparisons"), lambda entry: entry.get("view"),
                     {"road", "station", "water"}, "rebase comparisons")
    for view, comparison in rebase.items():
        require(comparison.get("same_absolute_point") is True and
                comparison.get("origin_before") == [300000, 0, -300000] and
                comparison.get("origin_after") == [301024, 0, -298976] and
                comparison.get("local_translation") == [-1024, 0, -1024],
                f"rebase {view}: invalid same-absolute-point setup")
        before, after = new[f"far-route-{view}-before"], new[f"far-route-{view}-after"]
        require(before.get("route_origin") == comparison["origin_before"] and
                after.get("route_origin") == comparison["origin_after"] and
                before.get("scene_local_translation") == [0, 0, 0] and
                after.get("scene_local_translation") == comparison["local_translation"],
                f"rebase {view}: captured origins disagree with measurement")
        pixel_measurement(comparison.get("before_vs_after"), pixels, f"rebase {view}")


def fixed_time_shader_code(source: str) -> str:
    """Same narrowly bounded transformation as the fixture's in-memory shader."""
    return (re.sub(r"\bTIME\b", "fixture_water_time", source)
            .replace("shader_type spatial;", "shader_type spatial;\nuniform float fixture_water_time = 0.0;")
            .replace('#include "extreme_surface_detail.gdshaderinc"',
                     '#include "res://game/shaders/extreme_surface_detail.gdshaderinc"'))


def validate_temporal(path: Path) -> dict:
    data = json.loads(path.read_text())
    require(isinstance(data, dict) and data.get("capture_status") == "temporal_diagnostic_captured_requires_review" and
            data.get("capture_scope") == "water_temporal_diagnostic", "temporal: incomplete or wrong diagnostic mode")
    require(data.get("renderer") == "forward_plus" and data.get("rendering_device_available") is True and
            data.get("display_server") not in (None, "", "headless") and bool(data.get("device")),
            "temporal: real Forward+ renderer required")
    require(data.get("shader_time_frozen") is True and data.get("check_rebase") is False and
            data.get("selected_views") == [] and data.get("selected_periods") == [],
            "temporal: global time must stay frozen without other capture modes")
    size = data.get("resolution")
    require(isinstance(size, list) and len(size) == 2 and all(type(v) is int and v > 0 for v in size),
            "temporal: invalid resolution")
    shader = data.get("temporal_shader", {})
    require(isinstance(shader, dict) and isinstance(shader.get("sha256"), dict),
            "temporal: missing shader provenance")
    require(shader.get("rollover_seconds") == 3600 and shader.get("endpoint_is_unwrapped") is True and
            shader.get("uniform") == "fixture_water_time", "temporal: wrong TIME substitution or rollover semantics")
    expected_files = {"source": "temporal_source_water.gdshader", "fixed_time": "temporal_fixed_time_water.gdshader"}
    require(shader.get("files") == expected_files, "temporal: missing or unsafe shader artifact filenames")
    shader_code = {}
    for kind, filename in expected_files.items():
        file = path.parent / filename
        require(file.is_file() and file.resolve().parent == path.parent.resolve(), "temporal: missing shader artifact")
        code = file.read_bytes()
        require(hashlib.sha256(code).hexdigest() == shader.get("sha256", {}).get(kind),
                f"temporal: {kind} shader hash mismatch")
        shader_code[kind] = code.decode("utf-8")
    source_path = "res://game/shaders/geographic_water.gdshader"
    require(isinstance(data.get("source_sha256"), dict) and shader.get("source_path") == source_path and
            data.get("source_sha256", {}).get(source_path) == shader["sha256"]["source"],
            "temporal: saved shader does not match source provenance")
    require(re.search(r"\bTIME\b", shader_code["source"]) is not None and
            fixed_time_shader_code(shader_code["source"]) == shader_code["fixed_time"],
            "temporal: shader transformation contains an unexpected change")
    captures = indexed(data.get("captures"), lambda entry: entry.get("id"),
                       {"temporal-water-" + key for key in TEMPORAL_TIMES}, "temporal captures")
    first = captures["temporal-water-t0"]
    for sample, seconds in TEMPORAL_TIMES.items():
        identity = "temporal-water-" + sample
        entry = captures[identity]
        require(entry.get("capture_status") == "captured" and entry.get("resolution") == size and
                entry.get("shader_time_frozen") is True and entry.get("preset") == "Diagnostic-Epic-temporal" and
                entry.get("period") == "dusk" and entry.get("hour") == 18.25 and entry.get("draw_calls", 0) > 0,
                f"{identity}: invalid temporal capture metadata")
        for key in ("camera_eye", "camera_target", "camera_fov", "route_origin", "scene_local_translation",
                    "preset_values", "ssr_enabled", "radiance_size_enum"):
            require(key in first and first[key] == entry.get(key), f"{identity}: {key} changed between samples")
        state = entry.get("diagnostic", {})
        require(isinstance(state, dict) and state.get("kind") == "water_temporal" and state.get("global_time_frozen") is True and
                state.get("surface_detail") == 1.0 and state.get("source_shader_sha256") == shader["sha256"]["source"] and
                state.get("fixed_time_shader_sha256") == shader["sha256"]["fixed_time"],
                f"{identity}: invalid shader or detail metadata")
        for key, expected in (("requested_time_seconds", seconds), ("production_time_seconds", seconds % 3600),
                              ("shader_uniform_time_seconds", struct.unpack("f", struct.pack("f", seconds))[0])):
            actual = state.get(key)
            require(type(actual) in (int, float) and math.isclose(actual, expected, rel_tol=1e-13, abs_tol=1e-12),
                    f"{identity}: incorrect {key}")
        verify_png(path, entry, size)
    comparisons = indexed(data.get("temporal_comparisons"), lambda entry: entry.get("id"),
                          set(TEMPORAL_PAIRS), "temporal comparisons")
    summary = {}
    for label, (left, right) in TEMPORAL_PAIRS.items():
        left, right = "temporal-water-" + left, "temporal-water-" + right
        comparison = comparisons[label]
        require(comparison.get("from") == left and comparison.get("to") == right, f"{label}: incorrect sample pair")
        difference = comparison.get("pixel_difference")
        pixel_measurement(difference, size[0] * size[1], label)
        same_bytes = captures[left]["png_sha256"] == captures[right]["png_sha256"]
        require(difference["exact_equal"] == same_bytes, f"{label}: equality metric disagrees with PNGs")
        summary[label] = difference
    return summary


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--baseline", type=Path)
    parser.add_argument("--patched", type=Path)
    parser.add_argument("--temporal", type=Path, help="Validate only the distinct six-image fixed-time water diagnostic.")
    args = parser.parse_args()
    try:
        if args.temporal:
            require(not args.baseline and not args.patched, "--temporal cannot be combined with production manifests")
            measurements = validate_temporal(args.temporal)
            print("EXTREME_TEMPORAL_VALID: six PNGs, source/transformed shader hashes and five measurements verified; "
                  "not production motion proof or an artistic quality pass. " + json.dumps(measurements, sort_keys=True))
            return 0
        require(args.baseline is not None and args.patched is not None, "provide --baseline and --patched, or --temporal")
        validate(args.baseline, args.patched)
    except (InvalidCapture, OSError, ValueError, TypeError, KeyError, StopIteration) as error:
        print(f"EXTREME_CAPTURE_INVALID: {error}", file=sys.stderr)
        return 1
    print("EXTREME_CAPTURE_VALID: 15 baseline + 51 patched PNGs verified; "
          "15 parent-High and 15 restored-High comparisons exact. "
          "Rebase differences recorded, not automatically approved. "
          "Artistic quality and target-GPU performance still require review.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
