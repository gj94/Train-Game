# Multicore railway simulation experiment

The simulation can distribute per-train passenger exchange and AI look-ahead
across Godot's CPU worker pool. This is actual parallel work inside one railway,
in addition to the dedicated skip/UI thread described in `threaded-skip.md`.

It is opt-in. The gain is small and depends on the workload on the development
laptop; the ordinary serial path remains the default. Use the measured result
for this workload, not CPU core count, to choose a strategy.

## Enable and compare

From the source checkout:

```powershell
& .local/godot/Godot_v4.7.2-stable_win64_console.exe --path . -- --simulation-workers=4
```

`--simulation-workers=0` selects the default serial path, `1` performs the same
preparation without pool scheduling, and `2`–`8` requests that many pool tasks.
The game caps the request at eight and, when possible, at the logical processor
count minus two. This setting applies to ordinary simulation and skip, and
is deliberately not saved as part of the railway state.

The reproducible rendering-free comparison is:

```powershell
& .local/godot/Godot_v4.7.2-stable_win64_console.exe --headless --path . --script res://tools/benchmark_parallel_sim.gd -- --seconds=60 --workers=0,4,8,0 --output=res://.local/parallel-sim-60s.json
& .local/godot/Godot_v4.7.2-stable_win64_console.exe --headless --path . --script res://tools/benchmark_parallel_sim.gd -- --sim-seconds=600 --workers=0,1,2,4,8 --output=res://.local/parallel-sim-fixed.json
```

The first invocation creates a 09:00 checkpoint from the same all-AI 100-service
timetable. Later invocations restore `.local/parallel-sim-checkpoint.bin` before
each run, validating its layout signature. Remove that benchmark checkpoint to
regenerate it after timetable/layout changes. Keep other games, editor imports
and simulation audits closed during measurement. All modes use identical 0.2 s
batches and 50 ms physics slices; initialization and a common 0.2 s warm prefix
are outside the timer. Worker scheduling and joining are inside the timer.

Wall-budget runs measure progress, so their final railway states naturally differ.
Fixed-simulation-duration runs compare complete snapshots exactly. Both fail on
safety events or zero progress. Thread IDs are sampled only during the warm prefix;
several IDs prove pool execution, not that all those threads ran simultaneously.
At most the requested number of group tasks execute for a slice.

## Measurements

Measured on 11 October 2026, Godot 4.7.2, Ryzen 7 7840HS (8 cores / 16 logical
processors). No other game, import or simulation audit ran during the timed tests.
These are **development-PC, rendering-free simulation results**, not game FPS or
measurements on the target i9-13980HX / RTX 4090 Laptop / 64 GB machine.

The final 60-second tests restored the same 100-service 09:00 checkpoint each
time (12 trains active initially, 17 at each finish), in the order shown:

| Strategy | Wall seconds | World seconds advanced | Simulation rate |
| --- | ---: | ---: | ---: |
| Serial control | 60.002820 | 2,156.2 | 35.93× |
| Four pool workers | 60.001740 | 2,213.8 | 36.90× |
| Eight pool workers | 60.002880 | 2,181.2 | 36.35× |
| Serial control repeated | 60.002807 | 2,121.8 | 35.36× |

Four workers achieved **2.67%–4.34% more throughput** than the two serial controls,
about **3.50%** versus their average. Eight workers gained less. All four runs had
zero safety events. The shorter equal-600-second comparison, however, gave serial
43.85× and four workers 43.55×: slightly slower with the pool. This is not a large
or universal multicore speedup, and does not justify enabling it for every frame
or extrapolating to the target laptop. The shipped download is unchanged.

The 600-second replay compared **exactly equal complete saved railway states**
with 0, 1, 2, 4 and 8 workers, including the single-thread preparation control.
A longer replay reversed the order (four workers first, then serial) and advanced
both worlds through 2,400 seconds to 09:40. It again produced exactly equal full
snapshots and zero safety events. Four workers took **64.877152 s (36.99×)**;
serial took **68.681812 s (34.94×)**, a **5.86% throughput gain** in that sample.
Reproduce it with `--sim-seconds=2400 --workers=4,0`.
Raw final measurements and source hashes are in
[`art/performance/parallel-simulation-2026-10-11/`](../art/performance/parallel-simulation-2026-10-11/).

## Ownership and ordered decisions

1. The simulation owner updates service entry, dispatch and automatic signals.
2. A barrier freezes movement, topology and railway authority while worker tasks
   process separate trains. Each task owns only its train's passenger data and a
   preallocated output slot. Static track/signal positions are read-only.
3. Tasks compute speed-restriction braking envelopes, buffer/next-signal distances,
   candidate signal positions and the track segments to check for obstruction.
   They never cache signal aspects or occupancy.
   Passenger exchange returns a proposed timetable release time without writing
   it to the timetable early. No-op waiting trains stay on the inexpensive path.
4. Join every pool task before resuming the original train order. Commit each
   passenger release at its original turn, run depot decisions, recheck **live**
   signal aspects and obstructions, drive and move that train, then update its
   occupancy and timetable. Discard prepared geometry if an earlier movement
   changes a point setting. Release routes after all trains have moved.

This preserves the important rule that a later train sees earlier trains' new
occupancy. Dispatch, route locks, depot allocation and movement are intentionally
ordered. Arbitrarily running those mutations concurrently would require a new
conflict-resolution model, rather than simply adding threads to the current loop.

The pool helper drops its world/train references at the barrier to avoid reference
cycles. Skip cancellation joins its owner thread, which first completes any active
pool group. Presentation must still respect the existing exclusive skip ownership.
There are no scene, rendering or audio calls in these tasks.

Godot documents the relevant API and the cost of splitting small jobs in
[WorkerThreadPool](https://docs.godotengine.org/en/stable/classes/class_workerthreadpool.html).
The current tasks are short and must synchronize twenty times per world second.
Scheduling, preparing extra look-ahead data and the remaining ordered work can
absorb the savings. Adding more workers alone is not a solution to that overhead.

## Playtest

Validation completed with **550 headless tests passing** under
`--simulation-workers=4`, plus **32 native source-game skip checks** and a clean
project import. The native checks cover the pool inside the dedicated skip
worker, responsive controls, completion, cancellation, disconnect and scene
teardown. They use Dummy audio and verify mute/restoration state rather than
audible playback. Raw logs and test timings accompany the benchmark evidence.

Launch with four workers. Open Pause → Skip to time / future stop; advance 30
minutes, cancel with B/Esc, then resume or take over. Repeat with Next stop and
verify actual arrival. Try a controller disconnection or window close mid-skip.
Watch a busy station under AI, save/load and resume; signals, passenger dwell and
depot departures should behave as with zero workers. Report benchmark results
separately from frame rate and identify the machine used.
