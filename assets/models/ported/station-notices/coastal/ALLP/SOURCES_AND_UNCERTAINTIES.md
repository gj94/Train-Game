# ALLP · Alappuzha | Coastal railway station reconstruction

## What is delivered
Full-scale metre scene with no trains or rolling stock. Packed Blender file, lossless portable GLB export when available, and rendered views derived from the frozen Blender scene. Current snapshot review date:2026-10-08. This is a useful visual reconstruction, not a surveyed as-built or certified operating layout.

## Station evidence and scope
- Status: Listed current by SR2025; no subsequent closure found
- IRI-reported platform faces: 3 (Reported platform positions; not independently verified current operational inventory)
- IRI source: https://indiarailinfo.com/station/map/alappuzha-alleppey-allp/54
- Official chainage if supplied: 57.00 km, datum ERS via ALLP.
- Mapped roads at station transect: 6; mapped rail segments in scene: 13; combined mapped route length: 7577.5m.
- Mapped description: Body 1 ref1; islandbody 2 refs2&3. Three passenger-adjacent roads plus three west-side serviceyard paths cross locator transect; one service path shorter than full yard. Service neck extends far south; total yardroad count depends on treatment of that continuation. South serviceway has passenger_lines=2 despite single physical geometry; do not count this tag as tracks.
- Source edit dates: 2018-11-04T15:21:43Z / 2024-08-27T03:18:47Z. An OSM edit timestamp is not a survey date.
- Current loops/sidings totals: NOT VERIFIED. The actual adopted OSM paths are modeled; service tags are preserved. A tag service=siding can describe a both-ended loop.
- Proposed/construction ways excluded. No extra operational running line inferred from line-doubling projects.

## Architecture source
https://static2.tripoto.com/media/filter/tst/img/165685/TripDocument/1474791688_img_20160902_064804.jpg

Additional actually inspected source records in references/architecture_google_evidence.json:
- https://www.google.com/maps/place/Alappuzha+Railway+Station/@9.4837254,76.3226877,3a,75y,90t/data=!3m8!1e2!3m6!1sCIABIhDD_VGUfUyb4_NpNxmnfkfQ!2e10!3e12!6shttps:%2F%2Flh3.googleusercontent.com%2Fgps-cs-s%2FAHRPTWkrdkY39sXU1doiA9DQ3zo5k2g5U8hsEK3OTKpo_HtSnqn2_4TVKNEE3V5-Ft7aoTdEL3yydxkQAKss3mBsJ53XfxCAoKwXqe1IVNNvnXA2_NCofRn7Y7wlKxdGJUprlbYvgreHua-C3n1b%3Dw203-h152-k-no!7i3264!8i2448!4m11!1m2!2m1!1sAlappuzha+railway+station!3m7!1s0x3b0884e368555555:0x22c5f93b4b2b6fb3!8m2!3d9.4836002!4d76.3222995!10e5!15sChlBbGFwcHV6aGEgcmFpbHdheSBzdGF0aW9ukgEXbG9naWNhbF90cmFuc2l0X3N0YXRpb27gAQA!16s%2Fm%2F0ynrkgj?entry=ttu&g_ep=EgoyMDI2MTAwNS4wIKXMDSoASAFQAw%3D%3D
- https://www.google.com/maps/place/Alappuzha+Railway+Station/@9.4837254,76.3226877,3a,75y,90t/data=!3m8!1e2!3m6!1sCIHM0ogKEICAgICW093erQE!2e10!3e12!6shttps:%2F%2Flh3.googleusercontent.com%2Fgps-cs-s%2FAHRPTWmVENX7qL-cm0jqfHJQnYoHUKYyq43C_vSlIfl9mFtA3XV__EgPc0VOnoBO1U4QM41Uvrt7sz4QhygItMKHv4Rt_sTrUwvDkxz1_98Gm6hRJvhtt9bBhGGiRYnrSA724HVKQfCZ%3Dw203-h152-k-no!7i4608!8i3456!4m11!1m2!2m1!1sAlappuzha+railway+station!3m7!1s0x3b0884e368555555:0x22c5f93b4b2b6fb3!8m2!3d9.4836002!4d76.3222995!10e5!15sChlBbGFwcHV6aGEgcmFpbHdheSBzdGF0aW9ukgEXbG9naWNhbF90cmFuc2l0X3N0YXRpb27gAQA!16s%2Fm%2F0ynrkgj?entry=ttu&g_ep=EgoyMDI2MTAwNS4wIKXMDSoASAFQAw%3D%3D
- https://www.google.com/maps/place/Alappuzha+Railway+Station/@9.4837254,76.3226877,3a,75y,90t/data=!3m8!1e2!3m6!1sCIHM0ogKEICAgID9kOb6kAE!2e10!3e12!6shttps:%2F%2Flh3.googleusercontent.com%2Fgps-cs-s%2FAHRPTWldE5NHU-0iByLR2hsKx1ejdM5iLcIf8Cg1u3YyAeVBXu7dDbi6dz5LGRZ7o_WpfZMzfJvDnb3e2RT7hgPhWroga_9w-xH8ZMkI1fI5f-6T5Yx_ff0C4eBi__xMZYNzHn08KgnuEg%3Dw203-h114-k-no!7i4000!8i2250!4m11!1m2!2m1!1sAlappuzha+railway+station!3m7!1s0x3b0884e368555555:0x22c5f93b4b2b6fb3!8m2!3d9.4836002!4d76.3222995!10e5!15sChlBbGFwcHV6aGEgcmFpbHdheSBzdGF0aW9ukgEXbG9naWNhbF90cmFuc2l0X3N0YXRpb27gAQA!16s%2Fm%2F0ynrkgj?entry=ttu&g_ep=EgoyMDI2MTAwNS4wIKXMDSoASAFQAw%3D%3D
- https://www.google.com/maps/place/Alappuzha+Railway+Station/@9.4836002,76.3222995,3a,75y,90t/data=!3m8!1e2!3m6!1sCIHM0ogKEICAgICsyf_w2gE!2e10!3e12!6shttps:%2F%2Flh3.googleusercontent.com%2Fgps-cs-s%2FAHRPTWn3CrxM9dLxHHX_zbQ__Wfa4riBHQF4P-OTirTLeGqi4Ck2jpIzgQGy3flF8XeMUNNCxoyKFGgTvRLEtuWtVT8M5ZoxStO7S2iQs_KXQ4rauwHgCQM_Xy3LWZcaFIisAEuWTDTo%3Dw203-h202-k-no!7i2422!8i2421!4m11!1m2!2m1!1sAlappuzha+railway+station!3m7!1s0x3b0884e368555555:0x22c5f93b4b2b6fb3!8m2!3d9.4836002!4d76.3222995!10e5!15sChlBbGFwcHV6aGEgcmFpbHdheSBzdGF0aW9ukgEXbG9naWNhbF90cmFuc2l0X3N0YXRpb27gAQA!16s%2Fm%2F0ynrkgj?entry=ttu&g_ep=EgoyMDI2MTAwNS4wIKXMDSoASAFQAw%3D%3D

