# Performance and target-PC benchmark

Confirmed target from the 10 October report: Core i9-13980HX, RTX 4090 Laptop GPU
with 16 GB VRAM, 64 GB RAM and an NVMe SSD. This supersedes the earlier assumed
desktop RTX 4080 target. The benchmark requests 2560×1440 and 3840×2160 by default;
verify the actual captured size because Windows can constrain a window.

See [the first target-PC analysis](benchmark-2026-10-10.md) for results and
limitations, including the non-4K size of the run labelled 4K, train-creation
stalls and the cache profile's RTX 4080-only rule.

## Run on the target PC

**R23 launcher fix:** if you downloaded the original R23 game ZIP, also download
`TrainGame-Benchmark-Fix-1.zip` from the LAN page and extract its contents beside
`TrainGame.exe`, replacing `Benchmark.ps1` and `Run Performance Benchmark.cmd`.
The fixed launcher displays **Train Game benchmark - launcher 2** immediately.
The original game executable and PCK stay the same. The incremental updater also
delivers this fix in sequence 24 (`R23-BenchmarkFix1`).

1. Extract the entire R23 portable ZIP onto the SSD.
2. Close other games and heavy background work. Keep the normal driver settings;
   do not change overclocks or clear shader caches for this run.
3. Double-click **Run Performance Benchmark.cmd**. No Godot, Python, administrator
   access or extra monitoring installation is needed.
4. Leave the game focused and let it control the cameras. Do not drive or open
   menus. It closes and reopens automatically for the next resolution.
5. Send back **Documents/TrainGame-Benchmark-<date-time>.zip**.

Allow roughly 10–20 minutes for both runs; actual loading time depends on the PC.
The console reports completion. If a run fails, it still packages the partial
reports and error logs. The launcher stops its own game after 30 minutes per run.
No saved game or display preferences are overwritten.

The console shows each startup hardware query, then a running message every
15 seconds and a message while packaging results. Hardware inventory has a
25-second process timeout; NVIDIA probes each have a 5-second limit. Partial
inventory and unavailable counters are recorded in the ZIP. Optional Windows
performance counters run separately and are stopped after 20 seconds without
new samples, so a stalled provider cannot hold up the game or its timeout.
If a particular machine still needs it, `-SkipHardware` bypasses optional Windows
and NVIDIA collection while retaining engine/frame/process measurements.

