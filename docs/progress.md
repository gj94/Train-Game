# Progress

## 2026-10-06 — Smooth close-up motion and a deeper second axle
- Replaced fixed-step visual train positions with route-distance interpolation shared by bodies, bogies, wheel rotation, camera targets and joint-sound scheduling. The old tail edge is retained until the rendered tail clears it; teleport/cab changes snap safely. Simulation/interlocking remain independent. Disabled Godot's physics jitter correction for this custom interpolation. The overview camera now carries forward the train's movement before easing its framing, avoiding speed-dependent lag at 3 m zoom.
- Updated the **sibling sound lab source**, then regenerated both impact WAVs and `physical_model_data.gd`: second axle **four semitones lower**, **+5 dB clang balance** (3 dB louder than before). Impact remains anchored at 768 samples / 17.415 ms, with the full longer decay retained. First-axle samples, fitted profile and rolling WAV are unchanged. Reversed imported two-axle bogies now retain cling-then-clang ordering. Comma/period still adjust balance.
- Added five route-interpolation tests, a reverse axle-order test, and an actual default-rake/camera/audio integration check to the Windows build checks. **108 unit tests pass**. The actual scene advances at every intermediate 240 Hz sample (0.083021–0.083510 m per frame) with zero measured close-follow error. A real engine-clock probe also found zero display-only stalls; rendered capture is `.local/motion-close-up.png`.
- Sound-lab targeted tests: **16 pass**; its complete suite has one unrelated failure because `examples/target-55-95-synthetic.wav` is absent. The approved fit was not recreated to hide that missing reference. Measured game audio has exactly +5 dB energy balance, a 0.7937 pitch ratio, unchanged lead, and no clipping in the comparison sample (`.local/audio-preview/`). Source changes are `src/game-track-tuning.js`, `test/game-track-tuning.test.js` and `tools/physical-export-godot.js` in the sibling lab.
- Graphics quality is unchanged. A 1280×720 wheel-level Forward+ probe on this host's Radeon 780M averaged about 19 FPS; GPU profiling attributes most time to geometry/shadow passes. The user confirmed the receiving PC has an RTX 4090. Its performance still needs a playtest; the interpolation correction does not imply a measured frame-rate claim for that PC.
- **Playtest:** download the refreshed ZIP and extract into a fresh folder. Launch the default WAP-7/LHB rake, press A for AI and Tab for exterior, and zoom on an LHB bogie while travelling at 40–80 km/h. Check smooth wheel/body/camera movement and a distinctly deeper, louder second axle at each fishplated gap. Check paused/resumed motion, a curve, and the rhythm after reversing. Comma/period adjust clang balance.
- Final complete integrations, release packaging and LAN publication are in progress.

## 2026-10-05 — LAN download server for the portable build
- Serving the latest 390.7 MiB mixed-LHB Windows ZIP at **http://192.168.8.183:8765/** using a hidden Node process. The server exposes only the ZIP, checksum, portable instructions and download page, binds to the Ethernet LAN address and accepts clients from its /24 subnet. Byte-range requests support resumed downloads. No router forwarding or startup task was configured.
- Verified a complete HTTP transfer of **409,647,224 bytes** against the archive's SHA-256, plus download headers, range requests and refusal of unrelated files/write methods. The user confirmed that access from the other PC works. Windows has enabled its Node inbound allowance; the separate administrator prompt for a narrower custom rule was canceled, so no custom rule was added.
- `tools/share-build.ps1` starts, reports or stops the server with a checked process identity. `tools/serve-build.mjs` uses the installed Node runtime without new dependencies. Instructions are in `docs/builds.md`; machine-local PID/logs are `.local/lan-share.*`. Keep the host awake during downloads; after extraction the receiving PC runs the game independently. The server must be restarted after a host reboot.

## 2026-10-05 — Default WAP-7 with mixed LHB coaches
- Fresh launches now start in the imported WAP-7 cab hauling seven LHB coaches: **1A, 2A, 3A, 2S, CC, SL and GS**. This uses the existing 188.560 m formation with 34 physical/sound axles. Explicit fleet selections, original F2/F3 scenarios and restart selection still take precedence; `-- --memu` directly opens the six-MEMU dispatcher.
- Updated the startup/portable guides and existing integration fixtures. The QoL check verifies the actual default locomotive, all seven coach models, cab state and axle count; the corridor check explicitly selects MEMUs.
- **102 headless tests pass**, plus track geometry, 25 fleet finishes/imports, default/QoL, six-service corridor and all seven imported fleet journey/menu checks. Rebuilt `export/TrainGame-Windows.zip` from clean commit `933f076`; verified extracted EXE/PCK hashes and a no-argument release launch (exit 0, no errors). Smoke-test copy: `.local/default-lhb-package/`; log: `.local/default-lhb-release.log`.
- **Playtest:** launch F5 or the rebuilt EXE with no arguments. Confirm WAP-7 + seven mixed LHB coaches, press Tab for the exterior, V then PgUp/PgDn to visit each class, and W/S to drive or A for AI. F9 selects other imported workings; F2 then F2 again (confirm each) returns to six MEMU services.

