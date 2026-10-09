# Dhanuvachapuram (DAVM) • complete station environment v01

Editable full-size Blender scene, five rendered review views, and a self-contained portable glTF archive. No trains or other rolling stock.

## Files
- DAVM_station_v01.blend: authoritative editable scene, materials, cameras and packed font resources
- renders/: full network, station architecture, platform/track view, furnished interior, railway detail
- exchange/DAVM_portable_GLTF.zip: losslessly archived GLB, verified against the raw export
- SOURCES.json: evidence links, dates and limitations
- QA_BUILD.json, QA_EXPORT.json and RENDER_PROVENANCE.json: measured model properties and exact source/render/export hashes
- source/: metric source-derived geometry, available native name outlines and documentary build/repair recipes

Recipe snapshots document the construction and narrow repairs. The packed scene is authoritative; these scripts are not a standalone one-click rebuild and refer to the region staging layout and shared locked Blender launcher.

## Scale and coverage
Metres, scene scale1.0. Broad-gauge running head inner faces1.676m apart. Modeled platform bodies: 1; IRI reported platform positions: 2. Source snapshot includes 1 clipped rail-way pieces, not a certified count of physical roads. Full source-specific curves, connected loops and separately mapped sidings are retained within the documented approach envelope. Platforms are not shortened decorative modules. Furniture, water points, lights, signs, waiting/ticket or appropriate service interiors, structural roof members, overhead lines, ballast/sleepers/fasteners, and relevant footbridge/stair connections are modelled.

The source scene has 687 objects, 218,899 mesh vertices and 2,864 sleeper/support placements. Rail-network local bounds: [-850.0, -119.27854207782337, 850.0, 79.27935889092605]. Nominal dimensions are explicit modelling choices, not an engineering survey.

## What is observed and what is reconstructed
Google Maps Akhil vs December2019 small corrugated ticket shelter interior plus undated satellite single definite developed road/platform; IRI reported2 retained separately.

The visible developed layout uses one road and one northeast-side platform, plus unfinished graded land. IRI reports2 platforms, but undated satellite does not resolve a completed second road/body. The small corrugated shelter interior is based on a December2019 photograph. Current replacement work is not certified.

Maps contain mixed historical edit dates. An OSM edit date, Google copyright year or photo upload date is not a construction or commissioning date. Buildings, shelter spans, unmeasured platform dimensions and hidden rooms/fixtures are reconstructed. This is a source-informed visual asset, not an as-built survey, operational railway inventory, safety certificate or railway-engineering design. Signals, switch details, model clearances and service assignments are illustrative. Geometric rail-channel checks do not certify real wheel/rail operation. Compound pointwork remains simplified where the exact design is unknown.

The 45mm geometric flange channels, unioned running heads, tapered blade components and reconstructed crossing bearers avoid duplicated rail overlays in the adopted model. Procedural material noise/bump is native Blender shading. The portable glTF preserves geometry and base material properties, but those procedural textures are not baked.

## Source references
- https://www.google.com/maps/place/Dhanuvachapuram/@8.3782131,77.1258376,225m/data=!3m1!1e3!4m6!3m5!1s0x3b05ac153f3f79a9:0x9a9de29f930dfb21!8m2!3d8.3782131!4d77.1258376!16s%2Fg%2F1tfzqbq0?entry=ttu&g_ep=EgoyMDI2MTAwNS4wIKXMDSoASAFQAw%3D%3D | Not exposed | Google Maps satellite visually inspected
- https://www.google.com/maps/place/Dhanuvachapuram/@8.3783057,77.1257969,3a,75y,90t/data=!3m8!1e2!3m6!1sCIHM0ogKEICAgIDM7NS_zwE!2e10!3e12!6shttps:%2F%2Flh3.googleusercontent.com%2Fgrass-cs%2FACvplmNO0geiJEqzciJpxYmVK4J5dIM-tPXeO9a7vuFFbMZCBPX87UV8UpybxQfNqVavzh3pIJRmmMXFac93aW5bEZNEUNTHqrGST2r8din8YVXuY6pnutxnL2OHZHl96ZApOaJSvQRNDw%3Dw114-h86-k-no!7i4608!8i3456!4m7!3m6!1s0x3b05ac153f3f79a9:0x9a9de29f930dfb21!8m2!3d8.3782131!4d77.1258376!10e5!16s%2Fg%2F1tfzqbq0?entry=ttu&g_ep=EgoyMDI2MTAwNS4wIKXMDSoASAFQAw%3D%3D | Dec 2019 | Ordinary contributor photograph of ticket/waiting shelter interior

- https://api.openstreetmap.org/api/0.6/map?bbox=77.1153520,8.3698020,77.1333520,8.3878020 | OSM snapshot accessed2026-10-08; original way dates retained in source/layout.json
- https://indiarailinfo.com/station/map/2774 | IRI profile cross-check accessed2026-10-08; reported totals are secondary and not a signed current yard plan

## Rights
Map-derived geometry © OpenStreetMap contributors, available under ODbL1.0: https://www.openstreetmap.org/copyright and https://opendatacommons.org/licenses/odbl/1-0/ . Preserve attribution and applicable derived-database obligations. No new licence is claimed for third-party source material. No Google/photographer screenshots, station photographs or copied photo textures are distributed in this package. Authoring geometry is newly generated for this request. DejaVu and Noto lettering uses locally installed freely licensed fonts; see THIRD_PARTY_NOTICES.txt.
