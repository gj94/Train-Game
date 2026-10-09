# TNU · Tirunettur | Coastal railway station reconstruction

## What is delivered
Full-scale metre scene with no trains or rolling stock. Packed Blender file, lossless portable GLB export when available, and rendered views derived from the frozen Blender scene. Current snapshot review date:2026-10-08. This is a useful visual reconstruction, not a surveyed as-built or certified operating layout.

## Station evidence and scope
- Status: CLOSED from2017-07-10
- IRI-reported platform faces: 1 (Historical closed station)
- IRI source: https://indiarailinfo.com/station/gallery/videos-pictures-tirunettur-tnu/6542
- Official chainage if supplied: Unresolved km, datum ERS via ALLP.
- Mapped roads at station transect: 1; mapped rail segments in scene: 2; combined mapped route length: 2175.9m.
- Mapped description: Officially closed halt in 2017. OSM still labels station; one through track mapped, no platform footprint. OSM station label does not establish passenger operation.
- Source edit dates: 2021-01-02T15:24:48Z / 2025-06-08T18:54:48Z. An OSM edit timestamp is not a survey date.
- Current loops/sidings totals: NOT VERIFIED. The actual adopted OSM paths are modeled; service tags are preserved. A tag service=siding can describe a both-ended loop.
- Proposed/construction ways excluded. No extra operational running line inferred from line-doubling projects.

## Architecture source
See the actually inspected photo records linked below.

Additional actually inspected source records in references/architecture_google_evidence.json:
- https://www.google.com/maps/place/Tirunettur/@9.9342008,76.3084576,3a,75y,90t/data=!3m8!1e2!3m6!1sCIHM0ogKEICAgIDE1teZVg!2e10!3e12!6shttps:%2F%2Flh3.googleusercontent.com%2Fgrass-cs%2FAABkmLf4A91uQjD4Jl_j41BsjdQXz1WTbq-Nzt1EM2jiEKYqYxGmHlZ6h1ejJR2TALkrvMi3wRe1_tkiGetvvKojklo8GMZVLSj8l46y3su9dDrd6b5oic26WbDUYo_QdjNJdspWoBfV%3Dw114-h86-k-no!7i3264!8i2448!4m7!3m6!1s0x3b0872f9a6570403:0x4f9e7955d2f279b6!8m2!3d9.9342008!4d76.3084576!10e5!16s%2Fg%2F1tfhy0dx?entry=ttu&g_ep=EgoyMDI2MTAwNS4wIKXMDSoASAFQAw%3D%3D
- https://www.google.com/maps/place/Tirunettur/@9.9342501,76.3085739,3a,75y,90t/data=!3m8!1e2!3m6!1sCIHM0ogKEICAgICE_f2L5gE!2e10!3e12!6shttps:%2F%2Flh3.googleusercontent.com%2Fgps-cs-s%2FAHRPTWn1oPEyXHK3eOhx_gpUODEjNyIMHLsmViwykg2uXNIF2hd6UBj0wyzTVaR_TlOVOZpuFW0m04Qp74hWxKkzZM2tXYtpLeF-vWWKE2U-fdvvaw6cZ2N0ChByyvFU0q96efS0y6X1%3Dw203-h152-k-no!7i4160!8i3120!4m7!3m6!1s0x3b0872f9a6570403:0x4f9e7955d2f279b6!8m2!3d9.9342008!4d76.3084576!10e5!16s%2Fg%2F1tfhy0dx?entry=ttu&g_ep=EgoyMDI2MTAwNS4wIKXMDSoASAFQAw%3D%3D

Facade color, roof type, portico rhythm and signage follow inspected photographs where available. Photo appearance may be historic. Dimensions are reconstruction estimates. Downloaded reference photos are excluded from the release; original sign artwork and materials are newly made. Google Images was traffic-blocked. Google Maps ordinary photos were usable; clicking a Street View-labelled station tile sometimes opened still photos. No actual Street View panorama is claimed unless a separate evidence entry explicitly records it.

## Platform bodies
- No current or reconstructed operational platform in this closed-site scene.

## Dimensions and coordinate system
- Local origin: longitude 76.3085098, latitude 9.9342399 (source station locator, not a survey monument).
- Local +Y follows mapped corridor northward, using EN north-vector [-0.2853069017989178, 0.9584362116416004]; +X is perpendicular.
- Adopted mapping window: [-230.0, -1150.0, 230.0, 1150.0]m. Mapped approaches are retained throughout this window, including loop joins and sidings; clipping at the window is documented rather than fabricated continuations.
- Enclosed building envelope in the mapped scene: approximately 0.00m across track × 0.00m along track, at [0, 0]. Original source footprint, if any, retained separately. For TNU this0m corridor envelope deliberately excludes the separate unplaced historical15.5×6.8×4.78m building study.
- Track gauge:1.676m. Railhead centers±0.868m, tread width60mm. Visual wheel-flange channels45mm.
- Rail top0.635m, platform top1.45m, contact wire6.30m. These are plausible reconstructed model dimensions, not certified construction tolerances.

## Reconstructed elements and limits
Unseen rooms, interior partitions, furniture placement, ticket-office equipment, toilets, fans, lamps, drainage fittings, roof supports, accessibility ramp, canopy/footbridge positions, signal positions, electrical equipment and vegetation are reconstructed. Small halts receive compact rooms and modest amenities; no large concourse is invented. Interiors are furnished for inspectability, without claiming access to private operational areas. All geometry is editable.

Station-specific cautions:
- Tirunettur closed on10 July2017. The legacy map point and remaining corridor do not locate a verified historic platform remnant. This is a CLOSED-SITE RECORD. A separate scene models the actually photographed August2016 facade and modest reconstructed hidden furnishings. That historical building is explicitly UNPLACED; the mapped corridor scene does not prove current remnant survival or precise historical building placement. The IRI one-platform figure is historical only.

## QA and lineage
QA_BUILD.json records scene counts, source-plan checksum, packed resources and the Blender checksum. Each render has a paired JSON with camera, source checksum and render settings. Manifest hashes identify the exact released files. Independent QA status is supplied separately; a successful render alone is not a blanket accuracy certification. Source railway-plan data and architecture estimates are intentionally distinguished.

## Attribution
Railway map data © OpenStreetMap contributors, ODbL1.0: https://www.openstreetmap.org/copyright . The derived source plan is retained in references/plan.json. Station metadata cites India Rail Info and the source register. Photographs remain with their owners and are linked as research references, not redistributed. Original models, textures and signage generated for this project. Noto fonts are used for original raster lettering under SIL Open Font License; no font binary is bundled.
