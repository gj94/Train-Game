# PNPR · Punnapra | Coastal railway station reconstruction

## What is delivered
Full-scale metre scene with no trains or rolling stock. Packed Blender file, complete portable GLB geometry export when available, and rendered views derived from the frozen Blender scene. The Blender file is authoritative for procedural materials; GLB embeds original sign textures and uses PBR approximations for procedural surface noise. A lossless GLB transport archive restores the exact verified GLB bytes, not arbitrary Blender shader nodes. Current snapshot review date:2026-10-08. This is a useful visual reconstruction, not a surveyed as-built or certified operating layout.

## Station evidence and scope
- Status: Listed current by SR2025; no subsequent closure found
- IRI-reported platform faces: 1 (Reported platform positions; not independently verified current operational inventory)
- IRI source: https://srv23.indiarailinfo.com/station/map/punnapura-pnpr/7373
- Official chainage if supplied: 64.07 km, datum ERS via ALLP.
- Mapped roads at station transect: 1; mapped rail segments in scene: 1; combined mapped route length: 2301.0m.
- Mapped description: One through track; platform footprint absent. Corrected OSM node3296422361 at9.4233973,76.3419377 uses alternate PUPR; officialstation code PNPR. Datameet PNPR point3km north rejected.
- Source edit dates: 2025-12-27T10:26:09Z / 2025-12-27T10:26:09Z. An OSM edit timestamp is not a survey date.
- Current loops/sidings totals: NOT VERIFIED. The actual adopted OSM paths are modeled; service tags are preserved. A tag service=siding can describe a both-ended loop.
- Proposed/construction ways excluded. No extra operational running line inferred from line-doubling projects.

## Architecture source
See the actually inspected photo records linked below.

Additional actually inspected source records in references/architecture_google_evidence.json:
- https://www.google.com/maps/place/Punnapra+Railway+Station/@9.423485,76.3419532,3a,75y,90t/data=!3m8!1e2!3m6!1sCIHM0ogKEICAgIDxkambNA!2e10!3e12!6shttps:%2F%2Flh3.googleusercontent.com%2Fgrass-cs%2FACvplmP-ncrnLN9C-Is7p4yp3WQqYPUWVk65xdJjYGw58j2QXpCRi15G7IMmyuTpWiEYKCbzjcZA7pwYK0jJ7xQfIl74ZJ2XK_pqi4YGe-VJwUsJaaxfUDaRDzkprhRrEk21pU9FR5gu%3Dw152-h86-k-no!7i4608!8i2592!4m11!1m2!2m1!1sPunnapra+railway+station!3m7!1s0x3b089ba7f8a75079:0x415ea616159f97fe!8m2!3d9.4234408!4d76.3418661!10e5!15sChhQdW5uYXByYSByYWlsd2F5IHN0YXRpb25aGiIYcHVubmFwcmEgcmFpbHdheSBzdGF0aW9ukgEUdHJhaW5fdGlja2V0X2NvdW50ZXKaASNDaFpEU1VoTk1HOW5TMFZKUTBGblNVUlllRXBIVFVoUkVBReABAPoBBAgAEA0!16s%2Fg%2F11h7vqj9rs?entry=ttu&g_ep=EgoyMDI2MTAwNS4wIKXMDSoASAFQAw%3D%3D

Facade color, roof type, portico rhythm and signage follow inspected photographs where available. Photo appearance may be historic. Dimensions are reconstruction estimates. Downloaded reference photos are excluded from the release; original sign artwork and materials are newly made. Google Images was traffic-blocked. Google Maps ordinary photos were usable; clicking a Street View-labelled station tile sometimes opened still photos. No actual Street View panorama is claimed unless a separate evidence entry explicitly records it.

## Platform bodies
- Body1: 1; IRI platform count; reconstructed extent/width; source ways none.

## Dimensions and coordinate system
- Local origin: longitude 76.34194, latitude 9.4234 (source station locator, not a survey monument).
- Local +Y follows mapped corridor northward, using EN north-vector [-0.2427561042092239, 0.9700873537311784]; +X is perpendicular.
- Adopted mapping window: [-230.0, -1150.0, 230.0, 1150.0]m. Mapped approaches are retained throughout this window, including loop joins and sidings; clipping at the window is documented rather than fabricated continuations.
- Enclosed building envelope in the mapped scene: approximately 7.26m across track × 13.24m along track, at [-0.7436313947864663, 2.9026690735767553]. Original source footprint, if any, retained separately. For TNU this0m corridor envelope deliberately excludes the separate unplaced historical15.5×6.8×4.78m building study.
- Track gauge:1.676m. Railhead centers±0.868m, tread width60mm. Visual wheel-flange channels45mm.
- Rail top0.635m, platform top1.45m, contact wire6.30m. These are plausible reconstructed model dimensions, not certified construction tolerances.

## Reconstructed elements and limits
Unseen rooms, interior partitions, furniture placement, ticket-office equipment, toilets, fans, lamps, drainage fittings, roof supports, accessibility ramp, canopy/footbridge positions, signal positions, electrical equipment and vegetation are reconstructed. Small halts receive compact rooms and modest amenities; no large concourse is invented. Interiors are furnished for inspectability, without claiming access to private operational areas. All geometry is editable.

Station-specific cautions:


## QA and lineage
QA_BUILD.json records scene counts, source-plan checksum, packed resources and the Blender checksum. Each render has a paired JSON with camera, source checksum and render settings. Manifest hashes identify the exact released files. Independent QA status is supplied separately; a successful render alone is not a blanket accuracy certification. Source railway-plan data and architecture estimates are intentionally distinguished.

## Attribution
Railway map data © OpenStreetMap contributors, ODbL1.0: https://www.openstreetmap.org/copyright . The derived source plan is retained in references/plan.json. Station metadata cites India Rail Info and the source register. Photographs remain with their owners and are linked as research references, not redistributed. Original models, textures and signage generated for this project. Noto fonts are used for original raster lettering under SIL Open Font License; no font binary is bundled.
