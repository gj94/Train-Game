# Connected raised road junctions — 24 October 2026

Rendering-only reconstruction. Track geometry, simulation and prepared railway
files are unchanged. These are source-development views, not a published build.

## What changed

The height network now inserts a shared vertex where a mapped road end lies
within 2 cm of a simplified through-road. It preserves layer separation and
connects bridge layers only at shared ramp endpoints. Parallel near-misses and
unnoded plan-view crossings remain separate. Small, level junction areas let
road edges meet across their width. Profile-to-ground transitions participate,
so blending a cross-slope cannot leave a step through a ground-level junction.
The runtime mesh preserves height-profile corners between its regular samples.

## Evidence

- 817 headless source tests; 14 Python road geometry/grade regressions.
- 32,857 render profile segments; 353 raised junctions have equal elevations.
- 2,169 visible junctions, 14,976 centre/edge probes on actual emitted triangles:
  maximum difference 6.15 mm; no failures against the 8 cm audit tolerance.
- Three unpaired diagnostics: one self-way continuation; the other two lie
  220.05 m and 221.19 m from the railway, at/beyond the 220 m scenery cutoff.
- Final geometry covers all 4,305 tiles. The final transition correction changed
  45 ways on 49 tiles. Those tiles were regenerated; unchanged rows were reused
  only after comparing profile ways and source/context/runtime-generator hashes.
- Independent clearance audit: 5,428,586 triangles, 2,180 piers and 13,256
  railway-crossing checks pass, including stations and water.
- Village clearance still passes: 7,526 approaches and 13,468 stair treads.
  Inaccessible entrances beside newly raised approaches are correctly omitted.
- Protected hashes: all 4,893 files unchanged. No full timetable rehearsal or
  regeneration and no extracted-distribution gameplay testing.
- Five frozen native views, railway clock zero, 1440 x 900. The first Kumbalam
  captures used the same profiles as final there; the last boundary correction
  affects the separately listed 49 tiles. Final captures used the dummy audio
  driver, avoiding a development-machine WASAPI device initialization error in
  an earlier intermediate capture.

## Cost and limitations

The isolated CPU-only interleaved road-generation comparison uses 90 tiles and
three passes per variant. Both variants use the final profiles and current
lookup implementation: it isolates ribbon subdivision, not the whole old/new
renderer. Aggregate generation/mesh time rises from 45.71 s to 48.32 s (+5.7%);
median tile time is 116.87 / 117.08 ms. Material-surface counts remain equal.
The selected station tiles emit 12.97% more vertices; this is worker-generated
geometry, not a measurement of frame time. Development GPU: Radeon 780M.
The target is an i9-13980HX / RTX 4090 Laptop 16 GB / 64 GB RAM.

Native views expose further work: some high approaches look too much like
networks of viaducts. Add believable earth/retaining support on dry clear land,
while keeping spans above rail, water and buildings open. Review redundant
collinear profile subdivisions and the prior terrain-projection worker cost.
Sparse landscape transitions and imported road-surface variety also remain.

## Reproduce / playtest after the eventual release

- Kumbalam junction at (2084.405, 7729.302), around 9.5 km: inspect both road
  edges and the canal span from low free camera.
- Raised joins at 146.2 and 269.7 km: inspect ramps and guardrail openings.
- Ground transition at 184.3 km: inspect the branch across the full road width.
- `tools/check_road_render_geometry.gd -- --all --output=res://.local/roads.jsonl`,
  followed by `tools/maps/audit_road_surfaces.py` and
  `tools/maps/check_rendered_road_junctions.py` with the generated profile report.
  These build static geometry without advancing railway time. `--tiles=x_z,...`
  supports bounded rechecks when only known profile ways have changed.
