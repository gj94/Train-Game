# KARUNAGAPPALLI (KPY) — full mapped station environment

A metre-scale, train-free scene with connected mapped running roads and service tracks, platform bodies, shelters, furnished station rooms and station-specific photographic architectural cues. This is a visual reconstruction, not a surveyed operational or signalling plan.

## Open the asset
- `KPY_coastal_station_v01.blend` is the authoritative editable scene. Generated sign images are packed; no source-photo textures are used.
- `export/KPY_coastal_station_v01.glb.zip` contains a losslessly zipped GLB. Extract before opening. The GLB has been re-imported in a fresh Blender scene; see `EXPORT_QA.json`.
- The GLB carries original mesh geometry and generated sign images. Procedural noise/paving shaders fall back to basic material colours; the full shader system remains in the Blend.
- `renders/` contains named source-scene views. `RENDER_PROVENANCE.json` records the exact source Blend SHA256 and camera pose for each render.

## Scope and dimensions
- Units: 1 Blender unit = 1 metre. Local equirectangular origin: longitude/latitude [76.5446447, 9.0652253]. X follows the local northbound railway direction, Y is the left normal; elevations are reconstructed.
- Track gauge: **1.676 m** inside the rail heads. Heads have centres ±0.872 m and width0.068 m; rail top0.178 m.
- Rail heads, webs and feet are geometric unions of mapped routes; wheel-flange channels are0.045 m wide. Guard rails are clipped against all running-head/channel footprints. Point machines and bearer assemblies are visual reconstructions, not an engineered turnout schedule.
- Platform top1.018 m; nominal platform height above rail0.840 m, reconstructed. Typical side-body width6 m; mapped bodies retain their own widths with necessary rail-clearance insets.
- Declared coverage rectangle (Xmin,Ymin,Xmax,Ymax), metres: [-2400, -430, 1700, 1630]. Running lines terminate at the declared model boundary. A cropped line is not given a fabricated buffer stop.
- 19 clipped OSM way-parts, total14787.4 m of centreline, are modelled. This is a geometry-part count, **not** the number of station tracks.
- Mapped junction nodes modelled: 21. Mapped true service-track dead ends fitted with buffers: 5.
- Station building reconstruction: centre/width/depth[-30, 27, 49, 11] m. Where a mapped envelope exists, its OSM ID is `not available`. Vertical detail and room planning are estimated.

## Platform positions versus physical bodies
India Rail Info reports **3 platform positions**; the model has **2 physical platform bodies**. No platform-position number is automatically treated as a separate island.

- Body `1`: reconstructed side body along mapped outer road; width6m, rail-centre offset1.92m; extent is approximate; sample minimum width 6.00 m, actual mesh-to-centreline minimum 1.909 m.
- Body `2;3`: reconstructed island body in widest mapped station-road gap; face assignment unverified; sample minimum width 2.42 m, actual mesh-to-centreline minimum 1.920 m.

These widths measure the raised platform-body mesh, not unobstructed pedestrian space. Building footprints, roofs and furniture are separate geometry; the independent circulation checks describe actual usable routes.

For Kollam, the mapped body labels1/1A,2/3,4/5 remain separate from a claim of six independent bodies. Elsewhere missing body geometry and face numbering are explicitly reconstructed. Narrow taper samples are reported, not silently presented as full-width boarding zones.

