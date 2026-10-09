# AMPA · Ambalappuzha | Coastal railway station reconstruction

## What is delivered
Full-scale metre scene with no trains or rolling stock. Packed Blender file, lossless portable GLB export when available, and rendered views derived from the frozen Blender scene. Current snapshot review date:2026-10-08. This is a useful visual reconstruction, not a surveyed as-built or certified operating layout.

## Station evidence and scope
- Status: Listed current by SR2025; no subsequent closure found
- IRI-reported platform faces: 3 (Reported platform positions; not independently verified current operational inventory)
- IRI source: https://indiarailinfo.com/station/map/ambalappuzha-ampa/55
- Official chainage if supplied: 69.16 km, datum ERS via ALLP.
- Mapped roads at station transect: 4; mapped rail segments in scene: 10; combined mapped route length: 6941.2m.
- Mapped description: One west-side body and one islandbody imply3 track-adjacent faces. Four parallel roads through yard including outer east-side serviceyard road; additional west-side dead-end goods/yard spur and north/south trap/neck ends. North single-line and south double-line geometries visible, but no official turnout chainage established.
- Source edit dates: 2018-11-04T15:21:43Z / 2025-12-27T10:26:09Z. An OSM edit timestamp is not a survey date.
- Current loops/sidings totals: NOT VERIFIED. The actual adopted OSM paths are modeled; service tags are preserved. A tag service=siding can describe a both-ended loop.
- Proposed/construction ways excluded. No extra operational running line inferred from line-doubling projects.

## Architecture source
https://pakkalokal.biz/frontend/web/upload/logo/Railway%20Station%20-%20Ambalapuzha-logo-20240305083620.jpeg

Facade color, roof type, portico rhythm and signage follow inspected photographs where available. Photo appearance may be historic. Dimensions are reconstruction estimates. Downloaded reference photos are excluded from the release; original sign artwork and materials are newly made. Google Images was traffic-blocked. Google Maps ordinary photos were usable; clicking a Street View-labelled station tile sometimes opened still photos. No actual Street View panorama is claimed unless a separate evidence entry explicitly records it.

## Platform bodies
- Body1: numbering inferred; OSM area footprint; source ways ['1034621341'].
- Body2: numbering inferred; OSM area footprint; source ways ['1034621340'].

## Dimensions and coordinate system
- Local origin: longitude 76.3627219, latitude 9.3862866 (source station locator, not a survey monument).
- Local +Y follows mapped corridor northward, using EN north-vector [-0.9818642820174028, 0.18958515685161123]; +X is perpendicular.
- Adopted mapping window: [-230.0, -1150.0, 230.0, 1150.0]m. Mapped approaches are retained throughout this window, including loop joins and sidings; clipping at the window is documented rather than fabricated continuations.
- Enclosed building envelope in the mapped scene: approximately 15.67m across track × 70.64m along track, at [-6.984294619298929, -12.299261299968114]. Original source footprint, if any, retained separately. For TNU this0m corridor envelope deliberately excludes the separate unplaced historical15.5×6.8×4.78m building study.
- Track gauge:1.676m. Railhead centers±0.868m, tread width60mm. Visual wheel-flange channels45mm.
- Rail top0.635m, platform top1.45m, contact wire6.30m. These are plausible reconstructed model dimensions, not certified construction tolerances.

## Reconstructed elements and limits
Unseen rooms, interior partitions, furniture placement, ticket-office equipment, toilets, fans, lamps, drainage fittings, roof supports, accessibility ramp, canopy/footbridge positions, signal positions, electrical equipment and vegetation are reconstructed. Small halts receive compact rooms and modest amenities; no large concourse is invented. Interiors are furnished for inspectability, without claiming access to private operational areas. All geometry is editable.

Station-specific cautions:
- Source roof/building envelope partly overlaps platform. Enclosed hall shifted outside platform by geometric clearance; source footprint retained unchanged. Not a surveyed correction.

## QA and lineage
QA_BUILD.json records scene counts, source-plan checksum, packed resources and the Blender checksum. Each render has a paired JSON with camera, source checksum and render settings. Manifest hashes identify the exact released files. Independent QA status is supplied separately; a successful render alone is not a blanket accuracy certification. Source railway-plan data and architecture estimates are intentionally distinguished.

## Attribution
Railway map data © OpenStreetMap contributors, ODbL1.0: https://www.openstreetmap.org/copyright . The derived source plan is retained in references/plan.json. Station metadata cites India Rail Info and the source register. Photographs remain with their owners and are linked as research references, not redistributed. Original models, textures and signage generated for this project. Noto fonts are used for original raster lettering under SIL Open Font License; no font binary is bundled.
