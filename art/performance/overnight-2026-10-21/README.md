# R39 scenery and electrification checks

Development PC: Ryzen 7840HS / Radeon 780M. The target remains the user's
i9-13980HX / RTX 4090 Laptop 16 GB / 64 GB RAM. These measurements are not
target-PC frame rates. No full-day timetable was rerun.

## Static correctness

- Headless game suite: **708 passed, zero failed**.
- OHE: **5,124 rows, 8,456 posts, 1,083 gantries**; 2,153 seamless chunk
  boundaries and 11,936 connected registrations, zero failures.
- Road export: all **4,305 scenery tiles**, with road surfaces in 1,074 tiles.
  Independent Shapely checks of 2,257,481 actual emitted triangles,
  9,177 rail-height intersections and 1,883 piers found no station,
  open-water, railway-envelope or pier/OHE conflicts. See
  `road-final-audit.json`; clipping uses a 3 cm station tolerance.
- **51 station road links**, zero endpoint-height failures.
- Profile freshness: **28,994 segments**, 1,793 checked inputs plus the
  scenery tile inventory. Six Python geometry tests and four release-gate
  tests pass. Seven download-page checks pass.
- The CPU optimization emitted byte-identical road geometry over the entire
  corridor before the final pedestrian-bridge cleanup: SHA-256 in
  `road-optimized-equivalence.json`. `road-clearance-audit.json` preserves that
  intermediate audit; `road-final-audit.json` checks the final geometry.
- Twenty mapped pedestrian bridge ways at fourteen stations are excluded from
  the road pass, preventing asphalt copies of station footbridges. Public road
  bridges remain. The exact ways/stations are in `road-surfaces-report.json`.

Profiles reconstruct OSM/SRTM geometry around the game's widened railway.
This is not proof that each bridge matches a surveyed civil structure. Long
ambiguous untagged water crossings are recorded in `road-surfaces-report.json`
and omitted over water instead of creating an invented viaduct.

## Streaming and source captures

The moving-camera soak ran for **3,742 seconds**, with 360 coverage samples
and 115 origin changes. ERS–TUVR, QLN–VAK, TVC–NYY and KZT–NCJ were swept and
reversed at a camera speed of 140 km/h, including TVC at 20:00. No near-track/
OHE gaps or coarse/near terrain coverage errors were recorded, and the world
was released on returning to the menu.

That soak began before the final long-arm, road-height and texture refinements.
It verifies the streaming approach but must not be described as the exact
release source. `scenery-release-final-*.png` use the optimized road code before
the final station-walkway cleanup; `ohe-final-*.png` use the final overhead code.
The railway remained frozen in these fixtures.

The subsequent full station tour ran **3,705 seconds** and visited all
**56 stations**, with **280 coverage samples**, no missing nearby track/OHE
or terrain coverage errors, and successful world release. It loaded runtime
source `55ebfec`, before the final walkway/sky refinements. Those changes have
a separate affected-station follow-up; do not label the earlier tour as the
exact final release.

That follow-up completed all **14 stations / 28 coverage samples** in **644
seconds**, with no missing nearby geometry or coverage errors and successful
world release. It includes the walkway/sky fixes, before the final flyover
junction barrier correction. Final close captures separately cover public
road bridges at ERS, Kundannoor near Kumbalam, QLN and TVC, including undersides.
The junction correction leaves openings for joining roads at the same height,
while retaining guardrails between roads at different heights.

The TVC close view also exposed a generated building intersecting the flyover.
Buildings now reserve the complete public-road corridor, including supports,
before facade/model placement. This conservatively excludes buildings beneath
raised roads; it does not exclude houses for tunnels or narrow footpaths.
`road-building-before.png` and the final TVC deck view show the correction.
The final bridge captures include both this and the junction correction.

The plain roof in the OHE fixture exposes thin-shadow aliasing. The small
invisible caster improves near-wire continuity without enlarging the visible
12 mm wire. Distant or low-resolution thin shadows can still alias; no global
shadow-resolution or bias increase is used to hide that limitation.
Morning, afternoon and evening views were also checked at 2048/4096/8192
shadow-map resolution, without runtime or shader errors.

An unrelated dashed vertical line above Kollam was reproduced with all world
geometry removed. The panorama's implicit texture derivatives crossed its 0/1
longitude wrap and selected a coarse, sun-bright mip. Wrapping the longitude
derivatives before `textureGrad` removed the line in the same native view,
while retaining ordinary mip filtering. `capture_sky_seam.gd` reproduces the
camera and captures morning, afternoon and night at three fields of view.
The filtering API is documented in Godot's
[shader function reference](https://docs.godotengine.org/en/stable/tutorials/shaders/shader_reference/shader_functions.html#shader-func-texturegrad).

## Mesh construction cost

`profile_road_generation.gd` builds road meshes on 90 station-area tiles,
three passes each, alternating old/new code against identical map inputs.
It measures CPU construction, not rendered frame time. Native visual checks
were also running, so compare the paired measurements rather than absolute
numbers across machines.

| CPU road mesh construction | R38 code | R39 before optimization | After optimization |
|---|---:|---:|---:|
| Median per tile | 28.7–29.2 ms | 84.9 ms | 66.2 ms |
| p95 per tile | 185.8–189.0 ms | 436.2 ms | 393.3 ms |
| Median vertices | 2,052 | 4,471.5 | 4,471.5 |
| Median material surfaces | 3 | 3 | 3 |

The fuller road/deck geometry and clipping cost more to construct than the old
flat ribbons. This work stays on scenery workers, and the profile/clearance
indices are shared read-only. Rejecting off-corridor segments before terrain
sampling removed about 22% of the measured median construction cost while
preserving every emitted triangle. These results precede the final duplicate
walkway removal and do not imply a 22% FPS gain.

The later barrier-junction check compared the same 90 tiles with only junction
openings enabled/disabled. Median construction was 83.60 / 82.44 ms and p95
474.99 / 468.31 ms respectively, with other checks running. This shows no
measured regression in that paired sample; it is not a frame-rate claim.
See `road-junction-cpu-summary.json`. The final roadway, shoulder, paint and
pier export remains byte-identical to the independently audited geometry
(`road-junction-geometry-equivalence.json`); only coping/guardrails changed.

The five native scenery captures retain their frame counters for inspection.
They are short source captures on the development GPU, with a headless test run
overlapping some captures, not an isolated release-performance benchmark.
