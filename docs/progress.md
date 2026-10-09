# Progress

## 2026-10-09 — Incremental LAN updater
- Added a small native Windows Update & Play launcher for existing portable
  installations, with an editable LAN address, progress and offline Play.
  It compares 64 KiB hashes, downloads changed ranges, and patches only those
  ranges in place. Unchanged PCK/assets/EXE bytes are retained. Saves, preferences
  and extra user files are untouched. No additional runtime install or admin.
- RSA-signed catalogues, verified blocks and final file hashes, exclusive game
  file locks, a per-installation lock, bounded paths and downgrade rejection.
  All changed blocks are durably staged before a signed pending plan is flushed;
  an interrupted apply resumes forward, including offline from its local cache.
  Download failures leave existing game bytes intact. Cache is removed only after
  verified completion; Play is blocked during an unfinished apply.
- R17 → R18 comparison across the actual 177 exported files: 17,187,465 bytes
  changed, including 17,148,488 in the PCK. With its 2,811,117-byte catalogue,
  roughly 20 MB download and 40 MB logical writes (staging/apply/state), versus
  1.68 GB ZIP download and approximately 3.71 GB ZIP-plus-extraction writes.
  Actual SSD write amplification is not measured; savings depend on the release.
- LAN server exposes only published manifest-listed resources, with existing
  byte ranges and subnet restrictions. Published release names are immutable.
  build-windows.ps1 now supports increasing UpdateSequence and SkipZip for future
  releases. Signing private key stays in ignored .local; pinned public key is
  committed. See docs/incremental-updates.md for release and recovery procedures.
- All 383 headless game tests pass. Nineteen native updater fixture groups pass,
  covering changed/no-op writes, interruption at six phases, offline recovery,
  corruption, dropped requests, bad ranges, running-game locks, signature/path/
  downgrade rejection, growth/shrink and server whitelisting. Live LAN catalogue,
  PCK range hash, updater download and invalid-path checks pass. Actual launcher
  against R18 returns zero downloaded game bytes and zero game writes. No game
  distribution launch or re-extraction.
- Player check: close the game, extract the tiny TrainGame-Updater.zip beside
  the current TrainGame.exe/PCK and open Update and Play.exe. Use Update & Play
  for future builds; use Play installed when the host is asleep. Reopen this
  launcher after interruption; do not directly start the game during a pending
  apply or delete .train-update. Latest game remains R18.
- Published TrainGame-Updater.zip at the existing LAN page: 15,323 bytes,
  SHA-256 `a8835a87d8a28c266ced5c19f42f592cfde7da65a6e635741103a60cfedad12b`.
  Verified the downloaded launcher ZIP against its sidecar. The GUI also lets
  players choose their existing game folder and defaults to declining a full
  installation if the selected folder lacks its EXE or PCK.

## 2026-10-09 — R18 controller camera flow
- Fresh starts use pilot view. From pilot the first D-pad press selects the
  matching head-out: right for right, left for left. The full reversible cycle
  retains cab positions, passenger presets and exterior views. Up/down walks
  the viewpoint through every passenger coach in driving-end order, with pilot
  and tail limits instead of wrapping. Applies in both layouts and on foot.
- LS in the cab enters collision-aware cabin walking instead of changing zoom;
  L3 returns to the pilot. Driver assignment, AI and power/brake remain set.
  X + D-pad Up now controls the walking headlamp; change-ends remains in Actions.
- R3 starts a detached camera on the nearest open station's usable platform,
  1.65 m above its surface, looking along the platform beside the train. Native
  ERS rendering caught an initial locomotive-side close-up; moved the spectator
  farther back on the platform and angled the view along it. Repeated short
  presses preserve the current free position. RS turns at the eye; LS moves.
- Free-camera RT/LT control optical zoom by default; RB/LB raise/lower it.
  Holding R3 for 0.65 s toggles driving triggers, once per hold. Explicit free
  input context, neutral gating and function hints prevent held zoom/run inputs
  becoming train controls on a viewpoint change, resume or toggle.
- New optional save fields restore the free viewpoint and lens. R14-R17 saves
  supply the older orbit defaults; source integration checks restore both forms.
- All 383 headless tests pass. Native event-driven camera/navigation checks pass
  in both layouts on all four formations, including carriage limits, actual cab
  translation, trigger switching and save compatibility. Final complete camera
  cycle: 112 checks; controller/menu/dispatch integration: 72 checks, no failures.
  Source-game ERS free-platform rendering reviewed at 1280×720; scenery loads and
  the eye remains on the platform. The headless sandbox retains its existing
  certificate-store warning. No extracted-distribution test.
- Playtest: from pilot press Right then L3 then Left; use Down repeatedly through
  the rake and Up to pilot. Move LS inside the cab and return with L3. Press R3,
  check the platform viewpoint, zoom using triggers, then hold R3 and release all
  controls before trying driving triggers. Switch back, return to pilot with a
  zoom trigger held and confirm the handle stays set. Save/load a free viewpoint.
  See `docs/controllers.md` for both layouts and the updated headlamp binding.
- Published `TrainGame-Kerala-Coast-R18-Windows.zip` from clean source `5386b42`:
  1,684,814,266 bytes; SHA-256
  `8c5fcfcdc7861337962b6d0dde144d408891f9a75e5e4ff91f6574b4eac484f5`.
  R18 is latest at `http://192.168.8.183:8765/`; verified catalogue, HEAD size,
  HTTP 206 ZIP range, checksum sidecar, README and controller guide. Source and
  publication record pushed to `origin/codex/port-indian-rail-assets`.

## 2026-10-09 — R17 free-camera audio receiver
- Fixed exterior track sound listening beside the camera's orbit pivot instead
  of its actual eye. Rolling, joint impacts and squeal now use the same physical
  viewpoint as native traction/horns. Geographic absolute coordinates survive
  rebasing; platform walking stays exterior. Website reference mode and explicit
  receiver overrides retain their intended behavior.
- Removed the unused nearest-joint graph search from gameplay exterior audio.
  Approved sound banks, gain/pitch laws, speed response and contact timing remain
  unchanged. No simulation, scenery or save-format changes.
- Added six receiver regressions plus native PCM near/far, pivot-only movement,
  origin rebase, nearby impact allocation/output and pause checks. In the failing
  baseline fixture moving from 200 m to 5 m barely changed rolling RMS
  (0.000374 to 0.000364); after the fix it rose from 0.001116 to 0.048562.
  These are captured test levels, not a global volume increase or calibrated SPL.
- Test suites start after SceneTree initialization so real camera fixtures have
  a valid viewport. Updated the old passenger-menu integration expectation to
  include the existing any-coach entry beside its three presets and Back.
- All 378 headless tests pass. Native free-camera PCM, filter routing and full
  enhanced-audio/passenger-view integration checks pass. The sandbox retains
  its existing certificate-store warning; there are no script or test failures
  in the completed checks. No packaged-game launch or extraction.
- Playtest: R3 selects free exterior. Approach a moving train's bogies, then
  move away; wheel noise and impacts should follow distance. Try a nearby AI
  service while retaining your driving assignment. L3 returns to pilot; cycle
  to passenger to compare the existing interior mix. Existing R14-R16 saves work.
  See `docs/enhanced-audio.md` for checks and reproduction steps.
- Published `TrainGame-Kerala-Coast-R17-Windows.zip` from clean source `8efaf41`:
  1,684,802,418 bytes; SHA-256
  `851636d2b1be45f950fcff1b99dbc5aba17dd20f4f57bbfdad476fd8aa4afd1b`.
  R17 is the sole latest entry at `http://192.168.8.183:8765/`. Verified HTTP
  HEAD size, byte-range ZIP download, checksum sidecar, README and audio guide.
  Existing builds remain fallbacks. Source pushed to
  `origin/codex/port-indian-rail-assets`; no distribution launch or extraction.

## 2026-10-09 — R16 coastal graphics
- Connected the detailed scenery kit to suitable mapped building footprints;
  preserved irregular, skewed and incompatible-height mapped envelopes. Door and
  storey heights stay unscaled. New original Kerala bungalow: 5,824 triangles,
  recessed windows, veranda, columns, steps and roof fittings; background Blender
  source and measured bounds retained. Filled bases support exposed verandas.
- Added terrain variation at multiple scales, grass/laterite normal blending,
  dusty roads/shoulders, young palms/scanned small trees/shrubs and more near-track
  weed patches. Spatial occupancy checks keep planting off mapped roads and houses;
  station and railway clearances remain. Planting uses rendered terrain heights.
- Refined simple house roof ridges/window frames, platform paving, canopy weathering,
  and station forecourt planters/kerbs/bollards/parking. More neutral daylight and
  no artificial bloom. Simulation, sounds, station layouts and save schema unchanged.
- Native source captures reviewed for pilot, passenger, Kumbalam exterior,
  close station and neighbourhood. Same-view mean frame times on Radeon 780M:
  42.54→43.92 ms pilot, 44.14→44.63 passenger, 33.88→35.96 exterior (about 1–6%
  cost). Same quality settings/1280×720/seed; short samples, not RTX 4090 results.
  Reduced the initial heavy foliage mix after profiling. Fixed a stale-origin test
  camera and exposed grass beneath building bases found during visual review.
- Scenery audit passes for 51 original GLBs plus registered CC0 asset hashes.
  Native comparison/measurements: `art/scenery/coastal-fidelity/index.html`.
  All 372 headless tests pass, including eight footprint/occupancy regressions.
  The sandbox emits its existing root-certificate-store warning after the passing
  suite; no script/test failures. No extracted-distribution test.
- Playtest: load a coastal save, inspect cab/passenger views, visit Kumbalam in
  Dispatch without handing over your service, and use external free camera to
  inspect frontage/paving, nearby verandas/roof detail and road/rail planting clearance.
  See `docs/visual-fidelity.md` for the comparison, limits and exact method.
- Published `TrainGame-Kerala-Coast-R16-Windows.zip` from clean source `724b2df`:
  1,684,798,540 bytes; SHA-256
  `6cf116551a29dc4a30517aa0e3cf01746b353a83debd4bbb6de42d8ed5577ad7`.
  LAN server restarted at `http://192.168.8.183:8765/`; R16 is the sole latest
  entry, earlier builds remain fallbacks. Verified HEAD size, byte-range ZIP
  download, checksum, README, graphics guide and comparison HTML/eight PNGs.
  Preview: `/kerala-r16/preview/index.html`. Source and release record pushed to
  `origin/codex/port-indian-rail-assets`. No packaged-game launch or extraction.

## 2026-10-09 — R15 coastal station architecture
- Pinned the newly published coastal collection at `089dbecca1d6209cc8dd35a2b431f4ec4063a490`.
  Downloaded/verified all 53 Blender masters, including split-file hashes, and
  evaluated them in background Blender with source script execution disabled.
  Added 51 active station building/interior assemblies and Viranialur's original
  open shelters; retained historical Tirunettur separately without an active stop.
- Preserved 1,394,944 active-source triangles and 3,849 exported objects in 137
  spatial batches. Original dimensions, bevels, roof geometry, furnished rooms,
  signs, packed image pixels and normals remain; source material graphs are
  translated to realtime shaders, now including brick patterns. Godot distance
  LODs and separate shadow meshes keep full nearby visible geometry.
- Added rigid placement at outer platforms and floor-level alignment. Foundations
  support southern plinths/verandas/annexes; Viranialur gets an outer apron for
  its full-width shelters. Source PNPR/TVCS map to existing PUPR/NEM IDs. No
  operational graph, platform inventory, dispatch state or save schema changes.
- Native route review caught generic mapped houses and trees overlapping the
  new models. Added an immutable spatial footprint index shared by workers to
  exclude these, prevent road surfaces through buildings and lower terrain that
  would bury the new plinths. Surrounding scenery remains streamed.
- Source geometry/material/placement check: 262 checks passed across all 52 active
  models, including exact triangle counts, shader overrides, rigid transforms
  and building/track clearance. All 53 exported geometry buffers pass SHA-256.
  Native streamed Kumbalam, Turavur, Kollam, Neyyattinkara and Viranialur each load
  one authored assembly without script/shader errors; screenshots were reviewed.
- All 364 headless tests pass, including four new scenery-footprint regressions.
  Native previews use the source project; no extracted-distribution test.
- Source commit `a4d7577` is pushed. R15 exported from that clean revision and
  is latest at `http://192.168.8.183:8765/`: 1,677,002,421 bytes; SHA-256
  `2e70adb15f6e847251ae2b3ee254804c6d32a43d0b1a4dab1c2c749933f274c4`.
  LAN catalogue, exact ZIP size, HTTP 206 range, checksum sidecar, README and
  station-port guide verified. R14 remains available as a fallback.
- Scope and reproduction steps: `station-model-port.md`. This imports architecture,
  interiors and attached access, not static source yards or station-room walking
  navigation. CSV platforms, live track/signals/OHE and most platform furnishings
  remain game-generated. Notices/reference notes/fonts accompany the assets.
- Playtest: visit Kumbalam and Turavur using the dispatch station visitor, then
  Kollam and Neyyattinkara. Use external free camera for entrances, platform sides,
  interiors and raised-floor bases; check there are no generic houses/trees inside
  the buildings or forecourt. At Viranialur check the original open shelters.
  Load an R14 save and confirm the assigned service and timetable resume paused.

## 2026-10-09 — R14 Save/Load journeys
- Added a versioned, renderer-independent railway checkpoint: occupied train
  paths/physics/controls, timetables and completed passenger results, passengers
  mid-exchange, points and signal authority, dispatch wait ages/commitments,
  future-platform reservations, operator choices, deleted services and depots.
  Restoring builds a separate world and verifies the track, platform, depot and
  signalling signature before replacing the live session.
- Added five manual slots and a separate quick save to the pause menu, with
  complete Xbox focus/back navigation. Ctrl+S quick-saves; Ctrl+L opens Load.
  Entries show service/time/progress/timestamp. Load and manual overwrite
  default to Cancel; each overwrite preserves the previous backup. Verified
  temporary writes and checksums reject damaged files without replacing a run.
  Open saves folder supports copying checkpoints between compatible PCs/builds.
- Loads resume paused, retaining the assigned service, custom service pack,
  AI/manual driving, power/brake, fast-forward multiplier, passenger/head-out/free
  camera, onboard/platform walking position and dispatch map. Existing authority
  is not reinitialized on scene construction. Inputs are neutralized and audio
  voices are rebuilt. Fixed startup selection to allow saves after handing over
  and deleting the original assigned train. No autosave or format migration.
- All 360 headless tests pass, including 12 new checkpoint/file regressions for
  exact continuation, overtake/future-clearance state, passenger exchange, depot
  results, topology compatibility, backup rotation and corruption rejection.
  Source integration checks pass: 27 Kerala checks including platform restoration,
  22 handover/deletion checks, 21 native menu/view checks and 72 controller checks.
  Native Save/Load screenshots were inspected; slot summaries wrap and scroll.
  No extracted-distribution test. See save-load.md for scope and file locations.
- Feature commit `18111a2` is pushed. R14 Windows was exported from that clean
  revision: 1,631,421,588 bytes; SHA-256
  `8730452a888e20dd5379da0833b98ec64ddd7edbdafd4e78eaf4d213e6a40192`.
  Published as latest at `http://192.168.8.183:8765/`; the host verified the
  catalogue, exact ZIP size, HTTP 206 range, checksum sidecar, README and saved
  journeys guide. R13 remains available as a fallback.
- Playtest: save while moving, continue, load and compare clock/speed/handle and
  nearby services before Resume. Save during an overtake wait or boarding, and
  while walking in a coach/on a platform. Overwrite a numbered slot, restore its
  previous backup, and cancel a load to check the current run remains intact.

## 2026-10-09 — R13 Turavur overtake departure order
- Recreated the reported three-train arrangement at Turavur around 09:30 with
  the passenger in a platform loop, VB on the central through road and an
  opposing ICF entering the other platform. This is a controlled reproduction,
  not a recovered save of the user's manual run.
- Found and reproduced the wrong order: the overtake timeout counted all prior
  signal waiting, then the local's waiting-age priority exceeded the VB's.
  Overtake plans now time their own age. Once the express arrives alongside,
  a routine crossing delay preserves its departure order until it passes.
  Unavailable expresses and circular dependencies can still be replanned;
  existing signal, route and tail locks remain authoritative.
