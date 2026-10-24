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
