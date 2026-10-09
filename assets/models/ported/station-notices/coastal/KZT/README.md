# Kulitturai (KZT) • complete station environment v01

Editable full-size Blender scene, five rendered review views, and a self-contained portable glTF archive. No trains or other rolling stock.

## Files
- KZT_station_v01.blend: authoritative editable scene, materials, cameras and packed font resources
- renders/: full network, station architecture, platform/track view, furnished interior, railway detail
- exchange/KZT_portable_GLTF.zip: losslessly archived GLB, verified against the raw export
- SOURCES.json: evidence links, dates and limitations
- QA_BUILD.json, QA_EXPORT.json and RENDER_PROVENANCE.json: measured model properties and exact source/render/export hashes
- source/: metric source-derived geometry, available native name outlines and documentary build/repair recipes

Recipe snapshots document the construction and narrow repairs. The packed scene is authoritative; these scripts are not a standalone one-click rebuild and refer to the region staging layout and shared locked Blender launcher.

## Scale and coverage
Metres, scene scale1.0. Broad-gauge running head inner faces1.676m apart. Modeled platform bodies: 2; IRI reported platform positions: 2. Source snapshot includes 4 clipped rail-way pieces, not a certified count of physical roads. Full source-specific curves, connected loops and separately mapped sidings are retained within the documented approach envelope. Platforms are not shortened decorative modules. Furniture, water points, lights, signs, waiting/ticket or appropriate service interiors, structural roof members, overhead lines, ballast/sleepers/fasteners, and relevant footbridge/stair connections are modelled.

The source scene has 941 objects, 491,694 mesh vertices and 4,766 sleeper/support placements. Rail-network local bounds: [-850.0, -13.449653188470931, 850.0, 348.59434975047697]. Nominal dimensions are explicit modelling choices, not an engineering survey.

## What is observed and what is reconstructed
Google Maps Ajin Singh M L January2024 turquoise arched parapet and white jali facade; Praveen Raj July2025 platform interior with pale plate-steel butterfly canopy, maroon doors, red/yellow paving, stainless ramps and basin around column. Detailed hidden room layouts remain reconstructed.



Maps contain mixed historical edit dates. An OSM edit date, Google copyright year or photo upload date is not a construction or commissioning date. Buildings, shelter spans, unmeasured platform dimensions and hidden rooms/fixtures are reconstructed. This is a source-informed visual asset, not an as-built survey, operational railway inventory, safety certificate or railway-engineering design. Signals, switch details, model clearances and service assignments are illustrative. Geometric rail-channel checks do not certify real wheel/rail operation. Compound pointwork remains simplified where the exact design is unknown.

The 45mm geometric flange channels, unioned running heads, tapered blade components and reconstructed crossing bearers avoid duplicated rail overlays in the adopted model. Procedural material noise/bump is native Blender shading. The portable glTF preserves geometry and base material properties, but those procedural textures are not baked.

## Source references
- https://www.google.com/maps/place/Kulitturai/@8.301441,77.2180258,3a,75y,90t/data=!3m8!1e2!3m6!1sCIABIhAkdGbC5-bTZvqbbbkHp99E!2e10!3e12!6shttps:%2F%2Flh3.googleusercontent.com%2Fgps-cs-s%2FAHRPTWmrO5pomEzC5QqSASqGhFy_eR8wMxUqVbp-dbIlQfQMJLZa12kaar7Pjm8l9jw_evZPY4i4w9mo45BsEfDnujpJBEsoyVJSpbVuSsCwqSWovoQNlisLDUPLai5GrrUtxcQRIPNWskc8Txc7%3Dw203-h152-k-no!7i4608!8i3456!4m11!1m2!2m1!1sKulitturai+railway+station!3m7!1s0x3b0455159f1df7b3:0x4a6dc1b394210207!8m2!3d8.3013149!4d77.2186943!10e5!15sChpLdWxpdHR1cmFpIHJhaWx3YXkgc3RhdGlvbpIBDXRyYWluX3N0YXRpb27gAQA!16s%2Fm%2F0fq1lpx?entry=ttu&g_ep=EgoyMDI2MTAwNS4wIKXMDSoASAFQAw%3D%3D | Jul 2025 | Ordinary contributor photograph of sheltered platform and public-room frontage
- https://www.google.com/maps/place/Kulitturai/@8.301441,77.2180258,3a,75y,90t/data=!3m8!1e2!3m6!1sCIHM0ogKEICAgIDNu5iaHQ!2e10!3e12!6shttps:%2F%2Flh3.googleusercontent.com%2Fgps-cs-s%2FAHRPTWmjPSW8ont0LKYkGJPIffpBX_lkMyWgXXtQ5SGDT1LONq9znqBcf8MjFZhIh1hMMOwHqazBIx5kLum-ymAunSWXyDPOakiCDectqBhJY9P_nhRlMn3KJZMwpZReJMxEp4Rzob0%3Dw203-h152-k-no!7i4608!8i3456!4m11!1m2!2m1!1sKulitturai+railway+station!3m7!1s0x3b0455159f1df7b3:0x4a6dc1b394210207!8m2!3d8.3013149!4d77.2186943!10e5!15sChpLdWxpdHR1cmFpIHJhaWx3YXkgc3RhdGlvbpIBDXRyYWluX3N0YXRpb27gAQA!16s%2Fm%2F0fq1lpx?entry=ttu&g_ep=EgoyMDI2MTAwNS4wIKXMDSoASAFQAw%3D%3D | Jan 2024 | Ordinary contributor photograph of main road facade

- https://api.openstreetmap.org/api/0.6/map?bbox=77.2098170,8.2933480,77.2278170,8.3113480 | OSM snapshot accessed2026-10-08; original way dates retained in source/layout.json
- https://indiarailinfo.com/station/map/803?a=1 | IRI profile cross-check accessed2026-10-08; reported totals are secondary and not a signed current yard plan

## Rights
Map-derived geometry © OpenStreetMap contributors, available under ODbL1.0: https://www.openstreetmap.org/copyright and https://opendatacommons.org/licenses/odbl/1-0/ . Preserve attribution and applicable derived-database obligations. No new licence is claimed for third-party source material. No Google/photographer screenshots, station photographs or copied photo textures are distributed in this package. Authoring geometry is newly generated for this request. DejaVu and Noto lettering uses locally installed freely licensed fonts; see THIRD_PARTY_NOTICES.txt.
