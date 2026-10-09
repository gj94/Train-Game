# Veli (VELI) • complete station environment v01

Editable full-size Blender scene, five rendered review views, and a self-contained portable glTF archive. No trains or other rolling stock.

## Files
- VELI_station_v01.blend: authoritative editable scene, materials, cameras and packed font resources
- renders/: full network, station architecture, platform/track view, furnished interior, railway detail
- exchange/VELI_portable_GLTF.zip: losslessly archived GLB, verified against the raw export
- SOURCES.json: evidence links, dates and limitations
- QA_BUILD.json, QA_EXPORT.json and RENDER_PROVENANCE.json: measured model properties and exact source/render/export hashes
- source/: metric source-derived geometry, native name outlines and documentary build recipe

## Scale and coverage
Metres, scene scale1.0. Broad-gauge running head inner faces1.676m apart. Modeled platform bodies: 1; IRI reported platform positions: 1. Source snapshot includes 2 clipped rail-way pieces, not a certified count of physical roads. Full source-specific curves, connected loops and separately mapped sidings are retained within the documented approach envelope. Platforms are not shortened decorative modules. Furniture, water points, lights, signs, waiting/ticket or appropriate service interiors, structural roof members, overhead lines, ballast/sleepers/fasteners, and relevant footbridge/stair connections are modelled.

The source scene has 670 objects, 405,365 mesh vertices and 5,865 sleeper/support placements. Rail-network local bounds: [-850.0, -7.910178242570758, 850.0, 248.67266202045496]. Nominal dimensions are explicit modelling choices, not an engineering survey.

## What is observed and what is reconstructed
Google Maps December2017 white high-vent service block (function unclear), January2023 sign/fence, September2026 butterfly canopy and opposite raised strip; interior reconstructed, opposite strip construction/status uncertain.

The clearly visible opposite raised strip in a September2026 contributor photo is modelled separately as uncertain construction/retaining or platform work. It is NOT included as a second confirmed operational platform. Existing platform count1 and earlier user/satellite evidence remain separate.

Maps contain mixed historical edit dates. An OSM edit date, Google copyright year or photo upload date is not a construction or commissioning date. Buildings, shelter spans, unmeasured platform dimensions and hidden rooms/fixtures are reconstructed. This is a source-informed visual asset, not an as-built survey, operational railway inventory, safety certificate or railway-engineering design. Signals, switch details, model clearances and service assignments are illustrative. Geometric rail-channel checks do not certify real wheel/rail operation. Compound pointwork remains simplified where the exact design is unknown.

The 45mm geometric flange channels, unioned running heads, tapered blade components and reconstructed crossing bearers avoid duplicated rail overlays in the adopted model. Procedural material noise/bump is native Blender shading. The portable glTF preserves geometry and base material properties, but those procedural textures are not baked.

## Source references
- https://www.google.com/maps/place/Veli/@8.522911,76.8827112,3a,75y,90t/data=!3m8!1e2!3m6!1sCIHM0ogKEICAgIDBorHCxAE!2e10!3e12!6shttps:%2F%2Flh3.googleusercontent.com%2Fgps-cs-s%2FAHRPTWkQ6-yBZUv0JYXXaZuoFMxhJoR0fLVrB9M7NVf1KHZ0ZJrOJvNIlz7KQERBWDvRmrV5zB9pH7DhE7ACsBiF4qaWCKz8J2evtwNkSsfaNM2NsCa4UsYWSwGimIs7NmZQebSzFc4Bww%3Dw203-h114-k-no!7i4624!8i2600!4m7!3m6!1s0x3b05be85ab08212f:0x8a104b716e09d89a!8m2!3d8.5229108!4d76.8827116!10e5!16s%2Fg%2F1tkd_d3c?authuser=0&hl=en&entry=ttu&g_ep=EgoyMDI2MTAwNS4wIKXMDSoASAFQAw%3D%3D | Jan 2023 | Ordinary contributor photograph; actual VELI sign visible
- https://www.google.com/maps/place/Veli/@8.5228406,76.8829058,3a,75y,90t/data=!3m8!1e2!3m6!1sCIHM0ogKEICAgIC8kMSyEg!2e10!3e12!6shttps:%2F%2Flh3.googleusercontent.com%2Fgps-cs-s%2FAHRPTWkA-NSo2PLLtZ9v0QZ9oqlXBSKCoxl6l4nh-2SKpHOffpji_DP35O8i2Kk3ku1MJQjxd-3Vo29UnlHbhMC7KwrtKOSqAUNdQGqPJDSHp0u-O5_w1Fc23b1msQa_ugVIYcNBgGo%3Dw203-h152-k-no!7i4160!8i3120!4m7!3m6!1s0x3b05be85ab08212f:0x8a104b716e09d89a!8m2!3d8.5229108!4d76.8827116!10e5!16s%2Fg%2F1tkd_d3c?authuser=0&hl=en&entry=ttu&g_ep=EgoyMDI2MTAwNS4wIKXMDSoASAFQAw%3D%3D | Dec 2017 | Ordinary contributor photograph; VELI sign in foreground
- https://www.google.com/maps/place/Veli/@8.5228406,76.8829058,3a,75y,90t/data=!3m8!1e2!3m6!1sCIABIhAXynpWBHjbVoYkPR3cenZo!2e10!3e12!6shttps:%2F%2Flh3.googleusercontent.com%2Fgps-cs-s%2FAHRPTWl0aZ5sV89R37YIQSpUqWShwOQZxIZtc9cn-0mez4eT3nCzlzyZxr__d9qpog7sdXfWj5RG6DUsxYp0kzorxdgZKKQ3uOst7YWQwES1-EQQZ6UBUbL-AtdRLsmdT9lr69l5Ir5VfEGsJrc9%3Dw203-h270-k-no!7i2448!8i3264!4m7!3m6!1s0x3b05be85ab08212f:0x8a104b716e09d89a!8m2!3d8.5229108!4d76.8827116!10e5!16s%2Fg%2F1tkd_d3c?authuser=0&hl=en&entry=ttu&g_ep=EgoyMDI2MTAwNS4wIKXMDSoASAFQAw%3D%3D | Sep 2026 | Ordinary contributor photograph of sheltered platform
- https://api.openstreetmap.org/api/0.6/map?bbox=76.8739192,8.5135365,76.8919192,8.5315365 | OSM snapshot accessed2026-10-08; original way dates retained in source/layout.json
- https://indiarailinfo.com/station/map/3528#st | IRI profile cross-check accessed2026-10-08; reported totals are secondary and not a signed current yard plan

## Rights
Map-derived geometry © OpenStreetMap contributors, available under ODbL1.0: https://www.openstreetmap.org/copyright and https://opendatacommons.org/licenses/odbl/1-0/ . Preserve attribution and applicable derived-database obligations. No new licence is claimed for third-party source material. No Google/photographer screenshots, station photographs or copied photo textures are distributed in this package. Authoring geometry is newly generated for this request. DejaVu and Noto lettering uses locally installed freely licensed fonts; see THIRD_PARTY_NOTICES.txt.