- Verification: 348 headless tests pass, including eight new regressions for
  both directions, prior waiting, manual driving, tail clearance, unavailable
  expresses and existing authority. A moving three-train reproduction passes
  with no safety events: opposing ICF fully inside at 09:31:58, VB starter
  clears at 09:32:20, passenger starter clears at 09:33:48. These fixture times
  illustrate departure order, not promised timings for every manual run.
  No new full-timetable or extracted-distribution run for this focused fix.
- Source fix `78e144c` is committed and pushed. R13 Windows was exported from
  that clean revision: 1,631,391,426 bytes; SHA-256
  `f717b1a29897c25eeaee7ce4b5c0228d876eff66070ac15b0b5b9f05c8f26a2a`.
  Published as latest on `http://192.168.8.183:8765/`; catalogue, exact ZIP size,
  HTTP 206 byte range, checksum sidecar, README and dispatcher guide verified
  from the host. R12 remains a fallback.
- Playtest: start a fresh stopping scenario; after a long crossing/overtake
  wait with the VB alongside, let the opposing train enter. The VB should
  depart first, followed by your passenger after its route clears. Inspect
  the dispatch decision log if an operator hold or emergency changes that plan.

## 2026-10-09 — R12 travelling passengers and fullscreen
- Added independent passenger journeys, actual model seat capacities and
  destination-bound boarding/alighting to scheduled ICF, LHB and VB services.
  Demand favours local trips with some through passengers; there is no real-world
  ridership claim. Free-drive trains carry seated riders without automatic stops.
  Exchanges require a booked stop at a stand with the full rake in a passenger
  platform. Alight before boarding, two door queues per coach, capacity-limited
  seats and conservation on interrupted exchanges. Pause/fast-forward use world
  time. Traction is interlocked until closing; timetable/dispatcher release
  forecasts include the exchange. Terminal unloading finishes before depot work.
- Added source-grid aisle routes for every seat/door in all 21 coach models,
  original male/female seated Blender variants, and eight shared GPU crowd
  batches. Riders follow the coach body. Boarding/alighting uses vestibules and
  platform-side apertures with hinged ICF/LHB or sliding VB leaves. Reversed VB
  cars use the correct side; cab doors are excluded. Disembarked people continue
  in railway coordinates and do not follow departing trains or origin rebases.
  Maximum 140 seated and 80 moving people within 100 m; journeys remain simulated
  outside this visual budget. Caching reduced the same ICF 220-person CPU update
  from 5.83 to 1.95 ms on the local Radeon 780M development PC (not whole-game FPS).
  Procedural characters, local queues and shader gait are documented honestly in
  passengers.md; dynamic people do not physically collide with the player.
- Added saved fullscreen preference, fullscreen by default in exports, global
  F11/Alt+Enter and a prominent controller-reachable pause-menu action. Windowed
  mode restores prior dimensions/mode. Progress/HUD expose passenger totals and
  the current exchange; occupied seats cannot be selected for sitting.
- Verification: 340 headless tests pass, including ten passenger regressions;
  native ICF/LHB/VB8/VB16
  boarding/seating/alighting captures and both-side door checks pass. Native
  keyboard fullscreen switching through the pause menu and saved configuration
  pass. Controller integration passes 69 checks. All baked seat/door paths are
  reachable. The full 32-service rehearsal passes: every service arrives safely
  and clears to depot, with no safety events. K1 encounters 19 opposing movements
  and three overtakes (including empty stock); latest passenger arrival delay is
  56.0 minutes. Runtime: 1,915 seconds. The free-drive-only initialization addition
  was validated by the 340-test suite and does not alter scheduled workings.
  Manual driving may change outcomes. No extracted-build test.
- Feature commit `9426d13` is pushed. R12 Windows was exported from that clean
  source: 1,631,403,751 bytes; SHA-256
  `f57afb5039ef878cc73a11d9012fa3f31712a8a02973e527de10dee09be95379`.
  Publication uses the existing private LAN server at `http://192.168.8.183:8765/`.
  R12 is advertised as latest; the host verified the catalogue, exact ZIP length,
  HTTP 206 range download, SHA-256 sidecar and passenger guide. R11 remains a fallback.
- Playtest: start fresh K1 at ERS; V/coach menu to inspect riders; watch boarding
  from outside and try power before the countdown finishes. Enable AI and watch
  Kumbalam alighting/boarding, compare F12 totals, then test LHB and both VBs.
  Pause/fast-forward during exchange; watch final unloading before depot work.
  F11/Alt+Enter and controller Menu must toggle fullscreen and remember the choice.

## 2026-10-09 — R11 station master port and terminal depot workings
- Pulled all three complete `south_indian_stations_v02` masters from the user's
  pinned `1585bc27960fb67d970a1b5c75208ddf53597191` gallery. Fetches verify Git
  blob hashes; reassembly verifies per-part and whole-master SHA-256. Background
  Blender runs with source script execution disabled and never saves over them.
- Ported ERS west entrance/interiors/forecourt, ERS east furnished hall, TVC
  heritage/halls/offices, NCJ historic facade/annex/rooms, and the ERS maintenance
  workshop. Preserved all 3,519,333 evaluated triangles from 9,251 source objects
  in 31 spatial batches, with original signage, UVs/normals and translated graph
  materials. Separate simple shadow meshes and Godot distance LODs manage cost.
  Five native model checks confirm exact triangle totals and shader application.
  Source/font notices and exact reconstruction/port limits accompany the build.
  Static authored yard/platform meshes remain in the local complete masters;
  they are not overlaid onto the CSV operating railway. See station-model-port.md.
- Replaced permanent terminal-platform parking with `sim/depot_workings.gd`:
  90-second unloading, exclusive reservation of a reachable finite depot berth,
  then ordinary signal-protected AI empty-stock movement. No teleport/despawn.
  Passenger results, progress and player identity remain; the entire train must
  clear all throats and stop inside its depot road before being marked stabled.
  Operator holds remain effective and deletion releases the depot reservation.
  If full, the depot request waits and retries without overwriting another lease.
- Added reconstructed depot receptions at ERS/ALLP/KYJ/QLN/TVCN/TVC/NCJ, separate
  from passenger inventory. Four full-rake roads per reception, ordinary locked
  points and route protection; new terrain/scenery clearance follows their
  geometry. Reused the detailed maintenance workshop beside those roads. These
  are gameplay connections, not surveyed depot tracks. Older fictional layouts
  without depot infrastructure keep their previous completion behaviour.
- Dispatcher roster/map, journey HUD and PROGRESS expose the new lifecycle while
  the service timetable retains its passenger results. Passenger timetable import
  cannot masquerade a depot berth as a passenger platform. Traffic rehearsal now
  requires all trains to be stabled as well as having completed their services.
  Restored K23's KPY terminus and K24's Haripad call; the temporary timetable
  workaround has been removed in favour of clearing the actual terminal trains.
- Verification: 330 headless tests pass; ten focused depot regressions include
  red signals, tail clearance, finite leases, retries, deletion, holds, all 32
  terminal-to-depot paths, passenger validation and terrain alignment. Native
  station geometry/material checks pass for all five assemblies. Native desk
  render/navigation/inspection checks pass at 1600×900 and 1280×720. The streamed
  ERS scene, including both entrances, loads and captures correctly. Depot
  allocation also passes 30 seeded arrival-order permutations of all 32 services.
  The complete 32-service rehearsal passes: every passenger working finishes
  and every train clears into a depot, with no safety events. K1 encounters 19
  opposing movements and three overtakes (including empty stock); latest
  passenger arrival delay is 55.3 minutes. Runtime: 2,071 seconds. Manual driving
  can change outcomes. No extracted-build test.
- Built the clean committed source `baf96c0` as R11 Windows, 1,630,291,108 bytes;
  SHA-256 `4b4a6223125c77716c1e6d794d441b85f84605f8fdc45d1f7fcb7615bde2d8c3`.
  R10 was withdrawn after its extended rehearsal exposed permanent terminal
  parking; R11 fixes the lifecycle and retains those long-rake/CSV/coach changes.
  Published as latest at `http://192.168.8.183:8765/`; catalogue, exact ZIP length,
  HTTP 206 byte-range download, checksum and both new guides verified from host.
- Playtest: start a fresh Kerala scenario; inspect both ERS entrances and use the
  free camera at TVC/NCJ. Follow K2 into the depot after ERS unloading; its whole
  rake must vacate the platform. Later inspect K23/K24 through KPY/Haripad. Finish
  a short custom service and check that passenger progress remains complete while
  the assigned train moves under AI to its depot. See depot-workings.md.

## 2026-10-09 — R10 long rakes, CSV stations, moving-coach access and rattles
- Replaced the seven-coach class showcase with representative service profiles:
  K1 has 20 seated ICF coaches (466.500 m including WAP-7); WAP expresses have
  22 ICF (511.094 m) or LHB (548.560 m) coaches. The Service Designer supports
  either seated/express profile, preserving it through export/import. VB remains
  8/16 cars. Research and exact formations are in rakes.md. Dedicated SLR, EOG
  and pantry models are absent from the remote assets; these remain fictional
  passenger-only formations rather than exact real-world coach diagrams.
- Every rake uses a single coach family. The reported red/blue mix came from
  blue LHB CC/2S source paint, not ICF geometry in an LHB rake. Standardised the
  exterior LHB paint RGB to the source AC/sleeper red, preserving roughness,
  bump, textures, markings and interiors. ICF retains its source blue finish.
  Rendering, occupied length and joint axles share the simulation formation.
  Full loaded mass now uses WAP-7's 322.6 kN traction ceiling; WAP/LHB is capped
  at 140 km/h and ICF at 110 km/h, with lower scenario service limits retained.
- Audited every Kerala platform/siding in both directions with the longest
  rake, including waiting at the starter. Extra ladder turnouts previously
  shortened inner roads, and starters sat inside the 195 m fouling zones.
  Extended yard approaches per ladder and moved starters to 210 m offsets.
  Shared berth clearance now accounts for signals, points and actual passenger
  platform ends in validation, route admission, future plans, platform selection
  and manual stopping tolerance. Rendering and walking share platform spans.
  Booked calls use reachable passenger faces instead of placeholder through
  roads. Platform totals follow the supplied CSV below; geometry is an operational
  reconstruction, not a real-yard length survey. Old Kerala service drafts have
  a different layout signature and must be recreated against the current layout.
- Added eight seeded, synthesized latch/panel cues from the sibling sound lab,
  with source snapshots and SHA-256 provenance. Irregular spatial timing and
  body jolts trigger stronger/more frequent ICF rattles, quieter LHB rattles.
  Four positional voices per nearby train, fixed pitch, no backlog after seeks;
  pause/reference mode is quiet and stopped trains fade out. These are tuned
  approximations, not measured ICF recordings. Approved joint/squeal banks and
  the user's recordings are unchanged.
- WAP-7 has no passenger gangway. Clarified standing/doorway/help prompts for
  the platform route, corrected passenger coach numbering to exclude the loco,
  and verified collision-swept walking from the actual pilot standing point to
  a side door, along the platform, and into coach 1 using controller Y/A.
  Moving exits remain blocked; walking preserves service/manual brake state.
- Added Pause/Start → Go to passenger coach and the same entry in Camera &
  passengers. Any of the 20/22 passenger coaches is selectable while moving;
  controller A selects, Y stands inside, L3 returns to pilot. Service, AI and
  handle settings remain unchanged. Coach numbering excludes the locomotive.
- Preserved the uploaded station CSV byte-for-byte, pinned its SHA-256 and
  exempted it from Git newline conversion. All 56 selected platform totals and
  station names match the generated world. TNU is closed, reducing K1 to 55 calls;
  KUMM has one passenger platform plus two through roads. Veli uses the CSV IRI
  count of one, retaining the unresolved three-count alternative as evidence.
  DAVM has two faces on one track; KPY storage cannot act as an extra passing
  loop. CSV loop additions at OCR/KZK and six TVCN positions are reconstructed.
  The dispatcher distinguishes platform/through/storage and filters passenger
  road choices. Future-clearance transactions can reserve the sole platform
  after the VB departs, with an independent opposing berth and protected escape.
  Revised regional service origins/calls to use the selected passenger faces.
  All raw reference columns and differences are retained in the reproducible
  station audit. Total yard-track counts, bay connections, chainage and older
  mapped construction figures are not all identical to the operating game map;
  see kerala-station-audit.md. Map regeneration reapplies the CSV specification.
- Verification so far: 320 headless tests pass (exit 0; sandbox certificate-store
  warning occurs after completion). Native ride integration passed
  36 checks across all six profiles; service-editor integration passed 12.
  Native rattle PCM passed 8 checks (peak 0.262, RMS 0.0191; paused/stopped zero),
  with a bounded four-voice pool. Source synthesis test checks all eight finite,
  distinct, repeatable, unclipped WAVs. Long-rake native walking passed 132
  assertions, including moving-coach menu/controller access and scene streaming
  at both stations. Native ICF/LHB throttle, braking and complete corridor trips
  passed. Dispatcher render/zoom/inspection checks passed at 1600×900 and 1280×720;
  captures confirm the sole-platform label and full train footprints. Full-route
  traffic verification is being finished before publication. No extracted-build test.
- Playtest: start fresh K1 and inspect the 20 blue coaches; inspect a WAP/LHB
  express for 22 red/grey coaches. Use F5 to select/export/import either rake.
  At a stopped platform, Y/E stands, A/left-click at the cab side door alights;
  walk to coach 1 and board via its prompt. In an ICF passenger view at 30–60
  km/h, listen for intermittent body rattles beneath the joint/rolling sound;
  compare LHB, stop and pause. At Kumbalam, inspect both train ends and wait
  for the last coach to clear before the conflicting route releases.
  While moving, Pause → Go to passenger coach → last coach, Y/E to stand,
  then L3/4 to return to pilot. Check Kumbalam's 1-platform/3-track dispatcher
  label and PROGRESS's 55 scheduled calls; Tirunettur should be passed without a call.
- Publication: source commit `0de9902` pushed to `codex/port-indian-rail-assets`.
  R10 was built from that clean commit and published at
  `http://192.168.8.183:8765/`; ZIP 1,507,237,046 bytes, SHA-256
  `e81763e01e4b58ade3bfa8ef8ed155f57bc92f58f4292aa31c6673f0c1b61ea6`.
  LAN catalogue, ZIP headers, 32-byte partial download, checksum and four guides
  verified. Existing R9/R8/R7/R6 fallbacks retained. This initial R10 listing was
  withdrawn when the full rehearsal found K23 terminating on KPY's only usable
  northbound passenger road, permanently blocking later calls. A temporary
  timetable workaround was superseded by the user's depot instruction below;
  K23 retains its KPY destination and K24 retains its Haripad call.

## 2026-10-08 — R9 ride motion, onboard acoustics and home lookahead
- User clarified that jolts/vibrations should be introduced. Added a pure damped
  suspension solver and a rendered-axle contact adapter. Actual 39 m joints and
  point interfaces excite heave, pitch and signed roll. Spatial roughness,
  traction/brake changes and curve loading move each body. Bogies/wheels keep
  their rail poses; cab, head-out, passenger and walking cameras share the body.
  Pause, origin rebase, reversal and time acceleration are covered. These are
  tuned ride cues, not measured suspension/coupler/brake-pipe simulation.
- Diagnosed late home setting: dispatch previously considered only the next
  signal. It now prepares the controlled entrance beyond the final clear
  automatic block, within bounded braking distance, using the existing planner,
  berth admission, future-clearance plan and interlocking. It cannot look
  through red/occupied approaches or skip an intermediate call. Yellow home
  remains expected when the platform starter is red; approach can now be green.
- Extended the website/native comparison to moving pilot and passenger receivers
  across multiple joints at 30/71.6/120 km/h. Six captures: -0.015 to +0.142 dB
  RMS difference and 0.064–0.167 dB mean band error, zero virtualized impacts.
  This is track-only, exact website geometry: it does not establish identical
  gameplay sound or video matching. Envelope correlation 0.57–0.86 is recorded
  alongside the close spectral match; no arbitrary EQ/volume retune was made.
- Corrected actual perspective errors: head-out previously inherited enclosed
  cab filtering; walking passenger coaches inherited pilot balance/filtering.
  DTC walking distinguishes the driving compartment from passenger space.
  Approved generated banks and the user's original recordings are unchanged.
