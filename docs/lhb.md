# LHB passenger coaches and playable WAP-7 rake

Original Blender models in classic red and grey: **AC three-tier (72 berths)** and
**AC two-tier (52 berths)**, with complete passenger compartments and end interiors.
The playable short formation is **WAP-7 30306 + B1 B2 B3 B4 A1 A2**. It fits all three
stations on the existing fictional line. Created 30 September 2026.

## Play

1. Run the game and press **F3**, or choose **LHB [F3]** on the dispatch board.
   This restarts at Chennapuram in the WAP-7's driving cab. The route is already
   cleared through Maruthur main. Direct launch: `Godot_v4.7.2-stable_win64.exe
   --path . -- --lhb` using the executable under `.local/godot/`.
2. Hold **W / Up** for more power, **S / Down** through coast into braking.
   **X** coasts; **Space** applies emergency braking and releases it at a stand.
   **A** toggles the AI driver. The AI obeys signals and speed limits but does not
   set routes. The heavier rake accelerates more slowly than the light engine.
3. **V** enters the passenger coach, preserving the current AI/manual setting and
   handle position. **PgUp / PgDn** selects B1–B4 or A1–A2. **Left / Right** visits
   the nine berth bays and both vestibules. **Home** switches between looking
   down the aisle and looking into the compartment. **Right-drag** looks around;
   release to face ahead. Mouse wheel zooms.
4. **B** lowers or folds the 3A middle berths across the rake. In daytime they form
   the blue seat backs; in sleeping mode they become the middle beds. 2A has
   fixed lower/upper berths, blue seat backs and gathered curtains.
5. **V** from a passenger view returns to the locomotive and takes manual control
   with the handle at coast. **Tab** leaves either interior for the exterior;
   Tab from the exterior takes the driver's cab. **F** follows the full rake.
6. Set **MRT-SE1 → KDP-H**, then **KDP-H → BUFFER:KDP_B** using **C / D** and the
   route desk. Without those routes, the AI stops safely before Maruthur's red
   starter. Brake before Kadalur's buffers; the whole rake fits the terminal.
7. This is an **outbound working**. **R** explains that a locomotive run-round is
   needed instead of swapping the passenger end into a driving cab. At arrival,
   use **RESTART SERVICES** for another trip. Run-round/shunting is not simulated.
   **F2** selects the WAP-7 light engine; **F3** returns to the original MEMU meet.
   Scenario changes restart the working. **F1** shows all controls.

## Blender files

- **`art/lhb/wap7_lhb_rake.blend`** — complete editable locomotive, both driving
  interiors and six coupled coaches. Copies share mesh data, with separate coach,
  bogie, axle and berth parents. Select `Rake_Hero` or `Coach_Close` cameras.
- **`art/lhb/lhb_3a.blend`** and **`art/lhb/lhb_2a.blend`** — individual masters,
  each with a separate studio and Hero, Bogie, Aisle, Compartment and Vestibule cameras.
- **`assets/models/lhb_3a.glb`**, **`lhb_2a.glb`** — metre-scale game exports, only
  coach assemblies. Blender +Y becomes Godot -Z; rail top is asset Z=0 / Godot Y=0.
- **`art/lhb/*_glb.png`** — inspection renders re-imported from the real exports.
  **`art/lhb/game_*.png`** — actual Forward+ game captures of the rake, both classes,
  berth positions, vestibule/washbasin, driving and route desk.

The masters include rounded glazed window openings and seals, door handles,
grab rails, hinges and patterned steps; roof RMPUs with condenser fans and grilles;
underframe battery/tank/brake equipment and pipes; hollow gangway bellows, tightlock
couplers, hoses and tail markers. FIAT bogies have primary/secondary coils, dampers,
axleboxes, wheel treads/flanges, three axle-mounted brake discs and calipers.

Inside are the full berth layouts, partitions, ladders, safety rails, folding middle
berths, blue cushions, under-seat luggage racks, window tables, wire bottle holders,
number plates, reading lamps, sockets, ceiling fans/vents/lights, 2A curtains, glazed
vestibule doors, washbasins/taps/mirrors, toilet fixtures, extinguishers and notices.
Only the 3A middle berths are interactive; doors, taps, lights and other fittings are
decorative. Passenger navigation uses inspection positions, not a walking controller.

## Dimensions, simulation and limits

