# Dry-land road supports — 24 October 2026

Rendering-only approach earthworks replace open piers on clear dry land. True
spans over rail, water and lower streets stay open. Low approaches use earth
batters; confined/high approaches use retaining walls. Adjacent footings meet,
soil tapers into retaining walls, and short isolated soil pockets are omitted.
Ground contacts match the rendered terrain triangles, including refined shores.
Existing concrete and soil batches are reused; there are no new texture assets.

Whole footprints are checked against actual rails/platforms, station precincts,
mapped buildings/rails/drains/water, lower roads and overhead-line fittings.
Checks load neighbouring tile metadata only near a boundary, so a bank cannot
cover a building just across a tile edge. This is scenery reconstruction, not
surveyed road engineering or a change to railway geometry.

Final independent clearance passes 19,885 support sections on 225 tiles:
16,895 retained and 2,990 with earth batters. The complete route now has 695
open piers, versus 2,180 before this increment. All existing road-profile
heights remain unchanged; the profile gate passes and all 4,893 protected
files match. The source suite passed 831 tests before the final overhead-footing
guard; the final road suite passes 32 tests (including 15 support tests).
Fourteen Python geometry tests pass. Intermediate failed audits are retained
under .local/map-2026-10-24 for diagnosis, not presented as final results.

An initial full export matched all 5,428,586 pre-existing road surface,
shoulder and paint triangles across 12,627 road rows exactly. Subsequent edits
are confined to support geometry. Road profile segment heights remain identical.
The final support audit checks the complete route, including neighbouring map
tiles. It also checks soil slopes and avoids self-intersecting footprints.
The final overhead guard only removes or narrows existing supports, so all
225 tiles previously containing supports were regenerated and merged with the
unchanged remainder before repeating the complete independent check.

Isolated interleaved worker comparison, 90 identical tiles and three passes:
48,710.744 ms before / 51,482.586 ms after aggregate generation and mesh build
(+5.69%); median 119.739 / 120.0495 ms. Both variants have 708 material surfaces;
road mesh vertices increase 3.50%. Both use current profile lookup, excluding
its one-time construction from this comparison. This measures scenery creation
on CPU, not per-frame cost or target-PC FPS. Road-worker optimisation remains
on the work list.

Native source captures use 1440 × 900 on the development Radeon 780M, with the
railway paused at time zero and afternoon lighting. They are visual evidence,
not an RTX 4090 Laptop FPS claim. Final images cover rural earth approaches at
13.0 / 95.9 / 197.8 / 270.6 km and raised joins at 146.2 / 184.3 / 269.7 km.
The 95.9 km fixture specifically confirms that a short soil mound is replaced
with a clean retaining wall. No extracted-distribution gameplay tests were run.

Playtest after release: view those approaches from low free camera; follow a
bank into its retaining section, inspect the toe against the grass and ensure
rail/water/road underpasses and overhead footings remain clear.

R45 remains live; this increment is not the overnight release. The next pass
uses recovered OSM surface tags for rural lanes, followed by drainage, vegetation
transitions, the twelve baseline support discrepancies and road-worker cost.
