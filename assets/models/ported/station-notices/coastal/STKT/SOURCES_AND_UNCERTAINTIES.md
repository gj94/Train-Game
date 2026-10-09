# SASTHANKOTTA (STKT) — full mapped station environment

A metre-scale, train-free scene with connected mapped running roads and service tracks, platform bodies, shelters, furnished station rooms and station-specific photographic architectural cues. This is a visual reconstruction, not a surveyed operational or signalling plan.

## Open the asset
- `STKT_coastal_station_v01.blend` is the authoritative editable scene. Generated sign images are packed; no source-photo textures are used.
- `export/STKT_coastal_station_v01.glb.zip` contains a losslessly zipped GLB. Extract before opening. The GLB has been re-imported in a fresh Blender scene; see `EXPORT_QA.json`.
- The GLB carries original mesh geometry and generated sign images. Procedural noise/paving shaders fall back to basic material colours; the full shader system remains in the Blend.
- `renders/` contains named source-scene views. `RENDER_PROVENANCE.json` records the exact source Blend SHA256 and camera pose for each render.

## Scope and dimensions
- Units: 1 Blender unit = 1 metre. Local equirectangular origin: longitude/latitude [76.6009828, 9.0314647]. X follows the local northbound railway direction, Y is the left normal; elevations are reconstructed.
- Track gauge: **1.676 m** inside the rail heads. Heads have centres ±0.872 m and width0.068 m; rail top0.178 m.
- Rail heads, webs and feet are geometric unions of mapped routes; wheel-flange channels are0.045 m wide. Guard rails are clipped against all running-head/channel footprints. Point machines and bearer assemblies are visual reconstructions, not an engineered turnout schedule.
- Platform top1.018 m; nominal platform height above rail0.840 m, reconstructed. Typical side-body width6 m; mapped bodies retain their own widths with necessary rail-clearance insets.
- Declared coverage rectangle (Xmin,Ymin,Xmax,Ymax), metres: [-1050, -230, 1100, 230]. Running lines terminate at the declared model boundary. A cropped line is not given a fabricated buffer stop.
- 6 clipped OSM way-parts, total5968.1 m of centreline, are modelled. This is a geometry-part count, **not** the number of station tracks.
- Mapped junction nodes modelled: 8. Mapped true service-track dead ends fitted with buffers: 0.
- Station building reconstruction: centre/width/depth[-10, -4, 38, 8] m. Where a mapped envelope exists, its OSM ID is `not available`. Vertical detail and room planning are estimated.

## Platform positions versus physical bodies
India Rail Info reports **2 platform positions**; the model has **2 physical platform bodies**. No platform-position number is automatically treated as a separate island.

- Body `1`: reconstructed side body along mapped outer road; width6m, rail-centre offset1.92m; extent is approximate; sample minimum width 6.00 m, actual mesh-to-centreline minimum 1.915 m.
- Body `2`: reconstructed side body along mapped outer road; width6m, rail-centre offset1.92m; extent is approximate; sample minimum width 6.00 m, actual mesh-to-centreline minimum 1.919 m.

For Kollam, the mapped body labels1/1A,2/3,4/5 remain separate from a claim of six independent bodies. Elsewhere missing body geometry and face numbering are explicitly reconstructed. Narrow taper samples are reported, not silently presented as full-width boarding zones.

## Track and operating-status evidence
- Primary identity/chainage: [Southern Railway system map,1April2025](https://sr.indianrailways.gov.in/cris/uploads/files/1748431911655-System%20Map%202025%20Signed.pdf). Station chainage135.91 km under datum `ERS via KTYM then KYJ`. A schematic system map is not a yard survey.
- Reported platform positions: [STKT/Sasthankotta (2 PFs)](https://d.indiarailinfo.com/station/map/sasthankotta-stkt/2763), cross-checked2026-10-08. The profile does not certify a current complete track/loop/siding inventory.
- Raw mapped observations: Two main roads and two connected outer loops visible. No platform geometry. Zero sidings means none separately mapped, not certified absence.
- OSM snapshot: [2026-10-08](https://api.openstreetmap.org/api/0.6/map?bbox=76.5898829,9.0233103,76.6078829,9.0413103). Frozen raw source geometry is in`source/mapped_geometry.json`; adopted geometry, the complete graph-related route records, per-platform meshes and corrections are in`source/adopted_geometry.json`.
- Current official station-yard operating inventory remains unverified. Construction/proposed/disused tags are excluded from the operating-looking rail mesh; historic façade photographs do not prove present redevelopment completion.

## Photographic scope and reconstruction
2025 photo-guided low flat-roof pale mint booking block, blue lower band, timber doors and awning windows. Furnished small office/ticket/waiting rooms are reconstructed. The2025 source describes one shared booking/reservation counter; the model therefore uses one counter, with public seating alongside.

Hidden interiors, desks, ticket equipment, seating, partitions, toilets, exact shelter spans, bridge details and component elevations are reconstructed and explicitly labelled in scene collections. Small halts receive compact booking/waiting facilities rather than invented large concourses. The historical Kollam upper offices and maintenance pit fittings are reconstructions.

Google Images search in the cloud browser encountered an unusual-traffic check. Google Maps station-photo/Street View evidence is recorded below only when actually inspected; an ordinary contributor photo is not described as a panorama. Image capture dates and header/upload dates remain distinct. No source-image pixels or Google screenshots are included in these deliverables.

### Article dated2025-09-03; exact capture date unresolved | Madhyamam
News photograph

- Long low pale-mint plaster block with medium-blue lower plinth and parapet band
- Flat/low roof behind platform canopy; brown wooden doors and casement windows
- Some wooden window shutters open outward as little awnings
- Platform shed on pale Y/braced columns; modest concrete platform

Source: https://www.madhyamam.com/kerala/local-news/kollam/sasthamkotta/inadequacy-of-sasthamkotta-railway-station-infrastructure-1443774

Uncertainty: Room layout and dimensions hidden; reconstructed; No Google Street View visit established by this observation

## Local geometry corrections
No manually displaced centreline nodes in this station.

## QA and rebuilding
- `BUILD_QA.json`: units, mesh/object totals, platform distinctions, packed-image state and source geometry hash.
- `EXPORT_QA.json`: lossless ZIP hash, GLB header, import counts/bounds, unchanged authoritative Blend hash.
- `source/build_station_used.py`: exact builder snapshot used for this scene. To rebuild from this snapshot, set`COASTAL_MIDDLE_ROOT` to the containing middle-batch directory and invoke Blender through the supplied shared lock wrapper, with`-- STKT`. The adopted geometry and generated sign texture are the inputs; the source Blend can always be opened directly without Python dependencies.
- Independent review status is tracked separately by the batch auditor. Do not treat an automatic generation check as a certified engineering clearance review.

## Attribution and rights
Geographic data ©[OpenStreetMap contributors](https://www.openstreetmap.org/copyright), available under[ODbL1.0](https://opendatacommons.org/licenses/odbl/1-0/). OSM-derived data is retained with provenance. Reference photographs remain with their credited photographers/providers and are **reference-only**, not included as textures or redistributed. Generated labels use Noto Sans Malayalam/Devanagari (SIL Open Font License) and DejaVu Sans; only rendered label pixels are included. Original procedural mesh/material work was produced for this project.