- Verification: 304 headless tests pass; real-model ride integration 24/24.
  Complete 32-service run finished safely in 1,430.6 s with 19 crossings and
  three overtakes of K1, maximum arrival delay 40.2 min. WAP/LHB source walking
  check passed 76 assertions; Vande Bharat passed 83, including the new acoustic
  profile checks in both driving compartment and passenger accommodation.
  Final native PCM capture passed all six cases with no virtualized contacts;
  physical contact-time error was below 0.001 ms against the fixture geometry.
  Ride CPU cost in the real-model source check averaged 0.39–0.42 ms/update for
  eight vehicles and 0.80 ms for VB16 on this host, at 1x and 60 Hz; this is an
  isolated component measurement, not a whole-game FPS claim.
  No extracted-distribution test. Reproducible audio harness is committed in
  tools/audio-comparison and tools/check_onboard_audio.gd.
- Playtest: fresh K1, use L3 pilot at 30–60 km/h; change power/coast/brake and
  cross joints/points. Stop and let the body settle. Cycle to passenger, stand
  and walk; then compare pilot versus head-out sound. Try pause and 2x/4x back
  to 1x. At a free station, approach should clear before passing the automatic;
  busy stations and crossings may correctly retain yellow/red protection.
  Published R9 at http://192.168.8.183:8765/ from clean source `feb55bd`.
  ZIP: 1,506,982,461 bytes; SHA-256
  `e218699884d8a54d13e26ac52cd77b2afbfd6c495534939e35819765bfb7ae9e`.
  Verified catalog, archive HEAD/byte range, checksum and ride guide. R8/R7/R6
  remain available as fallbacks; the temporary audio-render server was stopped.

## 2026-10-08 — R8 direct controller camera navigation
- Replaced context-dependent camera chords with shared shortcuts in both Xbox
  layouts: D-pad left/right cycles backwards/forwards, L3 returns to pilot and
  R3 selects detached external free view immediately. Repeated R3 stays free.
  The cycle reads the active camera rather than a stale private index, includes
  detailed WAP cab positions, both head-outs, first/middle/last passenger views,
  following exterior and free exterior, and skips duplicate coach presets.
- Camera commands preserve service assignment, AI and latched power/brake.
  They also exit walking cleanly; held walking/run controls must neutralise
  before they can operate traction. Menus/dispatcher keep their D-pad navigation.
  Free exterior stays in world space: LS pans, RS orbits; holding RS + LS zooms
  in the default layout. Legacy layout retains bumper zoom.
- Resolved displaced controls: on foot B crouches and D-pad up toggles the
  headlamp; default X+Y sounds the horn. Help, controller menus, guide and
  portable instructions describe the new bindings; keyboard controls remain.
- Verification: 285 headless tests passed. Native source checks passed 112 camera
  assertions on WAP-7/LHB, 88 on Vande Bharat, and all 68 existing controller/menu
  regression checks. Camera tests cover both layouts and every cycle position.
  No extracted distribution test.
- Playtest: cycle right through every camera and left back through them; use L3
  and R3 from passenger, head-out and walking views. Let AI drive and verify free
  camera stays behind while following exterior follows. Check menus still
  navigate normally, then B crouch / D-pad up lamp on foot and X+Y horn driving.
  Published R8 at http://192.168.8.183:8765/ from clean source 4d69cf2.
  ZIP: 1,506,962,810 bytes; SHA-256
  `3b2c6e1e75980e1db3d810acd9525ffddf933d27b90e43ec46ce8cbb5544e127`.
  Verified catalog, archive HEAD/byte range, checksum and updated controller guide.

## 2026-10-08 — R7 future-clearance crossing plans and delete service
- Implemented the user's Kumbalam sequence as automatic simulation-owned,
  bounded three-train crossing transactions. Reserve both station berths and
  the vacater's escape section plus a currently free compatible onward berth.
  Incoming trains can approach a protected home signal; actual occupancy,
  point/direction and tail locks still decide when they may enter. Opposing
  departures wait until the incoming train's complete tail is in its berth.
  No chained speculative vacancies; incompatible/held/manual vacaters, busy
  escape berths, unrelated approaches and operator preferences reject a plan.
- Compared with R6, K1 arrives Kumbalam 08:21:02 rather than 08:30:42 and
  Turavur 08:40:44 rather than 08:50:24. The VB still leaves at 08:18:00;
  K2 reaches ERS 08:27:13 rather than 08:21:51. Net arrival-time improvement
  across these three measured calls is 4m18s; not a global optimisation claim.
- Four committed-plan disruption trials passed: K1 starts +10/+20 min,
  K2 +15 min and VB at 08:30 instead of 08:18. No safety events, sampled
  circular waits, wrong receiving platforms or premature opposing departures.
  The complete 32-service rehearsal passed after 1,500 seconds: all arrived
  safely, with 19 opposing crossings and 3 overtakes of K1. Largest arrival
  delay was 40.2 minutes; this validates completion, not timetable optimality.
  Manual driving may change the outcome. Log: `.local/future-32-rehearsal.log`.
- Added Delete service… to the dispatch inspector, with a named confirmation
  defaulting to Keep service. The assigned train is protected; hand over first
  to remove it. Deletion is for this run, releases only that train's authority,
  removes its occupancy/holds/future commitments, then reassesses traffic.
  Streamed models, audio buses and motion state are released; viewing a deleted
  train returns the camera to the assigned service. Restart restores the pack.
- Verification: 285 headless tests pass. Native Vulkan source-game deletion
  checks passed all 18 checks, including Xbox confirmation/cancel, ownership,
  presentation cleanup and dialog placement. Screenshot review caught an
  inherited off-screen confirmation; a CenterContainer now owns its layout.
  The final screenshot and a separate headless layout check confirm centering.
- Removed 11 obsolete build families (base through R5), freeing 20,817,331,582
  bytes (19.39 GiB). Retained R6 as fallback and the incoming R7. The LAN catalog
  and startup script now use those retained builds instead of the deleted base
  ZIP; only archives with a completed checksum appear on the download page.
- Playtest: start fresh K1, drive to Kumbalam's home signal and wait for VB P3
  to clear. Enter P3; K2 should then depart north. Inspect the planned crossing
  advice in D. To recover a blocked run, inspect an AI train, Delete service…,
  cancel once with B, then confirm with A; verify your service remains selected.
  Published R7 at http://192.168.8.183:8765/ from clean source 8a84c42.
  ZIP: 1,506,961,014 bytes; SHA-256
  `7f8b6022c574fc3a86fa4f2d38ffc0bd62bcaa92e9adf0acf39a2af14e59af31`.
  Verified LAN catalog, archive HEAD/byte range, checksum and dispatcher guide.
  Extracted-distribution testing is skipped as requested. Rebuilds invalidate
  the completion checksum before exporting to avoid advertising a stale ZIP.

## 2026-10-08 — Isolated opening-priority experiment
- At the user's request, compared the full 32-service opening with K1/K2
  priorities 20/70 versus 70/20, changed before any route was committed.
  Identical AI driving in both runs; no production priority, timetable,
  dispatcher code or published R6 archive was changed.
- Baseline / swapped: K1 departed ERS 08:20:55 / 08:00:00 and arrived Turavur
  08:50:24 / 08:37:49. K2 arrived ERS 08:21:51 / 08:57:03. K3 departed
  Kumbalam 08:18:00 / 08:48:52. Reversing priority eliminates the passenger's
  initial wait but delays the VB by 30m52s and K2's arrival by 35m12s.
- Both openings cleared with no safety events or sampled circular waits.
  The 262-test headless suite passed. This is an opening comparison through
  K2's arrival and K1/K3 clearing Turavur, not another full-route rehearsal.
  Reusable tool: `tools/check_opening_priority.gd`; local JSON records the
  actual station times, first clearances and originating-road exits.
- Follow-up vacancy probe (`-- --vacancy`, two-second samples): baseline VB
  head left Kumbalam P3 at 08:18:54, rear at 08:19:16. At that moment K2 was
  already on ERS_TNU_M1 and ERS_single was locked for opposing traffic.
  ERS-S1 cleared at 08:20:56. This explains why a newly vacant platform alone
  cannot permit K1's departure in the existing baseline sequence.
- User proposes entering the platform vacated by the VB. A planned meet could
  instead retain K2 on Kumbalam P2, receive K1 into P3 after the VB exits and
  release K2 after K1 clears the approach. Current admission uses available
  berths, not predicted vacancies; this alternative still needs a separate
  simulation and escape-route safeguards. No such policy was implemented here.
- Playtest reference: fresh R6 still uses the baseline opening. Priority
  changes made after a route is committed will not revoke its authority, so
  changing priorities mid-session is not the same experiment.

## 2026-10-08 — Kumbalam receiving capacity, 32 services, platform walking and engine audio
- Reproduced the screenshot's cause: Kumbalam's through main was counted as a
  spare passenger berth, allowing both single-line approaches to depend on one
  remaining platform. Admission now matches each approaching service to a
  compatible free road across both approaches, respecting passenger faces,
  formation length, final road and the following booked call. The same berth
  rule is used for crossing/overtake predictions; stale crossing holds are
  withdrawn when the other service cannot be received. Route/interlocking and
  approach/tail locks remain authoritative. No reversal or teleport recovery.
- Added 25 fictional regional workings, bringing the default stopping scenario
  to 32 services. Starts and final platforms are individually allocated; the
  full simulated timetable is independent of nearby model/audio residency.
  Service packs accept up to 64 services. Presentation loads within 3.2 km and
  unloads beyond 4.5 km, with the player's and viewed service retained.
- Replaced the persistent camera label with next scheduled stop, metres and
  estimated world minutes. F12 remains the detailed progress panel. Estimates
  retain world minutes during fast forward; pending signals are identified.
- L3 held + D-pad left directly selects left head-out in both controller
  layouts, including repeated use and transitions from on-foot mode. Tap L3
  retains horn/crouch/legacy dispatch. Help and contextual prompts updated.
- Added Kerala platform walking from stopped, platform-side train doors and
  boarding another carriage of the assigned service. Background Blender exported
  door locations/provenance from all 22 pinned detailed masters. Collision uses
  platform boundaries and rendered fixtures; no track crossing or station
  footbridge navigation. Camera/audio remain on the platform if the train leaves;
  controller/AI ownership remains unchanged. Door leaves remain static with
  brief prompted transitions. Other-service boarding is not implemented.
- Restored electric hum, load/speed-dependent traction whine, inverter tone and
  the existing horn. Cached native 3D loops belong to WAP locomotives and VB motor
  cars on a separate Traction bus. No generated sound-lab data was edited.
  Native mixer capture measured idle RMS 0.009 and powered RMS 0.023 at the test
  cab; pause silenced the layer. Approved impact/rolling routing and enhanced
  contact counts passed unchanged at 0/30/71.6/120 km/h. Physical listening
  balance on the user's PC remains a playtest.
- Route audit: this game is already mixed line, with about 155 km doubled
  (Ambalappuzha–TVC and Eraniel–Nagercoil). Added the Ministry's February section
  breakdown and June sanction to the route guide; commissioning after those
  sources is not certified. Existing station-audit limits remain explicit.
- Verification: 262 tests passed, plus early and 10/20-minute late manual
  K1 rehearsals with no circular-dependency alerts or safety events. The full
  32-service rehearsal completed with every service arriving safely: 19 opposing
  encounters and three overtakes of K1, with no deadlock or safety event.
  Largest final arrival delay was 40.2 world minutes; this validates completion,
  not an optimal timetable or every possible manual driving pattern. Actual-game
  checks passed 69 interior-walking, 33 platform/controller/engine, 68 legacy
  controller and 17 journey/streaming checks. Every ICF/LHB/VB8/VB16 vehicle had
  a usable doorway, including reversed cars. Native HUD and platform captures
  reviewed; extracted-distribution tests remain skipped by request.
- Playtest: start a fresh K1 scenario, drive early or late through Kumbalam and
  inspect named wait advice in D. Tap L3+D-pad left twice and verify it remains
  left head-out. At a station stand with Y/E, face a platform-side exterior
  door, use A/left-click, walk along the platform and board another coach.
  Check idle hum, power-dependent whine and horn, then compare clack prominence
  from the cab and passenger views. Check next-stop HUD and all 32 roster entries.
- R6 released from clean source `a730104`, committed and pushed to
  `codex/port-indian-rail-assets`. At the user's request, it was published while
  the full rehearsal was finishing; that rehearsal subsequently passed.
  `TrainGame-Kerala-Coast-R6-Windows.zip` is 1,506,960,207 bytes; SHA-256
  `50ecc5270809e5b4ba8478511fe8a113c75a5f5edba796ee0d0e67d12c52c70a`.
  The LAN server at `http://192.168.8.183:8765/` offers R6 first, retaining older
  builds. Verified HTTP page, archive HEAD/length, 16-byte range/resume response,
  checksum sidecar and walking guide. No extracted distribution was launched.

## 2026-10-08 — Interior walking and TSW-style controller contexts
- Added on-foot movement in the moving WAP-7, ICF/LHB and VB8/VB16 interiors.
  Position stays local to the individual articulated car; the camera and audio
  listener use its interpolated pose and reversed-car orientation. Stand/sit
  preserves the current driver and handle. Nearby passenger seats retain their
  exact seat index when re-entered.
- Background Blender baked supported floor/standing/crouch clearance from all
  22 pinned detailed masters without altering visual assets. Runtime sub-cell
  sweeps stop at furnishings, partitions, floor holes and excessive steps; tiny
  isolated floor fragments are excluded from standing/gangway destinations.
  Cached room links connect interior partitions and source-located compartment
  doors. Doorway/gangway prompts use brief transitions; door leaves stay static.
  WAP-7 machinery access works, but there is no locomotive-to-coach gangway.
- Default Xbox controls follow Dovetail's immersive guide: Y stand/sit, LS walk,
  RS look, RT run, L3 crouch, A interact; RT/RB power and LT/LB brake while driving.
  RS camera shift exposes internal/exterior presets. View tap opens dispatch,
  hold shows progress; X opens actions or shifts AI/emergency/coast chords.
  Headlamp, exact-seat interaction, on-foot prompts and context-specific help
  are included. The legacy controller layout remains selectable and persisted.
- Keyboard E stands/sits; Shift+E is now right head-out. WASD walk, Shift run,
  C crouch, L headlamp, right-drag look, left-click interact, 9 dispatch.
  Standing, returning to driving, UI changes and focus loss require neutral
  movement controls before reuse. Walking inputs cannot operate traction; the
  strongest brake request wins when keyboard/controller inputs coincide.
- Verification: 243 headless tests passed. Source integration passed on all
  four formations; native ICF/LHB/VB16 cab, aisle and gangway captures were
  reviewed. VB16 included transitions back through oppositely-oriented coaches.
  The default Kerala scenario passed 69 walking checks, including the live HUD.
  Legacy controller/menu/dispatcher integration passed 68 checks. Native walking
  updates averaged 0.030 ms in LHB and 0.043 ms in VB16 on this host's Radeon 780M;
  those measure the walking update, not total frame time. Physical Xbox feel
  remains a user playtest; synthesized events exercise the actual input router.
- Playtest: Y/E out of the pilot seat, turn toward the machinery doorway and
  use A/left-click; return and sit. Enable AI, choose Alt+1/2/3 passenger views,
  stand, explore and sit elsewhere. Walk through gangways both directions,
  including the reversed VB half; open/close dispatch while holding RT, release
  it, and verify no unexpected power input. Full steps/limitations are in
  `docs/walking.md`. Exterior platform walking, jumps, animated doors and
  clickable cab instruments are outside this implementation.
- R5 packaging includes the clearance JSON and walking/controller guides.
  Extracted-distribution testing remains skipped as requested.
- R5 released from clean source `59dc584`, committed and pushed to
  `codex/port-indian-rail-assets`. `TrainGame-Kerala-Coast-R5-Windows.zip` is
  1,506,915,303 bytes; SHA-256
  `bea076febea9bffe4da4c72ba7f3d984451bfbe8c23aeb764009d20fbfdb918b`.
  The existing LAN page at `http://192.168.8.183:8765/` now offers R5 first;
  older builds are retained. HTTP HEAD, byte-range resume, checksum sidecar and
  walking-guide responses were verified. The source project was tested; the
  extracted build was not launched.

