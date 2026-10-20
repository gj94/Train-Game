#!/usr/bin/env python3
"""Fail closed unless a full parent-High / patched Extreme review is complete.

Usage: python3 tools/check_extreme_capture_manifest.py \
    --baseline /path/to/baseline/manifest.json --patched /path/to/manifest.json

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
PRESETS = ("High", "Extreme", "High-restored")
PAIRS = {(period, view) for period in PERIODS for view in VIEWS}
HIGH_IDS = {f"{period}-{view}-high" for period, view in PAIRS}
PATCHED_IDS = {
    f"{period}-{view}-{preset.lower()}"
    for period, view in PAIRS
    for preset in PRESETS
} | {f"far-route-{view}-{phase}" for view in ("road", "station") for phase in ("before", "after")}


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
        expected_preset = ("Extreme" if identity.startswith("far-route-") else
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
        extreme = new[f"{period}-{view}-extreme"]
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
        pixel_measurement(restored[(period, view)].get("high_vs_extreme"), pixels, identity + " vs Extreme")
        require(original["png_sha256"] == current["png_sha256"] == returned["png_sha256"],
                f"{identity}: exact equality reported but PNG bytes differ")
    rebase = indexed(patched.get("rebase_comparisons"), lambda entry: entry.get("view"),
                     {"road", "station"}, "rebase comparisons")
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


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--baseline", required=True, type=Path)
    parser.add_argument("--patched", required=True, type=Path)
    args = parser.parse_args()
    try:
        validate(args.baseline, args.patched)
    except (InvalidCapture, OSError, ValueError, TypeError, KeyError, StopIteration) as error:
        print(f"EXTREME_CAPTURE_INVALID: {error}", file=sys.stderr)
        return 1
    print("EXTREME_CAPTURE_VALID: 15 baseline + 49 patched PNGs verified; "
          "15 parent-High and 15 restored-High comparisons exact. "
          "Rebase differences recorded, not automatically approved. "
          "Artistic quality and target-GPU performance still require review.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
