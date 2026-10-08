# TVC full-station environment v02

A full metre-scale Thiruvananthapuram Central visual reconstruction, without trains or rolling stock. This revision expands the former small heritage/canopy study into a complete mapped rail campus with furnished interiors and operational detail.

## Accuracy boundary
- Heritage entrance: photo-derived from November 2022, with three distinctive central upper arches and individually modelled dressed granite, shutters, cornices and veranda details.
- Railway XY: mixed-date OpenStreetMap geometry retrieved 8 October 2026. Three mapped platform bodies serve five faces. Forty-six railway ways include mainline approaches, crossovers, sidings and the distinctive coaching/service fan. Approximately 16.56 km of rendered route centreline lies in the 1.64 km-long scene envelope; this is the sum across many parallel tracks, NOT station length.
- Full platform outlines span roughly 478 m, 579 m and 582 m along their local X extents. Tapers and asymmetric positions are preserved. No compact preview scaling.
- Missing room plans, heights, structural details, exact track hardware, shelter bays, signals and service-building siting are reconstructed. No source supplies a measured floorplan or complete point-engineering design. This is not a survey, railway simulation safety model or as-built engineering deliverable.
- Architectural era remains pre-redevelopment; no proposed terminal blocks are blended into the historic scene.

## Scene contents
- Traversable heritage entrance and back arcade to Platform 1.
- Furnished waiting lounge, booking/reservation hall with individual grilled counters, queue guides, token machine and back-office equipment; station office with filing cabinets; pantry; actual toilet cubicles, taps, sinks, cisterns and mirrors.
- Clocks, fans, fluorescent lights, conduits, switchboxes, fire equipment, notices, AC grilles, varied floor tiles and skirting.
- Full platform canopies with built-up columns, brackets, trusses, purlins, corrugations, gutters, lights, coach displays, benches, bins, water coolers, stocked refreshment kiosks and original trilingual signs.
- Two covered footbridges with six usable stair flights and openings in both barriers and shelter roofs. Entry and platform-end ramps.
- Unioned foot/web/head rail profiles, 1.676 m nominal clear gauge, genuine 45 mm flangeway cuts, tapered editable tongue regions, frog noses, opposite checkrails, turnout bearers, clips and pads, point machines and true-dead-end buffer stops.
- Mapped mainline/yard connectivity uses every intermediate node, not merely way endpoints. All 50 junctions are recognised; crop-boundary tracks receive no false buffer stops.
- Rail-clear OHE portals, following contact/messenger wires and droppers, porcelain insulators, visual signal equipment, cable troughs and drains, map-following maintenance utilities.
- Forecourt, marked autorickshaw bays and editable auto vehicles, kerbs, lamps, railings, tropical trees and mapped secondary urban building massing. No trains.

## Rebuild
1. Keep `source/TVC_heritage_source.blend`, `source/mapped_geometry.json`, `source/running_rails_mesh.json`, `source/turnout_review_target.json` and `textures/` together.
2. Run `/usr/bin/blender -b -t 4 --python scripts/build_full_tvc.py`.
3. Run `/usr/bin/blender -b TVC_full_station_v02.blend -t 4 --python scripts/render_review.py -- 04_Booking_hall` to render a particular named review camera.
4. To regenerate unioned rail geometry, install Shapely 2.2 and Matplotlib in ordinary Python and run `scripts/prepare_running_rails.py`. Generated geometry is supplied; Blender itself needs no Python add-on.
5. `draw_coverage_plan.py` regenerates the labelled plan and track register from the mapped source. `prepare_map.py` is the optional raw-OSM extraction step, requiring the raw research XML that is not part of the asset-only package.

The blend is the authoritative editable version. Semantic collections and repeated-component mesh names preserve editability while batching thousands of small parts efficiently. `80_LIFT_OFF_ROOFS_AND_CEILINGS` can be hidden for interior inspection. All texture images and non-built-in fonts are packed. Cycles denoising is disabled for this environment; renders are actual Blender output. Use only one heavy Blender render/export process at a time in a memory-limited workspace.

## Review and verification
`MODELLING_PLAN.md` contains the evidence ledger and important decisions. `TRACK_REGISTER.csv` maps R01–R46 review labels to OSM way IDs and classes; these are NOT operational road numbers. `TVC_track_coverage_plan.pdf` and `renders/00_Labelled_yard_coverage.png` show whole-site coverage. `BUILD_QA.json` is generated from the saved scene. Final visual/geometry review is documented in `FINAL_QA.md`. All 24 modular GLBs are validated and reimport-tested; see `EXCHANGE_QA.json` and `EXCHANGE_REIMPORT_QA.json`.

## Rights and attribution
Geographic extract and derived mapping data: © OpenStreetMap contributors, Open Database Licence 1.0. https://www.openstreetmap.org/copyright . The source extract carries embedded attribution. Do not remove it when redistributing map-derived data. Its ODbL terms do not grant a new blanket licence to unrelated authored geometry or scripts.

Reference photographs were inspected, not applied as textures. Raw research photographs are excluded from asset-only publication. Photograph sources/licences are listed in `MODELLING_PLAN.md` and the previous heritage documentation. Original trilingual label graphics use the bundled font notices under `licenses/`. No new open-source or Creative Commons licence is granted for authored geometry, code or renders; the existing project default remains unchanged.