## 2026-10-08 — R4 detailed coach fleet and published VB update
- Ported all fourteen v02 ICF/LHB masters (1A, 2A, 3A, 2S, CC, SL, GS per
  family) from user-owned remote checkpoint `e209ff5`, including full interiors,
  class fittings, bogies, brake gear, underframe equipment and original Hindi
  marking pixels. The source's final gallery remains WIP; its master geometry
  is independently checked. Source pins and rebuild steps are committed.
- A separate background-Blender census agrees with all 13,682,319 evaluated
  source triangles. Closest geometry is complete; static parts batch within
  rigid mechanisms, axles/discs rotate separately and bogies steer. Detailed
  source graphs use the existing material translator, extended for the new
  vector/checker nodes. Noise/lighting/transparency still differ from Cycles.
- Applied the published `main` VB revision `91bcc28`: the three changed EC
  masters are rebuilt, and the four byte-identical car sources are verified.
  Current VB source geometry totals 14,820,268 triangles. The detailed WAP-7
  is unchanged. Selectable stock remains ICF, LHB, VB8 and VB16.
- Native review found Godot stripping `_alpha` from an LHB material identifier,
  which interrupted material binding. Disabled import name hints and preserved
  full-precision material coordinates. A repeatable import configurator and
  material-binding regressions guard this. Original class images bind directly;
  reduced shadow proxies and distance LOD/interior visibility preserve close detail.
- Verification: 232 headless tests passed; all fourteen source censuses and
  coach/VB/WAP integrity checks passed. Native coach review passed 4,218 checks
  across 42 exterior/aisle/seated captures, inspected for all fourteen classes.
  The three updated VB EC masters passed another 959 native checks and nine views.
  All 25 archived/current masters and four playable formations passed import,
  straight/curved axle-to-audio alignment and reversible-car checks.
- Full Kerala source scene passed 128 integration checks, including all seven
  services, unchanged sound-axle maps, first/middle/last passenger views and live
  simulation. Twenty-one native captures cover the four playable formations.
  At 1280x720 on this host's Radeon 780M, settled samples were 33.2–47.6 ms/frame;
  these are diagnostic scene samples, not a 4090 laptop performance guarantee.
- Playtest: launch K1 and use Alt+1/2/3 for first/middle/trailing coach views.
  PgUp/PgDn changes class, Home toggles aisle/seat and arrow keys move between
  bays. Use F9 for the LHB showcase; inspect class lettering, furnishings and
  running gear up close. Use the dispatcher to inspect/view VB8/VB16 EC coaches.
  Doors and coupler articulation remain static source mechanisms. See
  `docs/coach-detail.md`. Extracted distribution testing remains skipped.
- R4 release: `TrainGame-Kerala-Coast-R4-Windows.zip`, 1,506,868,731 bytes,
  exported from clean source commit `a3ac191`, pushed to
  `codex/port-indian-rail-assets`. SHA-256:
  `27d246d064652880423542cab3283c3b4ff50d8ff2d49c0d4bd762a9d6232820`.
  The idle LAN server was refreshed at `http://192.168.8.183:8765/`; R4 is latest.
  HTTP 200, exact content length, byte ranges, checksum sidecar and coach guide
  passed download checks. R3 and earlier archives remain available.

## 2026-10-08 — R3 dispatch engine, control desk and station audit
- Moved automatic dispatch into the simulation-owned DispatchEngine, advancing
  every 0.5 simulation seconds independently of the camera/UI. Separate planner,
  prediction and resource diagnostics evaluate route alternatives, passenger
  road suitability, priority plus waiting age, and receiving capacity before
  admitting traffic to a single-line section. Existing physical interlocking,
  approach locking and tail clearance remain authoritative for all commands.
- Added bounded decision history, actionable blockers, circular-dependency
  alerts, and reconsideration/cooldown of discretionary overtake holds. Platform
  requests survive the departure-call transition and cannot retarget committed
  station entries. These prevent tested avoidable conflicts; arbitrary packed
  terminals or impossible service packs still require operator/schedule changes.
- Rebuilt D as a full-screen control desk: continuous anchored zoom, two-axis
  pan, overview strip, station locator, searchable service roster, timetable,
  attention/log tabs, route previews and service/route controls. Amber footprints
  show actual train length across track/point boundaries, distinct from occupied
  block highlights; close zoom shows coach divisions. UI draws only while visible.
- Clicking inspects without transferring assignment. View train moves only the
  camera; 4 returns to the assigned pilot seat. Take control requires a separate
  confirmation. Xbox LS pan, LT/RT zoom, D-pad targets, LB/RB areas and contextual
  A/B actions work without leaking input into traction. Confirmation traps focus.
- Used the requested in-app Browser for all 56 station entries, 34 secondary
  count sources and dated doubling evidence. The checked-in station audit links
  every source and distinguishes total yard tracks, platform faces and modeled
  operating roads. Current station plans were unavailable: disagreements and
  incomplete terminal bays remain explicit, not certified as exact layouts.
- Corrected commissioned Eraniel–Nagercoil Town–Nagercoil Junction double line,
  documented the reconstructed NJT third road, removed passenger-platform flags
  from QLN/NCJ goods roads and moved terminating services to passenger roads.
  Idempotent source-pipeline corrections preserve these changes on regeneration.
- Replaced station labels with fitted three-row regional/Hindi/English boards:
  Malayalam in Kerala and Tamil further south, correctly facing both sides,
  located inside actual platform ends. Native board checks cover 24 labels in
  all three scripts. Stable route IDs remain unchanged for existing service data.
- Verification: 232 headless tests and 67 native Xbox integration checks passed;
  0/8/20-minute departure-delay rehearsals each progressed beyond Kumbalam to
  call 10 without safety events. Native desk checks passed at 1600x900/1280x720;
  boards and full Kerala source renders were inspected. Sandboxed runs emitted
  Windows certificate/shader-cache environment warnings; no script failures.
- Final autonomous full-route rehearsal: all seven services arrived safely,
  with three crossings and two overtakes of K1. Latest arrival delay was
  10.1 minutes; simulation completed in 918 seconds of wall time. This checks
  the actual world-owned engine, including the corrected southern double line.
- Playtest: press D, locate Kumbalam and zoom to coach lengths; inspect K3,
  choose View train and return with 4, confirming K1 remains assigned. Try Take
  control, cancel, then confirm separately. On Xbox pan/zoom/navigate a wide
  yard and confirm power/brakes do not change. Depart late as K1 and watch named
  priority traffic receive routes. Inspect both faces of an ERS/TVC nameboard.
  Guides: dispatcher-overhaul.md, controllers.md and kerala-station-audit.md.
  Source checks precede packaging; extracted distribution testing remains skipped.
- R3 release: `TrainGame-Kerala-Coast-R3-Windows.zip`, 1,026,067,557 bytes,
  exported from clean source commit `3826889`. SHA-256:
  `fa600e160457eee615c619520ed7aab0aa20453a48879c975ecb093f895e8680`.
  Refreshed the idle LAN server at `http://192.168.8.183:8765/`; R3 is latest,
  with linked dispatcher/audit guides. HTTP 200, exact length, byte range and
  checksum sidecar verified. Earlier R2 downloads remain available. Code was
  pushed to `codex/port-indian-rail-assets` before packaging.

## 2026-10-08 — R2 support, ground contact and manual-stop corrections
- Fixed the geographic renderer placing a +3.6 m mast beside every individual
  road, which intruded into neighbouring track clearances. A read-only shared
  support layout now groups the full track cross-section on one 55 m grid.
  Double track uses outside cantilevers; wider yards use lattice gantries with
  foundations beyond the outer roads and platform edges. Actual curved and
  turnout segments are checked, including footing width. Rows avoid passenger
  footbridges and are owned once across streamed chunks and parallel roads.
- Complete route audit: 5,056 support rows, 7,870 posts, 415 yard gantries, no
  posts within 3 m of a running-track centre. The old method had 2,776 unsafe
  sites under the same audit. Native source renders of Ernakulam, Kollam and
  the Ambalappuzha–Takazhi double track passed without errors and were inspected.
- Buildings now sit on level floors with terrain-following foundation walls,
  sampled against the same 8 m triangles used to render the ground. Station
  frontages/forecourts have retaining foundations too. Shared bridge decks,
  outer guard rails, abutments and submerged piers replace narrow floating
  strips; fractional endpoints close chunk seams. Bridge terrain envelopes use
  their exact chainages rather than extending the lowered ground past the deck.
  `structures.json` covers 115 reconstructed spans, including 54 inferred only
  from water/stream intersections; these are explicitly not surveyed bridges.
- Reproduced a manual-driving failure matching the reported Kumbalam wait: an
  unrecorded Tirunettur call makes all onward platform routes fail the timetable
  reachability check, while old advice misleadingly names the VB/LHB occupant.
  Manual stops now accept the full formation inside the platform stretch with
  a 5 m end margin. AI still stops at its precise marker. A genuinely missed
  call gets specific advice and an explicit Progress recovery button; skipped
  calls remain separate from completed calls. The regression proves a freed
  Kumbalam road clears after recovery while the occupied LHB road stays protected.
  The user's exact run was not captured; an early-stop AI rehearsal also ran
  through Kumbalam normally. No signal/interlocking protection was weakened.
- Verification: 195 headless tests passed with no engine errors. Full-route OHE
  audit and native previews passed. Captures at 4.27 and 6.6 km show the reported
  early backwater crossings supported by complete decks/piers; native Progress
  recovery updates the next stop and skipped count. Generated audio is unchanged.
- Playtest: use D to visit Ernakulam or Kollam and inspect gantries across the
  yard, then ride a double-track section and check the supports stand outside
  both lines. Drive ERS–TNU–KUMM; stop normally with the whole train at Tirunettur
  and confirm 2/56 completed in Progress. A missed call offers explicit recovery
  instead of misleading traffic advice. Default remains K1. Distribution testing
  remains skipped; R2 is a separate download, preserving the original archive.
- R2 release: `TrainGame-Kerala-Coast-R2-Windows.zip`, 1,028,141,653 bytes,
  exported from clean source commit `ae7f457`. SHA-256:
  `2c6a3d7585a39a2885d919df42838b64c6aa89548985fcce5f6af1f220c18c97`.
  The LAN server at `http://192.168.8.183:8765/` serves R2 as latest; HTTP 200
  and exact Content-Length confirmed, with the original R1 URL still available.

## 2026-10-08 — Kerala Coast, dynamic traffic, detailed VB and journey progress
- Added the full-scale Ernakulam–Alappuzha–Kayamkulam–Kollam–TVC–Nagercoil
  railway: 276.585 km between station centres, 56 stations, dated OSM alignment,
  waterways/roads/building footprints and SRTM terrain. The source corridor has
  336,756 mapped buildings. Two workers stream nearby scenery, track, OHE and
  station chunks; edge-local coordinates and a floating origin avoid cab jitter.
  Original background Blender station frontages, platforms, bridges, bilingual
  boards, shelters, people and tropical planting are included. Wide yards keep
  buildings/footbridges clear of their outer roads; radar bridge-top elevations
  are clipped below the rail deck. Geography/provenance/rebuild: kerala-coast.md.
- Station operating roads use an OSM rail/siding cross-section audit with source
  way IDs. Construction and identified dead-end/yard tracks are excluded.
  Single-road halts have no invented loops. Throats, platform identifiers and
  roughly 1 km automatic blocks are reconstructed, not official current plans.
  A single-line direction lock permits following trains but blocks opposing
  entry until occupied trains and committed entry routes clear; idle automatic
  authorities cannot hold the direction forever.
- Seven designed passenger services, including K1's 56-call, 65 km/h stopping
  working, higher-priority LHB/VB services and northbound trains. Dispatch uses
  actual positions, release times, priority, reachable roads and interlocking.
  Overtakes/crossings are not scripted gates. First arrivals take available
  crossing loops, with lookahead covering the next single section through halts.
  A committed meet prevents reciprocal holds at different station loops.
  Fixed an opposite-line-loop overtake deadlock and a PUPR section ID being
  mistaken for a station platform. HUD/F1 names the service to wait for and
  updates/withdraws the advice as conditions change.
- Fresh launch now defaults to **K1 on Kerala Coast**. D still selects any
  service; F9 offers random assignment and four solo formations; F7 changes
  route. **PROGRESS / F12** shows completed/total calls, calls left, next stop,
  distance, approximate in-game travel/dwell time and booked arrival. Origin is
  counted (1/56 initially). Unknown signal waits are identified separately.
  The panel pauses and restores the prior pause state on closing.
- Whole-world fast forward: T cycles ×1/2/4/8/16/32, Shift+T restores ×1; direct
  buttons also exist in pause. All physics/dispatch/clock advance in bounded
  substeps, preserving in-world train limits. Playback and audio scheduling use
  the same simulation rate; approved generated sound data is unchanged.
- Enhanced full-size Vande Bharat v02 is pinned to asset-repo revision
  5322f1ca301c0d8832eccd84c779904f8e4f00f3 (backup/vande-bharat-fullsize-v02).
  All 12,828,460 source triangles across seven masters, source material graphs,
  furnished interiors, seats and articulation survive the transfer. Separate
  shadow meshes, shared resources and engine LODs control cost. Formation pitch
  is 192/384 m for 8/16 cars. Source remains an author-labelled WIP checkpoint.
  Only detailed WAP-7 + ICF, WAP-7 + LHB and VB8/VB16 are playable; low-detail
  WAP/MEMU and WAG showcases are excluded from the package.
- F5 service files now support priorities, speed caps and up to 64 stops, with
  exact stopping markers and route-specific geometry signatures. Long route
  distance queries use cached reverse shortest paths instead of a 64-edge limit.
- Verification: **183 headless tests pass**, including progress counting,
  long-section first-arrival loops, dynamic priority, no opposing single-line
  entry, following trains and expired automatic reservations. Native checks
  pass all four formations' axle/sound alignment, pivots, reverse orientation
  and cameras; WAP/VB geometry, coordinate and dependency hashes pass. Native
  route captures cover ERS/TVC/NCJ, backwaters, both VB interiors and cab, the
  named wait indication, every time rate and the default/progress button. A
  final full-route rehearsal completed all seven services safely, with three
  crossings and three overtakes of K1. Maximum final arrival delay was 3.4 min
  under AI driving; manual driving can change dispatch and arrival times.
  Source-render static memory stayed roughly 508–595 MiB across distant visits,
  with zero observed far-end position error. These are Radeon 780M checks,
  not a 4090 benchmark. Distribution testing remains skipped by request.
- Playtest: launch directly into K1; open PROGRESS/F12, close and depart or press
  A for AI. Check the counter after Tirunettur. Use T/Shift+T on long stretches
  and waits; watch the named crossing/overtake advice. Drive late and check that
  higher-priority traffic is dispatched from actual running. D selects K3/K5
  for VB8/VB16; inspect pilot, head-out and first/middle/last passenger views.
  F5 edits priority/speed/stops and exports/imports the timetable. F10 helps
  compare cab/exterior performance on the 4090 PC. Mapped geography is a
  playable reconstruction, not a surveyed replica of every railway detail.
- Release: `TrainGame-Kerala-Coast-Windows.zip`, 1,028,125,182 bytes, built from
  clean source `8058044` and pushed to `origin/codex/port-indian-rail-assets`.
  SHA-256: `533ae81626c4f7f570550fe1126172d2ab97d4cd6fc72c0a44c4e7f1b79d7575`.
  The existing LAN server now offers it as the latest build at
  `http://192.168.8.183:8765/`; ZIP HEAD returned 200 with the exact byte length.
  No extracted-distribution tests were run. Final source suite: 183 passed,
  zero failed, including the reciprocal-loop-hold regression.
  Rehearsal encounters: K2 crossing at Kumbalam 08:12:06; K3 overtake at Thuravur
  08:39:28; K4 crossing at Mararikulam 09:14:28; K5 overtake there 09:16:52;
  K6 overtake at Karunagappally 11:08:10; K7 crossing at Nemom 14:11:32.
  These are observed outcomes of this AI run, not scripted event times.

## 2026-10-07 — Pilot/head-out cameras and portable service designer
- Added direct pilot (4), left/right head-out (Q/E) and return toggles. Xbox
  D-pad left/right/up offers the same while driving; passenger shortcuts remain
  in other views. Eye points clear both body sides and follow the active cab,
  including reverse cabs. Quick transitions move/rotate with the train rather
  than trailing from a frozen world position. The shortcuts preserve AI/manual
  state and the handle; Tab's take-cab action no longer resets the handle.
