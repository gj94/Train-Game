# PARAVUR (PVU) — full mapped station environment

A metre-scale, train-free scene with connected mapped running roads and service tracks, platform bodies, shelters, furnished station rooms and station-specific photographic architectural cues. This is a visual reconstruction, not a surveyed operational or signalling plan.

## Open the asset
- `PVU_coastal_station_v01.blend` is the authoritative editable scene. Generated sign images are packed; no source-photo textures are used.
- `export/PVU_coastal_station_v01.glb.zip` contains a losslessly zipped GLB. Extract before opening. The GLB has been re-imported in a fresh Blender scene; see `EXPORT_QA.json`.
- The GLB carries original mesh geometry and generated sign images. Procedural noise/paving shaders fall back to basic material colours; the full shader system remains in the Blend.
- `renders/` contains named source-scene views. `RENDER_PROVENANCE.json` records the exact source Blend SHA256 and camera pose for each render.

## Scope and dimensions
- Units: 1 Blender unit = 1 metre. Local equirectangular origin: longitude/latitude [76.6693434, 8.8151309]. X follows the local northbound railway direction, Y is the left normal; elevations are reconstructed.
- Track gauge: **1.676 m** inside the rail heads. Heads have centres ±0.872 m and width0.068 m; rail top0.178 m.
- Rail heads, webs and feet are geometric unions of mapped routes; wheel-flange channels are0.045 m wide. Guard rails are clipped against all running-head/channel footprints. Point machines and bearer assemblies are visual reconstructions, not an engineered turnout schedule.
- Platform top1.018 m; nominal platform height above rail0.840 m, reconstructed. Typical side-body width6 m; mapped bodies retain their own widths with necessary rail-clearance insets.
- Declared coverage rectangle (Xmin,Ymin,Xmax,Ymax), metres: [-1050, -230, 1100, 230]. Running lines terminate at the declared model boundary. A cropped line is not given a fabricated buffer stop.
- 12 clipped OSM way-parts, total7063.5 m of centreline, are modelled. This is a geometry-part count, **not** the number of station tracks.
- Mapped junction nodes modelled: 12. Mapped true service-track dead ends fitted with buffers: 2.
- Station building reconstruction: centre/width/depth[-0.3, 25.8, 42, 8.7] m. Where a mapped envelope exists, its OSM ID is `787852642`. Vertical detail and room planning are estimated.

## Platform positions versus physical bodies
India Rail Info reports **3 platform positions**; the model has **2 physical platform bodies**. No platform-position number is automatically treated as a separate island.

- Body `1`: reconstructed side body along mapped outer road; width6m, rail-centre offset1.92m; extent is approximate; sample minimum width 6.00 m, actual mesh-to-centreline minimum 1.920 m.
- Body `2;3`: reconstructed island body in widest mapped station-road gap; face assignment unverified; sample minimum width 7.28 m, actual mesh-to-centreline minimum 1.920 m.

These widths measure the raised platform-body mesh, not unobstructed pedestrian space. Building footprints, roofs and furniture are separate geometry; the independent circulation checks describe actual usable routes.

For Kollam, the mapped body labels1/1A,2/3,4/5 remain separate from a claim of six independent bodies. Elsewhere missing body geometry and face numbering are explicitly reconstructed. Narrow taper samples are reported, not silently presented as full-width boarding zones.

