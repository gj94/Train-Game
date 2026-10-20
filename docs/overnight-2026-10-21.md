# Overnight graphics and updater work — 21 October 2026

User-authorized work began at **01:07:24 Asia/Singapore**. Work for at least
three hours; the earliest publication/completion is **04:07:24 Singapore
(20 October 2026 20:07:24 UTC)**. R39 was published after 04:41; final archive,
LAN and retirement checks completed after 04:42. The continuation heartbeat
is now **paused**.

## Completed release

- R39, source **3ed0761**, signed sequence **41**, full ZIP and incremental
  support at http://192.168.8.183:8765/. Source changes pushed.
- Final suite: **708 passed**; 57 updater checks; whole-route OHE and road
  geometry audits; source streaming/station/bridge/sky views. No full-day
  timetable rerun and no extracted-distribution gameplay test.
- ZIP **3,584,596,626 bytes**, SHA-256
  `e28b070a84faecceeb16b069aef08bb030aefef819387bd57160c86c808ad0cc`.
  All 506 CRCs, 504 managed hashes, pack inventory, prepared-state hashes,
  signatures, legacy v3 verification and served LAN ranges passed.
- Verified R38 export/ZIP/checksum retired, freeing **7,831,411,720 bytes**.
  Historical signed catalogues retained. New server PID9568.
- Evidence: `art/performance/overnight-2026-10-21/`,
  `art/performance/updater-v4-2026-10-21/`,
  `art/performance/r39-release-2026-10-21/`.
- Next release requires a fresh name and sequence **42+**. Existing users
  replace the small launcher once to get v4's faster transfer code.

## Scope and constraints

- Complete the in-progress updater fix: batch downloads, bounded parallelism,
  consolidated resumable cache, measured comparison against shipped v3.
- Repair discontinuous overhead-wire shadows and unsupported/floating
  attachment arms. Audit rendering across loading/LOD boundaries.
- Make roads and scenery consistent around stations and waterways; roads must
  have deliberate crossings/bridges rather than intersect platforms or water.
- Preserve simulation/rail topology, timetable inputs, approved sound and user
  files. **Do not rerun timetable rehearsals**: the user explicitly excluded them
  for this graphical work. Run relevant graphics/updater regression checks.
- Use Godot MCP for live editor/scene changes, scripts for procedural fixes,
  and background processes for any Blender work.
- Target is i9-13980HX / RTX 4090 Laptop 16 GB / 64 GB. Development Radeon 780M
  results are relative measurements, not target-PC FPS.
- Announce build preparation, then publish a new full ZIP plus incremental
  support after the minimum time and successful validation. No repeated
  distribution gameplay test. Commit/push changes and record playtest steps.

## Initial state and chronological checkpoints

- Live release remains R38, sequence 40, source `885dc17`; next sequence is 41.
- Updater source is complete in `tools/updater/UpdateCore.cs` and
  `tools/updater/test.mjs`. V4 reads existing v1-v3 catalogues/cache files.
  No launcher or server has been deployed. Existing installed launchers will
  need the small refreshed launcher when this ships; a running launcher is not
  self-overwritten.
- All 57 native updater checks and 684 headless game checks pass. The private
  GUI launcher compiles. The 32 MiB comparison used 513 → 9 requests and
  7.67 → 0.71 seconds (local disk/loopback, not target-PC LAN). With 5 ms
  injected request latency: 17.29 → 0.66 seconds. Evidence is under
  `art/performance/updater-v4-2026-10-21/`.
- Graphics inspection and evidence collection follow the updater commit.
- Godot editor PID 19372 is connected to MCP. Overhead supports currently
  connected. Updater committed/pushed as `65e30b1`.
- Overhead layout now shares shifted global rows, clips continuous spans
  across chunks and connects both contact/messenger attachments. Whole route:
  5,124 rows, 8,456 safe posts, 2,955 wire chunks, 2,153 seamless boundaries,
  11,936 registrations; zero audit failures. Ten focused tests pass.
  Invisible 40 mm shadow geometry replaces the 12 mm wire's shadow draw;
  the visible wire remains 12 mm. Native before/after fixtures collected.
- Road changes are uncommitted and undergoing validation: connected offline
  OSM/SRTM bridge/approach profiles (`tools/maps/road_surfaces.py` → render-only
  `assets/models/scenery/road-surfaces.json`), whole-ribbon station/platform
  clipping, water/hole-aware clipping, closed decks and clear piers, retained
  low approaches and open high approaches. Covered streams no longer render
  through roads. Station access rejects open canals and actual running tracks.
  Eleven road tests, three Python tests and seven station tests pass.
