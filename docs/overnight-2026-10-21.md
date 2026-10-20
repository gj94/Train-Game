# Overnight graphics and updater work — 21 October 2026

User-authorized work began at **01:07:24 Asia/Singapore**. Work for at least
three hours; the earliest publication/completion is **04:07:24 Singapore
(20 October 2026 20:07:24 UTC)**. The existing thread heartbeat is active every
twenty minutes as a continuation safeguard. Pause it after successful publication.

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

## Current state

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

## Evidence and handoff

Record changed files, running process/session IDs, visual locations and measured
results here as work proceeds. Reuse completed work and do not rerun full-day
simulations on heartbeat continuation.