## Track and operating-status evidence
- Primary identity/chainage: [Southern Railway system map,1April2025](https://sr.indianrailways.gov.in/cris/uploads/files/1748431911655-System%20Map%202025%20Signed.pdf). Station chainage167.82 km under datum `ERS via KTYM then KYJ`. A schematic system map is not a yard survey.
- Reported platform positions: [PVU/Paravur (3 PFs)](https://indiarailinfo.com/station/map/paravur-pvu/1014), cross-checked2026-10-08. The profile does not certify a current complete track/loop/siding inventory.
- Raw mapped observations: Two main roads and two connected loops; an extra yard track and end stubs visible. Exact siding inventory unresolved; platform geometry absent.
- OSM snapshot: [2026-10-08](https://api.openstreetmap.org/api/0.6/map?bbox=76.6592380,8.8067580,76.6772380,8.8247580). Frozen raw source geometry is in`source/mapped_geometry.json`; adopted geometry, the complete graph-related route records, per-platform meshes and corrections are in`source/adopted_geometry.json`.
- Current official station-yard operating inventory remains unverified. Construction/proposed/disused tags are excluded from the operating-looking rail mesh; historic façade photographs do not prove present redevelopment completion.

## Photographic scope and reconstruction
Mapped42m station envelope, three reported positions in side plus island arrangement. Extra mapped yard road and true dead-end extensions included. May2023 facade photo guides white walls/blue lower band, grey sheet roof, dark-red fascia, blue window transoms and long sunshade.

Hidden interiors, desks, ticket equipment, seating, partitions, toilets, exact shelter spans, bridge details and component elevations are reconstructed and explicitly labelled in scene collections. Small halts receive compact booking/waiting facilities rather than invented large concourses. The historical Kollam upper offices and maintenance pit fittings are reconstructions.

Google Images search in the cloud browser encountered an unusual-traffic check. Google Maps station-photo/Street View evidence is recorded below only when actually inspected; an ordinary contributor photo is not described as a panorama. Image capture dates and header/upload dates remain distinct. No source-image pixels or Google screenshots are included in these deliverables.

### Not exposed | Google Maps
Google Maps satellite visually inspected

- Main station building and developed side-platform body lie SOUTH/southwest of rail corridor
- Second developed body is island to NORTH/northeast of station-side body, with separated long grey shelter roofs
- Covered footbridge crosses from southern building side to island near western end of central long shelter; stairs parallel to tracks
- Broad open northern rail-yard/loading area should not be mistaken for passenger platform building
- Narrow lane and planted compounds outside southern station front

Source: https://www.google.com/maps/search/Paravur+railway+station/@8.8150153,76.6693343,224m/data=!3m1!1e3?entry=ttu&g_ep=EgoyMDI2MTAwNS4wIKXMDSoASAFQAw%3D%3D

Uncertainty: Exact road number assignment unresolved; directions given geographic, not local model axes; Undated satellite does not certify current operation
### May 2023 | Google Maps
Ordinary contributor photograph of public station facade

- Long single-storey off-white station building with strong medium-blue lower wall/plinth band
- Shallow pitched grey corrugated roof, dark-red/brown fascia, long narrow blue-edged concrete sunshade
- Paired/triple reddish-brown wooden rectangular windows with blue louvered transoms above
- Yellow station name panels on upper wall; wide open entry with black accordion gate
- Forecourt orange/grey checker/grid tiles, chain-linked low posts and pots; bench visible through open entry

Source: https://www.google.com/maps/place/Paravur/@8.8151447,76.6693524,3a,75y,90t/data=!3m8!1e2!3m6!1sCIHM0ogKEICAgICxzorGzAE!2e10!3e12!6shttps:%2F%2Flh3.googleusercontent.com%2Fgps-cs-s%2FAHRPTWnyQ65cjGfaSXlPuJ-TTqdmxzIjcMZ_M7VhFQGBS2bhCKgm0C6-7HTREhQZCNQQ5lxftOmnLRnHzklZFG4yRvyvKHY9cD8UwgSnEOf43EbWloh1Q4WzAoPIaYvJbC8CMPfvBHZRqA%3Dw203-h152-k-no!7i4096!8i3072!4m11!1m2!2m1!1sParavur+railway+station!3m7!1s0x3b05e51e47216cf3:0xd4dfb9078fa4d529!8m2!3d8.8151447!4d76.6693524!10e5!15sChdQYXJhdnVyIHJhaWx3YXkgc3RhdGlvbloZIhdwYXJhdnVyIHJhaWx3YXkgc3RhdGlvbpIBDXRyYWluX3N0YXRpb26aAURDaTlEUVVsUlFVTnZaRU5vZEhsalJqbHZUMnhvUzAxcVVuTlpWemxOVlROV01GZEhVbGxrVlhCc1VUQXdOVnBXUlJBQuABAPoBBAgAEDw!16s%2Fm%2F0102jx0q?entry=ttu&g_ep=EgoyMDI2MTAwNS4wIKXMDSoASAFQAw%3D%3D

Uncertainty: Back-of-house room plan not visible

## Local geometry corrections
No manually displaced centreline nodes in this station.

## QA and rebuilding
- `BUILD_QA.json`: units, mesh/object totals, platform distinctions, packed-image state and source geometry hash.
- `EXPORT_QA.json`: lossless ZIP hash, GLB header, import counts/bounds, unchanged authoritative Blend hash.
- `source/build_station_used.py`: exact builder snapshot used for this scene. To rebuild from this snapshot, set`COASTAL_MIDDLE_ROOT` to the containing middle-batch directory and invoke Blender through the supplied shared lock wrapper, with`-- PVU`. The adopted geometry and generated sign texture are the inputs; the source Blend can always be opened directly without Python dependencies.
- Independent review status is tracked separately by the batch auditor. Do not treat an automatic generation check as a certified engineering clearance review.

## Attribution and rights
Geographic data ©[OpenStreetMap contributors](https://www.openstreetmap.org/copyright), available under[ODbL1.0](https://opendatacommons.org/licenses/odbl/1-0/). OSM-derived data is retained with provenance. Reference photographs remain with their credited photographers/providers and are **reference-only**, not included as textures or redistributed. Generated labels use Noto Sans Malayalam/Devanagari (SIL Open Font License) and DejaVu Sans; only rendered label pixels are included. Original procedural mesh/material work was produced for this project.


## Final photographed facade revision02
PVU revision02 explicitly models the observed May2023 front window/transom, continuous blue-edged shade, yellow name panel and dark-red roof fascia. Building envelope, doors, rooms, tracks and platforms stay unchanged. Exact component and camera changes are recorded in ARCHITECTURE_REVISION.json. Revised views are source-bound; any retained view keeps its original source hash and unchanged-subject reason.


## Photographed wooden window leaves revision03
The lower street-facing window infill now consists of divided/louvred reddish-brown wooden leaves, with blue limited to the upper transoms as in the May2023 photograph. Existing walls/openings, central entry, ramp, room layouts and the rest of the station are unchanged. Exact leaf/slat dimensions remain reconstructed. All four final views are refreshed.
