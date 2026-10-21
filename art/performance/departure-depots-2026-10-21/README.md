# R42 departure and depot checks

Shared depot-access edges follow the adjoining running line. Only the chosen
branch lead and yard impose depot speed limits. AI passenger trains finish both
departure calls before applying power, including the player service handed to AI.
A previously allocated starter route cannot acquire a contradictory optional
priority hold that blocks its own intended overtaker.

- `headless-tests.txt`: 772 passing tests, zero failures.
- `test-timings.json`: per-test timings on the development PC.
- `native-horns.json`: production AudioStreamPlayer3D playback starts/stops with
  the actual simulation; own AI, other AI, manual-to-AI and 4x time scale pass.
  Dummy audio output: this checks native state, not subjective sound quality.
- `corridor-events.json`: fresh R42 morning checkpoints reproduce crossing and
  both overtake roles, returning 60 seconds before first physical overlap. A
  deliberately slowed VB produces a later pass and also replays correctly.
- `legacy-history.json`: three actual R41 checkpoints (standard morning/night,
  intensive morning) migrate, restore and replay exactly under R42. Train object
  identity is preserved; no safety events appear.
- `alappuzha-r41-before.bin` and `alappuzha-r41-trace.json`: published R41
  Intensive checkpoint and replay with the clean `ee75fa8` simulation. At
  09:59:37.55 a false circular-wait recovery cancels K1's B024 hold while K1 is
  still arriving. K1 then leaves at 10:02:43, just after B024 reaches its berth.
- `alappuzha-fixed.json`: replay under R42 distinguishes the current booked
  arrival from a departure wait. B024 departs first, K1 retains its hold through
  full tail clearance and onward receiving-capacity checks. No safety events.
  Reproduce with `tools/check_alappuzha_overtake.gd`.
- Four additional arrival/dispatch tests and the expanded 772-test suite pass.
  Fresh full-day baselines and the disturbed audit pass after this correction.

Reproduce the focused checks with `tests/run_tests.gd -- --filter=departure_sequence`,
`--filter=depot_speed_limits`, `--filter=journey_audio` and `--filter=overtake_commitment`.
Run `tools/check_departure_audio.gd --headless --audio-driver Dummy` with Godot.

Playtest a passenger departure with X handing driving to AI. Both calls should
finish before the train moves. Take back control during the pause and confirm
no automatic second call survives. Try a through service beside a depot junction
and compare the main-line limit with a train actually entering the depot lead.

## Complete R42 operating-day validation

- Standard: 100/100 services, 1,530 subsequent calls, zero safety events,
  all services cleared to depot. Longest continuous extra wait 28m16s.
- Intensive: 140/140 services, 1,726 subsequent calls, zero safety events,
  14 distinct K1 overtakers, no B042 reverse pass of B002.
- Disturbed Intensive: 140/140 finish after K1's ten-minute midday manual pause;
  zero safety events, 14 distinct K1 overtakers, no B042 reverse pass.
- Both station-only and combined meaningful-wait populations meet the requested
  cumulative 70/90/98/100 percent targets below 10/20/30/45 minutes in all runs.
- `standard-audit.json`, `intensive-audit.json`, `delayed-audit.json` and
  `summary.json` retain complete results, including lateness and every long call.
- `manual-delay.json`: separate player-assigned pause/recovery through 17:00,
  117.3 km progress, zero safety events. This focused diagnostic is
  separate from the full-day wait-distribution audit. It explicitly verifies
  a protected departure route while the player remains manually in control.
- `manual-delay-first-report.json`: the former test required route ownership
  during the forced pause, although ownership is only recorded when the train
  passes the signal. Its movement/recovery was safe; this assertion was invalid.
  The revised run records two seconds still arriving during the pause and
  explicitly probes the permissive starter while keeping manual control.
- `manual-route-owner-test-log.txt`: a second harness correction checks a
  permissive signal with an allocated route, rather than requiring the owner
  field before movement. Route ownership is recorded when the train passes the
  signal. No production simulation change was made for either harness correction.
- `history.json`: fresh R42 prepared states restore/replay exactly while keeping
  existing train objects. `legacy-history.json` covers actual R41 checkpoints.
- Rehearsal times on the development PC were 77.8,
  94.0 and 63.0 wall minutes respectively, with concurrent
  validation workloads. These are not target-PC frame-rate measurements.

Playtest Intensive K1 at Alappuzha around 10:00. Let B024 complete its pass;
K1 should retain its hold until the express clears and onward capacity permits
departure. The reference trace uses an R41 checkpoint, not a supplied player save.

Source-only service-browser checks also pass: 3,396 assertions / 1,030 traffic
cards in Standard, and 5,556 assertions / 1,710 cards in Intensive. The cards
include crossings and reciprocal overtaking / overtaken roles; controller Y
switches Stops/Traffic. See `standard-traffic-ui.txt` and
`intensive-traffic-ui.txt`. No extracted-distribution gameplay test was run.
The waiting policy is unchanged at the user's request.
