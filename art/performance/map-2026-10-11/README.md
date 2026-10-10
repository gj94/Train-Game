# Corrected Kerala map evidence

Source geometry and native-render checks for the 11 October map correction.
`map-inputs.json` binds the checked layout, route, operations and service pack.
`geometry-before.json` uses the R28 geometry from `fa67882`; both diagnostics
sample at the same 5 m interval. `crossings.json` is an independent Shapely
check of all 802 actual graph roads outside their protected point areas.
`building-clearance.json` records additional roof-footprint exclusions after
station-compound and current terrain/rail-distance filters; it is not a claim
about surveyed physical buildings or a before/after count over identical yards.
`station-register-audit.json` retains all CSV discrepancies and source fields.

Seven PNGs show the native streamed route on the development Radeon 780M.
They are visual checks, not target-PC performance evidence. The final bridge
view uses an unobstructed higher viewpoint. No exported-distribution playtest.

All 533 headless tests pass; timing/log files are included. Six Python geometry
converter tests also pass. Full operating-day baseline and delayed reports will
be added after completion; old R28 reports do not validate this changed map.