## Track and operating-status evidence
- Primary identity/chainage: [Southern Railway system map,1April2025](https://sr.indianrailways.gov.in/cris/uploads/files/1748431911655-System%20Map%202025%20Signed.pdf). Station chainage128.25 km under datum `ERS via KTYM then KYJ`. A schematic system map is not a yard survey.
- Reported platform positions: [KPY/Karunagappalli (3 PFs)](https://indiarailinfo.com/station/map/karunagappalli-kpy/570), cross-checked2026-10-08. The profile does not certify a current complete track/loop/siding inventory.
- Raw mapped observations: Two main roads and two connected outer loops visible; industrial spurs and several stubs mapped. Total siding inventory unresolved; platform geometry absent.
- OSM snapshot: [2026-10-08](https://api.openstreetmap.org/api/0.6/map?bbox=76.5350230,9.0562680,76.5530230,9.0742680). Frozen raw source geometry is in`source/mapped_geometry.json`; adopted geometry, the complete graph-related route records, per-platform meshes and corrections are in`source/adopted_geometry.json`.
- Current official station-yard operating inventory remains unverified. Construction/proposed/disused tags are excluded from the operating-looking rail mesh; historic façade photographs do not prove present redevelopment completion.

## Photographic scope and reconstruction
Three reported platform positions represented as one side and one island; industrial spur geometry included to mapped endpoints. Building footprint is approximate, absent from mapped inventory. Historic2017 white-and-salmon clerestory facade reconstructed separately from2023 flat-roof service block. Satellite evidence fixes the east island between ways641467876/661604986 and western building-side platform outside546893500. The additional641478855 goods/siding alignment remains fully modelled and is not mistaken for a platform-defining outer loop.

Hidden interiors, desks, ticket equipment, seating, partitions, toilets, exact shelter spans, bridge details and component elevations are reconstructed and explicitly labelled in scene collections. Small halts receive compact booking/waiting facilities rather than invented large concourses. The historical Kollam upper offices and maintenance pit fittings are reconstructions.

Google Images search in the cloud browser encountered an unusual-traffic check. Google Maps station-photo/Street View evidence is recorded below only when actually inspected; an ordinary contributor photo is not described as a panorama. Image capture dates and header/upload dates remain distinct. No source-image pixels or Google screenshots are included in these deliverables.

### Not exposed | Google Maps
Google Maps satellite visually inspected

- West station-building/approach side platform alongside Railway Station Road, with separated grey shelter roofs
- East developed platform body appears island with platform-edge rail alignment on its east and mainline gap on west; multiple separate rectangular grey shelters
- Passenger facilities confined to narrow central railway corridor; industrial sidings and large warehouses well west beyond approach road
- Southern main access/parking lies west of platforms; station label near northern shelter cluster

Source: https://www.google.com/maps/place/Karunagappalli/@9.0663604,76.5442173,224m/data=!3m1!1e3!4m6!3m5!1s0x3b060386c7e7d78d:0xa240b6d7421dd18a!8m2!3d9.0663604!4d76.5442173!16s%2Fm%2F011v7skn?entry=ttu&g_ep=EgoyMDI2MTAwNS4wIKXMDSoASAFQAw%3D%3D

Uncertainty: Islanding interpretation from two edges and four passenger roads; exact centrelines should be checked against screenshot; Satellite acquisition date unavailable
### May 2023 | Google Maps
Genuine Google Street View panorama; road coverage blue line opened and rotated

- West approach road is narrow asphalt with white edge stripes and tree-lined verge, station elevated slightly above it
- Beside station: tall rectangular water tank on four muted red/pink concrete legs and cross bracing
- Trackside auxiliary/service block is long pale cream/white flat-roofed building with thin reddish horizontal bands, a row of dark vertical windows/vents, and elevated open undercroft on short piers
- Blue platform canopy visible behind service building

Source: https://www.google.com/maps/place/Karunagappalli/@9.0660338,76.5441334,35a,75y,90h,90t/data=!3m7!1e1!3m5!1sUkDrOri5TcUGaBbWVN_xfQ!2e0!6shttps:%2F%2Fstreetviewpixels-pa.googleapis.com%2Fv1%2Fthumbnail%3Fcb_client%3Dmaps_sv.tactile%26w%3D900%26h%3D600%26pitch%3D0%26panoid%3DUkDrOri5TcUGaBbWVN_xfQ%26yaw%3D90!7i13312!8i6656!4m6!3m5!1s0x3b060386c7e7d78d:0xa240b6d7421dd18a!8m2!3d9.0663604!4d76.5442173!16s%2Fm%2F011v7skn?entry=ttu&g_ep=EgoyMDI2MTAwNS4wIKXMDSoASAFQAw%3D%3D

Uncertainty: Service-block function inferred from position and blank rear facade, not verified; do not label as passenger entrance; Capture May2023 may predate redevelopment
### Dec 2019 | Google Maps
Ordinary contributor photograph of island platform

- Narrow island platform visibly has tracks both sides
- Red rectangular-grid tile strip along one edge with yellow line bounding it; weathered dark-grey concrete/asphalt walking strip
- OHE portal gantry spans multiple roads; platform tapers in distance

Source: https://www.google.com/maps/place/Karunagappalli/@9.0663604,76.5442173,3a,75y,90t/data=!3m8!1e2!3m6!1sCIHM0ogKEICAgICcnrOhaQ!2e10!3e12!6shttps:%2F%2Flh3.googleusercontent.com%2Fgps-cs-s%2FAHRPTWlScykyLLSN_QT9pb4pNKDyJg3wwujeY9y0NihrIVv-iDyaIUSq6iKzZBb8A59ni5k_VID6AV3p-N1yKEfVrL9trl8H5DrVvZM3nbOAh5jA-mPt3yZyR7otEHlxtHgKQGZjb9c%3Dw203-h270-k-no!7i3120!8i4160!4m7!3m6!1s0x3b060386c7e7d78d:0xa240b6d7421dd18a!8m2!3d9.0663604!4d76.5442173!10e5!16s%2Fm%2F011v7skn?entry=ttu&g_ep=EgoyMDI2MTAwNS4wIKXMDSoASAFQAw%3D%3D

Uncertainty: No trains to be included in model despite reference train; Image does not independently label platform numbers
### Sep 2017 | Google Maps
Ordinary contributor photograph of older station building

- Long old white station block with salmon-pink vertical wall panels and central raised triangular cross-gable
- Pitched reddish-brown tiled roof over tall loft/clerestory wall with small rectangular vents
- Dark projecting continuous mid-level eave divides high clerestory and ground-floor windows/doors
- Large dark glazed rectangular front windows; lower attached wing extends left
- Small yellow picket garden fence and planted flower bed at front; tracks/siding visible in immediate foreground

Source: https://www.google.com/maps/place/Karunagappalli/@9.0663604,76.5442173,3a,75y,90t/data=!3m8!1e2!3m6!1sCIHM0ogKEICAgICE56CKYg!2e10!3e12!6shttps:%2F%2Flh3.googleusercontent.com%2Fgps-cs-s%2FAHRPTWk04CqOaE_lPqmrXLVp1GgkolaXtcsHAwTZbi-iFg7zfk89Kuony7eZySp3ticPPGVf1Or7pxR5xdkflC438JGrwYSp3kHOLr30Ci0vJS97nB5WcIJrC-ktBxo5vXN8z6gfIG8%3Dw203-h114-k-no!7i4128!8i2322!4m7!3m6!1s0x3b060386c7e7d78d:0xa240b6d7421dd18a!8m2!3d9.0663604!4d76.5442173!10e5!16s%2Fm%2F011v7skn?entry=ttu&g_ep=EgoyMDI2MTAwNS4wIKXMDSoASAFQAw%3D%3D

Uncertainty: Historical building image; current facade changes not established; Relationship of photographed rail to running lines requires overhead alignment

## Local geometry corrections
No manually displaced centreline nodes in this station.

## QA and rebuilding
- `BUILD_QA.json`: units, mesh/object totals, platform distinctions, packed-image state and source geometry hash.
- `EXPORT_QA.json`: lossless ZIP hash, GLB header, import counts/bounds, unchanged authoritative Blend hash.
- `source/build_station_used.py`: exact builder snapshot used for this scene. To rebuild from this snapshot, set`COASTAL_MIDDLE_ROOT` to the containing middle-batch directory and invoke Blender through the supplied shared lock wrapper, with`-- KPY`. The adopted geometry and generated sign texture are the inputs; the source Blend can always be opened directly without Python dependencies.
- Independent review status is tracked separately by the batch auditor. Do not treat an automatic generation check as a certified engineering clearance review.

## Attribution and rights
Geographic data ©[OpenStreetMap contributors](https://www.openstreetmap.org/copyright), available under[ODbL1.0](https://opendatacommons.org/licenses/odbl/1-0/). OSM-derived data is retained with provenance. Reference photographs remain with their credited photographers/providers and are **reference-only**, not included as textures or redistributed. Generated labels use Noto Sans Malayalam/Devanagari (SIL Open Font License) and DejaVu Sans; only rendered label pixels are included. Original procedural mesh/material work was produced for this project.
