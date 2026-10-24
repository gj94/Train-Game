# Overnight map refinement — 24 October 2026

The user requested at least six hours of useful map work, continuing until at
least 10:30 AM Asia/Singapore. The fixed start is 03:30:53 on 24 October; the
earliest completion is 10:30:00 that morning (02:30 UTC). Do not reset the start
or finish early. Progress and owned processes are recorded in
`.local/map-2026-10-24/window.json`.

## Scope and safeguards

- Refine the landscape around the existing railway: regional terrain relief,
  embankments/cuttings, drainage, connected country paths and roads, coherent
  village/station surroundings, grounded scenery and vegetation.
- Preserve track positions and operating geometry, all simulation code,
  timetable inputs and prepared railway data. Baseline commit: `3d72d61`.
  A SHA-256 manifest of protected tracked files is in
  `.local/map-2026-10-24/protected-inputs.json`.
- Kerala's backwaters and rice-growing coast should remain low and wet; use
  existing elevation for the more undulating southern landscape. Do not add
  generic mountains or random bumps to the permanent way.
- No dispatcher work, full timetable runs/regeneration, unrelated audio edits
  or repeated extracted-distribution gameplay tests. No sub-agents.
- R45 remains available while work proceeds. Commit and push coherent tested
  increments. Notify before preparing a follow-up full/incremental release.

## Work sequence

1. Establish representative source captures and numerical audits of terrain,
   roads, shorelines, station precincts and the southern route. Identify causes
   before adding detail. Inspect existing road-profile and placement consumers.
2. Improve common terrain shaping around protected rail formations and station
   footprints, including consistent transitions at tile/station boundaries.
   Keep scenery placements and generated road approach heights in agreement.
3. Refine road/path continuity, graded shoulders, access ramps and drainage.
   Resolve abrupt ends and hanging surfaces while preserving clearances.
4. Improve regional countryside composition and settlement grounding with
   bounded geometry, instancing and existing streaming budgets.
5. Audit representative close train-height views plus wider context, wet and
   dry terrain, road/rail crossings, station approaches and tile boundaries.
   Compare native performance on the Radeon 780M development PC; do not claim
   these measurements represent the i9-13980HX / RTX 4090 Laptop target.
6. Run relevant headless tests and native visual checks, verify protected input
   hashes, document limitations and exact playtest points. After the minimum
   window and successful validation, prepare and verify a follow-up release
   using the documented increasing-sequence full/incremental process. Record
   completion and pause the continuation automation.

## Initial finding

Ordinary terrain is currently flattened to rail height for 32 m on either side
of the route, then blended over another 58 m. Station widths are expanded in
500 m bins. This can erase visible embankments/cuttings and introduce a change
in terrain grading at bin boundaries. The road-profile generator duplicates
this calculation, so any change needs matching generation and placement checks.
This is a hypothesis to validate with route samples and native captures.

## Regional references