## 2026-10-05 — Realistic permanent way, sound-aligned joints and fleet finishing
- Replaced the box-sleeper track with a dedicated rendering adapter: correct 1,676 mm visible gauge, shaped 172 mm rails with worn heads/oxidised webs, 2.75 m cast concrete sleepers at 1,660/km, pads, spring clips and shoulders, coarse granite with scattered stones and irregular ballast shoulders. Local 64 m sections and distance-limited fine hardware keep the long route manageable. Rail top remains 0.5 m; simulation alignment and graphics-quality settings are unchanged.
- Modelled stock rails, tapered moving switch tongues, shared turnout bearers, motor/slide chairs, drive/detection rods, crossing noses, wing rails and check rails. Tongues/rods follow actual locked route state with elapsed-time animation. Replaced glowing point discs with small unlit indicators. The geometry follows the fictional graph; it is not a surveyed RDSO turnout or a new wheel/flange contact simulation.
- Added **always-visible 10 mm gaps and six-bolt fishplates**, centred on the approved sound model's 13 m joint spacing / 6.5 m edge offset. `rail_joint_layout.gd` now owns constants used by both the renderer and sound scheduler. Rail triangles cannot bridge those openings; both travel directions trigger the corresponding joint. Existing kernel lead/lateness, generated sound data, levels and clang balance are unchanged. This deliberately represents jointed track, not modern continuous-welded mainline practice.
- Built a new original MEMU detail kit in **background Blender**: fabricated bogie frames, springs/dampers, brake rigging, wheel treads/flanges/faces, axle boxes, reservoirs, louvred cabinets, plumbing, couplers/hoses, window bars/gaskets, steps/handrails, roof fittings and cab wipers/horns. `art/memu/memu_detailed.blend` is editable; the export is about 11.9 MiB. The existing vehicle dimensions are retained. All 16 bogies / 32 axles in an eight-car rake steer/rotate and match the sound positions. Corrected steps to remain clear of platform coping and hid the duplicate exterior wiper in cab mode.
- Added non-destructive material finishing across the MEMU, original WAP-7/LHB and 25 imported models: enamel wear/rain film, roof dirt, brake dust, oxidised wheel faces with burnished treads, rough metal and dark reflective exterior glazing. Source exports, instrument textures and labels remain intact; onboard glass clearing restores the finished exterior on exit. Exterior camera zoom now reaches **3 m** with a rail-height target for inspecting hardware.
- **102 headless tests pass.** New track geometry/joint/point checks and all 25 fleet-finish/source-preservation checks pass; MEMU rig/sound/contact checks pass. Imported asset checks, seven complete fleet journeys, six-train corridor integration, QoL, original WAP-7 round trip and full LHB integration pass. Actual graphical captures reviewed wheel-level track, open joints/fishplates, both point settings, seven representative fleets, coaches and cabs. Fixed sleeper shading/aggregate scale, overly bright wheel faces and duplicate MEMU wipers during review. Captures/logs are in `.local/track-after/`, `.local/fleet-finish/` and `.local/realism-*.log`. Sandboxed Godot still reports machine certificate/cache access diagnostics; no project script/shader failures were observed.
- Rebuilt **`export/TrainGame-Windows.zip` (390.7 MiB)** from clean source commit `48df6fd`, with `guides/track.md` and checksums. Verified the extracted EXE/PCK hashes; the MEMU and **all seven imported fleet choices** start and exit successfully from `.local/realism-package/TrainGame-Windows`, with no script or missing-resource errors. Release startup logs are `.local/release-realism-*.log`. The export completed with normal Windows certificate/cache access; sandboxed release checks retain the machine certificate diagnostic noted above.
- **Playtest:** follow **`docs/track.md`**. Zoom/orbit onto a bogie at 3 m, watch/hear each wheel cross a fishplated gap (J is optional diagnostics), change an unlocked junction's route and watch paired blades/rods, then check F9 fleet exteriors and Tab/V glass restoration. Check MEMU steps at platforms and bogie steering on curves. Human listening, close-camera comfort and target-PC performance still need feedback. Surrounding vegetation/towns remain visibly stylized; this pass does not claim whole-scene photorealism. Imported cab controls/doors retain their documented static limitations.

## 2026-10-05 — User-owned TF3 vehicle assets ported into a selectable Godot fleet
- Imported the **25 current Blender masters** from `gj94/transport-fever-3-mods`, pinned to `4c4f0be85edbf4468bca22f2d1285fec72343bd5`: WAP-7 pantograph v0.4, WAG-9, WAG-12B A/B, seven ICF and seven LHB coach classes, and seven compact Vande Bharat types. Downloaded files have verified Git blob hashes; generated metadata records source/output SHA-256 hashes. Original masters remain unchanged under ignored `.local/transport-fever-3-mods/`. User ownership and explicit reuse permission are registered in `docs/assets.md`; no open-source licence is inferred.
- Added a reproducible background-Blender converter (`tools/blender/port_tf3_assets.py`) and pinned downloader. It preserves metre scale, UVs, materials, packed WAP-7 textures, interiors and rigid pivots while consolidating meshes. Godot generates mesh LODs. Visual inspection caught the source VB ceiling's outward winding; the conversion now reverses the lining faces/normals, with a regression check that all seven ceilings face inward. Rendered captures are in `.local/ported-preview/`.
- **F9 / Escape → Imported fleet** selects seven playable workings: three locomotive types, WAP-7 with each seven-class coach showcase, and compact 8/16-car Vande Bharat. These use the existing Southern corridor, manual/AI driving, signalling, braking, route interlocking and cab/passenger controls. Cancel preserves the current run. Physical model spacing and visible end overhangs define occupancy; wheels/bogies animate, pantographs reach the route's 5.6 m wire, and sound timing follows every physical axle. WAG-12 sections and VB cars articulate independently. Reversal preserves physical orientation and updates audio geometry; loco-hauled showcases retain the run-round guard. Simulation profiles remain independent of rendering. Existing scenarios and generated sound data are unchanged.
- **102 headless tests pass, zero failures.** `check_ported_assets.gd` passes all 25 imports and seven formations: bounds/orientation, materials/textures, pivots, spacing, axle/rail/audio alignment on straight track and a 600 m radius curve, pantograph level/range, cameras and physical reversal. `check_ported_playable.gd` passes all seven actual-scene corridor journeys, throttle/emergency controls, safe approach to red, onward routes/completion, passenger cycling, reversal, menu cancellation and accepted fleet selection. Full graphical checks also pass; final VB captures verify repaired ceilings. Existing QoL, six-service corridor, WAP-7 and LHB integrations pass. A duplicate-event warning in the initial test harness was corrected; original WAP-7 integration still reports its known six ObjectDB shutdown leaks. Sandboxed Godot runs report Windows certificate/cache access diagnostics; normal-access export succeeds.
- Rebuilt `export/TrainGame-Windows.zip` (about **384.5 MiB**) with all models, runtime manifest and the new `guides/imported-fleet.md`. **All seven imported fleet choices start successfully from an extracted release copy**, exit 0, and report no script or missing-resource errors. Release templates require launching the EXE directly without `--path`. This remains a personal-use playtest build under the existing sound restriction. Build metadata records the source base plus uncommitted changes used for this build. Normal future builds also run both new imported-fleet check scripts.
- **Playtest:** open F9 and try WAG-9 and WAG-12B; Tab outside, zoom onto wheels/pantographs, stop and R to the other cab. Choose ICF and LHB showcases, V then PgDn through all seven classes; Home and arrows change viewpoint. Try both VB lengths and their end cabs. A runs to Maruthur; set **MRT-E1 → E-AE1**, then **KDP-H → BUFFER:KDP_B1**, to complete the corridor. Check comfort, clipping, audio and frame rate. Full details and rebuild commands: **`docs/imported-fleet.md`**.
- **Limits / next:** imported source gauges, switches, coach doors and berths remain decorative/static; HUD values are live. VB intentionally keeps the compact source dimensions. No freight wagons, passenger boarding/characters, TF3 economy/browser/scripts or private horn were imported. Dynamic coupler compression/yaw and human target-PC performance/comfort feedback remain future work. No claim of smooth performance on every PC or operationally exact cab instruments is made.

