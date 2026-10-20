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

## R39 — Roads, bridges and electrification

The road renderer now clips whole road ribbons, shoulders and markings against
the actual station buildings, forecourts, platforms and open water. Ground roads
may meet the rail head at a level crossing; inconsistent fragments in the space
occupied by trains and overhead equipment are omitted. Mapped station stairs,
platform paths and underground roads no longer become generic asphalt ramps.
The operating railway and CSV platform inventory are unchanged.
Mapped pedestrian bridge ways inside station compounds are excluded from the
generic road pass, preventing duplicate elevated asphalt paths over the
modelled station footbridges. Public road bridges retain their decks and
connected approaches.

Bridge decks have undersides, coping, rails and piers. Connected approach grades
extend beyond the original OSM bridge tag where the reconstructed yard is wider.
Clearance uses the actual running/depot tracks and overhead support spans.
Water-side deck corners are checked as well as the centreline. High approaches
use open supports instead of retaining walls across tracks; lower approaches
have retaining faces meeting the ground. Piers avoid running tracks, platforms
and mapped roads beneath them.

Raised junctions leave openings in the coping and guardrails where another
road meets at the same height. Crossing roads on separate levels retain their
barriers. This uses the shared road-profile grid during mesh construction.

Station entrance planning uses all completed station grading and those same road
elevations. It rejects a connection to the underside of a raised approach, an
open canal, a tunnel or a running line. Generic building footprints also reserve
mapped sidings before placement, regardless of map feature order. Public road
corridors also exclude reconstructed buildings, preventing guessed building
heights from intersecting flyovers, ramps or piers. This conservatively omits
buildings beneath roads; tunnels and narrow access paths do not exclude houses.
Yard rails use
a rougher, aged steel finish rather than the general polished-metal material.
Asphalt now has stable absolute texture coordinates and a separate edge-dust
mask, including when the world rebases.

Overhead supports and wires use a common 55 m chainage grid, including rows
shifted clear of a footbridge. Edge and streaming boundaries retain the same
wire endpoints, messenger sag and dropper positions. Registration arms meet the
contact wire and messenger; gantry outriggers connect to their crossbeam.
Unusually long cantilevers become two-legged portals. The 6.5 m switch to a portal
is a rendering design threshold, not a claim about an Indian Railways standard.
The visible contact/messenger wires remain 12 mm; an invisible 40 mm shadow
caster follows the same path to reduce gaps from shadow-map undersampling.
This does not increase global shadow resolution or view distance. Very distant
thin shadows remain limited by the selected shadow setting.

The sky panorama also uses wrapped longitude derivatives for texture filtering.
This removes the bright dashed seam found above Kollam without disabling mipmaps
or changing the time-of-day cycle.

Road elevations are a rendering reconstruction from OSM, SRTM and the game's
railway geometry, not a survey of civil engineering structures. Long untagged
road/water conflicts remain recorded for later map research; their submerged
fragments are omitted rather than inventing a large bridge. Profiles are
precomputed and shared read-only with scenery workers. Geometry remains batched
by material; no per-frame road planning or additional road traffic is introduced.

To regenerate after changing map inputs, use the portable engine to run
`tools/export_scenery_context.gd`, then run `tools/maps/road_surfaces.py` with the
existing `.local/kerala-route/python` dependencies. `node tools/verify-road-surfaces.mjs`
checks the rendered context, source hashes and tile inventory during every export.
It does not advance railway time. Focused checks are `test_road_surfaces.gd`,
`test_ohe_clearance.gd`, `tools/check_kerala_ohe.gd` and
`tools/check_station_road_connections.gd`. The full-corridor triangle audit uses
`tools/check_road_render_geometry.gd -- --all`, followed by
`tools/maps/audit_road_surfaces.py`.

Player checks for this release:

1. Visit Ernakulam, Kollam and Trivandrum in free camera. Follow entrance links
   to the surrounding streets and inspect road bridges over each yard.
2. At Kumbalam and the coastal stretches, check road edges and canal crossings;
   asphalt should not run flat across open water.
3. Look above the train near a station throat and under road bridges. Supports
   should connect to the wire, with no exceptionally long floating arms.
4. Stop in an exterior camera and inspect wire shadows on the train roof, then
   drive through a few streaming boundaries. Check the same area at night.
