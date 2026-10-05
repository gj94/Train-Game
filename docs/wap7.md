# WAP-7 locomotive asset

An original, detailed Blender locomotive inspired by **Lallaguda WAP-7 30306** in its
classic ivory and red livery. Created 30 September 2026. Chrome was used to inspect
real locomotive photographs, including the front, cab side and rooftop equipment.
It now includes both driving interiors and a playable light-engine scenario.

## Drive it

1. Run the game, then press **F2**, or choose **WAP-7 [F2]** on the dispatch
   board. This restarts in Cab 1 at Chennapuram. The initial route is cleared to
   Maruthur's main-line starter. F2 switches back to the six-MEMU corridor.
2. Hold **W / Up** to increase power. **S / Down** moves the combined handle back
   through coast into service braking; **X** selects coast. Obey the HUD limits.
   **Space** applies emergency braking; press it again after stopping to release.
3. **Right-drag** looks around the cab, including fully rearward; releasing returns
   the view ahead. Mouse wheel changes field of view. **Tab** toggles exterior / cab.
   **D** shows or hides the route desk; **F1** lists controls.
4. Use **C** or **D** to set onward routes: **MRT-E1 → E-AE1**, then
   **KDP-H → BUFFER:KDP_B1**. **A** hands driving to the existing AI if desired.
   The AI obeys signals and limits but does not set its own routes.
5. Stop before Kadalur's buffers and press **R** to change to the physical Cab 2.
   Set **KDP-W1 → E-AW1**, **MRT-HW → MRT-W3**, **MRT-W3 → W-AW1**, and
   **CPM-H → BUFFER:CPM_B3** for the return. Reversing is refused while moving or
   before an owned movement has reached its reserved block.

Direct launch: `Godot_v4.7.2-stable_win64.exe --path . -- --wap7` using the executable
under `.local/godot/`. This scenario is one locomotive without coaches; the
six-service, eight-car MEMU corridor remains available by pressing F2 again.

For the locomotive hauling 20 full-length LHB coaches, press **F3** and see
[LHB coaches and passenger controls](lhb.md). The complete assembled Blender rake
is `art/lhb/wap7_lhb_rake.blend`.

## Open and inspect

- Complete editable master, exterior and both interiors: `art/wap7/wap7_30306_full.blend`.
- Original exterior master: `art/wap7/wap7_30306.blend`.
- Interior master with three inspection cameras: `art/wap7/wap7_cab.blend`.
- Godot/glTF export: `assets/models/wap7.glb`.
- Reusable interior export: `assets/models/wap7_cab.glb`, instantiated at both ends.
- Overall render: `art/wap7/hero.png`.
- Export inspection renders: `art/wap7/hero_glb.png`, `front_glb.png`,
  `bogie_glb.png`, `roof_glb.png`, and `side_glb.png`.
- Interior renders: `cab_driver.png`, `cab_overview.png`, `cab_rear.png`.
- Actual game captures: `game_cab1.png`, `game_desk.png`, `game_rear.png`,
  `game_exterior.png`, `game_driving.png`, `game_cab2.png`, `game_routes.png`,
  and `game_memu_selector.png`.

Open the master in Blender and use Numpad 0 for the prepared hero camera. In the
Outliner, expand **WAP-7 • locomotive assemblies** to select the body, either cab,
bogies, wheelsets and pantographs. The separate **STUDIO • excluded from GLB**
collection contains the track, floor, lights and five inspection cameras. Select
another camera and use Ctrl+Numpad 0 to make it active. Use Material Preview for
orbiting, or F12 for a Cycles render. All geometry is saved in the master; opening
it does not run the builder. Text is converted to mesh, so no installed font is
needed to open or export the model.
The complete master adds **WAP7_DrivingInterior** and **WAP7_DrivingInterior_Cab2**
collections. Use the separate cab master for unobstructed interior inspection;
its `Cab_Driver`, `Cab_Overview` and `Cab_Rear` cameras are already positioned.

## Modeled detail

- Chamfered body, sloped cab faces, continuous red belt, roof crown, rain gutters,
  panel gaps, lower access covers, rivets and fasteners.