## 2026-09-30 — Uncluttered HUD and portable Windows playtest build
- Stopped the previous four-platform checkpoint. Default play now shows a compact two-line speed/limit/controller/next-signal HUD with small dispatch/help/menu buttons. Dispatch starts closed; its open/closed state is restored after a cab visit. Track labels and event history start hidden, with F6/F8 toggles. F4 clears the HUD/board/labels and restores the previous view; emergency-brake information and safety-event notices remain available. Toasts expire instead of leaving a permanent log over the world. The event history is scrollable.
- Added Escape pause/resume with a readable menu, scrollable F1 controls that pause and restore the previous pause state, F11 fullscreen/window, automatic pause on focus loss, and confirmation before restarting, changing scenarios or quitting (including window close). Modal input cannot change train controls. The initial window is 1280×720 with the existing 1600×900 UI scale; graphics quality, simulation and generated/approved sound data are unchanged. View choices are session-only; save/load is still absent.
- Simplified the dispatch header, moved scenario buttons beside the service controls, retained map/timetable access and a visible close button, and reserved clear space for the compact HUD. Reviewed 1280×720 overview, dispatch, timetable, cab, pause, help and clean-view captures under `.local/qol-*.png`. The portable EXE also rendered successfully from an extracted folder outside the checkout. Fullscreen and different-monitor readability still need the user's target-PC playtest.
- Added `export_presets.cfg`, `tools/build-windows.ps1`, generated-engine-licence support and `docs/builds.md`. Official Godot 4.7.2 templates were SHA-512 verified and extracted under `.local/export-templates/`. The x86-64 release includes the EXE/PCK, instructions, route/stock guides, asset provenance and engine notices, with SHA-256 checksums. It excludes editor addons, tests, build tools and original Blender files. Copy **`export/TrainGame-Windows.zip`** (about 336 MiB), extract the whole folder, and run **`TrainGame.exe`**; Godot/Blender/Node are not required on the target PC. This remains a personal-use playtest copy because of the existing sound-source provenance.
- **98 headless tests pass, zero failures.** `check_qol.gd` covers clean defaults, cab/desk restoration, modal clock/input blocking, help pause restoration, clean-view emergency feedback, event history/toast expiry, scenario cancellation, F4 from the pause menu, focus loss and window-close confirmation. Corridor integration passes six services/four concurrent berths/safe completion. Updated WAP-7 and LHB integrations pass the new confirmation flow and existing driving/cab/passenger/route checks. An isolated extracted release starts in MEMU, WAP-7 and LHB modes with exit code 0 and no script/missing-resource errors. The pre-existing audio ObjectDB shutdown warning scales to 18 instances for six trains during graphical movie capture; this did not prevent startup, rendering or normal termination.
- **Playtest on the other Windows PC:** extract the ZIP, run the EXE, press D and enable AUTO DISPATCH, then close D and check the clear railway view. Tab into/out of the cab with the board both open and closed. Try F4, F6, F8, F1/Esc, F11 and alt-tab/resume. F2/F3 must wait for confirmation; cancel should retain your current run. For LHB, confirm F3, press A then V and check passenger views. W/S/X/Space and C still control driving/routes. Quit from Escape. The game is left stopped after verification. Next: user feedback on target-PC readability, fullscreen, graphics performance and audio; no target-PC execution is claimed.

## 2026-09-30 — Expanded double-line corridor, four-platform yards and six-train dispatch
- Replaced the default 4.89 km demonstration with `sim/layouts/southern_corridor.gd`: **21.64 km between terminal buffers**, two directional mainlines at **6 m centres**, four block sections per direction between stations, and **four 600 m platform faces at every station**. The original `first_line.gd` remains a regression fixture. F2 light-engine and F3 full-length LHB modes use the expanded corridor too.
- Built three new `*_yard.blend` / `*_yard.glb` variants in background Blender, retaining the selected **Kumbakonam / Mayiladuthurai / Thanjavur** architecture. Two islands, covered bridge/stairs reaching both islands, platform-face numbering and four-road OHE portals match the simulation. These remain architectural adaptations on fictional yards, not surveyed station replicas.
- Added paired platform fans and successive terminal crossovers, with access to all four terminal roads. Corrected a crossover orientation that initially produced a geometric turn-back; route continuity is now checked. Mainlines allow left-hand directional running only. Speeds are 110 km/h on the mainline, 65 on normal platform roads and 30 on loops/crossovers. Homes sit 250 m before points; platform starter/clearance placement accommodates the **500.562 m** LHB rake.
- Added automatic plain-line block signals (A plates), platform-number route indicators on station homes, point motors and fouling markers. Automatic block control cannot move points; manual/optional automatic station dispatch uses the same route validation and interlocking. Opposing/shared-point conflicts and occupied platforms refuse routes. Fixed entrance routes remaining attached to a berthed train after its tail cleared the throat, allowing following trains into other free platforms while occupancy protects the first. Deduplicated crossover paths to a stable shortest route per exit.
- Rebuilt the dispatch schematic from the graph: complete double line, crossovers, four-platform yards, directional arrows, live aspects, occupancy/reservations, locks and proposed routes. Added **Whole line / CPM / MRT / KDP yard** views and selectable train labels. The right panel shows all six services, route refusal reasons and cab/AI controls; M timetable remains readable beside it. **AUTO DISPATCH** optionally requests booked routes; **HOLD MRT** holds Maruthur departures for the saturation demo. Both default off.
- Added `sim/timetables/southern_corridor.json`: six eight-car MEMUs, paired departures at 08:01/08:02/08:04, Maruthur +12 min with 3 min dwell, terminal +28 min. Actual times/delays are recorded. T1/T3 use MRT P1/P2; T2/T4 use P3/P4; T5/T6 wait for P1/P3 to become free. Completion/restart counts all six.
- Added original instanced lineside scenery: maintenance paths, cable troughs, drains/equipment cabinets, station compound walls, market streets and house lanes, village clusters, paddy bunds/planting/irrigation, two road overbridges with embankments and two watercourse culverts. Tree placement excludes the new infrastructure and fields. Reviewed actual game views and corrected floating road ramps, overly reflective fields, missing house rear windows and station portal placement. Towns/vegetation still use repeated procedural forms; richer unique weathering/detail remains art polish.
- **98 headless tests pass, 0 failures.** Seven corridor tests cover scale/direction, independent/conflicting routes, terminal access, path continuity/deduplication, complete LHB berthing/tail clearance, six-train saturation/recovery, and a WAP-7 outward/return trip. `tools/check_corridor_playable.gd` passes the actual main scene, all six rendered trains/roster selection, route chooser, timetable, four simultaneous station arrivals with following traffic held, occupied-platform refusal and all six completions **without SPAD, collision intervention or point run-through events**. Imported station dimensions pass `tools/check_stations.gd`. Legacy dispatcher, WAP-7 and LHB scene checks also pass; the previously known six ObjectDB audio shutdown leaks remain in the LHB check.
- Inspected the live whole-line schematic, MRT yard, selected timetable, four-train station scene, bridge, culvert, town and rural views. Captures: `art/stations/corridor_*.png`. Final project scripts have no live runtime errors or warnings; the MCP checkpoint snippet itself produces an unused `tree` parameter warning. No project graphics settings or generated sound data changed. Documentation and manual route tables are updated in **`docs/dispatching.md`**, `timetables.md`, `stations.md`, `wap7.md` and `lhb.md`.
- **Playtest from a fresh F5 launch:** enable **AUTO DISPATCH** and **HOLD MRT**, press **2**, choose **MRT YARD**, and press **T** twice. Wait until four trains occupy the four platforms and T5/T6 stop outside at red (roughly 08:16). Try **MRT-HE → MRT-E1** while P1 is occupied: it must refuse. Turn **HOLD MRT off** and watch the station clear, following trains berth, and all six finish. M shows timing; select any roster entry then Tab/A for cab/AI handoff. The current live scene is left paused at the four-platform checkpoint: turn HOLD MRT off and press Esc to continue.
- **Stock/scenery playtest:** F3 then A runs the full 20-coach train to Maruthur; inspect its head/tail alongside the platform. Set **MRT-E1 → E-AE1** and **KDP-H → BUFFER:KDP_B1** to continue. F2 supports the documented Cab 2 return. Use 1/2/3, D, orbit/zoom and F follow to inspect the platform yards and longer rural sections from the cab. Next: user feedback on visual density, readability, performance and timetable pacing; surveyed real yards, shunting/run-round, degraded signalling and save/load remain future work.

