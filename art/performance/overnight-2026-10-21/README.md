# R39 scenery and electrification checks

Development PC: Ryzen 7840HS / Radeon 780M. The target remains the user's
i9-13980HX / RTX 4090 Laptop 16 GB / 64 GB RAM. These measurements are not
target-PC frame rates. No full-day timetable was rerun.

## Static correctness

- Headless game suite: **705 passed, zero failed**.
- OHE: **5,124 rows, 8,456 posts, 1,083 gantries**; 2,153 seamless chunk
  boundaries and 11,936 connected registrations, zero failures.
- Road export: all **4,305 scenery tiles**, with road surfaces in 1,074 tiles.
  Independent Shapely checks of 2,257,858 actual emitted triangles,
  9,314 rail-height intersections and 1,899 piers found no station,
  open-water, railway-envelope or pier/OHE conflicts. See
  `road-clearance-audit.json`; clipping uses a 3 cm station tolerance.
- **50 station road links**, zero endpoint-height failures.
- Profile freshness: **29,266 segments**, 1,793 checked inputs plus the
  scenery tile inventory. Five Python geometry tests and four release-gate
  tests pass. Seven download-page checks pass.
- The CPU optimization emits byte-identical road geometry over the entire
  corridor: SHA-256 in `road-optimized-equivalence.json`.

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
release source. `scenery-release-final-*.png` and `ohe-final-*.png` use the final
rendering code. The railway remained frozen in these fixtures.

The plain roof in the OHE fixture exposes thin-shadow aliasing. The small
invisible caster improves near-wire continuity without enlarging the visible
12 mm wire. Distant or low-resolution thin shadows can still alias; no global
shadow-resolution or bias increase is used to hide that limitation.

## Mesh construction cost

`profile_road_generation.gd` builds road meshes on 90 station-area tiles,
three passes each, alternating old/new code against identical map inputs.
It measures CPU construction, not rendered frame time. Native visual checks
were also running, so compare the paired measurements rather than absolute
numbers across machines.

| CPU road mesh construction | R38 code | R39 before optimization | R39 final |
|---|---:|---:|---:|
| Median per tile | 28.7–29.2 ms | 84.9 ms | 66.2 ms |
| p95 per tile | 185.8–189.0 ms | 436.2 ms | 393.3 ms |
| Median vertices | 2,052 | 4,471.5 | 4,471.5 |
| Median material surfaces | 3 | 3 | 3 |

The fuller road/deck geometry and clipping cost more to construct than the old
flat ribbons. This work stays on scenery workers, and the profile/clearance
indices are shared read-only. Rejecting off-corridor segments before terrain
sampling removed about 22% of the measured median construction cost while
preserving every emitted triangle. These results do not imply a 22% FPS gain.

The five native scenery captures retain their frame counters for inspection.
They are short source captures on the development GPU, with a headless test run
overlapping some captures, not an isolated release-performance benchmark.