- Native four-location captures exist in `.local/scenery-roads-before*` and
  `after*`; the initial after run exposed solid high approaches over the yard,
  now corrected but needs new capture. Full source rendering only, no
  distribution launches. Do not claim the first after images are final.
- Road profile regeneration is exec session 94310, log
  `.local/road-surfaces-build.log`. Context generator:
  `tools/export_scenery_context.gd` → `.local/scenery-context.json`.
  Next: actual generated triangle audit with `check_road_render_geometry.gd`,
  source visuals/performance and longer paused-railway streaming checks.
- Editor auto-detected two trackside texture imports on opening; restore only
  these known editor-generated `.png.import` changes before final source
  commit unless deliberately validated. Preserve unrelated user `.import`s.

### 18:20 UTC checkpoint

- Updater commit `65e30b1` is pushed; no release has been published. R38 stays live.
- Full graphics suite rerun passed **701/701** after a first run had cached the
  scenery script before the final siding member was added. Subsequent small
  fixes have focused checks; run the final suite again before the source commit.
- The native one-hour camera-only soak is PID **15968**, output
  `.local/graphics-soak-final-2026-10-21/`, started around 17:55 UTC.
  ERS sweep/reversal completed; QLN is running. Zero missing near tracks/OHE
  and zero terrain coverage errors so far. This run predates the later long-arm,
  station-access, water-edge and asphalt-UV refinements below. It remains useful
  streaming evidence but must not be labelled the exact final source.
- Follow it with final-source native captures and a station tour, including
  dusk/night, all station entrances and the changed bridge approaches.
- OHE audit exposed 139 arms exceeding the chosen 6.5 m visual reach; those
  rows now use supported gantries. Final static audit: 5,124 rows, 8,456 posts,
  **1,083 gantries**, 11,936 connected registrations, zero failures.
  Eleven focused OHE checks pass.
- Station approach audit exposed six height mismatches, including entrances
  below the new ERS flyovers. Precinct construction now installs all grading
  first, uses the actual railway ground and road profiles, and rejects links
  to raised approaches/tunnels. **49 retained links, zero height failures**;
  seven precinct tests pass.
- Whole-corridor road export covered 4,305 tiles, 2,306,772 triangles including
  shoulders/paint, and 1,134 piers. Independent audit found one 0.112 m² wet
  approach corner lacking clearance. Generator now protects full deck width
  at skewed banks; 19 vertex constraints, **23,972 profile segments**.
  Final whole-corridor export is exec session **8815**, log
  `.local/road-corridor-final-export.log`, output
  `.local/road-corridor-final-triangles.jsonl`. Run the Shapely audit when done.
- Profile rebuild for final source hashes is exec session **62494**, log
  `.local/road-surfaces-final-source-build.log`. Four Python tests pass.
  `verify-road-surfaces.mjs` checks static context, 1,793 input hashes and tile
  inventory during export; four gate tests pass. It does not step the railway.
- Asphalt now has separate absolute texture and across-road dust coordinates;
  station asphalt includes the rebase origin. This prevents texture-phase
  jumps and uniform edge dust. Thirteen focused road tests pass.
- Download page explains the one-time small v4 launcher replacement only for
  publications advertising updaterVersion 4; seven catalogue tests pass.

### 18:45 UTC checkpoint

- Final headless suite: **705 passed, 0 failed**. No full-day timetables run.
- Expanded audit found mid-height road fragments intersecting widened railway
  yards. Bridge approaches now account for all rendered roads and OHE, use open
  piers where raised, and propagate connected grades to convergence. Ten
  refinement rounds, 29,266 profile segments, 2,330,041 bytes. Unresolved ground
  fragments are clipped from the train envelope; underground paths and mapped
  platform stairways are not redrawn as ordinary roads.
- Final independent geometry audit passes: 4,305 exported tiles, 1,074 with
  road geometry, 2,257,858 triangles, 9,314 rail-height intersection checks,
  1,899 piers. Zero station, open-water, railway-height or pier/OHE conflicts.
  Logs: `.local/road-clearance-{export,audit}.log`, audit JSON of same stem.
- Static entrance check now retains **50 links, zero height failures**.
- Road profile freshness passes. Five Python geometry tests, four release-gate
  tests and seven download-page checks pass. The release guard verifies 1,793
  source inputs and the scenery tile inventory without advancing the railway.
- The one-hour native moving-camera soak is still PID 15968, now in TVC at
  night, with no missing nearby track/OHE or terrain coverage errors. Its
  loaded code predates the last refinements; follow with final-source captures
  and the station tour before committing.

### 19:10 UTC checkpoint

- Final runtime code now passes **705/705** headless checks again after the
  road CPU optimization. Full-day timetables remain untouched.
