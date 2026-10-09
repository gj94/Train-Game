# MUNROTURUTTU (MQO) — full mapped station environment

A metre-scale, train-free scene with connected mapped running roads and service tracks, platform bodies, shelters, furnished station rooms and station-specific photographic architectural cues. This is a visual reconstruction, not a surveyed operational or signalling plan.

## Open the asset
- `MQO_coastal_station_v01.blend` is the authoritative editable scene. Generated sign images are packed; no source-photo textures are used.
- `export/MQO_coastal_station_v01.glb.zip` contains a losslessly zipped GLB. Extract before opening. The GLB has been re-imported in a fresh Blender scene; see `EXPORT_QA.json`.
- The GLB carries original mesh geometry and generated sign images. Procedural noise/paving shaders fall back to basic material colours; the full shader system remains in the Blend.
- `renders/` contains named source-scene views. `RENDER_PROVENANCE.json` records the exact source Blend SHA256 and camera pose for each render.

## Scope and dimensions
- Units: 1 Blender unit = 1 metre. Local equirectangular origin: longitude/latitude [76.6115842, 8.9945309]. X follows the local northbound railway direction, Y is the left normal; elevations are reconstructed.
- Track gauge: **1.676 m** inside the rail heads. Heads have centres ±0.872 m and width0.068 m; rail top0.178 m.
- Rail heads, webs and feet are geometric unions of mapped routes; wheel-flange channels are0.045 m wide. Guard rails are clipped against all running-head/channel footprints. Point machines and bearer assemblies are visual reconstructions, not an engineered turnout schedule.
- Platform top1.018 m; nominal platform height above rail0.840 m, reconstructed. Typical side-body width6 m; mapped bodies retain their own widths with necessary rail-clearance insets.
- Declared coverage rectangle (Xmin,Ymin,Xmax,Ymax), metres: [-1050, -230, 1100, 230]. Running lines terminate at the declared model boundary. A cropped line is not given a fabricated buffer stop.
- 12 clipped OSM way-parts, total3596.5 m of centreline, are modelled. This is a geometry-part count, **not** the number of station tracks.
- Mapped junction nodes modelled: 0. Mapped true service-track dead ends fitted with buffers: 0.
- Station building reconstruction: centre/width/depth[-38, -6, 13, 6] m. Where a mapped envelope exists, its OSM ID is `not available`. Vertical detail and room planning are estimated.

## Platform positions versus physical bodies
India Rail Info reports **2 platform positions**; the model has **2 physical platform bodies**. No platform-position number is automatically treated as a separate island.

- Body `1`: reconstructed side body along mapped outer road; width6m, rail-centre offset1.92m; extent is approximate; sample minimum width 6.00 m, actual mesh-to-centreline minimum 1.920 m.
- Body `2`: reconstructed side body along mapped outer road; width6m, rail-centre offset1.92m; extent is approximate; sample minimum width 6.00 m, actual mesh-to-centreline minimum 1.920 m.

For Kollam, the mapped body labels1/1A,2/3,4/5 remain separate from a claim of six independent bodies. Elsewhere missing body geometry and face numbering are explicitly reconstructed. Narrow taper samples are reported, not silently presented as full-width boarding zones.

