# Train rendering fidelity — 14 October 2026

The source WAP-7, ICF, LHB and Vande Bharat masters retain their evaluated
geometry. The discrepancy with the source previews was partly a presentation
bug: reducing a car's shadow detail changed a shadow-only mesh to `OFF`.
In Godot that disables shadow casting but draws the mesh normally. Simplified
shadow geometry could therefore cover the detailed train. Those meshes now
stay shadow-only and are hidden when unnecessary. Interior visibility acts on
their parent, so returning to a carriage cannot expose a hidden shadow mesh.

## Surface depth and lighting

- A deterministic offline bake traces 24 cosine-weighted rays from each unique
  surface probe against the complete imported car, excluding optical glazing
  and marking cards. Contact visibility covers 0.55 m; enclosure visibility
  covers 5 m. Shared probes use a 2 cm position grid and quantized split normals.
- Two normalized vertex channels carry these visibility values. The shader
  applies a restrained blend to ambient/reflected light. No paint colour,
  sunlight, camera, timetable time or world location is baked. This is an
  approximation of indirect occlusion, not path-traced moving-car GI.
  It uses the imported mechanical pose, so local indirect shading around an
  opened door or moved pantograph remains approximate; direct light is dynamic.
- Original positions, split normals, indices, UVs, procedural coordinates,
  material assignments, mechanical pivots and texture pixels remain unchanged.
  A separate four-byte-per-vertex buffer holds the bake. The importer still
  generates distance LODs; their selected triangle counts can change
  because the new colour attributes participate in simplification.
- The lighting cubemap now has a muted ground hemisphere. The pure-sky HDRI
  previously supplied sky light below the railway as well, washing out the
  running gear. The visible sky and clock-driven daylight cycle are retained.
