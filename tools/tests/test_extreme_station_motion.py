"""Optional motion contract tests. Mock metadata is not published as render evidence."""
import json
import math
from pathlib import Path
import sys
import tempfile
import unittest
from unittest.mock import patch

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
import check_extreme_station_manifest as validator


class MotionManifestTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.path = Path(self.temp.name) / "manifest.json"
        self.data = self.make_manifest()
        self.png_check = patch.object(validator, "verify_png")
        self.png_check.start()  # Shared PNG validation has separate real-file tests.

    def tearDown(self):
        self.png_check.stop()
        self.temp.cleanup()

    @staticmethod
    def make_manifest():
        sources = {"res://" + name: "c" * 64 for name in (*validator.VEGETATION_RESOURCES, "sim/rail_world.gd")}
        groups = [dict(id=anchor[0], kind="coconut_palm" if name == "palm" else "coastal_grass",
                       shared_aabb_center=anchor[1], instances=16 if name == "palm" else 197)
                  for name, anchor in validator.MOTION_ANCHORS.items()]
        data = dict(capture_status="captured_stepped_motion_requires_visual_review",
            capture_scope="bounded_station_stepped_motion", motion_mode="stepped_traversal_not_continuous_motion",
            presets=["High", "Epic"], shader_time_frozen=True, simulation_step_calls=0,
            world_unchanged=True, static_geometry_unchanged=True, source_files_unchanged=True,
            comparisons=[], high_baseline_comparisons=[], resolution=[2, 2], world_sha256_before="a" * 64,
            geometry_sha256_before="b" * 64, source_sha256=sources,
            source_provenance={"files": [dict(path=name.removeprefix("res://"), sha256=digest) for name, digest in sources.items()]},
            vegetation_fixture=dict(palm_instances=16, grass_patches=197, catalog_empty=True,
                                    full_catalog_prepared=False, groups=groups),
            station_nameboards=8, station_light_sites=8, synthetic_station={"platform_faces": 2}, track_stats={"sleepers": 996},
            renderer="forward_plus", rendering_device_available=True, display_server="x11", device="unit-test metadata",
            screenshots_captured=16, motion_steps=[], motion_witnesses=[], invariant_checks=[], captures=[], motion_comparisons=[])
        for identity in sorted(validator.MOTION_IDS | {"after_build"}):
            factor = 1.5 if identity.endswith("-epic") else 1
            data["invariant_checks"].append(dict(id=identity, world_unchanged=True, geometry_unchanged=True,
                world_sha256="a" * 64, geometry_sha256="b" * 64, vegetation_ranges_match=True,
                vegetation_range_factor=factor, vegetation_ranges=validator.vegetation_ranges(factor)))
        for index, (step_id, segment, hour, eye, target) in enumerate(validator.MOTION_STEPS):
            data["motion_steps"].append(dict(id=step_id, segment=segment, hour=hour, eye=eye, target=target))
            data["motion_comparisons"].append(dict(step=step_id, high_vs_extreme=dict(exact_equal=True, total_pixels=4,
                changed_rgb_pixels=0, changed_rgb_fraction=0, mean_absolute_rgb_error_255=0, max_rgb_error_255=0)))
            for preset in ("High", "Epic"):
                identity = f"motion-{step_id}-{preset.lower()}"
                nodes = []
                for group in groups:
                    distance = math.dist(eye, group["shared_aabb_center"])
                    for role, ranges in validator.vegetation_ranges(1.5 if preset == "Epic" else 1).items():
                        if role.startswith("palm") != (group["kind"] == "coconut_palm"):
                            continue
                        begin, end, begin_margin, end_margin = ranges
                        nodes.append(dict(node=role, group=group["id"], kind=group["kind"], role=role,
                            shared_aabb_center=group["shared_aabb_center"], distance_metres=distance, ranges=ranges,
                            within_nominal_range=(begin == 0 or distance >= begin) and (end == 0 or distance < end),
                            within_begin_margin=begin > 0 and abs(distance - begin) <= begin_margin,
                            within_end_margin=end > 0 and abs(distance - end) <= end_margin,
                            visible_property=True, visible_in_tree=True, centre_in_frustum=True,
                            instances=group["instances"], visible_instance_count=-1))
                sites = []
                for site_index in range(8):
                    position = [4.87 if site_index < 4 else -4.87, 6.04, 252 + 24 * (site_index % 4)]
                    sites.append(dict(id=f"group0-site{site_index}", position=position, distance_metres=math.dist(eye, position)))
                sites.sort(key=lambda site: site["distance_metres"])
                night = .5 if segment == "light-pool" else 0
                active = [site for site in sites if site["distance_metres"] < 130] if night else []
                policy = dict(shadow_enabled=preset == "Epic", light_size=.12 if preset == "Epic" else 0,
                    shadow_blur=1.5 if preset == "Epic" else 1, distance_fade_enabled=True,
                    distance_fade_begin=90, distance_fade_shadow=20 if preset == "Epic" else 50, distance_fade_length=40)
                pool = [dict(slot=slot, site=site["id"], visible=True, energy=2.8 * night,
                             position=[site["position"][0], site["position"][1] - .25, site["position"][2]],
                             shadow_policy=policy.copy()) for slot, site in enumerate(active)]
                lights = dict(allocated_pool_nodes=24, visible_fixtures=8, sites_by_distance=sites,
                    fixture_site_order=[site["id"] for site in sites], fixture_transform_readback_available=True,
                    night_amount=night, active_lights=len(pool), active_pool=pool)
                data["motion_witnesses"].append(dict(id=identity, step=step_id, step_index=index, segment=segment,
                    hour=hour, preset=preset, camera_eye=eye, camera_target=target, vegetation=nodes, lights=lights,
                    visibility_evidence="host flags and nominal distance tests only; not GPU culling or opacity"))
                data["captures"].append(dict(id=identity, capture_status="captured", resolution=[2, 2],
                    shader_time_frozen=True, draw_calls=10, view=step_id, preset=preset, hour=hour,
                    period="daylight" if segment == "lod" else "dusk", station_active_lights=len(pool),
                    station_visible_fixtures=8, camera_eye=eye, camera_target=target))
        return data

    def witness(self, step="lights-rank-after", preset="Epic"):
        return next(w for w in self.data["motion_witnesses"] if w["step"] == step and w["preset"] == preset)

    def validate(self, structural_only=False):
        self.path.write_text(json.dumps(self.data))
        validator.validate_motion(self.path, structural_only)

    def assert_rejected(self, message):
        with self.assertRaisesRegex(validator.InvalidCapture, message):
            self.validate()

    def test_complete_sixteen_image_contract(self):
        self.validate()

    def test_missing_capture(self):
        self.data["captures"].pop()
        self.assert_rejected("missing IDs")

    def test_missing_rank_handoff_witness(self):
        self.data["motion_witnesses"].remove(self.witness())
        self.assert_rejected("missing IDs")

    def test_missing_motion_comparison(self):
        self.data["motion_comparisons"].pop()
        self.assert_rejected("missing IDs")

    def test_false_rank_assignment(self):
        self.witness()["lights"]["active_pool"][3]["site"] = "group0-site0"
        self.assert_rejected("nearest light-pool")

    def test_old_four_rank_shadow_policy(self):
        self.witness()["lights"]["active_pool"][4]["shadow_policy"]["shadow_enabled"] = False
        self.assert_rejected("nonuniform or incorrect shadow policy")

    def test_site_size_jump(self):
        self.witness()["lights"]["active_pool"][3]["shadow_policy"]["light_size"] = 0
        self.assert_rejected("nonuniform or incorrect shadow policy")

    def test_shadow_fade_leaks_into_light_activation(self):
        self.witness()["lights"]["active_pool"][3]["shadow_policy"]["distance_fade_begin"] = 20
        self.assert_rejected("nonuniform or incorrect shadow policy")

    def test_changed_allocation(self):
        self.witness()["lights"]["allocated_pool_nodes"] = 25
        self.assert_rejected("allocation changed")

    def test_false_shared_aabb_distance(self):
        self.witness("lod-210")["vegetation"][0]["distance_metres"] += 10
        self.assert_rejected("false AABB distance")

    def test_wrong_lod_range(self):
        self.witness("lod-210")["vegetation"][0]["ranges"][1] = 175
        self.assert_rejected("wrong actual LOD")

    def test_missing_lod_node(self):
        self.witness("lod-210")["vegetation"].pop()
        self.assert_rejected("nodes changed")

    def test_camera_mismatch(self):
        self.witness("lod-210")["camera_eye"] = [0, 0, 0]
        self.assert_rejected("vector mismatch")

    def test_false_frustum_target(self):
        self.witness("lod-210")["vegetation"][0]["centre_in_frustum"] = False
        self.assert_rejected("not in camera frustum")

    def test_false_gpu_visibility_claim(self):
        self.witness()["visibility_evidence"] = "GPU visibility proven"
        self.assert_rejected("GPU visibility limitation")

    def test_missing_gpu_fixture_readback(self):
        self.witness()["lights"]["fixture_transform_readback_available"] = False
        self.assert_rejected("readback missing")

    def test_headless_capture(self):
        self.data["display_server"] = "headless"
        self.assert_rejected("real Forward")

    def test_mutated_source(self):
        self.data["source_sha256"]["res://sim/rail_world.gd"] = "f" * 64
        self.assert_rejected("source hash mismatch")

    def test_mutated_world(self):
        self.data["invariant_checks"][0]["world_sha256"] = "f" * 64
        self.assert_rejected("invariant changed")

    def test_structural_mode_is_separate_and_explicit(self):
        self.data.update(capture_status="structural_motion_validation_only_not_rendered", captures=[], screenshots_captured=0,
                         motion_comparisons=[], rendering_device_available=False, display_server="headless")
        for witness in self.data["motion_witnesses"]:
            witness["lights"].update(fixture_transform_readback_available=False, fixture_site_order=[])
        self.validate(structural_only=True)
        self.assert_rejected("structural-only evidence")
        self.assertFalse(list(self.path.parent.glob("*.png")))

    def test_static_validator_rejects_motion_contract(self):
        self.path.write_text(json.dumps(self.data))
        with self.assertRaises(validator.InvalidCapture):
            validator.load_manifest(self.path, False)


if __name__ == "__main__":
    unittest.main()
