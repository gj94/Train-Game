# MAYYANAD (MYY) — full mapped station environment

A metre-scale, train-free scene with connected mapped running roads and service tracks, platform bodies, shelters, furnished station rooms and station-specific photographic architectural cues. This is a visual reconstruction, not a surveyed operational or signalling plan.

## Open the asset
- `MYY_coastal_station_v01.blend` is the authoritative editable scene. Generated sign images are packed; no source-photo textures are used.
- `export/MYY_coastal_station_v01.glb.zip` contains a losslessly zipped GLB. Extract before opening. The GLB has been re-imported in a fresh Blender scene; see `EXPORT_QA.json`.
- The GLB carries original mesh geometry and generated sign images. Procedural noise/paving shaders fall back to basic material colours; the full shader system remains in the Blend.
- `renders/` contains named source-scene views. `RENDER_PROVENANCE.json` records the exact source Blend SHA256 and camera pose for each render.

## Scope and dimensions
- Units: 1 Blender unit = 1 metre. Local equirectangular origin: longitude/latitude [76.6476808, 8.8380291]. X follows the local northbound railway direction, Y is the left normal; elevations are reconstructed.
- Track gauge: **1.676 m** inside the rail heads. Heads have centres ±0.872 m and width0.068 m; rail top0.178 m.
- Rail heads, webs and feet are geometric unions of mapped routes; wheel-flange channels are0.045 m wide. Guard rails are clipped against all running-head/channel footprints. Point machines and bearer assemblies are visual reconstructions, not an engineered turnout schedule.
- Platform top1.018 m; nominal platform height above rail0.840 m, reconstructed. Typical side-body width6 m; mapped bodies retain their own widths with necessary rail-clearance insets.
- Declared coverage rectangle (Xmin,Ymin,Xmax,Ymax), metres: [-1050, -230, 1100, 230]. Running lines terminate at the declared model boundary. A cropped line is not given a fabricated buffer stop.
- 2 clipped OSM way-parts, total4300.1 m of centreline, are modelled. This is a geometry-part count, **not** the number of station tracks.
- Mapped junction nodes modelled: 0. Mapped true service-track dead ends fitted with buffers: 0.
- Station building reconstruction: centre/width/depth[-2.9, -0.8, 27.5, 10.1] m. Where a mapped envelope exists, its OSM ID is `890103189`. Vertical detail and room planning are estimated.

## Platform positions versus physical bodies
India Rail Info reports **2 platform positions**; the model has **2 physical platform bodies**. No platform-position number is automatically treated as a separate island.

- Body `2`: reconstructed side body along mapped outer road; width6m, rail-centre offset1.92m; extent is approximate; sample minimum width 6.00 m, actual mesh-to-centreline minimum 1.920 m.
- Body `1`: reconstructed side body along mapped outer road; width6m, rail-centre offset1.92m; extent is approximate; sample minimum width 6.00 m, actual mesh-to-centreline minimum 1.920 m.

For Kollam, the mapped body labels1/1A,2/3,4/5 remain separate from a claim of six independent bodies. Elsewhere missing body geometry and face numbering are explicitly reconstructed. Narrow taper samples are reported, not silently presented as full-width boarding zones.

