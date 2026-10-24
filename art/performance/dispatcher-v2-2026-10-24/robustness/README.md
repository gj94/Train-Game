# Forecast robustness and Kollam scenery compatibility

The full source suite passes **953 tests with zero failures**, including the
final-call, manual-driver and newly eligible follower regressions. The focused
owner suite passes all fifteen tests; `source-tests.log` records the full run.
Whole-day validation remains separate and is not claimed by these fixtures.

## Timing sample

`arrival-calibration.json` records eight real AI single-train runs: ICF, LHB,
eight-car and sixteen-car Vande Bharat, each southbound and northbound between
KPY and QLN. Initial booked roads and roads actually selected by dispatch are
both recorded. Later decision forecasts are recaptured after each call or road
assignment change. The 32 same-road cautious forecasts differ from measured
arrival by -61.23 to +14.55 seconds. The implemented clearance uncertainty
covers these sampled errors with at least 26.49 seconds remaining. This is not
a guarantee for every speed, formation, signal delay or manual intervention.

The larger initial QLN discrepancy came from comparing an initial main-road
forecast against an actual terminal-loop arrival. The tool now makes that
distinction explicit rather than presenting it as a same-route timing error.
Forecasting beyond a final booked call is rejected.

## Manual changes and new traffic

`disruptions.json` records baseline, three/ten-minute manual passenger pauses,
a three-minute manual express pause and a three-minute operator express hold.
Both trains pass beyond STKT in each case without safety events. Maximum
continuous unbooked stands are approximately 3.7, 4.9, 4.6, 5.9 and 5.5 minutes.
The replay budget is thirty minutes plus the injected pause. Stopped manual
expresses have no assumed departure; a stopped manual passenger cannot be
certified for a future loop on assumed acceleration.

Owner regressions cover an express spawned after capture, a priority promotion,
a released operator hold and a released emergency. Each invalidates pending
and previously accepted advice. Unrelated lower-priority, opposing, ahead,
held, finished or dormant traffic does not by itself invalidate the plan.
The interlocking still owns all movement authority.

`async-live.json` additionally exercises the actual nonblocking worker path for
33 simulation minutes per case. The undisturbed pair completes its pass with K1
on STKT_P3. Pausing the passenger manually for two minutes changes the completed
pass to KPY_P1, reflecting its lost progress. Both clear STKT without safety
events, accepted proposals come from other threads, and shutdown joins cleanly.
No elapsed-time/FPS conclusion is drawn while other rehearsal jobs are running.

Reproduce from the repository root:

```powershell
& .local/godot/Godot_v4.7.2-stable_win64_console.exe --headless --path . --script res://tools/audit_predictive_timing.gd
& .local/godot/Godot_v4.7.2-stable_win64_console.exe --headless --path . --script res://tools/check_predictive_disruption.gd
& .local/godot/Godot_v4.7.2-stable_win64_console.exe --headless --path . --script res://tools/check_predictive_async.gd
& .local/godot/Godot_v4.7.2-stable_win64_console.exe --headless --path . --script res://tests/run_tests.gd -- --filter=test_predictive_dispatch
```

## Road profiles after the Kollam layout change

The render-only road cache was regenerated from fresh scenery context, not
merely given a new compatibility hash. Changed profiles affect 40 ways near
QLN. The independently checked vicinity includes 27 tiles with 228,437 actual
rendered triangles and 27 piers. No station, water, rail-height or pier/OHE
conflicts were found. Every road material emitted in this vicinity is audited.
The profile check covers all 353 prepared junctions with zero height difference;
122 rendered junctions in the affected area have 809 paired samples, maximum
height difference 0.00020 m and no one-sided holes. Reports are adjacent here.
This is geometry evidence, not an FPS or full-railway-performance measurement.
Four frozen native views at 140.74 and 141.5 km were reviewed with no script or
render errors. Two views and their complete capture report are included here;
the railway clock stayed at zero throughout.

Playtest after compatible states are installed: inspect Kollam's approaches and
both platform groups; compare V2 K1/B002 at KPY/STKT; hand control to/from AI
during the approach and verify that any new advice still respects red signals.