Facade color, roof type, portico rhythm and signage follow inspected photographs where available. Photo appearance may be historic. Dimensions are reconstruction estimates. Downloaded reference photos are excluded from the release; original sign artwork and materials are newly made. Google Images was traffic-blocked. Google Maps ordinary photos were usable; clicking a Street View-labelled station tile sometimes opened still photos. No actual Street View panorama is claimed unless a separate evidence entry explicitly records it.

## Platform bodies
- Body1: 2 & 3; OSM area footprint; source ways ['649481298'].
- Body2: 1; OSM area footprint; source ways ['649481297'].

## Dimensions and coordinate system
- Local origin: longitude 76.3223403, latitude 9.4846528 (source station locator, not a survey monument).
- Local +Y follows mapped corridor northward, using EN north-vector [-0.23440461521064146, 0.972139123977608]; +X is perpendicular.
- Adopted mapping window: [-230.0, -1150.0, 230.0, 1150.0]m. Mapped approaches are retained throughout this window, including loop joins and sidings; clipping at the window is documented rather than fabricated continuations.
- Enclosed building envelope in the mapped scene: approximately 15.33m across track × 106.88m along track, at [2.3880533657438594, -0.0014108848709639688]. Original source footprint, if any, retained separately. For TNU this0m corridor envelope deliberately excludes the separate unplaced historical15.5×6.8×4.78m building study.
- Track gauge:1.676m. Railhead centers±0.868m, tread width60mm. Visual wheel-flange channels45mm.
- Rail top0.635m, platform top1.45m, contact wire6.30m. These are plausible reconstructed model dimensions, not certified construction tolerances.

## Reconstructed elements and limits
Unseen rooms, interior partitions, furniture placement, ticket-office equipment, toilets, fans, lamps, drainage fittings, roof supports, accessibility ramp, canopy/footbridge positions, signal positions, electrical equipment and vegetation are reconstructed. Small halts receive compact rooms and modest amenities; no large concourse is invented. Interiors are furnished for inspectability, without claiming access to private operational areas. All geometry is editable.

Station-specific cautions:
- Pedestrian bridge: Mapped pedestrian bridge centerline, exact source retained; height/structure reconstructed https://www.openstreetmap.org/way/901863259
- Source roof/building envelope partly overlaps platform. Enclosed hall shifted outside platform by geometric clearance; source footprint retained unchanged. Not a surveyed correction.

## QA and lineage
QA_BUILD.json records scene counts, source-plan checksum, packed resources and the Blender checksum. Each render has a paired JSON with camera, source checksum and render settings. Manifest hashes identify the exact released files. Independent QA status is supplied separately; a successful render alone is not a blanket accuracy certification. Source railway-plan data and architecture estimates are intentionally distinguished.

## Attribution
Railway map data © OpenStreetMap contributors, ODbL1.0: https://www.openstreetmap.org/copyright . The derived source plan is retained in references/plan.json. Station metadata cites India Rail Info and the source register. Photographs remain with their owners and are linked as research references, not redistributed. Original models, textures and signage generated for this project. Noto fonts are used for original raster lettering under SIL Open Font License; no font binary is bundled.
