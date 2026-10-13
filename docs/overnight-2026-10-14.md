# Overnight visual fidelity and performance pass

User authorized sustained implementation through **at least 06:00 Asia/Singapore,
14 October 2026** (22:00 UTC, 13 October), followed by a validated downloadable
build. Started 02:05 local. Do not report completion before that minimum.
Continuation heartbeat: `overnight-train-game-visual-polish`, every 20 minutes;
disable only after the overnight work and publication are complete.

## Scope and order

1. Capture an unchanged native day/night and crowded baseline on the 780M.
2. Fix vegetation/trackside detail transitions, matched batch bounds and shadow
   continuity. Regress offset parts, rotations, negative cells and density settings.
3. Make streamed terrain replacements complete before presentation switches;
   bound memory and build/destruction work. Stress forward/backward travel,
   normal/high speed and world-origin shifts. Keep simulation independent.
4. Add convincing domestic/shop night windows and restrained local illumination,
   coordinated with the railway clock, deterministic occupancy and daytime
   appearance. Improve station/platform lighting where the native captures show
   deficits. Reuse source assets and preserve licences.
5. Measure native day/night and five occupied full formations. Use prolonged
   normal-speed streaming runs to exercise cache expiration and retirement.
6. Run headless regression tests, review screenshots and code, commit/push,
   then publish a new signed release/full ZIP and incremental update on the LAN.
   Check packaging/downloads without repeated distribution gameplay tests.

## Constraints

- Target: i9-13980HX, RTX 4090 Laptop 16 GB, 64 GB RAM. Development 780M timings
  are relative comparisons, never target-PC claims.
- Native R30 access violation remains undiagnosed without the user's dump.
  Do not call a visual fix a crash fix without evidence.
- Preserve timetable/save/checkpoint inputs and approved generated audio.
- No proactive subagents authorized. Scripts/background benchmarks are permitted.
- Existing user TrainAudio.mp3/import and TrainVideo.mp4 remain untouched.
- Prior release R30 must remain valid until its replacement is ready.

## Work ledger

- 02:05: confirmed clean tracked checkout at d3c66ad; read project guidance.
- 02:09: continuation scheduled; beginning native baseline captures.
- 02:26: baseline complete (23 native checks); matched LOD grouping/static bounds
  and stable cheap tree shadows implemented. Stable far terrain patches and
  complete-before-visible activation implemented; 577 headless and 108 native
  LOD checks passed. Source journey currently has zero coverage errors.
- Native source soak PID 15408, two x1 journeys (B012 then B011), about one hour;
  logs in `.local/overnight-2026-10-14/streaming-soak/`. Do not start a simultaneous
  isolated GPU benchmark. Normal-speed cache expiry is part of this check.
- 02:42: shared domestic window/shutter emission now follows the railway clock,
  with deterministic occupancy and matching distant masks. Fifteen geometry-based
  masks rebaked/imported. Added a pool of eight shadow-free porch lights plus
  instanced fixtures. All night changes remain **uncommitted WIP**, pending
  native visual checks and performance comparison. Four focused night-light
  tests pass; full suite still required after the final iteration.
- Streaming-stage commit a49dc3e pushed. The active one-hour soak loaded that
  stage before night work, so its result does not cover the new lighting.
- **02:54:39: the native soak crashed after 29 min / 29.6 km on B012**, approaching
  KZT (`KZT_PYD_M3`), x1, 88.56 km/h. No completed result. Windows Event1000:
  editor Godot4.7.2 timestamp6a826550, c0000005, RVA031c5fde, PID15408. This is
  a different binary from the user's release, so RVAs cannot be compared directly.
  Scenery coverage remained zero errors until termination. A headless import
  was running near this time; repeat with stable imports and captured exception
  before attributing the cause. Do not count the one-hour soak as passed.
- Import ran 02:54:17–02:54:36; exception was 02:54:39. This is a confound,
  not proof of cause. WER metadata retained locally in `crash-soak/`; its temporary
  minidump was already removed by Windows. New captured soak launched around
  02:58 in `captured-soak/` (PID in that folder). **Do not run any import or asset
  rebake during this run.** Attach verified Microsoft ProcDump after `ready`.
- Captured soak game PID14980, started02:58:42, ready30.5s. Microsoft-signed
  ProcDump attached after readiness; capture PID in `captured-soak/capture-pid.txt`.
  This run covers the current night lighting and consolidated tree shadows.
- Night native harness `tools/check_residential_night.gd`: 30 checks passed;
  close/day/night and distant masks inspected in `houses-v2/`. Source normal,
  roughness and metallic texture channels preserved. Shop glassware emission
  was then excluded and its masks rebaked/imported before the captured soak.
- Tree shadows now merge identical opaque authored LOD2 triangles into one
  position-only surface (`game/scenery_shadow.gd`). `tree-shadows/` captures
  compare source vs merged at60/120/220m: draws129→49,104→46,44→15. Image RMS
  difference0.059/0.045/0.008 on 0–255 scale. Original material-specific auto LOD
  and culling make the merged count~2% higher; harness expectation adjusted to
  an8% budget and must be rerun after the captured soak. Three unit tests pass.
- Full suite after initial night code passed581; current shadow addition brings
  expected total582. Full suite needed before committing the current stage.
- Possible next performance experiment: consolidate constant-colour opaque tree
  materials into vertex colour/roughness, keeping textured surfaces and automatic
  LOD indices. No implementation yet. Source Godot4.7.2 `mesh.cpp` is in `.local/`
  for API verification; `_get_surfaces` exposes paired threshold/index-buffer
  LODs, index stride via `RenderingServer.mesh_surface_get_format_index_stride`.
  Test exact native appearance before changing production assets. Imports remain
  prohibited during captured soak. Consider this optional; stability is priority.

## Active processes and outputs

- Baseline day/night: `.local/overnight-2026-10-14/baseline/`; process identity
  recorded in that directory when launched. Check it before starting another
  graphics benchmark; do not overlap GPU measurements.

## Remaining / handoff

Finish native night-house review, compare day/night and occupied-train performance,
extend fast/reverse streaming checks, run the full suite, commit/push and publish
after the 06:00 minimum. Record concrete results here as they complete.