- Twin glazed windscreens, rubber seals, metal surrounds, protective guards,
  wiper arms/blades/pivots, sliding side windows, cab doors, hinges, latches,
  handrails and grated steps.
- Twin central headlamps with lens ribs, marker/tail lamps, sockets, road numbers,
  LGD badge, small tricolours, side lettering and maintenance stencils.
- Circular buffers, shaped centre couplers, release handles, air hoses, valves,
  open pilot grilles and diagonal supports at both ends.
- Two Co-Co bogies, six individually named wheelsets, flanges and machined treads,
  wheel-face recess details, axleboxes, bolt circles, primary and secondary coil
  springs, dampers, brake blocks/linkages, traction motors, gear housings and
  sanding pipes.
- Underframe transformer, battery/equipment boxes, ribbed covers, air reservoirs,
  straps and pipework.
- One folded and one raised pantograph, articulated arms, pivots, cross-bracing,
  spring packs, contact strips and horns; roof insulators, copper bus, breaker
  assembly, cables, hatch fasteners, lifting handles, walkways and fan grilles.
- Both driving cabs: grey wraparound desk, knee recesses, separate speed recorder,
  power/brake demand gauges, DDU, annunciators, controller and brake handles,
  emergency mushroom, auxiliary toggles, radio/microphone and clipboard.
- Rounded upholstered seats, armrests, seat pedestals, driver's pedal, ribbed floor,
  lined walls, sliding-window runners/latches, windscreen surrounds and visors,
  twin caged fans, ceiling light, rear electrical cabinet, machine-room door,
  extinguisher and safety notices.
- Working speed needle/digital readout, live power/brake demand needles, lamps,
  controller/brake-handle animation and DDU with actual speed, demand, emergency,
  AI/manual state and physical cab number. Auxiliary switches and fans are static.

## Scale, integration and limits

Blender coordinates are metres, **X across, +Y cab 1, Z up**, with rail top at
Z=0. GLB conversion gives Godot **-Z forward and Y up**, matching the MEMU asset.
Nominal dimensions used: 20.562 m over couplers, 3.152 m body width, 12 m between
bogie centres, 1.85 m adjacent axle spacing and 1.092 m wheel tread diameter.
The actual export extends to ±1.79 m across its projecting steps; flange bottoms
extend 29 mm below rail top. The raised pantograph reaches approximately 5.75 m.

The exterior has **53 mesh objects, 693,756 evaluated triangles and 46 materials**;
the GLB is approximately 18.5 MiB. Meshes are grouped by functional assembly;
bogies and pantographs have useful parent origins, and each wheelset has an axle
origin. The game articulates both bogies along the track and rotates all six
wheelsets with distance travelled; no Blender animation actions are supplied.
All exported materials use backface culling. Studio geometry, cameras and lights
are excluded from the export. `art/wap7/.gdignore` excludes the editable master
and inspection images from Godot's importer.

This is a high-detail visual reconstruction, not a measured engineering replica.
Small equipment positions, underside fittings, roof machinery and stencils are
interpreted from class references; it does not reproduce every era-specific
fitting of 30306. English side lettering is used. The exterior uses opaque PBR
glass. In cab view, glass is cleared and exterior door backing assemblies are
hidden in favour of the dedicated lining and its open window apertures. Interiors
are hidden in overview. Changing ends preserves the locomotive's physical
orientation and activates the opposite cab and headlight. The machine-room door
is closed; there is no walk-through machinery compartment or clickable switch
simulation. Godot generates automatic mesh LODs on import.

Simulation remains independent of rendering. Its approximate light-engine profile
uses 108 t, 4.5 MW at the wheels, a 1.0 m/s² low-speed traction cap and 140 km/h
vehicle maximum; the layout's lower speed limits still apply. The inherited
combined-handle, braking and protection systems are gameplay abstractions, not a
WAP-7 air-brake or electrical-system training simulator. Power/brake gauges show
**demand percentages**, not simulated amperes or air pressure. Track sound uses the
existing approved impact kernels at the actual six Co-Co axle positions. No sound
data or graphics quality settings changed.

