# Kulitturai West (KZTW) • complete station environment v01

Editable full-size Blender scene, five rendered review views, and a self-contained portable glTF archive. No trains or other rolling stock.

## Files
- KZTW_station_v01.blend: authoritative editable scene, materials, cameras and packed font resources
- renders/: full network, station architecture, platform/track view, furnished interior, railway detail
- exchange/KZTW_portable_GLTF.zip: losslessly archived GLB, verified against the raw export
- SOURCES.json: evidence links, dates and limitations
- QA_BUILD.json, QA_EXPORT.json and RENDER_PROVENANCE.json: measured model properties and exact source/render/export hashes
- source/: metric source-derived geometry, available native name outlines and documentary build/repair recipes

Recipe snapshots document the construction and narrow repairs. The packed scene is authoritative; these scripts are not a standalone one-click rebuild and refer to the region staging layout and shared locked Blender launcher.

## Scale and coverage
Metres, scene scale1.0. Broad-gauge running head inner faces1.676m apart. Modeled platform bodies: 1; IRI reported platform positions: 1. Source snapshot includes 3 clipped rail-way pieces, not a certified count of physical roads. Full source-specific curves, connected loops and separately mapped sidings are retained within the documented approach envelope. Platforms are not shortened decorative modules. Furniture, water points, lights, signs, waiting/ticket or appropriate service interiors, structural roof members, overhead lines, ballast/sleepers/fasteners, and relevant footbridge/stair connections are modelled.

The source scene has 669 objects, 229,385 mesh vertices and 3,050 sleeper/support placements. Rail-network local bounds: [-850.0, -238.64007992230708, 850.0, 262.18325723614504]. Nominal dimensions are explicit modelling choices, not an engineering survey.

## What is observed and what is reconstructed
Google Maps Suresh Sri December2017 small cream/yellow three-bay block, rear picket fence and green platform fascia. Block function and hidden interiors are unverified/reconstructed; no large concourse or sidings invented.



Maps contain mixed historical edit dates. An OSM edit date, Google copyright year or photo upload date is not a construction or commissioning date. Buildings, shelter spans, unmeasured platform dimensions and hidden rooms/fixtures are reconstructed. This is a source-informed visual asset, not an as-built survey, operational railway inventory, safety certificate or railway-engineering design. Signals, switch details, model clearances and service assignments are illustrative. Geometric rail-channel checks do not certify real wheel/rail operation. Compound pointwork remains simplified where the exact design is unknown.

The 45mm geometric flange channels, unioned running heads, tapered blade components and reconstructed crossing bearers avoid duplicated rail overlays in the adopted model. Procedural material noise/bump is native Blender shading. The portable glTF preserves geometry and base material properties, but those procedural textures are not baked.

## Source references
- https://www.google.com/maps/place/Kulitturai+West/@8.324058,77.208864,3a,75y,90t/data=!3m8!1e2!3m6!1sCIHM0ogKEICAgID4qrPWaw!2e10!3e12!6shttps:%2F%2Flh3.googleusercontent.com%2Fgrass-cs%2FACvplmNsd2_WkHxqhjo0NEe23Aqgg2WJZZ8CrbXV09fDRSpaj4xh64vMtlZ1tyMU6_QXIiVlqJwgLeL0-LlvEDSLm0KI2pOkzhlnNgS82aDHl54LRfJ5eU0u-Ycg-YPUcaWhVAY8EKr5%3Dw114-h86-k-no!7i4128!8i3096!4m7!3m6!1s0x3b0454d96dc6431b:0x7f60fb6d0f97a81!8m2!3d8.324058!4d77.208864!10e5!16s%2Fg%2F1tfnx07k?entry=ttu&g_ep=EgoyMDI2MTAwNS4wIKXMDSoASAFQAw%3D%3D | December 2017 | Ordinary contributor photograph

- https://api.openstreetmap.org/api/0.6/map?bbox=77.2007920,8.3147340,77.2187920,8.3327340 | OSM snapshot accessed2026-10-08; original way dates retained in source/layout.json
- https://d.indiarailinfo.com/station/map/2775 | IRI profile cross-check accessed2026-10-08; reported totals are secondary and not a signed current yard plan

## Rights
Map-derived geometry © OpenStreetMap contributors, available under ODbL1.0: https://www.openstreetmap.org/copyright and https://opendatacommons.org/licenses/odbl/1-0/ . Preserve attribution and applicable derived-database obligations. No new licence is claimed for third-party source material. No Google/photographer screenshots, station photographs or copied photo textures are distributed in this package. Authoring geometry is newly generated for this request. DejaVu and Noto lettering uses locally installed freely licensed fonts; see THIRD_PARTY_NOTICES.txt.