## 2026-09-30 — Southern Railway station references and full-length trains
- Replaced the generic station geometry with three original Blender kits based on the user's chosen **Kumbakonam, Mayiladuthurai Junction and Thanjavur** photographs. Added KMU's blue canopies and yellow/blue entrance with round piers and maroon crown; MV's red/white roofing and white-railed covered bridge; TJ's stepped entrance tower, coloured portico, barred windows and upper gallery. Full reference links, dimensions, ownership and modeling limits: **`docs/stations.md`**.
- Every platform has **600 m of level usable length**, 8 m ramps at each end, a surface **800 mm above rail**, full steel roof trusses, gutters, connected bridge stairs, tiled water points, benches, stalls, lamps, bins and multilingual yellow boards. Buildings have forecourts and original auto-rickshaws. Station OHE portals avoid the platforms and bridge; station scenery now uses a flat delta profile. The platform length is a realistic capacity choice, **not a surveyed measurement of the reference stations**.
- Kept the compact fictional line and names/route IDs, with architectural adaptations and reduced track counts. Expanded station roads, turnout approaches and starter positions together; the line now spans 4.89 km in X. Physical train/platform envelopes and entrance-point release are checked on both Maruthur roads. These are photograph-based reconstructions, not exact replicas of the real yards; people, tower ornament, surrounding vegetation and forecourt vehicles remain simplified.
- **F3** now supplies **WAP-7 + 20 LHB coaches, 500.562 m, 1,145.70 t gross**: EOG1 / B1–B16 / A1–A2 / EOG2. Added a distinct louvred generator/luggage van exterior; only the tail van has LV/tail fixtures. Passenger cycling skips both vans in either direction. The composition follows a reported SWR AC-special formation, while the service and route remain fictional. Rebuilt the editable full-rake master.
- Corrected the eight-car MEMU body/gap geometry to **21.337 / 0.795 m**, giving a **176.261 m modeled envelope**, and bogie/axle spacings to **14.783 / 2.896 m**. Rendering, simulation and axle scheduling share the geometry. No generated sound data or project graphics settings were changed. LHB sound scheduling matches all **86 physical axles**.
- Built everything in background Blender; masters are in **`art/stations/`**, exports in **`assets/models/stations/`**, with `tools/blender/build_stations.py` as source. Added an original metre-based weathering shader. Inspected the actual Godot imports from platform height and the forecourts; fixed roof sheets disappearing during mesh optimisation and entrance lettering hidden behind fascia. Reviewed game screenshots are saved in **`art/stations/`**.
- **91 headless tests pass, 0 failures.** `tools/check_stations.gd` checks imported platform dimensions, heights and bridge/canopy presence. `tools/check_lhb_playable.gd` passes 21 vehicles, 86 sound/mesh axle alignments, generator-skip camera cycling, both passenger classes, berth controls, braking, safe arrival, tail clearance and the run-round guard. Existing `tools/check_dispatch_ui.gd` two-service timetable/meet and `tools/check_wap7_playable.gd` cab/round-trip regressions also pass. Scene-exit checks still report the previously known six ObjectDB audio shutdown leaks. Final live launch reports **zero editor/runtime errors or warnings**.
- **Playtest:** use **1 / 2 / 3** to inspect the station buildings, right-drag/wheel to orbit/zoom, **D** to hide the dispatcher. In LHB mode, **F** follows the full rake, **Tab** enters the cab, **A** enables AI and **V** enters B1; **PgUp/PgDn** must cycle B1–B16/A1–A2 without entering a generator van. At Maruthur's red starter check that the tail is at the platform and clear of the entrance points. Set **MRT-SE1 → KDP-H → BUFFER:KDP_B**, then inspect the whole arrival at Kadalur. **F3** returns to the two-MEMU meet; follow `docs/dispatching.md`. R still requires a run-round for the LHB working.
- Next: user visual playtest against the references, particularly platform furniture, entrance silhouettes and the sense of scale from the cab. Exact surveyed yards, additional real station tracks and richer surrounding town scenery remain beyond this architectural adaptation.

## 2026-09-30 — Detailed LHB coaches and playable passenger rake
- Researched real red/grey coach exteriors and classic blue-berth interiors in Chrome. Built original **72-berth AC3** and **52-berth AC2** models in background Blender, with full compartment/vestibule/toilet interiors, rounded window openings, roof RMPUs, underframe equipment, detailed FIAT bogies, brake discs, gangways/couplers/hoses, markings and tail fixtures. References, modeling interpretations and controls are in **`docs/lhb.md`**.
- Native masters: **`art/lhb/lhb_3a.blend`**, **`lhb_2a.blend`**; complete editable locomotive with both cabs and six coaches: **`art/lhb/wap7_lhb_rake.blend`**. Game exports are **`assets/models/lhb_3a.glb`** and **`lhb_2a.glb`**, roughly 0.93/0.89 million evaluated triangles. Studios/cameras stay out of exports. `art/lhb/.gdignore` excludes the native work from game import. Builders/render inspector are under `tools/blender/`.
- **F3 / LHB [F3]** starts WAP-7 + **B1–B4 / A1–A2** in Cab 1 at Chennapuram, with initial authority through Maruthur main. The independent simulation profile carries **164.562 m**, approximately **408 t**, 4.5 MW, 0.65 m/s² initial acceleration cap and 0.8 m/s² service braking. F2 still provides the light engine; F3 from LHB returns to the original two-MEMU meet. No project graphics settings were changed.
- Each coach and bogie follows the track independently; 24 coach axle pivots rotate with distance. Only A2 shows tail markers/LV. Track sound schedules all **30 physical axles**, with the onboard listener following the passenger's actual coach/bay. Existing generated sound data, TRACK_ONLY and clang +2 dB are unchanged.
- **V** enters a passenger view without taking control away from AI. **PgUp/PgDn** selects coach, **Left/Right** moves through nine bays and both vestibules, **Home** swaps aisle/compartment views, right-drag looks around. **B** lowers/folds the 3A middle berths; folded berths become the seat backs. Returning to the cab with V takes manual control at coast. A2/2A has gathered curtains and fixed upper/lower berths.
- This scenario runs **outbound only**: R refuses with a run-round explanation instead of turning the non-driving rear coach into a cab. The complete rake fits each station; RESTART SERVICES starts another working. Doors and utility fittings are decorative; no free-walking, shunting, distributed air-brake dynamics, HOG electrical simulation or coach-specific timetable is included.
- **87 headless tests pass**, plus real imported-asset checks (72/52 berths, four axle pivots, FIAT dimensions) and `tools/check_lhb_playable.gd` (30 sound/mesh axle matches, W/S/brakes, passenger classes, listener placement, vestibules, berth folding, safe arrival, run-round guard and F3 scenario button). Existing WAP-7 outbound/return and two-MEMU dispatch/timetable regressions pass. Known audio shutdown leak warnings can still occur in scene checks.
- Inspected GLB round-trip renders and actual Forward+ captures in **`art/lhb/`**. Corrected reversed folded cushions, window corner lining and a buried basin opening during visual QA. Final native/GLB files imported through Godot; the editor was restarted after its first scan stalled on the initially unignored native-art folder.
- Launched the LHB working through Godot MCP using an ignored local launcher, verified a real V key event enters B1 with seven vehicles present, captured the live viewport, and left the train stopped in passenger view. **Zero editor/runtime errors or warnings** on the final launch. The main game still defaults to the MEMU meet; F3 is the permanent entry point for LHB.
- **Playtest:** press F3, W to depart/S to brake, A for AI, V to ride. Check B1 through A2 with PgDn; use Home/right-drag and B, and Left/Right past the end bays for vestibules. Set **MRT-SE1 → KDP-H**, **KDP-H → BUFFER:KDP_B**, or leave the starter red and confirm the AI stops. At Kadalur inspect the full rake, try R's refusal, then RESTART SERVICES. F2 selects the WAP-7 light engine; F3 returns to MEMUs. Check that passenger sound moves with the selected coach.
- Next: user feedback on coach proportions/interiors and handling. A locomotive run-round, operating doors, passengers and a full-length scheduled express are separate future work.

