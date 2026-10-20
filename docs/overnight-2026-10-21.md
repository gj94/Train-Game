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
  use global chainage, but wires use edge-local spacing; investigate and
  correct this mismatch without changing simulation track geometry.

## Evidence and handoff

Record changed files, running process/session IDs, visual locations and measured
results here as work proceeds. Reuse completed work and do not rerun full-day
simulations on heartbeat continuation.
