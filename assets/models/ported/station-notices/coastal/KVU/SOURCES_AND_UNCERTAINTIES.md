# KADAKKAVUR (KVU) — full mapped station environment

A metre-scale, train-free scene with connected mapped running roads and service tracks, platform bodies, shelters, furnished station rooms and station-specific photographic architectural cues. This is a visual reconstruction, not a surveyed operational or signalling plan.

## Open the asset
- `KVU_coastal_station_v01.blend` is the authoritative editable scene. Generated sign images are packed; no source-photo textures are used.
- `export/KVU_coastal_station_v01.glb.zip` contains a losslessly zipped GLB. Extract before opening. The GLB has been re-imported in a fresh Blender scene; see `EXPORT_QA.json`.
- The GLB carries original mesh geometry and generated sign images. Procedural noise/paving shaders fall back to basic material colours; the full shader system remains in the Blend.
- `renders/` contains named source-scene views. `RENDER_PROVENANCE.json` records the exact source Blend SHA256 and camera pose for each render.

## Scope and dimensions
- Units: 1 Blender unit = 1 metre. Local equirectangular origin: longitude/latitude [76.7676427, 8.6786987]. X follows the local northbound railway direction, Y is the left normal; elevations are reconstructed.
- Track gauge: **1.676 m** inside the rail heads. Heads have centres ±0.872 m and width0.068 m; rail top0.178 m.
- Rail heads, webs and feet are geometric unions of mapped routes; wheel-flange channels are0.045 m wide. Guard rails are clipped against all running-head/channel footprints. Point machines and bearer assemblies are visual reconstructions, not an engineered turnout schedule.
- Platform top1.018 m; nominal platform height above rail0.840 m, reconstructed. Typical side-body width6 m; mapped bodies retain their own widths with necessary rail-clearance insets.
- Declared coverage rectangle (Xmin,Ymin,Xmax,Ymax), metres: [-1050, -230, 1100, 230]. Running lines terminate at the declared model boundary. A cropped line is not given a fabricated buffer stop.
- 8 clipped OSM way-parts, total6043.6 m of centreline, are modelled. This is a geometry-part count, **not** the number of station tracks.
- Mapped junction nodes modelled: 8. Mapped true service-track dead ends fitted with buffers: 2.
- Station building reconstruction: centre/width/depth[0.8, -3.7, 41.5, 16] m. Where a mapped envelope exists, its OSM ID is `725262299`. Vertical detail and room planning are estimated.

## Platform positions versus physical bodies
India Rail Info reports **3 platform positions**; the model has **2 physical platform bodies**. No platform-position number is automatically treated as a separate island.

- Body `1`: reconstructed side body along mapped outer road; width6m, rail-centre offset1.92m; extent is approximate; sample minimum width 6.00 m, actual mesh-to-centreline minimum 1.920 m.
- Body `2;3`: reconstructed island body in widest mapped station-road gap; face assignment unverified; sample minimum width 3.18 m, actual mesh-to-centreline minimum 1.920 m.

These widths measure the raised platform-body mesh, not unobstructed pedestrian space. Building footprints, roofs and furniture are separate geometry; the independent circulation checks describe actual usable routes.

For Kollam, the mapped body labels1/1A,2/3,4/5 remain separate from a claim of six independent bodies. Elsewhere missing body geometry and face numbering are explicitly reconstructed. Narrow taper samples are reported, not silently presented as full-width boarding zones.

