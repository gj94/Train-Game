# KOLLAM JUNCTION (QLN) — full mapped station environment

A metre-scale, train-free scene with connected mapped running roads and service tracks, platform bodies, shelters, furnished station rooms and station-specific photographic architectural cues. This is a visual reconstruction, not a surveyed operational or signalling plan.

## Open the asset
- `QLN_coastal_station_v01.blend` is the authoritative editable scene. Generated sign images are packed; no source-photo textures are used.
- `export/QLN_coastal_station_v01.glb.zip` contains a losslessly zipped GLB. Extract before opening. The GLB has been re-imported in a fresh Blender scene; see `EXPORT_QA.json`.
- The GLB carries original mesh geometry and generated sign images. Procedural noise/paving shaders fall back to basic material colours; the full shader system remains in the Blend.
- `renders/` contains named source-scene views. `RENDER_PROVENANCE.json` records the exact source Blend SHA256 and camera pose for each render.

## Scope and dimensions
- Units: 1 Blender unit = 1 metre. Local equirectangular origin: longitude/latitude [76.5954829, 8.8862192]. X follows the local northbound railway direction, Y is the left normal; elevations are reconstructed.
- Track gauge: **1.676 m** inside the rail heads. Heads have centres ±0.872 m and width0.068 m; rail top0.178 m.
- Rail heads, webs and feet are geometric unions of mapped routes; wheel-flange channels are0.045 m wide. Guard rails are clipped against all running-head/channel footprints. Point machines and bearer assemblies are visual reconstructions, not an engineered turnout schedule.
- Platform top1.018 m; nominal platform height above rail0.840 m, reconstructed. Typical side-body width6 m; mapped bodies retain their own widths with necessary rail-clearance insets.
- Declared coverage rectangle (Xmin,Ymin,Xmax,Ymax), metres: [-600, -750, 1350, 190]. Running lines terminate at the declared model boundary. A cropped line is not given a fabricated buffer stop.
- 44 clipped OSM way-parts, total20457.9 m of centreline, are modelled. This is a geometry-part count, **not** the number of station tracks.
- Mapped junction nodes modelled: 43. Mapped true service-track dead ends fitted with buffers: 10.
- Station building reconstruction: centre/width/depth[-63, -26, 132, 16] m. Where a mapped envelope exists, its OSM ID is `269160473`. Vertical detail and room planning are estimated.

## Platform positions versus physical bodies
India Rail Info reports **6 platform positions**; the model has **3 physical platform bodies**. No platform-position number is automatically treated as a separate island.

- Body `4;5`: mapped polygon, locally inset for 1.90m rail-centre clearance; sample minimum width 9.52 m, actual mesh-to-centreline minimum 1.900 m.
- Body `2;3`: mapped polygon, locally inset for 1.90m rail-centre clearance; sample minimum width 9.35 m, actual mesh-to-centreline minimum 2.080 m.
- Body `1;1A`: mapped polygon, locally inset for 1.90m rail-centre clearance; sample minimum width 9.08 m, actual mesh-to-centreline minimum 1.900 m.

For Kollam, the mapped body labels1/1A,2/3,4/5 remain separate from a claim of six independent bodies. Elsewhere missing body geometry and face numbering are explicitly reconstructed. Narrow taper samples are reported, not silently presented as full-width boarding zones.

