# Station surroundings and coastal vegetation

R20 rebuilds the civil setting around the preserved detailed station models.
The source architecture and CSV operating tracks/platform totals remain intact.
The surroundings are a researched reconstruction, not an as-built survey of
each station or a claim that every station has completed redevelopment.

## Reference and design

The Ministry of Railways' [Amrit Bharat station guidance, 27 December 2022](https://www.pib.gov.in/PressReleasePage.aspx?PRID=1886884&lang=2&reg=3)
calls for organised access, pedestrian paths, parking, drainage, lighting and
landscaping, scaled to station usage. It also favours boundaries that preserve
the view of the facade. These circulation principles inform the reconstructed
forecourts; this release does not implement the entire scheme.

The user's supplied fence photograph guides the precast concrete palisade:
closely spaced slats with bevelled heads, two horizontal rails, heavier posts
and streaked, weathered surfaces. The photograph is reference only; its pixels
are not distributed or used as a texture. Geometry and weathering are original.

## What changed

- A common station footprint now drives grading, foundations and scenery
  exclusion at all 56 station sites plus Ernakulam's east entrance. Ground is
  filled or cut to meet the buildings, with an outward transition to natural
  terrain. Open shelters retain their individual foundation treatment.
- Platform backs, ends and the lower track-facing strip are closed, rather
  than leaving a thin floating top and one front face.
- Entrance paving meets the building, with a protected pedestrian promenade,
  central crossing/ramp, circulation lane, marked parking, rickshaws,
  motorcycle parking, planted pockets, covered drains and lighting columns.
- Accepted entrance links connect to nearby mapped roads. The road planner
  rejects paths through mapped water/buildings and excessive slopes. Where
  the map cannot support a clear connection, it does not invent one through
  obstacles. Small through halts receive boundaries without a large car park.
- Precast fencing encloses forecourts and outer platform backs, leaving
  entrances open. Islands are not fenced across passenger circulation.
- Single-platform Kumbalam no longer gets a redundant generic footbridge.
  Other procedural footbridges have stairs connected to their deck and
  platform landings, with canopy space cleared around the stairway.
- Coastal ground cover uses instanced bent 3D grass blades, mixed-height
  weeds/shrubs and a denser mix of coconut palms and broadleaf trees.
  Exclusion follows actual simulation tracks, platforms and signal posts,
  together with mapped roads, houses and water. Cropped fields remain open.

## Rendering limits

Grass shares one 1,152-triangle mesh, uses 48 m instance cells, fades at 125 m,
and casts no expensive individual shadows. Broadleaf tree geometry changes
to the existing normal-mapped canopy impostors at 115 m; palms at 175 m.
Trees use smaller 64 m geometry batches so nearby views do not draw an entire
large district at full detail. Distant canopies remain visible to 2.7 km.
These settings bound the additional work; they are not a measured FPS promise
for another computer.

## Player checks

1. Update and open the Kerala stopping scenario. Use the dispatcher to visit
   Kumbalam, Turavur and Ernakulam; keep your current service when prompted.
2. Enter free camera (R3), move around the platform back and entrance, and
   check that platform faces/building bases meet the ground.
3. Inspect concrete fencing, gate openings, pedestrian crossing, parking and
   the mapped approach-road connections. Kumbalam should have no generic FOB.
4. At Turavur, look along the footbridge stairs and the gap in the canopy.
5. Inspect the grass at eye level beside the track and the denser canopy beyond
   the boundary. Ballast, platforms and circulation areas should remain clear.
   Move away and check the vegetation fades/transitions without large pops.
6. Visit Virani Alur to check the smaller open-shelter treatment. Existing saves
   and train/controller behaviour should continue unchanged.

## Developer checks

Run `tests/run_tests.gd` before committing. Focused regressions are also exposed
by `tools/check_station_surroundings.gd`. `tools/check_station_precincts.gd`
reports every footprint and accepted road connection. Native source screenshots
come from `tools/capture_station_surroundings.gd`, with `--tag=NAME`,
`--codes=KUMM,TUVR,ERS,VRLR` and optional `--views=forecourt,ground,platform`.
No extracted distribution launch is required for this visual iteration.
