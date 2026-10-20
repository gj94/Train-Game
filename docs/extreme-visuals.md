# Extreme visual preset

This is an opt-in, presentation-only review branch. It does not replace the
work branch, publish a release, or change the railway simulation.

## What changes

- Filtered close-range ground normals and material variation, using the existing
  licensed grass/laterite textures.
- Dry asphalt aggregate and aligned world-projected normals, without adding
  weather, road geometry or changing markings.
- Shallow paver bevel shading and differentiated masonry, painted metal and
  roof microdetail. Optical glass and readable signs/instruments are not replaced.
- Filtered water detail with the existing wave phases/speeds, plus optional
  screen-space reflections. Water remains dielectric rather than metallic.
- Sharper sky reflections (512 instead of the original 256 radiance size),
  96-step screen-space reflections, and 150% of High's tree/building/other-train
  detail ranges. Mesh LOD threshold is 0.5 rather than 1.0.
- Native resolution, 8× MSAA and FXAA remain. The first render review found that
  disabling FXAA worsened thin overhead lines for little material benefit.

High remains the default. Existing High, Balanced and Performance values are
unchanged; the two new switches default off when loading old preference files.
Extreme does not add passengers or plants, extend the world streaming radius,
change shadows beyond the existing High budget, or alter camera limits.

## Boundaries

`game/extreme_visuals.gd` applies `extreme_detail` as a per-geometry shader uniform
(slot 15). It does not edit a shared authored material or duplicate source meshes.
Newly activated streamed subtrees use the current settings. Road and station
finishes receive the world-owned route-origin offset alongside the existing water
update; only Extreme uses the absolute projection. Paver color and bevels share
that projection, avoiding misalignment when the floating origin moves. Fine road
and station noise uses a bounded origin phase plus rebased local coordinates;
pavers use rational 30 cm cells. This avoids losing millimetre-scale detail when
absolute route positions approach 300 km. Existing ground UV and water phase
precision are not redesigned by this change.

The original environment reflection settings are captured and restored exactly.
Day/night ambient energy, fog color and simulation clock remain owned by the
existing day/night code. No edits are made to `sim/`, persistence, operating-day
inputs, prepared states, sound data, physics, dispatch, boarding or controls.

## Cost and limitations

This mode intentionally spends more GPU time and memory. Larger sky radiance,
SSR and longer mesh-detail ranges can be costly, particularly at 4K. Screen-space
reflections have the usual camera-edge/off-screen limitations and do not replace
ray tracing. Hardware and full-game visual validation must not be inferred from
headless unit tests or a source-material fixture.

The target remains the RTX 4090 Laptop GPU, not the cloud runner. Software Vulkan
frame intervals are useful for detecting gross regressions only, never target-PC
FPS claims. The source fixture does not cover trains, station masters, streamed
vegetation, long route traversal or the full gameplay scene.

## Reproducible source-material review

Run `python3 tools/check_extreme_surface_precision.py` for standard-library-only
float32 rebase checks and legacy-zero shader source comparison against the pinned
parent. These numerical/source checks do not substitute for rendered evidence.

Prepare the small fixture without importing the whole asset collection:

```sh
python3 tools/prepare_extreme_visual_fixture.py --output /tmp/extreme-fixture
godot --headless --path /tmp/extreme-fixture --editor --import
godot --path /tmp/extreme-fixture --rendering-method forward_plus \
  --script res://tools/check_extreme_visuals.gd -- \
  --output=/tmp/extreme-review --size=1280x720
```

Use a real display/rendering device for the final command. On Linux CI, Xvfb
with Mesa software Vulkan supplies a genuine renderer. `--headless` deliberately
fails capture with a blocked manifest and zero screenshots; a blank dummy image
is not evidence. The manifest records engine, renderer, adapter, resolution,
source hashes, image hashes, High → Extreme → High-restored pixel comparisons
and limitations. Time and camera positions are fixed for the comparison.

The review workflow has read-only repository permissions, no deployment and an
exact review-branch trigger restricted to explicit edits of its workflow file.
It uses the SHA-256-verified official Godot 4.7.2 portable build and Ubuntu Mesa.
Ordinary code commits do not trigger repeated capture jobs.

## Full-game playtest

1. From a saved daytime platform view, compare High and Extreme without moving
   the camera. Inspect paving edges, adjacent road surfaces and nearby ground.
2. Repeat at dusk/night. Check that reflections do not obscure signs, signals,
   instruments or the view through the occupied cab glass.
3. Ride past trees/buildings and inspect the longer mesh-to-impostor transitions.
   Switch Extreme → Performance → High, then visit a newly streamed station.
4. Cross an origin-rebase boundary near a road, platform or water surface. New
   grain, bevels and waves should remain attached to the same physical surface.
5. Look across water at grazing angles and move the camera slowly. Check SSR
   edge behavior and fine-detail shimmer. Disable Detailed reflections alone
   if its cost or screen-edge artifacts are objectionable.
6. Measure uncapped frame times with F10 at the same resolution/view; report the
   actual GPU and image dimensions. Existing saved-graphics benchmark mode can
   compare the chosen settings. Do not compare different traffic/camera states.
7. Return to High and reload: original appearance, settings, passenger counts,
   service state and controls should remain intact.

## Validation record

Implementation and verification are ongoing on official Godot 4.7.2. The focused
graphics, day/night, train-visibility and streaming suites pass 61 assertions;
MEMU/WAP7 cab suites pass 8, and parallel simulation passes 8 with four workers.
These are headless behavior checks, not rendering approval.

The unchanged parent commit `65e30b152ed612074f16d06d95896014229e4c77` reproduces
one operating-day test failure in an independently extracted baseline fixture:
the intensive timetable layout signature differs from the generated layout.
Its cause is not established; no simulation or timetable changes are made here
to hide it. The full-suite attempt did not complete: unavailable large authored
VB scene imports caused an existing train-build-queue test to loop on missing
resources. Two isolated VB import attempts were externally killed before scene
cache output; the cause of those kills is unknown. Full authored-model coverage
is therefore not claimed. Original asset/import settings remain unchanged.

The first [software Vulkan render run](https://github.com/gj94/Train-Game/actions/runs/39473413938)
produced all 15 parent High images and 33 patched images before the capture
watchdog expired. All 11 completed original-High / patched-High / restored-High
comparisons are pixel-identical. This is partial evidence, not a complete pass:
the original workflow pipeline masked the timeout exit status. The workflow now
uses pipefail and a separate fail-closed manifest/image validator.

Pixel review found improved filtered paving and plaster, but insufficient water
definition and worse thin-line antialiasing with FXAA disabled. Extreme now keeps
FXAA; water reflection/normal diagnostics and full night/rebase captures follow.
No target-hardware or full-game visual sign-off is claimed. The morning handoff
will record final parent/head commits and complete evidence.

The second run completed all 45 standard patched images. All 15 parent-High and
15 restored-High comparisons, including night, are exactly equal. Its 14-minute
watchdog expired before the four far-route images, so it correctly failed. The
bounded watchdog is now 20 minutes, with water diagnostics moved first. Full
completion is still required; these partial captures are not relabelled passes.

A separate bounded station fixture uses actual station, permanent-way, OHE and
lighting builders with a synthetic single-track halt. It never steps simulation
or loads a full route/train. The preparer and validator are
`tools/prepare_extreme_station_scene.py` and
`tools/check_extreme_station_manifest.py`; its expected evidence is four original
High images and twelve current High/Extreme/restored images. Structural checks
preserve world and mesh buffers, but are explicitly not rendered visual proof.
