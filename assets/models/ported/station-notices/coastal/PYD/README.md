# Palliyadi (PYD) • complete station environment v01

Editable full-size Blender scene, five rendered review views, and a self-contained portable glTF archive. No trains or other rolling stock.

## Files
- PYD_station_v01.blend: authoritative editable scene, materials, cameras and packed font resources
- renders/: full network, station architecture, platform/track view, furnished interior, railway detail
- exchange/PYD_portable_GLTF.zip: losslessly archived GLB, verified against the raw export
- SOURCES.json: evidence links, dates and limitations
- QA_BUILD.json, QA_EXPORT.json and RENDER_PROVENANCE.json: measured model properties and exact source/render/export hashes
- source/: metric source-derived geometry, available native name outlines and documentary build/repair recipes

Recipe snapshots document the construction and narrow repairs. The packed scene is authoritative; these scripts are not a standalone one-click rebuild and refer to the region staging layout and shared locked Blender launcher.

## Scale and coverage
Metres, scene scale1.0. Broad-gauge running head inner faces1.676m apart. Modeled platform bodies: 1; IRI reported platform positions: 1. Source snapshot includes 1 clipped rail-way pieces, not a certified count of physical roads. Full source-specific curves, connected loops and separately mapped sidings are retained within the documented approach envelope. Platforms are not shortened decorative modules. Furniture, water points, lights, signs, waiting/ticket or appropriate service interiors, structural roof members, overhead lines, ballast/sleepers/fasteners, and relevant footbridge/stair connections are modelled.

The source scene has 969 objects, 222,215 mesh vertices and 2,862 sleeper/support placements. Rail-network local bounds: [-850.0, -75.86066896505285, 850.0, 66.25566304252835]. Nominal dimensions are explicit modelling choices, not an engineering survey.

## What is observed and what is reconstructed
Google Maps SHAJU S April2023 cream/turquoise hut under galvanized lattice canopy; Edward Jeni June2026 physically built covered footbridge. Opposite works/landing do not establish a second operational platform or track.

A physically built covered footbridge is documented in June2026 despite the reported one-platform count. The opposite landing/raised work is modelled separately with uncertain commissioning/function; no second operational platform or rail is inferred solely from the bridge.

Maps contain mixed historical edit dates. An OSM edit date, Google copyright year or photo upload date is not a construction or commissioning date. Buildings, shelter spans, unmeasured platform dimensions and hidden rooms/fixtures are reconstructed. This is a source-informed visual asset, not an as-built survey, operational railway inventory, safety certificate or railway-engineering design. Signals, switch details, model clearances and service assignments are illustrative. Geometric rail-channel checks do not certify real wheel/rail operation. Compound pointwork remains simplified where the exact design is unknown.

The 45mm geometric flange channels, unioned running heads, tapered blade components and reconstructed crossing bearers avoid duplicated rail overlays in the adopted model. Procedural material noise/bump is native Blender shading. The portable glTF preserves geometry and base material properties, but those procedural textures are not baked.

## Source references
- https://www.google.com/maps/place/Palliyadi/@8.2647436,77.2600592,3a,75y,90t/data=!3m8!1e2!3m6!1sCIHM0ogKEICAgICRjcfy-QE!2e10!3e12!6shttps:%2F%2Flh3.googleusercontent.com%2Fgrass-cs%2FAABkmLd_vSQX67Qo-KMFpyyr6kTA6___0ppq0Lml1siWAg2bL-1aBA9nmSC9xVrBDz3qiCY7Rcuzf_qQO71vjLoUNbSa1FSfLYF7QXJMtfEgIJkXKmt6Tv6c2R5iioWDK2xAzSpMS8lq%3Dw99-h86-k-no!7i2889!8i2496!4m7!3m6!1s0x3b04ff68eeccde45:0x384dd77076446dc1!8m2!3d8.2657788!4d77.2595028!10e5!16s%2Fg%2F1td6dxjq?entry=ttu&g_ep=EgoyMDI2MTAwNS4wIKXMDSoASAFQAw%3D%3D | April 2023 | Ordinary contributor photograph
- https://www.google.com/maps/place/Palliyadi/@8.2647436,77.2600592,3a,75y,90t/data=!3m8!1e2!3m6!1sCIABIhBgVQA3LJAFWoyv9yBpqTgb!2e10!3e12!6shttps:%2F%2Flh3.googleusercontent.com%2Fgps-cs-s%2FAHRPTWlf17O-bHZR2wIGog8pn3BSjnYnm6f1Sfh1XEqdiwufCOSqh89UHVDQyOIFN91Yg0bODHn97MRjclFDuFZA0xAcI2GgXgD3i43dIfFbRy1LV4ju9hFMrnjFpiG5MZzrSLI4dfVkNVyM8WM%3Dw203-h152-k-no!7i4032!8i3024!4m7!3m6!1s0x3b04ff68eeccde45:0x384dd77076446dc1!8m2!3d8.2657788!4d77.2595028!10e5!16s%2Fg%2F1td6dxjq?entry=ttu&g_ep=EgoyMDI2MTAwNS4wIKXMDSoASAFQAw%3D%3D | June 2026 | Ordinary contributor photograph of footbridge deck

- https://api.openstreetmap.org/api/0.6/map?bbox=77.2506830,8.2561500,77.2686830,8.2741500 | OSM snapshot accessed2026-10-08; original way dates retained in source/layout.json
- https://d.indiarailinfo.com/station/map/palliyadi-pyd/2776 | IRI profile cross-check accessed2026-10-08; reported totals are secondary and not a signed current yard plan

## Rights
Map-derived geometry © OpenStreetMap contributors, available under ODbL1.0: https://www.openstreetmap.org/copyright and https://opendatacommons.org/licenses/odbl/1-0/ . Preserve attribution and applicable derived-database obligations. No new licence is claimed for third-party source material. No Google/photographer screenshots, station photographs or copied photo textures are distributed in this package. Authoring geometry is newly generated for this request. DejaVu and Noto lettering uses locally installed freely licensed fonts; see THIRD_PARTY_NOTICES.txt.
