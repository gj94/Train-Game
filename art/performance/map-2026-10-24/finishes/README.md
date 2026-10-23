# Rural road finishes — 24 October 2026

Rendering-only appearance recovery from the cached OSM source. Protected route
geometry, all simulation/prepared data, road elevations and support footprints
stay unchanged. The overlay carries surface/tracktype/smoothness only: 6,717
ways, 7,007 tags, 250,181 bytes. Source and road-ID SHA-256 provenance is included.

Materials reuse existing photographic textures. Concrete, staggered paving,
gravel and earth share the road shader, absolute metre UVs, clipping and terrain
projection. Untagged ordinary streets stay paved; country paths use explicit
artistic defaults. The source tags are not a survey of present lane condition.
Paving joints are filtered and shaded relative to the underlying concrete.
Unpaved lanes receive no painted centre line. Shoulder/earth-bank tint is lighter.

## Validation

- Full headless suite: 838 passed, zero failed, clean stderr. The later change
  only strengthens paving joint contrast in the shader; native checks cover it.
- 38 focused road tests; 17 Python tests. Six new runtime checks cover recovered
  tags, precedence/defaults, markings, station clipping, identical surface
  geometry and UV scale, and committed overlay provenance.
- All 32,857 road elevation segments, station walkway exclusions and overhead
  support posts compare exactly with 7b136ad. Profile input gate is current.
- All 4,893 protected files match. No full timetable or extracted-build runs.
- Native views use the source project, Vulkan, 1440 × 900, time frozen at zero,
  daylight set to 15:00. Final paving close-up supersedes the initial weak joints.
  The other five final views retain identical shading after that correction.

## Reproduction

- `tools/maps/road_finishes.py --pbf <southern-zone-261006.osm.pbf>` or
  `--recovered <recovered-road-tags.json>` regenerates the appearance overlay.
- `tools/capture_village_access.gd -- --cases=<cases.json> --output=<folder>`
  reproduces the native views. Use `--audio-driver Dummy` before `--script`.
- `tools/profile_road_generation.gd` compares the previous chunk/road scripts
  against current source on 90 station tiles, interleaved for three repeats.
  Both use the same current profile lookup. This measures CPU mesh creation,
  not target-PC frame rate. Results are recorded separately below.

## Remaining visual findings

The 2.5 km paving view exposes a jagged narrow waterway: `_stream` draws flat
source-segment quads while terrain varies underneath. Reproduction is saved in
`.local/map-2026-10-24/drainage-repro.json`, tile 0,2, ways w135107593/w65958901.
Correct its terrain/stream joining in the drainage pass, leaving rails intact.
The 143.7 km path camera mostly sees a neighbouring parallel asphalt road;
it is useful context but not evidence of visible earth surfacing at that point.
Audit low, parallel road/rail overlaps separately from legitimate crossings.

## Measured cost and shader stability

The isolated three-repeat comparison (90 tiles, same current profile data)
measured 51,406.700 ms before / 51,989.014 ms after: +1.13% aggregate mesh
creation time. Median tile was 119.43 / 120.77 ms. Vertex count is essentially
unchanged (-0.0135%; removed paint). Road material surfaces total 708 / 885
across all repeats: 25% more road-only batches, or 0.66 additional batches per
tile per repeat. This is not a 25% increase in whole-scene draw calls.

The native shader fixture compares a 1,024 m rebase at physical route origin
(262144,131072), in both High and Epic. Mean 8-bit channel differences are
0.0088 / 0.0103; 44 / 45 channels out of 1,555,200 differ by more than eight
(maximum 17). Pattern phase remains stable; tiny rasterization differences
remain. Fixture source and two representative images are included. This tests
rebase consistency, not temporal antialiasing or target-PC performance.

Playtest: lane at 2.5 km for paving, 130.8 km for concrete, 1.1 km for gravel,
42.6 km for an earth path and 197.8 km for the lighter approach bank. Move from
close-up to train distance and switch High/Epic. No timetable replay is needed.
