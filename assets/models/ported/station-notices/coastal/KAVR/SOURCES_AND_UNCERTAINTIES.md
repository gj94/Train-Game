# KAVR · Kalavur | Coastal railway station reconstruction

## What is delivered
Full-scale metre scene with no trains or rolling stock. Packed Blender file, complete portable GLB geometry export when available, and rendered views derived from the frozen Blender scene. The Blender file is authoritative for procedural materials; GLB embeds original sign textures and uses PBR approximations for procedural surface noise. A lossless GLB transport archive restores the exact verified GLB bytes, not arbitrary Blender shader nodes. Current snapshot review date:2026-10-08. This is a useful visual reconstruction, not a surveyed as-built or certified operating layout.

## Station evidence and scope
- Status: Listed current by SR2025; no subsequent closure found
- IRI-reported platform faces: 1 (Reported platform positions; not independently verified current operational inventory)
- IRI source: https://indiarailinfo.com/station/map/kalavur-halt-kavr/6547
- Official chainage if supplied: 47.58 km, datum ERS via ALLP.
- Mapped roads at station transect: 1; mapped rail segments in scene: 1; combined mapped route length: 2306.8m.
- Mapped description: One through track mapped at halt. No platform footprint.
- Source edit dates: 2025-02-17T07:33:28Z / 2025-02-17T07:33:28Z. An OSM edit timestamp is not a survey date.
- Current loops/sidings totals: NOT VERIFIED. The actual adopted OSM paths are modeled; service tags are preserved. A tag service=siding can describe a both-ended loop.
- Proposed/construction ways excluded. No extra operational running line inferred from line-doubling projects.

## Architecture source
https://www.mappls.com/place/254ECC_1649655969877_0.png

Additional actually inspected source records in references/architecture_google_evidence.json:
- https://www.google.com/maps/place/Kalavur+Halt/@9.5680494,76.3186463,3a,75y,90t/data=!3m8!1e2!3m6!1sCIHM0ogKEICAgID40LOnjAE!2e10!3e12!6shttps:%2F%2Flh3.googleusercontent.com%2Fgrass-cs%2FACvplmOA3kOgZnAiyZdpbr6wuj2ZsLKA0m3NJVZzQBcIjgGo9P16tK2koIkIUxUzU7f3ClivXHOOBgul0Ekm2pePxFFnlEUmcFHSQi-nGueIt9YE0CeT6z0RO2XtJ21uZF9rlDxIFubs%3Dw114-h86-k-no!7i4160!8i3120!4m7!3m6!1s0x3b0886f63c27656b:0x5b5375cecfa37427!8m2!3d9.5680236!4d76.3185482!10e5!16s%2Fg%2F1tfg62q3?entry=ttu&g_ep=EgoyMDI2MTAwNS4wIKXMDSoASAFQAw%3D%3D

Facade color, roof type, portico rhythm and signage follow inspected photographs where available. Photo appearance may be historic. Dimensions are reconstruction estimates. Downloaded reference photos are excluded from the release; original sign artwork and materials are newly made. Google Images was traffic-blocked. Google Maps ordinary photos were usable; clicking a Street View-labelled station tile sometimes opened still photos. No actual Street View panorama is claimed unless a separate evidence entry explicitly records it.

## Platform bodies
- Body1: 1; IRI platform count; reconstructed extent/width; source ways none.

## Dimensions and coordinate system
- Local origin: longitude 76.3185589, latitude 9.5679922 (source station locator, not a survey monument).
- Local +Y follows mapped corridor northward, using EN north-vector [-0.14940324925882345, 0.9887763493889332]; +X is perpendicular.
- Adopted mapping window: [-230.0, -1150.0, 230.0, 1150.0]m. Mapped approaches are retained throughout this window, including loop joins and sidings; clipping at the window is documented rather than fabricated continuations.
- Enclosed building envelope in the mapped scene: approximately 7.45m across track × 13.93m along track, at [5.133058974264925, 2.199585232054528]. Original source footprint, if any, retained separately. For TNU this0m corridor envelope deliberately excludes the separate unplaced historical15.5×6.8×4.78m building study.
- Track gauge:1.676m. Railhead centers±0.868m, tread width60mm. Visual wheel-flange channels45mm.
- Rail top0.635m, platform top1.45m, contact wire6.30m. These are plausible reconstructed model dimensions, not certified construction tolerances.

## Reconstructed elements and limits
Unseen rooms, interior partitions, furniture placement, ticket-office equipment, toilets, fans, lamps, drainage fittings, roof supports, accessibility ramp, canopy/footbridge positions, signal positions, electrical equipment and vegetation are reconstructed. Small halts receive compact rooms and modest amenities; no large concourse is invented. Interiors are furnished for inspectability, without claiming access to private operational areas. All geometry is editable.

Station-specific cautions:


## QA and lineage
QA_BUILD.json records scene counts, source-plan checksum, packed resources and the Blender checksum. Each render has a paired JSON with camera, source checksum and render settings. Manifest hashes identify the exact released files. Independent QA status is supplied separately; a successful render alone is not a blanket accuracy certification. Source railway-plan data and architecture estimates are intentionally distinguished.

## Attribution
Railway map data © OpenStreetMap contributors, ODbL1.0: https://www.openstreetmap.org/copyright . The derived source plan is retained in references/plan.json. Station metadata cites India Rail Info and the source register. Photographs remain with their owners and are linked as research references, not redistributed. Original models, textures and signage generated for this project. Noto fonts are used for original raster lettering under SIL Open Font License; no font binary is bundled.