- [Kerala Irrigation: Kuttanad](https://www.irrigation.kerala.gov.in/node/77):
  low-lying paddy polders protected by bunds. Keep broad lowland fields and
  drainage rather than adding arbitrary hills.
- [Kerala Tourism: Varkala topography](https://www.keralatourism.org/varkala/varkala-topography.php):
  laterite relief and winding approaches. Use existing local elevation, without
  inventing coastal cliffs at the railway itself.
- [Kanniyakumari district agriculture](https://kanniyakumari.nic.in/agri/): varied
  terrain and extensive paddy/coconut cultivation. Preserve planted valleys and
  the more undulating southern route.

## First implementation checkpoint (validated)

- Ordinary formation half-width reduced to 14 m, with height-dependent grading
  back into existing DEM relief. Preserve the old station/ladder footprints and
  depot/outer-yard slopes; station changes taper continuously over 280 m.
- Actual mapped parallel lines widen their own formation envelope. The static
  route audit covers 8,946 rail positions: no worsened terrain support. Twelve
  previously imperfect samples remain for later visual examination; maximum
  old/new sampled deviation is unchanged at 1.941 m. These are presentation
  measurements, not changes to railway track positions or train physics.
- Offline road generator uses the same grading. Across 12,243 shared samples,
  99% agree within 2.7 mm; maximum disagreement is 8.5 cm at large geographic
  coordinates. Rebuilt bridge/approach profiles preserve station links (51,
  zero height failures).
- Ground road, shoulder and paint ribbons now follow the rendered terrain
  triangles, including the finer shoreline mesh. They blend into planar road
  approaches. Worker-local cell reuse and coplanar shortcuts bound extra work.
  Native 11.5 km views show the previously broken road now continuous; 169.7 km
  views show intact graded road surfaces beside the railway cutting/flyover.
- Eight native rural views captured with railway clock frozen at zero, plus
  four original station baselines. Evidence remains under
  `.local/map-2026-10-24/`; retain representative final evidence after validation.
- Final full source suite: **807 pass**; Python road tests: seven pass. No errors
  in native source captures or the editor. The profile release gate passes.
- All 4,305 scenery tiles examined; 5,433,511 emitted road/shoulder/paint triangles
  across 1,074 road-containing tiles pass independent station, water, rail and
  pier intersection checks, including 12,607 railway-crossing checks and 1,836
  piers. All 4,893 protected source/data hashes are unchanged.
- Evidence: `art/performance/map-2026-10-24/terrain-roads/`. No extra draw calls
  in matched 169.7 km native views; approximately 0.14% more rendered primitives.
  Exact road projection adds worker CPU time: the interleaved 90-tile test is
  about 1.8 times the old road-only generation cost. Other validation jobs ran
  concurrently; this is neither isolated frame timing nor target-PC FPS.

## Next work

- Continue until the fixed 10:30 minimum. R45 remains the published build.
- Connect village building fronts to mapped streets using grounded paths and
  steps where needed. Use surface tags for unpaved country tracks. Reject paths
  through buildings, waterways, railway envelopes or steep unsupported terrain.
- Ground compound walls on slopes; current flat-bottom beams can leave gaps
  even within the accepted 55–65 cm local variation. Verify that garden props
  belong to buildings actually rendered, rather than rejected footprints.
- Add restrained drainage and visible cut-bank texture where appropriate;
  inspect station outskirts, field edges and the distant vegetation transition.
- Revisit the twelve baseline rail/terrain discrepancy samples visually: bridge
  ends can legitimately span lower ground. Do not move tracks to hide a defect.
- Review road-worker generation overhead and broader native streaming before
  the final release. Keep the existing terrain mesh and visibility budgets.

## Second implementation checkpoint (validated)

Village access now uses the accepted rendered building record and the actual
front-of-asset bounds, keeping entrance steps in line with verandas. Paths are
1.3 m wide, at most 45 m long and capped at 24 per tile. Whole footprints are
checked against neighbours, waterways, station reservations and actual rail
clearances. Raised road profiles are sampled on their centreline; stairs land
on terrain with 9–19 cm rises and 34 cm runs. Unworkable slopes are omitted.

Compound walls use short level masonry panels with terrain-following bottoms
and grounded posts. Garden dressing no longer survives around rejected houses.
Source suite: 816 pass. Static audit: 36,899 buildings, 7,553 paths, 13,547 steps;
independent full-footprint clearance/road-join audit passes. Eight final native
views with railway time frozen; six retained in the village evidence folder.
The nine new tests cover ownership-aware exclusion, narrow water/rail obstacles,
reservations, road-profile sampling, stair proportions and cross-slopes, and wall
footings. All protected hashes remain unchanged. No timetable runs or release.

### Road-continuity finding to address next

Native view at 9.5 km exposes an awkward raised-road T-junction. Mapped branch
`w982280481` ends at world (2084.405, 7729.302), only 0.001724 m from the line
`w760132250`. The latter line lacks a vertex there after map simplification.
The offline height graph links only identical vertices, so a real T-junction
can acquire two unrelated approach elevations. A read-only candidate audit
found 7,251 such same-layer endpoint-to-line contacts within 2 cm among 35,355
road fragments. Results: .local/map-2026-10-24/road-junction-candidates.json.
Noding/snap-tolerant render-only road connectivity is the next priority. Keep
road source/railway data unchanged, preserve grade-separated intersections and
recheck road-profile, station access, clearance and native join evidence.

After connectivity: surface-tag-aware rural lanes, drainage and bank texture,
regional vegetation and streaming, the twelve baseline support discrepancies,
and road-projection worker overhead remain on the overnight work list.

## Third implementation checkpoint (validated)

Render-only junction noding, layer-safe connectivity and level junction areas
now fix disconnected heights at simplified T-junctions. Runtime profile corners
remain in the road mesh. Native inspection caught a cross-width step after the
centreline fix; the full-width apron fixes that. An independent triangle audit
then caught a 9 cm profile-to-ground blend seam; including original profile
boundary nodes in junction grading fixes it. Maximum final sampled difference
is 6.15 mm across 14,976 probes at 2,169 visible junctions.

Source tests 817; Python road tests 14; 32,857 profile segments; 353 raised joins
agree exactly. All 51 station access links pass. Full final static road audit:
5,428,586 triangles, 2,180 piers, 13,256 rail-crossing checks; no conflicts.
Final boundary correction touched 45 ways on 49 tiles: those were regenerated
with --tiles and merged into the unchanged verified full-route triangle set.
The final independent audit still covers every emitted triangle. Village audit
still passes 7,526 paths / 13,468 treads; 4,893 protected files unchanged.
Five final native views are retained with source fixtures and reports at
art/performance/map-2026-10-24/junctions. R45 remains live; no build prepared.

Performance: isolated 90-tile interleaved three-pass ribbon comparison, final
profiles on both variants, costs +5.7% aggregate worker time; median tile time
116.87 / 117.08 ms, identical surface counts. Selected station tiles have 12.97%
more vertices from preserving profile corners. This is not target-PC FPS.
The profile tool now installs road profiles (the earlier comparison did not).
Do not repeat these completed checks without relevant changes.

### Next priorities after junctions

1. Native 146.2 / 269.7 / 184.3 km views show too many road approaches on piers.
   Use grounded earth/retaining support on dry clear land while keeping true
   water/rail spans open and avoiding buildings. Do not lower railways to fix
   roads. Full open clearance remains essential below the deck.
2. Recover mapped surface attributes into a render-only overlay from cached
   .local/kerala-route/southern-zone-261006.osm.pbf (557,975,955 bytes). The tile
   importer intentionally dropped surface tags; road-surface-inventory.json
   confirms all retained tile roads currently say unspecified. Keep protected
   route files unchanged. Use existing PBR finishes for country paths/lanes.
3. Consider omitting collinear height-profile corners when they do not change
   the mesh shape, then recheck road-worker cost. Prior ground-ribbon projection
   overhead also remains to address. Keep any optimisation evidence honest.
4. Drainage/cut-bank texture, field edges, vegetation corridor transitions and
   twelve old rail-support discrepancies remain as previously listed.

The final junction diagnostic has three unpaired entries: one is a same-way
continuation and two are at 220.05 / 221.19 m from the line, at/beyond the
220 m scenery cutoff. These are not unconnected height profiles. Include this
boundary in the later distant-scene transition review.

## Fourth implementation checkpoint (validated)

Dry raised roads now use ground-reaching retaining walls and continuous earth
batters. Open rail/water/road spans remain on piers. Narrow/steep sites are
retained; adjacent toes meet and short soil islands are omitted. Whole support
footprints, including neighbouring tile features and OHE footings, are checked.
The OHE footprint index is generated into render-only road profiles and shared
by workers. Railway geometry and the 32,857 road-profile segment heights stay
unchanged. Existing material batches are reused.

Validation: 831 full source tests before the final OHE guard; 32 final road
tests including 15 support regressions; 14 Python geometry tests. Independent
Shapely audit passes all 19,885 supports (16,895 retained / 2,990 earth). Open
piers reduce from 2,180 to 695. The final guard only removes/narrows existing
fill: all 225 previously support-bearing tiles were regenerated and merged
with unchanged rows before the full independent clearance check. All 4,893
protected hashes match. Road surface/shoulder/paint triangles initially compare
exactly across all 12,627 rows (5,428,586 triangles); later edits concern only
supports. Seven frozen native source views retained; editor zero errors.

Isolated 90-tile / three-pass comparison measures +5.69% road generation and
mesh build time, nearly unchanged median, +3.50% road vertices, same 708 material
surfaces. Both use current shared profile lookup; not a whole-game FPS result.
Evidence: art/performance/map-2026-10-24/supports. Final audit data is
.local/map-2026-10-24/support-complete-records.jsonl and
support-final-clearance.json. Earlier failed audits are intentionally retained.
The audit tool now supports --supports-only to avoid writing millions of
unchanged top-surface triangles during support-only follow-ups.

### Next work after grounded approaches

1. Recover rural finishes into a render-only overlay. Source tags are already
   read from the cached PBF: .local/map-2026-10-24/recovered-road-tags.json and
   recover-road-tags.py. All 50,365 requested ways found; 6,717 have useful
   attributes. Source SHA-256 is recorded in that JSON. Do not re-scan merely
   to rediscover them. Promote this to a reproducible tools/maps exporter,
   retain OSM attribution and keep protected route tiles intact. Current road
   materials in geographic_world.gd can supply soil/gravel/concrete/paving.
   Ensure new finish batches preserve UV scale, clipping, Epic rebasing and
   worker sharing. Do not change track/timetable data.
2. Reduce profile-knot and terrain-projection overhead. New support surfaces
   reuse batches, but cumulative worker generation overhead needs attention.
   support-baseline-chunk.gd / support-baseline-road.gd in .local preserve the
   preceding increment; profile_road_generation.gd includes real profiles.
3. Drainage, cut-bank/field-edge finishes and vegetation corridor transitions.
4. Twelve baseline rail/terrain discrepancies now have frozen native fixtures
   at .local/map-2026-10-24/rail-support-cases.json, generated by
   prepare-rail-support-cases.gd. Inspect before deciding whether each is a
   legitimate bridge/end or needs render-only support. Do not move rails.

Do not edit scripts while a full headless suite is running: dependencies can be
cached while later test files are freshly read, producing a mixed-revision
failure. tests-support-final was superseded for this reason. The clean suite
is tests-support-verified; final focused road tests ran after the OHE metadata
was generated. No full timetable rehearsals or extracted-build gameplay tests.
R45 remains published; the fixed deadline and six actual hours still apply.

## Fifth implementation checkpoint (validated)

Rural road finishes are complete: a reproducible 250 KB OSM appearance overlay
for 6,717 source ways, shared by workers through road profiles. All 50,365 IDs
were found in the cached source PBF; no protected tile changes. Existing texture
families supply concrete, filtered staggered paving, gravel and earth. Preserve
geometry/UVs/clipping; omit paint from unpaved surfaces. Shoulder/bank tint is
lighter. Recovered tags override defaults; ordinary untagged streets stay paved.

838 source tests pass, 38 focused road tests, 17 Python tests. A final shader-only
paving contrast correction has native and six focused checks. Six final native
views and a High/Epic distant-origin rebase fixture are retained. Road-profile
gate current, all 32,857 elevations/exclusions/support-post coordinates identical,
4,893 protected files unchanged. Editor zero errors. Isolated 90-tile/three-pass
road-worker comparison: +1.13% mesh creation time, -0.0135% vertices, 0.66 extra
road batches per tile (25% road-only surfaces, not whole-world draw calls).
Evidence: art/performance/map-2026-10-24/finishes. No timetable/distribution run.

Next work:
1. Reduce collinear profile knots and redundant terrain projections. The fresh
   baseline files are .local/map-2026-10-24/finishes-baseline-{chunk,road}.gd;
   they represent 7b136ad before finishes. For the next comparison use the new
   committed source as baseline. finish-generation-profile.json has current
   samples. Profile with no other test/native jobs running.
2. Drainage: tile 0,2, w135107593/w65958901, around 2.5 km. `_stream` uses one flat
   water quad per source segment, visibly cutting coarse terrain. Repro camera
   and data are in .local/map-2026-10-24/drainage-repro.json. Add believable banks
   and continuity without moving railway surfaces or creating floating channels.
3. Low parallel road/rail overlap deserves a dedicated audit: the 143.7 km path
   fixture mostly sees the adjacent main asphalt road. Current road audit allows
   low-level crossings; distinguish those from roads running along ballast.
4. Vegetation/cut-bank transitions and twelve prepared rail-support cases remain.
   rail-support-cases.json is prepared but still not captured/reviewed.

R45 remains live. Continue the original fixed window and six actual work hours;
this checkpoint is not release completion. All fifth-pass jobs are finished at
checkpoint; no runtime/test script was edited while the full suite ran.

## Sixth implementation checkpoint (validated)

Road-worker optimisation: cached float64 terrain-plane equations, hoisted UV
setup, per-way height indices and unique endpoint indices. Do not remove flat
profile knots: bridge piers/retaining grouping depends on those subdivisions.
Against d500cfe, isolated 90 tiles x three interleaved passes: generation
49,422.664 -> 47,384.621 ms (-4.12%), including mesh finish 52,320.611 ->
50,280.776 ms (-3.90%). Both 6,881,697 vertices / 885 road material surfaces.
This is development-PC CPU mesh creation, not a target-PC frame-rate result.

841 full source tests, 17 Python tests; exact query parity on all source roads
with profiles (27,984 segments, 139,920 height probes, 27,337 split knots).
All 4,305 tiles exported: 5,428,221 actual road triangles across all finishes,
shoulders/paint; independent clearance audit passes, including 13,256 rail
crossing checks and 695 piers. 14,976 rendered junction probes pass, max
6.148 mm. All 32,857 profile elevations/exclusions/support positions unchanged;
1,800-input gate current. All 4,893 protected inputs unchanged. Three native
junction views frozen at time 0. Six scripts validate; editor zero errors.
Evidence: art/performance/map-2026-10-24/optimisation. No timetable or extracted
gameplay run; no runtime/test edits while the full suite ran.

The twelve baseline support cases are now captured and reviewed, not pending
capture. Read art/performance/map-2026-10-24/support-investigation/README.md:
KZTW bridge exit and ERS/NCJ extensions show gaps; TVC platform walls obscure
the underlying ground, so do not automatically treat them as floating rails.

Next priorities (supersede previous lists):
1. Fix canal-bank teeth at 2.5 km: source native view in
   .local/map-2026-10-24/stream-baseline-native. Current 2 m shore cells force
   every perimeter onto coarse 8 m edges, even between refined neighbours.
   Refine a shore buffer, stitch only to coarse neighbours, and share identical
   rules between terrain and GroundRibbon. Watch tile-edge continuity and
   protect track/road heights. Duplicate centreline water also overlaps mapped
   water polygons; stream-intrusions.json quantifies it. stream-cases.json and
   inspect-streams.gd are ready; do not repeat their baseline capture.
2. Repair ground beneath the confirmed bridge-end/terminal formation cases,
   without changing rail geometry. Inspect install_railway's lateral>24 filter
   and reference-alignment endpoint coverage; bridge ground/deck interpolation
   may also differ. NCJ extension includes a water overlap. Keep true bridge
   openings. Reuse all twelve prepared cases; they are already reviewed.
3. Low parallel road/rail overlap at 143.7 km needs an angle-aware audit;
   the current audit deliberately permits low-level crossings.
4. Junction shoulders visibly cross mouths at the 146.2 km native fixture.
   Clip same-level shoulders/paint against crossing road footprints while
   preserving higher/lower roads and every material kind.
5. Vegetation/cut-bank transitions and final scenery/performance checks.

R45 remains available. Original 03:30:53 start, 10:30 minimum finish and six
actual active hours still apply. Notify before preparing the eventual full
and incremental release, then validate it and pause automation at completion.

## Seventh implementation checkpoint (validated)

The 2.5 km canal bank now uses shared 2 m samples across fine cells, with
stitching only at real fine/coarse transitions. The existing coarse outer-tile
contract is preserved. A 10 m shore buffer limits detail; terrain and road
projection share the exact mesh. Centreline stream ribbons are clipped where
mapped water polygons already supply a surface, retaining uncovered lengths
and polygon holes. No mapped water elevations or railway inputs change.

849 source tests, 17 Python tests; 60 tiles / 801,774 actual edge comparisons
pass. Full 4,305-tile road export: 5,503,160 triangles, all finishes, 13,270
rail checks, 695 piers and 19,885 supports pass independent audits. Junctions:
14,976 probes, max 6.148 mm, same three one-sided cases. 32,857 profile rows,
exclusions and OHE coordinates unchanged; 1,801-input gate current. All 4,893
protected hashes unchanged. Three final native views at time zero; five
scripts validate, no editor/native errors. Evidence: shore-banks directory.

Isolated three-repeat comparisons: 60 water-heavy/dry tiles terrain/water CPU
+22.62% (25.4 ms/tile extra), vertices +15.38%; 90 road tiles generation +2.68%,
total mesh creation +2.57%, vertices +0.61%, material surfaces unchanged. A
wider 14 m prototype was rejected for higher cost. Not target-PC FPS results.

Updated next work (supersedes the sixth checkpoint list):
1. Ground-support repair. Read support-investigation/ground-diagnosis.json:
   KZTW raw height is correct, but coarse rendered triangles cross the bridge
   end and dip by about 1.94 m. Similar interpolation at NYY/AMY/TVC/TZH/OCR.
   Terminal extensions are missing from the render formation index (nearest
   rail 46–67 m away); NCJ also overlaps mapped water. Refine presentation and
   grounding without moving tracks or filling real bridge openings. ALLP
   depot access is a legitimate bridge. Existing twelve native baselines are
   reviewed; do not repeat them. Diagnostic helper remains in .local.
2. Angle-aware audit/repair of low parallel road overlap around 143.7 km.
3. Clip junction shoulders/paint from same-level road mouths (146.2 km and
   184.3 km), preserving grade separation and every road material kind.
4. Vegetation/cut-bank transitions and final scenery/performance validation.

R45 remains live; no build prepared. Keep fixed start 03:30:53, minimum 10:30
and six actual active hours. No full timetable runs or extracted gameplay;
no runtime/test edits during the full suite. All seventh validation jobs have
completed. Continue useful implementation toward the original deadline.

## Eighth implementation checkpoint

Actual terminal running roads and precise segments near bridge ends now enter
the render ground index. This fixes incorrect reference projections such as
QLN P4's outer shoulder being classified inside a bridge it had already left.
Water carving respects the actual non-bridge formation. Small fine terrain
patches and grounded landward abutments close the sampled bridge-end gaps.
Road-footprint/gradient guards omit supports that would obstruct lower roads;
adjacent bridge openings are clipped out. No railway geometry moved.

26,778 centre/shoulder probes: 271 improved, none worsened, no remaining
exposure beyond tolerance. 216 actual support footprints / 43 road overlaps
pass the independent audit. Full road audit: 4,305 tiles, 5,545,611 triangles,
13,563 rail checks, 696 piers, 19,922 supports, 14,976 junction probes pass.
All 4,893 protected files unchanged. Ground correction regenerates 32,863
render-only road profile segments (43 ways changed); 1,802-input gate current.
860 full source tests passed, then 12 final formation tests after tightening
the last footprint gradient check; 17 Python tests. Eight scripts validate.

Internal terrain edges pass on 136 transition tiles (2,523,448 comparisons
including the border probes, max internal error 0.000002 m). The stricter
cross-tile check discovered 63 existing waterway border cases, worst 6.988 m.
17,680 before/after border probes show no new regressions. The cause probe
shows missing neighbouring shore context: at (1024,2448), one tile has no
nearby shore segments and stays at 8.5 m; its neighbour sees the real shore
2.31 m away and grades to 1.512 m. These are not changes to railway elevation.
Exact twelve worst cases: .local/map-2026-10-24/border-causes.json.

Isolated interleaved generation: 71 tiles x3, +28.90% terrain/water worker CPU,
+5.44% vertices, roughly 70.8 ms extra per tested tile. Selection includes the
densest bridge patches. Actual index installs in 197 ms vs 9 ms old and is
shared by workers. This is not target GPU frame time. Review water-formation
query indexing while repairing shared bank context to contain generation cost.

Seven final frozen native views were reviewed. Native QLN additionally exposes
a shader-instance-buffer overflow, reproduced by a fresh single-location run.
`.local/map-2026-10-24/qln-uniform-probe/uniform-diagnostic.json` counts 4,090
extreme-detail parameters and 420 door parameters, 23,524 geometry nodes. Read
game/extreme_visuals.gd and the nine surface shaders: a global graphics option
currently occupies instance uniforms on thousands of surfaces. Investigate a
shared shader-global setting that preserves immutable cached materials, rather
than blindly increasing allocations; verify Godot's supported API first. Door
animation needs its per-instance data. Fix this before publishing. Captures
are not error-free; stderr and isolated reproduction are retained. A remaining
bridge-edge slit left of QLN's focal point is inside the bridge area, separate
from the corrected dry approach sample; inspect it before claiming all deck
support is resolved.

Next priorities (supersede earlier lists):
1. Resolve the reproduced QLN shader-instance allocation failure. All current
   diagnostic jobs have finished; reuse the fresh native case and counts.
2. Share shore/bank context across tile edges; preserve detailed-water holes,
   actual rail formations and shared road projection. Use the prepared worst
   cases and comparison, not a new baseline. Optimise the bounded queries.
3. QLN bridge-edge slit, low parallel road overlap 143.7 km, and junction
   shoulders crossing same-level road mouths. Keep every material audited.
4. Vegetation/cut-bank transitions and final native/performance checks.

Evidence: art/performance/map-2026-10-24/formation-support. R45 remains live;
no build prepared. Continue the fixed window and six actual hours, notify
before the eventual full/incremental release. No full timetable or extracted
gameplay run. No runtime/test edits while the full suite ran; an earlier
incomplete suite/export was stopped before fixing the QLN reference case.

## Ninth implementation checkpoint (validated)

QLN shader-instance overflow is fixed. Nine world surface shaders use one
project-declared global detail value rather than allocating identical parameters
on 4,090 geometry instances. The main thread changes the global only when the
preference changes; immutable cache materials and the 420 per-instance door
parameters remain untouched. The renderer buffer is unchanged. API verified
through live ClassDB and official Godot docs; project setting applied via MCP.

861 full source tests pass, clean stderr; three scripts validate, editor zero
errors, all 4,893 protected hashes unchanged. Fresh QLN High/Epic/High GPU probe
reads 0/1/0, 23,524 geometry nodes, zero extreme-detail instance allocations,
420 door parameters and clean renderer stderr. The 51-frame source-material
fixture includes day/dusk/night and six rebase views: 14/15 High restorations
pixel-identical, remaining daylight overview mean RGB error 0.003/255. Small
rebase differences are retained, not claimed absent. Evidence: surface-globals.

Next priorities remain shared bounded shoreline context (border-causes.json),
water-formation query cost, QLN bridge-edge slit, parallel road overlap143.7km,
same-level junction shoulders and vegetation transitions. No railway or terrain
geometry changed in this ninth increment; completed geometry audits remain
applicable. R45 stays live, no build prepared. Original fixed time and six actual
active hours continue. Playtest High/Epic toggles at QLN and streaming/doors after
release. No full timetable runs, extracted gameplay or source edits during tests.

## Tenth implementation checkpoint (validated)

A worker-owned 64-tile cache shares real shore segments within a 10 m halo.
Clipped tile perimeter edges remain excluded, polygon holes retained, and
border water classification uses the same source-local rings. Surface water
still renders only in its owning tile. Refresh cache hits so later neighbour
loads cannot evict earlier participants before border classification is built.

All 4,305 tiles / 7,918 borders / 514,670 samples pass at 1 mm tolerance; max
0.000063 m (old sampled worst 6.988 m). Internal/fine transitions:136 tiles,
2,528,740 comparisons pass. Actual rail-ground audit still 26,778 samples,
271 improved against pre-formation baseline, zero worsened/remaining exposures.
Full road export 5,547,232 triangles/all finishes and696 piers passes;19,922
supports and14,976 junction probes pass,max6.148mm,same3one-sided cases.868full
source tests,then16focused shore tests after final cache-retention guard;17Python.
The full boundary/road audits preceded that cache-only guard; its new regression
covers the exact cache-history defect. No runtime/tests edited during full suite.

Final isolated71tiles x3:67296.623->54534.765ms (-18.96%) terrain/water generation,
7993287->8002737vertices (+0.12%). Avoid redundant second rail queries away from
banks; actual-formation bins64m instead128m retain their27m support envelope.
Both interleaved runs improve CPU18–19%; not target4090Laptop FPS evidence.
Road profiles regenerated:32863 rows/exclusions/OHE positions identical, only
input hashes change; new shore-context source is in the build gate.4893 protected
inputs unchanged. Two frozen nativebank views4.1/129.1km reviewed, clean stderr.
Evidence:art/performance/map-2026-10-24/shared-banks. Large ignored raw triangles
remain in bank-road-triangles.jsonl for reuse in future bounded road corrections.

Next priorities (supersede earlier lists):
1. QLN bridge deck is now specifically diagnosed. Interval140725.726–140740.141m
   has ownerQLN_LADDER_LU5. Other platform roads at a common chainage have large
   longitudinal offsets. A single perpendicular width projected onto the owner's
   diverging tangent does not cover them. Only14/45 QLN_P4 centre/±3.8m shoulder
   samples are supported by current two slabs. Read committed next-qln-deck-*
   evidence and .local/map-2026-10-24/probe-qln-deck-coverage.gd. Correct slabs
   using actual road positions; keep true bridge openings and every rail fixed.
   The earlier ground audit samples approaches; it does not validate deck spans.
2. Low parallel road overlap143.7km. Existing road_reservations permits all
   near-railhead ribbons as crossings; it currently ignores approach angle.
   Investigate orientation-aware treatment while preserving real crossings,
   underpasses/flyovers and all road finishes. Existing exact native case ready.
3. Clip shoulder/paint strips from same-level junction mouths (146.2/184.3km).
   Preserve distinct elevations and connected main carriageway surfaces.
4. Vegetation/cut-bank transitions and final native/performance checks.

R45 remains live; no build prepared. The fixed03:30:53 start,minimum10:30finish
and six actual active hours continue. Do not duplicate completed captures or
full road audits without relevant changes; no full timetables/extracted gameplay.
Playtest canal banks4.1km/backwaters129.1km and adjoining roads after release.

## Eleventh checkpoint — actual bridge footprints

Shared chainage is not a shared perpendicular cross-section in a station yard.
The old Kollam deck followed QLN_LADDER_LU5 and missed neighbouring QLN_P4.
Each track now supplies its real footprint. Stable ownership clips overlapping
slab area, mitered corners close curve joints, and guardrails clear actual rails.
Piers follow actual centre lines and clear the full road plus its 65 cm shoulder.
Existing landward abutments, water openings and every railway input are unchanged.

- All 115 bridge spans: 17,463 centre/shoulder probes, zero unsupported or height
  failures. Baseline 66b1efa had 1,250 unsupported probes. Independent Shapely
  audit uses actual emitted top triangles, not the planning polygons.
- 11,197 top triangles, no degenerates. Overlapping top area totals 0.00235 m²
  across the route, versus 1,272.7 m² in the previous shared beams.
- 2,679 horizontal guard beams: minimum continuous rail clearance 3.268 m.
  All 416 emitted piers checked against the existing actual road-triangle export;
  zero conflicts. First audit caught shoulders outside the centre-road envelope;
  the final guard and regression cover this.
- 875 full source tests, then 7 focused bridge tests after the final shoulder
  guard and mesh reduction. Four scripts validate in Godot MCP; editor errors 0.
- Five frozen native source views, including the exact QLN reproduction and
  four regional bridge views. Clean stderr; railway time remains zero.
- All 4,893 protected railway/prepared files remain byte-identical. R45 stays live.

Geometry cost is higher because the old shared deck omitted actual track areas.
Isolated 207 whole-edge generation/mesh jobs x3: 745.896 -> 2200.329 ms
in total; 288,648 -> 721,734 vertices across the whole route. The first correct
version had 1,437,192 vertices; removing internal walls and giving guard beams
their own cadence halved that. This measures creation, not per-frame GPU cost or
target RTX 4090 Laptop FPS. Only nearby chunks are loaded. No timetable run.

Reproduce with tools/audit_bridge_decks.gd and tools/maps/audit_bridge_decks.py.
The independent clearance reproduction reuses the ignored bank-road-triangles
export, whose five road finishes were already independently audited. Baseline
script is the geographic_bridges.gd file from 66b1efa. Profile reproduction uses
that saved baseline. Native cases run through tools/capture_village_access.gd.

After release: inspect QLN near 140.73 km from both sides, then the regional
backwater bridges; rails and shoulders should have solid decks, with no railings
across running tracks or piers through adjacent roads.

Remaining visual observation: the wide bank views reveal conspicuous flat
terrain normals/triangular shading. Assess smooth shared vertex normals without
moving tested terrain vertices; preserve the bank/tile topology and clearance.

Next priority: actual parallel road w1024795790 at 143.7 km is 3.09 m from
QLN_DEPOT_RD_LEAD and only 3.56 degrees from parallel. Current near-railhead
reservation exceptions mistake it for an at-grade crossing: 158 road triangles
and 120 shoulders overlap, about 0.08–0.11 m below the rail. Preserve legitimate
crossings (the neighbouring w1558296525 footway is about 86 degrees), true
underpasses/flyovers and all finishes. Then same-level junction shoulder clipping,
smooth terrain shading and vegetation transitions. Do not rerun unchanged full
road audits for bridge-only work; only new pier/road intersections were checked.

## Twelfth checkpoint — road mouths and low parallel roads

The 143.7 km parallel-road intrusion is fixed. Low parallel ribbons and their
actual draped edges stay clear of the railway; legitimate crossing mouths remain
connected. Same-level shoulders/paint yield at other carriageways. Five initially
severed road mouths were repaired and the final junction audit matches the
baseline 2,169 pairs / 14,976 probes / 6.148 mm worst height difference.

887 full source tests and 51 final road tests pass, plus 23 Python tests.
Full 4,305-tile mesh audit: 5,474,690 triangles, all five road finishes, 696 piers,
19,922 supports. Independent parallel audit: 48,229 near-level intersections,
1,788 verified crossing-mouth fragments, zero unresolved conflicts. Audit false
positives at bent crossroads and beyond track endpoints were investigated using
actual meshes; rejection tests still catch long parallel roads and high flyovers
that must not exempt low roads. Native views at 143.7/146.2/184.3 km are clean.

Isolated 90-tile x3 road-generation cost rises 26.07% (14,568.815 to 18,367.173 ms),
indexed vertices fall 2.02%. This is streaming CPU cost, not GPU FPS. All 32,863
road-profile rows/exclusions/OHE positions and 4,893 protected inputs are unchanged.
Evidence and playtest steps: art/performance/map-2026-10-24/road-junctions.

### Work already underway after the road checkpoint

Smooth terrain normals use a temporary per-build helper (an initial owner/callable
cycle was caught in native cleanup and fixed; a lifetime regression test passes).
Vegetation now seats on actual refined terrain triangles and excludes mapped wet
footprints. The 24-tile baseline found 197 root errors >10 cm, max1.861 m, and8 wet
plants; the corrected audit has zero >10 cm errors, max0.0000038 m and no wet plants.
The final full source suite completed in normal2-tests.log: 896 passes, clean stderr.
Native final views complete without cleanup errors.
A 71-tile geometry comparison shows identical positions; four previously reversed
fine-bank triangles at tile6_107 now have consistent upward winding. Complete the
isolated x3 terrain profile is complete: generation +7.33%, indexed vertices
-67.33%, no position changes or invalid normals. Road input hashes refreshed with
identical profiles, all 4,893 protected files unchanged. Evidence:
art/performance/map-2026-10-24/terrain-planting. Both time minimums are now met.

The new close southern views reveal another real baseline defect to address
before release: pond a1522434304 near230.55 km has water51.5 m while nearby dry
formation ground is46.84 m at31.74 m from a46.99 m track. Current bank grading only
lowers high land and refuses to operate within32 m of rail, leaving a floating
water edge. Exact captures and numerical samples: ground-before-native and
southern-bank-gaps.json in .local/map-2026-10-24. Do not move railway or change the
prepared map. Investigate a render-only dry-bank rise toward the water outside
the protected formation, with a gradual rail-clearance fade; retain the existing
lowering safeguards. Validate road support, station envelopes, track-ground
support and tile seams if terrain heights change. Do not claim this is fixed by
smoothing normals alone. Fixed10:30 minimum and six-active-hour accounting remain;
no build has been prepared. Continue beyond10:30 if validation needs it.
