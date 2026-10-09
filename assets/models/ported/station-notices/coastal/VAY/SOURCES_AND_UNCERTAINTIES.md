# VAY · Vayalar | Coastal railway station reconstruction

## What is delivered
Full-scale metre scene with no trains or rolling stock. Packed Blender file, complete portable GLB geometry export when available, and rendered views derived from the frozen Blender scene. The Blender file is authoritative for procedural materials; GLB embeds original sign textures and uses PBR approximations for procedural surface noise. A lossless GLB transport archive restores the exact verified GLB bytes, not arbitrary Blender shader nodes. Current snapshot review date:2026-10-08. This is a useful visual reconstruction, not a surveyed as-built or certified operating layout.

## Station evidence and scope
- Status: Listed current by SR2025; no subsequent closure found
- IRI-reported platform faces: 1 (Reported platform positions; not independently verified current operational inventory)
- IRI source: https://srv23.indiarailinfo.com/station/map/vayalar-vay/6546
- Official chainage if supplied: 26.97 km, datum ERS via ALLP.
- Mapped roads at station transect: 1; mapped rail segments in scene: 3; combined mapped route length: 2285.7m.
- Mapped description: One through track mapped at halt. No platform footprint.
- Source edit dates: 2021-01-02T15:24:39Z / 2025-03-09T14:07:14Z. An OSM edit timestamp is not a survey date.
- Current loops/sidings totals: NOT VERIFIED. The actual adopted OSM paths are modeled; service tags are preserved. A tag service=siding can describe a both-ended loop.
- Proposed/construction ways excluded. No extra operational running line inferred from line-doubling projects.

## Architecture source
https://st.indiarailinfo.com/kjfdsuiemjvcya21/0/3/2/9/1865329/0/dscn03142807061.jpg

Additional actually inspected source records in references/architecture_google_evidence.json:
- https://www.google.com/maps/place/Vayalar/@9.7419872,76.3120298,3a,75y,90t/data=!3m8!1e2!3m6!1sCIABIhCsJmdg04wJmjAaTVxDwQK-!2e10!3e12!6shttps:%2F%2Flh3.googleusercontent.com%2Fgrass-cs%2FACvplmOAnPxoNk9_T-KHqLmzTaM9E9J5hG3p8kqAVHscWdPQq6m6uFxMAsACMhWT1L5IPypFui5EGg6WHs0zrVA4XC3vESgPwWn3SxpD2QNTLmJYdiQzEnhuBZeqSPv5s-TPTXh8dYFhuTKZJpQ%3Dw114-h86-k-no!7i4096!8i3072!4m7!3m6!1s0x3b087b0ed4b7d355:0xab04033ee968c77d!8m2!3d9.74199!4d76.3118986!10e5!16s%2Fg%2F1vk6xncz?entry=ttu&g_ep=EgoyMDI2MTAwNS4wIKXMDSoASAFQAw%3D%3D
- https://www.google.com/maps/place/Vayalar/@9.7419872,76.3120298,3a,75y,90t/data=!3m8!1e2!3m6!1sCIHM0ogKEICAgIDk5cPv8AE!2e10!3e12!6shttps:%2F%2Flh3.googleusercontent.com%2Fgps-cs-s%2FAHRPTWnf-Y2bRCRIZrWLYf7UOvsRooPPmAEG_wnXrDG8dEzWp__4uAkS0wFvcuezvYHz56SYWdYDQ1Q-JSxi-iJPSHDhtsnuCBTwcN5VqLWrvCHJaicYCPGIGAKlrPwJ-gXT64-K8rzQUg%3Dw203-h140-k-no!7i2884!8i2000!4m7!3m6!1s0x3b087b0ed4b7d355:0xab04033ee968c77d!8m2!3d9.74199!4d76.3118986!10e5!16s%2Fg%2F1vk6xncz?entry=ttu&g_ep=EgoyMDI2MTAwNS4wIKXMDSoASAFQAw%3D%3D

Facade color, roof type, portico rhythm and signage follow inspected photographs where available. Photo appearance may be historic. Dimensions are reconstruction estimates. Downloaded reference photos are excluded from the release; original sign artwork and materials are newly made. Google Images was traffic-blocked. Google Maps ordinary photos were usable; clicking a Street View-labelled station tile sometimes opened still photos. No actual Street View panorama is claimed unless a separate evidence entry explicitly records it.

## Platform bodies
- Body1: 1; IRI platform count; reconstructed extent/width; source ways none.

## Dimensions and coordinate system
- Local origin: longitude 76.3119626, latitude 9.7420079 (source station locator, not a survey monument).
- Local +Y follows mapped corridor northward, using EN north-vector [0.11898767066464278, 0.9928957318015837]; +X is perpendicular.
- Adopted mapping window: [-230.0, -1150.0, 230.0, 1150.0]m. Mapped approaches are retained throughout this window, including loop joins and sidings; clipping at the window is documented rather than fabricated continuations.
- Enclosed building envelope in the mapped scene: approximately 9.69m across track × 12.46m along track, at [-6.369473311008943, -3.999840230317064]. Original source footprint, if any, retained separately. For TNU this0m corridor envelope deliberately excludes the separate unplaced historical15.5×6.8×4.78m building study.
- Track gauge:1.676m. Railhead centers±0.868m, tread width60mm. Visual wheel-flange channels45mm.
- Rail top0.635m, platform top1.45m, contact wire6.30m. These are plausible reconstructed model dimensions, not certified construction tolerances.

## Reconstructed elements and limits
Unseen rooms, interior partitions, furniture placement, ticket-office equipment, toilets, fans, lamps, drainage fittings, roof supports, accessibility ramp, canopy/footbridge positions, signal positions, electrical equipment and vegetation are reconstructed. Small halts receive compact rooms and modest amenities; no large concourse is invented. Interiors are furnished for inspectability, without claiming access to private operational areas. All geometry is editable.

Station-specific cautions:


## QA and lineage
QA_BUILD.json records scene counts, source-plan checksum, packed resources and the Blender checksum. Each render has a paired JSON with camera, source checksum and render settings. Manifest hashes identify the exact released files. Independent QA status is supplied separately; a successful render alone is not a blanket accuracy certification. Source railway-plan data and architecture estimates are intentionally distinguished.

## Attribution
Railway map data © OpenStreetMap contributors, ODbL1.0: https://www.openstreetmap.org/copyright . The derived source plan is retained in references/plan.json. Station metadata cites India Rail Info and the source register. Photographs remain with their owners and are linked as research references, not redistributed. Original models, textures and signage generated for this project. Noto fonts are used for original raster lettering under SIL Open Font License; no font binary is bundled.
