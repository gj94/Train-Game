# Viranialur (VRLR) • complete station environment v01

Editable full-size Blender scene, five rendered review views, and a self-contained portable glTF archive. No trains or other rolling stock.

## Files
- VRLR_station_v01.blend: authoritative editable scene, materials, cameras and packed font resources
- renders/: full network, station architecture, platform/track view, furnished interior, railway detail
- exchange/VRLR_portable_GLTF.zip: losslessly archived GLB, verified against the raw export
- SOURCES.json: evidence links, dates and limitations
- QA_BUILD.json, QA_EXPORT.json and RENDER_PROVENANCE.json: measured model properties and exact source/render/export hashes
- source/: metric source-derived geometry, available native name outlines and documentary build/repair recipes

Recipe snapshots document the construction and narrow repairs. The packed scene is authoritative; these scripts are not a standalone one-click rebuild and refer to the region staging layout and shared locked Blender launcher.

## Scale and coverage
Metres, scene scale1.0. Broad-gauge running head inner faces1.676m apart. Modeled platform bodies: 2; IRI reported platform positions: 1. Source snapshot includes 2 clipped rail-way pieces, not a certified count of physical roads. Full source-specific curves, connected loops and separately mapped sidings are retained within the documented approach envelope. Platforms are not shortened decorative modules. Furniture, water points, lights, signs, waiting/ticket or appropriate service interiors, structural roof members, overhead lines, ballast/sleepers/fasteners, and relevant footbridge/stair connections are modelled.

The source scene has 887 objects, 459,141 mesh vertices and 5,705 sleeper/support placements. Rail-network local bounds: [-850.0, -1.1500826997789177, 850.0, 95.41828095975583]. Nominal dimensions are explicit modelling choices, not an engineering survey.

## What is observed and what is reconstructed
Google Maps Gouse Basha S May2023 shallow red shelters on thin pale posts with flared pastel bases/red rims and a cream/yellow water basin. Two built opposing bodies and bridge follow later undated satellite; their operation is unverified. No unobserved ticket-building facade or large concourse is invented.

Two opposing physically built bodies and the footbridge are represented from Google satellite, even though IRI/Wikipedia report1. Operation/commissioning of both bodies is unverified. Old OSM construction tags may be stale after reported2026 doubling.

Maps contain mixed historical edit dates. An OSM edit date, Google copyright year or photo upload date is not a construction or commissioning date. Buildings, shelter spans, unmeasured platform dimensions and hidden rooms/fixtures are reconstructed. This is a source-informed visual asset, not an as-built survey, operational railway inventory, safety certificate or railway-engineering design. Signals, switch details, model clearances and service assignments are illustrative. Geometric rail-channel checks do not certify real wheel/rail operation. Compound pointwork remains simplified where the exact design is unknown.

The 45mm geometric flange channels, unioned running heads, tapered blade components and reconstructed crossing bearers avoid duplicated rail overlays in the adopted model. Procedural material noise/bump is native Blender shading. The portable glTF preserves geometry and base material properties, but those procedural textures are not baked.

## Source references
- https://www.google.com/maps/place/Virani+Alur/@8.1941177,77.3679473,3a,75y,90t/data=!3m8!1e2!3m6!1sCIHM0ogKEICAgICx2f2oCw!2e10!3e12!6shttps:%2F%2Flh3.googleusercontent.com%2Fgps-cs-s%2FAHRPTWnx5S6VBlKGcO0jWNUyv9FZ8rTw9n6b-QD6kaOek5lu8alQTXIXcWHo9TbbqSXJRf6d0NI0ORmhI8rbPQegN_b43UUXsonIn90JvH0m9NfbW5Xe3F0Tt81rbL6xdUDmbdNB7l6N%3Dw203-h152-k-no!7i4096!8i3072!4m7!3m6!1s0x3b04fa02c4748933:0x7b4185fa9dfc38b!8m2!3d8.1943656!4d77.3678545!10e5!16s%2Fm%2F0fp_k5k?entry=ttu&g_ep=EgoyMDI2MTAwNS4wIKXMDSoASAFQAw%3D%3D | May 2023 | Ordinary contributor photograph of platform shelter
- https://www.google.com/maps/place/Virani+Alur/@8.1943709,77.3671142,225m/data=!3m1!1e3!4m6!3m5!1s0x3b04fa02c4748933:0x7b4185fa9dfc38b!8m2!3d8.1943656!4d77.3678545!16s%2Fm%2F0fp_k5k?entry=ttu&g_ep=EgoyMDI2MTAwNS4wIKXMDSoASAFQAw%3D%3D | satellite acquisition date not exposed; observation accessed2026-10-08
- https://api.openstreetmap.org/api/0.6/map?bbox=77.3596992,8.1856449,77.3776992,8.2036449 | OSM snapshot accessed2026-10-08; original way dates retained in source/layout.json
- https://d.indiarailinfo.com/station/map/virani-alur-vrlr/4792 | IRI profile cross-check accessed2026-10-08; reported totals are secondary and not a signed current yard plan

## Rights
Map-derived geometry © OpenStreetMap contributors, available under ODbL1.0: https://www.openstreetmap.org/copyright and https://opendatacommons.org/licenses/odbl/1-0/ . Preserve attribution and applicable derived-database obligations. No new licence is claimed for third-party source material. No Google/photographer screenshots, station photographs or copied photo textures are distributed in this package. Authoring geometry is newly generated for this request. DejaVu and Noto lettering uses locally installed freely licensed fonts; see THIRD_PARTY_NOTICES.txt.