## 2026-09-30 — WAP-7 interiors and playable light engine
- Added both driving interiors to **`art/wap7/wap7_30306_full.blend`**, with a separate **`wap7_cab.blend`** and reusable **`assets/models/wap7_cab.glb`**. Built only in background Blender. Real cab imagery was inspected in Chrome; the source and modeling limits are recorded in **`docs/wap7.md`**. No photograph pixels or third-party models were imported.
- Modeled the grey wraparound desk, speed recorder, demand gauges, DDU and switchgear, separate moving handles, padded seats/armrests/pedestals, pedal, ribbed floor, ceiling lining/light, caged fans, window runners/latches, rear cabinet, machine-room door, extinguisher and notices. Corrected buried markings, softened seats, closed lining gaps and cleared side-window views after inspecting Blender renders and actual game captures.
- **F2** or the dispatch board's **DRIVE WAP-7 30306** button switches to a manual light-engine run, starting in Cab 1 at Chennapuram with the route cleared through Maruthur main. F2 returns to the original two eight-car MEMUs. `-- --wap7` starts the WAP-7 directly. Scenario changes restart the working.
- Dedicated rendering places the exterior on the rails, articulates both bogies, rotates six wheelsets and selects the leading headlight. **R** swaps physical driving cabs without turning the locomotive around; wheel rotation remains continuous. Cab windows are cleared and exterior backing panels replaced by the interior lining during cab view. Right-drag can look fully rearward.
- Instruments consume actual simulation speed, power/brake demand, emergency state and AI/manual state. Speed needle and digital display agree over the full marked range; Cab 2 has its own display identity. Auxiliary controls are decorative. This is a driving-cab reconstruction, with a closed machine room and no walk-through machinery interior.
- Pure simulation now carries stock identity and physical cab end. The WAP-7 light-engine profile uses 20.562 m, 108 t, 4.5 MW, a 1.0 m/s² traction cap and 140 km/h maximum; these are gameplay approximations, with the existing route speed limits and protection. Existing sound kernels are scheduled at the six actual Co-Co axle positions; approved TRACK_ONLY / clang +2 dB and graphics settings remain unchanged.
- **80 headless tests pass.** `tools/check_wap7_playable.gd` passes real W/S input, emergency/release, six sound/mesh axle alignments, both cabs, unchanged physical orientation, route buttons, a safe outbound/return trip and switching back to MEMUs. The original `tools/check_dispatch_ui.gd` meet/timetable regression and `tools/check_wap7.gd` exterior check also pass. A separate test confirms the faster light engine stops at Maruthur's uncleared red starter. Only the previously known audio playback shutdown leak warning remains in the scene checks.
- Inspected actual Forward+ game captures of Cab 1, the desk, rear equipment, exterior, driving at 97 km/h, Cab 2 and both scenario selectors; saved under **`art/wap7/game_*.png`**. Blender interior renders are `cab_driver.png`, `cab_overview.png` and `cab_rear.png`. Full master and controls: **`docs/wap7.md`**.
- **Playtest:** start game, press F2; hold W for traction and S through neutral into brake, X to coast, Space for emergency/release at a stand. Right-drag looks around; Tab shows the exterior. Set **MRT-SE1 → KDP-H → BUFFER:KDP_B** via the route desk, stop before the buffers, press R and inspect Cab 2. Set **KDP-S → MRT-HW → MRT-SW1 → CPM-H → BUFFER:CPM_B1** to return. A toggles AI, C selects the next signal's route desk, F2 restores the MEMU meet.
- Next: user feedback on cab proportions, manual handling and visual performance. Passenger coaches, machine-room access and interactive auxiliary/electrical systems remain separate future work.

## 2026-09-30 — Detailed WAP-7 Blender exterior
- Researched real WAP-7 photographs in Chrome and built an original exterior inspired by Lallaguda **30306** in classic ivory/red livery. Front, cab-side and roof references, credits, nominal dimensions and interpretation limits are recorded in **`docs/wap7.md`**.
- Added the background-only `tools/blender/build_wap7.py` builder, editable **`art/wap7/wap7_30306.blend`**, and **`assets/models/wap7.glb`**. The master includes a separately collected studio, display track and five inspection cameras; only locomotive assemblies are exported.
- Detailed cab glazing/guards/wipers, livery and lettering, doors/steps/handrails, lamps/horns/sockets, buffers/couplers/hoses/pilots, six wheelsets, primary/secondary coil springs, dampers, brake/motor/sanding equipment, transformer/reservoirs, pantographs, insulators, roof bus/cables, hatches and grilles. Bogie/pantograph parents and axle origins are independently usable.
- **53 mesh assemblies, 693,756 evaluated triangles, 46 materials**, approximately 18.5 MiB GLB. All materials use backface culling. This is a detailed exterior reconstruction with interpreted fittings, opaque glazing and English side lettering; it does not include a driving interior, animated actions or authored LOD meshes. Godot's importer generates its normal automatic mesh LODs.
- Inspected the master render and five views rendered from the actual GLB round trip; corrected front lettering clearance, refined the cast coupler shape and adjusted inspection cameras. `tools/blender/render_wap7.py` checks export bounds, six wheelsets and materials. Godot successfully imported the final file; `tools/check_wap7.gd` verifies **53 meshes, 6 wheelsets, correct axle heights/spacings and no failures**. **74 headless tests pass**.
- No gameplay, simulation, sound or project graphics settings changed. The WAP-7 is an available asset, not yet assigned to a service. This supersedes the earlier plan to obtain a Sketchfab WAP-7.
- Inspect: open the `.blend`, Numpad 0 for the hero camera, or orbit in Material Preview. Review `hero_glb.png`, `front_glb.png`, `bogie_glb.png`, `roof_glb.png` and `side_glb.png` under `art/wap7/`. Expand the locomotive collection to select individual assemblies. Full rebuild/inspection commands are in `docs/wap7.md`.
- Next: user feedback on the WAP-7 shape and detailing; a dedicated driving cab, LHB coaches and express-service integration remain separate future work.