- Early rejection of off-corridor road segments avoids unnecessary terrain
  and profile queries. All 4,305 exported tiles remain **byte-identical** to
  the audited geometry (SHA-256 `db8e04c7f676650b3761af3a29bd6063b38679c9c5b25b852bf63597266a0af6`).
  Road profiles regenerated and freshness gate passed.
- Interleaved 90-tile, three-pass road CPU profile: R38 median 28.7 ms,
  final 66.2 ms (before optimization 84.9 ms). More complete road/deck geometry
  costs more to construct than old flat ribbons; it stays on scenery workers.
  Median material surfaces remain three. This is not an FPS gain claim.
- Moving-camera soak completed: 3,742 seconds, 360 coverage samples,
  115 rebases, zero missing near-track/OHE and terrain errors; world released.
  See `art/performance/overnight-2026-10-21/README.md` for the source-version
  qualification and detailed evidence.
- Final native ERS/KUMM/QLN/TVC captures and OHE fixture complete. The full
  frozen-railway station tour is PID **17816**, exec queue session **56528**,
  output `.local/station-scenery-final-2026-10-21/`; currently around TUVR,
  no coverage errors. It holds scenes for 40 minutes plus loading time.
- Next: inspect station captures as generated, check OHE at lower shadow
  resolution/other sun angles, finish evidence/docs, commit/push, announce
  build preparation and publish R39/sequence 41 **after 20:07:24 UTC**.
  Publication audit scripts are prepared in `.local/r39-release/`.

### 19:25 UTC checkpoint

- Commit **55ebfec** (OHE/roads, initial evidence) is pushed. R38 is still live.
- Close inspection found OSM station footbridges also rendered as asphalt
  bridge decks after the modelled station civil works. New refinement excludes
  **20 pedestrian bridge ways at 14 stations**, retaining public road bridges.
  This is not a simulation or station-track-count change.
- Regenerated profiles: **28,994 segments, 2,311,087 bytes**; freshness passes.
  Six Python geometry checks and eleven Node release/download checks pass.
  Current static audit: 4,305 tiles, **2,257,481 triangles, 9,177 rail-height
  checks, 1,883 piers**, zero conflicts. Station links: **51**, zero height
  failures. Logs `.local/road-final-{export,audit}.log`, `.local/road-final-audit.json`.
- Final headless suite with the new walkway regression is session **91238**,
  log `.local/r39-final-headless.log`, still running (no reported failures).
  Previous optimized source passed 705; expected new total 706.
- Full 56-station native tour is still PID **17816**, queue **56528**, around
  KPY with no coverage errors. It loaded **55ebfec**, before walkway cleanup.
  Queue **15661** waits for it, then launches the final-source 14-station
  tour to `.local/station-walkways-final-2026-10-21/`. Affected codes are in
  `.local/r39-affected-stations.txt`. Do not duplicate these processes.
- Morning/afternoon/evening OHE captures at 2048/4096/8192 completed without
  runtime/shader errors. Low-resolution/far thin shadows can still alias.
- `tools/capture_road_structures.gd` parses, but its four explicit public-road
  bridge cases still need a native run **after** the tours (avoid competing
  full-world GPU runs). Cases `.local/r39-road-views.json` were prepared by
  `.local/prepare-road-views.py`; use output `.local/road-structures-final`.
- Before release: update final evidence/counts/docs, import the new capture
  tool UID, commit/push the walkway refinement and evidence, update the
  read-only mount audit's profile count from 29,266 to 28,994, announce build
  preparation, then publish **R39 sequence 41 after 20:07:24 UTC**.
- Legacy v3 catalogue verifier is compiled in `.local/r39-release/VerifyOnly.exe`;
  it must verify the actual R39 signed catalogue after publication. The
  archive/publication/mount/retirement audit scripts are in the same folder.
  Old R38 ZIP SHA-256 in retirement script was checked against its live checksum.
- Heartbeat was read, remains ACTIVE; pause only after successful publication.

## Evidence and handoff

### 19:44 UTC checkpoint

- Final road refinement passed **706/706** tests. Shader refinement now has
  a fresh suite running in exec **71760**, `.local/r39-final-headless-sky.log`.
- The full station tour continues as PID **17816**, now around Kazhakuttam.
  The affected 14-station tour still waits in exec **15661**; it will load the
  final walkway and sky changes automatically when the first tour exits.
- Visual review found a dashed line in the Kollam sky. A pure-sky reproduction
  proved it was panorama filtering across the longitude wrap, not geometry.
  Corrected wrapped derivatives before `textureGrad`; native before/after
  confirms removal. Nine morning/afternoon/night and FOV captures are running
  in exec **57680**, output `.local/sky-seam-final/`.
