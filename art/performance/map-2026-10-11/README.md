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

All 533 headless tests, six Python geometry tests and five catalogue tests pass.
Both fresh operating-day reports pass: 100/100 services stabled, 1,530 subsequent
calls, zero safety events, finish 03:18:14 on day 2. Longest extra continuous wait
29.57 minutes; p95 final lateness 16.60 minutes, worst 33.89 minutes. See
`summary.json` and `comparison.json` for exact values and the R28 comparison.

`baseline.json` and `delay.json` preserve the original Godot JSON bytes, including
large exponents in absent-signal diagnostics. Both source digests match the
current simulation and all five hashes in `map-inputs.json` were verified.
The delayed run holds K1 until 08:10; its initial delay is absorbed at early calls,
so later traffic converges. These are full fresh runs, not resumed checkpoints.
The raw route-to-final conversion was also reproduced byte-for-byte.
