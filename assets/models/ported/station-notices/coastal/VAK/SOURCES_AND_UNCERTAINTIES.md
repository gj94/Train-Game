# VARKALA SIVAGIRI (VAK) — full mapped station environment

A metre-scale, train-free scene with connected mapped running roads and service tracks, platform bodies, shelters, furnished station rooms and station-specific photographic architectural cues. This is a visual reconstruction, not a surveyed operational or signalling plan.

## Open the asset
- `VAK_coastal_station_v01.blend` is the authoritative editable scene. Generated sign images are packed; no source-photo textures are used.
- `export/VAK_coastal_station_v01.glb.zip` contains a losslessly zipped GLB. Extract before opening. The GLB has been re-imported in a fresh Blender scene; see `EXPORT_QA.json`.
- The GLB carries original mesh geometry and generated sign images. Procedural noise/paving shaders fall back to basic material colours; the full shader system remains in the Blend.
- `renders/` contains named source-scene views. `RENDER_PROVENANCE.json` records the exact source Blend SHA256 and camera pose for each render.

## Scope and dimensions
- Units: 1 Blender unit = 1 metre. Local equirectangular origin: longitude/latitude [76.723134, 8.7406369]. X follows the local northbound railway direction, Y is the left normal; elevations are reconstructed.
- Track gauge: **1.676 m** inside the rail heads. Heads have centres ±0.872 m and width0.068 m; rail top0.178 m.
- Rail heads, webs and feet are geometric unions of mapped routes; wheel-flange channels are0.045 m wide. Guard rails are clipped against all running-head/channel footprints. Point machines and bearer assemblies are visual reconstructions, not an engineered turnout schedule.
- Platform top1.018 m; nominal platform height above rail0.840 m, reconstructed. Typical side-body width6 m; mapped bodies retain their own widths with necessary rail-clearance insets.
- Declared coverage rectangle (Xmin,Ymin,Xmax,Ymax), metres: [-1250, -180, 650, 180]. Running lines terminate at the declared model boundary. A cropped line is not given a fabricated buffer stop.
- 18 clipped OSM way-parts, total6494.8 m of centreline, are modelled. This is a geometry-part count, **not** the number of station tracks.
- Mapped junction nodes modelled: 11. Mapped true service-track dead ends fitted with buffers: 5.
- Station building reconstruction: centre/width/depth[34.1, -2.3, 57.3, 8.3] m. Where a mapped envelope exists, its OSM ID is `427595517`. Vertical detail and room planning are estimated.

## Platform positions versus physical bodies
India Rail Info reports **3 platform positions**; the model has **2 physical platform bodies**. No platform-position number is automatically treated as a separate island.

- Body `1`: reconstructed side body along mapped outer road; width6m, rail-centre offset1.92m; extent is approximate; sample minimum width 6.00 m, actual mesh-to-centreline minimum 1.898 m.
- Body `2;3`: reconstructed island body in widest mapped station-road gap; face assignment unverified; sample minimum width 10.00 m, actual mesh-to-centreline minimum 1.920 m.

For Kollam, the mapped body labels1/1A,2/3,4/5 remain separate from a claim of six independent bodies. Elsewhere missing body geometry and face numbering are explicitly reconstructed. Narrow taper samples are reported, not silently presented as full-width boarding zones.

