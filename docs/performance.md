# Performance and target-PC benchmark

Per-option controls are now available under **Menu → Graphics settings**. See
[the graphics guide](graphics-settings.md) for presets and the 18 live controls.
Add `-SavedGraphics` to `Benchmark.ps1` to measure your saved preferences; otherwise
the benchmark uses the High baseline. Both modes disable frame caps and V-sync.

Confirmed target from the 10 October report: Core i9-13980HX, RTX 4090 Laptop GPU
with 16 GB VRAM, 64 GB RAM and an NVMe SSD. This supersedes the earlier assumed
desktop RTX 4080 target. The benchmark requests 2560×1440 and 3840×2160 by default;
verify the actual captured size because Windows can constrain a window.

See [the first target-PC analysis](benchmark-2026-10-10.md) for results and
limitations, including the non-4K size of the run labelled 4K, train-creation
stalls and the cache profile's RTX 4080-only rule.

The new scenery/performance build adds a reproducible five-train stress fixture:
WAP-7 + ICF passenger, WAP-7 + LHB express, another ICF rake, VB8 and VB16 on
separate ERS roads. **91 vehicles and 5,580 onboard passengers** remain resident.
Pilot, passenger, platform and elevated overview cases each compare full-detail
reference rendering with the optimized presentation in the same process.
The reference enables all train interiors/eligible nearby seated passengers,
original detailed vehicle shadows/LOD bias and original-distance track detail,
building geometry and grass density.
It is an A/B rendering diagnostic, not a separate historical release benchmark.

The A/B fixture pauses dispatch for reproducible rendering. It verifies that
five trains and their passenger population survive every view, pilot has no
seated meshes, and the passenger camera still has people. The regular benchmark
also retains its separate 75-second live 32-service simulation phase. A final
12-second crowded phase releases all five formations to coast at an initial
2 m/s, entirely within their separate station roads. Their travelled metres,
CPU simulation/motion costs and passenger counts are recorded. This controlled
fixture measures crowded movement; it is not a timetable or dispatcher test.
Passenger meshes are observer-local: at most 140 seated and 80 platform/moving
actors, not one mesh for every simulated passenger. Pilot view skips the seated
population entirely. Counts for both groups appear in each stress-case JSON.

To run only the crowded fixture on the other PC after updating:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\Benchmark.ps1 -CrowdedOnly -Resolution 1440p
```

The ordinary launcher runs it automatically after the existing route sequence.
Each case records the actual captured pixel dimensions. Keep the game focused;
do not infer native 4K from a requested resolution alone.

RTX 4090 Laptop now receives a measured-allocation warm-cache ceiling of 8 GiB
and up to 96 retained chunks. RTX 4080 Laptop uses 6 GiB; recognized large desktop
GPUs use 10 GiB. These are conservative cache trimming thresholds, not total
VRAM caps or automatic measurements of every GPU model's installed memory.
Nearby AI resources load in the background and assemble one coach per frame;
the JSON reports the largest nonblocking assembly step. Initial player creation
and an explicit immediate handover can still synchronously finish a formation.

Full nearby scenery geometry is retained. Supplied tree LODs, model-baked
impostors, distant track silhouettes and camera-dependent train visibility are
documented in [the collection port](trackside-collection.md).
The [R24 development capture](crowded-benchmark-2026-10-10.md) records the
five-train comparison, moving-phase results and remaining loading hitches.

## Run on the target PC

Use **Update & Play v2** to install the current build before benchmarking. R24
includes the crowded fixture and its `-CrowdedOnly` switch; the original R23
launcher does not support that switch.

**Historical R23 launcher fix:** if you downloaded the original R23 game ZIP, also download
`TrainGame-Benchmark-Fix-1.zip` from the LAN page and extract its contents beside
`TrainGame.exe`, replacing `Benchmark.ps1` and `Run Performance Benchmark.cmd`.
The fixed launcher displays **Train Game benchmark - launcher 2** immediately.
The original game executable and PCK stay the same. The incremental updater also
delivers this fix in sequence 24 (`R23-BenchmarkFix1`).

1. Update the installation on the SSD using Update & Play, or extract the entire
   current portable download for a fresh installation.
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

## Railway corridor rendering (R25)

The 3D camera now stops at **60 m above local terrain**, with orbit distance
limited to **300 m** and the far clip at **2,200 m**. Distance haze blends the
last kilometre into the horizon. These limits also apply to controller input
and restored external cameras. Onboard views and the 2D dispatcher map retain
their existing movement and navigation.

Detailed 512 m tiles are requested within 1,150 m of the observer and must
intersect the railway corridor. Buildings, trees and crops concentrate within
220 m of the route, including depot branches. Other nearby tiles retain mapped
ground and water, with no decorative buildings or planting. Shared terrain
edge samples preserve tile joins. Cheap background terrain covers the full
view beyond them. Stations retain a 2 km streaming radius; track, overhead
equipment, signals and speed boards retain 1,650 m. The simulation continues
to operate the entire route.

To playtest, use R3 at a station, hold RB to climb, and confirm the camera stops
60 m above the ground and descends immediately with LB. Check mouse/controller
orbit zoom, then return to pilot with L3. Inspect nearby vegetation, platform
boundaries and backwaters at ERS and Kumbalam. Load an older save with an elevated
external view, then verify its height is bounded and its service is unchanged.
The existing five-train benchmark records camera height, far clip and requested
chunk kinds alongside frame timings. Its overview now uses a 55 m offset;
older 95 m overview captures are not directly comparable.

Source profiling can additionally isolate render costs with
`--benchmark --benchmark-traffic-only --benchmark-diagnose --benchmark-render-costs`.
This holds the five-train overview still and removes one geometry group or
effect at a time, restoring it before the next capture. Compare median GPU
milliseconds with the starting/ending baselines. Savings overlap and must not
be added: hiding an object also changes its shadows, occlusion and lighting.
Station-asset contents are grouped together; the source-triangle inventory is
only a geometry estimate, not a substitute for GPU timing.

On the playing PC, run `powershell -NoProfile -ExecutionPolicy Bypass -File
.\Benchmark.ps1 -CrowdedOnly -RenderCosts -Resolution 1440p` from the game
folder. The returned ZIP includes GPU timings and the category screenshots.
