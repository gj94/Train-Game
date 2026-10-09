# Perunguzhi (PGZ) • complete station environment v01

Editable full-size Blender scene, five rendered review views, and a self-contained portable glTF archive. No trains or other rolling stock.

## Files
- PGZ_station_v01.blend: authoritative editable scene, materials, cameras and packed font resources
- renders/: full network, station architecture, platform/track view, furnished interior, railway detail
- exchange/PGZ_portable_GLTF.zip: losslessly archived GLB, verified against the raw export
- SOURCES.json: evidence links, dates and limitations
- QA_BUILD.json, QA_EXPORT.json and RENDER_PROVENANCE.json: measured model properties and exact source/render/export hashes
- source/: metric source-derived geometry, native name outlines and documentary build recipe

## Scale and coverage
Metres, scene scale1.0. Broad-gauge running head inner faces1.676m apart. Modeled platform bodies: 2; IRI reported platform positions: 2. Source snapshot includes 2 clipped rail-way pieces, not a certified count of physical roads. Full source-specific curves, connected loops and separately mapped sidings are retained within the documented approach envelope. Platforms are not shortened decorative modules. Furniture, water points, lights, signs, waiting/ticket or appropriate service interiors, structural roof members, overhead lines, ballast/sleepers/fasteners, and relevant footbridge/stair connections are modelled.

The source scene has 824 objects, 436,550 mesh vertices and 5,803 sleeper/support placements. Rail-network local bounds: [-850.0, -95.99761793574018, 850.0, 120.79229574490533]. Nominal dimensions are explicit modelling choices, not an engineering survey.

## What is observed and what is reconstructed
Google Maps contributor Josy anand, February 2020; small flat-roof hut and railed ramp system. Position approximate relative to route marker; hidden interior reconstructed.



Maps contain mixed historical edit dates. An OSM edit date, Google copyright year or photo upload date is not a construction or commissioning date. Buildings, shelter spans, unmeasured platform dimensions and hidden rooms/fixtures are reconstructed. This is a source-informed visual asset, not an as-built survey, operational railway inventory, safety certificate or railway-engineering design. Signals, switch details, model clearances and service assignments are illustrative. Geometric rail-channel checks do not certify real wheel/rail operation. Compound pointwork remains simplified where the exact design is unknown.

The 45mm geometric flange channels, unioned running heads, tapered blade components and reconstructed crossing bearers avoid duplicated rail overlays in the adopted model. Procedural material noise/bump is native Blender shading. The portable glTF preserves geometry and base material properties, but those procedural textures are not baked.

## Source references
- https://www.google.com/maps/place/Perunguzhi/@8.6330304,76.8076046,3a,75y,90t/data=!3m8!1e2!3m6!1sCIHM0ogKEICAgICcxozseg!2e10!3e12!6shttps:%2F%2Flh3.googleusercontent.com%2Fgps-cs-s%2FAHRPTWmJjINhsaaJWtFmAEmIWEI5PF9MJXL3I9INIq-bqspQM0pyWEX46I3RN1dhDtMEUh1zHEk4VSw8Lzji-NnFSwtHGlXV1wPieGxJhThkIfRSS45oZ7iUmgxn1lxtqZTGSdAiAByT%3Dw203-h145-k-no!7i2048!8i1463!4m7!3m6!1s0x3b05ea9425ea1a05:0xb3ec32aecf5b7c4d!8m2!3d8.6330304!4d76.8076046!10e5!16s%2Fg%2F1td1hd_r?entry=ttu&g_ep=EgoyMDI2MTAwNS4wIKXMDSoASAFQAw%3D%3D | Feb 2020 | Ordinary contributor photograph of ticket hut and accessible approach
- https://www.google.com/maps/place/Perunguzhi/@8.6330304,76.8076046,3a,75y,90t/data=!3m8!1e2!3m6!1sCIHM0ogKEICAgIDE8rr7Kw!2e10!3e12!6shttps:%2F%2Flh3.googleusercontent.com%2Fgps-cs-s%2FAHRPTWlWfPOXNasL6wo5gscWK5iXu2UkHnLjHX6x68ooWsa9GFHVkg3839t7ekSBy6wXCMLmNEFqmDnX_47YmPzcuspyFUor5EDr3ls3Da36rlN2BejjHPDT8TDn1Wdthrbj-wKGvv8q%3Dw203-h135-k-no!7i1800!8i1200!4m7!3m6!1s0x3b05ea9425ea1a05:0xb3ec32aecf5b7c4d!8m2!3d8.6330304!4d76.8076046!10e5!16s%2Fg%2F1td1hd_r?entry=ttu&g_ep=EgoyMDI2MTAwNS4wIKXMDSoASAFQAw%3D%3D | Dec 2016 | Ordinary contributor photograph of platform-facing station facade
- https://api.openstreetmap.org/api/0.6/map?bbox=76.7992110,8.6225610,76.8172110,8.6405610 | OSM snapshot accessed2026-10-08; original way dates retained in source/layout.json
- https://indiarailinfo.com/station/map/3526 | IRI profile cross-check accessed2026-10-08; reported totals are secondary and not a signed current yard plan

## Rights
Map-derived geometry © OpenStreetMap contributors, available under ODbL1.0: https://www.openstreetmap.org/copyright and https://opendatacommons.org/licenses/odbl/1-0/ . Preserve attribution and applicable derived-database obligations. No new licence is claimed for third-party source material. No Google/photographer screenshots, station photographs or copied photo textures are distributed in this package. Authoring geometry is newly generated for this request. DejaVu and Noto lettering uses locally installed freely licensed fonts; see THIRD_PARTY_NOTICES.txt.
