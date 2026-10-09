# Thiruvananthapuram South (TVCS) • complete station environment v01

Editable full-size Blender scene, five rendered review views, and a self-contained portable glTF archive. No trains or other rolling stock.

## Files
- TVCS_station_v01.blend: authoritative editable scene, materials, cameras and packed font resources
- renders/: full network, station architecture, platform/track view, furnished interior, railway detail
- exchange/TVCS_portable_GLTF.zip: losslessly archived GLB, verified against the raw export
- SOURCES.json: evidence links, dates and limitations
- QA_BUILD.json, QA_EXPORT.json and RENDER_PROVENANCE.json: measured model properties and exact source/render/export hashes
- source/: metric source-derived geometry, available native name outlines and documentary build/repair recipes

Recipe snapshots document the construction and narrow repairs. The packed scene is authoritative; these scripts are not a standalone one-click rebuild and refer to the region staging layout and shared locked Blender launcher.

## Scale and coverage
Metres, scene scale1.0. Broad-gauge running head inner faces1.676m apart. Modeled platform bodies: 2; IRI reported platform positions: 2. Source snapshot includes 4 clipped rail-way pieces, not a certified count of physical roads. Full source-specific curves, connected loops and separately mapped sidings are retained within the documented approach envelope. Platforms are not shortened decorative modules. Furniture, water points, lights, signs, waiting/ticket or appropriate service interiors, structural roof members, overhead lines, ballast/sleepers/fasteners, and relevant footbridge/stair connections are modelled.

The source scene has 986 objects, 423,920 mesh vertices and 5,489 sleeper/support placements. Rail-network local bounds: [-1100.0, -239.85283848390108, 1100.0, 153.1220436935325]. Nominal dimensions are explicit modelling choices, not an engineering survey.

## What is observed and what is reconstructed
Google Maps R. Ganapathi Raman August2024 existing Nemom platform facade; no proposed terminal represented.

This models the modest existing Nemom/Thiruvananthapuram South station using the August2024 facade reference and mapped roads. Proposed expanded terminal facilities are excluded.

Maps contain mixed historical edit dates. An OSM edit date, Google copyright year or photo upload date is not a construction or commissioning date. Buildings, shelter spans, unmeasured platform dimensions and hidden rooms/fixtures are reconstructed. This is a source-informed visual asset, not an as-built survey, operational railway inventory, safety certificate or railway-engineering design. Signals, switch details, model clearances and service assignments are illustrative. Geometric rail-channel checks do not certify real wheel/rail operation. Compound pointwork remains simplified where the exact design is unknown.

The 45mm geometric flange channels, unioned running heads, tapered blade components and reconstructed crossing bearers avoid duplicated rail overlays in the adopted model. Procedural material noise/bump is native Blender shading. The portable glTF preserves geometry and base material properties, but those procedural textures are not baked.

## Source references
- https://www.google.com/maps/place/Thiruvananthapuram+South+(Nemom)/@8.4538347,77.0104114,3a,75y,90t/data=!3m8!1e2!3m6!1sCIHM0ogKEICAgIC76ObCygE!2e10!3e12!6shttps:%2F%2Flh3.googleusercontent.com%2Fgps-cs-s%2FAHRPTWlpOyr5tNHt-UtSkg9S8pZMnZ7AKaCIljT6s8tox8HA4709Ih1XePySoSsQTpu522pQ7dlqA0fizBoLL9EhRYeOUz5n68H5H6Q5v2uN770vAH3oHagVHmdbbWdKDpbNfdzQciVUMQ%3Dw203-h152-k-no!7i4608!8i3456!4m7!3m6!1s0x3b05baa770a1dd23:0x9f6578fd4e85bdf9!8m2!3d8.4539403!4d77.0104538!10e5!16s%2Fm%2F0fpgtk7?entry=ttu&g_ep=EgoyMDI2MTAwNS4wIKXMDSoASAFQAw%3D%3D | Aug 2024 | Ordinary contributor photograph of Nemom station platform facade

- https://api.openstreetmap.org/api/0.6/map?bbox=77.0006930,8.4462330,77.0186930,8.4642330 | OSM snapshot accessed2026-10-08; original way dates retained in source/layout.json
- https://indiarailinfo.com/station/rfclub/railfan-club-thiruvananthapuram-south-nemom-tvcs/4790 | IRI profile cross-check accessed2026-10-08; reported totals are secondary and not a signed current yard plan

## Rights
Map-derived geometry © OpenStreetMap contributors, available under ODbL1.0: https://www.openstreetmap.org/copyright and https://opendatacommons.org/licenses/odbl/1-0/ . Preserve attribution and applicable derived-database obligations. No new licence is claimed for third-party source material. No Google/photographer screenshots, station photographs or copied photo textures are distributed in this package. Authoring geometry is newly generated for this request. DejaVu and Noto lettering uses locally installed freely licensed fonts; see THIRD_PARTY_NOTICES.txt.
