# Stationary shadows, verge boards and bumpers — 20 October 2026

Source checks, not an exported-distribution playtest. Native GPU captures used
Radeon 780M; they are not RTX 4090 Laptop measurements.

- Sun update: fixed WAP-7 and external overhead casters, fixed camera, no streaming
  or animated foliage. 81 samples span 20 simulation seconds. Old sunlight moved
  in four five-second steps; new sunlight moves on every changed clock. Direction
  jumps are 20 times smaller at this sampling interval. Paused light stays exact.
  `shadow-comparison.json` includes image deltas: peak body-crop delta is lower,
  but mean delta is higher because change is continuous. This does not establish
  that all fine shadow shimmer or a paused-world artifact is eliminated.
- A comparison disabling contact-hardening did not improve shimmer and is not
  adopted. Existing shadow resolution, reach, softness and quality remain.
- The route has 713 posts rather than 1,058. Same-facing pairs within 8 m drop
  from 458 to six. The remaining pairs carry different release/caution/start
  meanings. Duplicate plates consolidate with road qualification; departure
  releases never move earlier and mixed boundaries stay fixed. Branch-depot
  warnings are kept off passenger approaches; through ACCESS warnings remain.
- `controller.log`: 73 native LHB/context checks pass. The compatibility-renderer
  warnings in stderr are expected SSA/SSIL limitations of that UI fixture.
  Driving RB reduces power; LB releases brake; both stop at coast, respect AI
  ownership and do not change headlights. Walking RB retains its torch action.
- **633 headless tests pass**. The guide and board-layout screenshots were
  visually inspected. Full-suite
  and prepared-state verification logs are recorded alongside this file.

Reproduce with `tools/check_stationary_shadows.gd`, `tools/check_speed_board_layout.gd`
and `tools/check_controller_qol.gd`. The old sunlight comparison is available by
saving `game/day_night.gd` from commit d726793 under `.local/` and passing its
res:// path with `--cycle=...` to the shadow fixture. The fixture samples fixed
clock increments and excludes wall-time capture delays; it is not an FPS test.

Playtest: at a stationary train beneath overhead equipment/trees, keep the camera
still as the clock runs, then pause. Shadows should advance gradually with time
and stop with it. Check ERS/ALLP/TVC yard boards and their road labels. In manual
pilot or follow view, hold RB with power applied, then LB with braking applied;
each should stop at coast. Repeat under AI and verify no takeover. Open Menu →
Controller layout → Driving to see the revised bindings.

The existing R34 download has not been replaced by this source update.