- F5 / pause menu / dispatch opens a separate, paused service editor: formations,
  unique IDs/names, departure day/time, world start, platform/block stops, minute
  offsets, dwell, optional markers, add/duplicate/remove and stop ordering.
  Import/export portable JSON; last valid draft persists in user data.
- Added pure simulation service-pack validation and construction. Files bind to
  the layout geometry/signals. Unknown/malformed input, invalid markers,
  unreachable/wrong-direction stops and duplicate starting blocks are rejected
  without replacing the draft or running world. Overnight schedules supported.
- Incremental AI rehearsal checks the whole timetable independently, reports
  arrival delay or held services, and can be cancelled. Play selected service
  launches it with the other trains under AI and the dispatcher routing the
  manual player's service too. Arbitrary service IDs work throughout the desk;
  handover returns the previous train to AI. Restart retains the launch choice.
- Limits are explicit in the UI/guide: 12 physically present trains, 16 stops,
  forward workings, no automatic run-rounds or train spawning. Definitions are
  not running savegames. Finished trains still occupy their destinations.
- Verification: **161 headless tests pass**, including portable round-trip,
  invalid/overnight schedules, full six-service completion and a deliberately
  blocked terminal. **37 native source integration checks**, **58 existing Xbox
  checks**, **7 moving/reversing camera checks**, and **9 incremental editor
  rehearsal/persistence checks** pass. Native captures show
  both WAP-7 head-out sides and the designer at 1280×720. Distribution testing
  remains skipped per the user's preference.
- Playtest: use Q/E/4 while accelerating/braking and looking around; try the
  Xbox D-pad from the pilot. F5, edit service times/platforms, Validate, Rehearse,
  Export, then Import the JSON on the other PC. Select a service and Play; obey
  red while the other trains depart. D switches services; verify the old one
  continues under AI. Restart and check the authored schedule is retained.
  Guide: docs/services.md (included in the portable build).
- Committed/pushed source **7f102d5** and built the clean
  TrainGame-Services-Windows.zip, **610,375,399 bytes**, SHA-256
  **1dcf5e91fefaeda08f039b2af20209eaeb0a8f7ebaaca8394490cb320704c40f**.
  The existing private-LAN page at http://192.168.8.183:8765/ lists it first.
  Its download returns HTTP 200 and the correct length; prior builds remain.
  Only source checks and download availability were tested, not the extracted
  distribution. The task's hidden editor and check processes are closed.

## 2026-10-07 — Asset and surface fidelity with a bounded rendering increase
- Responded to the user's request for less artificial-looking assets, with
  explicit permission to use some of the newly available performance headroom.
  Preserved the full WAP-7 v0.2 model, simulation and approved audio data.
- Rebuilt 14 building types with rounded masonry edges and improved plaster,
  exposed-brick, metal and window finishes. Restricted bevels to substantial
  construction edges after the first native comparison; small fittings retain
  their original geometry. Single-surface architectural batching remains intact.
- Rebuilt four tree variants: fuller 23-frond palms and broadleaf crowns using
  registered CC0 leaf photographs on bent cards. Rebaked matching eight-view
  distant atlases. Added 8,471 nearby grass/weed patches, finer varied rice blades,
  closer road texture scale and revised terrain texture blending. Whole patches
  clear rails, paths, drains, troughs, fields and building footprints.
- Stations now use photographic PBR plaster/concrete maps, paving joints and
  varied roof-sheet wear. Ballast/sleepers are darker and more weathered. Five
  static passenger assets have integrated facial geometry, hairlines and revised
  clothing. These remain simple scenery characters, not scanned humans. Native
  comparisons and scope/limitations: `docs/visual-fidelity.md` and
  `art/scenery/fidelity-preview/`.
- **155 headless tests pass**, as do the focused permanent-way check and
  **99 native scenery checks**, including all ground-cover placements and world
  release after reload. The first clearance audit exposed the Dummy renderer's
  identity transform readback; the check now explicitly skips that unsupported
  operation in headless mode and verifies it with the native renderer. All 42
  geometry GLBs and existing registered hashes pass the asset audit; all 43
  Blender masters open with packed dependencies. Native shader/visual captures
  cover the three stations, settlement/rural views and close trackwork.
- Isolated same-camera six-train profiles on this **Radeon 780M at 1280 × 720**
  measure before/after mean frame time **27.09/27.33 ms cab**, **35.98/38.57 ms
  exterior**, **21.24/22.66 ms passenger**: about 1%, 7%, 7% extra frame time.
  GPU times are 26.27/26.32, 35.03/37.73 and 20.31/21.75 ms respectively.
  These short fixed-camera measurements are not a 4090 or route-wide FPS result.
- Playtest: Tab at a station, inspect paving/roof sheets/buildings; A to let AI
  depart, then Alt+1/2/3 and look sideways at foliage, fields and verges. Check
  grass clearance and distant transitions while moving. Compare F10 at the same
  camera/resolution against the previous WAP build, which is retained on the LAN
  server. Distribution testing remains skipped per the user's preference.
- Built and pushed clean source **`959e8b9`**. The new
  `TrainGame-Fidelity-Windows.zip` is **610,339,539 bytes**, SHA-256
  `00928f96827d7a70e7ff4be5769e6c477f5b07c635433a697cb34917be2e4a83`.
  The existing private-LAN server now lists it first at
  `http://192.168.8.183:8765/`; its download responds HTTP 200 with the correct
  length. The previous WAP-7/audio-fix archive remains available for comparison.
  No extracted-build/distribution tests ran. The temporary MCP editor was closed.

## 2026-10-07 — Joint timing and website audio fidelity correction
- Investigated the user's delayed cling/clang and weaker website resemblance.
  Confirmed that desktop streamed polyphonic voices ignore the per-substream bus
  argument: a native PCM probe recorded zero signal on the intended filter bus
  until the owning player itself was routed there. The previous property checks
  and unfiltered single-joint reference comparison did not expose that error.
- Routed rolling through its actual 900 Hz shelf, pooled impact players through
  each joint's distance/cab filter, and squeal players through their color/air
  chains. Keep 24 impact locations, 128 impact channels and 12 squeal voices;
  pause, re-entry and scene exit stop/release all routed players and buses. The
  approved PCM, variant laws, pitch, axle loads and geometric sound travel are
  unchanged. Generated sound assets were not edited.
- The previous starts also omitted output-device/mixer delay. Added a cached
  driver-latency estimate and per-submission next-mix compensation, with enough
  prediction to retain the entire 21.333 ms attack even at lower frame rates.
  F10 now shows the driver and output-buffer estimate. Dummy/offline captures
  are exempt. This host's WASAPI probe could not open an output device and fell
  back to Dummy, so the fix is verified at the scheduler/native-mixer level;
  actual speaker/Bluetooth/display alignment still needs the user's PC playtest.
- The website defaults to **39 m SWR**, while the game used 13 m joints. The user
  explicitly approved matching 39 m. Changed the shared visible/sounding layout
  together, retaining the 6.5 m edge offset, 10 mm gap and separate turnout
  interfaces. This removes two thirds of ordinary joint contacts; axle-pair
  timing still follows each vehicle's geometry and speed.
- **155 headless unit tests pass**, including device-buffer prediction headroom
  and 39 m/2.56 m timing in both directions at 30/60/120 km/h. Focused native PCM,
  reference-audio, curve/passenger lifecycle, permanent-way, rendered axle-motion
  and original BODY V2 checks pass. The routing test measures rolling/impact
  signal on the actual filtered buses and approximately 0.021 filtered/bypass
  amplitude for a 6 kHz probe through the 900 Hz low-pass.
- Re-recorded the controlled eight-second single-joint website fixture at
  30/71.6/120 km/h. Mean absolute spectral-band error is 0.137/0.135/0.142 dB;
  the 30 km/h result improved from 0.767 dB after the rolling shelf correction.
  Overall level differences are -0.035/+0.0004/-0.063 dB. These are controlled
  reference measurements, not a claim of identical whole-game or speaker output.
  Evidence: `.local/audio-fix-ab/comparison.json` and capture WAVs. A six-service
  120-second simulated CPU profile ends at 4.90 ms mean / 6.54 ms p95 control work,
  12 queued events and 23 buses; it is not an FPS measurement.
- Playtest the updated build at normal simulation time: F3, drive/AI at about
  30/60/100 km/h, Tab close to a bogie and watch an actual gap as axles cross.
  Compare cab and Alt+1 passenger sound, slow into a turnout, stop, then resume.
  Check the clearer spacing and preserved cling/clang pitch. If a device delay
  remains, F10 supplies its driver/buffer estimate. Distribution testing remains
  skipped per the user's preference; required source tests ran above.
- Built from clean source **`c7858cb`**, pushed to the existing GitHub branch.
  The updated `TrainGame-WAP7-Detail-Windows.zip` is **601,356,949 bytes**, SHA-256
  `652bdad3ea934817f520ac4ec45a7c28837ba229651d22d2ab552583d9dbea34`.
  Replaced the latest WAP-7 download on `http://192.168.8.183:8765/`; a HEAD request
  confirms HTTP 200 and the correct length. No extraction/distribution tests ran.

## 2026-10-07 — Detailed WAP-7 v0.2 port and persistent mouse look
- Ported the user's updated WAP-7 39002 master from `transport-fever-3-mods`
  revision `de45b4e0e4194af47b1182800b7d103409c69478`. The offline byte audit and
  Godot mesh audit confirm **2,885,744 visible triangles**, 12,331 nonempty source
  objects consolidated into 24 rigid groups, 109 material roles and **40 original
  texture files with matching source hashes**. Both furnished cabs, machinery
  compartment, lettering, seats, grilles and running gear are retained. See
  [the port guide](wap7-detail.md) and `art/wap7/detail-preview/` native captures.
- Preserved full float object/generated material coordinates and the original
  image resolutions. Translated material graphs into 21 shared shader programs,
  with filtered noise and a shared small volume texture. Near visible geometry
  is not decimated. A separate 107,006-triangle shadow mesh follows the rigid
  moving parts; distant interiors cull at 100 m. URI-backed geometry buffers
  are split losslessly below GitHub's file-size limit, with manifest hashes.
- Godot materials approximate Cycles noise, BSDF mixing and refractive glazing.
  Occupied-cab windows reduce reflection/tint to keep the forward view clear.
  The source instruments remain static artwork; live driving values use the HUD.
  The source has no authored `SURFV02_Wear` mesh attributes, so its absent-attribute
  value of zero is preserved. Simulation geometry and approved sound banks are
  unchanged; bogies, six axles, pantographs and cab-door hinges stay independent.
- F2/F3 now select this detailed light engine / mixed LHB rake. Default random
  six-train traffic also uses it for WAP-7 services. Home cycles driver, assistant,
  cab overview and machinery-aisle viewpoints; the controller menu exposes the
  same action. Passenger Home keeps its seat/aisle function. Right-drag look now
  persists on release; middle-click explicitly recenters, as does right-stick
  click. F2/F3 retain the existing scenario-change confirmation.
- All **16 release-check scripts pass**: **153 unit tests**, **58 controller checks**,
  **16 detailed cab/control checks**, **95 scenery checks**, source/engine geometry
  and texture audits, seven imported
  formation journeys, rendered motion, track, original/enhanced audio, passenger
  views and six-service corridor/traffic checks pass. Native inspection covers
  both cabs, machinery, running gear, roof and both exterior sides without script
  or shader errors. The release builder now also treats logged engine errors as
  failures even when Godot exits with status zero.
- The six-minute moving cab soak completed cleanly: node count 26,099 and audio
  buses 30 throughout, peak pending events 56, engine static memory 667.4–676.5 MB.
  It overlapped headless checks and is a stability check, not an isolated FPS
  benchmark. An isolated same-camera native comparison on the Radeon 780M at
  1280 × 720 measures previous/detailed mean frame times of **21.25/26.69 ms cab**,
  **34.56/35.27 ms exterior**, **19.37/21.15 ms passenger**. Preserving the full cab
  adds measurable GPU cost; this is not a 4090 result. The guide includes GPU
  times and method. Portable release verification follows below.
- Playtest: F3 → confirm → Home through the four cab positions; right-drag and
  release, then middle-click to recenter. Tab outside and inspect grilles, bogies
  and roof while moving. F2 → confirm → stop → R to inspect the opposite cab.
  Alt+1/2/3 still selects first/middle/last passenger coaches. F10 shows performance
  readings for comparison on the 4090 laptop.
- **Portable release:** `TrainGame-WAP7-Detail-Windows.zip`, **601,353,874 bytes**,
  built from clean tracked source **`b814c75`**. SHA-256:
  `60f290bffdd55fcada77172cae622c477f8c7118763f1e11d378f59d479b19ab`.
  The code commit is pushed to `origin/codex/port-indian-rail-assets`. The LAN
  server at `http://192.168.8.183:8765/` now lists it first; its ZIP responds with
  HTTP 200 and the correct length. The earlier scenery archive hash is unchanged.
- The user requested stopping repeated distribution tests. Stopped this run's
  remaining extracted-build checks after default/MEMU/WAP-7/WAG-9 startups had
  passed. The other extracted formations and PCK audit were **not completed**;
  no full distribution-verification claim is made. Saved the preference in
  `docs/builds.md`. The 16 source release checks and native model/stability work
  above were already complete. Only a download-link availability check followed.

## 2026-10-07 — GitHub sign-in and first push
- Completed the user-requested GitHub CLI browser sign-in as `gj94` and pushed
  the full committed game history through scenery verification commit `3b3106c`
  to `https://github.com/gj94/Train-Game`, branch
  `codex/port-indian-rail-assets`. The branch now tracks its matching origin branch.
- Configured this checkout's GitHub credential helper to use the signed-in CLI;
  Git directory trust remains scoped to each command. The raw reference recordings
  and local build/tool folders were not added to Git. Gameplay and the verified
  LAN build are unchanged; use the scenery playtest steps below.
- Re-ran the headless suite before the handoff commit: **152 passed, zero failed**
  (`.local/github-push-tests.log`). The remote default branch matches the pushed
  working branch.

## 2026-10-07 — Scenery rebuild and portable release
- Replaced the corridor's generic houses and sparse ground dressing with a
  deterministic settlement/land-use plan: three station towns, four villages,
  industrial fringes and about 1,967 buildings. Roads, building roofs/awnings and
  942 agricultural plots are checked against the actual rail segments and each
  other. Simulation, rail geometry and approved sound data are unchanged.
- Added 41 original Blender assets plus a registered CC0 photographic tree:
  tiled homes, shopfronts, apartments, quarters, school, warehouses, rice mill,
  temple, water tower, telecom mast, road vehicles, passengers, stalls and
  vegetation. Editable masters and reproducible background build scripts are
  included. Scanned foliage and the three new Poly Haven PBR texture sets have
  source URLs, author/licence records and verified hashes in the asset register.
- Added street signs in English/Tamil, clipped pavement at junctions, bus bays,
  parked vehicles, utility wires, passenger figures, produce carts and 36
  decorative vehicles following smooth left-hand road loops. Road traffic reads
  the simulation clock and pauses with the game; it does not affect rail logic.
- Terrain is spatially tiled, with a land-use mask, modelled canal banks, field
  bunds/irrigation and nearby crop geometry. Trees use eight-view colour/normal
  impostors at distance. Architecture uses one draw surface per model with
  material categories encoded in vertex colour; all instances are spatially
  batched. The asset library holds its owning world weakly, preventing a reload
  resource cycle caught during native inspection.
- **151 headless tests passed** at this milestone, including exact clearance,
  exported footprint bounds, road-loop continuity, junction/bus-bay openings,
  determinism and release of the old scenery owner. All **95 scenery runtime
  checks** also pass, covering the exported library, impostor dimensions, paused
  road traffic, platform figures and resource release after reload. Final native
  inspection, GPU comparison, moving soaks and portable verification are recorded
  below.
- Playtest focus: look out from the cab and Alt+1/2/3 passenger views at station
  approaches and the four villages; compare both sides of the train. Check shop
  fronts, bus stops, people, foliage transitions and field detail while moving.
  Use F10 to compare frame time and audio queue behaviour on the 4090.
- Asset portability follow-up: independent GLB audit checks all 41 original
  exports, embedded resources and exact encoded material categories; the CC0
  tree and nine downloaded texture hashes match provenance. All 42 editable
  Blender masters open without external image dependencies. Fixed lazy-loaded
  image packing in the photographic tree master and removed an unused source
  object; runtime GLB geometry/pixels are unchanged. Manifest triangle counts now
  come from the actual glTF export, after degenerate-face removal.
