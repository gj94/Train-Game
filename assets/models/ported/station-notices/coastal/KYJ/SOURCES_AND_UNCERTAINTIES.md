# KYJ · Kayamkulam Junction | Coastal railway station reconstruction

## What is delivered
Full-scale metre scene with no trains or rolling stock. Packed Blender file, complete portable GLB geometry export when available, and rendered views derived from the frozen Blender scene. The Blender file is authoritative for procedural materials; GLB embeds original sign textures and uses PBR approximations for procedural surface noise. A lossless GLB transport archive restores the exact verified GLB bytes, not arbitrary Blender shader nodes. Current snapshot review date:2026-10-08. This is a useful visual reconstruction, not a surveyed as-built or certified operating layout.

## Station evidence and scope
- Status: Listed current by SR2025; no subsequent closure found
- IRI-reported platform faces: 5 (Reported platform positions; not independently verified current operational inventory)
- IRI source: https://m.indiarailinfo.com/station/map/57
- Official chainage if supplied: 100.34 km, datum ERS via ALLP.
- Mapped roads at station transect: 6; mapped rail segments in scene: 29; combined mapped route length: 12259.9m.
- Mapped description: Three bodies: western sidebody plus two islandbodies gives5 adjacentfaces. Middle island refs2;3 and eastern4;5; western side body wrongly repeats2;3 rather than1, so numbering is unresolved there. Six parallel station roads; one outsideeastisland has no platform face. Numerous throat crossovers/neck extensions not extra long roads.
- Source edit dates: 2018-08-23T10:48:27Z / 2026-07-09T15:19:18Z. An OSM edit timestamp is not a survey date.
- Current loops/sidings totals: NOT VERIFIED. The actual adopted OSM paths are modeled; service tags are preserved. A tag service=siding can describe a both-ended loop.
- Proposed/construction ways excluded. No extra operational running line inferred from line-doubling projects.

## Architecture source
https://graphon.in/wp-content/uploads/2023/12/advertising-boards-at-Kayamkulam-railway-station.jpg

Facade color, roof type, portico rhythm and signage follow inspected photographs where available. Photo appearance may be historic. Dimensions are reconstruction estimates. Downloaded reference photos are excluded from the release; original sign artwork and materials are newly made. Google Images was traffic-blocked. Google Maps ordinary photos were usable; clicking a Street View-labelled station tile sometimes opened still photos. No actual Street View panorama is claimed unless a separate evidence entry explicitly records it.

## Platform bodies
- Body1: 2;3; OSM area footprint; source ways ['827854368'].
- Body2: 1 (OSM incorrectly repeats2;3; IRI-led face numbering inferred); OSM area footprint; source ways ['827854369'].
- Body3: 4;5; OSM area footprint; source ways ['273481410'].

## Dimensions and coordinate system
- Local origin: longitude 76.5121004, latitude 9.1813015 (source station locator, not a survey monument).
- Local +Y follows mapped corridor northward, using EN north-vector [0.3473554696426697, 0.9377335323583776]; +X is perpendicular.
- Adopted mapping window: [-500.0, -1400.0, 500.0, 1400.0]m. Mapped approaches are retained throughout this window, including loop joins and sidings; clipping at the window is documented rather than fabricated continuations.
- Enclosed building envelope in the mapped scene: approximately 16.00m across track × 100.00m along track, at [-3, 100]. Original source footprint, if any, retained separately. For TNU this0m corridor envelope deliberately excludes the separate unplaced historical15.5×6.8×4.78m building study.
- Track gauge:1.676m. Railhead centers±0.868m, tread width60mm. Visual wheel-flange channels45mm.
- Rail top0.635m, platform top1.45m, contact wire6.30m. These are plausible reconstructed model dimensions, not certified construction tolerances.

## Reconstructed elements and limits
Unseen rooms, interior partitions, furniture placement, ticket-office equipment, toilets, fans, lamps, drainage fittings, roof supports, accessibility ramp, canopy/footbridge positions, signal positions, electrical equipment and vegetation are reconstructed. Small halts receive compact rooms and modest amenities; no large concourse is invented. Interiors are furnished for inspectability, without claiming access to private operational areas. All geometry is editable.

Station-specific cautions:
- Pedestrian bridge: Mapped pedestrian bridge centerline, exact source retained; height/structure reconstructed https://www.openstreetmap.org/way/1103711043
- The western mapped platform repeats ref2;3 erroneously. It is modeled as the side body, with two additional island bodies, matching5 reported faces. The nearby OSM bus-station footprint is excluded as the railway hall. Station-building placement/dimensions are reconstructed adjacent to the western side platform.

## QA and lineage
QA_BUILD.json records scene counts, source-plan checksum, packed resources and the Blender checksum. Each render has a paired JSON with camera, source checksum and render settings. Manifest hashes identify the exact released files. Independent QA status is supplied separately; a successful render alone is not a blanket accuracy certification. Source railway-plan data and architecture estimates are intentionally distinguished.

## Attribution
Railway map data © OpenStreetMap contributors, ODbL1.0: https://www.openstreetmap.org/copyright . The derived source plan is retained in references/plan.json. Station metadata cites India Rail Info and the source register. Photographs remain with their owners and are linked as research references, not redistributed. Original models, textures and signage generated for this project. Noto fonts are used for original raster lettering under SIL Open Font License; no font binary is bundled.
