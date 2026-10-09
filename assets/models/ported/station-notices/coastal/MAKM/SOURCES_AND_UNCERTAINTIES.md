# MAKM · Mararikulam | Coastal railway station reconstruction

## What is delivered
Full-scale metre scene with no trains or rolling stock. Packed Blender file, complete portable GLB geometry export when available, and rendered views derived from the frozen Blender scene. The Blender file is authoritative for procedural materials; GLB embeds original sign textures and uses PBR approximations for procedural surface noise. A lossless GLB transport archive restores the exact verified GLB bytes, not arbitrary Blender shader nodes. Current snapshot review date:2026-10-08. This is a useful visual reconstruction, not a surveyed as-built or certified operating layout.

## Station evidence and scope
- Status: Listed current by SR2025; no subsequent closure found
- IRI-reported platform faces: 2 (Reported platform positions; not independently verified current operational inventory)
- IRI source: https://d.indiarailinfo.com/station/map/mararikkulam-makm/1784
- Official chainage if supplied: 44.23 km, datum ERS via ALLP.
- Mapped roads at station transect: 3; mapped rail segments in scene: 6; combined mapped route length: 4611.5m.
- Mapped description: One clear sideplatform ref1(way798274551). Stationbuilding798274550 also taggedplatform but excluded to avoid double counting. Three long parallel roads; two outer roads taggedsidings but both-ended. Short southern auxiliaryloop, north refuge spur and south trap extension mapped. Actual current second platform not established.
- Source edit dates: 2018-11-04T12:59:36Z / 2025-11-10T19:23:30Z. An OSM edit timestamp is not a survey date.
- Current loops/sidings totals: NOT VERIFIED. The actual adopted OSM paths are modeled; service tags are preserved. A tag service=siding can describe a both-ended loop.
- Proposed/construction ways excluded. No extra operational running line inferred from line-doubling projects.

## Architecture source
https://files.yappe.in/place/full/mararikkulam-8802778.webp

Facade color, roof type, portico rhythm and signage follow inspected photographs where available. Photo appearance may be historic. Dimensions are reconstruction estimates. Downloaded reference photos are excluded from the release; original sign artwork and materials are newly made. Google Images was traffic-blocked. Google Maps ordinary photos were usable; clicking a Street View-labelled station tile sometimes opened still photos. No actual Street View panorama is claimed unless a separate evidence entry explicitly records it.

## Platform bodies
- Body1: 1; OSM area footprint; source ways ['798274551'].
- Body2: 2; Second IRI-reported platform; footprint and current state unverified; source ways none.

## Dimensions and coordinate system
- Local origin: longitude 76.3180189, latitude 9.5977041 (source station locator, not a survey monument).
- Local +Y follows mapped corridor northward, using EN north-vector [0.24163200810506544, 0.9703679573538656]; +X is perpendicular.
- Adopted mapping window: [-230.0, -1150.0, 230.0, 1150.0]m. Mapped approaches are retained throughout this window, including loop joins and sidings; clipping at the window is documented rather than fabricated continuations.
- Enclosed building envelope in the mapped scene: approximately 7.33m across track × 31.41m along track, at [-9.41789483152797, -2.183718150657712]. Original source footprint, if any, retained separately. For TNU this0m corridor envelope deliberately excludes the separate unplaced historical15.5×6.8×4.78m building study.
- Track gauge:1.676m. Railhead centers±0.868m, tread width60mm. Visual wheel-flange channels45mm.
- Rail top0.635m, platform top1.45m, contact wire6.30m. These are plausible reconstructed model dimensions, not certified construction tolerances.

## Reconstructed elements and limits
Unseen rooms, interior partitions, furniture placement, ticket-office equipment, toilets, fans, lamps, drainage fittings, roof supports, accessibility ramp, canopy/footbridge positions, signal positions, electrical equipment and vegetation are reconstructed. Small halts receive compact rooms and modest amenities; no large concourse is invented. Interiors are furnished for inspectability, without claiming access to private operational areas. All geometry is editable.

Station-specific cautions:
- Source roof/building envelope partly overlaps platform. Enclosed hall shifted outside platform by geometric clearance; source footprint retained unchanged. Not a surveyed correction.
- IRI reports2 platforms. Only one side platform is confidently mapped; the second is explicitly a hypothetical reconstructed footprint on the opposite side. It is not evidence that a second platform is currently operational. A safe present-day pedestrian connection to that hypothetical body has not been established. No footbridge is invented across the narrow mapped3.06m side platform; the modeled two-body arrangement is a visual hypothesis, not a certified connected passenger layout.

## QA and lineage
QA_BUILD.json records scene counts, source-plan checksum, packed resources and the Blender checksum. Each render has a paired JSON with camera, source checksum and render settings. Manifest hashes identify the exact released files. Independent QA status is supplied separately; a successful render alone is not a blanket accuracy certification. Source railway-plan data and architecture estimates are intentionally distinguished.

## Attribution
Railway map data © OpenStreetMap contributors, ODbL1.0: https://www.openstreetmap.org/copyright . The derived source plan is retained in references/plan.json. Station metadata cites India Rail Info and the source register. Photographs remain with their owners and are linked as research references, not redistributed. Original models, textures and signage generated for this project. Noto fonts are used for original raster lettering under SIL Open Font License; no font binary is bundled.
