# Village access and grounded compound walls

Rendering-only reconstruction around mapped, actually rendered buildings.
No surveyed private driveway/step/property-boundary positions are claimed.
All 4,893 protected railway/simulation/prepared-data hashes remain unchanged.

The source suite passes 816 tests, including nine new regressions for complete
path clearance, joins to engineered roads, stair proportions and sloping walls.
The static route audit finds 7,553 paths with 13,547 steps across 598 tiles;
independent Shapely checks find no building/water/rail/platform conflicts or
missed road joins. Road-edge checks allow an endpoint inside the road at a bend.
They reject gaps, rather than requiring a precise offset from a straight line.

Native source captures use the Radeon 780M development PC, Forward+, 1440x900,
15:00 sun and railway time frozen at zero. `report.json` contains scene counters,
not an isolated frame-time benchmark or an RTX 4090 Laptop result. Four house
fronts and four wall views were captured; six representative images are saved.
Road joins around Kumbalam still need the next connectivity pass: the background
raised junction visible in the 9.5 km view is not claimed fixed here.

Reproduce static placement with `tools/audit_village_access.gd`, then run
`tools/maps/check_village_access.py`. The audit never advances railway time.
For native views use `tools/capture_village_access.gd -- --cases=res://art/performance/map-2026-10-24/village/village-cases.json`.
Use `wall-cases.json` for close wall views. Scripts accept `--output=` to keep
new results separate from the retained evidence.