## Track and operating-status evidence
- Primary identity/chainage: [Southern Railway system map,1April2025](https://sr.indianrailways.gov.in/cris/uploads/files/1748431911655-System%20Map%202025%20Signed.pdf). Station chainage155.50 km under datum `ERS via KTYM then KYJ`. A schematic system map is not a yard survey.
- Reported platform positions: [QLN/Kollam Junction (Quilon) (6 PFs)](https://indiarailinfo.com/station/map/58?a=1), cross-checked2026-10-08. The profile does not certify a current complete track/loop/siding inventory.
- Raw mapped observations: Complex junction and service yard. Platform polygons refs 4;5, 2;3, 1;1A denote six numbered positions on three bodies. A mapped track named Platform Number 1B and shared long body make physical face total uncertain. Goods roads, MEMU-side yard and FCI spurs present; exact operational classification and inventory unresolved.
- OSM snapshot: [2026-10-08](https://api.openstreetmap.org/api/0.6/map?bbox=76.5847530,8.8745860,76.6087530,8.8985860). Frozen raw source geometry is in`source/mapped_geometry.json`; adopted geometry, the complete graph-related route records, per-platform meshes and corrections are in`source/adopted_geometry.json`.
- Current official station-yard operating inventory remains unverified. Construction/proposed/disused tags are excluded from the operating-looking rail mesh; historic façade photographs do not prove present redevelopment completion.

## Photographic scope and reconstruction
Three mapped bodies carry positions1/1A,2/3,4/5. Historical2017–2020 terminal facade reconstructed; present redevelopment completion is not claimed. Yard, depot/FCI spurs, secondary terminal and service buildings retained within declared coverage.

Hidden interiors, desks, ticket equipment, seating, partitions, toilets, exact shelter spans, bridge details and component elevations are reconstructed and explicitly labelled in scene collections. Small halts receive compact booking/waiting facilities rather than invented large concourses. The historical Kollam upper offices and maintenance pit fittings are reconstructions.

Google Images search in the cloud browser encountered an unusual-traffic check. Google Maps station-photo/Street View evidence is recorded below only when actually inspected; an ordinary contributor photo is not described as a panorama. Image capture dates and header/upload dates remain distinct. No source-image pixels or Google screenshots are included in these deliverables.

### Nov 2019 | Google Maps
Ordinary contributor photograph; Street View-labelled button opened photo, not panorama

- Large yellow rectangular trilingual station nameboard between white concrete posts with black lower legs
- Red/pink small paving tiles near platform edge; dark red platform fascia and white-painted edge
- Backless orange/coral slab benches on two light-blue concrete pedestals
- Metal platform shelter roofs appear pale grey with blue edge and open triangular roof framing

Source: https://www.google.com/maps/place/Kollam+Junction/@8.8854235,76.5950284,3a,75y,90t/data=!3m8!1e2!3m6!1sCIHM0ogKEICAgIDc-eOTEA!2e10!3e12!6shttps:%2F%2Flh3.googleusercontent.com%2Fgps-cs-s%2FAHRPTWnjoMPFnFTvfNwppCwFu3I0sWNmhzsKXM5V-c6doDt0ewfTBa8lYwYNklsmWmFR_s3bJQWLtrCkKzAEuHuOj_Lzr6onQY4O3qlKT-sxltH80CgPS2m8vTFLxPRlycWT-5w7BPLh%3Dw203-h152-k-no!7i4000!8i3000!4m11!1m2!2m1!1sKollam+Junction+railway+station!3m7!1s0x3b05fcf63d6fc94b:0xff033ef2cf9c187c!8m2!3d8.8863898!4d76.5959578!10e5!15sCh9Lb2xsYW0gSnVuY3Rpb24gcmFpbHdheSBzdGF0aW9ukgENdHJhaW5fc3RhdGlvbuABAA!16s%2Fm%2F0z6t6d0?entry=ttu&g_ep=EgoyMDI2MTAwNS4wIKXMDSoASAFQAw%3D%3D

Uncertainty: Image old; recent redevelopment may change buildings; Do not model visible train; no current inventory inference
### Sep 2019 | Google Maps
Ordinary contributor photograph

- Island platform canopy has prominent butterfly/V roof with central low gutter and higher outer eaves; exposed pale steel plate/truss framing
- Central square steel columns; fluorescent strip lights beneath exposed corrugated roofing
- Orange bench tops on blue square concrete piers; red tiled tactile/edge strip along both sides of platform
- Opposite platform blue pitched canopy

Source: https://www.google.com/maps/place/Kollam+Junction/@8.8859901,76.5951169,3a,75y,90t/data=!3m8!1e2!3m6!1sCIHM0ogKEICAgIC0gu2EcQ!2e10!3e12!6shttps:%2F%2Flh3.googleusercontent.com%2Fgps-cs-s%2FAHRPTWnj6I9d8mMuI41GbYGy5RFAEM34QHP7NfNxiGxoC6rNd4Sy9bTSzSqL_Gj-rM7bkxjiw5mVUGIwNq3RGzFMtDbNB0klvsvUy-VdaikElHqLVMUyLab-Izwhlj8jpS1HdcAfDX5_%3Dw203-h152-k-no!7i4000!8i3000!4m11!1m2!2m1!1sKollam+Junction+railway+station!3m7!1s0x3b05fcf63d6fc94b:0xff033ef2cf9c187c!8m2!3d8.8863898!4d76.5959578!10e5!15sCh9Lb2xsYW0gSnVuY3Rpb24gcmFpbHdheSBzdGF0aW9ukgENdHJhaW5fc3RhdGlvbuABAA!16s%2Fm%2F0z6t6d0?entry=ttu&g_ep=EgoyMDI2MTAwNS4wIKXMDSoASAFQAw%3D%3D

Uncertainty: Photo predates current redevelopment
### Image capture Sep 2020; photo header Apr 2022 | Google Maps
Ordinary contributor photograph

- Long two-storey pale mint/off-white facade; continuous terracotta-red flat horizontal bands and slender red mullions
- Central shallow red-tiled roof over upper facade signage; multicolored trilingual rooftop letters
- Broad rectangular red flat-roof portico with yellow columns; green vertical piers and green lower plinth elsewhere
- White central circular panel with blue railway emblem in this photo (not clearly a clock)
- Two red-white diagonal stepped/checkered wall panels flank central entrance; one panel triangular/gable-shaped within pale wall
- Steel handrail access ramps across foreground; exposed open ground-floor entrance

Source: https://www.google.com/maps/place/Kollam+Junction/@8.8863898,76.5959578,3a,75y,90t/data=!3m8!1e2!3m6!1sCIHM0ogKEICAgIDW38-uHA!2e10!3e12!6shttps:%2F%2Flh3.googleusercontent.com%2Fgps-cs-s%2FAHRPTWnWxZLqbPJ668JUDy5Vkp_6zhUQ3dYOsxONPYEubF_XvU0QL2WiNItsWb05YwpFbjnKtX9gY-naF0RFTEkHVwebDt5GjmeeKIebC0IIPJhbq1siS6C2CFTba2Z5vEMocqUSOc8%3Dw203-h152-k-no!7i4608!8i3456!4m11!1m2!2m1!1sKollam+Junction+railway+station!3m7!1s0x3b05fcf63d6fc94b:0xff033ef2cf9c187c!8m2!3d8.8863898!4d76.5959578!10e5!15sCh9Lb2xsYW0gSnVuY3Rpb24gcmFpbHdheSBzdGF0aW9ukgENdHJhaW5fc3RhdGlvbuABAA!16s%2Fm%2F0z6t6d0?entry=ttu&g_ep=EgoyMDI2MTAwNS4wIKXMDSoASAFQAw%3D%3D

Uncertainty: Historical pre-redevelopment facade; capture and header dates differ; Interior beyond dark entry is unresolved

## Local geometry corrections
No manually displaced centreline nodes in this station.

## QA and rebuilding
- `BUILD_QA.json`: units, mesh/object totals, platform distinctions, packed-image state and source geometry hash.
- `EXPORT_QA.json`: lossless ZIP hash, GLB header, import counts/bounds, unchanged authoritative Blend hash.
- `source/build_station_used.py`: exact builder snapshot used for this scene. To rebuild from this snapshot, set`COASTAL_MIDDLE_ROOT` to the containing middle-batch directory and invoke Blender through the supplied shared lock wrapper, with`-- QLN`. The adopted geometry and generated sign texture are the inputs; the source Blend can always be opened directly without Python dependencies.
- Independent review status is tracked separately by the batch auditor. Do not treat an automatic generation check as a certified engineering clearance review.

## Attribution and rights
Geographic data ©[OpenStreetMap contributors](https://www.openstreetmap.org/copyright), available under[ODbL1.0](https://opendatacommons.org/licenses/odbl/1-0/). OSM-derived data is retained with provenance. Reference photographs remain with their credited photographers/providers and are **reference-only**, not included as textures or redistributed. Generated labels use Noto Sans Malayalam/Devanagari (SIL Open Font License) and DejaVu Sans; only rendered label pixels are included. Original procedural mesh/material work was produced for this project.


## Depot and service-building footprint distinctions
Named OSM MEMU footprint266072399 spans localX111.297–321.489 andY−49.702–−31.298, about210.2×18.4m. The model preserves its position and length but uses a20m-wide enclosure centred at(216.4,−40.3) to maintain outer-track clearance; this lateral enclosure allowance is reconstructed, not a surveyed footprint. Shed height, overhead service fittings, three inspection pits and interior equipment are reconstructed. Goods Shed266848044, FCI Storage266848045 and second terminal752939904 have named mapped footprints retained in source/yard_building_footprints.json. The distinct southern FCI Godown243514280 is recorded in that raw source but not modelled as a warehouse; its mapped rail spur is included.


## Historical facade revision02
The two small placeholder step outlines were replaced by filled red-white stepped-diagonal facade panels: a broad left rectangle and pointed right panel matching the September2020 photograph. These are wall infills, not public doors. The central public path, remote approach ramp and passed upper-office/bridge routes are unchanged. Camera04 is closer for an inspectable central facade; views01,02,04 were rerendered, with unaffected platform03 and interior05 explicitly retaining their immutable source hash. See ARCHITECTURE_REVISION.json and the exact repair script.
