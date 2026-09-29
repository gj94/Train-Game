# WAP-7 locomotive asset

An original, detailed Blender exterior inspired by **Lallaguda WAP-7 30306** in its
classic ivory and red livery. Created 30 September 2026. Chrome was used to inspect
real locomotive photographs, including the front, cab side and rooftop equipment.

## Open and inspect

- Editable master: `art/wap7/wap7_30306.blend`.
- Godot/glTF export: `assets/models/wap7.glb`.
- Overall render: `art/wap7/hero.png`.
- Export inspection renders: `art/wap7/hero_glb.png`, `front_glb.png`,
  `bogie_glb.png`, `roof_glb.png`, and `side_glb.png`.

Open the master in Blender and use Numpad 0 for the prepared hero camera. In the
Outliner, expand **WAP-7 • locomotive assemblies** to select the body, either cab,
bogies, wheelsets and pantographs. The separate **STUDIO • excluded from GLB**
collection contains the track, floor, lights and five inspection cameras. Select
another camera and use Ctrl+Numpad 0 to make it active. Use Material Preview for
orbiting, or F12 for a Cycles render. All geometry is saved in the master; opening
it does not run the builder. Text is converted to mesh, so no installed font is
needed to open or export the model.

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

## Scale, integration and limits

Blender coordinates are metres, **X across, +Y cab 1, Z up**, with rail top at
Z=0. GLB conversion gives Godot **-Z forward and Y up**, matching the MEMU asset.
Nominal dimensions used: 20.562 m over couplers, 3.152 m body width, 12 m between
bogie centres, 1.85 m adjacent axle spacing and 1.092 m wheel tread diameter.
The actual export extends to ±1.79 m across its projecting steps; flange bottoms
extend 29 mm below rail top. The raised pantograph reaches approximately 5.75 m.

The master has **53 mesh objects, 693,756 evaluated triangles and 46 materials**;
the GLB is approximately 18.5 MiB. Meshes are grouped by functional assembly;
bogies and pantographs have useful parent origins, and each wheelset has an axle
origin. They are independently selectable but no animated actions are supplied.
All exported materials use backface culling. Studio geometry, cameras and lights
are excluded from the export. `art/wap7/.gdignore` excludes the editable master
and inspection images from Godot's importer.

This is a high-detail visual reconstruction, not a measured engineering replica.
Small equipment positions, underside fittings, roof machinery and stencils are
interpreted from class references; it does not reproduce every era-specific
fitting of 30306. English side lettering is used. The cab glazing is opaque PBR
glass; a complete driving interior, operable mechanisms, collision shapes and
authored LOD meshes are not included (Godot generates automatic mesh LODs on
import). The asset is not yet assigned to a playable service;
the two existing MEMU services, simulation, sound and graphics settings remain
as before.

## Rebuild and verify

Run from the repository root, only in background Blender:

```powershell
& .\.local\blender\blender-5.2.1-windows-x64\blender.exe --background --factory-startup --python tools/blender/build_wap7.py -- --render
& .\.local\blender\blender-5.2.1-windows-x64\blender.exe --background --factory-startup --python tools/blender/render_wap7.py -- --roundtrip hero front bogie roof side
powershell -ExecutionPolicy Bypass -File tools/godot.ps1 test
& .\.local\godot\Godot_v4.7.2-stable_win64_console.exe --headless --path . --script res://tools/check_wap7.gd
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

## Research and rights

These photographs were **viewed as references in Chrome**; their pixels are not
included in the master, GLB or materials. Geometry, materials and renders are
original project work. No downloaded third-party model or photo texture is used.

| Reference | Author / licence | Details inspected |
|---|---|---|
| [LGD WAP7 30306 at Bangalore](https://commons.wikimedia.org/wiki/File:LGD_WAP7_30306.jpg) | Pramath S.B, CC BY-SA 3.0 | Primary identity, front windows and guards, lamps, stripe, buffers, pilot and numbering; photographed 29 Nov 2012 |
| [Cab-side view at Vijayawada](https://commons.wikimedia.org/wiki/File:Side_view_of_a_WAP_7_class_Locomotive_of_Indian_Railways.jpg) | Adityamadhav83, CC BY-SA 3.0 | Cab door/window proportions, large grille, handrails, pantograph base; photographed 30 Sep 2011 |
| [WAP-7 outside Mumbai Central](https://commons.wikimedia.org/wiki/File:WAP-7_Locomotive_outside_Mumbai_Central_Passenger_station.jpg) | Historical Trains, CC0 1.0 | Overall side layout, roof silhouette and folded pantographs; photographed 20 May 2023 |

Chrome searches also located BLW's WAP7 technical leaflet and IRICEN's
*WAP7/WAG9 Three Phase Locomotives* monograph. Search excerpts supported a
3.7 m bogie wheelbase and 20.562 m overall length. The official document sites
did not load reliably, so they were not used as a claim of full drawing-based
verification. Remaining scale values are nominal modeling parameters and small
detail geometry is photo-proportioned.
