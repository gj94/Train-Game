#!/usr/bin/env python3
"""Require complete genuine-renderer evidence for the bounded station review.

Usage: python3 tools/check_extreme_station_manifest.py \
    --baseline /path/to/baseline/manifest.json --patched /path/to/patched/manifest.json

Requires 4 parent-High and 12 patched images, exact parent/restored High pixels,
all fixed cameras/periods, and unchanged recorded world/geometry/source state.
This is evidence validation, never artistic or target-hardware approval.
PNG structure/hash and pixel measurement checks reuse the source-fixture validator.
"""
from __future__ import annotations

import argparse
import json
from pathlib import Path
import re
import sys

from check_extreme_capture_manifest import (
    InvalidCapture, indexed, pixel_measurement, require, verify_png,
)

VIEWS = ("platform-track", "platform-canopy")
PERIODS = ("daylight", "dusk")
PRESETS = ("High", "Extreme", "High-restored")
PAIRS = {(period, view) for period in PERIODS for view in VIEWS}
HIGH_IDS = {f"{period}-{view}-high" for period, view in PAIRS}
PATCHED_IDS = {f"{period}-{view}-{preset.lower()}" for period, view in PAIRS for preset in PRESETS}
SHA = re.compile(r"[0-9a-f]{64}")


def load_manifest(path: Path, baseline: bool) -> tuple[dict, dict]:
    data = json.loads(path.read_text())
    role = "baseline" if baseline else "patched"
    require(isinstance(data, dict), f"{role}: manifest is not an object")
    require(data.get("capture_status") == "captured_requires_visual_review",
            f"{role}: not a completed rendering ({data.get('capture_status')!r})")
    require(data.get("capture_scope") == "bounded_synthetic_station", f"{role}: wrong scene scope")
    require(data.get("renderer") == "forward_plus" and data.get("rendering_device_available") is True and
            data.get("display_server") not in (None, "", "headless") and bool(data.get("device")),
            f"{role}: real Forward+ renderer required")
    require(data.get("presets") == (["High"] if baseline else list(PRESETS)), f"{role}: wrong presets")
    require(data.get("shader_time_frozen") is True, f"{role}: shader time was not frozen")
    require(type(data.get("simulation_step_calls")) is int and data["simulation_step_calls"] == 0,
            f"{role}: simulation was stepped")
    require(data.get("world_unchanged") is True and data.get("static_geometry_unchanged") is True and
            data.get("source_files_unchanged") is True, f"{role}: missing unchanged-state checks")
    size = data.get("resolution")
    require(isinstance(size, list) and len(size) == 2 and
            all(type(value) is int and value > 0 for value in size), f"{role}: invalid resolution")
    expected = HIGH_IDS if baseline else PATCHED_IDS
    captures = indexed(data.get("captures"), lambda entry: entry.get("id"), expected, f"{role} captures")
    for identity, entry in captures.items():
        require(entry.get("capture_status") == "captured" and entry.get("resolution") == size and
                entry.get("shader_time_frozen") is True, f"{identity}: invalid capture metadata")
        require(isinstance(entry.get("draw_calls"), (int, float)) and entry["draw_calls"] > 0,
                f"{identity}: no rendered geometry")
        require(entry.get("preset") in PRESETS and
                identity == f"{entry.get('period')}-{entry.get('view')}-{entry.get('preset', '').lower()}",
                f"{identity}: inconsistent view/preset")
        require(entry.get("station_visible_fixtures") == 4, f"{identity}: station lights missing")
        require(entry.get("station_active_lights") == (4 if entry.get("period") == "dusk" else 0),
                f"{identity}: fixed station lighting differs")
        verify_png(path, entry, size)
    checks = indexed(data.get("invariant_checks"), lambda entry: entry.get("id"),
                     expected | {"after_build"}, f"{role} invariants")
    for name in ("world_sha256_before", "geometry_sha256_before"):
        require(isinstance(data.get(name), str) and SHA.fullmatch(data[name]) is not None,
                f"{role}: invalid initial {name}")
    for identity, check in checks.items():
        require(check.get("world_unchanged") is True and check.get("geometry_unchanged") is True and
                check.get("world_sha256") == data["world_sha256_before"] and
                check.get("geometry_sha256") == data["geometry_sha256_before"],
                f"{role}: state changed at {identity}")
    require(data.get("station_nameboards") == 4 and data.get("station_light_sites") == 4 and
            data.get("track_stats", {}).get("sleepers") == 996, f"{role}: bounded game geometry missing")
    sources = data.get("source_sha256")
    provenance = data.get("source_provenance")
    require(isinstance(sources, dict) and bool(sources) and isinstance(provenance, dict),
            f"{role}: source provenance missing")
    simulation_files = 0
    for entry in provenance.get("files", []):
        relative = entry.get("path", "")
        if relative.endswith(".import"):
            continue  # Importer-owned cache remaps, not game/simulation source.
        require(sources.get("res://" + relative) == entry.get("sha256") and
                isinstance(entry.get("sha256"), str) and SHA.fullmatch(entry["sha256"]) is not None,
                f"{role}: source hash mismatch for {relative}")
        simulation_files += relative.startswith("sim/") and relative.endswith(".gd")
    require(simulation_files > 0, f"{role}: no unchanged simulation source hashes")
    return data, captures


