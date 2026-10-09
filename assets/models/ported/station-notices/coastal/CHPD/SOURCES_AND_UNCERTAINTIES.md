# CHPD · Cheppad | Coastal railway station reconstruction

## What is delivered
Full-scale metre scene with no trains or rolling stock. Packed Blender file, complete portable GLB geometry export when available, and rendered views derived from the frozen Blender scene. The Blender file is authoritative for procedural materials; GLB embeds original sign textures and uses PBR approximations for procedural surface noise. A lossless GLB transport archive restores the exact verified GLB bytes, not arbitrary Blender shader nodes. Current snapshot review date:2026-10-08. This is a useful visual reconstruction, not a surveyed as-built or certified operating layout.

## Station evidence and scope
- Status: Listed current by SR2025; no subsequent closure found
- IRI-reported platform faces: 3 (Reported platform positions; not independently verified current operational inventory)
- IRI source: https://indiarailinfo.com/station/blog/cheppad-halt-chpd/6541
- Official chainage if supplied: 92.58 km, datum ERS via ALLP.
- Mapped roads at station transect: 4; mapped rail segments in scene: 10; combined mapped route length: 7530.4m.
- Mapped description: Two main tracks plus one long west loop and shorter western auxiliary yardroad crossing locator transect. Additional crossover and trapextension geometry. Platform footprints absent.
- Source edit dates: 2018-11-04T15:21:44Z / 2025-11-24T08:40:10Z. An OSM edit timestamp is not a survey date.
- Current loops/sidings totals: NOT VERIFIED. The actual adopted OSM paths are modeled; service tags are preserved. A tag service=siding can describe a both-ended loop.
- Proposed/construction ways excluded. No extra operational running line inferred from line-doubling projects.

## Architecture source
https://files.yappe.in/place/full/cheppad-halt-8781173.webp

Additional actually inspected source records in references/architecture_google_evidence.json:
- https://www.google.com/maps/place/Cheppad+Railway+Station/@9.2330775,76.4766973,3a,75y,90t/data=!3m8!1e2!3m6!1sCIHM0ogKEICAgID0m96Y1AE!2e10!3e12!6shttps:%2F%2Flh3.googleusercontent.com%2Fgps-cs-s%2FAHRPTWm_2RVJhes58nfAz7k87YcT0PodL5sPbV97N_xXHKlmFlDPP5pDMhRvLfN59m2s4EcATykkzXnyW4hEM7Uz369lY8Y1VP1oZu6YLJoiPYkjhRJ2aUNfPzuhCSHTgrg5qYE9c9V-dQ%3Dw203-h152-k-no!7i4032!8i3024!4m7!3m6!1s0x3b061f35b5107bcb:0x46a60bf8c43d3166!8m2!3d9.2331013!4d76.4767813!10e5!16s%2Fg%2F11gtz4580c?authuser=0&hl=en&entry=ttu&g_ep=EgoyMDI2MTAwNS4wIKXMDSoASAFQAw%3D%3D

Facade color, roof type, portico rhythm and signage follow inspected photographs where available. Photo appearance may be historic. Dimensions are reconstruction estimates. Downloaded reference photos are excluded from the release; original sign artwork and materials are newly made. Google Images was traffic-blocked. Google Maps ordinary photos were usable; clicking a Street View-labelled station tile sometimes opened still photos. No actual Street View panorama is claimed unless a separate evidence entry explicitly records it.

## Platform bodies
- Body1: 1; IRI count; reconstructed side platform; source ways none.
- Body2: 2;3; IRI count; reconstructed island in mapped track gap; source ways none.

## Dimensions and coordinate system
- Local origin: longitude 76.4768113, latitude 9.2330076 (source station locator, not a survey monument).
- Local +Y follows mapped corridor northward, using EN north-vector [-0.30565343373172077, 0.952142835108267]; +X is perpendicular.
- Adopted mapping window: [-230.0, -1150.0, 230.0, 1150.0]m. Mapped approaches are retained throughout this window, including loop joins and sidings; clipping at the window is documented rather than fabricated continuations.
- Enclosed building envelope in the mapped scene: approximately 10.00m across track × 16.00m along track, at [-2.185578344055089, 0]. Original source footprint, if any, retained separately. For TNU this0m corridor envelope deliberately excludes the separate unplaced historical15.5×6.8×4.78m building study.
- Track gauge:1.676m. Railhead centers±0.868m, tread width60mm. Visual wheel-flange channels45mm.
- Rail top0.635m, platform top1.45m, contact wire6.30m. These are plausible reconstructed model dimensions, not certified construction tolerances.

## Reconstructed elements and limits
Unseen rooms, interior partitions, furniture placement, ticket-office equipment, toilets, fans, lamps, drainage fittings, roof supports, accessibility ramp, canopy/footbridge positions, signal positions, electrical equipment and vegetation are reconstructed. Small halts receive compact rooms and modest amenities; no large concourse is invented. Interiors are furnished for inspectability, without claiming access to private operational areas. All geometry is editable.

Station-specific cautions:


## QA and lineage
QA_BUILD.json records scene counts, source-plan checksum, packed resources and the Blender checksum. Each render has a paired JSON with camera, source checksum and render settings. Manifest hashes identify the exact released files. Independent QA status is supplied separately; a successful render alone is not a blanket accuracy certification. Source railway-plan data and architecture estimates are intentionally distinguished.

## Attribution
Railway map data © OpenStreetMap contributors, ODbL1.0: https://www.openstreetmap.org/copyright . The derived source plan is retained in references/plan.json. Station metadata cites India Rail Info and the source register. Photographs remain with their owners and are linked as research references, not redistributed. Original models, textures and signage generated for this project. Noto fonts are used for original raster lettering under SIL Open Font License; no font binary is bundled.