- `tools/capture_sky_seam.gd` is the reusable reproduction. Temporary
  `.local/capture-qln-sky.gd` and texture inspection files remain diagnostics.
- `tools/soak_station_scenery.gd` retains only the useful optional station filter;
  the temporary sky/ray diagnostic was removed before the queued tour starts.
- Headless editor import previously completed successfully; import again for
  the new sky capture tool UID before the source commit. Road profiles remain
  final at 28,994 segments / 20 omitted duplicate pedestrian bridge ways.
- R38 still live; R39 publication remains after **20:07:24 UTC** and final QA.

Record changed files, running process/session IDs, visual locations and measured
results here as work proceeds. Reuse completed work and do not rerun full-day
simulations on heartbeat continuation.

### 20:03 UTC checkpoint

- Full native tour completed successfully: **56 stations, 280 samples,
  3,704.621 seconds**, zero coverage/near-track errors; released world,
  432,670,316 bytes Godot heap after returning to menu. PID17816/exec56528 ended.
- Final-source 14-station follow-up now runs as **PID10880**, queue **15661**,
  output `.local/station-walkways-final-2026-10-21/`. Wait for this before
  launching the full-world public-road bridge capture.
- Final headless suite after the sky fix: **706 passed, zero failed**.
  Log `.local/r39-final-headless-sky.log`, copied to evidence. Exec71760 ended.
- Nine native sky/FOV cases passed without errors. The before/after image
  difference is confined to the seam: 1,245 pixels change by more than 8/255,
  zero outside its strip. Images/JSON copied to the overnight evidence folder.
- Final headless editor import completed (exec85016); both new capture tool
  UIDs exist, and no tracked `.import` files changed.
- Next: finish affected tour, run `capture_road_structures.gd`, inspect its
  eight views, then run `.local/collect-r39-visual-evidence.py`. It asserts
  56/14 station results and four bridge cases before collecting evidence.
- `.local/finalize-r39-docs.py` is prepared for **after** actual successful
  publication/retirement; reads real sizes, hashes and delta statistics.
- Minimum publication time still **20:07:24 UTC**; final QA comes first.
- Public-road captures are now queued in exec **67784** using
  `.local/road-structures-final-queue.ps1`. It waits for PID10880, checks the
  affected-station result, then runs `capture_road_structures.gd` automatically.
  Do not launch a duplicate. The 20:07:24 minimum has now elapsed; QA remains
  the release gate.

### 20:25 UTC checkpoint

- The 14-station follow-up completed: 28 coverage samples, 643.985 seconds,
  zero errors/missing terrain and successful world release. This includes the
  walkway/sky corrections, before the junction refinement below.
- Close public bridge views exposed a guardrail across a same-level joining
  road at Kundannoor. Barrier openings now use the existing road-profile grid
  and actual relative heights; separate-level roads retain their barriers.
  Sixteen focused road checks pass, including the actual generated deck/rail.
- Profile regeneration completed in exec45635: unchanged 28,994 segments and
  twenty omitted walkway ways. The export freshness gate passes.
- Final unit suite runs in exec25328; revised bridge views in exec43062,
  PID18556, output `.local/road-structures-junctions-final/`.
  Minimum three-hour period has elapsed; publication follows successful QA.

### 20:32 UTC checkpoint

- All eight public bridge views completed; TVC exposed a generic building
  intersecting its flyover. Public-road corridors now exclude entire
  reconstructed building footprints before placement; tunnels and narrow paths
  do not. All eleven focused footprint checks pass.
- Final full unit suite restarted against this final source in exec28082.
  The preceding run loaded an older cached scenery script before the new
  footprint test appeared, so that mixed-source run is not release evidence.
- Final native bridge views run in exec26505, PID20532, output
  `.local/road-structures-release-final/`. TVC underside camera moves to the
  track side to avoid an unrelated wall obscuring the view.
- Barrier-junction generation has no measured paired CPU regression
  (83.60 to 82.44 ms median); road/shoulder/paint/pier geometry is byte-identical
  to the independent final clearance audit. Evidence collected in art.
- Expected final suite count: 708. Collect with
  `.local/collect-r39-visual-evidence.py` after the native bridge views finish.

### Final source gate

- Final full headless suite: 708 passed, zero failed. Final native public bridge
  captures: eight views, zero coverage errors, successful world release.
- TVC road/building collision confirmed removed in the final deck view.
- Source evidence collected. User notified before preparation of R39 sequence41.
- This gate was followed by successful export/publication, all archive and LAN
  checks, R38 retirement and heartbeat pause, recorded at the top of this file.
