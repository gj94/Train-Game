# KAPPIL (KFI) — full mapped station environment

A metre-scale, train-free scene with connected mapped running roads and service tracks, platform bodies, shelters, furnished station rooms and station-specific photographic architectural cues. This is a visual reconstruction, not a surveyed operational or signalling plan.

## Open the asset
- `KFI_coastal_station_v01.blend` is the authoritative editable scene. Generated sign images are packed; no source-photo textures are used.
- `export/KFI_coastal_station_v01.glb.zip` contains a losslessly zipped GLB. Extract before opening. The GLB has been re-imported in a fresh Blender scene; see `EXPORT_QA.json`.
- The GLB carries original mesh geometry and generated sign images. Procedural noise/paving shaders fall back to basic material colours; the full shader system remains in the Blend.
- `renders/` contains named source-scene views. `RENDER_PROVENANCE.json` records the exact source Blend SHA256 and camera pose for each render.

## Scope and dimensions
- Units: 1 Blender unit = 1 metre. Local equirectangular origin: longitude/latitude [76.6792879, 8.7795558]. X follows the local northbound railway direction, Y is the left normal; elevations are reconstructed.
- Track gauge: **1.676 m** inside the rail heads. Heads have centres ±0.872 m and width0.068 m; rail top0.178 m.
- Rail heads, webs and feet are geometric unions of mapped routes; wheel-flange channels are0.045 m wide. Guard rails are clipped against all running-head/channel footprints. Point machines and bearer assemblies are visual reconstructions, not an engineered turnout schedule.
- Platform top1.018 m; nominal platform height above rail0.840 m, reconstructed. Typical side-body width6 m; mapped bodies retain their own widths with necessary rail-clearance insets.
- Declared coverage rectangle (Xmin,Ymin,Xmax,Ymax), metres: [-1050, -230, 1100, 230]. Running lines terminate at the declared model boundary. A cropped line is not given a fabricated buffer stop.
- 4 clipped OSM way-parts, total3368.4 m of centreline, are modelled. This is a geometry-part count, **not** the number of station tracks.
- Mapped junction nodes modelled: 0. Mapped true service-track dead ends fitted with buffers: 0.
- Station building reconstruction: centre/width/depth[11.5, -2, 20, 6] m. Where a mapped envelope exists, its OSM ID is `not available`. Vertical detail and room planning are estimated.

## Platform positions versus physical bodies
India Rail Info reports **2 platform positions**; the model has **2 physical platform bodies**. No platform-position number is automatically treated as a separate island.

- Body `2`: reconstructed side body along mapped outer road; width6m, rail-centre offset1.92m; extent is approximate; sample minimum width 6.00 m, actual mesh-to-centreline minimum 1.920 m.
- Body `1`: reconstructed side body along mapped outer road; width6m, rail-centre offset1.92m; extent is approximate; sample minimum width 6.00 m, actual mesh-to-centreline minimum 1.920 m.

These widths measure the raised platform-body mesh, not unobstructed pedestrian space. Building footprints, roofs and furniture are separate geometry; the independent circulation checks describe actual usable routes.

For Kollam, the mapped body labels1/1A,2/3,4/5 remain separate from a claim of six independent bodies. Elsewhere missing body geometry and face numbering are explicitly reconstructed. Narrow taper samples are reported, not silently presented as full-width boarding zones.

