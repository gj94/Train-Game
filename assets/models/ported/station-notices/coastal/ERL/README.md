# Eraniel (ERL) • complete station environment v01

Editable full-size Blender scene, five rendered review views, and a self-contained portable glTF archive. No trains or other rolling stock.

## Files
- ERL_station_v01.blend: authoritative editable scene, materials, cameras and packed font resources
- renders/: full network, station architecture, platform/track view, furnished interior, railway detail
- exchange/ERL_portable_GLTF.zip: losslessly archived GLB, verified against the raw export
- SOURCES.json: evidence links, dates and limitations
- QA_BUILD.json, QA_EXPORT.json and RENDER_PROVENANCE.json: measured model properties and exact source/render/export hashes
- source/: metric source-derived geometry, available native name outlines and documentary build/repair recipes

Recipe snapshots document the construction and narrow repairs. The packed scene is authoritative; these scripts are not a standalone one-click rebuild and refer to the region staging layout and shared locked Blender launcher.

## Scale and coverage
Metres, scene scale1.0. Broad-gauge running head inner faces1.676m apart. Modeled platform bodies: 2; IRI reported platform positions: 2. Source snapshot includes 7 clipped rail-way pieces, not a certified count of physical roads. Full source-specific curves, connected loops and separately mapped sidings are retained within the documented approach envelope. Platforms are not shortened decorative modules. Furniture, water points, lights, signs, waiting/ticket or appropriate service interiors, structural roof members, overhead lines, ballast/sleepers/fasteners, and relevant footbridge/stair connections are modelled.

The source scene has 969 objects, 662,014 mesh vertices and 9,437 sleeper/support placements. Rail-network local bounds: [-1100.0, -226.50069817788582, 1100.0, 50.98827434234629]. Nominal dimensions are explicit modelling choices, not an engineering survey.

## What is observed and what is reconstructed
Google Maps Anto Yesuraj November2017 low ochre entry and Harsh2897 January2020 two-level white/lavender platform block with turquoise parapet and yellow brackets; Ramprasad GV August2021 blue zigzag footbridge roofs. The relationship between dated entry/platform blocks is unresolved, so their composition and hidden circulation are explicitly reconstructed.



Maps contain mixed historical edit dates. An OSM edit date, Google copyright year or photo upload date is not a construction or commissioning date. Buildings, shelter spans, unmeasured platform dimensions and hidden rooms/fixtures are reconstructed. This is a source-informed visual asset, not an as-built survey, operational railway inventory, safety certificate or railway-engineering design. Signals, switch details, model clearances and service assignments are illustrative. Geometric rail-channel checks do not certify real wheel/rail operation. Compound pointwork remains simplified where the exact design is unknown.

The 45mm geometric flange channels, unioned running heads, tapered blade components and reconstructed crossing bearers avoid duplicated rail overlays in the adopted model. Procedural material noise/bump is native Blender shading. The portable glTF preserves geometry and base material properties, but those procedural textures are not baked.

## Source references
- https://www.google.com/maps/place/Eraniel/@8.2135467,77.3076172,3a,75y,90t/data=!3m8!1e2!3m6!1sCIHM0ogKEICAgIDaxJGhhwE!2e10!3e12!6shttps:%2F%2Flh3.googleusercontent.com%2Fgps-cs-s%2FAHRPTWnMbIJTdobLNuPeZ3Edv-hkYdjLrb3pWJf58L26W4Ve42QMI4LqcZZjXP0nGkheY-vffK4XllMJ91B5BjHoILlookb1PB-sdT1dXoMRvonfZZIlsErjMUgO3kzxld-PEXjE3_zr%3Dw203-h114-k-no!7i3840!8i2160!4m7!3m6!1s0x3b04f940324092f3:0xede939b9fc71a249!8m2!3d8.2135428!4d77.3077562!10e5!16s%2Fm%2F0dlnw3d?entry=ttu&g_ep=EgoyMDI2MTAwNS4wIKXMDSoASAFQAw%3D%3D | Aug 2021 | Ordinary contributor photograph of platform footbridge
- https://www.google.com/maps/place/Eraniel/@8.2135428,77.3077562,3a,75y,90t/data=!3m8!1e2!3m6!1sCIHM0ogKEICAgIDcl8HlWg!2e10!3e12!6shttps:%2F%2Flh3.googleusercontent.com%2Fgps-cs-s%2FAHRPTWkBRJw_jfOcOeKqpAqx8HWN8rZ1Q2RAhlL8YkADcYSIagZ-xFgOzZECMFwdebD7hy7k1XLqqct2uT3AmJWqsAtNwuExSR08XNNhf44N_4mapwWU2k4-Om1nA-ZeuKK7B4G6UJzm%3Dw203-h128-k-no!7i1500!8i947!4m7!3m6!1s0x3b04f940324092f3:0xede939b9fc71a249!8m2!3d8.2135428!4d77.3077562!10e5!16s%2Fm%2F0dlnw3d?entry=ttu&g_ep=EgoyMDI2MTAwNS4wIKXMDSoASAFQAw%3D%3D | Nov 2017 | Ordinary contributor photograph of public road entrance
- https://www.google.com/maps/place/Eraniel/@8.2136218,77.3077738,3a,75y,90t/data=!3m8!1e2!3m6!1sCIHM0ogKEICAgICsgpCQFQ!2e10!3e12!6shttps:%2F%2Flh3.googleusercontent.com%2Fgps-cs-s%2FAHRPTWmY8BUztw66TRwr2ME2D_goK3Uq3MiywqWJH4YaAz1_r3Yip1N4zVf219ZYBDcpVyfdDkliCztjTsoaLXYEnlIq27kuKLQ8jlC0D4vZkCmDb0oM1DWjG7PjhQXag1UjHZ-xG63O%3Dw203-h152-k-no!7i4032!8i3024!4m7!3m6!1s0x3b04f940324092f3:0xede939b9fc71a249!8m2!3d8.2135428!4d77.3077562!10e5!16s%2Fm%2F0dlnw3d?entry=ttu&g_ep=EgoyMDI2MTAwNS4wIKXMDSoASAFQAw%3D%3D | Jan 2020 | Ordinary contributor photograph of two-level platform-facing block

- https://api.openstreetmap.org/api/0.6/map?bbox=77.2991610,8.2035490,77.3171610,8.2215490 | OSM snapshot accessed2026-10-08; original way dates retained in source/layout.json
- https://indiarailinfo.com/station/map/eraniel-erl/802 | IRI profile cross-check accessed2026-10-08; reported totals are secondary and not a signed current yard plan

## Rights
Map-derived geometry © OpenStreetMap contributors, available under ODbL1.0: https://www.openstreetmap.org/copyright and https://opendatacommons.org/licenses/odbl/1-0/ . Preserve attribution and applicable derived-database obligations. No new licence is claimed for third-party source material. No Google/photographer screenshots, station photographs or copied photo textures are distributed in this package. Authoring geometry is newly generated for this request. DejaVu and Noto lettering uses locally installed freely licensed fonts; see THIRD_PARTY_NOTICES.txt.
