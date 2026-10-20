# Detailed audio and operating-day validation

Source changes are tested independently of rendering. This development machine
has a Radeon 780M; these results are not FPS measurements on the target
i9-13980HX / RTX 4090 Laptop.

- `tests.log` / `test-timings.json`: 684 headless tests, zero failures.
- `final-tests-*.log`: 23 additional checks after staging the new departure,
  timeline and traffic data, including operating-day save/restart metadata.
- `summary.json` and `standard-audit.json`, `intensive-audit.json`,
  `intensive_delayed-audit.json`: all three full days, all services/calls/depot
  clearances complete, zero safety events. All source fingerprints match the
  prepared baselines. Both meaningful-wait populations meet the requested
  distribution. The summary also exposes K1's less favourable individual
  distribution and each Standard service's destination-delay change from R37.
- `selector-ui-final.log`: 16 native checks, including D-pad access to the
  operating-day selector, departure loading, day identity and time browsing.
  The adjacent four menu screenshots were visually reviewed at 1280×720.
- `intensive-traffic-ui-final.log`: 5,592 checks over all 1,722 reciprocal
  Intensive encounter cards. K1 has 13 distinct baseline overtakers; B042
  never passes B002 back.
- `sound-menu.log`: 63 native mixer-menu reachability and navigation checks.
- `five-train-audio.log`: five rakes / 93 vehicles, independent native buses,
  output headroom, interior attenuation and pause. Uses the Dummy audio driver;
  this is a rendered audio-capture check, not a hardware listening test.
- `standard-menu.log`: R37's original 100-service preview before regenerating
  the operating days. It is retained as historical evidence.
- `standard-traffic-ui-final.log`: the freshly regenerated standard day,
  3,378 checks over all 1,024 reciprocal encounter cards, with all three roles.
- `tvcn-through-fresh.json`: both VBs from the new standard baseline use their
  mains. Preparation is 5.36 km ahead northbound and 5.38 km southbound; peak
  yard speeds are 82.8 and 87.5 km/h respectively under the 90 km/h line limit.
- `tvcn-through-r37-starts.json`: both Vande Bharats continued from R37 time
  states with the corrected route selector. They use TVCN_P2 northbound and
  TVCN_P1 southbound, prepared approximately 5.35 and 5.07 km ahead.
- `orphaned-crossing.bin`: the actual rejected 140-service candidate at 15:10,
  with D103 already stored after terminating at TVC but still promised at NEM.
  `tools/check_orphaned_crossing.gd` replays it without moving any train by hand.
  `orphaned-crossing-recovery.json` records cancellation of the unfulfilled
  virtual reservation and B096 leaving after 46 simulated seconds.
- `kzt-delayed.json`: the existing KZT forward-crossing fixture with a ten-minute
  manual delay. Full arrival protection, no circular wait, and home preparation
  4.41 km ahead remain intact after the new capacity checks.
- `turavur-before-cycle.bin` and `turavur-capacity.json`: the standard railway
  at 14:25 before the four-train cycle. With no traffic rearrangement, all four
  services clear their crossing stations; no safety events, longest continuous
  extra wait 1,642 seconds. Replay with `tools/check_turavur_capacity.gd`.
- `intensive_delayed-audit.json` and `intensive-delay-finalize.log`: the full
  140-service day with K1 manually braked from 13:00 to 13:10, then AI resumed.
  All 1,726 subsequent calls and depot clearances complete without safety
  events. Eighteen distinct trains overtake K1; B042 never passes B002 back.
  This full-day run does not set the dispatcher's player-assignment field.
- `manual-assignment-delay.json` / `.log`: a separate focused check does set
  `manual_service="K1"`, continuing the fresh 12:55 railway through 17:00 with
  the same ten-minute pause. K1 retains route preparation throughout the
  600-second manual pause, then advances 93.5 km. No safety events; longest
  continuous extra wait 26m22s. Reproduce with
  `tools/check_intensive_manual_delay.gd -- --baseline=res://data/timetables/intensive`.
  This is a focused intervention test, not another full-day baseline.

Failed timetable candidates are not release data. Full-day acceptance requires
every train to complete its calls and clear to depot, no safety events, and extra
waits meeting the user-approved cumulative distribution (70% under ten minutes,
90% under twenty, 98% under thirty, all under forty-five), and at least ten **distinct**
overtakers of the slowest service in the intensive baseline. Prepared snapshots
are restored and compared before publication. The two operating days retain
separate catalogues and traffic histories.

`wait-quality-tests.log` records four Node gate tests. Four matching Godot tests
are included in the full suite. The publication check recomputes the distribution
from recorded per-call/per-signal waits; the recorded passing flag alone is not
trusted. Booked dwell and explicit manual pauses are excluded; episodes below
30 seconds are reported separately and cannot dilute the percentile population.
The Godot JSON report was also read by the independent Node check, including
non-terminating fractional percentages.

`time-grid-tests.log` covers a validator regression found during finalization:
the simulated clock ended at 98400.0000000001 seconds, which an exact ceiling
mistook for the next five-minute block. The validator now tolerates only
sub-microsecond residue; real later samples still require the next state.
Four tests pass. Simulation clocks and saved snapshot bytes were not changed.
Scheduled-duration validation also tolerates sub-microsecond JSON subtraction
residue, while retaining exact snapshot hashes and the authored timings.

`operating-days-profile.json` records an isolated sequential CPU-only sample
at 12:05: 120 simulated seconds at 60 calls per second, after a one-second warm-up.
The development Ryzen 7 7840HS has 22 active trains in Standard and 32 in
Intensive. Median simulation-call time is 1.972 versus 2.537 ms; p99 is 8.598
versus 9.804 ms, with no safety events. This is the extra timetable's measured
simulation cost, not a renderer benchmark or an RTX 4090 Laptop FPS prediction.