## Track and operating-status evidence
- Primary identity/chainage: [Southern Railway system map,1April2025](https://sr.indianrailways.gov.in/cris/uploads/files/1748431911655-System%20Map%202025%20Signed.pdf). Station chainage172.35 km under datum `ERS via KTYM then KYJ`. A schematic system map is not a yard survey.
- Reported platform positions: [KFI/Kappil (2 PFs)](https://indiarailinfo.com/station/map/kadakavur-kvu/3523), cross-checked2026-10-08. The profile does not certify a current complete track/loop/siding inventory.
- Raw mapped observations: Two main roads mapped; platform geometry absent. No loops or separate sidings mapped.
- OSM snapshot: [2026-10-08](https://api.openstreetmap.org/api/0.6/map?bbox=76.6706300,8.7704350,76.6886300,8.7884350). Frozen raw source geometry is in`source/mapped_geometry.json`; adopted geometry, the complete graph-related route records, per-platform meshes and corrections are in`source/adopted_geometry.json`.
- Current official station-yard operating inventory remains unverified. Construction/proposed/disused tags are excluded from the operating-looking rail mesh; historic façade photographs do not prove present redevelopment completion.

## Photographic scope and reconstruction
Compact coastal halt building. Minor regularization of erroneous close mainline node documented separately; no added loops or sidings. October2017 photo guides peach flat parapet with blue accents and deep rose veranda; April2025 photo guides rough earthen/grass platform end behind narrow paved edge, not uniformly polished paving.

Hidden interiors, desks, ticket equipment, seating, partitions, toilets, exact shelter spans, bridge details and component elevations are reconstructed and explicitly labelled in scene collections. Small halts receive compact booking/waiting facilities rather than invented large concourses. The historical Kollam upper offices and maintenance pit fittings are reconstructions.

Google Images search in the cloud browser encountered an unusual-traffic check. Google Maps station-photo/Street View evidence is recorded below only when actually inspected; an ordinary contributor photo is not described as a panorama. Image capture dates and header/upload dates remain distinct. No source-image pixels or Google screenshots are included in these deliverables.

### Oct 2017 | Google Maps
Ordinary contributor photograph across tracks toward station building

- Small salmon/peach single-storey station block with long flat parapet and row of turquoise/blue rectangular accent/name panels
- Deep red/magenta sloping roof over open front veranda, four-to-five visible dark rectangular open bays supported by square peach piers
- Turquoise/blue narrow trim/side awning at right end
- Low brown-grey platform retaining wall and broad concrete steps/path toward tracks
- Nearby separate light wall building with red sloping roof; coconut palms immediately behind station

Source: https://www.google.com/maps/place/Kappil/@8.7795388,76.6786444,3a,75y,90t/data=!3m8!1e2!3m6!1sCIHM0ogKEICAgIC47YTxGA!2e10!3e12!6shttps:%2F%2Flh3.googleusercontent.com%2Fgps-cs-s%2FAHRPTWmLek4qifaw0yT09f5L3XYp122dPH9JxghqwwNhGXNxFALw36daS2LfwKsLrE8OLXn-WJnW9gE32FSFb7dw1XDlLMjrNY82HQIvbIlKu01SyNio4NERN6xfzhqzx3QPCZH6lwbc%3Dw203-h338-k-no!7i768!8i1280!4m11!1m2!2m1!1sKappil+railway+station!3m7!1s0x3b05e57b8763331f:0x946acfeaef6faeeb!8m2!3d8.7795877!4d76.6794164!10e5!15sChZLYXBwaWwgcmFpbHdheSBzdGF0aW9uWhgiFmthcHBpbCByYWlsd2F5IHN0YXRpb26SAQ10cmFpbl9zdGF0aW9umgEkQ2hkRFNVaE5NRzluUzBWSlEwRm5TVU10TFhGbGVHaG5SUkFC4AEA-gEECFgQMg!16s%2Fg%2F11fd4v6l9b?entry=ttu&g_ep=EgoyMDI2MTAwNS4wIKXMDSoASAFQAw%3D%3D

Uncertainty: Distant low-resolution view; precise text and interior dimensions unresolved; Other gallery photos show beach scenery, not station architecture
### Apr 2025 | Google Maps
Ordinary contributor photograph of station platform edge

- Very narrow grey paving/coping strip immediately along track, with mostly reddish-earth and grass walking surface behind at photographed end
- Yellow KAPPIL trilingual board between white decorative concrete posts with black bases
- Low weathered grey boundary wall and dense flowering bushes/trees directly behind narrow platform
- Small red roof visible farther along platform

Source: https://www.google.com/maps/place/Kappil/@8.7795388,76.6786444,3a,75y,90t/data=!3m8!1e2!3m6!1sCIABIhAGbyfQTifDLGfrTyYAA37O!2e10!3e12!6shttps:%2F%2Flh3.googleusercontent.com%2Fgps-cs-s%2FAHRPTWn9K8R6W49HpAMX2gnz7ztIoXu7eU0DB3UAu-DT4mIfCDKoxkd30qFmeT7NpLb-WzFLm_AYN742GU7IycEV_U-2EGHhBYgcxz5AI8qS6Q2z7l893a2rGm_ERrGUYbTrG1rTkDk3aUUeu33X%3Dw203-h114-k-no!7i4000!8i2252!4m11!1m2!2m1!1sKappil+railway+station!3m7!1s0x3b05e57b8763331f:0x946acfeaef6faeeb!8m2!3d8.7795877!4d76.6794164!10e5!15sChZLYXBwaWwgcmFpbHdheSBzdGF0aW9uWhgiFmthcHBpbCByYWlsd2F5IHN0YXRpb26SAQ10cmFpbl9zdGF0aW9umgEkQ2hkRFNVaE5NRzluUzBWSlEwRm5TVU10TFhGbGVHaG5SUkFC4AEA-gEECFgQMg!16s%2Fg%2F11fd4v6l9b?entry=ttu&g_ep=EgoyMDI2MTAwNS4wIKXMDSoASAFQAw%3D%3D

Uncertainty: Image shows one platform end; do not assume every platform surface unpaved; Do not include train

## Local geometry corrections
- Node 6041709145 / way 236119109: [2.3906, -15.2486] → [2.3906, -17.8] (2.551 m). Local mapping-artifact regularization to avoid overlapping parallel running envelopes; graph unchanged; not a surveyed correction.

## QA and rebuilding
- `BUILD_QA.json`: units, mesh/object totals, platform distinctions, packed-image state and source geometry hash.
- `EXPORT_QA.json`: lossless ZIP hash, GLB header, import counts/bounds, unchanged authoritative Blend hash.
- `source/build_station_used.py`: exact builder snapshot used for this scene. To rebuild from this snapshot, set`COASTAL_MIDDLE_ROOT` to the containing middle-batch directory and invoke Blender through the supplied shared lock wrapper, with`-- KFI`. The adopted geometry and generated sign texture are the inputs; the source Blend can always be opened directly without Python dependencies.
- Independent review status is tracked separately by the batch auditor. Do not treat an automatic generation check as a certified engineering clearance review.

## Attribution and rights
Geographic data ©[OpenStreetMap contributors](https://www.openstreetmap.org/copyright), available under[ODbL1.0](https://opendatacommons.org/licenses/odbl/1-0/). OSM-derived data is retained with provenance. Reference photographs remain with their credited photographers/providers and are **reference-only**, not included as textures or redistributed. Generated labels use Noto Sans Malayalam/Devanagari (SIL Open Font License) and DejaVu Sans; only rendered label pixels are included. Original procedural mesh/material work was produced for this project.


## Rose veranda canopy revision02
The existing thin sloping roof plane was made solid with a visible deep rose fascia and support beam, and the peach pier tops were lowered beneath it. The photographed peach parapet with blue rectangular accents is also shown on the platform-facing side. Camera04 now looks at the photographed platform facade rather than the less-documented road side. The distant2017 photograph supports the colour and canopy form; exact roof thickness and support dimensions remain reconstructed. Exterior01/03/04 are refreshed; unchanged interior05 retains its explicit base-scene lineage.


## Final source-facing proof view
KFI revision03: camera04 clears the opposite platform canopy and faces the photographed rose veranda. Its high roof attachment/support tops are refined so the blue parapet accents remain visible above it; public circulation geometry is unchanged. Geometry and camera changes are recorded exactly in ARCHITECTURE_REVISION.json and source/camera_revision_input.json. Retained image subjects have unchanged geometry/camera/lighting and keep their actual source hashes.