- The moving soak exposed expensive onboard arrival queries when several trains
  meet. Added a conservative sound-wave/receiver reach check before the unchanged
  exact curved-arrival solver, and skip stereo calculations for virtual voices.
  **152 unit tests pass** including the new curved-path bound regression.
  A same-frame before/after six-service comparison over 1,200 simulated seconds
  matched **92,375 contacts** in physical time, arrival time, native scheduling
  frame, sample variant and gain (tolerance 0.1 microsecond for times).
  Mean control CPU fell from 17.62 to 11.04 ms; the worst original ten-second
  window fell from 100.36 to 18.13 ms. This accelerated, rendering-free comparison
  is not an FPS measurement or a bit-identical live audio capture: native voice
  allocation follows wall time, and was counted separately. No sound data changed.
- All **14 release-check scripts pass** on the final runtime code: 152 unit tests,
  58 controller checks, 95 scenery resource/lifecycle checks, original and enhanced
  native audio, motion, permanent way, all seven imported formations, six-train
  dispatch and full corridor completions. Portable extraction, final native
  rendering comparison, sustained runs and LAN delivery also pass as recorded below.
- Final pedestrian review corrected the street-lot selector so all four standing
  passenger variants appear. The 152 unit tests and 95 scenery runtime checks
  pass again after this placement-only correction.
- **Portable scenery release:** `TrainGame-Scenery-Windows.zip`, **491,977,062
  bytes**, built from clean tracked source **`d675d57`**. SHA-256:
  **`0c0626138b42bf686170839d9c51b207098286e6ff81816a758221dbdedc1ede`**.
  A fresh extraction passes EXE/PCK hashes and all nine startup configurations
  (default, MEMU and the seven imported formations). The PCK audit finds all 42
  scenery models, ten atlases, seven scenery shaders, the 39 original lossless
  impact/rolling WAVs and provenance, with raw references/development files absent.
- The authorized LAN server is running at **`http://192.168.8.183:8765/`**. A full
  HTTP download matches the new archive hash; range/resume, HEAD, read-only access
  and the path allowlist pass. The previous standard/controller archives retain
  their original hashes. Logs: `.local/scenery-final-package-check.log` and
  `.local/scenery-download-verification.json`.
- Saved an [interactive before/after comparison](../art/scenery/preview.html)
  and unedited native screenshots in `art/scenery/preview-*.png`. The overview uses
  the same camera before and after; street/crop close-ups show the final source.
  This fictional scenery has decorative people/road traffic and exterior-only
  buildings; it is not a surveyed town or a finished photorealistic environment.
- **Isolated Forward+ comparison:** Radeon 780M, 1280×720, frozen six-service
  scene and unchanged quality. Mean GPU time before → after is **cab 20.76 →
  18.23 ms; exterior 31.33 → 31.63 ms; first passenger coach 19.44 → 17.17 ms**.
  Final source has 25,979 scene nodes and roughly 638–640 MB engine static memory.
  This is graphics timing, not live-game FPS or a 4090 result. Evidence:
  `.local/perf-render-after.json`, `.local/scenery-profile3.json`; all three native
  screenshots were inspected. The extracted final EXE also passes native startup.
- **One-hour moving scenery soak passed:** cab, all three coach positions and
  exterior, two completed journeys/reloads, zero retained old worlds and no engine
  errors. Nodes remain 25,948 in this run's earlier pedestrian mix; engine static
  memory ranges about 637–667 MB and drops after reload. This run started before
  the audio arrival optimization and overlapped other checks, so its frame times
  are not the final performance result. Evidence: `.local/scenery-soak.{log,json}`.
- **Final-source 24-minute native drive passed:** twenty minutes in the cab, then
  the first passenger coach, a full service completion and a clean reload into
  the next service. All 48 samples retain **25,979 nodes**; sampled engine static
  memory is **644.6–670.5 MB**, falling to 644.6 MB after reload and ending at
  649.4 MB. The old world is released. No warnings, script/resource errors or
  leaked-object reports occur. Reload takes 19.15 seconds on this PC.
- During that isolated moving run, 30-second steady-play frame-time means range
  **18.17–27.92 ms**; the worst audio-control window is **12.67 ms** with about
  917 impacts pending. The queue peaks at 1,370 during nearby traffic and drains
  again. This is the same Radeon 780M/1280×720 setup, with Dummy audio for
  unattended scheduling checks; these figures exclude loading pauses and are not
  an audible sound comparison or a prediction for the 4090. Evidence:
  `.local/scenery-soak-final.{log,json}` and `.local/scenery-native-qa.json`.
- Work is committed on `codex/port-indian-rail-assets`. GitHub push was attempted
  without interactive prompts, but this PC still has no saved GitHub credentials
  (`gh auth status` rechecked during final verification). Remote delivery remains
  pending sign-in; the verified LAN ZIP is available now. Raw reference recordings
  remain untracked and are absent from the commits and build.

## 2026-10-06 — Interior slowdown and scenery rendering
- Fixed the growing interior audio workload: impacts from trains at the other end
  of the corridor were retained for long propagation delays and recalculated every
  frame before eventually being discarded. Cull contacts beyond a conservative
  2.6 km prefetch radius before queueing, preserve the existing 1.6 km native
  playback limit, and avoid allocating filter buses for inaudible events. Onboard
  audio skips the unused corridor-wide nearest-joint search; exterior sources
  share the listener's selection. The arrival solver stops after convergence to
  0.1 ns instead of repeating identical route queries. Approved PCM is unchanged.
- Split corridor-wide MultiMeshes into 256 m spatial cells so distant scenery and
  shadows can be culled. Batch differently sized scenery/station boxes by material
  using scaled unit boxes, and reuse other BoxMeshes. World geometry and graphics
  settings are preserved; automatic LOD now operates on the spatial batches.
- Controlled six-service audio profile: before, mean control work rose from
  **20 ms at 10 simulated seconds to 358 ms at 60 seconds**, with **2,342 pending
  impacts**. After, it stays approximately **4–7 ms through 300 simulated seconds**,
  with a peak of **54 pending impacts**. This is an accelerated 10 Hz CPU workload,
  not a game FPS measurement. Evidence: `.local/perf-audio-before.json`,
  `.local/perf-audio-after.json`; repeat with `tools/profile_traffic_audio.gd`.
- Forward+ comparison on this PC's **Radeon 780M at 1280×720**, with identical
  frozen six-train scenes and unchanged quality: mean GPU time **cab 56.21 →
  20.76 ms, exterior 52.58 → 31.33 ms, passenger 54.61 → 19.44 ms**. Cab primitives
  fall from 41.45 M to 11.91 M. Before/after screenshots of all three views were
  inspected. These are graphics profiles, not a 4090 or full-game FPS claim.
  Evidence: `.local/perf-render-before.json`, `.local/perf-render-after.json`;
  repeat with `tools/profile_rendering.gd` without `--headless`.
- F10, or controller Menu → Train & view actions → Sound/diagnostics, toggles live
  FPS, GPU time, audio control time, queued impacts, buses and draw counts.
  Disabled by default. `tools/profile_runtime.gd` provides a 90-second moving
  six-train cab/passenger soak; timings are report-only, not hardware thresholds.
- The live 90-second moving cab → passenger → cab soak completed without engine
  errors: audio control averages **7.57–8.84 ms** across ten-second samples,
  pending impacts peak at **49**, buses settle at **30**, and memory settles near
  **540 MB**. The F10 overlay was visually checked in both interiors. This run
  overlapped headless validation, so its 37–43 FPS is not an isolated benchmark.
  Evidence: `.local/perf-runtime.json` and `.local/perf-runtime-*.png`.
- **143 unit tests, 58 controller checks, enhanced audio reference checks and
  native lifecycle/passenger checks pass.** New regressions verify unchanged
  world transforms/box corners, converged arrival timing, rejection of 1,000
  remote impacts without queue/bus growth, retained approach margin and expiry.
  Release/package verification is recorded below.
- **Release complete:** all thirteen build-check scripts pass on performance
  source `d0dc90c`, including permanent-way geometry, all 25 imported models,
  motion, both audio adapters, UI/controller safety, traffic, the six-MEMU corridor,
  all seven imported-fleet journeys and menu reload. Logs:
  `.local/perf-verify-*.log`. Controller implementation is commit `79e0349`.
- Exported **`TrainGame-Controller-Windows.zip`**, **420,689,679 bytes**, from a clean
  tracked tree. SHA-256:
  **`cf36d4598abfb20ad08eeddca4e47aef8f8c8d66abecef6f5bb6d3245d9335f0`**.
  A fresh extracted copy passes EXE/PCK hashes, default traffic and VB16 startup
  with no script/resource errors, and an independent PCK audit confirms all
  controller/performance scripts, **39 lossless WAVs** and provenance, with raw
  reference media excluded. Evidence: `.local/perf-release-build.log`,
  `.local/perf-package-check.log`, `.local/controller-package/`.
- Published at **http://192.168.8.183:8765/**, server PID **26232**. The landing page
  offers the latest performance/controller ZIP first; the prior ZIP is unchanged
  (SHA-256 `11b315007d9f95fa3920652a673ab42edb5092ac1b2733eb579e9f210e323ce1`).
  A full **420,689,679-byte HTTP download** matches the new checksum. Both links,
  instructions, file allowlist, method restrictions, HEAD and byte ranges pass.
  Existing private-LAN configuration is retained; no firewall prompt was needed.
  Temporary editor/profiling games have exited. Keep the host awake for downloads.
- Opened a fresh requested GitHub CLI browser sign-in after the earlier device
  code expired. Authentication is still pending; commits are local and **not
  pushed**. No credentials are stored in the repository. Resume the authorized
  push after sign-in succeeds.
- **Playtest on the 4090:** extract the new performance/controller ZIP into a fresh
  folder; press F10 and A for AI. Ride in cab for at least five minutes, switch to
  first/middle/trailing passenger coaches with Alt+1/2/3, then compare exterior
  with Tab. Check that frame time and queued impacts do not steadily grow, and
  that nearby axle pairs and curve squeal still follow motion. Note FPS, GPU ms,
  audio ms and resolution if any view remains slow. The earlier ZIP stays on LAN
  for comparison. Physical controller feel/vibration still need user testing.

## 2026-10-06 — Full Xbox controller input and menus
- Added standard-layout Xbox 360/One/Series/Elite controls across driving, cameras,
  passenger positions, pause/help/fleet menus, dispatch routes, service selection,
  timetables and manual point control. RT/LT adjust the combined handle with brake
  priority; all other existing commands are reachable under Train & view actions.
  Native dropdowns use explicit controller selection and a single repeat owner,
  avoiding duplicate native/gamepad actions. The simulation and approved audio
  sources are unchanged.
- Added visible focus outlines, scrolling menu buttons, context hints, and saved
  deadzone/sensitivity/inversion/vibration settings. Active-pad disconnect and
  application focus loss pause safely. Reconnection never resumes automatically;
  held inputs cannot carry from menus into driving until neutral. Switching back
  to keyboard releases controller UI focus. Route/point safety remains in RailWorld.
- **139 headless tests passed. All 56 graphical controller integration checks
  passed**, including analog input, brake priority, AI takeover, camera/coach
  controls, menu selection, settings persistence, native dropdowns, safe routes,
  locked-point refusal, timetable overflow, disconnect and keyboard handoff.
  Screenshots of pause/settings/dispatch and the corrected footer were inspected
  at 1280×720. These are synthetic pad events in native Godot; physical USB/wireless
  controllers and vibration still need the user's playtest. All release checks
  passed on controller commit `79e0349`, including all seven fleet journeys and
  menu transitions; the separate ZIP also includes the performance fixes above.
- Installed SHA-256-verified official GitHub CLI 2.102.0 under `.local/gh/` because
  no CLI was available here. Opened its browser device sign-in at the user's request;
  authentication is not yet confirmed. No credentials or raw recordings are committed.
- **Playtest:** use [the controller guide](controllers.md): RT/LT partial movement
  and release-to-hold; A AI/manual; B emergency at a stand; Y and sticks for views;
  D-pad for first/last/adjacent coaches and Menu for middle; L3 dispatch with
  signal/destination dropdowns and service selection. Scroll Help and every pause
  action. Hold RT across pause/resume and unplug/reconnect while moving: both must
  require a deliberate neutral/reapply cycle. Check Windows focus loss, saved
  settings and keyboard Space after closing menus. The earlier LAN ZIP remains
  available for comparison.

## 2026-10-06 late evening — Random traffic assignment and scenario briefing
- User extended the release request: start as a randomly selected train among live traffic, with genuine waits for other trains; Help must explain what to expect from the player's perspective. Fresh launches now choose one of six passenger services (two LHB, two ICF, VB8 and VB16) on the existing Southern corridor. All are ready at 08:00; paired departures compete for real interlocked throats/blocks. The other five use AI; automatic dispatch includes the manually driven player's booked routes without changing their throttle or brakes.
- `sim/layouts/traffic_service.gd` owns stock/placement and reproducible assignment; `dispatch_plan.gd` adds an explicit eligible manual-service argument, retaining legacy behavior by default. No interlocking bypass, imposed wait countdown or fake traffic. Restart keeps the assignment; F9 offers a fresh random service alongside explicit solo fleet choices. Passenger cameras, audio listener ownership, desk selection and the previous train's AI update together when changing services.
- F1 now opens **Scenario & Controls**: selected service, booked stops/times, preceding departures, shared-platform waits, completion objective, driving/passenger instructions and current auto-dispatch/HOLD MRT state. Help still pauses the simulation. T5 specifically explains that T1 and T3 normally depart first. The original MEMU dispatch exercise and solo scenarios remain explicitly accessible.
- **136 unit tests pass**, including real queued departure/release and safe completion of all six mixed services, geometry/platform capacity, deterministic assignments covering all services and manual-driver routing without control takeover (`.local/traffic-unit.log`). The revised QoL integration passes on a fresh six-train default, including contextual Help and modal clock/input safety (`.local/traffic-qol.log`). Actual-scene traffic integration also passes: T5 remains manual and braked while T1 and T3 physically depart, its route then clears automatically, all six passenger camera/audio transfers remain attached, and Help follows the selected service and dispatcher settings (`.local/traffic-playable.log`). The rendered Help screenshot was inspected at 1280×720 (`.local/traffic-help.png`); the graphical integration also passes. Release verification is recorded below when complete.
- Preserved-mode checks: the original six-MEMU corridor completes its congestion/recovery test (`.local/traffic-legacy-check.log`); the solo LHB journey completes. Its old eight-button assertion was updated for the additional traffic choice, and the isolated fleet menu/reload now passes with all seven named workings plus the new option (`.local/traffic-menu-final.log`). The isolated harness now waits for the initial scene before accessing its HUD. Xbox 360/One/Series/Elite support was discussed as a future input/UI task; it is not part of this build.
- **Playtest:** extract the refreshed ZIP and launch with no arguments. Press F1 first to read your assignment and expected traffic. Resume, watch preceding departures on D, obey red and use W/S to drive or A for AI. Use Alt+1/2/3 to ride; check the new squeal on curves. Let preceding trains clear before your signal changes; call at the booked Maruthur platform, dwell, then finish at the opposite terminus. F9 → New random traffic service starts a new assignment; restarting keeps the same one. Push remains deferred.


- **Final release verified and published:** game source **`4dcb0a7`**, clean tracked tree at export. ZIP **422,357,689 bytes / 402.8 MiB**, SHA-256 **`11b315007d9f95fa3920652a673ab42edb5092ac1b2733eb579e9f210e323ce1`**. Freshly extracted default random traffic and explicit VB16 launches exit 0 without script/resource errors; EXE/PCK hashes agree. Independent PCK audit finds all **39 lossless audio WAVs**, provenance and the traffic/briefing scripts; raw recordings remain excluded. Logs: `.local/traffic-release-build.log`, `.local/traffic-package-check.log`; extracted copy `.local/traffic-package/`.
- Private-LAN download is live at **http://192.168.8.183:8765/**, PID **23332**. Refreshed the identified old game server and its landing-page instructions; no firewall changes. A complete **422,357,689-byte HTTP transfer matches the new ZIP SHA-256**; landing page, download allowlist, method restrictions, HEAD and byte ranges pass. Keep this PC awake during downloads. Temporary editor and graphical probes have exited; the LAN server stays running. Game/audio changes and release notes are committed locally; GitHub push remains deferred.