## 2026-09-30 — Timetabled AI and 24-hour world clock
- Added an independent 24-hour simulation clock with day counter; absolute timestamps keep overnight services ordered across midnight. Pause and time acceleration use the existing simulation clock. HUD, dispatcher and event log show world times.
- Added validated per-train timetables: scheduled origin departure/day, block IDs, direction, minutes from origin, dwell and optional stopping coordinate. Invalid assignment preserves the existing timetable. Arrival offsets remain anchored to the booked origin time when trains run late.
- AI waits for departure time and a dispatcher-set route, serves every block stop even under clear signals, waits for the booked intermediate departure and full actual dwell, then continues only with authority. Wrong-platform routes hold the train at the entrance for correction. Terminal arrival completes the service without restarting it at midnight.
- Manual/AI handoff preserves timetable progress. Manual arrivals/departures are recorded when stops are served; unfinished workings cannot change ends. Completed services can reverse for an unscheduled return.
- Default schedules now load from `sim/timetables/first_line.json`: world D1 08:00, T1 departs 08:01 via `mrt_loop`, T2 08:02 via `mrt_main`; Maruthur +4 min with 1 min dwell, final stop +8 min.
- Added **M / TIMETABLE** to the dispatcher: selected service, stop/block, origin offset, planned arrival/departure, dwell, actual times, early/late/held status and overnight day suffix. Route controls remain available beside the timetable.
- **74 headless tests pass** (15 timetable/clock cases), plus the expanded full-scene integration check covering timetable selection/cells, no early departure under green, two-service completion, actual arrivals and midnight display. Graphical captures inspected the timetable at startup, Maruthur and completion at 1600×900. Full meet had no safety events. Godot MCP launch reports zero errors; the known six audio playback shutdown leaks remain in the headless scene check.
- Playtest: **`docs/dispatching.md`** for routes, **`docs/timetables.md`** for format and overnight example. Set origin routes early and check 08:01/08:02 departures; set onward routes before dwell ends and check 08:06/08:07 releases; hold a train late and check full dwell plus fixed booked times. Check **M**, **Tab/A**, **Esc**, **T** and midnight rollover.
- Next: user playtest of timetable pacing, handling, graphics and audio. Daily recurrence, an in-game schedule editor, scoring, save/load and additional layouts remain future work. Finished scene launched through Godot MCP for playtesting.

## 2026-09-30 — Station passing, dispatcher and visual upgrade
- Explicit entrance-to-exit route enumeration and atomic setting; occupied blocks and shared switch conflicts refused. Signal aspects require a set, clear route; routes retain an owner after signal passage.
- Cancellation holds approach locks; points release after the owning train's tail clears the fouling zone independently of occupied berth release. Maruthur starters moved inside the loop clearance points.
- Production automatic driving brakes for signals, buffers and lower speed limits. Two opposing eight-car MEMU services are available through `FirstLine.build_dispatch()`; drivers never set routes themselves.
- Hard occupied-block boundary safeguard also applies with driver protection disabled. Long simulation steps are subdivided.
- Delivered a live schematic and route desk with entrance/exit selection, automatic point alignment, reservation/occupancy colours, refusal reasons, safe cancellation, service roster, AI/manual handoff, pause and scenario completion/restart.
- Default game now starts the two-service Maruthur meet. Both MEMUs use the existing exterior and new detailed cab, as confirmed by the user. Selecting either train switches view/audio; Tab takes its cab, A hands control back to AI, C opens the route desk rather than clearing directly.
- Graphics: world-texture mipmaps were previously disabled (causing distant shimmer/noise); enabled all 19 PBR/HDRI mip chains. Added station furniture, passengers, footbridge, street/village scenery, grass blades, revised foliage and flooded-field water; improved camera composition, lighting and label visibility. MEMUs have destination boards and headlights. 8× MSAA/high SSIL configured through the live Godot MCP; no performance-driven reductions.
- **59 headless tests pass**, plus `tools/check_dispatch_ui.gd` full-scene integration: route buttons, selected cab/audio, cancellation, opposing meet, both terminal arrivals/completion, imported mipmaps. Graphical captures inspected overview, detailed cab and both trains at Maruthur; no runtime errors or safety events in that meet. Godot may still report the pre-existing audio playback shutdown leaks (now six for two trains).
- Moved Chennapuram's turnout beyond the straight platform roads and checked the full-width train envelope against its island platform. Turnout clearance is a TrackGraph switch parameter, so other station loops can use the same interlocking without station-name rules.
- Playtest guide and exact eight-route sequence: **`docs/dispatching.md`**. Set T1 through MRT-SE2 (loop), T2 through MRT-SW1 (main), then dispatch both onward after approach blocks clear. Check refused opposing routes, tail clearance, C route desk, Tab/A handoff, pause and completion/restart.
- Next: user playtest of handling, visual quality and two-train audio balance. Recurring timetable, scoring, save/load and additional layouts remain future work. Blocks currently use conservative edge sections; turnout clearance distances are specific to this layout.
- Launched the finished main scene through Godot MCP for playtesting. Removed three editor-only numeric/material type warnings caught on that launch.

## 2026-09-30 — Detailed MEMU driving interior
- User prioritised a more realistic interior. Replaced the box cab with an original Blender-built MEMU-inspired interior: formed green desk, analogue gauges, engraved controls, seats, fans, window hardware, wipers, headliner, footwell, radio, clipboard and rear equipment.
- `tools/blender/build_cab.py` exports `assets/models/memu_cab.glb`; `render_cab.py` checks the exported GLB. Roughness tile is original, embedded and extracted by Godot. Asset registration and build/verification notes are in `docs/cab-interior.md`.
- `game/cab_view.gd` reads simulation state: speed, power/brake demand, controller position and four annunciators. Other cab fixtures are decorative. Simulation and approved audio are unchanged.
- Wider seated view, mouse-wheel cab zoom and increased head-turn range. Large HUD speed label hides inside the cab; F correctly restores exterior visuals/audio.
- Compared old/new cabins at the same in-game camera and inspected four Blender views. Fixed gaps, buried labels, wiper joints and legroom. All 43 headless tests pass, including 2 exported-cab/state tests.
- Live playtest: C/W departure at 53% power and about 12 km/h; needle, controller and POWER lamp responded. Space emergency stopped the train and activated the brake indicators. Released, reversed with R, checked F hides the cab, and checked cab zoom.
- Chrome research remains blocked in this chat by saved site permissions. User authorised continuing development; this is an original interpretation, not a verified replica. Global graphics settings and exterior MEMU are unchanged.
- Playtest: Tab into cab, F1 hide help, right-drag to inspect, wheel zoom; C/W depart, X coast, S service brake, Space emergency/release at a stand, R change ends. Check visibility on the TV. Full details: `docs/cab-interior.md`.
- Next: user visual feedback; passenger interiors and the exterior art pass remain future work.

