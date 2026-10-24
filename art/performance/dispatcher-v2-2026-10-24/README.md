# Optional predictive dispatcher evidence

Foundation only: live dispatch does not yet use these proposals. No release or
prepared timetable has been changed at this checkpoint.

- Full source suite: **919 passed, 0 failed**. Local log:
  `.local/dispatcher-v2-2026-10-24/foundation-full-tests.log`.
- Sixteen focused new tests cover physical forecasts, receiving-loop capacity,
  occupied roads, competing expresses, copied worker input, task shutdown and
  equivalent synchronous/asynchronous proposals.
- `worker-benchmark.json`: 40 identical result sets (10 each inline / 1 / 2 / 4
  workers), 25 active trains, 706 topology edges; worker IDs differ from caller.
  Four-worker mean 10.14 ms versus inline 24.60 ms; input capture 3.13 ms and
  submission around 0.4 ms. This is task CPU time on the development machine,
  not game FPS or the user's RTX 4090 Laptop performance.
- `classic-k1-distribution.json`: 14 distinct overtakers at eight locations;
  five concentrated at Karunagappalli. Derived read-only from current Intensive
  prepared encounters, excluding cases where K1 overtakes someone else.

Reproduce the compute measurement from source:

```powershell
& .local/godot/Godot_v4.7.2-stable_win64_console.exe --headless --path . --script res://tools/benchmark_dispatch_forecast.gd
```

The real 11:40 K1/B002 forecast prefers STKT_P3 for K1 and STKT_P1 for B002.
No claim of live success until bounded movement tests and full operating-day
validation are complete. Continue with `docs/dispatcher-v2-work-2026-10-24.md`.

## Owner integration checkpoint, 24 October 23:35

Full source suite: **937 passed, 0 failed** (`owner-full-tests.log`). Live
proposals now pass owner-side freshness, participant, route-claim and competing
plan checks. Explicit following/overtaking comparisons measure predicted
priority-train lateness saved against lower-priority detention. Classic remains
the default; no home selector or new prepared day is delivered yet.

`order-live.json` records a 20-minute 11:35–11:55 replay of the original
Intensive state. K1 is not held for B002 at KPY; it takes STKT_P3 while B002
passes STKT_P1 above 20 m/s. No safety events. The original closely grouped
relief services still catch K1 there: this is not full-day distribution proof.
Reproduce with `tools/check_predictive_overtake.gd` on this geometry/state.

`order-worker-benchmark.json` repeats the equivalent-result benchmark after the
order comparison was added: inline 32.80 ms, one worker 33.69 ms, two 23.28 ms,
four 17.62 ms; capture 3.319 ms. Asynchronous live submission remains nonblocking.
Offline preparation/time skip joins four workers on its simulation owner.
Save/load and event rewind preserve validated plans; worker handles never enter
snapshots. A real 20-second skip matches the inline state exactly and restores
the live asynchronous strategy. These are development CPU timings, not FPS.
