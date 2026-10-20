#!/usr/bin/env python3
"""Require complete genuine-renderer evidence for the bounded station review.

Usage: python3 tools/check_extreme_station_manifest.py \
    --baseline /path/to/baseline/manifest.json --patched /path/to/patched/manifest.json

Requires 6 parent-High and 18 patched images, exact parent/restored High pixels,
all fixed cameras/periods, and unchanged recorded world/geometry/source state.
This is evidence validation, never artistic or target-hardware approval.
PNG structure/hash and pixel measurement checks reuse the source-fixture validator.
Optional --motion MANIFEST requires a distinct 16-image stepped traversal;
--motion-structure MANIFEST checks host witnesses only and never approves images.
"""
from __future__ import annotations

import argparse
import json
import math
from pathlib import Path
import re
import sys

from check_extreme_capture_manifest import (
    InvalidCapture, indexed, pixel_measurement, require, verify_png,
)

VIEWS = ("platform-track", "platform-canopy", "vegetation-lod")
PERIODS = ("daylight", "dusk")
PRESETS = ("High", "Extreme", "High-restored")
PAIRS = {(period, view) for period in PERIODS for view in VIEWS}
HIGH_IDS = {f"{period}-{view}-high" for period, view in PAIRS}
PATCHED_IDS = {f"{period}-{view}-{preset.lower()}" for period, view in PAIRS for preset in PRESETS}
SHA = re.compile(r"[0-9a-f]{64}")
VEGETATION_RESOURCES = (
    "assets/models/scenery/coconut_palm.glb",
    "assets/models/scenery/impostors/coconut_palm_albedo.png",
    "assets/models/scenery/impostors/coconut_palm_normal.png",
)


def vegetation_ranges(factor: float) -> dict:
    return dict(palm_detail=[0, 175 * factor, 28 * factor, 28 * factor],
                palm_impostor=[175 * factor, 2700, 28 * factor, 180],
                grass_0=[0, 50 * factor, 12 * factor, 12 * factor],
                grass_1=[50 * factor, 90 * factor, 12 * factor, 12 * factor],
                grass_2=[90 * factor, 125 * factor, 12 * factor, 35 * factor])


def validate_vegetation(data: dict, captures: dict, checks: dict, role: str) -> None:
    vegetation = data.get("vegetation_fixture")
    require(isinstance(vegetation, dict), f"{role}: missing bounded vegetation evidence")
    require(vegetation.get("palm_instances") == 16 and vegetation.get("grass_patches") == 197 and
            vegetation.get("grass_blades_per_lod") == [384, 96, 24] and
            vegetation.get("catalog_empty") is True and vegetation.get("full_catalog_prepared") is False,
            f"{role}: vegetation bounds/catalogue differ")
    require(vegetation.get("shared_lod_bounds_checked") is True and
            vegetation.get("palm_transition_witness") is True and
            vegetation.get("grass_transition_witnesses") == [True, True, True],
            f"{role}: LOD-distance witnesses missing")
    groups = vegetation.get("groups")
    require(isinstance(groups, list) and bool(groups), f"{role}: missing vegetation groups")
    group_ids = [entry.get("id") for entry in groups]
    require(all(isinstance(key, str) and key for key in group_ids) and len(set(group_ids)) == len(group_ids),
            f"{role}: duplicate/invalid vegetation groups")
    total = {"coconut_palm": 0, "coastal_grass": 0}
    for group in groups:
        kind = group.get("kind")
        require(kind in total and type(group.get("instances")) is int and group["instances"] > 0,
                f"{role}: invalid vegetation instances")
        require(group.get("roles") == (["detail", "impostor"] if kind == "coconut_palm" else ["0", "1", "2"]),
                f"{role}: vegetation LOD representation missing")
        centre = group.get("shared_aabb_center")
        require(isinstance(centre, list) and len(centre) == 3 and
                all(type(value) in (int, float) and math.isfinite(value) for value in centre),
                f"{role}: invalid vegetation bounds centre")
        total[kind] += group["instances"]
    require(total == {"coconut_palm": 16, "coastal_grass": 197}, f"{role}: grouped vegetation totals differ")
    distances = indexed(vegetation.get("camera_distances"), lambda entry: (entry.get("group"), entry.get("view")),
                        {(key, view) for key in group_ids for view in VIEWS}, f"{role} LOD camera distances")
    witnesses = {"palm": False, "grass_0": False, "grass_1": False, "grass_2": False}
    for group in groups:
        for view in VIEWS:
            entry = distances[(group["id"], view)]
            eye = captures[f"daylight-{view}-high"].get("camera_eye")
            require(isinstance(eye, list) and len(eye) == 3, f"{role}: missing LOD camera")
            measured = math.dist(eye, group["shared_aabb_center"])
            require(type(entry.get("distance_metres")) in (int, float) and
                    math.isclose(entry["distance_metres"], measured, abs_tol=0.001) and
                    entry.get("kind") == group["kind"], f"{role}: LOD distance contradicts shared bounds")
            if view != "vegetation-lod":
                continue
            if group["kind"] == "coconut_palm":
                witnesses["palm"] |= 203 < measured < 220.5
            else:
                witnesses["grass_0"] |= 50 < measured < 75
                witnesses["grass_1"] |= 90 < measured < 135
                witnesses["grass_2"] |= 125 < measured < 187.5
    require(all(witnesses.values()), f"{role}: fixed camera misses nominal LOD transition bands")
    for identity, check in checks.items():
        factor = 1.5 if identity.endswith("-extreme") else 1.0
        require(check.get("vegetation_ranges_match") is True and check.get("vegetation_range_factor") == factor and
                check.get("vegetation_ranges") == vegetation_ranges(factor),
                f"{role}: incorrect/restoration-failed vegetation ranges at {identity}")


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
    validate_vegetation(data, captures, checks, role)
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
    require(provenance.get("vegetation_provenance", {}).get("resources") == list(VEGETATION_RESOURCES) and
            provenance.get("vegetation_provenance", {}).get("register") == "docs/assets.md" and
            all("res://" + name in sources for name in (*VEGETATION_RESOURCES, "docs/assets.md")),
            f"{role}: existing vegetation model/licence provenance missing")
    return data, captures