## 2026-09-30 — First playtest on this PC
- Launched and visually inspected overview and cab. Eight-car MEMU renders; existing overlapping signal labels remain.
- Exercised physical-key input through the MCP runtime: C clears starter, W accelerates (observed 52 km/h), Tab enters cab, X coasts, Space emergency brake brings speed to zero. Released brake and returned to overview afterward.
- Observed 4–5 FPS at 1600×900, Forward+, AMD Radeon 780M, including with the game focused. **User explicitly said not to worry about performance; leave graphics settings alone.**
- Standalone game stderr stayed empty. Audio quality was not assessed; service braking and a full end-to-end route/SPAD playtest remain untested.
- Normal launch lacks a connected MCPRuntime. Used ignored `.local/playtest.gd` to add the existing runtime helper for this run only; no gameplay/project settings changed. Native automated key taps did not affect the physical-key controls, but MCP replay did.
- Left the standalone game open, stopped. Next: resume the user's chosen gameplay work or audio playtesting. Existing approved sound settings remain unchanged.

## 2026-09-30 — Continue on this PC with Codex
- Installed portable Godot 4.7.2, Blender 5.2.1 LTS, and Godot MCP bridge 1.2.1 under ignored `.local/`.
  Verified official download checksums. Existing Node 24.15.0 and Git reused.
- Registered project-local Codex MCP config; corrected Claude MCP's E: path to D:.
- Added `AGENTS.md`, `docs/pc-setup.md`, and `tools/godot.ps1` for future sessions.
- MEMU builder now resolves its project directory relative to the script instead of hard-coding E:.
- Godot imports successfully; **41 tests pass**. Blender background startup and script syntax verified.
- MCP handshake/tool listing and live editor connection diagnostic passed (healthy, matching addon 1.2.1).
- Sound lab is present as a sibling directory. No sound or gameplay changes.
- Next: restart Codex to load the MCP config, open Godot via `tools/godot.ps1 editor`, and resume the existing sound playtest / planned features.

