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
- House window masks generated but need refinement: TF3 glass is often just a
  tiny lens; homes have wooden shutters. `game/night_windows.gd`, its shader,
  tests, `tools/bake_night_windows.gd` and 15 mask PNGs are **uncommitted WIP**.
  Night materials are not wired into the game yet. Implement shutter/porch
  lighting and proper distant masks before evaluating them.

## Active processes and outputs

- Baseline day/night: `.local/overnight-2026-10-14/baseline/`; process identity
  recorded in that directory when launched. Check it before starting another
  graphics benchmark; do not overlap GPU measurements.

## Remaining / handoff

All implementation, before/after measurement, extended streaming validation and
release publication still pending. Record concrete results here as they complete.
