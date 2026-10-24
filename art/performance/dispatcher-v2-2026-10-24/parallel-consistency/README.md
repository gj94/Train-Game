# Prepared-day planner consistency

All **233** certified Standard V2 five-minute states passed **699** comparisons:
inline planning versus one, two and four workers at each state. Each result has
identical proposals, captured participant inputs, occupied roads and claims.
Detached inputs and the restored railway remain byte-identical after planning.
Nonempty work groups ran outside the caller thread. Empty states are included.

The audit verified 4,833 source fingerprints and every checkpoint checksum. The
maximum active planning population was 23 trains. Across the sampled states it
observed 154 northbound and 144 southbound proposals: 246 following-order and
52 passing proposals. These are repeated observations, not unique encounters or
completed overtakes. The full report retains every state hash and worker result.

This is a read-only determinism audit. It does not advance the railway, regenerate
the timetable, prove all live asynchronous acceptance orders identical, measure
performance or replace safety/full-day completion tests. Four independent
Intensive replay processes were running concurrently; no throughput claim is made.
The prepared Standard results and their existing native checks were not repeated.

`run.err` is empty. A separate negative check against the Classic timeline exits
1 with “Expected a certified V2 timeline” and creates no accepted report.
`verification.json` records the diagnostic's source fingerprint and these checks.

Reproduce from the source project with an existing writable output folder:

```powershell
& .local/godot/Godot_v4.7.2-stable_win64_console.exe --headless --path . --script res://tools/audit_forecast_parallel_consistency.gd -- --directory=res://data/timetables/standard_v2/times --output=res://.local/parallel-consistency.json
```

No new gameplay needs checking for this diagnostic. For the related operator
guide, choose a V2 Standard journey, inspect Forecast details, then use Journey
tools to change planner mode: the train positions and authored departure times
must stay unchanged. Intensive UI checks remain pending its completed audit.
