# R28 operating-day evidence

Tested simulation code: `4cbb726` on `codex/port-indian-rail-assets`.
Raw simulation-tree SHA-256:
`8d005da082ab9cf4ac21bea656eb3d052caf640b8fc6c249e106b33e9b43058c`.

`baseline.json` and `delay.json` are fresh, complete runs of
`tools/check_busy_timetable.gd`; neither resumes a checkpoint. The delayed run
holds K1 manually until 600 simulation seconds, then returns it to AI. All other
trains use normal AI and dynamic dispatch. Two-second audit requests execute the
ordinary 50 ms physics slices. No geometry, safety or speed-limit shortcuts.

Both runs finish at day 2 03:16:56: 100 origin departures, all 1,530 subsequent
calls and 100 services fully stabled. Zero safety events. Peak active passenger
workings: 23. Median non-negative final lateness: 0.00 min; p95: 17.58 min;
maximum: 32.70 min (B015). Maximum continuous extra wait: 28.17 min (B013).
K1's longest extra stand is 28.03 min.

K1 departs at 08:00:44.95 / 08:10:00.10. The initial delay is absorbed during
early calls and later traffic converges. Both runs record K1 overtaken by B001
at MAKM, B024 at STKT and B002 at NYY. These decisions are not scripted.

`completed_calls` excludes the origin and must equal `calls - 1`. Every origin
has a recorded departure. `max_wait_seconds` measures continuous stationary
delay after booked/passenger release; early-arrival dwell is excluded. Final
arrival delay is clamped at zero for early arrivals. The quality gate rejects
extra waits over 30 minutes, incomplete calls, safety events or unfinished depots.

Raw per-service times, booked calls, waits, dispatch history and source hash are
in the JSON reports; `summary.json` gives aggregates. The logs retain audit
progress. Headless tests: 517 passed, zero failures. Test timing data is included.
Five Node download-catalogue tests also passed before publication.

Audits ran concurrently on the development PC (43.61 / 45.29 wall minutes),
not as a controlled performance comparison or a target RTX 4090 Laptop graphics
benchmark. No extracted-distribution gameplay test was run. Manual driving and
edited timetables can produce different outcomes.

`release.json` records the published R28 ZIP, signature/LAN checks and old-build
cleanup. The two guide report copies inside the immutable R28 ZIP were rewritten
by an intermediate serializer and contain `Infinity` for absent signal distances.
The repository copies preserve the original Godot JSON (`1e99999`); use these
copies with strict JSON parsers. All measured timetable fields are unchanged.