## 2026-09-28 — Physical (wheel-position) model of the approved take — JS in the lab first
- Finding: the approved take = a fixed point on the track while an **ICF rake at ~66 km/h** rolls over a joint
  (lead bogie clang-clang, long gap, trail bogie, then next coach's lead bogie across the coupling). Time ratios
  match ICF geometry (22.297 / 14.783 / 2.896 m) to 3 digits; independent speed fit 66.01 km/h, all hits ±5 ms.
  → game cab engine (`calibrated_bed.gd`) REFERENCE_SPEED 55 → **66** (user approved). Lab files untouched.
- New lab files (not modifying existing ones): `src/physical-geometry.js`, `src/physical-analysis.js`,
  `src/physical-model.js` (magnitude-domain NMF with fixed geometry events → 4 axle-class kernels via the lab's
  phase reconstruction), `src/physical.js` (`AxleJointSynth`: every axle over every joint, fixed or onboard
  listener, distance fade, per-wheel rolling noise), `src/physical-calibrate.js`, `tools/physical-*.js`,
  model `profiles/physical-icf.json`.
- vs the take (trackside, 66 km/h): level +0.15 dB, 1/3-oct tonal balance 0.76 / 0.37 dB (mid/side), envelope
  correlation 0.85. Gap to "perfect": one averaged kernel per axle class; each real hit has its own spectrum.
- Demos in the lab's `exports/` (A/B, onboard MEMU 66/100 km/h, onboard ICF). User: "AB is good" → **ported**.
- Game port: `game/axle_joint.gd` (scheduler, tested), `game/train_audio.gd` (hits via AudioStreamPolyphonic with
  late-start compensation inside the 17 ms kernel lead; per-wheel rolling loop), data exported by the lab's
  `tools/physical-export-godot.js`. Listener = driver in the cab, camera in the overview (blended on Tab).
  The WSOLA cab engine and procedural clacks were removed (in git history). 36 tests pass, 60 FPS at ×4.

- Feedback round 1: "too low in cab and when following; leading cab bogie only 'cling', no 'clang'".
  Cause: the take's lead-bogie kernels are 9–13 dB quieter than the trail bogie's (microphone position in the
  recording), and the cab sits over the lead bogie; overview used the camera (up to 260 m away) as listener.
  Fix: per-class loudness equalised in the export (`CLASS_GAIN`, +10.8/+12.0/0/+7.6 dB) so distance decides;
  overview listener = camera focus, 6 m beside the track, gentle zoom fade; default level up; hard limiter on
  the Train bus; `[` / `]` adjust track sound in 2 dB steps (toast shows the level — tell Claude the number).

- Round 2 (user's model): **one bogie = cling (1st wheel over the joint) + clang (2nd wheel)**, applied to both
  bogies of every car → a car over a joint = cling-clang ......... cling-clang. Refit in the lab with 2 pooled
  templates (1st/2nd wheel of any bogie): 1st is brighter (centroid 747 Hz), 2nd heavier (697 Hz, more <200 Hz);
  per-hit gains now 0.8–1.34 (were 0.11–2.27). The take's per-position loudness (0.19/1.57/1.81/0.56) is kept
  only for reproducing the take (`groupGain`, `takePerspective`), not in the game. Take reproduction: level
  0.0 dB, tonal 0.49/0.35 dB, envelope 0.85. The take can't fix clang-vs-cling level → default clang +4 dB,
  `,` / `.` adjust live. **User tuned: clang +2 dB → default.** Game: `physical_icf_wheel1/2.wav`, `WHEEL_GAIN`.
  Back to the full 8-car formation. TRACK_ONLY still on (whine/hum/squeal/hiss/horn off) until the user says.

### Playtest (sound v4 — physical)
1. Cab at ~66 km/h: close to the take? The rhythm is now your own MEMU's axles over 13 m joints (not the ICF
   coach pattern), since you sit in the train. Overview close to the track: coaches passing = the take's pattern.
2. Speed: slow pull-away vs 100 km/h — rhythm, loudness, rolling noise.
3. Anything that sounds mechanical/repetitive (4 kernels cycling recorded loudness).

## 2026-09-28 — Track sound from the user's Railway Sound Lab
- Source: `E:\ClaudeWS\railway-clang-simulator` (user's own Node.js lab; README explains both engines).
- **Cab:** `game/calibrated_bed.gd` = GDScript port of `src/calibrated.js` (stereo WSOLA of the approved
  5 s synthetic take, rhythm ∝ speed/55, pitch constant). Runs at 22.05 kHz, ~6% of one core.
- **Outside:** `game/rail_sounds.gd` = `src/synth.js` impact model with the 24 measured modes + 68 Hz body mode,
  randomized contact pressure, flam 4–7 ms later, contact noise; pre-rendered (4 variants × 2 bogies, ~1 s at
  startup) and fired per axle per rail joint with synth.js's speed gain and per-joint irregularity.
  synth.js's rolling bed (noise + sleeper pulse) is synthesized live.
- Cab ⇄ outside crossfade on Tab; "Train" bus reverb (+ cab low-pass). Eurostar loop no longer used.
- `tools/audio/render_clack_demo.gd` renders the outside clacks to a WAV for auditioning.
- Calibrated WAV must import uncompressed (`compress/mode=0`), a test checks it. 34 tests pass.

### Playtest (sound v3)
1. Cab (Tab): does it sound like your lab's calibrated simulator at the same speed? (55 km/h = the approved take)
2. Overview: clack rhythm and metal tone vs your lab's studio model.
3. Balance between track sound, motor whine, hum — any layer too loud/quiet?

## 2026-09-27 — Train sound
- `game/train_audio.gd`, attached over the leading bogie (3D, so quieter from the overview camera):
  - rolling: CC0 BigSoundBank interior loop, volume + pitch follow speed;
  - synthesized live: 3-phase traction whine (pitch ∝ speed, loudness ∝ power/brake handle), low-speed PWM
    whistle, transformer hum, flange squeal on curves (from `RailWorld.curvature_at`), air-brake hiss;
  - rail-joint clacks timed from `Train.odometer` as each nearby axle crosses a joint (13 m rails);
  - horn on **H**.
- 7 CC0 sounds downloaded (horns, pass-by, station, door beeps, 2 interiors); 3 not yet used.
- Test runner fix: failures (String results) used to crash the runner in Godot 4.7.

### Playtest (sound)
1. Pull away with W: does the whine rise with speed and fade when you coast (X)? Clacks speed up?
2. Brake (S) — hiss; emergency (Space) — big air dump. Horn (H).
3. Tight curves at speed (Maruthur loop, Chennapuram platform 2): squeal?
4. Tell me what's too loud / too quiet / annoying — levels are easy to tune in `train_audio.gd`.

### Planned: WAP-7 express as a second train
- Model: Sketchfab "WAP 7 Indian Locomotive Low Poly model" (knitro_vedant, CC BY) or its "New Design" version —
  the user downloads it (Sketchfab needs a login; glTF format into `assets/`). Credit the author in docs/assets.md.
- Coaches: build LHB coaches in Blender (tools/blender/) in the MEMU's style.
- Indian loco horn: Freesound pack "Indian Railway" by sama66 (login needed; user downloads).
- Game is offline personal use only (see memory) — personal-use / CC BY assets are fine.

## 2026-09-27 — Graphics upgrade (semi-realistic)
- CC0 Poly Haven PBR textures + clear-sky HDRI, Quaternius palm (see `docs/assets.md`).
- Lighting: HDRI ambient, AgX, SSAO, SSIL, glow, aerial fog, 4-split soft shadows, 8K shadow map, FXAA + MSAA.
- World: terrain mesh with hills; grass/laterite ground shader; soil shoulders; textured ballast, steel rails,
  concrete sleepers; 25 kV OHE masts + wires; Mangalore-tile roofs; paddy fields with bunds; palm clumps.
- Train: new MEMU model from `tools/blender/build_memu.py` (background Blender → `assets/models/memu.glb`):
  cab/trailer/motor cars, livery, windows, doors, bogies, pantographs, head/tail lamps; simple cab interior.

### Playtest (graphics)
1. Overview and cab: does it look "modern" enough? Anything that looks wrong or cheap?
2. Cab view: is the windscreen framing / eye height comfortable? (right-drag to look around)
3. Frame rate — is it smooth on your machine? (RTX 4090 laptop; if not, SSIL/shadows are the first to cut)
4. Ideas still open: grass tufts near the track, station details (people, lights, signage), textured train livery.

## 2026-09-27 — Phase 1 first playable
**Sim (`sim/`, 26 headless tests):**
- `TrackGraph`: nodes / polyline edges / 3-way switches; facing + trailing moves; "trailing against" detection.
- `Train`: EMU-style combined power/brake handle, traction/power limits, running resistance, emergency brake,
  path tracking (head + occupied edges), change ends at a stand.
- `RailWorld`: 3-aspect signals protecting blocks up to the next signal; route locking with sectional release
  (switches locked, conflicting/opposing routes refused); signals return to red behind a train; SPAD detection
  with optional train protection (emergency brake); run-through of a trailing switch set against (warning);
  buffer-stop hit warning.
- Layout `first_line.gd`: Chennapuram (2-platform terminus) — 1.5 km — Maruthur (passing loop) — 1.3 km —
  Kadalur (terminus). 8-car MEMU (~175 m). 11 signals, 3 switches.

**Game (`game/`, main scene `game/main.tscn`):** procedural low-poly world (ballast/rails/sleepers, palms, paddy
fields, hills, stations with yellow name boards), MEMU model, signals with lit lamps, clickable signals/switches,
overview camera + cab camera with a smooth blend, HUD (speed, limit, handle, next signal + aspect, events).

**Known limits:** no train-to-train collision (only one train yet); no look-ahead for speed limits; overspeed only
warns; signal labels overlap near Chennapuram junction; route edges ahead that a train never reaches stay locked
(e.g. if it reverses before using the whole route) — put the signal back doesn't free them yet.

### Playtest checklist (run from the editor with F5, or the Run button)
1. Start: overview of Chennapuram. Press **C** (clear CPM-S1), hold **W** to ~50%, depart. Does acceleration feel right?
2. Press **Tab** to jump into the cab and back. Is the fly-in smooth? Is the cab view usable?
3. On the way, MRT-HE is red. Try stopping before it with **S** (brake). Then press **C** to clear it.
4. Before that: in overview (Tab), click switch **MRT_1** to route into the loop (marker turns orange, shows R).
   Try throwing a switch that's under a cleared route — it should refuse with a message.
5. Pass a red signal on purpose: protection should stop you (SPAD message). **Space** releases once stopped. **P** turns protection off.
6. Run into Kadalur, stop at the buffers, press **R** to change ends, drive back.
7. **T** speeds up time (×2/×4). **1/2/3** jump the camera to stations. **F** follows the train again.
8. Report: anything that feels wrong (controls, speeds, braking, camera), visual glitches, confusing HUD text.

## 2026-09-27 — PC setup
- Installed Node 24 LTS, Claude Code CLI 2.1.268, Godot 4.7.2, Blender 5.2.1, GitHub CLI.
- Engine decided: **Godot 4.x**. Godot MCP bridge + Blender connector both verified live.

## Decisions (brief §7)
Godot · South India, present-day Indian Railways (era assumed) · simple 3-aspect colour-light ·
middle-ground tone · both 2D schematic + 3D overview · small fictional first layout.

## Next
- Playtest the two-train Maruthur meet using `docs/dispatching.md`, including manual handoff and audio balance.
- Build on the dispatcher with recurring timetables, delay/scoring, save/load and further layouts after feedback.
- Visual feedback on stations/scenery and the MEMU cab/exterior; approved sound synthesis stays sourced from the sibling lab.
