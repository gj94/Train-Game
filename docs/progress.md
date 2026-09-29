# Progress

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