## 2026-10-06 evening — Enhanced benchmark squeal and passenger presets
- User requested the enhanced source at `platform-curve-squeal-src-md-20261006-215639`, then supplied a newer version in the workspace. **The current reference is `platform-squeal-benchmark-src-md-20261006-221237/platform-experience/Acoustics.md`.** Its spectrum-fitted random-phase squeal replaces the intermediate three-tone source; source snapshots remain untouched. The sibling lab owns `profiles/platform-enhanced/` and `tools/export-platform-enhanced.mjs`; complete recovery sources/calibration scripts are in `tools/sound-lab/enhanced/`.
- `game/main.gd` now selects `platform_audio.gd`. Preserved original BODY V2 PCM and pitch; added multiple real joints, stationary rail sources, moving-listener flight time, 32-bin passenger/cab body balance, low-speed rolling gain/900 Hz shelf, and native per-source air filters. `track_contacts.gd` shares actual turnout interface/gap positions with rendering, suppresses ordinary periodic gaps inside complete point assemblies, and supplies 11 per-rail contacts per axle at each modeled complete point. Ordinary track retains its actual 13 m gaps; the website's 39 m optional arrangement is not substituted invisibly.
- New squeal banks preserve the full **262,144-frame / 5.461333 s** periodic FFT output at 48 kHz, quantized without normalization/detuning. Weighted curvature under individual wheels, the sustained envelope, 4.8 kHz curve-color shelf, moving inner-wheel sources and retarded pose history follow the new source. Bounded native voices release/re-enter and clean up on pause, coach jumps, consist reset and exit. No per-sample GDScript synthesis. Source-native dynamics/resampling and finite voice budgets are documented adaptations; no sample-identical output claim.
- User additionally requested first/middle/trailing passenger views. **Alt+1/2/3** enter them directly, **1/2/3 while riding** switch them, and **Esc → Passenger views** provides buttons. Skip non-passenger luggage/generator stock; preserve AI/manual controls. Existing PgUp/PgDn, position and seat controls remain. The default seven-coach mixed LHB selects vehicles **1/4/7**. Actual camera/listener attachment and menu checks pass, and three graphical captures were inspected (`.local/enhanced-pax-0/1/2.png`).
- **132 headless tests pass** (`.local/enhanced-sparse-full.log`), including independent new-JavaScript fixtures for 56 onboard cases, rolling/demand/curved states, stable reverse identities, point sources/gaps, both directions at 30/60/120 FPS and 10/30/71.6/130 km/h, lifecycle history and exact routed PCM. Native curve/lifecycle and actual passenger integration checks pass. Ordinary-track geometry checks pass. New source package: 23 acoustic/model tests pass; one report-only test cannot run because its source-only archive omits `public/squeal-fit.json`. Do not claim its recording/held-out calibration was independently reproduced.
- Native offline mixer vs unmodified new website in single-joint reference mode at **30/71.6/120 km/h**: RMS differences **+0.256 / +0.0004 / −0.063 dB**, mean absolute third-octave differences **0.767 / 0.135 / 0.142 dB**, with peak below 0.35 after warm-up. Heard-event counts **12/29/45**, zero at rest; these use acoustic arrival rather than the old look-ahead boundary counts. Evidence `.local/enhanced-ab/`, `.local/compare_enhanced.py`, `.local/enhanced-capture.log`. This comparison validates the straight reference mix; native curve routing/banks have separate tests and do not constitute speaker listening or a field recording match.
- **Playtest:** download the refreshed build after release verification below. Use A for AI, Alt+1/2/3 for first/middle/last passenger coach, then compare slow/fast running, curved turnouts and straight track. Pause/resume and switch coaches repeatedly; brake to a stand, restart and change ends. Impact timing must follow actual wheel distance/speed without transposition; low-speed rushing should recede; squeal should follow curves. Human listening on the other PC is still required. Git push remains deferred under the user's earlier instruction; do not reopen authentication automatically.
- Additional real-scene preset checks pass for the original 20-coach LHB (**1/9/18**) and VB16 (**0/7/15**), retaining driver state and exact camera/listener attachment. A long-consist CPU probe exposed redundant full-train history interpolation per bogie. Sparse wheel queries, converged retarded-time iteration and conservative distant-source culling reduce measured control cost for 86 axles / 42 bogies on a curve from **19.01 to 6.05 ms/update** on this host. A regression test verifies sparse/full pose equality, and the final native curve/lifecycle plus default passenger-view integration passes (`.local/enhanced-sparse-integration.log`); this is an isolated CPU measurement, not an FPS guarantee.

## 2026-10-06 — BODY V2 website audio integrated into the game
- User explicitly requested faithful integration of the **complete approved website**. `game/main.gd` now instantiates `body_v2_audio.gd`; the prior joint-video mixer is inactive. The sibling sound lab owns `profiles/platform-body-v2/` and `tools/export-body-v2-godot.mjs`; the approved snapshot remains untouched. All nine original WAV files match their approved SHA-256 hashes. Routed stereo copies preserve every impact PCM sample and add only silence for precise native scheduling. Imports explicitly disable lossy QOA; game mixing is 48 kHz.
- Preserved eight full 341.333 ms decays, 21.333 ms attack lead, variant/load mapping, unchanged impact pitch, neutral shelves, approved master/impact/rolling balance, one listening joint, per-bogie phase-staggered rolling, inverse-distance/equal-power panning, power normalization and mild rolling-only Doppler. Removed the active old speed-gain/reverb path. Matched Web Audio's independently measured **1.255 dB** compressor makeup gain. Godot's compressor does not expose the browser's 3 dB soft knee; native resampling/buffering differs, so this is not claimed to be sample-identical output.
- Physical axle positions and shared rendered motion drive contact timing at changing speeds and in both directions. A stationary observer hears one existing visible joint; moving/following views select the nearby joint, onboard views use actual camera position. Below 0.5 m/s rolling fades to silence; at a stand there are no new contacts. Default controls retain the approved neutral balance. Track geometry and graphics quality are unchanged. Details and playtests: `docs/body-v2-audio.md` and `docs/track.md`.
- **121 headless tests pass** on the final adapter. Tests cover approved hashes, exact routed PCM, website fixture identity/loads, power normalization, stereo/distance law, visible-joint selection and 25–160 km/h timing in both directions at 30/60/120 fps. Existing scheduler tests exercise acceleration/braking/stopping/transitions. Actual-scene rendered-motion check passes: zero camera error, 0.083021–0.083510 m intermediate body steps, matching visual/audio axle positions.
- Original website `audio.js`/`model.js` were rendered unchanged through browser OfflineAudioContext; actual native game playback was captured through Godot's offline mixer with the same 20-coach geometry, 42 bogies, listener and pass origin. Full-mix RMS differences at **30 / 71.6 / 120 km/h: +0.0014 / +0.0063 / +0.0282 dB**; mean absolute third-octave differences **0.115 / 0.129 / 0.177 dB** over roughly 80–8,000 Hz after excluding start/end buffers. Correct contact counts: **11 / 29 / 46** in eight seconds, zero at a stand. Waveform/envelope identity is not claimed. Evidence: `.local/body-v2-ab/`, `.local/compare_body_v2.py`; final packaging checks and LAN publication are recorded separately below when complete.
- Windows WASAPI could not open a host output device during this session. Comparison therefore uses verified native offline mixer output, not a claim of speaker listening on this PC. The user's other-PC listening/performance check remains necessary.
- **Playtest:** extract the refreshed ZIP to a fresh folder, start the default WAP-7/mixed-LHB formation, enable AI with A, use Tab for exterior and V for passenger view. Inspect a visible joint at roughly 30/60/120 km/h where permitted: pair intervals halve as speed doubles without raising impact pitch. Brake to a stand, restart, change ends and repeat. A stationary trackside view is closest to the approved website; moving/onboard perspectives are explicit adaptations.
- **Release verified and published:** all Windows build checks pass: 121 unit tests, permanent-way geometry, fleet finish, imported assets, rendered motion, actual audio players, QoL, six-service corridor, all seven fleet journeys and the fleet-menu reload. Build log: `.local/body-v2-build.log`. Clean source **`dd464a1`** (audio implementation `54f7a6a`), ZIP **415,490,411 bytes / 396.2 MiB**, SHA-256 **`16263987f05a3f2c95c3017889018ab97457c8c2a3f930625611b2d535c25238`**. Freshly extracted default WAP-7/LHB and VB16 launches exit 0 without script/resource errors; EXE/PCK hashes match. An independently mounted PCK loads all **27 lossless WAVs** and provenance; raw reference recordings are absent. Evidence: `.local/body-v2-package-check.log`, `.local/body-v2-package/`.
- The existing private-LAN download is live again at **http://192.168.8.183:8765/** (PID **10144**). A complete **415,490,411-byte HTTP transfer matches the ZIP checksum**; landing page, allowlist, method restrictions, HEAD and byte ranges pass. No firewall changes or new prompt. Temporary audio comparison servers/editor/captures were closed; the LAN server remains running. Keep this PC awake during the download.
- Final isolated-layer comparisons also pass: strike RMS differences stay within **0.08 dB** and mean band differences within **0.28 dB**; rolling RMS differences within **0.008 dB**, band differences within **0.12 dB**. The stopped native PCM capture is digital silence. Full-mix peak is below 0.30 after warm-up. These are objective offline measurements; they do not replace the user's listening check on the other PC.
- The user requested committing and pushing, then supplied **https://github.com/gj94/Train-Game**. `origin` now points there; the remote initially had no refs. The push of `codex/port-indian-rail-assets` waited for local Git Credential Manager authentication. The user explicitly deferred authentication/pushing until later, so the waiting attempt was canceled; **do not claim this work is pushed**. The working sibling lab is not a Git checkout, so `tools/sound-lab/body-v2/` preserves its exact exporter and approved reference sources with restoration instructions; all four copied source hashes and exporter syntax were verified. Original WAV inputs/provenance are committed under `assets/sounds/body_v2/`; raw recordings remain untracked. Git push preflight finds no blob over 100 MiB (largest 52.4 MiB). Resume with `git -c safe.directory=D:/ClaudeWS/train-game push -u origin codex/port-indian-rail-assets` after local authentication is ready.

## 2026-10-06 — BODY V2 website is the new user-approved audio reference (review)
- User supplied **`D:/ClaudeWS/platform-body-v2-approved-20261006-022055`**, said another agent had perfected the sound at various speeds, and clarified **the website's playback was perfect**. Treat the complete website playback/mix as the approved reference for the next game port. The currently published game still uses the preceding joint-video bank; this session inspected the new package without changing runtime audio or the LAN build.
- The immutable snapshot includes complete source, eight **48 kHz mono / 341.333 ms** synthesized impact variants, an **8-second rolling bed**, the fitter and its reference. It fits **`MultipleTrainsTrackside.mp4` seconds 15–35**, a different recording from our previous `TrainVideo.mp4`. The default **71.6 km/h** is a geometry-based acoustic estimate. The user has approved the website at various speeds; the snapshot manifest's older wording only mentions reference speed.
- **Nine existing tests pass.** Additional direct scheduler checks pass at **25/30/60/71.6/100/120/130 km/h in both directions**: 86 contacts for a Co-Co locomotive plus 20 LHB coaches at one joint; wheel/bogie/coach timing follows distance divided by speed. Verified **36 first-party/source/media files against the backup's SHA-256 manifest**, with no mismatch. Independent analysis of the actual reference/composite WAVs reproduces **0.0390 dB mean / 0.3755 dB maximum third-octave error**, after undoing the shared bank gain, and **87.8658% vs 87.8415%** energy in 50–800 Hz relative to 50–10,000 Hz. This validates the saved offline mono fit, not perceptual identity or the full browser output. Analysis: `.local/review_body_v2.py`, `.local/body-v2-review.json`.
- Preserve the website's full **341 ms decay**, **21.3333 ms pre-contact lead**, eight-way variant selection `(vehicle*3 + bogie*2 + axleIndex) % 8`, natural axle loads, unchanged impact pitch, default impact/rolling ratio, neutral body/brightness shelves and **no added reverb/metal oscillators**. Impact strength is not multiplied by our old speed law. Body/brightness default to 50%, impact strength 0.7 (unity after normalization), rumble 0.55 (unity), master 0.65. A simple WAV swap into the existing game mixer would alter the approved result.
- The website sounds **one fixed listening joint** and pans it with equal-power spatialization/inverse-distance attenuation (4 m reference, 1.2 rolloff). Its rolling bed is emitted per bogie with staggered loop phases, a power normalization that prevents a longer rake becoming arbitrarily louder, and mild rolling-only Doppler. The game currently combines repeated 13 m joints, a single rolling layer, speed gain and reverb. The port must preserve the website's listening perspective at a stationary trackside observer and explicitly adapt onboard/moving views; one-joint playback does not establish real track-joint spacing. Keep physical sound/visible axle crossings aligned.
- Website speed adjustments preserve train position by rescaling its time, cancel pending sounds and reschedule a constant-speed pass. Its UI range is 25–130 km/h. A game port must retain continuous acceleration/braking, stopping, reverse travel and route transitions through the game's physical scheduler, and validate the complete mix against website output at matching speed/geometry/listener settings before replacing the approved LAN build. Adopt the package through the sibling sound lab as the source; preserve the supplied snapshot without refitting or overwriting it.

## 2026-10-06 — Approved joint-video strikes integrated at physical train speeds
- User approved the offline recreation and requested it in game with speed-dependent gaps. The sibling sound lab now owns `tools/fit-joint-video.js`, `profiles/joint-video.json` and `tools/export-joint-video-godot.js`. It extracts **14 pairs / 28 individual synthetic strikes** from the approved v3 synthesis (SHA-256 `bfabf8112fe1c2facb26d32ed9cdb4ad35af521b17c005ee599b7d253a220c6a`) and fits a separate rolling bed. Original video PCM is not copied. The generated game bank has provenance alongside it; raw MP3/video references are explicitly excluded from exports.
- Each strike is **133.515 ms** including a **17.415 ms** lead, tapered before the next reference wheel. Both wheels of a bogie select the same approved variant pair. Actual axle/joint crossings schedule playback, with late-start compensation and constant pitch. No eight-second loop, fixed beat interval, inferred video speed or original audio/video lag is embedded in the game. The approved natural first/second-wheel tone and level replace the earlier extra -4 semitone / +5 dB treatment. Reduced reverb preserves transient prominence; comma/period still adjust the second axle and brackets the overall level.
- Existing **13 m visible/sounding joints** remain shared through `rail_joint_layout.gd`; the video shows one joint and cannot establish spacing to another. LHB pair delays are **0.3072 / 0.1536 / 0.0768 s at 30 / 60 / 120 km/h**. Different stock uses its actual axle positions; stopped wheels create no contacts and rolling becomes silent. TRACK_ONLY remains on.
- **114 unit tests pass**, including constant-speed timing from **15–160 km/h**, **30/60/144 fps**, both directions, acceleration/braking/stop and consistent variant pairs. The actual `TrainAudio` player check passes at 0/30/60/120 km/h. WASAPI Train-bus captures under `.local/audio-preview/game-joints-*kmh.wav` confirm nonzero moving audio without clipping and digital silence at zero speed. Fifteen targeted sound-lab regression tests pass. Game-bank reassembly at reviewed source contact times measures 0.906 envelope correlation, 1.66 dB third-octave difference and +0.24 dB level versus the full approved clip; unassigned background thuds are not scheduled as extra axles.
- Added the real audio-player check to Windows packaging; updated active-bank documentation and asset provenance. Full release checks passed: 114 unit tests, permanent-way geometry, fleet finish, imported assets, rendered motion, actual audio players, QoL, six-service corridor, all seven imported fleet journeys and fleet-menu transitions. Build log: `.local/joint-bank-build.log`.
- Published **`export/TrainGame-Windows.zip` (410,216,206 bytes / 391.2 MiB)** from clean source commit **`e2f7f66`**, including the earlier close-up motion interpolation fix. SHA-256 **`922fc3a0e6895de1ceb16751e259d9c77a651f7e6684cf364e8c8eec079ec31e`**. Extracted EXE/PCK checksums match; default mixed LHB and VB16 release launches return exit 0 without script/resource errors. An independently mounted PCK loads all 28 strikes and rolling, and confirms both original references are absent. Test copy/logs: `.local/joint-bank-package/` and `.local/joint-bank-release-*.log`.
- Restarted the existing private-LAN server at **http://192.168.8.183:8765/** (PID 24644). A complete HTTP download matches the ZIP's SHA-256; landing page, allowlist, HEAD, method restrictions and byte ranges pass. No new firewall prompt or rule. Keep the host awake for downloads; target-PC listening/performance still needs the user's playtest.
- **Playtest:** extract the refreshed LAN ZIP into a fresh folder. Start the default WAP-7/mixed LHB rake, use A for AI, Tab for an exterior view, and zoom to an LHB bogie. Compare roughly 30/60/120 km/h where allowed: every doubling of speed should halve the gap within the pair without raising its pitch. Use V for the passenger perspective, brake to a stand, then change ends and repeat. Inspect the wheel crossing the visible gap. The preceding close-up interpolation fix is included; graphics quality is unchanged.

