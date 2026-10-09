# IRAVIPURAM (IRP) — full mapped station environment

A metre-scale, train-free scene with connected mapped running roads and service tracks, platform bodies, shelters, furnished station rooms and station-specific photographic architectural cues. This is a visual reconstruction, not a surveyed operational or signalling plan.

## Open the asset
- `IRP_coastal_station_v01.blend` is the authoritative editable scene. Generated sign images are packed; no source-photo textures are used.
- `export/IRP_coastal_station_v01.glb.zip` contains a losslessly zipped GLB. Extract before opening. The GLB has been re-imported in a fresh Blender scene; see `EXPORT_QA.json`.
- The GLB carries original mesh geometry and generated sign images. Procedural noise/paving shaders fall back to basic material colours; the full shader system remains in the Blend.
- `renders/` contains named source-scene views. `RENDER_PROVENANCE.json` records the exact source Blend SHA256 and camera pose for each render.

## Scope and dimensions
- Units: 1 Blender unit = 1 metre. Local equirectangular origin: longitude/latitude [76.6247345, 8.8667939]. X follows the local northbound railway direction, Y is the left normal; elevations are reconstructed.
- Track gauge: **1.676 m** inside the rail heads. Heads have centres ±0.872 m and width0.068 m; rail top0.178 m.
- Rail heads, webs and feet are geometric unions of mapped routes; wheel-flange channels are0.045 m wide. Guard rails are clipped against all running-head/channel footprints. Point machines and bearer assemblies are visual reconstructions, not an engineered turnout schedule.
- Platform top1.018 m; nominal platform height above rail0.840 m, reconstructed. Typical side-body width6 m; mapped bodies retain their own widths with necessary rail-clearance insets.
- Declared coverage rectangle (Xmin,Ymin,Xmax,Ymax), metres: [-1050, -230, 1100, 230]. Running lines terminate at the declared model boundary. A cropped line is not given a fabricated buffer stop.
- 2 clipped OSM way-parts, total4302.1 m of centreline, are modelled. This is a geometry-part count, **not** the number of station tracks.
- Mapped junction nodes modelled: 0. Mapped true service-track dead ends fitted with buffers: 0.
- Station building reconstruction: centre/width/depth[-46, -5.5, 14, 6] m. Where a mapped envelope exists, its OSM ID is `not available`. Vertical detail and room planning are estimated.

## Platform positions versus physical bodies
India Rail Info reports **2 platform positions**; the model has **2 physical platform bodies**. No platform-position number is automatically treated as a separate island.

- Body `1`: mapped polygon, locally inset for 1.90m rail-centre clearance; sample minimum width 5.92 m, actual mesh-to-centreline minimum 1.900 m.
- Body `2`: mapped polygon, locally inset for 1.90m rail-centre clearance; sample minimum width 3.40 m, actual mesh-to-centreline minimum 1.900 m.

For Kollam, the mapped body labels1/1A,2/3,4/5 remain separate from a claim of six independent bodies. Elsewhere missing body geometry and face numbering are explicitly reconstructed. Narrow taper samples are reported, not silently presented as full-width boarding zones.

