# PERINAD (PRND) — full mapped station environment

A metre-scale, train-free scene with connected mapped running roads and service tracks, platform bodies, shelters, furnished station rooms and station-specific photographic architectural cues. This is a visual reconstruction, not a surveyed operational or signalling plan.

## Open the asset
- `PRND_coastal_station_v01.blend` is the authoritative editable scene. Generated sign images are packed; no source-photo textures are used.
- `export/PRND_coastal_station_v01.glb.zip` contains a losslessly zipped GLB. Extract before opening. The GLB has been re-imported in a fresh Blender scene; see `EXPORT_QA.json`.
- The GLB carries original mesh geometry and generated sign images. Procedural noise/paving shaders fall back to basic material colours; the full shader system remains in the Blend.
- `renders/` contains named source-scene views. `RENDER_PROVENANCE.json` records the exact source Blend SHA256 and camera pose for each render.

## Scope and dimensions
- Units: 1 Blender unit = 1 metre. Local equirectangular origin: longitude/latitude [76.6206762, 8.9486074]. X follows the local northbound railway direction, Y is the left normal; elevations are reconstructed.
- Track gauge: **1.676 m** inside the rail heads. Heads have centres ±0.872 m and width0.068 m; rail top0.178 m.
- Rail heads, webs and feet are geometric unions of mapped routes; wheel-flange channels are0.045 m wide. Guard rails are clipped against all running-head/channel footprints. Point machines and bearer assemblies are visual reconstructions, not an engineered turnout schedule.
- Platform top1.018 m; nominal platform height above rail0.840 m, reconstructed. Typical side-body width6 m; mapped bodies retain their own widths with necessary rail-clearance insets.
- Declared coverage rectangle (Xmin,Ymin,Xmax,Ymax), metres: [-1050, -230, 1100, 230]. Running lines terminate at the declared model boundary. A cropped line is not given a fabricated buffer stop.
- 7 clipped OSM way-parts, total6360.7 m of centreline, are modelled. This is a geometry-part count, **not** the number of station tracks.
- Mapped junction nodes modelled: 6. Mapped true service-track dead ends fitted with buffers: 0.
- Station building reconstruction: centre/width/depth[-8, -3, 26, 8] m. Where a mapped envelope exists, its OSM ID is `not available`. Vertical detail and room planning are estimated.

## Platform positions versus physical bodies
India Rail Info reports **2 platform positions**; the model has **2 physical platform bodies**. No platform-position number is automatically treated as a separate island.

- Body `1`: reconstructed side body along mapped outer road; width6m, rail-centre offset1.92m; extent is approximate; sample minimum width 6.00 m, actual mesh-to-centreline minimum 1.920 m.
- Body `2`: reconstructed side body along mapped outer road; width6m, rail-centre offset1.92m; extent is approximate; sample minimum width 6.00 m, actual mesh-to-centreline minimum 1.920 m.

These widths measure the raised platform-body mesh, not unobstructed pedestrian space. Building footprints, roofs and furniture are separate geometry; the independent circulation checks describe actual usable routes.

For Kollam, the mapped body labels1/1A,2/3,4/5 remain separate from a claim of six independent bodies. Elsewhere missing body geometry and face numbering are explicitly reconstructed. Narrow taper samples are reported, not silently presented as full-width boarding zones.

