# Five occupied trains — R24 development capture

The native Vulkan capture completed with **five resident trains, 91 vehicles
and 5,580 onboard passengers** on five separate ERS platform roads. All eight
static comparisons and the moving phase passed the benchmark audit. The log
has no renderer or script errors.

This is a **Radeon 780M development-PC run at a verified 1600×900**, using the
source/debug engine. The target is the **i9-13980HX, RTX 4090 Laptop GPU (16 GB),
64 GB RAM and NVMe PC**. These results are not target-PC FPS estimates. The
target needs the included crowded benchmark after updating.

## Same-process rendering comparison

Each static interval lasts at least 12 seconds and contains at least 120
frames, after loading and 45 transition warm-up frames. All captured views are
1600×900, have zero loading frames and zero unfocused frames. Dispatch is paused
for reproducibility. The reference enables original-distance building/grass/
track geometry, full train interior visibility and detailed vehicle shadows.
Both modes use the newly ported collection. This is not an R23-versus-R24 test.

| View | Median reference → optimized, ms | p95 reference → optimized, ms | Rendered primitives reference → optimized |
| --- | ---: | ---: | ---: |
| Pilot | 57.12 → 55.61 | 58.58 → 58.19 | 19.05 M → 16.99 M |
| Passenger | 59.26 → 57.21 | 61.11 → 58.39 | 22.01 M → 19.58 M |
| Platform | 55.60 → 51.93 | 57.96 → 53.79 | 24.33 M → 21.24 M |
| Overview | 62.54 → 58.00 | 65.72 → 60.36 | 24.24 M → 19.88 M |

Observed median frame-time reductions are 2.6–7.3%; primitive reductions are
10.8–18.0%. This single local pass shows a modest improvement, not a universal
speedup or a 60/120 FPS guarantee. Renderer primitive counts include render
passes and should not be confused with unique source-model triangle counts.

Pilot seated meshes fall from 140 to zero and visible interior groups from
202 to six. The passenger view restores 140 nearby seated actors and 26
interior groups. The complete 5,580-person population survives all views;
rendering fewer meshes does not remove passengers. Allocations stay around
4.74 GiB because hidden geometry/resources remain resident.

## Moving and loading behavior

All five trains coast from 2 m/s for 12 seconds, remaining within separate
platform roads. Each travels **23.65 m**. Median frame time is **70.26 ms**, p95
**82.87 ms**, p99 **90.63 ms**; this is not yet smooth on the development GPU.
Simulation median/p95 is 1.08/1.94 ms; train presentation is 13.21/16.62 ms.
This phase measures crowded movement, not high-speed passing, timetable
completion or dispatcher deadlock resilience.

The largest recorded asynchronous build step, including startup arrivals, is
**349.30 ms**, down from 666.46 ms in the immediately preceding development
capture. The former largest step was repeated route-contact setup in audio;
that immutable metadata is now shared. The current largest step is first-use
VB material/vehicle assembly. Building one coach per frame bounds formation
work, but does not eliminate individual material/geometry stalls. Explicit
immediate player handover can still finish pending work synchronously.

Diagnostic overview captures give p95 20.02 ms with scenery hidden and 47.86 ms
with trains hidden. Those are component-isolation diagnostics, not additive
timings. Scenery draw/shader cost and moving-vehicle updates remain priorities,
alongside preparing first-use vehicle materials off the main thread.

## Evidence and repeat

- [Complete report](../art/performance/crowded-2026-10-10/report.json)
- [Audited summary and build-step timings](../art/performance/crowded-2026-10-10/summary.json)
- [Five-train overview](../art/performance/crowded-2026-10-10/overview.png)

Raw frame CSV, stage screenshots and logs are retained under
`.local/scenery-crowded-verified/`. The source audit command is:

```powershell
python tools/check_crowded_benchmark.py .local/scenery-crowded-verified/run.json
```

On the target PC, update with Update & Play, then run from the game folder:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\Benchmark.ps1 -CrowdedOnly -Resolution 1440p
```

The regular benchmark also includes this fixture after its route-wide stages.
It saves the returnable ZIP under Documents. Verify actual screenshot dimensions
before interpreting a requested 4K run as native 4K.
