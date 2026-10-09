# KVTA · Karuvatta | Coastal railway station reconstruction

## What is delivered
Full-scale metre scene with no trains or rolling stock. Packed Blender file, complete portable GLB geometry export when available, and rendered views derived from the frozen Blender scene. The Blender file is authoritative for procedural materials; GLB embeds original sign textures and uses PBR approximations for procedural surface noise. A lossless GLB transport archive restores the exact verified GLB bytes, not arbitrary Blender shader nodes. Current snapshot review date:2026-10-08. This is a useful visual reconstruction, not a surveyed as-built or certified operating layout.

## Station evidence and scope
- Status: Listed current by SR2025; no subsequent closure found
- IRI-reported platform faces: 2 (Reported platform positions; not independently verified current operational inventory)
- IRI source: https://d.indiarailinfo.com/station/map/karuvatta-halt-kvta/6540
- Official chainage if supplied: 81.49 km, datum ERS via ALLP.
- Mapped roads at station transect: 2; mapped rail segments in scene: 2; combined mapped route length: 4600.1m.
- Mapped description: Two sideplatform bodies beside two continuous main tracks; no extra track mapped within inspected station bounding box.
- Source edit dates: 2022-02-24T20:58:24Z / 2025-05-27T22:33:36Z. An OSM edit timestamp is not a survey date.
- Current loops/sidings totals: NOT VERIFIED. The actual adopted OSM paths are modeled; service tags are preserved. A tag service=siding can describe a both-ended loop.
- Proposed/construction ways excluded. No extra operational running line inferred from line-doubling projects.

## Architecture source
https://www.madhyamam.com/h-upload/2025/04/21/2559828-untitled-1.webp

Additional actually inspected source records in references/architecture_evidence.json:
- https://www.google.com/maps/place/Karuvatta+Railway+Station/@9.3165241,76.4311114,3a,75y,90t/data=!3m8!1e2!3m6!1sCIABIhAGbwPTfgw2VGepVhQACWDo!2e10!3e12!6shttps:%2F%2Flh3.googleusercontent.com%2Fgps-cs-s%2FAHRPTWmPrwEHUlkNNBRXdN_ZihmkApwz-7AwPpX6L8pMZh13len1CiSI7xCFr65D-g2skrnCFSgdQibibYhJGUOJlDDZttkzno6xWmzGPKYjG-yXtrkK_KgFTCcrcgPxDLXDqertV6KLhRv6fFc%3Dw203-h269-k-no!7i3072!8i4080!4m7!3m6!1s0x3b089f48d71a17ab:0xf84d0dad69b7ddf9!8m2!3d9.3165872!4d76.4311817!10e5!16s%2Fg%2F11gxx6cghj?authuser=0&hl=en&entry=ttu&g_ep=EgoyMDI2MTAwNS4wIKXMDSoASAFQAw%3D%3D

Facade color, roof type, portico rhythm and signage follow inspected photographs where available. Photo appearance may be historic. Dimensions are reconstruction estimates. Downloaded reference photos are excluded from the release; original sign artwork and materials are newly made. Google Images was traffic-blocked. Google Maps ordinary photos were usable; clicking a Street View-labelled station tile sometimes opened still photos. No actual Street View panorama is claimed unless a separate evidence entry explicitly records it.

## Platform bodies
- Body1: numbering inferred; OSM platform line buffered to estimated 6 m width; source ways ['1034910486'].
- Body2: numbering inferred; OSM platform line buffered to estimated 6 m width; source ways ['1034910485'].

## Dimensions and coordinate system
- Local origin: longitude 76.4311191, latitude 9.3166262 (source station locator, not a survey monument).
- Local +Y follows mapped corridor northward, using EN north-vector [-0.7330163846054991, 0.6802109819018528]; +X is perpendicular.
- Adopted mapping window: [-230.0, -1150.0, 230.0, 1150.0]m. Mapped approaches are retained throughout this window, including loop joins and sidings; clipping at the window is documented rather than fabricated continuations.
- Enclosed building envelope in the mapped scene: approximately 7.64m across track × 17.08m along track, at [-2.593703198649344, -1.2018194800626545]. Original source footprint, if any, retained separately. For TNU this0m corridor envelope deliberately excludes the separate unplaced historical15.5×6.8×4.78m building study.
- Track gauge:1.676m. Railhead centers±0.868m, tread width60mm. Visual wheel-flange channels45mm.
- Rail top0.635m, platform top1.45m, contact wire6.30m. These are plausible reconstructed model dimensions, not certified construction tolerances.

## Reconstructed elements and limits
Unseen rooms, interior partitions, furniture placement, ticket-office equipment, toilets, fans, lamps, drainage fittings, roof supports, accessibility ramp, canopy/footbridge positions, signal positions, electrical equipment and vegetation are reconstructed. Small halts receive compact rooms and modest amenities; no large concourse is invented. Interiors are furnished for inspectability, without claiming access to private operational areas. All geometry is editable.

Station-specific cautions:
- Pedestrian bridge: Reconstructed near ticket hut based on actually inspected Feb2025 public photo; longitudinal position estimated, not surveyed. 
- Source photographs span older single-side views and a2025 two-line station/footbridge view. Operational services are not inferred from the model.

## QA and lineage
QA_BUILD.json records scene counts, source-plan checksum, packed resources and the Blender checksum. Each render has a paired JSON with camera, source checksum and render settings. Manifest hashes identify the exact released files. Independent QA status is supplied separately; a successful render alone is not a blanket accuracy certification. Source railway-plan data and architecture estimates are intentionally distinguished.

## Attribution
Railway map data © OpenStreetMap contributors, ODbL1.0: https://www.openstreetmap.org/copyright . The derived source plan is retained in references/plan.json. Station metadata cites India Rail Info and the source register. Photographs remain with their owners and are linked as research references, not redistributed. Original models, textures and signage generated for this project. Noto fonts are used for original raster lettering under SIL Open Font License; no font binary is bundled.