def validate(baseline_path: Path, patched_path: Path) -> None:
    baseline, old = load_manifest(baseline_path, True)
    patched, new = load_manifest(patched_path, False)
    for key in ("resolution", "godot", "renderer", "rendering_driver", "device", "fixture_overrides",
                "settle_frames", "frame_samples", "world_sha256_before", "synthetic_station"):
        require(key in baseline and baseline[key] == patched.get(key), f"baseline/patched mismatch: {key}")
    pin = baseline["source_provenance"].get("baseline_ref", "")
    require(isinstance(pin, str) and re.fullmatch(r"[0-9a-f]{40}|[0-9a-f]{64}", pin) is not None,
            "baseline: missing pinned original commit")
    require(patched.get("baseline_source_sha256") == baseline["source_sha256"],
            "patched manifest references different baseline sources")
    old_sim = {name: digest for name, digest in baseline["source_sha256"].items() if name.startswith("res://sim/")}
    new_sim = {name: digest for name, digest in patched["source_sha256"].items() if name.startswith("res://sim/")}
    require(old_sim == new_sim, "simulation source differs from pinned parent")
    require(baseline.get("comparisons") == [] and baseline.get("high_baseline_comparisons") == [],
            "baseline contains unexpected comparisons")
    require(patched.get("all_baseline_high_pixels_equal") is True and
            patched.get("all_high_restored_pixels_equal") is True, "parent/restored High pixels differ")
    parent = indexed(patched.get("high_baseline_comparisons"), lambda entry: entry.get("id"),
                     HIGH_IDS, "parent-High comparisons")
    restored = indexed(patched.get("comparisons"), lambda entry: (entry.get("period"), entry.get("view")),
                       PAIRS, "restored-High comparisons")
    pixels = baseline["resolution"][0] * baseline["resolution"][1]
    for period, view in sorted(PAIRS):
        identity = f"{period}-{view}-high"
        original, current, returned = old[identity], new[identity], new[identity + "-restored"]
        extreme = new[f"{period}-{view}-extreme"]
        for key in ("camera_eye", "camera_target", "camera_fov", "period", "hour"):
            require(key in original and original[key] == current.get(key) == returned.get(key) == extreme.get(key),
                    f"{identity}: fixed camera/lighting mismatch ({key})")
        comparison = parent[identity]
        require(comparison.get("baseline_file") == original["file"] and
                comparison.get("baseline_png_sha256") == original["png_sha256"], f"{identity}: wrong baseline PNG")
        pixel_measurement(comparison.get("high_vs_baseline"), pixels, identity + " vs parent", exact=True)
        pixel_measurement(restored[(period, view)].get("high_vs_restored"), pixels, identity + " restored", exact=True)
        pixel_measurement(restored[(period, view)].get("high_vs_extreme"), pixels, identity + " Extreme")
        require(original["png_sha256"] == current["png_sha256"] == returned["png_sha256"],
                f"{identity}: PNG bytes contradict exact pixel equality")


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--baseline", type=Path, required=True)
    parser.add_argument("--patched", type=Path, required=True)
    args = parser.parse_args()
    try:
        validate(args.baseline, args.patched)
    except (InvalidCapture, OSError, ValueError, TypeError, KeyError) as error:
        print(f"EXTREME_STATION_INVALID: {error}", file=sys.stderr)
        return 1
    print("EXTREME_STATION_EVIDENCE_VALID: 4 original High + 12 patched PNGs; "
          "4 original-High and 4 restored-High comparisons exact. "
          "Recorded world, static geometry and simulation source unchanged. Visual review still required.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