## Track and operating-status evidence
- Primary identity/chainage: [Southern Railway system map,1April2025](https://sr.indianrailways.gov.in/cris/uploads/files/1748431911655-System%20Map%202025%20Signed.pdf). Station chainage159.92 km under datum `ERS via KTYM then KYJ`. A schematic system map is not a yard survey.
- Reported platform positions: [IRP/Iravipuram (2 PFs)](https://indiarailinfo.com/station/map/3522), cross-checked2026-10-08. The profile does not certify a current complete track/loop/siding inventory.
- Raw mapped observations: Two side platforms, two main roads, no loops or separate sidings mapped.
- OSM snapshot: [2026-10-08](https://api.openstreetmap.org/api/0.6/map?bbox=76.6140590,8.8579480,76.6320590,8.8759480). Frozen raw source geometry is in`source/mapped_geometry.json`; adopted geometry, the complete graph-related route records, per-platform meshes and corrections are in`source/adopted_geometry.json`.
- Current official station-yard operating inventory remains unverified. Construction/proposed/disused tags are excluded from the operating-looking rail mesh; historic façade photographs do not prove present redevelopment completion.

## Photographic scope and reconstruction
Two mapped side platform bodies with unequal lengths retained. Compact ticket-office/waiting shelter, no large concourse. May2016 photograph guides a compact white/pale-blue flat-parapet building and tall repeated geometric grille windows; later repainting is not claimed.

Hidden interiors, desks, ticket equipment, seating, partitions, toilets, exact shelter spans, bridge details and component elevations are reconstructed and explicitly labelled in scene collections. Small halts receive compact booking/waiting facilities rather than invented large concourses. The historical Kollam upper offices and maintenance pit fittings are reconstructions.

Google Images search in the cloud browser encountered an unusual-traffic check. Google Maps station-photo/Street View evidence is recorded below only when actually inspected; an ordinary contributor photo is not described as a panorama. Image capture dates and header/upload dates remain distinct. No source-image pixels or Google screenshots are included in these deliverables.

### May 2016 | Google Maps
Ordinary contributor photograph across tracks with station facade visible

- Small long white/pale-blue single-storey station building with flat weathered parapet roof
- Thin projecting slab eave; tiny dark vent/letter panels in parapet band
- Tall narrow repeated geometric lattice/breeze-block windows beside a dark open door
- Red rectangular wall notices; very shallow raised concrete plinth
- Grey concrete picket boundary fence, old yellow IRAVIPURAM board, tree-shaded rough-earth approach on camera side

Source: https://www.google.com/maps/place/Iravipuram/@8.8673353,76.6236583,3a,75y,90t/data=!3m8!1e2!3m6!1sCIHM0ogKEICAgIDci-P2qQE!2e10!3e12!6shttps:%2F%2Flh3.googleusercontent.com%2Fgps-cs-s%2FAHRPTWl92pOyFnCewJxewY8eBsYdEIJ42jaW0J36LoWvCBg5oGiRwRdmR3rwAoVV0GjMKrB5DqUyqcek6H0b7lhntQRchyUf0e4s3jWXlICuAI5XQbycFX2i_4pBXp9whrJiLvZ7wDHBKw%3Dw203-h152-k-no!7i4032!8i3024!4m7!3m6!1s0x3b05fca3661c3cfb:0x96d779d723a90f53!8m2!3d8.8669131!4d76.6245295!10e5!16s%2Fm%2F011v63wj?entry=ttu&g_ep=EgoyMDI2MTAwNS4wIKXMDSoASAFQAw%3D%3D

Uncertainty: Historical paint/date; foreground fruit kiosk is not station building; Building across tracks identified through visible station context; internal room plan unresolved

## Local geometry corrections
No manually displaced centreline nodes in this station.

## QA and rebuilding
- `BUILD_QA.json`: units, mesh/object totals, platform distinctions, packed-image state and source geometry hash.
- `EXPORT_QA.json`: lossless ZIP hash, GLB header, import counts/bounds, unchanged authoritative Blend hash.
- `source/build_station_used.py`: exact builder snapshot used for this scene. To rebuild from this snapshot, set`COASTAL_MIDDLE_ROOT` to the containing middle-batch directory and invoke Blender through the supplied shared lock wrapper, with`-- IRP`. The adopted geometry and generated sign texture are the inputs; the source Blend can always be opened directly without Python dependencies.
- Independent review status is tracked separately by the batch auditor. Do not treat an automatic generation check as a certified engineering clearance review.

## Attribution and rights
Geographic data ©[OpenStreetMap contributors](https://www.openstreetmap.org/copyright), available under[ODbL1.0](https://opendatacommons.org/licenses/odbl/1-0/). OSM-derived data is retained with provenance. Reference photographs remain with their credited photographers/providers and are **reference-only**, not included as textures or redistributed. Generated labels use Noto Sans Malayalam/Devanagari (SIL Open Font License) and DejaVu Sans; only rendered label pixels are included. Original procedural mesh/material work was produced for this project.
