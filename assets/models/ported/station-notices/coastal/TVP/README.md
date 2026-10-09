# Thiruvananthapuram Pettah (TVP) • complete station environment v01

Editable full-size Blender scene, five rendered review views, and a self-contained portable glTF archive. No trains or other rolling stock.

## Files
- TVP_station_v01.blend: authoritative editable scene, materials, cameras and packed font resources
- renders/: full network, station architecture, platform/track view, furnished interior, railway detail
- exchange/TVP_portable_GLTF.zip: losslessly archived GLB, verified against the raw export
- SOURCES.json: evidence links, dates and limitations
- QA_BUILD.json, QA_EXPORT.json and RENDER_PROVENANCE.json: measured model properties and exact source/render/export hashes
- source/: metric source-derived geometry, available native name outlines and documentary build/repair recipes

Recipe snapshots document the construction and narrow repairs. The packed scene is authoritative; these scripts are not a standalone one-click rebuild and refer to the region staging layout and shared locked Blender launcher.

## Scale and coverage
Metres, scene scale1.0. Broad-gauge running head inner faces1.676m apart. Modeled platform bodies: 2; IRI reported platform positions: 2. Source snapshot includes 2 clipped rail-way pieces, not a certified count of physical roads. Full source-specific curves, connected loops and separately mapped sidings are retained within the documented approach envelope. Platforms are not shortened decorative modules. Furniture, water points, lights, signs, waiting/ticket or appropriate service interiors, structural roof members, overhead lines, ballast/sleepers/fasteners, and relevant footbridge/stair connections are modelled.

The source scene has 850 objects, 493,505 mesh vertices and 5,988 sleeper/support placements. Rail-network local bounds: [-850.0, -346.3205065838997, 850.0, -17.753606635483777]. Nominal dimensions are explicit modelling choices, not an engineering survey.

## What is observed and what is reconstructed
Google Maps Nijin February2020 long low red-roof platform frontage, golden-yellow columns; undated satellite northeast building and northwest bridge.



Maps contain mixed historical edit dates. An OSM edit date, Google copyright year or photo upload date is not a construction or commissioning date. Buildings, shelter spans, unmeasured platform dimensions and hidden rooms/fixtures are reconstructed. This is a source-informed visual asset, not an as-built survey, operational railway inventory, safety certificate or railway-engineering design. Signals, switch details, model clearances and service assignments are illustrative. Geometric rail-channel checks do not certify real wheel/rail operation. Compound pointwork remains simplified where the exact design is unknown.

The 45mm geometric flange channels, unioned running heads, tapered blade components and reconstructed crossing bearers avoid duplicated rail overlays in the adopted model. Procedural material noise/bump is native Blender shading. The portable glTF preserves geometry and base material properties, but those procedural textures are not baked.

## Source references
- https://www.google.com/maps/place/Thiruvananthapuram+Pettah/@8.4951769,76.9316934,224m/data=!3m1!1e3!4m10!1m2!2m1!1sThiruvananthapuram+Pettah+railway+station!3m6!1s0x3b05bb905af9eee7:0x31ad0e09421c5423!8m2!3d8.4950165!4d76.931783!15sCilUaGlydXZhbmFudGhhcHVyYW0gUGV0dGFoIHJhaWx3YXkgc3RhdGlvblorIil0aGlydXZhbmFudGhhcHVyYW0gcGV0dGFoIHJhaWx3YXkgc3RhdGlvbpIBDXRyYWluX3N0YXRpb26aAURDaTlEUVVsUlFVTnZaRU5vZEhsalJqbHZUMnhHZVZOdVRuSmhSMHB0VVZaUk5WSjZVblZOUjNSMVQxZGtjbGRIWXhBQuABAPoBBAgAEEc!16s%2Fm%2F0cz9m9v?entry=ttu&g_ep=EgoyMDI2MTAwNS4wIKXMDSoASAFQAw%3D%3D | Not exposed | Google Maps satellite visually inspected
- https://www.google.com/maps/place/Thiruvananthapuram+Pettah/@8.4950165,76.931783,3a,75y,90t/data=!3m8!1e2!3m6!1sCIHM0ogKEICAgICsi-6ZWA!2e10!3e12!6shttps:%2F%2Flh3.googleusercontent.com%2Fgrass-cs%2FACvplmPvNw8-9-yyoQve8tS5rGRz9IvtHXqY5JkCb7ANd9xj-Key1lzPoqHnhpolGNw3aMJ8_1scyDWSLNBuhW1OgJDMms72yztSo1Kb9tfM874OrkmpbCeGoE48VutXaoaTfH0nYONx%3Dw114-h86-k-no!7i3264!8i2448!4m11!1m2!2m1!1sThiruvananthapuram+Pettah+railway+station!3m7!1s0x3b05bb905af9eee7:0x31ad0e09421c5423!8m2!3d8.4950165!4d76.931783!10e5!15sCilUaGlydXZhbmFudGhhcHVyYW0gUGV0dGFoIHJhaWx3YXkgc3RhdGlvblorIil0aGlydXZhbmFudGhhcHVyYW0gcGV0dGFoIHJhaWx3YXkgc3RhdGlvbpIBDXRyYWluX3N0YXRpb26aAURDaTlEUVVsUlFVTnZaRU5vZEhsalJqbHZUMnhHZVZOdVRuSmhSMHB0VVZaUk5WSjZVblZOUjNSMVQxZGtjbGRIWXhBQuABAPoBBAgAEEc!16s%2Fm%2F0cz9m9v?entry=ttu&g_ep=EgoyMDI2MTAwNS4wIKXMDSoASAFQAw%3D%3D | Feb 2020 | Ordinary contributor photograph of platform-facing station building

- https://api.openstreetmap.org/api/0.6/map?bbox=76.9226730,8.4855240,76.9406730,8.5035240 | OSM snapshot accessed2026-10-08; original way dates retained in source/layout.json
- https://d.indiarailinfo.com/station/map/2532?a=1 | IRI profile cross-check accessed2026-10-08; reported totals are secondary and not a signed current yard plan

## Rights
Map-derived geometry © OpenStreetMap contributors, available under ODbL1.0: https://www.openstreetmap.org/copyright and https://opendatacommons.org/licenses/odbl/1-0/ . Preserve attribution and applicable derived-database obligations. No new licence is claimed for third-party source material. No Google/photographer screenshots, station photographs or copied photo textures are distributed in this package. Authoring geometry is newly generated for this request. DejaVu and Noto lettering uses locally installed freely licensed fonts; see THIRD_PARTY_NOTICES.txt.
