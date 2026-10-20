# Detailed audio and operating-day validation

Source changes are tested independently of rendering. This development machine
has a Radeon 780M; these results are not FPS measurements on the target
i9-13980HX / RTX 4090 Laptop.

- `tests.log` / `test-timings.json`: 674 headless tests, zero failures.
- `sound-menu.log`: 63 native mixer-menu reachability and navigation checks.
- `five-train-audio.log`: five rakes / 93 vehicles, independent native buses,
  output headroom, interior attenuation and pause. Uses the Dummy audio driver;
  this is a rendered audio-capture check, not a hardware listening test.
- `standard-menu.log`: R37's original 100-service preview before regenerating
  the operating days. It is retained as historical evidence.
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

Failed timetable candidates are not release data. Full-day acceptance requires
every train to complete its calls and clear to depot, no safety events, no
continuous extra wait over thirty minutes, and at least ten **distinct**
overtakers of the slowest service in the intensive baseline. Prepared snapshots
are restored and compared before publication. The two operating days retain
separate catalogues and traffic histories.