## 2026-10-06 — Use the joint-focused video as the current offline reference
- User supplied **`TrainVideo.mp4`**, then explicitly asked to focus on its axle crossings. Inspected all **242 frames at 30 fps**: **28 near-side wheel passages / 14 two-axle bogie groups**, crossing one fixed joint location (gaps visible in both rails). Original file is untouched and untracked. This trackside view does not establish distance between successive joints, train type or speed; do not transfer the other MP3's 60 km/h assumption to it.
- `tools/analyze_joint_video.py` records manually reviewed contact-frame estimates with at least **±33 ms** visual uncertainty and matches their audio peaks. Corresponding within-bogie peak spacing is **0.13787 s median** (range 0.13497–0.13932 s); bogie-pair starts alternate **0.39474 / 0.78222 s**, with a four-wheel pattern every **1.17769 s**. Audio energy peaks are not exact mechanical contact or attack-onset timestamps.
- Source AAC timestamps contain a **33.333 ms gap after the first 1024-sample frame**. Plain WAV decoding removes it. The final `TrainVideo-audio-clocked.wav` was decoded with `-copyts` and `aresample=async=1000:min_hard_comp=0.001:first_pts=0`, preserving the full **8.160317 s** timeline. After preserving it, matched audio peaks lag the reviewed visual crossings by **0.18068 s median**, with 0.01005 s RMS residual. The cause of this apparent lag is not established; it must not become a game sound delay.
- Extended the sibling lab's separate `tools/match-onboard-reference.js` to label trackside references and unknown speed, while preserving compatibility with the previous onboard model. Final offline reconstruction: `.local/video-reference/joint-video-v3-*` (v1/v2 are superseded extraction trials). The A/B WAV plays **reference 8.160 s → silence 0.750 s → reconstruction 8.160 s**. Both measure **-17.4 LUFS**, with **0.99943** 10 ms envelope correlation, **0.171 dB** one-third-octave RMS spectral error and negligible RMS level difference. It is a magnitude-based reconstruction of the whole clip, not yet a reusable physical wheel-impact model.
- `joint-video-v3-aligned.mp4` copies the original video stream unchanged and uses reconstructed audio advanced by **0.180680439 s**, with a 5 ms entry fade and silence padding at the end. Video stream SHA-256 is identical to the original. After decoding the preview's AAC, all **28 matched peaks** remain within **0.73 ms** of their intended shifted times and within **22.86 ms** of reviewed contact frames. This is an estimated alignment for visual listening comparison; `joint-video-v3-AB.wav` retains the original timeline for the sound-only comparison. Reports and plots are in `.local/video-reference/`.
- **Validation:** sound-lab spectral/voicing tests **4 pass**; game headless suite **108 pass** (`.local/joint-video-unit.log`, existing sandbox certificate diagnostic). No game sounds, geometry or LAN package changed. **Listen next:** watch the aligned video, compare the sound-only A/B, then use the labelled contacts to develop reusable impact and decay components after the user judges the match.

## 2026-10-06 — First offline match of the actual 00:55–01:00 recording
- User explicitly wants to match audio **outside the game first**. Created a separate five-second spectral reconstruction of the actual selected passage using the sound lab's existing `src/spectral.js`. The new lab tool is `../railway-clang-simulator/tools/match-onboard-reference.js` (staged backup under `.local/sound-update/`); existing lab profiles, generated game sounds, physical schedules and LAN release are unchanged.
- This is an explicitly labelled **analysis/resynthesis baseline**, not the old equal-level LHB impacts or an independent physical model. It fits the whole excerpt including background, saves only mid/side spectral magnitudes, then reconstructs with seeded phases and 256 consistency passes. It preserves the measured changing pattern instead of inserting a fixed 0.94 s pair schedule. It does not identify individual wheel contacts, choose joint spacing, or claim generalization to new speeds.
- Listening artifacts in `.local/audio-preview/`: `onboard-55-60-v1-AB.wav` = **reference 5 s → silence 0.75 s → reconstruction 5 s**; `onboard-55-60-v1-synthetic.wav` is the reconstruction alone. Both comparison takes share the same headroom attenuation after RMS matching, with no limiter/compressor; FFmpeg measures each at **-16.4 LUFS**. Their true peaks are -4.6 / -1.4 dBFS respectively, reflecting different synthesized phases. Original MP3 and prior previews are preserved.
- `tools/verify_offline_audio_match.py` verifies the exact A/B ordering/silence and output measurements: **0.99293** stereo 10 ms energy-envelope correlation, **0.99935** midband envelope correlation, **0.174 dB** RMS one-third-octave spectral error, and less than **0.001 dB** RMS level difference. Midband transient contrast is **6.291 dB reference / 6.253 dB reconstruction** under this analysis window. Saved report, model, verification JSON and comparison plot accompany the WAVs. These are acoustic checks, not a perceived-similarity score.
- A second render using only the saved magnitude model (no source WAV argument) produced a **byte-identical synthetic WAV**, SHA-256 `47ee662024ff825ce01bc26eb760d352c4f4aba1f3b9d40d0a1cdcbda22d71ae`. Sound-lab spectral/voicing tests: **4 pass**. Game headless suite: **108 pass**, no gameplay changes (log `.local/offline-match-unit.log`; same sandbox certificate diagnostic). **Listen next:** play the combined A/B at one volume and compare cling/clang separation, body, ringing and sound between groups. First confirm this excerpt's audible match before extracting reusable impact/background components or integrating into the game.

## 2026-10-06 — Diagnose crowding before matching the onboard recording
- The user still finds the 60 km/h preview crowded and asks how to make the game match `TrainAudio.mp3`. The reference-mix preview deliberately removes distance attenuation, making both bogies equally prominent. With 26 m joints, successive pair starts alternate **0.894 / 0.666 s**, so it does not reproduce the recording's measured dominant envelope period near 0.938 s. That autocorrelation result is a provisional group periodicity, not a verified list of cling/clang onsets.
- The actual game still uses **13 m** joints: at 60 km/h one axle repeats every **0.780 s**. For one LHB coach on an uninterrupted uniform joint lattice, the two bogies' pair starts settle into **0.114 / 0.666 s** intervals; the 0.114 s separation is shorter than the **0.1536 s** within-bogie axle interval, so pairs interleave. These calculations distinguish the game schedule from the 26 m offline preview; neither establishes the recording's track construction.
- The game's kernels were fitted to the earlier ICF/66 km/h reference. Interior playback currently applies the same distance law as exterior playback, followed by a common low-pass/reverb; it has no separately fitted transmission/filtering for the listener's coach, its two bogies and neighbouring coaches. This is a model limitation to investigate, not proof that every distant axle should be muted.
- Recommended next work: verify the audible groups and within-pair timing in 00:55–01:00, check recurrence over a longer surrounding section, then fit an onboard profile in the sibling sound lab (near/far bogie levels, decay, spectral body and rolling bed). Compare physical schedules at the confirmed 60 km/h without inventing rail spacing from the 0.938 s estimate. Keep contact events aligned with the shared visible joint layout. Render a level-matched A/B using the same runtime model, then validate speed changes and export to Godot once the listening comparison is convincing. Asked the user for coach type and recording position; unknown is acceptable but limits physical identification.
- A fixed 0.94 s pair preview was proposed as a listening diagnostic; it has **not** been generated or applied to the game. User steered to diagnosing the real game match. No sound assets, gameplay, recording, or LAN package changed. Existing executable code retains its latest **108 passing headless tests**. Next listening check should use an onboard LHB passenger position at 60 km/h, compared at equal perceived loudness with the recording, rather than assuming the WAP-7 cab has the same acoustics.

## 2026-10-06 — Match the preview to the recording's 60 km/h speed
- The user clarified that `TrainAudio.mp3` was recorded at **60 km/h**, and found the 100 km/h preview's cling/clang hits too close. Re-rendered the one-LHB/1-km comparison at 60 km/h using `node tools/preview_lhb_track.mjs --speed=60 --reference-mix`. This schedules new event times without slowing or pitching down the impact WAVs.
- At each joint, the four axle times relative to the first are **0, 0.1536, 0.8940 and 1.0476 seconds**: 153.6 ms within each bogie, then 740.4 ms from the leading bogie's second axle to the trailing bogie's first. These match the preferred isolated 60 km/h sample exactly. The comparison still uses its explicitly illustrative 26 m track spacing, giving 1.56 seconds between successive joints for one axle; this spacing was not deduced from the onboard recording.
- Output: `.local/audio-preview/lhb-one-coach-1km-jointed-26m-60kmh-reference-mix.wav` (62 seconds, 39 joint locations / 156 axle events). Stronger reference impact level and -12 dB preview rolling bed retained; measured peak 0.2706 (-11.35 dBFS), no clipping. The recording analysis now records the user-provided speed separately from measured group periodicity. Game assets and LAN package are still awaiting the ongoing sound/layout tuning decision.
- **Listen:** compare the first coach crossing against `lhb-one-coach-one-joint-60kmh.wav`, then listen through repeated joints. The cling/clang should have the same spacing and pitch as that preferred short clip, with quiet rolling noise underneath.

## 2026-10-06 — Smooth close-up motion and a deeper second axle
- Replaced fixed-step visual train positions with route-distance interpolation shared by bodies, bogies, wheel rotation, camera targets and joint-sound scheduling. The old tail edge is retained until the rendered tail clears it; teleport/cab changes snap safely. Simulation/interlocking remain independent. Disabled Godot's physics jitter correction for this custom interpolation. The overview camera now carries forward the train's movement before easing its framing, avoiding speed-dependent lag at 3 m zoom.
- Updated the **sibling sound lab source**, then regenerated both impact WAVs and `physical_model_data.gd`: second axle **four semitones lower**, **+5 dB clang balance** (3 dB louder than before). Impact remains anchored at 768 samples / 17.415 ms, with the full longer decay retained. First-axle samples, fitted profile and rolling WAV are unchanged. Reversed imported two-axle bogies now retain cling-then-clang ordering. Comma/period still adjust balance.
- Added five route-interpolation tests, a reverse axle-order test, and an actual default-rake/camera/audio integration check to the Windows build checks. **108 unit tests pass**. The actual scene advances at every intermediate 240 Hz sample (0.083021–0.083510 m per frame) with zero measured close-follow error. A real engine-clock probe also found zero display-only stalls; rendered capture is `.local/motion-close-up.png`.
- Sound-lab targeted tests: **16 pass**; its complete suite has one unrelated failure because `examples/target-55-95-synthetic.wav` is absent. The approved fit was not recreated to hide that missing reference. Measured game audio has exactly +5 dB energy balance, a 0.7937 pitch ratio, unchanged lead, and no clipping in the comparison sample (`.local/audio-preview/`). Source changes are `src/game-track-tuning.js`, `test/game-track-tuning.test.js` and `tools/physical-export-godot.js` in the sibling lab.
- Graphics quality is unchanged. A 1280×720 wheel-level Forward+ probe on this host's Radeon 780M averaged about 19 FPS; GPU profiling attributes most time to geometry/shadow passes. The user confirmed the receiving PC has an RTX 4090. Its performance still needs a playtest; the interpolation correction does not imply a measured frame-rate claim for that PC.
- **Playtest:** download the refreshed ZIP and extract into a fresh folder. Launch the default WAP-7/LHB rake, press A for AI and Tab for exterior, and zoom on an LHB bogie while travelling at 40–80 km/h. Check smooth wheel/body/camera movement and a distinctly deeper, louder second axle at each fishplated gap. Check paused/resumed motion, a curve, and the rhythm after reversing. Comma/period adjust clang balance.
- Full game checks now pass: track/joint geometry, fleet finishing, imported assets, motion, QoL, six-service corridor, all seven imported fleet journeys/menu transitions, original WAP-7 and 20-coach LHB integrations. Release packaging and LAN publication are pending the joint-layout listening comparison below.
- The user asked for isolated previews: one bogie pair (three repetitions), one LHB coach across one joint at 60 km/h, and one coach over 1 km. The coach uses 14.9 m bogie centres / 2.56 m axle spacing. `tools/preview_lhb_track.mjs` renders from the exported WAVs/constants without editing sound data. Current comparison: 26 m jointed track at 100 km/h, 39 joint positions / 156 axle events, 38 seconds including approach/decay, with a rolling bed; a given axle meets successive joints every 0.936 seconds. A separate illustrative welded-panel preview has joints at its two ends, 1 km apart. Both are local under `.local/audio-preview/`.
- Joint-spacing clarification: 13 m is the game's existing jointed-track setting, not a claim about present-day welded mainlines. Indian Railways' 2024 permanent-way manual includes 26 m rails and 39 m short welded panels; its LWR manual explains much longer welded sections and end expansion joints. The user's initially suggested 500 m minimum and subsequent request for roughly once-per-second clanging at 100 km/h are being resolved with the audible 26 m preview before changing the game's shared visual/audio layout.
- **User prefers the prominence of `lhb-one-coach-one-joint-60kmh.wav`.** The first long preview accidentally changed the mix as well as the event schedule: coach-centre distance attenuation reduced per-axle impacts by 5.81–8.39 dB; rolling noise averaged 4.32 dB above the impact stem over seconds 1–36. `tools/analyze_lhb_previews.py` reconstructs/validates those stems within one PCM step, then compares the same uncontaminated first-axle 80 ms: level-matched correlation 0.9999996, median spectral difference 0.0033 dB. This is a level/masking problem, not lost kernel timbre. Equal-scale spectrograms and measured results are `.local/audio-preview/spectrum-comparison.png` / `.json`. The `--reference-mix` preview restores the preferred dry impact level and reduces only the preview's rolling bed by 12 dB. Neither preview comparison changes the game's WAVs or live audio mix. Joint-layout selection is still unanswered; no 500 m or 26 m change has been applied to the game.
- The second axle was checked separately after removing the preceding axle's decay: 5.8145 dB quieter in the rejected mix, level-matched correlation 0.99999994 and median spectral difference 0.0015 dB. The corrected `lhb-one-coach-1km-jointed-26m-100kmh-reference-mix.wav` matches the preferred first-axle level to 0.0003 dB, puts steady impact energy 14.59 dB above the rolling bed, and peaks at -10.75 dBFS without clipping. Both compared originals are preserved with SHA-256 recorded in the analysis report. Plotting dependencies were installed only under ignored `.local/analysis-python/`; the game needs none of them.
- The user supplied **`TrainAudio.mp3`** and requested **00:55–01:00** as an actual onboard reference. The original is untouched and untracked, not packaged. FFmpeg extracted exactly five seconds to `.local/audio-preview/TrainAudio-55-60.wav`. `tools/analyze_train_recording.py` measures a dominant midband-envelope repeat near **0.938 s** (not a verified individual axle/joint interval or proof of speed). After matching total 80–8000 Hz power, the recording places **37.0%** in 350–1500 Hz versus the preferred dry sample's **20.0%**, and **4.85%** in 1500–6000 Hz versus **9.73%**. Midband transient contrast (95th-percentile minus median window level) is **6.05 dB** in the recording, **2.71 dB** in the rejected long preview, and **8.22 dB** in the corrected preview. The reference therefore supports stronger transient prominence, more midrange body and less high-frequency emphasis; whole-recording levels are not treated as calibrated loudness. Results/plots are `recording-55-60-analysis.json` / `.png` in the audio-preview folder. No new fit or waveform export was applied to the approved lab model.

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
