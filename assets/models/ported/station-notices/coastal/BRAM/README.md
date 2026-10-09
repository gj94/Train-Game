# Balaramapuram (BRAM) • complete station environment v01

Editable full-size Blender scene, five rendered review views, and a self-contained portable glTF archive. No trains or other rolling stock.

## Files
- BRAM_station_v01.blend: authoritative editable scene, materials, cameras and packed font resources
- renders/: full network, station architecture, platform/track view, furnished interior, railway detail
- exchange/BRAM_portable_GLTF.zip: losslessly archived GLB, verified against the raw export
- SOURCES.json: evidence links, dates and limitations
- QA_BUILD.json, QA_EXPORT.json and RENDER_PROVENANCE.json: measured model properties and exact source/render/export hashes
- source/: metric source-derived geometry, available native name outlines and documentary build/repair recipes

Recipe snapshots document the construction and narrow repairs. The packed scene is authoritative; these scripts are not a standalone one-click rebuild and refer to the region staging layout and shared locked Blender launcher.

## Scale and coverage
Metres, scene scale1.0. Broad-gauge running head inner faces1.676m apart. Modeled platform bodies: 1; IRI reported platform positions: 1. Source snapshot includes 1 clipped rail-way pieces, not a certified count of physical roads. Full source-specific curves, connected loops and separately mapped sidings are retained within the documented approach envelope. Platforms are not shortened decorative modules. Furniture, water points, lights, signs, waiting/ticket or appropriate service interiors, structural roof members, overhead lines, ballast/sleepers/fasteners, and relevant footbridge/stair connections are modelled.

The source scene has 739 objects, 228,874 mesh vertices and 2,856 sleeper/support placements. Rail-network local bounds: [-850.0, -91.26536619745771, 850.0, 27.464810145788647]. Nominal dimensions are explicit modelling choices, not an engineering survey.

## What is observed and what is reconstructed
Google Maps Born to guide August2022 stepped corbel and turquoise-trim frontage, Prem Kumar January2022 ticket hatch; side and metric building/platform placement inferred.

The original platform polygon crosses the mapped running centreline. A usable parallel body is reconstructed toward the station-marker/access side; exact width, side and extent are not independently measured or fully visible in the satellite. The raw source polygon remains in source/layout.json. Proposed Vizhinjam freight infrastructure is excluded.

Maps contain mixed historical edit dates. An OSM edit date, Google copyright year or photo upload date is not a construction or commissioning date. Buildings, shelter spans, unmeasured platform dimensions and hidden rooms/fixtures are reconstructed. This is a source-informed visual asset, not an as-built survey, operational railway inventory, safety certificate or railway-engineering design. Signals, switch details, model clearances and service assignments are illustrative. Geometric rail-channel checks do not certify real wheel/rail operation. Compound pointwork remains simplified where the exact design is unknown.

The 45mm geometric flange channels, unioned running heads, tapered blade components and reconstructed crossing bearers avoid duplicated rail overlays in the adopted model. Procedural material noise/bump is native Blender shading. The portable glTF preserves geometry and base material properties, but those procedural textures are not baked.

## Source references
- https://www.google.com/maps/place/Balaramapuram/@8.4308609,77.0513341,225m/data=!3m1!1e3!4m6!3m5!1s0x3b05afcdc511c657:0x3ff909371aad29f6!8m2!3d8.4308609!4d77.0513341!16s%2Fg%2F1v3kfydn?entry=ttu&g_ep=EgoyMDI2MTAwNS4wIKXMDSoASAFQAw%3D%3D | Not exposed | Google Maps satellite visually inspected
- https://www.google.com/maps/place/Balaramapuram/@8.4311594,77.0508883,3a,75y,90t/data=!3m8!1e2!3m6!1sCIHM0ogKEICAgIDumf6tywE!2e10!3e12!6shttps:%2F%2Flh3.googleusercontent.com%2Fgps-cs-s%2FAHRPTWkkFoW-sai3HkZi1Pg_N_1txIsZNJ0oQ-4JZLh26GdBVsbJfea2Vp6vkIsoBuXypXq1WDeDEUIOEetF5xd9eKxL5C67IBuH960mSYn0kwp85YkZIq9d8MNjwnsm2v2zXy2_1FdllA%3Dw203-h114-k-no!7i1920!8i1080!4m7!3m6!1s0x3b05afcdc511c657:0x3ff909371aad29f6!8m2!3d8.4308609!4d77.0513341!10e5!16s%2Fg%2F1v3kfydn?entry=ttu&g_ep=EgoyMDI2MTAwNS4wIKXMDSoASAFQAw%3D%3D | Aug 2022 | Ordinary contributor photograph of station building entrance
- https://www.google.com/maps/place/Balaramapuram/@8.4311594,77.0508883,3a,75y,90t/data=!3m8!1e2!3m6!1sCIHM0ogKEICAgIDOzvjGlAE!2e10!3e12!6shttps:%2F%2Flh3.googleusercontent.com%2Fgps-cs-s%2FAHRPTWmS8bHrxqbhW0iS_GKsNzGP9Sl_xU7IPvuewVWD8VltYMPgFLyAa4gHokUlvjifmASiMmB6EtxKOIz9PN5cp--XZl9YYFNTyvvNjTG0slCMFRrwKGrP5xeppaMAzlARK1XJuXsZ3A%3Dw203-h152-k-no!7i4160!8i3120!4m7!3m6!1s0x3b05afcdc511c657:0x3ff909371aad29f6!8m2!3d8.4308609!4d77.0513341!10e5!16s%2Fg%2F1v3kfydn?entry=ttu&g_ep=EgoyMDI2MTAwNS4wIKXMDSoASAFQAw%3D%3D | Image capture Jan 2022; photo header Jul 2022 | Ordinary contributor photograph of public ticket counter

- https://api.openstreetmap.org/api/0.6/map?bbox=77.0423209,8.4211075,77.0603209,8.4391075 | OSM snapshot accessed2026-10-08; original way dates retained in source/layout.json
- https://indiarailinfo.com/station/map/thiruvananthapuram-central-trivandrum-tvc/3529 | IRI profile cross-check accessed2026-10-08; reported totals are secondary and not a signed current yard plan

## Rights
Map-derived geometry © OpenStreetMap contributors, available under ODbL1.0: https://www.openstreetmap.org/copyright and https://opendatacommons.org/licenses/odbl/1-0/ . Preserve attribution and applicable derived-database obligations. No new licence is claimed for third-party source material. No Google/photographer screenshots, station photographs or copied photo textures are distributed in this package. Authoring geometry is newly generated for this request. DejaVu and Noto lettering uses locally installed freely licensed fonts; see THIRD_PARTY_NOTICES.txt.