The model uses a **23.54 m body**, **24 m over couplers**, **3.24 m outer width**,
**14.9 m bogie centres**, **2.56 m bogie wheelbase**, **915 mm wheel diameter**,
and approximately **1.32 m floor height** above the rails. Both visual variants use
the common 4.25 m AC3-style roof envelope; the 2A roof and final partial bay are an
interpretation, not a reproduction of a specific production drawing. The short
four-3A/two-2A formation is a fictional HOG-compatible test working, not a claim
about the actual consist of a named Indian Railways service.

`sim/stock/lhb_consist.gd` owns formation geometry independently of rendering.
The full train is **164.562 m**, with an approximate **408 t loaded mass**, WAP-7's
existing 4.5 MW power profile, 0.65 m/s² low-speed traction cap and 0.8 m/s² service
braking. These are gameplay values; distributed air-brake delays, coupler slack,
electrical HOG systems and a train-specific timetable are not simulated.

The view samples each coach and bogie along the track and rotates all wheelsets.
Only the last coach shows tail lamps/LV board. Sound uses all **30 real axle
positions**; the onboard listener follows the selected passenger coach and bay.
The approved existing sound kernels, TRACK_ONLY and clang +2 dB remain in use.
Project graphics settings have not been altered. Each coach export contains roughly
0.9 million evaluated triangles; Godot generates its usual automatic mesh LODs.

## Research and provenance

Chrome was used for dimensions, real exterior photographs and an enlarged image
of a real classic LHB interior. Search results containing other artists' 3D models
were excluded as photographic evidence. All meshes are original procedural work;
no photograph pixels, downloaded train meshes or video frames are shipped.

- [LHB coach overview](https://en.wikipedia.org/wiki/LHB_coach): nominal dimensions,
  coach types and berth capacities viewed in Chrome.
- [LHB AC 3 tier coach of Golden Temple Mail](https://commons.wikimedia.org/wiki/File:LHB_AC_3_tier_coach_of_Golden_Temple_Mail.jpg),
  Ravi Dwivedi / Libreravi, 11 May 2022, CC BY-SA 4.0: real red/grey exterior,
  windows, destination boards and underframe reference viewed in Chrome.
  The photograph is referenced, not incorporated or redistributed.
- [AC 3 Tier LHB Coach Interiors — Chennai Trivandrum SF Mail](https://www.youtube.com/watch?v=cow1W1eJ3Hg),
  Jerin G, 19 June 2018: enlarged video thumbnail viewed through Chrome image search
  for blue upholstery, pale partitions, stainless rails and bottle holders.
  This was a visual reference, not a full-video inspection or a reused video asset.
- RDSO's indexed [Revised LHB Maintenance Manual introduction](https://rdso.indianrailways.gov.in/uploads/files/Revised_LHB_Manual_Vol_II_Chapter_I_Introduction_Draft.pdf)
  corroborated headline dimensions in search results. The PDF itself could not be
  fetched in this session; no detailed manufacturing accuracy is claimed from it.

Fittings and proportions not resolved by these references are interpreted.
Markings are English and the coach numbers are illustrative. Blender procedural
micrograin stays in the native masters; glTF uses the corresponding base materials.

## Rebuild and verify

Run only background Blender; do not run a builder in an open user Blender session:

```powershell
& .\.local\blender\blender-5.2.1-windows-x64\blender.exe --background --factory-startup --python tools/blender/build_lhb.py
& .\.local\blender\blender-5.2.1-windows-x64\blender.exe --background --factory-startup --python tools/blender/assemble_lhb_rake.py
& .\.local\blender\blender-5.2.1-windows-x64\blender.exe --background --factory-startup --python tools/blender/render_lhb.py -- 3a Hero Aisle Compartment Bogie --glb
```

Rescan through Godot MCP and wait for import to finish. `art/lhb/.gdignore` keeps
native masters/studios out of the game import. Then run:

```powershell
& .\.local\godot\Godot_v4.7.2-stable_win64_console.exe --headless --path . --script res://tests/run_tests.gd
& .\.local\godot\Godot_v4.7.2-stable_win64_console.exe --headless --path . --script res://tools/check_lhb.gd
& .\.local\godot\Godot_v4.7.2-stable_win64_console.exe --headless --path . --script res://tools/check_lhb_playable.gd
```

Asset checks count 72/52 actual berths and four correctly spaced axle pivots in each
export. Scene checks exercise W/S, emergency/release, all 30 physical/sound axle
positions, passenger selection and listener placement, both vestibules, berth
deployment, safe arrival, the run-round guard and return to the MEMU scenario.
The existing WAP-7 round trip and full two-MEMU meet checks also pass.