- Exported two-sided train shaders no longer flip backface normals a second
  time. Forward+ already orients these normals before running fragment code;
  the redundant operation made VB flooring and inner ceiling sheets face away
  from the lamps. The fixed-camera night check now asserts a lit aisle floor.
  See the [Godot Forward+ implementation](https://github.com/godotengine/godot/blob/master/servers/rendering/renderer_rd/shaders/forward_clustered/scene_forward_clustered.glsl).
- Four shadowless ceiling lights follow the occupied carriage. Their positions
  are fixed in the car, rather than following the player's eyes. Interior-only
  layers keep them off terrain and locomotive paint. ICF shared shell/roof
  batches contain interior lining; LHB/VB body batches contain flooring. These
  shared batches also receive the light while the carriage is occupied.
- Known interior lamp diffusers emit softly. LHB shares one material between
  signs and diffusers; a source-coordinate height mask restricts emission to
  ceiling sheets. Ordinary signs, window glass and exterior markings do not
  receive this added emission.

AI interior/passenger culling and distant shadow hulls remain in place. Each
train allocates one four-light rig, but it is hidden unless its interior is
being viewed. Seated passengers can receive the active carriage lights.

## Rebuild and checks

Use the pinned source-port procedure in `wap7-detail.md` / `coach-detail.md`
first. `tools/install_train_occlusion_shaders.py` adds the shared shader term
without altering the authored graph or source-value indices. The Blender
material compiler also adds it on future exports.

Run `tools/blender/bake_train_occlusion.py` with background Blender,
`--factory-startup --disable-autoexec --python-exit-code 1`, then `--` followed
by model IDs and `--samples 24`. `--stage` writes independent model outputs
under `.local/train-fidelity/staged`; `tools/install_train_occlusion.py`
verifies original streams before installing them serially. The baker refuses
to bake an already-baked GLB; regenerate it from the source first.

Stop native games before installing/importing assets. Import with the editor
closed. Run the headless suite, `tools/check_train_occlusion.py`, the existing
WAP/coach port integrity checks, and native `tools/check_train_fidelity.gd`.
The latter reviews five representative vehicles through the playable adapter,
records GPU/draw counts, and compares pixels across shadow-detail switches.
`--night` repeats the fixed cameras at 22:00. The five-train benchmark and
`tools/check_day_night.gd` exercise the integrated game.

The preservation audit compares against R31 source commit `2405060`; changing
the source masters intentionally requires updating that comparison baseline.
Blender Cycles and Godot still differ in indirect light, reflection, glass,
noise and antialiasing. This pass does not establish pixel-identical renders.

## Measurements and evidence

The [native comparison gallery](../art/performance/train-fidelity-2026-10-14/gallery.html)
contains unretouched before/after captures, night interiors and integrated
railway views. Source comparisons use the same fixed cameras and 1600 × 900
viewport. The neutral review stage has no track geometry; it is not a route
screenshot. Raw reports are beside the gallery.

All 22 models passed the preservation audit: 31,388,331 original triangles,
unchanged geometry streams and texture pixels. The additional vertex buffers
total 107,761,132 bytes (102.8 MiB across the complete catalogue, not per train).
Actual GPU residency also depends on which models and generated LODs are loaded.
Five representative models passed the native shadow-budget transition check
in day and night with zero pixel difference when shadow rendering was disabled.
The VB night aisle-floor luminance was 0.358 against a minimum of 0.10.

Single-run GPU observations on the Radeon 780M development PC:

| Fixed review camera | Before | After |
| --- | ---: | ---: |
| WAP-7 pilot | 17.89 ms | 18.14 ms |
| WAP-7 exterior | 14.93 ms | 19.14 ms |
| LHB CC aisle | 23.40 ms | 24.69 ms |
| ICF GS aisle | 21.43 ms | 23.00 ms |
| VB EC aisle | 26.75 ms | 29.24 ms |

These are whole-stage GPU samples, not per-model costs or target-laptop FPS.
The bake's vertex attributes also make some generated LODs retain more triangles.
A separate experiment, before the final lamp/normal correction, disabled all
automatic LODs: VB EC aisle cost rose from 29.22 to 35.11 ms and rendered
primitives from 4.91 to 11.06 million. Production keeps automatic LODs.
The improvement is a fidelity tradeoff; it is not a global performance claim.

The integrated five-train benchmark passed with **91 vehicles and 5,580
simulated passengers**, no loading during the measured cases, zero rendered
seated passengers in pilot view and 140 in passenger view. All five formations
moved 23.65 m during the live phase. Against the R31 run at the same resolution,
culled static-view frame medians changed as follows:

| Busy-station view | R31 | This pass |
| --- | ---: | ---: |
| Pilot | 51.59 ms | 52.94 ms |
| Passenger | 52.85 ms | 56.41 ms |
| Platform | 50.39 ms | 54.75 ms |
| Overview | 41.93 ms | 47.26 ms |

GPU allocations rose from approximately 4.98 to 5.08 GB. Live-frame median
changed from 59.85 to 56.57 ms while GPU time increased from 42.73 to 47.15 ms;
the mixed CPU/GPU overlap means that single observation is not evidence of a
general FPS gain. Moving-train CPU work remains about 13 ms. These runs were
separate development-PC processes, not a controlled target-laptop experiment.
The full headless suite passed **595 tests**, with zero failures.
The integrated day/night fixture passed 23 assertions across eight views.

## Playtest

1. Inspect a WAP formation from the platform, move beyond 65 m and return.
   There should be no crude grey geometry over the body or through windows.
2. Enter its pilot seat, then walk to either end of an ICF or LHB carriage.
   Look at seats, racks, panels, lamps and the floor; lighting should stay fixed
   to the carriage while the camera moves.
3. Repeat in Vande Bharat and at a night departure. Check that ceiling lamps
   are visible, signs remain readable, and returning to an exterior camera
   disables the occupied-car light rig.
4. Run the crowded benchmark on the i9-13980HX / RTX 4090 Laptop target.
   Development-PC timings use a Radeon 780M and are not target-PC results.