def validate(baseline_path: Path, patched_path: Path) -> None:
    baseline, old = load_manifest(baseline_path, True)
    patched, new = load_manifest(patched_path, False)
    for key in ("resolution", "godot", "renderer", "rendering_driver", "device", "fixture_overrides",
                "settle_frames", "frame_samples", "world_sha256_before", "synthetic_station", "vegetation_fixture"):
        require(key in baseline and baseline[key] == patched.get(key), f"baseline/patched mismatch: {key}")
    pin = baseline["source_provenance"].get("baseline_ref", "")
    require(isinstance(pin, str) and re.fullmatch(r"[0-9a-f]{40}|[0-9a-f]{64}", pin) is not None,
            "baseline: missing pinned original commit")
    require(patched.get("baseline_source_sha256") == baseline["source_sha256"],
            "patched manifest references different baseline sources")
    old_sim = {name: digest for name, digest in baseline["source_sha256"].items() if name.startswith("res://sim/")}
    new_sim = {name: digest for name, digest in patched["source_sha256"].items() if name.startswith("res://sim/")}
    require(old_sim == new_sim, "simulation source differs from pinned parent")
    for name in VEGETATION_RESOURCES:
        require(baseline["source_sha256"]["res://" + name] == patched["source_sha256"].get("res://" + name),
                f"vegetation source differs from pinned parent: {name}")
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


MOTION_STEPS = (
    ("lod-140", "lod", 12.0, [-73, 3, 294], [-73, 6.201989, 154]),
    ("lod-170", "lod", 12.0, [-73, 3, 324], [-73, 6.201989, 154]),
    ("lod-210", "lod", 12.0, [-73, 3, 364], [-73, 6.201989, 154]),
    ("lod-260", "lod", 12.0, [-73, 3, 414], [-73, 6.201989, 154]),
    ("lod-350", "lod", 12.0, [-73, 3, 504], [-73, 6.201989, 154]),
    ("lights-rank-before", "light-pool", 18.65, [4, 2.95, 276.79], [0, 1.6, 300]),
    ("lights-rank-after", "light-pool", 18.65, [4, 2.95, 276.83], [0, 1.6, 300]),
    ("lights-two", "light-pool", 18.65, [4, 2.95, 450], [0, 3, 300]),
)
MOTION_IDS = {f"motion-{step[0]}-{preset.lower()}" for step in MOTION_STEPS for preset in ("High", "Extreme")}
MOTION_ANCHORS = {
    "palm": ("coconut_palm(-128.0, 0.0, 128.0)", [-73, 6.201989, 154]),
    "grass": ("coastal_grass(-96.0, 0.0, 240.0)", [-50.531288, 0.119856, 260.006317]),
}


