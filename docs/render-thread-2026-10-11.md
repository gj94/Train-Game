# Rendering thread investigation — 11 October 2026

The feedback based on `crowded-2026-10-10` correctly identified moving-train
presentation as a major CPU cost. Its scene counts describe that older capture,
and its component timings should not be added into a guaranteed target-PC FPS
prediction. Render/GPU samples can lag, different components can overlap, and
the development Radeon 780M is often GPU-limited.

## Correcting the measuring tool

The first separate-render-thread probe exposed a benchmark problem. Its two
per-frame viewport timing getters forced the main and render threads to synchronize.
Godot explicitly logged that these calls significantly affected performance. That
probe was stopped and is not valid performance evidence.

`game/render_telemetry.gd` now queues the timing reads with
[`RenderingServer.call_on_render_thread`](https://docs.godotengine.org/en/stable/classes/class_renderingserver.html#class-renderingserver-method-call-on-render-thread).
A mutex publishes only copied GPU/CPU timing numbers, with at most one callback
pending. Neither the benchmark nor F10 calls those viewport getters on the main
thread. Samples describe the last completed read and can lag the current frame;
wall-clock frame measurements remain the primary A/B measure. Teardown closes
the helper so queued work will not read a discarded viewport. Reports retain the
engine command line and explain the asynchronous timing collection.

This correction applies to both renderer modes. It does not hide engine warnings,
alter graphics quality, change the railway timestep or enable separate rendering
by default. Godot's
[thread-safety documentation](https://docs.godotengine.org/en/stable/tutorials/performance/thread_safe_apis.html#rendering)
still identifies known bugs in the separate renderer mode.

## Corrected native A/B

Two completed source-game runs used Godot 4.7.2 / Vulkan Forward+, the development
Ryzen 7 7840HS / Radeon 780M, High settings and **actual 1600 × 900 captures**.
Separate mode ran first, safe mode second, without overlapping games, imports or
simulation audits. Both used the corrected timing collector, serial simulation
and Dummy audio. No target i9 / RTX 4090 Laptop measurement is implied.

The fixture retained five trains, 91 vehicles and 5,580 simulated passengers.
Each view passed the existing report auditor; the compared cases had zero loading
or unfocused frames. Median wall-clock frame times for optimized presentation:

| View | Safe renderer | Separate renderer |
| --- | ---: | ---: |
| Pilot, stationary | 53.56 ms | 53.36 ms |
| Passenger, stationary | 54.79 ms | 54.76 ms |
| Platform, stationary | 51.41 ms | 51.18 ms |
| Overview, stationary | 41.94 ms | 42.04 ms |
| All five trains moving | **61.10 ms** | **46.22 ms** |
| Moving case p95 | **75.47 ms** | **58.04 ms** |

In this pair the moving case improved **24.36% in median frame time**. Stationary
views barely changed: GPU time dominates them on this development machine.
Moving-train presentation still cost 13.49 ms in safe mode and 15.68 ms with the
separate renderer. Threading permits overlap; it does not remove that work.
These are one paired experiment, not repeatability bounds or a projected target
FPS. The fresh optimized scenes have about 18,000–20,000 nodes, rather than the
older report's approximately 52,000.

**Keep safe rendering as the default.** Safe mode completed with empty stderr.
Separate mode logged four empty-image texture-update errors, an off-render-thread
`finalize` error at shutdown and two leaked objects. It also logged shader metadata
synchronizations from material duplication during vehicle construction. Those are
distinct from the fixed timing queries: neither corrected run logged a viewport
timing synchronization warning. The captured platform and cab images were
inspected, but matching-looking captures do not establish renderer stability.

Raw reports, audited summaries, issue counts, source hashes, source asset inventory
and a platform screenshot pair are in
[`art/performance/render-thread-2026-10-11/`](../art/performance/render-thread-2026-10-11/).
The stopped pre-fix probe and the old synchronous safe baseline are intentionally
excluded from this comparison. No project rendering setting or download changed.

To repeat on the target PC from source, run the launcher once with each mode,
keeping the game focused and other heavy work closed:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\Benchmark.ps1 -CrowdedOnly -RenderThread safe -Resolution 1440p
powershell -NoProfile -ExecutionPolicy Bypass -File .\Benchmark.ps1 -CrowdedOnly -RenderThread separate -Resolution 1440p
```

Inspect stderr as well as frame times before considering the separate mode for
ordinary play. Shader-parameter metadata access during coach construction and
the texture/shutdown errors need a separate compatibility fix.

## What the coach inventory actually shows

Read directly from the committed GLB scene descriptions, excluding runtime-added
shadow meshes, door leaves, lights and passenger actors:

| Stock | Source nodes | Mesh instances | Material surfaces |
| --- | ---: | ---: | ---: |
| WAP-7 | 51 | 24 | 268 |
| LHB coaches | 31–35 | 15–17 | 111–138 |
| ICF coaches | 45–47 | 21–22 | 147–151 |
| Vande Bharat cars | 28–86 | 12–39 | 112–211 |

There is batching opportunity, especially in repeated compatible material surfaces.
The source assets are already grouped; a blanket estimate of 300–400 nodes per
coach does not describe these GLBs. The normal-play CPU cost also includes repeated
route sampling, transform propagation, wheel/bogie animation and renderer updates.
It needs measurement rather than attribution to node count alone.

For a geometry-batching change, group by motion pivot, interior/exterior visibility,
transparency/shadow behavior and compatible material parameters. Preserve all source
triangles and authored LOD behavior. Baking vertices into a common car/pivot space
must also transform `author_from_mesh` and `passenger_from_mesh`; otherwise the
procedural finish and shader-cut door openings change. Glass still needs the onboard
variant, and wheels, bogies, pantographs and door leaves must stay independently
animated. Seat/camera positions use the existing manifest/car transforms.

Material consolidation and texture atlasing are distinct from simply merging nodes.
One merged mesh with the same hundred material surfaces can still issue a hundred
draws per applicable pass. Keep this distinction when choosing the next asset change.

## Simulation scope

The new optional multicore simulation and its independent 60-second / 40-world-minute
comparisons are documented in `parallel-simulation.md`. Skip already subdivides its
work into 50 ms slices. Changing normal play from its current physics tick to 20 Hz
would require new driving, sound-contact, interpolation and timetable validation;
it cannot be counted as a threefold improvement to skip.

Moving normal-play simulation wholesale to a worker is a separate ownership refactor:
presentation would need immutable snapshots and driving/dispatcher actions would
need a command queue. The current skip handoff safely pauses live world readers;
normal play cannot reuse that assumption.