## Track and operating-status evidence
- Primary identity/chainage: [Southern Railway system map,1April2025](https://sr.indianrailways.gov.in/cris/uploads/files/1748431911655-System%20Map%202025%20Signed.pdf). Station chainage140.43 km under datum `ERS via KTYM then KYJ`. A schematic system map is not a yard survey.
- Reported platform positions: [MQO/Munroturuttu (2 PFs)](https://indiarailinfo.com/station/map/munroturuttu-mqo/2781), cross-checked2026-10-08. The profile does not certify a current complete track/loop/siding inventory.
- Raw mapped observations: Two side platform outlines along two main roads. No loops or separate sidings mapped.
- OSM snapshot: [2026-10-08](https://api.openstreetmap.org/api/0.6/map?bbox=76.6029084,8.9859978,76.6209084,9.0039978). Frozen raw source geometry is in`source/mapped_geometry.json`; adopted geometry, the complete graph-related route records, per-platform meshes and corrections are in`source/adopted_geometry.json`.
- Current official station-yard operating inventory remains unverified. Construction/proposed/disused tags are excluded from the operating-looking rail mesh; historic façade photographs do not prove present redevelopment completion.

## Photographic scope and reconstruction
Modest island halt; no invented concourse. Ticket shelter and staff booth interiors are reconstructed, not observed. August2026 Google contributor photo shows a covered footbridge and short grey shelters; these are represented with long uncovered concrete platform ends.

Hidden interiors, desks, ticket equipment, seating, partitions, toilets, exact shelter spans, bridge details and component elevations are reconstructed and explicitly labelled in scene collections. Small halts receive compact booking/waiting facilities rather than invented large concourses. The historical Kollam upper offices and maintenance pit fittings are reconstructions.

Google Images search in the cloud browser encountered an unusual-traffic check. Google Maps station-photo/Street View evidence is recorded below only when actually inspected; an ordinary contributor photo is not described as a panorama. Image capture dates and header/upload dates remain distinct. No source-image pixels or Google screenshots are included in these deliverables.

### Aug 2026 | Google Maps
Ordinary contributor photograph taken from covered footbridge

- Two through tracks between opposing side platforms viewed from footbridge
- Covered footbridge stairs descend along platform; pale grey steel posts/diagonal truss framing, narrow vertical mesh/bar parapet, corrugated pitched roof
- Near platform has separate silver-grey corrugated gable shelters on white central posts with dark-blue lower feet, further bright blue roof section
- Far platform has short separate dark/silver gable shelters; long platform ends are largely unsheltered
- Grey/tan paving with faded light/yellow edge lines; red/orange paved approach visible beyond near platform
- Very flat lush palm/green landscape beyond station

Source: https://www.google.com/maps/place/Munroturuttu/@8.9948423,76.6116844,3a,75y,90t/data=!3m8!1e2!3m6!1sCIABIhBfr3vQc1wcmJT7QRHWowAU!2e10!3e12!6shttps:%2F%2Flh3.googleusercontent.com%2Fgps-cs-s%2FAHRPTWmf_sPVAR5wD5bLIwToI_V52aG44o4OUDbauOB_EYiujVJsAyXBm_Zq41JKb03W4cmHp-Me8YUzq5ZoAZ5mRAmDc8FLHexN0LpK7Xl801MwGpWC5J6Fo1C0doDYvVjn4mUehA0cEQu53w6C%3Dw203-h270-k-no!7i3000!8i4000!4m7!3m6!1s0x3b06064ec586f409:0xb09236b5da561427!8m2!3d8.9946666!4d76.6115213!10e5!16s%2Fm%2F0129c5m9?entry=ttu&g_ep=EgoyMDI2MTAwNS4wIKXMDSoASAFQAw%3D%3D

Uncertainty: Main station room facade not visible; no invented large hall; Reference train omitted from model

## Local geometry corrections
No manually displaced centreline nodes in this station.

## QA and rebuilding
- `BUILD_QA.json`: units, mesh/object totals, platform distinctions, packed-image state and source geometry hash.
- `EXPORT_QA.json`: lossless ZIP hash, GLB header, import counts/bounds, unchanged authoritative Blend hash.
- The packed Blend is the authoritative editable source and opens without Python dependencies. Frozen adopted geometry and generated sign inputs are also provided. This first candidate predates automatic builder-script snapshotting; its precise code revision was not captured.
- Independent review status is tracked separately by the batch auditor. Do not treat an automatic generation check as a certified engineering clearance review.

## Attribution and rights
Geographic data ©[OpenStreetMap contributors](https://www.openstreetmap.org/copyright), available under[ODbL1.0](https://opendatacommons.org/licenses/odbl/1-0/). OSM-derived data is retained with provenance. Reference photographs remain with their credited photographers/providers and are **reference-only**, not included as textures or redistributed. Generated labels use Noto Sans Malayalam/Devanagari (SIL Open Font License) and DejaVu Sans; only rendered label pixels are included. Original procedural mesh/material work was produced for this project.


## Bridge revision02
The two stair flights now terminate at the leading deck edge, with continuous tread/deck height. Covered flights moved with them. See BRIDGE_REVISION.json and source/repair_bridge_used.py for exact component shifts and the immutable base hash. Views01–03 were rerendered from the repaired scene; unaffected facade/interior views04–05 retain their original source hash explicitly.