## Track and operating-status evidence
- Primary identity/chainage: [Southern Railway system map,1April2025](https://sr.indianrailways.gov.in/cris/uploads/files/1748431911655-System%20Map%202025%20Signed.pdf). Station chainage178.98 km under datum `ERS via KTYM then KYJ`. A schematic system map is not a yard survey.
- Reported platform positions: [VAK/Varkala Sivagiri (3 PFs)](https://indiarailinfo.com/station/map/varkala-sivagiri-vak/569), cross-checked2026-10-08. The profile does not certify a current complete track/loop/siding inventory.
- Raw mapped observations: Two main roads and two outer loops with several end stubs. Two platform polygons refs 1 and2; eastern polygon intersects mapped track, so face inventory not inferred from imperfect alignment. Siding total unresolved.
- OSM snapshot: [2026-10-08](https://api.openstreetmap.org/api/0.6/map?bbox=76.7138720,8.7317320,76.7318720,8.7497320). Frozen raw source geometry is in`source/mapped_geometry.json`; adopted geometry, the complete graph-related route records, per-platform meshes and corrections are in`source/adopted_geometry.json`.
- Current official station-yard operating inventory remains unverified. Construction/proposed/disused tags are excluded from the operating-looking rail mesh; historic façade photographs do not prove present redevelopment completion.

## Photographic scope and reconstruction
Mapped station building footprint plus dated facade photos. Inconsistent2026 platform polygons replaced by clearance-corrected reconstructed side-plus-island arrangement; raw polygons retained for comparison. Incomplete shelter coverage retained.

Hidden interiors, desks, ticket equipment, seating, partitions, toilets, exact shelter spans, bridge details and component elevations are reconstructed and explicitly labelled in scene collections. Small halts receive compact booking/waiting facilities rather than invented large concourses. The historical Kollam upper offices and maintenance pit fittings are reconstructions.

Google Images search in the cloud browser encountered an unusual-traffic check. Google Maps station-photo/Street View evidence is recorded below only when actually inspected; an ordinary contributor photo is not described as a panorama. Image capture dates and header/upload dates remain distinct. No source-image pixels or Google screenshots are included in these deliverables.

### Not exposed | Google Maps
Google Maps satellite visually inspected

- West station-building side platform parallel to main road; broad pale station roof on west side of passenger tracks
- East island platform body with long southern grey-blue canopy and northern shorter shelter block
- Four passenger-road alignments with broad eastmost gap occupied by island; matches side outside westmost road and island between east loop/east main
- Large paved/roofed station block west of tracks; secondary narrow road beyond eastmost alignment

Source: https://www.google.com/maps/place/Varkala+Sivagiri/@8.7403852,76.7233547,224m/data=!3m1!1e3!4m10!1m2!2m1!1sVarkala+Sivagiri+railway+station!3m6!1s0x3b05ef2f75edb7e3:0x10e88f4aecb715d0!8m2!3d8.7401948!4d76.7235034!15sCiBWYXJrYWxhIFNpdmFnaXJpIHJhaWx3YXkgc3RhdGlvbloiIiB2YXJrYWxhIHNpdmFnaXJpIHJhaWx3YXkgc3RhdGlvbpIBDXRyYWluX3N0YXRpb26aASNDaFpEU1VoTk1HOW5TMFZKUTBGblNVUlJlVXB4WWtWQkVBReABAPoBBQjcARAz!16s%2Fm%2F0b746rt?entry=ttu&g_ep=EgoyMDI2MTAwNS4wIKXMDSoASAFQAw%3D%3D

Uncertainty: No survey-grade polygon extraction; builder should inspect exact screenshot; Date unavailable; redevelopment stage uncertain
### Oct 2019 | Google Maps
Ordinary contributor photograph of platform facade

- Long cream/yellow single-storey station building with red-orange tiled/corrugated sloping veranda roof and dark red/brown door surrounds
- Distinctive raised central square pavilion/cupola above roof: yellow-cream walls, stepped overhanging ochre roof with upward curved corners and small finial
- Platform veranda supported by slender metal posts and branching/arched decorative brackets
- Front canopy edge has a bright blue strip in central section; pale red long platform fascia with white coping edge
- Three passenger rail roads visible between camera-side island and main-building platform

Source: https://www.google.com/maps/place/Varkala+Sivagiri/@8.7403325,76.7233467,3a,75y,90t/data=!3m8!1e2!3m6!1sCIHM0ogKEICAgIC0ncbiVg!2e10!3e12!6shttps:%2F%2Flh3.googleusercontent.com%2Fgrass-cs%2FACvplmN2FB83kvHbBF-WmBvqI57hXJPSgNveSlJRaUYOCTDahuTVjj4rjeY_WTs0Wau_IHXPc__AgFTDlP22ydDvTDKkApjCmyYYzxc9Wz9My-3iyDb3GQsF8Vgp9aasKkdAJ8Xuy0l5%3Dw114-h86-k-no!7i4160!8i3120!4m11!1m2!2m1!1sVarkala+Sivagiri+railway+station!3m7!1s0x3b05ef2f75edb7e3:0x10e88f4aecb715d0!8m2!3d8.7401948!4d76.7235034!10e5!15sCiBWYXJrYWxhIFNpdmFnaXJpIHJhaWx3YXkgc3RhdGlvbloiIiB2YXJrYWxhIHNpdmFnaXJpIHJhaWx3YXkgc3RhdGlvbpIBDXRyYWluX3N0YXRpb26aASNDaFpEU1VoTk1HOW5TMFZKUTBGblNVUlJlVXB4WWtWQkVBReABAPoBBQjcARAz!16s%2Fm%2F0b746rt?entry=ttu&g_ep=EgoyMDI2MTAwNS4wIKXMDSoASAFQAw%3D%3D

Uncertainty: Historical image prior to redevelopment; public interiors only partly visible through doors
### Mar 2022 | Google Maps
Ordinary contributor photograph of road facade

- Cream-yellow single-storey facade with long red corrugated hipped roof and very dark broad eave fascia
- Brown/maroon grilled rectangular windows beneath continuous yellow horizontal sunshade
- Trilingual station letters on cream sign panel: red Malayalam, blue Hindi, green English
- Ramped side access and metal rails, low weathered compound walls and open forecourt from main road
- Distinctive higher corner/central pavilion glimpsed left behind tree; footbridge stairs visible at far right

Source: https://www.google.com/maps/place/Varkala+Sivagiri/@8.7401948,76.7235034,3a,75y,90t/data=!3m8!1e2!3m6!1sCIHM0ogKEICAgICWq9f0jgE!2e10!3e12!6shttps:%2F%2Flh3.googleusercontent.com%2Fgps-cs-s%2FAHRPTWn1EF1UbjN1YskT2TgyfG3T-7QZ2P7POwX6yEMDxVqEBWlMfTfcOoFyEnOm9I7dD5dboHoZHDX_sFhDpUjJJPatrNPDsNhBvGkdxxipNzaIEvLilMIFc6A4c5I2opDWyhyrsARSdg%3Dw203-h152-k-no!7i4608!8i3456!4m11!1m2!2m1!1sVarkala+Sivagiri+railway+station!3m7!1s0x3b05ef2f75edb7e3:0x10e88f4aecb715d0!8m2!3d8.7401948!4d76.7235034!10e5!15sCiBWYXJrYWxhIFNpdmFnaXJpIHJhaWx3YXkgc3RhdGlvbloiIiB2YXJrYWxhIHNpdmFnaXJpIHJhaWx3YXkgc3RhdGlvbpIBDXRyYWluX3N0YXRpb26aASNDaFpEU1VoTk1HOW5TMFZKUTBGblNVUlJlVXB4WWtWQkVBReABAPoBBQjcARAz!16s%2Fm%2F0b746rt?entry=ttu&g_ep=EgoyMDI2MTAwNS4wIKXMDSoASAFQAw%3D%3D

Uncertainty: View may represent one frontage wing rather than whole station; Public room interiors not resolved

## Local geometry corrections
No manually displaced centreline nodes in this station.

## QA and rebuilding
- `BUILD_QA.json`: units, mesh/object totals, platform distinctions, packed-image state and source geometry hash.
- `EXPORT_QA.json`: lossless ZIP hash, GLB header, import counts/bounds, unchanged authoritative Blend hash.
- `source/build_station_used.py`: exact builder snapshot used for this scene. To rebuild from this snapshot, set`COASTAL_MIDDLE_ROOT` to the containing middle-batch directory and invoke Blender through the supplied shared lock wrapper, with`-- VAK`. The adopted geometry and generated sign texture are the inputs; the source Blend can always be opened directly without Python dependencies.
- Independent review status is tracked separately by the batch auditor. Do not treat an automatic generation check as a certified engineering clearance review.

## Attribution and rights
Geographic data ©[OpenStreetMap contributors](https://www.openstreetmap.org/copyright), available under[ODbL1.0](https://opendatacommons.org/licenses/odbl/1-0/). OSM-derived data is retained with provenance. Reference photographs remain with their credited photographers/providers and are **reference-only**, not included as textures or redistributed. Generated labels use Noto Sans Malayalam/Devanagari (SIL Open Font License) and DejaVu Sans; only rendered label pixels are included. Original procedural mesh/material work was produced for this project.


## Architecture revision02
The central pavilion now follows the actual October2019 photograph: a raised square cream chamber on a stepped cornice, broad yellow-ochre hip cap with upturned corners, and axial finial. Exact chamber dimensions and its hidden rear faces are reconstructed. Camera03 was moved clear of footbridge obstructions. All original track/platform/room geometry remains unchanged. Views01–04 were rerendered; unaffected interior05 retains its original source hash explicitly. See ARCHITECTURE_REVISION.json and the exact repair script.


## Station-edge clearance revision03
The inferred six-metre side-platform body includes259.68m² beneath the axis-aligned mapped station building and is treated as continuous raised foundation there. It does not imply six metres of clear passenger space. Between the rear building wall and track-side platform edge, the reconstructed clear strip is 1.06–1.74m between the masonry envelope and platform edge. Standing veranda piers were replaced by high reconstructed wall brackets to leave that ground passage clear, and rear doors swing inward rather than across it. Outdoor canopy bays, benches, water/notice/sign fixtures accidentally placed inside the building envelope have been removed. Actual platform widths and building alignment remain survey uncertainties; accessibility compliance is not claimed. The revised source preserves the original mapped tracks, building and bridge. See ARCHITECTURE_REVISION.json for exact removed components and the proposed y−7.05m walking line for independent checking.
