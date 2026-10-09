# Murukkampuzha (MQU) • complete station environment v01

Editable full-size Blender scene, five rendered review views, and a self-contained portable glTF archive. No trains or other rolling stock.

## Files
- MQU_station_v01.blend: authoritative editable scene, materials, cameras and packed font resources
- renders/: full network, station architecture, platform/track view, furnished interior, railway detail
- exchange/MQU_portable_GLTF.zip: losslessly archived GLB, verified against the raw export
- SOURCES.json: evidence links, dates and limitations
- QA_BUILD.json, QA_EXPORT.json and RENDER_PROVENANCE.json: measured model properties and exact source/render/export hashes
- source/: metric source-derived geometry, available native name outlines and documentary build/repair recipes

Recipe snapshots document the construction and narrow repairs. The packed scene is authoritative; these scripts are not a standalone one-click rebuild and refer to the region staging layout and shared locked Blender launcher.

## Scale and coverage
Metres, scene scale1.0. Broad-gauge running head inner faces1.676m apart. Modeled platform bodies: 2; IRI reported platform positions: 2. Source snapshot includes 6 clipped rail-way pieces, not a certified count of physical roads. Full source-specific curves, connected loops and separately mapped sidings are retained within the documented approach envelope. Platforms are not shortened decorative modules. Furniture, water points, lights, signs, waiting/ticket or appropriate service interiors, structural roof members, overhead lines, ballast/sleepers/fasteners, and relevant footbridge/stair connections are modelled.

The source scene has 995 objects, 559,957 mesh vertices and 7,481 sleeper/support placements. Rail-network local bounds: [-850.0, 9.637274966610894, 850.0, 101.93894437448485]. Nominal dimensions are explicit modelling choices, not an engineering survey.

## What is observed and what is reconstructed
Google Maps Aneeshraj BT April2022 louvered low flat-parapet street facade, Anjali S Nair November2022 golden platform facade with orange bands/maroon shutters and colored pots, plus undated satellite two outer platforms around three roads. Southwest platform width reconstructed5.5m because mapped footprint is imprecise.



Maps contain mixed historical edit dates. An OSM edit date, Google copyright year or photo upload date is not a construction or commissioning date. Buildings, shelter spans, unmeasured platform dimensions and hidden rooms/fixtures are reconstructed. This is a source-informed visual asset, not an as-built survey, operational railway inventory, safety certificate or railway-engineering design. Signals, switch details, model clearances and service assignments are illustrative. Geometric rail-channel checks do not certify real wheel/rail operation. Compound pointwork remains simplified where the exact design is unknown.

The 45mm geometric flange channels, unioned running heads, tapered blade components and reconstructed crossing bearers avoid duplicated rail overlays in the adopted model. Procedural material noise/bump is native Blender shading. The portable glTF preserves geometry and base material properties, but those procedural textures are not baked.

## Source references
- https://www.google.com/maps/place/Murukkampuzha/@8.6132024,76.8304919,224m/data=!3m1!1e3!4m6!3m5!1s0x3b05c003ead06e63:0xc129dadc3a71bf9!8m2!3d8.6132024!4d76.8304919!16s%2Fg%2F1tlqndzm?entry=ttu&g_ep=EgoyMDI2MTAwNS4wIKXMDSoASAFQAw%3D%3D | Not exposed | Google Maps satellite visually inspected
- https://www.google.com/maps/place/Murukkampuzha/@8.6132024,76.8304919,3a,75y,90t/data=!3m8!1e2!3m6!1sCIHM0ogKEICAgIC-wdDtTw!2e10!3e12!6shttps:%2F%2Flh3.googleusercontent.com%2Fgps-cs-s%2FAHRPTWkZrVQOhTJQdbDtHuo24h5voxG641KqXXE9BXwyP77KmJ7W16RgDByHB3J2jOFMyqsse65JQucFUTqZhUeXtFoYFa5L6kJsjUqlhzLMMQFPegM_xUzFjEe-S0cb4pl28PnRBZwR%3Dw203-h152-k-no!7i1024!8i768!4m7!3m6!1s0x3b05c003ead06e63:0xc129dadc3a71bf9!8m2!3d8.6132024!4d76.8304919!10e5!16s%2Fg%2F1tlqndzm?entry=ttu&g_ep=EgoyMDI2MTAwNS4wIKXMDSoASAFQAw%3D%3D | Nov 2022 | Ordinary contributor photograph of platform facade
- https://www.google.com/maps/place/Murukkampuzha/@8.6122506,76.8309089,3a,75y,90t/data=!3m8!1e2!3m6!1sCIHM0ogKEICAgIC2zPOg-wE!2e10!3e12!6shttps:%2F%2Flh3.googleusercontent.com%2Fgps-cs-s%2FAHRPTWk_vSQSXtGJZ1pFFedv0ibDWuxrUGLfjP5ymBJ2y-87CEC3faNYbwg1eslNY456tN5GJ5OF86f15jN3ocnOrNLNiTtR87hnz4sjvL4qUCvoKL6eeZcldoNtFaQO2xa9NkwCgRRdSw%3Dw203-h152-k-no!7i3264!8i2448!4m7!3m6!1s0x3b05c003ead06e63:0xc129dadc3a71bf9!8m2!3d8.6132024!4d76.8304919!10e5!16s%2Fg%2F1tlqndzm?entry=ttu&g_ep=EgoyMDI2MTAwNS4wIKXMDSoASAFQAw%3D%3D | Apr 2022 | Ordinary contributor photograph of road entrance

- https://api.openstreetmap.org/api/0.6/map?bbox=76.8212450,8.6046300,76.8392450,8.6226300 | OSM snapshot accessed2026-10-08; original way dates retained in source/layout.json
- https://d.indiarailinfo.com/station/map/murukkampuzha-mqu/2782 | IRI profile cross-check accessed2026-10-08; reported totals are secondary and not a signed current yard plan

## Rights
Map-derived geometry © OpenStreetMap contributors, available under ODbL1.0: https://www.openstreetmap.org/copyright and https://opendatacommons.org/licenses/odbl/1-0/ . Preserve attribution and applicable derived-database obligations. No new licence is claimed for third-party source material. No Google/photographer screenshots, station photographs or copied photo textures are distributed in this package. Authoring geometry is newly generated for this request. DejaVu and Noto lettering uses locally installed freely licensed fonts; see THIRD_PARTY_NOTICES.txt.
