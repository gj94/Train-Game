# TUVR · Turavur | Coastal railway station reconstruction

## What is delivered
Full-scale metre scene with no trains or rolling stock. Packed Blender file, lossless portable GLB export when available, and rendered views derived from the frozen Blender scene. Current snapshot review date:2026-10-08. This is a useful visual reconstruction, not a surveyed as-built or certified operating layout.

## Station evidence and scope
- Status: Listed current by SR2025; no subsequent closure found
- IRI-reported platform faces: 2 (Reported platform positions; not independently verified current operational inventory)
- IRI source: https://indiarailinfo.com/station/map/turavur-tuvr/436
- Official chainage if supplied: 23.30 km, datum ERS via ALLP.
- Mapped roads at station transect: 3; mapped rail segments in scene: 6; combined mapped route length: 4573.0m.
- Mapped description: Three long parallel roads; outer two tagged siding but geometrically both-ended crossing loops. Short south auxiliary path and north/south trap/neck extensions also mapped. Platform footprints absent; nearby busplatform excluded.
- Source edit dates: 2018-11-04T12:25:17Z / 2025-11-24T08:40:10Z. An OSM edit timestamp is not a survey date.
- Current loops/sidings totals: NOT VERIFIED. The actual adopted OSM paths are modeled; service tags are preserved. A tag service=siding can describe a both-ended loop.
- Proposed/construction ways excluded. No extra operational running line inferred from line-doubling projects.

## Architecture source
https://www.mappls.com/place/TTFDEA_1650206030296_0.png

Additional actually inspected source records in references/architecture_evidence.json:
- https://www.mappls.com/place/TTFDEA_1650206030296_0.png

Facade color, roof type, portico rhythm and signage follow inspected photographs where available. Photo appearance may be historic. Dimensions are reconstruction estimates. Downloaded reference photos are excluded from the release; original sign artwork and materials are newly made. Google Images was traffic-blocked. Google Maps ordinary photos were usable; clicking a Street View-labelled station tile sometimes opened still photos. No actual Street View panorama is claimed unless a separate evidence entry explicitly records it.

## Platform bodies
- Body1: 1; IRI platform count; reconstructed side-platform footprints; source ways none.
- Body2: 2; IRI platform count; reconstructed side-platform footprints; source ways none.

## Dimensions and coordinate system
- Local origin: longitude 76.3102752, latitude 9.7749279 (source station locator, not a survey monument).
- Local +Y follows mapped corridor northward, using EN north-vector [-0.1784681550226385, 0.9839456883602954]; +X is perpendicular.
- Adopted mapping window: [-230.0, -1150.0, 230.0, 1150.0]m. Mapped approaches are retained throughout this window, including loop joins and sidings; clipping at the window is documented rather than fabricated continuations.
- Enclosed building envelope: approximately 12.19m across track × 33.68m along track, at [-5.388632659432361, -0.39736338022700934]. Original source footprint, if any, retained separately.
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