## Rebuild and verify

Run from the repository root, only in background Blender:

```powershell
& .\.local\blender\blender-5.2.1-windows-x64\blender.exe --background --factory-startup --python tools/blender/build_wap7.py -- --render
& .\.local\blender\blender-5.2.1-windows-x64\blender.exe --background --factory-startup --python tools/blender/render_wap7.py -- --roundtrip hero front bogie roof side
& .\.local\blender\blender-5.2.1-windows-x64\blender.exe --background --factory-startup --python tools/blender/build_wap7_cab.py -- --render
powershell -ExecutionPolicy Bypass -File tools/godot.ps1 test
& .\.local\godot\Godot_v4.7.2-stable_win64_console.exe --headless --path . --script res://tools/check_wap7.gd
& .\.local\godot\Godot_v4.7.2-stable_win64_console.exe --headless --path . --script res://tools/check_wap7_playable.gd
& .\.local\godot\Godot_v4.7.2-stable_win64_console.exe --headless --path . --script res://tools/check_dispatch_ui.gd
```

The first command rebuilds the master and GLB, writes geometry statistics and
renders the master. The second loads the master studio, removes the source
locomotive, imports the actual GLB, checks its dimensions, six wheelsets and
single-sided materials, then renders five inspection views. Its checks are saved
in `art/wap7/export-validation.json`. The builder refuses to run inside an
interactive Blender session. Rebuilding uses the Windows Bahnschrift font when
available, with Blender's built-in font as fallback; exported geometry has no
font dependency. After Godot's import finishes, the last command checks the real
imported PackedScene: 53 meshes, six axles at the correct height/spacing,
backface-culling materials and no studio objects.
The cab builder also assembles the complete two-interior master from the exterior
master. The playable check loads the real main scene, injects W input, checks
emergency/release, wheel and sound-axle alignment, both cabs and preserved body
orientation, operates route buttons, completes an outward/return trip and switches
back to the MEMU scenario. The dispatcher check covers the original two-train meet.

## Research and rights

These photographs were **viewed as references in Chrome**; their pixels are not
included in the master, GLB or materials. Geometry, materials and renders are
original project work. No downloaded third-party model or photo texture is used.

| Reference | Author / licence | Details inspected |
|---|---|---|
| [LGD WAP7 30306 at Bangalore](https://commons.wikimedia.org/wiki/File:LGD_WAP7_30306.jpg) | Pramath S.B, CC BY-SA 3.0 | Primary identity, front windows and guards, lamps, stripe, buffers, pilot and numbering; photographed 29 Nov 2012 |
| [Cab-side view at Vijayawada](https://commons.wikimedia.org/wiki/File:Side_view_of_a_WAP_7_class_Locomotive_of_Indian_Railways.jpg) | Adityamadhav83, CC BY-SA 3.0 | Cab door/window proportions, large grille, handrails, pantograph base; photographed 30 Sep 2011 |
| [WAP-7 outside Mumbai Central](https://commons.wikimedia.org/wiki/File:WAP-7_Locomotive_outside_Mumbai_Central_Passenger_station.jpg) | Historical Trains, CC0 1.0 | Overall side layout, roof silhouette and folded pantographs; photographed 20 May 2023 |
| [Footplating and Testing a P7](http://sundarmukherjee.blogspot.com/2014/03/footplating-and-testing-p7.html) | Sundar Mukherjee; viewed in Chrome's image preview, no pixels copied | Real cab photograph: grey desk, sloping switch panels, separate speed recorder, instrument placement, windows and overhead fans |

Chrome searches also located BLW's WAP7 technical leaflet and IRICEN's
*WAP7/WAG9 Three Phase Locomotives* monograph. Search excerpts supported a
3.7 m bogie wheelbase and 20.562 m overall length. The official document sites
did not load reliably, so they were not used as a claim of full drawing-based
verification. Remaining scale values are nominal modeling parameters and small
detail geometry is photo-proportioned.

The old scene integration keeps the small layout as a fixture. The corridor suite
also checks a complete outward/return trip on the expanded double-line route,
including both terminal crossovers and arrival at Chennapuram P3.
