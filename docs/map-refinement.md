# R46 countryside and map refinement

R46 improves the world around the existing railway. Track positions, service
timings, train physics and prepared journeys remain unchanged.

## What to look for

- More varied ground beside ordinary lines, with embankments and cuttings that
  blend into the existing coastal and southern elevation.
- Village access paths, steps and boundary walls grounded on the terrain.
- Connected road junctions, continuous approach heights, visible support below
  elevated approaches and rural finishes based on mapped surface tags.
- Roads beside tracks stay outside the rail corridor. Crossing mouths remain
  connected, with shoulders and paint yielding at intersecting carriageways.
- Continuous canal banks across scenery tiles, supported bridge ends and
  terminal extensions, and bridge decks following the actual running roads.
- Smooth terrain lighting and plants rooted on the rendered ground. Mapped
  water excludes vegetation roots.
- Dry pond banks rise toward the water where there is room; confined edges
  receive retaining faces. Narrow streams follow the ground instead of spanning
  uneven terrain with long flat ribbons.
- A shared graphics shader flag avoids the instance-buffer overflow found in
  detailed Kollam views. Passenger-door parameters remain independent.

## Suggested drive

1. Start K1 at Ernakulam. Inspect the canal banks and roads between Ernakulam,
   Kumbalam and the next stops, including around 2.5–4.1 km and 11.5 km.
2. Around Kollam, inspect the bridge decks at 140.7 km and the road parallel to
   the depot lead at 143.7 km. Roads should remain clear of the rails.
3. Inspect road approaches and junctions around 146.2, 169.7 and 184.3 km.
4. On the southern route, inspect vegetation roots, pond banks and drainage
   around 220.8 and 230.6 km from a carriage or low external view.
5. Switch High → Epic → High around Kollam and continue driving. Detailed
   scenery should remain visible without renderer errors.

## Scope and performance

This is a reconstruction from the existing mapped footprints and elevation,
not a surveyed model of every property. Some junction texture overlaps and
abrupt mapped water/terrain transitions can remain. The changes substantially
improve consistency but do not establish photorealism everywhere.

The development PC has a Radeon 780M; the playing PC is an i9-13980HX with an
RTX 4090 Laptop GPU, 16 GB VRAM and 64 GB RAM. Recorded generation timings are
CPU streaming measurements and must not be read as FPS on the playing PC.
The new geometry is batched and uses bounded worker caches; some more accurate
road/water projections add generation work. Use the game's benchmark to compare
frame times on the playing PC at the same resolution and graphics preset.

Full downloads and incremental updates are both available through the LAN site
and Update & Play v4.
