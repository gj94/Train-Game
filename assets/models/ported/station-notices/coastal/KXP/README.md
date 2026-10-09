# Kaniyapuram (KXP) • complete station environment v01

Editable full-size Blender scene, five rendered review views, and a self-contained portable glTF archive. No trains or other rolling stock.

## Files
- KXP_station_v01.blend: authoritative editable scene, materials, cameras and packed font resources
- renders/: full network, station architecture, platform/track view, furnished interior, railway detail
- exchange/KXP_portable_GLTF.zip: losslessly archived GLB, verified against the raw export
- SOURCES.json: evidence links, dates and limitations
- QA_BUILD.json, QA_EXPORT.json and RENDER_PROVENANCE.json: measured model properties and exact source/render/export hashes
- source/: metric source-derived geometry, available native name outlines and documentary build/repair recipes

Recipe snapshots document the construction and narrow repairs. The packed scene is authoritative; these scripts are not a standalone one-click rebuild and refer to the region staging layout and shared locked Blender launcher.

## Scale and coverage
Metres, scene scale1.0. Broad-gauge running head inner faces1.676m apart. Modeled platform bodies: 2; IRI reported platform positions: 2. Source snapshot includes 2 clipped rail-way pieces, not a certified count of physical roads. Full source-specific curves, connected loops and separately mapped sidings are retained within the documented approach envelope. Platforms are not shortened decorative modules. Furniture, water points, lights, signs, waiting/ticket or appropriate service interiors, structural roof members, overhead lines, ballast/sleepers/fasteners, and relevant footbridge/stair connections are modelled.

The source scene has 864 objects, 446,740 mesh vertices and 5,668 sleeper/support placements. Rail-network local bounds: [-850.0, -18.41317003407437, 850.0, -10.11681170321351]. Nominal dimensions are explicit modelling choices, not an engineering survey.

## What is observed and what is reconstructed
Google Maps November2017 bungalow-like building and January2023 fabricated pale footbridge; hidden room plans reconstructed.



Maps contain mixed historical edit dates. An OSM edit date, Google copyright year or photo upload date is not a construction or commissioning date. Buildings, shelter spans, unmeasured platform dimensions and hidden rooms/fixtures are reconstructed. This is a source-informed visual asset, not an as-built survey, operational railway inventory, safety certificate or railway-engineering design. Signals, switch details, model clearances and service assignments are illustrative. Geometric rail-channel checks do not certify real wheel/rail operation. Compound pointwork remains simplified where the exact design is unknown.

The 45mm geometric flange channels, unioned running heads, tapered blade components and reconstructed crossing bearers avoid duplicated rail overlays in the adopted model. Procedural material noise/bump is native Blender shading. The portable glTF preserves geometry and base material properties, but those procedural textures are not baked.

## Source references
- https://www.google.com/maps/place/Kaniyapuram/@8.5870837,76.8545099,3a,75y,90t/data=!3m8!1e2!3m6!1sCIHM0ogKEICAgIDBosnCew!2e10!3e12!6shttps:%2F%2Flh3.googleusercontent.com%2Fgps-cs-s%2FAHRPTWk53f0GsW7F96BtEgXoajps3IIN8dq9JDIBBotiXgO9LyMPTsBaPAuQQ4cNGTXyISANDtRPeLi6c0PTFh7BnlhGe7hx081rUysbkQquIazzzsQYzkiVjYMoDHIibakjz0jz_YU6%3Dw203-h114-k-no!7i4624!8i2600!4m11!1m2!2m1!1sKaniyapuram+railway+station!3m7!1s0x3b05bf95e4deacf9:0xc89e18687b8a6689!8m2!3d8.5870837!4d76.8545099!10e5!15sChtLYW5peWFwdXJhbSByYWlsd2F5IHN0YXRpb25aHSIba2FuaXlhcHVyYW0gcmFpbHdheSBzdGF0aW9ukgENdHJhaW5fc3RhdGlvbpoBRENpOURRVWxSUVVOdlpFTm9kSGxqUmpsdlQyczVSbFZ1U21oT01qbEZWV3RXUTJKcVNqQlhRekZoVFcxMFVXUklZeEFC4AEA-gEECAAQGw!16s%2Fg%2F1ttdlf08?entry=ttu&g_ep=EgoyMDI2MTAwNS4wIKXMDSoASAFQAw%3D%3D | Jan 2023 | Ordinary contributor photograph of covered footbridge
- https://www.google.com/maps/place/Kaniyapuram/@8.5874944,76.8544214,3a,75y,90t/data=!3m8!1e2!3m6!1sCIHM0ogKEICAgIDEx97UsAE!2e10!3e12!6shttps:%2F%2Flh3.googleusercontent.com%2Fgps-cs-s%2FAHRPTWnXvoZilIJrGWHYiegth04yjzPz9t51QNO7GZziIxxHGzI-h3AkVU6v-rbAteWyoQJxAGysvM2gPgyEbtQGxafmOrtv1mQ3UWwMUPpzzno2FU_3YSUkzNJdiU0F46oGXShvGF6M%3Dw203-h152-k-no!7i5344!8i4008!4m11!1m2!2m1!1sKaniyapuram+railway+station!3m7!1s0x3b05bf95e4deacf9:0xc89e18687b8a6689!8m2!3d8.5870837!4d76.8545099!10e5!15sChtLYW5peWFwdXJhbSByYWlsd2F5IHN0YXRpb25aHSIba2FuaXlhcHVyYW0gcmFpbHdheSBzdGF0aW9ukgENdHJhaW5fc3RhdGlvbpoBRENpOURRVWxSUVVOdlpFTm9kSGxqUmpsdlQyczVSbFZ1U21oT01qbEZWV3RXUTJKcVNqQlhRekZoVFcxMFVXUklZeEFC4AEA-gEECAAQGw!16s%2Fg%2F1ttdlf08?entry=ttu&g_ep=EgoyMDI2MTAwNS4wIKXMDSoASAFQAw%3D%3D | Nov 2017 | Ordinary contributor photograph of station approach building

- https://api.openstreetmap.org/api/0.6/map?bbox=76.8454820,8.5786120,76.8634820,8.5966120 | OSM snapshot accessed2026-10-08; original way dates retained in source/layout.json
- https://indiarailinfo.com/station/map/kadakavur-kvu/3527 | IRI profile cross-check accessed2026-10-08; reported totals are secondary and not a signed current yard plan

## Rights
Map-derived geometry © OpenStreetMap contributors, available under ODbL1.0: https://www.openstreetmap.org/copyright and https://opendatacommons.org/licenses/odbl/1-0/ . Preserve attribution and applicable derived-database obligations. No new licence is claimed for third-party source material. No Google/photographer screenshots, station photographs or copied photo textures are distributed in this package. Authoring geometry is newly generated for this request. DejaVu and Noto lettering uses locally installed freely licensed fonts; see THIRD_PARTY_NOTICES.txt.
