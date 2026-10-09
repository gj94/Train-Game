# Amaravila (AMVA) • complete station environment v01

Editable full-size Blender scene, five rendered review views, and a self-contained portable glTF archive. No trains or other rolling stock.

## Files
- AMVA_station_v01.blend: authoritative editable scene, materials, cameras and packed font resources
- renders/: full network, station architecture, platform/track view, furnished interior, railway detail
- exchange/AMVA_portable_GLTF.zip: losslessly archived GLB, verified against the raw export
- SOURCES.json: evidence links, dates and limitations
- QA_BUILD.json, QA_EXPORT.json and RENDER_PROVENANCE.json: measured model properties and exact source/render/export hashes
- source/: metric source-derived geometry, available native name outlines and documentary build/repair recipes

Recipe snapshots document the construction and narrow repairs. The packed scene is authoritative; these scripts are not a standalone one-click rebuild and refer to the region staging layout and shared locked Blender launcher.

## Scale and coverage
Metres, scene scale1.0. Broad-gauge running head inner faces1.676m apart. Modeled platform bodies: 1; IRI reported platform positions: 1. Source snapshot includes 1 clipped rail-way pieces, not a certified count of physical roads. Full source-specific curves, connected loops and separately mapped sidings are retained within the documented approach envelope. Platforms are not shortened decorative modules. Furniture, water points, lights, signs, waiting/ticket or appropriate service interiors, structural roof members, overhead lines, ballast/sleepers/fasteners, and relevant footbridge/stair connections are modelled.

The source scene has 755 objects, 227,444 mesh vertices and 2,946 sleeper/support placements. Rail-network local bounds: [-850.0, -4.505462990176852, 850.0, 318.1654756474451]. Nominal dimensions are explicit modelling choices, not an engineering survey.

## What is observed and what is reconstructed
Google Maps Kannan Chidambaranath May2017 ochre/white corrugated ticket hut and separate small toilet block; hidden interiors and metric siting reconstructed.



Maps contain mixed historical edit dates. An OSM edit date, Google copyright year or photo upload date is not a construction or commissioning date. Buildings, shelter spans, unmeasured platform dimensions and hidden rooms/fixtures are reconstructed. This is a source-informed visual asset, not an as-built survey, operational railway inventory, safety certificate or railway-engineering design. Signals, switch details, model clearances and service assignments are illustrative. Geometric rail-channel checks do not certify real wheel/rail operation. Compound pointwork remains simplified where the exact design is unknown.

The 45mm geometric flange channels, unioned running heads, tapered blade components and reconstructed crossing bearers avoid duplicated rail overlays in the adopted model. Procedural material noise/bump is native Blender shading. The portable glTF preserves geometry and base material properties, but those procedural textures are not baked.

## Source references
- https://www.google.com/maps/place/Amaravila/@8.3965171,77.1006601,3a,75y,90t/data=!3m8!1e2!3m6!1sCIHM0ogKEICAgICExLPMrAE!2e10!3e12!4m7!3m6!1s0x3b05ae8184fbd5af:0x5690540fa040a4ac!8m2!3d8.3965171!4d77.1006601!10e5!16s%2Fg%2F1tm110_5 | May 2017 | Ordinary contributor photograph, not a Street View panorama
- https://www.google.com/maps/place/Amaravila/@8.3965171,77.1006601,3a,75y,90t/data=!3m8!1e2!3m6!1sCIHM0ogKEICAgICExLOocA!2e10!3e12!6shttps:%2F%2Flh3.googleusercontent.com%2Fgps-cs-s%2FAHRPTWlD-SDB4aX96Pd06ubj7_4rPlAka1y-G2_EqVZoRGFCSMWD_EgR84Phw3I-nMPGSgc-mt2gpgUOGIyxKKdcroW9zMKoyjs-iFTmvtSGDgn43tvQFMbLK_8xdVhEQp-6aKJdUpXd%3Dw203-h152-k-no!7i4128!8i3096!4m7!3m6!1s0x3b05ae8184fbd5af:0x5690540fa040a4ac!8m2!3d8.3965171!4d77.1006601!10e5!16s%2Fg%2F1tm110_5?entry=ttu&g_ep=EgoyMDI2MTAwNS4wIKXMDSoASAFQAw%3D%3D | May 2017 | Ordinary contributor photograph

- https://api.openstreetmap.org/api/0.6/map?bbox=77.0913620,8.3881090,77.1093620,8.4061090 | OSM snapshot accessed2026-10-08; original way dates retained in source/layout.json
- https://indiarailinfo.com/station/blog/thiruvananthapuram-south-nemom-nem/4791 | IRI profile cross-check accessed2026-10-08; reported totals are secondary and not a signed current yard plan

## Rights
Map-derived geometry © OpenStreetMap contributors, available under ODbL1.0: https://www.openstreetmap.org/copyright and https://opendatacommons.org/licenses/odbl/1-0/ . Preserve attribution and applicable derived-database obligations. No new licence is claimed for third-party source material. No Google/photographer screenshots, station photographs or copied photo textures are distributed in this package. Authoring geometry is newly generated for this request. DejaVu and Noto lettering uses locally installed freely licensed fonts; see THIRD_PARTY_NOTICES.txt.
