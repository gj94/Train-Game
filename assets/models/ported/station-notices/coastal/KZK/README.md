# Kazhakuttam (KZK) • complete station environment v01

Editable full-size Blender scene, five rendered review views, and a self-contained portable glTF archive. No trains or other rolling stock.

## Files
- KZK_station_v01.blend: authoritative editable scene, materials, cameras and packed font resources
- renders/: full network, station architecture, platform/track view, furnished interior, railway detail
- exchange/KZK_portable_GLTF.zip: losslessly archived GLB, verified against the raw export
- SOURCES.json: evidence links, dates and limitations
- QA_BUILD.json, QA_EXPORT.json and RENDER_PROVENANCE.json: measured model properties and exact source/render/export hashes
- source/: metric source-derived geometry, available native name outlines and documentary build/repair recipes

Recipe snapshots document the construction and narrow repairs. The packed scene is authoritative; these scripts are not a standalone one-click rebuild and refer to the region staging layout and shared locked Blender launcher.

## Scale and coverage
Metres, scene scale1.0. Broad-gauge running head inner faces1.676m apart. Modeled platform bodies: 2; IRI reported platform positions: 3. Source snapshot includes 11 clipped rail-way pieces, not a certified count of physical roads. Full source-specific curves, connected loops and separately mapped sidings are retained within the documented approach envelope. Platforms are not shortened decorative modules. Furniture, water points, lights, signs, waiting/ticket or appropriate service interiors, structural roof members, overhead lines, ballast/sleepers/fasteners, and relevant footbridge/stair connections are modelled.

The source scene has 1,113 objects, 1,106,393 mesh vertices and 16,267 sleeper/support placements. Rail-network local bounds: [-1350.0, -303.106552828031, 1350.0, 5.519289348709254]. Nominal dimensions are explicit modelling choices, not an engineering survey.

## What is observed and what is reconstructed
Google Maps Raijo V James August2023 station entrance; undated Google satellite side+island layout and south bridge.

The east side platform and west island are distinct from the much farther western FCI industrial sidings. Four close passenger-road alignments and separate mapped industrial branches are retained. Exact operational role of each road is unverified.

Maps contain mixed historical edit dates. An OSM edit date, Google copyright year or photo upload date is not a construction or commissioning date. Buildings, shelter spans, unmeasured platform dimensions and hidden rooms/fixtures are reconstructed. This is a source-informed visual asset, not an as-built survey, operational railway inventory, safety certificate or railway-engineering design. Signals, switch details, model clearances and service assignments are illustrative. Geometric rail-channel checks do not certify real wheel/rail operation. Compound pointwork remains simplified where the exact design is unknown.

The 45mm geometric flange channels, unioned running heads, tapered blade components and reconstructed crossing bearers avoid duplicated rail overlays in the adopted model. Procedural material noise/bump is native Blender shading. The portable glTF preserves geometry and base material properties, but those procedural textures are not baked.

## Source references
- https://www.google.com/maps/place/Kazhakuttam/@8.5571261,76.8725282,224m/data=!3m1!1e3!4m6!3m5!1s0x3b05bef879d8164f:0x6dffefba165c07cc!8m2!3d8.5571261!4d76.8725282!16s%2Fm%2F0j42789?entry=ttu&g_ep=EgoyMDI2MTAwNS4wIKXMDSoASAFQAw%3D%3D | Not exposed | Google Maps satellite visually inspected
- https://www.google.com/maps/place/Kazhakuttam/@8.5569929,76.8728577,3a,75y,90t/data=!3m8!1e2!3m6!1sCIHM0ogKEICAgIDpsa-ctgE!2e10!3e12!6shttps:%2F%2Flh3.googleusercontent.com%2Fgps-cs-s%2FAHRPTWm9aMpN9RwXKWtdWfJHDNdWiMKJ01bsExoVrFiEABk_LiTyWOncQqZG0Vxwm30aJWlVufKiLIOhINt5AFBzvqt3JbOGVfv1t3F5pRuXekDjDcH1iyMuTAh8bq5K7lC8RVTZ2FKB%3Dw203-h152-k-no!7i3280!8i2464!4m7!3m6!1s0x3b05bef879d8164f:0x6dffefba165c07cc!8m2!3d8.5571261!4d76.8725282!10e5!16s%2Fm%2F0j42789?entry=ttu&g_ep=EgoyMDI2MTAwNS4wIKXMDSoASAFQAw%3D%3D | Aug 2023 | Ordinary contributor photograph of station entrance

- https://api.openstreetmap.org/api/0.6/map?bbox=76.8632350,8.5468480,76.8812350,8.5648480 | OSM snapshot accessed2026-10-08; original way dates retained in source/layout.json
- https://indiarailinfo.com/station/map/kazhakkuttam-kzk/2764 | IRI profile cross-check accessed2026-10-08; reported totals are secondary and not a signed current yard plan

## Rights
Map-derived geometry © OpenStreetMap contributors, available under ODbL1.0: https://www.openstreetmap.org/copyright and https://opendatacommons.org/licenses/odbl/1-0/ . Preserve attribution and applicable derived-database obligations. No new licence is claimed for third-party source material. No Google/photographer screenshots, station photographs or copied photo textures are distributed in this package. Authoring geometry is newly generated for this request. DejaVu and Noto lettering uses locally installed freely licensed fonts; see THIRD_PARTY_NOTICES.txt.
