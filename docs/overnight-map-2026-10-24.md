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