## Track and operating-status evidence
- Primary identity/chainage: [Southern Railway system map,1April2025](https://sr.indianrailways.gov.in/cris/uploads/files/1748431911655-System%20Map%202025%20Signed.pdf). Station chainage164.25 km under datum `ERS via KTYM then KYJ`. A schematic system map is not a yard survey.
- Reported platform positions: [MYY/Mayyanad (2 PFs)](https://indiarailinfo.com/station/map/mayyanad-myy/2767), cross-checked2026-10-08. The profile does not certify a current complete track/loop/siding inventory.
- Raw mapped observations: Two main roads mapped; platform geometry absent. No loops or separate sidings mapped.
- OSM snapshot: [2026-10-08](https://api.openstreetmap.org/api/0.6/map?bbox=76.6383310,8.8287590,76.6563310,8.8467590). Frozen raw source geometry is in`source/mapped_geometry.json`; adopted geometry, the complete graph-related route records, per-platform meshes and corrections are in`source/adopted_geometry.json`.
- Current official station-yard operating inventory remains unverified. Construction/proposed/disused tags are excluded from the operating-looking rail mesh; historic façade photographs do not prove present redevelopment completion.

## Photographic scope and reconstruction
Mapped station building envelope anchors reconstruction; two side platforms reconstructed from double-line alignment. February2023 photo guides blue central bay, red decorative cross-gable with scalloped boards/trefoil motif, yellow name plaque, brown joinery and broad single-slope cream/grey shelters.

Hidden interiors, desks, ticket equipment, seating, partitions, toilets, exact shelter spans, bridge details and component elevations are reconstructed and explicitly labelled in scene collections. Small halts receive compact booking/waiting facilities rather than invented large concourses. The historical Kollam upper offices and maintenance pit fittings are reconstructions.

Google Images search in the cloud browser encountered an unusual-traffic check. Google Maps station-photo/Street View evidence is recorded below only when actually inspected; an ordinary contributor photo is not described as a panorama. Image capture dates and header/upload dates remain distinct. No source-image pixels or Google screenshots are included in these deliverables.

### Feb 2023 | Google Maps
Ordinary contributor photograph across two tracks

- Two opposing side platforms with simple broad single-slope cream/grey corrugated shelters
- Far shelter carried by row of slender pale steel posts with diagonal knee/branch bracing, about five visible bays
- Open sides, small roundel signs on columns, low pale rear wall and mature trees behind
- Grey slab-paved platform and grey weathered retaining fascia; no elaborate enclosed station hall in this view

Source: https://www.google.com/maps/place/Mayyanad/@8.8381818,76.6473583,3a,75y,90t/data=!3m8!1e2!3m6!1sCIHM0ogKEICAgIChu4SSAw!2e10!3e12!6shttps:%2F%2Flh3.googleusercontent.com%2Fgrass-cs%2FAABkmLeVuCj6pZ3TzVCLoS4kdP2n4aaxWGKntXUZkRNqc_qU0HUbOFuFigvJUSpKJjBVyC5VQXasiA6wDPwPg0Jhu5i2hnntpdq0_KrQ58Md3zpXYOqaVDB8dJrQWBaO-7m8ApdYVq3E%3Dw114-h86-k-no!7i4032!8i3024!4m7!3m6!1s0x3b05e4b604f528c9:0xb5fa7ba8b1a82385!8m2!3d8.8380543!4d76.6477315!10e5!16s%2Fm%2F011vl5d7?entry=ttu&g_ep=EgoyMDI2MTAwNS4wIKXMDSoASAFQAw%3D%3D

Uncertainty: Main station building outside crop; shelter roof should not be generalized to large pitched masonry roof
### Feb 2023 | Google Maps
Ordinary contributor photograph of main station facade

- Pale mint/off-white heritage-like tall single-storey building with broad BLUE central doorway bay/pilasters
- Red-brown tiled roof with projecting central triangular front gable; gable face vertical red boards with scalloped lower ends and small trefoil/clover vent
- Yellow MAYYANAD name panel in blue central upper wall, small rectangular vent/window immediately below
- Flat cantilevered concrete hood above entry; tall brown wooden windows with louver transoms and blue patterned iron grille on right
- Three shallow pale steps into open passage/waiting room; patterned rear grilles visible, dark dado and pale interior floor
- Blue lower wall/name panel and dark-blue plinth

Source: https://www.google.com/maps/place/Mayyanad/@8.8381818,76.6473583,3a,75y,90t/data=!3m8!1e2!3m6!1sCIHM0ogKEICAgIChudDjPA!2e10!3e12!6shttps:%2F%2Flh3.googleusercontent.com%2Fgps-cs-s%2FAHRPTWl-4SQ_xlKUxDXHRTYagkO-uQOR-WV-9wb3UJ0WqPdOs5-d07lTxlmVaTP8ZjNhlYVq7btbMg5E6ozWlrXmG1K0F_bt8owhmG8nqEksagKprWZidvAI3VC78WjTz90S9Jc3kC9I%3Dw203-h270-k-no!7i3024!8i4032!4m7!3m6!1s0x3b05e4b604f528c9:0xb5fa7ba8b1a82385!8m2!3d8.8380543!4d76.6477315!10e5!16s%2Fm%2F011vl5d7?entry=ttu&g_ep=EgoyMDI2MTAwNS4wIKXMDSoASAFQAw%3D%3D

Uncertainty: Exact interior plan not visible, but central through circulation verified

## Local geometry corrections
No manually displaced centreline nodes in this station.

## QA and rebuilding
- `BUILD_QA.json`: units, mesh/object totals, platform distinctions, packed-image state and source geometry hash.
- `EXPORT_QA.json`: lossless ZIP hash, GLB header, import counts/bounds, unchanged authoritative Blend hash.
- `source/build_station_used.py`: exact builder snapshot used for this scene. To rebuild from this snapshot, set`COASTAL_MIDDLE_ROOT` to the containing middle-batch directory and invoke Blender through the supplied shared lock wrapper, with`-- MYY`. The adopted geometry and generated sign texture are the inputs; the source Blend can always be opened directly without Python dependencies.
- Independent review status is tracked separately by the batch auditor. Do not treat an automatic generation check as a certified engineering clearance review.

## Attribution and rights
Geographic data ©[OpenStreetMap contributors](https://www.openstreetmap.org/copyright), available under[ODbL1.0](https://opendatacommons.org/licenses/odbl/1-0/). OSM-derived data is retained with provenance. Reference photographs remain with their credited photographers/providers and are **reference-only**, not included as textures or redistributed. Generated labels use Noto Sans Malayalam/Devanagari (SIL Open Font License) and DejaVu Sans; only rendered label pixels are included. Original procedural mesh/material work was produced for this project.


## Fixture revision02
Noticeboard assemblies and the waiting-room television were shifted onto solid masonry piers, clearing the glazed windows. Only the affected interior05 was refreshed; exterior01–04 explicitly retain their base-scene hashes. All rail, building, platform and circulation geometry is unchanged. See ARCHITECTURE_REVISION.json and the exact repair script.