For a shorter first run, open PowerShell in the extracted folder:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\Benchmark.ps1 -Resolution 1440p
```

Options: `-Resolution 4K`, `-Passes 2` for repeatability, and
`-RenderThread separate` for a separately labelled experimental renderer-thread
comparison. The default engine render-thread mode stays `safe`; scenery workers
remain genuinely parallel in both modes. Do not interpret a different render
mode as a quality setting. `-Quick` is a developer validation run, not a benchmark.

## What the ZIP contains

- **SUMMARY.txt**: frame median/p95/p99/max, GPU time, peak allocation and loading
  frames for each case; completion state and any missing counters.
- **hardware.json**: CPU model/core count, RAM capacity/speed, GPU and driver,
  Windows version, power plan, disk type/free space and build identity.
- **Each run's JSON**: exact adapter/API, resolution and render-target dimensions,
  refresh/VSync, all rendering settings, worker/cache budgets, startup time and
  stage statistics. A quick validation is explicitly flagged.
- **Each run's frames.csv**: every sampled frame, including loading. Timestamps,
  CPU/GPU render time, engine/game/simulation/train/crowd/HUD/audio-control costs,
  draw calls, primitives, graphics allocations, object counts, active workers,
  backlog, activation queue, residency, cache hits, simulation/camera state and
  focus/window state and individual pipeline-compilation counters.
- **Each run's jobs.json**: request/submission/start/completion times for scenery
  and station preparation, cancellation state, and main-thread activation events.
- **system-telemetry.jsonl**: timestamped process CPU/core use, RAM and
  thread/handle counts. **Each run's system-counters.jsonl** stores timestamped
  individual logical-CPU counters, memory pressure/paging and disk I/O separately.
  Raw disk timing counters are included to avoid rounded sub-second latency.
- **gpu-telemetry.csv**: NVIDIA load, memory, clocks, temperature, power/P-state
  and clock-limiting flags, when the installed driver exposes them.
- **Engine logs and PNGs**: errors and a screenshot of every measured view.
- **launcher.log, inventory-worker.log and inventory-partial.json**: startup and
  run progress, the last attempted hardware query and partial inventory on timeout.

The scripted sequence covers startup, cab and passenger interiors, 75 seconds of
live 32-service traffic, Kumbalam wide/close views, 25-second outbound and return
streaming passes, a warm revisit, Nagercoil landscape, and return to the cab.
Loading and settled views are reported separately. The streaming camera moves at
45 m/s to cross tile/origin boundaries; this is not a train-speed test.

## Reading the measurements

120 FPS allows 8.33 ms/frame; 60 FPS allows 16.67 ms. Judge p95/p99 and long stalls,
not only average FPS. Loading samples deliberately include the preparing screen.
Camera motion is wall-clock based; live simulation advances normally and can
pause for missing required scenery. Its clock/speed/loading state are recorded.
Driver-level VSync or caps can override the game's uncapped request.

GPU queries can lag the corresponding CPU frame; some engine counters refresh up
to one second late. Engine graphics allocations
are estimates and are distinct from NVIDIA's whole-GPU memory use. Static engine
memory is unavailable in release builds (marked in each JSON); its zero samples
are not zero RAM use. Process working/private RAM is recorded separately.
Unsupported sensor values mean unavailable, not zero.
CPU temperature requires a separate hardware sensor provider and is not guessed.
Windows disk/CPU telemetry covers the whole system as well as this game's process.

CSV writes, statistics, JSON and PNG capture happen between measured stages.
System and GPU telemetry runs at a nominal one-second interval; WMI query time can
lengthen it, so use recorded timestamps. Instrumentation itself has some overhead.
The script neither changes power/driver settings nor clears disk/shader caches.
Initial versus repeat runs are process-cold versus warm, not guaranteed cold SSD
or cold driver-cache measurements. No files are uploaded automatically.

## Changes in R23

- Persistent sleeping scenery workers scale from 2 to 8 using logical CPU count,
  leaving capacity for simulation, audio and engine work. A separate resource
  worker prepares stations; immutable cached bundles have synchronized publication.
- Scene activation is spread over frames (2 ms/24 top-level children per update).
  One large indivisible subtree may exceed the soft budget.
- Nearby hidden chunks retain uploaded meshes/buffers for revisits. RTX 4080
  gets up to 96 warm chunks for 120 seconds, trimmed when measured allocations
  exceed 10 GiB. Active scenery is never evicted to meet this cache ceiling;
  it is not a hard cap on total GPU memory.
- Tree impostor meshes/materials are shared. Train position queries reuse exact
  samples; unchanged pantographs, lights, wheel transforms and point blades avoid
  redundant updates. All simulation rules and physics timing remain unchanged.
- F10 shows frame percentiles, GPU allocations and worker/cache activity. It is
  hidden normally.

Texture sizes, geometry, visibility distances, 8× MSAA, shadow resolution/filtering,
SSAO and SSIL remain unchanged. A trial of broad occlusion culling was removed
after it added overhead without a meaningful gain on the development PC.

Local 1600×900 R22 baseline on the Radeon 780M: cab median 65.85 ms / p95 69.10 ms;
passenger 68.50 / 71.56; Kumbalam wide 62.41 / 64.35; station close 54.47 / 56.74.
Those are development-machine numbers, not RTX 4080 predictions. Its cab GPU
allocation was about 3.25 GiB; deliberately filling 16 GB is not a performance
goal. The target-PC reports are needed before selecting further GPU optimizations
or promising a 60/120 FPS target.

Implementation references:
[Godot threading](https://docs.godotengine.org/en/stable/tutorials/performance/thread_safe_apis.html),
[Godot performance monitors](https://docs.godotengine.org/en/stable/classes/class_performance.html),
[NVIDIA telemetry](https://docs.nvidia.com/deploy/nvidia-smi/index.html).
