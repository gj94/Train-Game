# Parassala (PASA) • complete station environment v01

Editable full-size Blender scene, five rendered review views, and a self-contained portable glTF archive. No trains or other rolling stock.

## Files
- PASA_station_v01.blend: authoritative editable scene, materials, cameras and packed font resources
- renders/: full network, station architecture, platform/track view, furnished interior, railway detail
- exchange/PASA_portable_GLTF.zip: losslessly archived GLB, verified against the raw export
- SOURCES.json: evidence links, dates and limitations
- QA_BUILD.json, QA_EXPORT.json and RENDER_PROVENANCE.json: measured model properties and exact source/render/export hashes
- source/: metric source-derived geometry, available native name outlines and documentary build/repair recipes

Recipe snapshots document the construction and narrow repairs. The packed scene is authoritative; these scripts are not a standalone one-click rebuild and refer to the region staging layout and shared locked Blender launcher.

## Scale and coverage
Metres, scene scale1.0. Broad-gauge running head inner faces1.676m apart. Modeled platform bodies: 2; IRI reported platform positions: 2. Source snapshot includes 4 clipped rail-way pieces, not a certified count of physical roads. Full source-specific curves, connected loops and separately mapped sidings are retained within the documented approach envelope. Platforms are not shortened decorative modules. Furniture, water points, lights, signs, waiting/ticket or appropriate service interiors, structural roof members, overhead lines, ballast/sleepers/fasteners, and relevant footbridge/stair connections are modelled.

The source scene has 913 objects, 398,829 mesh vertices and 4,666 sleeper/support placements. Rail-network local bounds: [-850.0, 16.0486787506569, 850.0, 240.67287534874836]. Nominal dimensions are explicit modelling choices, not an engineering survey.

## What is observed and what is reconstructed
Google Maps Sooraj SL image captureJune2026 (headerAugust2026): pale pink/white low wings, shallow brown-red tile roofs, raised central name wall, small rear gable and low projecting gabled entrance portico. Hidden rooms and measured dimensions reconstructed.



Maps contain mixed historical edit dates. An OSM edit date, Google copyright year or photo upload date is not a construction or commissioning date. Buildings, shelter spans, unmeasured platform dimensions and hidden rooms/fixtures are reconstructed. This is a source-informed visual asset, not an as-built survey, operational railway inventory, safety certificate or railway-engineering design. Signals, switch details, model clearances and service assignments are illustrative. Geometric rail-channel checks do not certify real wheel/rail operation. Compound pointwork remains simplified where the exact design is unknown.

The 45mm geometric flange channels, unioned running heads, tapered blade components and reconstructed crossing bearers avoid duplicated rail overlays in the adopted model. Procedural material noise/bump is native Blender shading. The portable glTF preserves geometry and base material properties, but those procedural textures are not baked.

## Source references
- https://www.google.com/maps/place/Parassala+railway+station+-+PASA/@8.3395959,77.1657685,3a,75y,90t/data=!3m8!1e2!3m6!1sCIABIhDXkW2ptv1jY8rQ9vpE4k5A!2e10!3e12!6shttps:%2F%2Flh3.googleusercontent.com%2Fgrass-cs%2FAABkmLee-jeSuLI_7G2Lfx0WJbYo6z_US47ZmmO4ZYOCB6DHmeTqUp_9mgKXYWxd77yoDUJWYiV5VJmdKV-tesTyi5OOZU-XT0C6n26OCuOuEHJQwVyDqi0i_rZZCsbq7iPn-l3W6N0syQtbGxIg%3Dw152-h86-k-no!7i3840!8i2160!4m11!1m2!2m1!1sParassala+railway+station!3m7!1s0x3b05ab14341a4bdf:0x3704ddc3129c52e!8m2!3d8.3396498!4d77.1658846!10e5!15sChlQYXJhc3NhbGEgcmFpbHdheSBzdGF0aW9uWhsiGXBhcmFzc2FsYSByYWlsd2F5IHN0YXRpb26SAQt0cmFpbl9kZXBvdJoBJENoZERTVWhOTUc5blMwVkpRMEZuU1VOQ2FUVnVOR2gzUlJBQuABAPoBBAgiEEo!16s%2Fg%2F1tp1x7l1?entry=ttu&g_ep=EgoyMDI2MTAwNS4wIKXMDSoASAFQAw%3D%3D | Image capture Jun 2026; photo header Aug 2026 | Ordinary contributor photograph of station road frontage

- https://api.openstreetmap.org/api/0.6/map?bbox=77.1564897,8.3308400,77.1744897,8.3488400 | OSM snapshot accessed2026-10-08; original way dates retained in source/layout.json
- https://indiarailinfo.com/station/map/parassala-pasa/1011 | IRI profile cross-check accessed2026-10-08; reported totals are secondary and not a signed current yard plan

## Rights
Map-derived geometry © OpenStreetMap contributors, available under ODbL1.0: https://www.openstreetmap.org/copyright and https://opendatacommons.org/licenses/odbl/1-0/ . Preserve attribution and applicable derived-database obligations. No new licence is claimed for third-party source material. No Google/photographer screenshots, station photographs or copied photo textures are distributed in this package. Authoring geometry is newly generated for this request. DejaVu and Noto lettering uses locally installed freely licensed fonts; see THIRD_PARTY_NOTICES.txt.
