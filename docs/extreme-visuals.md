# Epic visual preset

Integrated from `codex/extreme-visual-fidelity` at `5c406aa` for R40.
Select **Graphics → Epic** to enable it. High remains the default.
Internal source filenames retain the upstream `extreme` name.
This is a presentation-only choice; it does not change the railway simulation.


## R40 native integration

The merged preset is named **Epic** in the game. R39 road metre UVs and the
separate UV2 dust shoulder remain unchanged; fine asphalt detail uses local
coordinates with a bounded origin phase. Both origin uniforms update on rebase.
The integrated source passed 731 game tests and 76 review-tool checks. Native
material and five-full-train day/night evidence is in
`art/performance/epic-2026-10-21/README.md` in the source repository. Native pixel
comparisons contain small differences, recorded there; the older software CI
pixel-exact results below must not be mistaken for new native GPU results.
Epic adds GPU cost; High restores the previous settings. The 4090 Laptop itself
still needs a same-camera comparison at the user's chosen resolution.

## What changes

- Filtered close-range ground normals and material variation, using the existing
  licensed grass/laterite textures.
- Dry asphalt aggregate and aligned world-projected normals, without adding
  weather, road geometry or changing markings.
- Shallow paver bevel shading and differentiated masonry, painted metal and
  roof microdetail. Optical glass and readable signs/instruments are not replaced.
- Filtered analytic water ripples from roughly 7 m to 18 cm, with unresolved
  slope variance returned to roughness. This is shading only, not displacement;
  water remains opaque and dielectric. Existing High waves remain unchanged.
- Concrete boundary finish with projection-aligned normals; photographed ballast,
  stable sleeper finish, filtered running-surface rail wear and matched shoulder
  mineral tint. Railway geometry, coverage and contacts remain unchanged.
- Distance-faded shadows from the existing station-lamp pool, without changing lamp
  placement, allocation, brightness or visibility. Other presets retain original
  shadow-free lamps. Shadows fade smoothly from 20 to 60 m; light fade remains
  90–130 m. Uniform settings avoid shadow pops when nearest-first slots reorder.
- Sharper sky reflections (512 instead of the original 256 radiance size),
  and 150% of High's tree/building/other-train
  detail ranges. Mesh LOD threshold is 0.5 rather than 1.0.
- Native resolution, 8× MSAA and FXAA remain. The first render review found that
  disabling FXAA worsened thin overhead lines for little material benefit.

High remains the default. Existing High, Balanced and Performance values are
unchanged; the four new switches default off when loading old preference files.
Epic does not add passengers or plants, extend the world streaming radius,
alter sun-shadow resolution beyond High, or alter camera limits. The optional
positional shadows use the existing pool of at most 24 lamps, with shadow rendering
skipped beyond 60 m. Dense multi-platform stations can still require many shadow
maps; this is an explicit GPU/atlas cost, not a guaranteed four-light budget.

## Boundaries

`game/extreme_visuals.gd` applies `extreme_detail` as a per-geometry shader uniform
(slot 15). It does not edit a shared authored material or duplicate source meshes.
Newly activated streamed subtrees use the current settings. Road and station
finishes receive the world-owned route-origin offset alongside the existing water
update. R39 road UV/UV2 and legacy absolute projection are preserved. Paver color and bevels share
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
optional SSR and longer mesh-detail ranges can be costly, particularly at 4K. Screen-space
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
source hashes, image hashes, High → Epic → High-restored pixel comparisons
and limitations. Time and camera positions are fixed for the comparison.

The review workflow has read-only repository permissions, no deployment and an
exact review-branch trigger restricted to explicit edits of its workflow file.
It uses the SHA-256-verified official Godot 4.7.2 portable build and Ubuntu Mesa.
Ordinary code commits do not trigger repeated capture jobs.

## Full-game playtest

1. From a saved daytime platform view, compare High and Epic without moving
   the camera. Inspect paving edges, adjacent road surfaces and nearby ground.
2. Repeat at dusk/night. Check that reflections do not obscure signs, signals,
   instruments or the view through the occupied cab glass.
3. Ride past trees/buildings and inspect the longer mesh-to-impostor transitions.
   Switch Epic → Performance → High, then visit a newly streamed station.
4. Cross an origin-rebase boundary near a road, platform or water surface. New
   grain, bevels and waves should remain attached to the same physical surface.
5. Look across water at grazing angles and move the camera slowly. Check fine-
   detail shimmer and wave continuity. Optional screen-space reflections are off
   in Epic: the tested Godot 4.7.2 software renderer only produced silhouettes
   in the MSAA-disabled diagnostic configurations. Do not sacrifice thin-wire AA just to enable this effect.
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
definition and worse thin-line antialiasing with FXAA disabled. Epic now keeps
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
High images and twelve current High/Epic/restored images. Structural checks
preserve world and mesh buffers, but are explicitly not rendered visual proof.

The third material run completed 15 original + 49 current frames, with all 15
original/restored High pairs exact. The original bounded station run completed
4 original + 12 current frames with all four pairs exact and state unchanged.
The next material contract adds water-rebase frames (51 current); the richer
station fixture adds existing palms/grass and a measured LOD camera (6/18 frames).
New water, fence, track and lamp-shadow refinements are pending those captures.
SSR off/on remained pixel-identical even on a smooth diagnostic metal mirror;
reflection visibility is not yet claimed. A final controlled MSAA/raymarch
diagnostic is separate from production settings.

The [fourth material run](https://github.com/gj94/Train-Game/actions/runs/39487392500)
completed 15 baseline + 51 current images. All 15 original-High and 15 restored-
High comparisons are pixel-exact. Directional water ripples and a broken-up sun
path are now visible. Ten isolated diagnostic frames establish actual reflected
column/block silhouettes in the MSAA-off/default-SSR diagnostic configurations,
but no SSR response with production
8× MSAA. Epic therefore retains MSAA and sharper sky while leaving SSR off;
the separate advanced SSR option carries this renderer limitation. This is not
a claim that SSR fails on every GPU, nor a strict single-variable MSAA proof: the
working diagnostic also changes raymarch settings.

The [rich station run](https://github.com/gj94/Train-Game/actions/runs/39487392781)
completed 6 baseline + 18 current images. All six original/restored High pairs
are exact, with world/geometry invariants preserved. Existing palm/grass assets
and measured LOD ranges are included. Fence material, coherent ballast/shoulder
tint and lamp-cast bench/column shadows show a visible improvement. The synthetic
halt is not a full-route or train-interior sign-off. Lamp-shadow softness and
water regularity are undergoing another pixel review before final handoff.

Review found and corrected a rank-dependent shadow handoff risk before final
sign-off: sorting the fixed pool could exchange its fourth and fifth physical
lamps, abruptly changing shadows and source size. Uniform distance-faded shadow
settings now follow every eligible pool entry. A motion-only two-face station
fixture exercises the exact crossing without changing production site selection.

Optional diagnostic commands remain separate from the main review contract:

- `--water-temporal-diagnostic` captures six explicit float32 water times, including
  adjacent frames and the 3600-second phase closure. The fixture-only shader
  changes only TIME to a fixed uniform; saved source/rewrite hashes are validated
  with `check_extreme_capture_manifest.py --temporal <manifest>`. This is not a
  moving-camera or real-time performance recording.
- `--motion-review` in the station fixture captures sixteen deterministic stepped
  camera/preset views across vegetation ranges and an eight-lamp sorting boundary.
  `check_extreme_station_manifest.py --motion <manifest>` verifies completeness,
  physical-site light properties and source/world/geometry invariants. Host-side
  range witnesses do not themselves prove GPU culling or smooth transitions.
