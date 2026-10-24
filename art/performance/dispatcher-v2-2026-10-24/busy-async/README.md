# Crowded live asynchronous V2 stress

25 October 2026, source 22340ae plus the read-only diagnostic in this increment.
The original complete-day replays were left running with unchanged inputs.

Restored the actual 12:35 Intensive 140 checkpoint, validated every frozen
railway input hash, and switched its detached copy to live asynchronous forecast
execution. Thirty simulated minutes included 30 active services at peak and five
new entries (B075, B004, B055, B032, B096). All 140 services remain in the railway.

The owner executed nine changes: manual K1 braking, return to AI, D101 hold and
release, D108 priority promotion and restoration, Classic then V2 selection,
and exact save/reload while a forecast group was pending. Switching mode left
movement authorities byte-identical; restoring the save preserved the complete
snapshot exactly and did not retain worker handles. The restored railway resumed
asynchronous forecasts. Every worker was closed before exit.

Result: no safety events or missed calls; K1 advanced 10.42 km, D101 27.75 km and
D108 22.74 km. The observer saw 346 accepted batches containing plans and forecast
work on non-owner threads. This count excludes completed empty/rejected results;
it is a functional activity check, not a worker-throughput benchmark. Five other
railway audits were competing for CPU and the observer deliberately yields 1 ms
per half-second step. The 181.65 s wall time is not target-PC performance.

All 18 focused owner regressions also pass with empty stderr. The preceding
full source suite passed 961 tests; runtime and test sources are unchanged.

Run from the source checkout with its compatible rehearsal states:

```powershell
.local/godot/Godot_v4.7.2-stable_win64_console.exe --headless --path . --script res://tools/check_predictive_busy_async.gd
```

Optional `--folder=res://...` and `--output=res://...` follow Godot's `--` separator.
The checkpoint is T045300; its SHA-256 is in result.json. This tool never writes
back to the source checkpoint or publishes/certifies a timetable. The underlying
v3 full-day preparation and its baseline encounter/wait gates are separate.

Playtest after the compatible data is installed: start V2 Intensive from 12:35,
assign K1, brake manually then hand driving to AI. In Operations briefly hold
D101, release it, change and restore D108 priority, and switch Classic/V2. Save
and reload while trains are moving. Your assigned service and mode should remain;
forecast advice should refresh without granting movement past a red signal.