## Track and operating-status evidence
- Primary identity/chainage: [Southern Railway system map,1April2025](https://sr.indianrailways.gov.in/cris/uploads/files/1748431911655-System%20Map%202025%20Signed.pdf). Station chainage146.31 km under datum `ERS via KTYM then KYJ`. A schematic system map is not a yard survey.
- Reported platform positions: [PRND/Perinad (2 PFs)](https://indiarailinfo.com/station/map/perinad-prnd/6537), cross-checked2026-10-08. The profile does not certify a current complete track/loop/siding inventory.
- Raw mapped observations: Four parallel connected roads at station. Two platform outlines mapped; opposite-side/island face usage cannot be established from tags and alignment alone. Crossover excluded from siding count.
- OSM snapshot: [2026-10-08](https://api.openstreetmap.org/api/0.6/map?bbox=76.6113410,8.9389160,76.6293410,8.9569160). Frozen raw source geometry is in`source/mapped_geometry.json`; adopted geometry, the complete graph-related route records, per-platform meshes and corrections are in`source/adopted_geometry.json`.
- Current official station-yard operating inventory remains unverified. Construction/proposed/disused tags are excluded from the operating-looking rail mesh; historic façade photographs do not prove present redevelopment completion.

## Photographic scope and reconstruction
Two mapped platform edge lines do not define full platform lengths/bodies. Reconstructed side bodies follow outer track alignments; topology remains the mapped four-road station. April2026 Google photograph guides the off-white/blue-plinth block, maroon timber doors, grey corrugated canopy, central waiting-hall entry and wooden slab benches; older red-tile assumption removed.

Hidden interiors, desks, ticket equipment, seating, partitions, toilets, exact shelter spans, bridge details and component elevations are reconstructed and explicitly labelled in scene collections. Small halts receive compact booking/waiting facilities rather than invented large concourses. The historical Kollam upper offices and maintenance pit fittings are reconstructions.

Google Images search in the cloud browser encountered an unusual-traffic check. Google Maps station-photo/Street View evidence is recorded below only when actually inspected; an ordinary contributor photo is not described as a panorama. Image capture dates and header/upload dates remain distinct. No source-image pixels or Google screenshots are included in these deliverables.

### Apr 2026 | Google Maps
Ordinary contributor photograph of platform-facing building

- Long low cream/off-white station block with medium-blue plinth and blue door/window surrounds
- Many maroon-red solid timber doors/shutters; tall dark glazed/grilled double doors to left and centre
- Central WAITING HALL opening has blue louvered transom and small trilingual label above; black noticeboard panels on wall
- Continuous shallow grey corrugated canopy on pale weathered steel Y/branched columns, exposed roof purlins; no decorative tiled pitch visible
- Long dark wooden backless bench slabs on pale-blue block legs; rough brown-grey platform, faded short yellow line marks
- Very weathered pale pink platform retaining wall

Source: https://www.google.com/maps/place/Perinad/@8.9490133,76.6206069,3a,75y,90t/data=!3m8!1e2!3m6!1sCIABIhA5qmk6ZyoV6ITnH7YqQ0Fk!2e10!3e12!6shttps:%2F%2Flh3.googleusercontent.com%2Fgrass-cs%2FAABkmLfn7sMs-mL_x5_ZbkKhIfoxqV4Z0PLiXEaskjLfZkvd_ZXLDgZc3dgsZEePB5NUAA1fzk8Iymdtvcqy-IDquy8ryvLZ9riLQ0f646_8JXYux_rSgey9eczFbh1MEjsBZyl_no76QQ1zVz0%3Dw114-h86-k-no!7i4080!8i3072!4m7!3m6!1s0x3b0607f4f5d53fb9:0x7c5d6b17a4035df9!8m2!3d8.948716!4d76.6205061!10e5!16s%2Fm%2F01296wxm?entry=ttu&g_ep=EgoyMDI2MTAwNS4wIKXMDSoASAFQAw%3D%3D

Uncertainty: Platform elevation fully visible; road-facing facade and exact room depth unresolved

## Local geometry corrections
No manually displaced centreline nodes in this station.

## QA and rebuilding
- `BUILD_QA.json`: units, mesh/object totals, platform distinctions, packed-image state and source geometry hash.
- `EXPORT_QA.json`: lossless ZIP hash, GLB header, import counts/bounds, unchanged authoritative Blend hash.
- `source/build_station_used.py`: exact builder snapshot used for this scene. To rebuild from this snapshot, set`COASTAL_MIDDLE_ROOT` to the containing middle-batch directory and invoke Blender through the supplied shared lock wrapper, with`-- PRND`. The adopted geometry and generated sign texture are the inputs; the source Blend can always be opened directly without Python dependencies.
- Independent review status is tracked separately by the batch auditor. Do not treat an automatic generation check as a certified engineering clearance review.

## Attribution and rights
Geographic data ©[OpenStreetMap contributors](https://www.openstreetmap.org/copyright), available under[ODbL1.0](https://opendatacommons.org/licenses/odbl/1-0/). OSM-derived data is retained with provenance. Reference photographs remain with their credited photographers/providers and are **reference-only**, not included as textures or redistributed. Generated labels use Noto Sans Malayalam/Devanagari (SIL Open Font License) and DejaVu Sans; only rendered label pixels are included. Original procedural mesh/material work was produced for this project.


## Fixture revision02
Noticeboard assemblies and the waiting-room television were shifted onto solid masonry piers, clearing the glazed windows. The already rendered overview01 retains its base-scene hash; platform03, facade04 and interior05 are generated from the corrected scene. All rail, building, platform and circulation geometry is unchanged. See ARCHITECTURE_REVISION.json and the exact repair script.
