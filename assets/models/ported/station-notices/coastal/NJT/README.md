# Nagercoil Town (NJT) • complete station environment v01

Editable full-size Blender scene, five rendered review views, and a self-contained portable glTF archive. No trains or other rolling stock.

## Files
- NJT_station_v01.blend: authoritative editable scene, materials, cameras and packed font resources
- renders/: full network, station architecture, platform/track view, furnished interior, railway detail
- exchange/NJT_portable_GLTF.zip: losslessly archived GLB, verified against the raw export
- SOURCES.json: evidence links, dates and limitations
- QA_BUILD.json, QA_EXPORT.json and RENDER_PROVENANCE.json: measured model properties and exact source/render/export hashes
- source/: metric source-derived geometry, available native name outlines and documentary build/repair recipes

Recipe snapshots document the construction and narrow repairs. The packed scene is authoritative; these scripts are not a standalone one-click rebuild and refer to the region staging layout and shared locked Blender launcher.

## Scale and coverage
Metres, scene scale1.0. Broad-gauge running head inner faces1.676m apart. Modeled platform bodies: 2; IRI reported platform positions: 3. Source snapshot includes 3 clipped rail-way pieces, not a certified count of physical roads. Full source-specific curves, connected loops and separately mapped sidings are retained within the documented approach envelope. Platforms are not shortened decorative modules. Furniture, water points, lights, signs, waiting/ticket or appropriate service interiors, structural roof members, overhead lines, ballast/sleepers/fasteners, and relevant footbridge/stair connections are modelled.

The source scene has 1,004 objects, 684,309 mesh vertices and 8,917 sleeper/support placements. Rail-network local bounds: [-1100.0, -42.34911930801162, 1100.0, -3.8311535184650003]. Nominal dimensions are explicit modelling choices, not an engineering survey.

## What is observed and what is reconstructed
Google Maps R photo captureNovember2023/headerDecember2023: two-level cream modern flat-parapet block, deep pilaster bays, dark window/vent bands and a large separate barrel-vault approach canopy. Southern side and northern island follow inspected satellite; hidden rooms, dimensions and precise canopy placement reconstructed. Main envelope follows tagged OSM train_station way551805510; main block→barrel canopy→bridge order follows the2023 approach photo and independently image-picked Google satellite points. Canopy/bridge dimensions, stair direction toward mapped approach way383031404 and service-annex placement remain reconstructed.

Southern side platform1 and northern island2/3 follow the satellite interpretation. The third road around the northern island and its connectors are satellite-guided reconstruction where OSM is absent. Old construction tags are not treated as proof of current non-operation.

Maps contain mixed historical edit dates. An OSM edit date, Google copyright year or photo upload date is not a construction or commissioning date. Buildings, shelter spans, unmeasured platform dimensions and hidden rooms/fixtures are reconstructed. This is a source-informed visual asset, not an as-built survey, operational railway inventory, safety certificate or railway-engineering design. Signals, switch details, model clearances and service assignments are illustrative. Geometric rail-channel checks do not certify real wheel/rail operation. Compound pointwork remains simplified where the exact design is unknown.

The 45mm geometric flange channels, unioned running heads, tapered blade components and reconstructed crossing bearers avoid duplicated rail overlays in the adopted model. Procedural material noise/bump is native Blender shading. The portable glTF preserves geometry and base material properties, but those procedural textures are not baked.

## Source references
- https://www.google.com/maps/place/Nagercoil+Town+Railway+Station/@8.1995318,77.4200662,3a,75y,90t/data=!3m8!1e2!3m6!1sCIHM0ogKEICAgIDlxqacAg!2e10!3e12!6shttps:%2F%2Flh3.googleusercontent.com%2Fgps-cs-s%2FANWiy9S9fxa_F1DKYmP6acSMtrBX8GaLks1ndUE7SiS9tc1ClJFBt0RQw39tgzfS9WRW0vvZrLMUnaQ8ugz0NZRo5fB_20EkqX6zrpOuDt0BtU2a9pcqY-4-Rn9vKcw9tRe8PRUrKn5r%3Dw203-h151-k-no!7i9280!8i6944!4m11!1m2!2m1!1sNagercoil+Town+railway+station!3m7!1s0x3b04f72667fbec1f:0x23ca788f1d61379!8m2!3d8.1998198!4d77.4200528!10e5!15sCh5OYWdlcmNvaWwgVG93biByYWlsd2F5IHN0YXRpb25aICIebmFnZXJjb2lsIHRvd24gcmFpbHdheSBzdGF0aW9ukgELdHJhaW5fZGVwb3SaASRDaGREU1VoTk1HOW5TMFZKUTBGblNVTlNORFJEY0dsblJSQULgAQD6AQQIABBM!16s%2Fg%2F11rn_ygzgv?entry=ttu&g_ep=EgoyMDI2MTAwNS4wIKXMDSoASAFQAw%3D%3D | Image capture Nov 2023; photo header Dec 2023 | Ordinary contributor photograph of modern station entrance
- https://www.google.com/maps/place/8%C2%B011'59.8%22N+77%C2%B025'12.2%22E/@8.1999573,77.4193037,225m/data=!3m1!1e3!4m4!3m3!8m2!3d8.199952!4d77.420044?entry=ttu&g_ep=EgoyMDI2MTAwNS4wIKXMDSoASAFQAw%3D%3D | satellite acquisition date not exposed; observation accessed2026-10-08
- https://api.openstreetmap.org/api/0.6/map?bbox=77.4104318,8.1905718,77.4284318,8.2085718 | OSM snapshot accessed2026-10-08; original way dates retained in source/layout.json
- https://indiarailinfo.com/station/map/nagercoil-town-njt/4793 | IRI profile cross-check accessed2026-10-08; reported totals are secondary and not a signed current yard plan

## Rights
Map-derived geometry © OpenStreetMap contributors, available under ODbL1.0: https://www.openstreetmap.org/copyright and https://opendatacommons.org/licenses/odbl/1-0/ . Preserve attribution and applicable derived-database obligations. No new licence is claimed for third-party source material. No Google/photographer screenshots, station photographs or copied photo textures are distributed in this package. Authoring geometry is newly generated for this request. DejaVu and Noto lettering uses locally installed freely licensed fonts; see THIRD_PARTY_NOTICES.txt.
