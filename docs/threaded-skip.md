# Threaded skip forward

Skip to time / stop now runs the existing railway simulation on a dedicated CPU
thread. The main thread displays progress and handles keyboard, mouse and
controller cancellation. Normal driving is unchanged.

This removes the old 12 ms-per-frame simulation allowance. It does **not** divide
one railway across all CPU cores: dispatch, route reservations and train movement
still run in their original deterministic order on one worker. Each train must
see the preceding train's updated occupancy. Parallelising those mutations would
introduce conflicting authorities and change the timetable.

## Ownership and cancellation

- Pause the game, hide Dispatch, disable inherited scene processing/3D and mute
  audio. Keep the progress HUD, menu input router and skip coordinator alive.
- Wait asynchronously for any in-flight scenery jobs. They can read the live
  graph; their results stay queued until ordinary rendering resumes. Never block
  the render loop waiting for GPU uploads to finish.
- Give the worker exclusive access to the existing `RailWorld` and `Advance`.
  There is no save/load reconstruction or replacement of train objects. Caches,
  dispatcher commitments, passengers and presentation bindings retain identity.
- Publish only copied scalar progress through a mutex, at most every 100 ms;
  update the visible text every 200 ms. The UI never reads the worker's world.
- Cancel via a mutex-protected request, checked between the unchanged 0.2 s
  simulation batches (each contains 50 ms physics slices). Join on completion
  before any presentation/control code reads the railway again.
- Reject stale menu commands during ownership. Controller disconnection cancels;
  closing the window first cancels, then opens the normal quit confirmation.
  Scene teardown joins the worker and restores shared viewport/audio state.
- If the OS cannot create the worker, retain the original main-thread skip and
  display a notification. Protection events and actual-arrival stop targets still
  use the same `sim/time_skip.gd` logic in both paths.

Godot's [thread-safety guidance](https://docs.godotengine.org/en/stable/tutorials/performance/thread_safe_apis.html)
requires avoiding concurrent access to active scene state and mutable containers;
the worker contains no scene, rendering or audio calls.

## Reproduce the benchmark

Run on an otherwise idle machine, with no editor/import, game or other simulation
audit competing for CPU time:

```powershell
& .local/godot/Godot_v4.7.2-stable_win64_console.exe --headless --path . --script res://tools/benchmark_time_skip.gd -- --seconds=60 --output=res://.local/threaded-skip.json
```

The harness warms the 100-service all-AI railway from 08:00 to 09:00 outside the
measurement, then restores the **same checkpoint before every strategy**:

1. Original skip: 12 ms simulation allowance each frame, 60 FPS cap.
2. Threaded skip: continuous worker, main loop capped at the same 60 FPS.
3. Original skip with no frame cap, to expose the remaining serial CPU ceiling.

Each strategy gets 60 wall seconds, checked between complete simulation batches;
the recorded time includes small scheduling/cancellation overhead. The harness
then compares every saved railway field after an equal 600 simulated seconds on
serial and threaded paths. It uses the same 0.2 s batches for both; it does not
increase timestep size or omit trains, passengers, dispatch or safety checks.

This is a **headless comparison of skip scheduling**, not a rendered-game FPS
benchmark. Frame intervals describe main-loop responsiveness. The target playing
PC is an i9-13980HX / RTX 4090 Laptop / 64 GB; development-PC results must not be
presented as a measurement on that machine.

## Validation and playtest

Measured on 11 October 2026 with Godot 4.7.2, on the development PC's Ryzen 7
7840HS (8 cores / 16 logical processors). No other simulation audit ran during
the timed comparison. The checkpoint contains 100 services, 12 active at 09:00;
both capped runs end with 17 active services.

| Strategy | Actual wall time | World time advanced | Simulation rate | Main-loop p95 interval |
| --- | ---: | ---: | ---: | ---: |
| Original, 60 FPS cap | 60.009 s | 33m 12.6s | 33.21× | 19.084 ms |
| Worker, 60 FPS cap | 60.031 s | 36m 02.6s | 36.02× | 16.680 ms |
| Original, uncapped control | 60.001 s | 36m 28.8s | 36.48× | 19.114 ms |

The threaded path achieved **8.49% higher throughput** than the capped original,
advancing 170 additional world seconds during the roughly 60-second windows. It
reached 98.75% of the uncapped serial control's rate. This is a modest throughput
gain and a steadier progress loop, not an all-core simulation speedup. Do not
extrapolate this sample to a full operating day or the target i9 laptop.

All three runs recorded zero safety events. A separate equal-duration replay
from the same checkpoint produced **exactly equal full snapshots** after 600
simulated seconds: 15 active trains and 66 recorded arrivals at 09:10. Threaded
benchmark cancellation and join took 16.682 ms, including one UI polling frame.
Raw measurements and source hashes are in
[`art/performance/threaded-skip-2026-10-11/`](../art/performance/threaded-skip-2026-10-11/).

Pure tests cover complete-state equivalence, actual-arrival targets, midnight
service entry, safety intervention, cancellation, repeated use and worker shutdown.
`tools/check_time_skip.gd` exercises the actual game UI, controller navigation,
stale command rejection, disconnection, window close, same-train/platform return
and teardown: **30 checks passed** in the native source game. The full headless
suite passes **540 tests**, including six new skip-worker tests and the scenery
handoff regression. The automated native run
used the dummy audio driver and verified mute restoration, not audible playback.
Run the full headless suite before committing.

In the game, open **Pause → Skip to time / future stop**, advance 30 minutes and
watch the clock and progress rate. Cancel with **B/Esc**; verify you return paused
with AI still driving, then resume or take control. Repeat with **Next stop** and
confirm the train has actually arrived. Try controller disconnect or window close
during a skip; the railway should return safely before another menu opens.
