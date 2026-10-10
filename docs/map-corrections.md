# Kerala railway geometry correction

This update addresses buildings over operating tracks at Kollam and TVC,
reversed running-line sides at station boundaries, and angular track curves.
It uses the same geographic route and user-authoritative 56-station CSV.
Pointwork and platform-to-road assignments remain a reconstruction, not a
surveyed station working diagram.

## Geometry

- Apply 40 m Gaussian smoothing in plan with a 300 m endpoint taper. Maximum
  horizontal correction is 4.908 m. Preserve source elevations, original chainage,
  station references, bridges and route endpoints.
- Evaluate horizontal position and its normal continuously with cubic Hermite
  interpolation. Sample the actual train/rail graph every 2.5 m. Extrapolate
  linearly only at route buffer ends.
- Keep D/U roads consistently separated through double-line sections. Southern
  Railway General Rule 4.06 specifies left-hand running on double lines:
  [official operating rules](https://indianrailways.gov.in/railwayboard/uploads/directorate/safety/SR_SR/SR_SR_CHAP4.pdf).
  The data fix keeps existing single/double section designations.
- Give successive ladder turnouts at least 100 m, increasing their length with
  lateral displacement and a 250 m reconstruction radius target. Extend yards
  so their innermost roads retain at least 1,040 m; retain the 640 m passenger
  platform limit and full-rake clearances.
- Route depot leads outward and put outer stabling roads first in the fan.
  No new unsignalled geometric crossing is accepted outside protected points.
- Keep logical road IDs and every CSV platform total. Two MQU faces are assigned
  to its running roads for access in both directions; official numbering remains
  unresolved. Legacy 32-service origins that share a road queue outside the
  railway instead of overlapping active trains.

## Scenery and foundations

Mapped buildings are checked as complete roof envelopes against every actual
track, platform and signal, including outer yards. The check includes polygons
surrounding a whole track and edges crossing a rail with all corners far away.
Existing station-compound and route-distance filters still apply.

Terrain indexing follows outer station roads and extended ladders. Main-route
height samples are 25 m apart, and workers share immutable railway indices.
The formation has a sloped soil edge reaching into terrain; bridge decks retain
their separate construction and water clearance. The sampled QLN/TVC ground
mismatch is below 0.115 m, against a 0.15 m check.

## Validation

The equal-distance diagnostic samples bends at 5 m in both R28 and this update.
The maximum changes from 19.656 degrees to 2.850 degrees, including depot roads;
1,083 measured outer-offset discontinuities over 3 cm become zero. All 802
resulting graph roads have positive length. The independent Shapely audit finds
zero unprotected centreline intersections. All 56 CSV station entries match.

Source-scene captures review QLN/TVC yards, TVC double-line approach, and the
curves near QLN, NEM and BRAM. These are native Godot renders on the development
Radeon 780M, not performance measurements on the target RTX 4090 Laptop.

All **533 headless tests**, six Python converter tests and five download-catalogue
checks pass. Both fresh baseline/+600 s operating-day audits pass on this map:
**100/100 services in depot, 1,530 subsequent calls, zero safety events**, finishing
at **03:18:14 on day 2**. Peak active passenger workings: 23. The longest extra
continuous wait is 29.57 minutes (K1), below the unchanged 30-minute quality limit;
p95 final delay is 16.60 minutes, worst 33.89 minutes (B015), median 1.85 minutes.

Against R28, the longest wait rises from 28.17 to 29.57 minutes; p95 final delay
falls from 17.58 to 16.60 minutes. Longer reconstructed station approaches change
travel times, so this is not a claim of identical timings. No departure slots or
calling patterns were retimed to obtain a pass. The ten-minute initial K1 delay
is absorbed at early calls and later traffic converges. Raw reports, map hashes,
comparison and visual evidence are in
[`map-2026-10-11`](../art/performance/map-2026-10-11/).

## Compatibility and playtest

The geometry signature changes. Start a fresh Kerala scenario or import the
new matching service pack; R28 saves and timetable files cannot be restored on
this map. Rejection happens before replacing the current railway state.
The roster remains 100 services, including both full-route Vande Bharats.

1. In Dispatch, select QLN then Visit Yard. Follow the platforms and each end
   of the yard; buildings should stay clear of operating tracks.
2. Repeat at TVC and inspect its northern approach: two running lines remain
   distinct. Inspect the southern throat and depot leads as well.
3. Ride through NEM and BRAM, looking along the rails from pilot/head-out views.
   Curves should turn continuously without sideways jumps.
4. Start K1 with AI, or drive late, and use Skip to Time to inspect later traffic.
   Confirm opposing trains cross, priority trains overtake and completed workings
   clear to depot. Inspect B001/B012 in Dispatch for their full-route calls.

## Reproduce

Run the existing raw-map pipeline and CSV application before the final geometry
postprocessor. Do not reapply original CSV offsets to normalized operations.

```powershell
python tools/maps/rail_geometry.py --source data/routes/kerala_coast --output data/routes/kerala_coast --dependencies .local/kerala-route/python
python tools/maps/test_rail_geometry.py
godot --headless --path . --script res://tests/run_tests.gd
godot --headless --path . --script res://tools/check_route_geometry.gd -- --output=.local/map-geometry
python tools/maps/check_rail_clearance.py .local/map-geometry-graph.json --output .local/map-crossings.json
godot --headless --path . --script res://tools/check_station_clearance.gd
godot --headless --path . --script res://tools/check_busy_timetable.gd -- --output=.local/map-baseline.json
godot --headless --path . --script res://tools/check_busy_timetable.gd -- --delay=600 --output=.local/map-delayed.json
```

Use the installed engine/Python paths in `pc-setup.md`. For a visual check,
attach `tools/review_route_geometry.gd` to a temporary Node scene in the editor
and run it; captures go to `.local/map-visual-*.png`. No distribution gameplay
test is required.