## Track and operating-status evidence
- Primary identity/chainage: [Southern Railway system map,1April2025](https://sr.indianrailways.gov.in/cris/uploads/files/1748431911655-System%20Map%202025%20Signed.pdf). Station chainage188.19 km under datum `ERS via KTYM then KYJ`. A schematic system map is not a yard survey.
- Reported platform positions: [KVU/Kadakavur (3 PFs)](https://indiarailinfo.com/station/map/kadakavur-kvu/1013), cross-checked2026-10-08. The profile does not certify a current complete track/loop/siding inventory.
- Raw mapped observations: Two main roads and two outer connected loops with end extensions. Only one island-like platform polygon mapped, platform inventory incomplete.
- OSM snapshot: [2026-10-08](https://api.openstreetmap.org/api/0.6/map?bbox=76.7576720,8.6700780,76.7756720,8.6880780). Frozen raw source geometry is in`source/mapped_geometry.json`; adopted geometry, the complete graph-related route records, per-platform meshes and corrections are in`source/adopted_geometry.json`.
- Current official station-yard operating inventory remains unverified. Construction/proposed/disused tags are excluded from the operating-looking rail mesh; historic façade photographs do not prove present redevelopment completion.

## Photographic scope and reconstruction
Mapped station building and central platform body. Three platform positions use side plus island, not three islands. July2019 photo guides tall ochre front, red sheet roof, white geometric grille panels, brown clerestory windows and long sunshade.

Hidden interiors, desks, ticket equipment, seating, partitions, toilets, exact shelter spans, bridge details and component elevations are reconstructed and explicitly labelled in scene collections. Small halts receive compact booking/waiting facilities rather than invented large concourses. The historical Kollam upper offices and maintenance pit fittings are reconstructions.

Google Images search in the cloud browser encountered an unusual-traffic check. Google Maps station-photo/Street View evidence is recorded below only when actually inspected; an ordinary contributor photo is not described as a panorama. Image capture dates and header/upload dates remain distinct. No source-image pixels or Google screenshots are included in these deliverables.

### Jul 2019 | Google Maps
Ordinary contributor photograph of public station facade

- Tall yellow/ochre single-storey facade under reddish corrugated sloping roof/eave
- Long black-bordered trilingual KADAKAVUR name panel high on front, with small red-brown framed horizontal clerestory windows below
- Continuous projecting ochre concrete sunshade divides upper band from entrance
- Wide central open passage with white louvered transom; large white geometric grille panels at both sides
- Pale interior floor and opposite opening visible through passage; no full room plan implied

Source: https://www.google.com/maps/place/Kadakavur/@8.6785144,76.7676502,3a,75y,90t/data=!3m8!1e2!3m6!1sCIHM0ogKEICAgICUtMuFKg!2e10!3e12!6shttps:%2F%2Flh3.googleusercontent.com%2Fgps-cs-s%2FAHRPTWmE9GFJhDdf-u5QWjarPZo3YQ50SiLMcH73PoTghcwUZRe7YfPjCMxztSPIY6s5FiK7nVYl8RbtGeTU-hvy_PKaspDI3PTZDdWQl00xS6cR6dLNtI8Qv9u9-O_82Vex0SuGPA-P%3Dw203-h114-k-no!7i1920!8i1080!4m11!1m2!2m1!1sKadakkavoor+railway+station!3m7!1s0x3b05ebc54258d587:0x930e4703c9d6b3bd!8m2!3d8.6794254!4d76.7669056!10e5!15sChtLYWRha2thdm9vciByYWlsd2F5IHN0YXRpb25aHSIba2FkYWtrYXZvb3IgcmFpbHdheSBzdGF0aW9ukgENdHJhaW5fc3RhdGlvbpoBI0NoWkRTVWhOTUc5blMwVkpRMEZuU1VSd2F6Z3phMGwzRUFF4AEA-gEECAAQIw!16s%2Fm%2F013chxkv?entry=ttu&g_ep=EgoyMDI2MTAwNS4wIKXMDSoASAFQAw%3D%3D

Uncertainty: Cropped top-front photograph; total building footprint not measured

## Local geometry corrections
No manually displaced centreline nodes in this station.

## QA and rebuilding
- `BUILD_QA.json`: units, mesh/object totals, platform distinctions, packed-image state and source geometry hash.
- `EXPORT_QA.json`: lossless ZIP hash, GLB header, import counts/bounds, unchanged authoritative Blend hash.
- `source/build_station_used.py`: exact builder snapshot used for this scene. To rebuild from this snapshot, set`COASTAL_MIDDLE_ROOT` to the containing middle-batch directory and invoke Blender through the supplied shared lock wrapper, with`-- KVU`. The adopted geometry and generated sign texture are the inputs; the source Blend can always be opened directly without Python dependencies.
- Independent review status is tracked separately by the batch auditor. Do not treat an automatic generation check as a certified engineering clearance review.

## Attribution and rights
Geographic data ©[OpenStreetMap contributors](https://www.openstreetmap.org/copyright), available under[ODbL1.0](https://opendatacommons.org/licenses/odbl/1-0/). OSM-derived data is retained with provenance. Reference photographs remain with their credited photographers/providers and are **reference-only**, not included as textures or redistributed. Generated labels use Noto Sans Malayalam/Devanagari (SIL Open Font License) and DejaVu Sans; only rendered label pixels are included. Original procedural mesh/material work was produced for this project.


## Narrow station-edge reconstruction
The inferred six-metre side body includes about188.3m² beneath the axis-aligned mapped building envelope, treated as continuous raised foundation. It does not imply six metres of unobstructed walking space. The narrow rear veranda uses reconstructed high wall brackets rather than standing piers, with rear door leaves swinging inward. Outdoor canopy/furniture components are excluded from the building footprint. Exact building alignment and clear widths are not surveyed; source photographs guide the street facade, while the rear support arrangement is a functional reconstruction.