def close_vector(actual: object, expected: list, label: str) -> None:
    require(isinstance(actual, list) and len(actual) == 3 and
            all(type(value) in (int, float) and math.isfinite(value) for value in actual) and
            math.dist(actual, expected) < .001, f"{label}: vector mismatch")


def validate_motion(path: Path, structural_only: bool = False) -> None:
    """Independent optional contract. Never accept this in the static 6+18 gate."""
    data = json.loads(path.read_text())
    require(isinstance(data, dict), "motion: manifest is not an object")
    expected_status = ("structural_motion_validation_only_not_rendered" if structural_only else
                       "captured_stepped_motion_requires_visual_review")
    require(data.get("capture_status") == expected_status and
            data.get("capture_scope") == "bounded_station_stepped_motion" and
            data.get("motion_mode") == "stepped_traversal_not_continuous_motion",
            "motion: wrong mode, incomplete capture, or structural-only evidence")
    require(data.get("presets") == ["High", "Extreme"] and data.get("shader_time_frozen") is True,
            "motion: wrong presets or unfrozen shader time")
    require(type(data.get("simulation_step_calls")) is int and data["simulation_step_calls"] == 0 and
            data.get("world_unchanged") is True and data.get("static_geometry_unchanged") is True and
            data.get("source_files_unchanged") is True, "motion: missing source/state invariance")
    require(data.get("comparisons") == [] and data.get("high_baseline_comparisons") == [],
            "motion: static comparison results must remain separate")
    size = data.get("resolution")
    require(isinstance(size, list) and len(size) == 2 and
            all(type(value) is int and value > 0 for value in size), "motion: invalid resolution")
    steps = indexed(data.get("motion_steps"), lambda entry: entry.get("id"),
                    {step[0] for step in MOTION_STEPS}, "motion steps")
    witnesses = indexed(data.get("motion_witnesses"), lambda entry: entry.get("id"), MOTION_IDS, "motion witnesses")
    checks = indexed(data.get("invariant_checks"), lambda entry: entry.get("id"),
                     MOTION_IDS | {"after_build"}, "motion invariants")
    for field in ("world_sha256_before", "geometry_sha256_before"):
        require(isinstance(data.get(field), str) and SHA.fullmatch(data[field]) is not None,
                f"motion: invalid {field}")
    for identity, check in checks.items():
        factor = 1.5 if identity.endswith("-extreme") else 1.0
        require(check.get("world_unchanged") is True and check.get("geometry_unchanged") is True and
                check.get("world_sha256") == data["world_sha256_before"] and
                check.get("geometry_sha256") == data["geometry_sha256_before"] and
                check.get("vegetation_ranges_match") is True and check.get("vegetation_range_factor") == factor and
                check.get("vegetation_ranges") == vegetation_ranges(factor), f"motion: invariant changed at {identity}")
    sources = data.get("source_sha256")
    provenance = data.get("source_provenance")
    require(isinstance(sources, dict) and bool(sources) and isinstance(provenance, dict), "motion: no source provenance")
    sim_files = 0
    for entry in provenance.get("files", []):
        relative = entry.get("path", "")
        if relative.endswith(".import"):
            continue
        require(sources.get("res://" + relative) == entry.get("sha256") and
                isinstance(entry.get("sha256"), str) and SHA.fullmatch(entry["sha256"]) is not None,
                f"motion: source hash mismatch for {relative}")
        sim_files += relative.startswith("sim/") and relative.endswith(".gd")
    require(sim_files > 0 and all("res://" + name in sources for name in VEGETATION_RESOURCES),
            "motion: required simulation/vegetation source hashes missing")
    vegetation = data.get("vegetation_fixture", {})
    require(vegetation.get("palm_instances") == 16 and vegetation.get("grass_patches") == 197 and
            vegetation.get("catalog_empty") is True and vegetation.get("full_catalog_prepared") is False,
            "motion: bounded existing vegetation changed")
    require(data.get("station_nameboards") == 8 and data.get("station_light_sites") == 8 and
            data.get("synthetic_station", {}).get("platform_faces") == 2 and
            data.get("track_stats", {}).get("sleepers", 0) >= 900, "motion: genuine two-face station/track evidence missing")
    group_list = vegetation.get("groups", [])
    require(isinstance(group_list, list) and bool(group_list), "motion: no actual vegetation groups")
    groups = {group["id"]: group for group in group_list}
    require(len(groups) == len(group_list), "motion: duplicate vegetation groups")
    require(sum(group.get("instances", 0) for group in group_list if group.get("kind") == "coconut_palm") == 16 and
            sum(group.get("instances", 0) for group in group_list if group.get("kind") == "coastal_grass") == 197,
            "motion: group instance totals differ")
    captures = {}
    if structural_only:
        require(data.get("captures") == [] and data.get("screenshots_captured") == 0 and
                data.get("motion_comparisons") == [], "motion structure: must not claim rendered captures")
    else:
        require(data.get("renderer") == "forward_plus" and data.get("rendering_device_available") is True and
                data.get("display_server") not in (None, "", "headless") and bool(data.get("device")),
                "motion: real Forward+ renderer required")
        captures = indexed(data.get("captures"), lambda entry: entry.get("id"), MOTION_IDS, "motion captures")
        require(data.get("screenshots_captured") == 16, "motion: expected exactly 16 PNGs")
        comparisons = indexed(data.get("motion_comparisons"), lambda entry: entry.get("step"),
                              {step[0] for step in MOTION_STEPS}, "motion comparisons")
        for step, comparison in comparisons.items():
            pixel_measurement(comparison.get("high_vs_extreme"), size[0] * size[1], "motion " + step)
        for identity, capture in captures.items():
            require(capture.get("capture_status") == "captured" and capture.get("resolution") == size and
                    capture.get("shader_time_frozen") is True and type(capture.get("draw_calls")) in (int, float) and
                    capture["draw_calls"] > 0, f"{identity}: invalid render readback")
            verify_png(path, capture, size)
    stable_nodes = None
    for index, (step_id, segment, hour, eye, target) in enumerate(MOTION_STEPS):
        step = steps[step_id]
        require(step.get("segment") == segment and step.get("hour") == hour, f"motion {step_id}: wrong period")
        close_vector(step.get("eye"), eye, step_id + " planned eye")
        close_vector(step.get("target"), target, step_id + " planned target")
        pair_lights = []
        for preset in ("High", "Extreme"):
            identity = f"motion-{step_id}-{preset.lower()}"
            witness = witnesses[identity]
            require(witness.get("step") == step_id and witness.get("step_index") == index and
                    witness.get("segment") == segment and witness.get("hour") == hour and witness.get("preset") == preset,
                    f"{identity}: inconsistent step metadata")
            close_vector(witness.get("camera_eye"), eye, identity + " eye")
            close_vector(witness.get("camera_target"), target, identity + " target")
            require(witness.get("visibility_evidence") == "host flags and nominal distance tests only; not GPU culling or opacity",
                    f"{identity}: missing GPU visibility limitation")
            nodes = witness.get("vegetation")
            require(isinstance(nodes, list) and bool(nodes), f"{identity}: missing actual vegetation nodes")
            node_names = [node.get("node") for node in nodes]
            require(all(isinstance(name, str) and name for name in node_names) and len(set(node_names)) == len(node_names),
                    f"{identity}: duplicate or invalid actual nodes")
            if stable_nodes is None:
                stable_nodes = set(node_names)
            require(set(node_names) == stable_nodes, f"{identity}: actual vegetation nodes changed")
            expected_ranges = vegetation_ranges(1.5 if preset == "Extreme" else 1.0)
            seen_roles = set()
            seen_group_roles = {name: set() for name in groups}
            for node in nodes:
                group = groups.get(node.get("group"), {})
                require(bool(group) and node.get("kind") == group.get("kind"), f"{identity}: unknown actual vegetation group")
                close_vector(node.get("shared_aabb_center"), group["shared_aabb_center"], identity + " group centre")
                distance = math.dist(eye, node["shared_aabb_center"])
                require(type(node.get("distance_metres")) in (int, float) and
                        math.isclose(node["distance_metres"], distance, abs_tol=.001), f"{identity}: false AABB distance")
                role = node.get("role"); seen_roles.add(role)
                seen_group_roles[node["group"]].add(role)
                require(role in expected_ranges and node.get("ranges") == expected_ranges[role], f"{identity}: wrong actual LOD range")
                begin, end, begin_margin, end_margin = node["ranges"]
                require(node.get("within_nominal_range") is ((begin == 0 or distance >= begin) and (end == 0 or distance < end)) and
                        node.get("within_begin_margin") is (begin > 0 and abs(distance - begin) <= begin_margin) and
                        node.get("within_end_margin") is (end > 0 and abs(distance - end) <= end_margin),
                        f"{identity}: false nominal range/margin witness")
                require(node.get("visible_property") is True and node.get("visible_in_tree") is True and
                        type(node.get("centre_in_frustum")) is bool and node.get("instances") == group["instances"] and
                        node.get("visible_instance_count") in (-1, group["instances"]), f"{identity}: host visibility/count changed")
            require(seen_roles == set(expected_ranges), f"{identity}: missing LOD roles")
            for name, roles in seen_group_roles.items():
                expected_roles = {"palm_detail", "palm_impostor"} if groups[name]["kind"] == "coconut_palm" else {"grass_0", "grass_1", "grass_2"}
                require(roles == expected_roles, f"{identity}: missing actual LOD group representations")
            if segment == "lod":
                for anchor, (group_id, centre) in MOTION_ANCHORS.items():
                    selected = [node for node in nodes if node["group"] == group_id]
                    require(bool(selected) and all(node["centre_in_frustum"] for node in selected),
                            f"{identity}: {anchor} target not in camera frustum")
                    for node in selected:
                        close_vector(node["shared_aabb_center"], centre, identity + " anchor " + anchor)
            lights = witness.get("lights", {})
            require(lights.get("allocated_pool_nodes") == 24 and lights.get("visible_fixtures") == 8,
                    f"{identity}: production light allocation changed")
            sites = lights.get("sites_by_distance", [])
            require(len(sites) == 8 and {site.get("id") for site in sites} == {f"group0-site{i}" for i in range(8)},
                    f"{identity}: missing actual light sites")
            for site in sites:
                site_index = int(site["id"].rsplit("site", 1)[1])
                close_vector(site.get("position"), [4.87 if site_index < 4 else -4.87, 6.04, 252 + 24 * (site_index % 4)], identity + " light site")
                require(type(site.get("distance_metres")) in (int, float) and
                        math.isclose(site["distance_metres"], math.dist(eye, site["position"]), abs_tol=.001),
                        f"{identity}: false light distance")
            require(sites == sorted(sites, key=lambda entry: entry["distance_metres"]), f"{identity}: light ranks unsorted")
            fixture_readback = lights.get("fixture_transform_readback_available")
            require(type(fixture_readback) is bool and (structural_only or fixture_readback),
                    f"{identity}: actual fixture-transform readback missing")
            require(lights.get("fixture_site_order") == ([site["id"] for site in sites] if fixture_readback else []),
                    f"{identity}: light rank/fixture mismatch")
            night = lights.get("night_amount")
            require(type(night) in (int, float) and math.isfinite(night) and 0 <= night <= 1 and
                    (night == 0 if segment == "lod" else night > .001), f"{identity}: wrong lighting state")
            active = [site for site in sites if site["distance_metres"] < 130] if night > .001 else []
            pool = lights.get("active_pool", [])
            require(lights.get("active_lights") == len(active) == len(pool), f"{identity}: wrong active light count")
            for slot, (lamp, site) in enumerate(zip(pool, active)):
                require(lamp.get("slot") == slot and lamp.get("site") == site["id"] and lamp.get("visible") is True and
                        type(lamp.get("energy")) in (int, float) and math.isclose(lamp["energy"], 2.8 * night, abs_tol=.001),
                        f"{identity}: actual nearest light-pool assignment differs")
                close_vector(lamp.get("position"), [site["position"][0], site["position"][1] - .25, site["position"][2]],
                             identity + " light pool position")
            # Shadow policy is allowed to differ by preset, not by physical site
            # or its current nearest-first slot. Position/energy/allocation match.
            light_base = {key: value for key, value in lights.items() if key != "active_pool"}
            light_base["active_pool"] = [{key: value for key, value in lamp.items() if key != "shadow_policy"} for lamp in pool]
            pair_lights.append(light_base)
            for lamp in pool:
                policy = lamp.get("shadow_policy", {})
                expected_policy = dict(shadow_enabled=preset == "Extreme", light_size=.12 if preset == "Extreme" else 0,
                                       shadow_blur=1.5 if preset == "Extreme" else 1, distance_fade_enabled=True,
                                       distance_fade_begin=90, distance_fade_shadow=20 if preset == "Extreme" else 50,
                                       distance_fade_length=40)
                require(set(policy) == set(expected_policy), f"{identity}: missing physical-site shadow policy")
                for field, expected in expected_policy.items():
                    require(policy[field] is expected if type(expected) is bool else
                            type(policy[field]) in (int, float) and math.isclose(policy[field], expected, abs_tol=.0001),
                            f"{identity}: nonuniform or incorrect shadow policy at {lamp['site']} ({field})")
            if not structural_only:
                capture = captures[identity]
                require(capture.get("view") == step_id and capture.get("preset") == preset and capture.get("hour") == hour and
                        capture.get("period") == ("daylight" if segment == "lod" else "dusk") and
                        capture.get("station_active_lights") == len(active) and capture.get("station_visible_fixtures") == 8,
                        f"{identity}: capture/witness metadata differs")
                close_vector(capture.get("camera_eye"), eye, identity + " captured eye")
                close_vector(capture.get("camera_target"), target, identity + " captured target")
        require(pair_lights[0] == pair_lights[1], f"{step_id}: High/Extreme changed actual light allocation")
    # Specific expected handoffs, not just generic positive counts.
    for preset in ("high", "extreme"):
        first = witnesses[f"motion-lights-rank-before-{preset}"]["lights"]
        second = witnesses[f"motion-lights-rank-after-{preset}"]["lights"]
        last = witnesses[f"motion-lights-two-{preset}"]["lights"]
        require(first["active_pool"][3]["site"] == "group0-site0" and first["active_pool"][4]["site"] == "group0-site6" and
                second["active_pool"][3]["site"] == "group0-site6" and second["active_pool"][4]["site"] == "group0-site0" and
                first["active_lights"] == second["active_lights"] == 8 and last["active_lights"] == 2,
                "motion: expected rank3/4 swap / eight-to-two light boundary absent")
        before_by_site = {lamp["site"]: lamp["shadow_policy"] for lamp in first["active_pool"]}
        after_by_site = {lamp["site"]: lamp["shadow_policy"] for lamp in second["active_pool"]}
        require(before_by_site == after_by_site, "motion: physical-site shadow properties jump when pool ranks exchange")


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--baseline", type=Path)
    parser.add_argument("--patched", type=Path)
    motion = parser.add_mutually_exclusive_group()
    motion.add_argument("--motion", type=Path, help="Validate a distinct 16-image stepped traversal manifest.")
    motion.add_argument("--motion-structure", type=Path, help="Validate witnesses only; explicitly no rendering proof.")
    args = parser.parse_args()
    if args.motion or args.motion_structure:
        if args.baseline or args.patched:
            parser.error("Motion review is separate from --baseline/--patched static review.")
        try:
            validate_motion(args.motion or args.motion_structure, structural_only=bool(args.motion_structure))
        except (InvalidCapture, OSError, ValueError, TypeError, KeyError, IndexError) as error:
            print(f"EXTREME_STATION_MOTION_INVALID: {error}", file=sys.stderr)
            return 1
        print("EXTREME_STATION_MOTION_STRUCTURE_VALID: 16 step/preset witnesses; no rendered images or visual approval." if args.motion_structure else
              "EXTREME_STATION_MOTION_EVIDENCE_VALID: 16 PNGs and bounded LOD/light-pool witnesses. Stepped traversal only; visual review still required.")
        return 0
    if not args.baseline or not args.patched:
        parser.error("Static review requires both --baseline and --patched.")
    try:
        validate(args.baseline, args.patched)
    except (InvalidCapture, OSError, ValueError, TypeError, KeyError) as error:
        print(f"EXTREME_STATION_INVALID: {error}", file=sys.stderr)
        return 1
    print("EXTREME_STATION_EVIDENCE_VALID: 6 original High + 18 patched PNGs; "
          "6 original-High and 6 restored-High comparisons exact. "
          "Bounded genuine vegetation, shared-bound distances and restored LOD ranges checked. "
          "Recorded world, static geometry and simulation source unchanged. Visual review still required.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
