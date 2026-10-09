# RTX 4090 laptop benchmark — 10 October 2026

Source: `D:\ClaudeWS\TrainGame-Benchmark-20261010-000502.zip`, returned by the
player after the R23 launcher fix. Both full runs completed, with no unfocused
sampled frames. This is analysis of the supplied recordings, not a new benchmark
or an optimization result. The archive remains unchanged and outside Git.

## Hardware and measurement limits

- Actual target: **Core i9-13980HX, RTX 4090 Laptop GPU (16 GB), 64 GB RAM, NVMe**.
  This supersedes the earlier assumed desktop RTX 4080 target.
- The 1440p screenshots are 2560×1440. Every screenshot from the run labelled
  **4K is 3028×1703**, inside a reported 3028×1843 window. Do not quote these
  results as native 3840×2160 performance.
- Startup `render_target_size` reports 4096×2304 and 5730×3222 respectively,
  inconsistent with the captured images. Render scale is 1.0. These early values
  do not establish supersampling; record settled, per-stage target/image sizes
  and validate them against the requested size before future comparisons.
- Many settled views cluster almost exactly at 16.67 ms even though benchmark
  VSync and Engine.max_fps are disabled. External limiting/presentation pacing
  is a possibility, not a diagnosed cause. Hardware inventory includes virtual
  displays as well as a physical 4K display; it does not prove which component
  caused the size mismatch or pacing.
- Engine process counters can retain previous stage-capture costs for a second.
  Use wall-clock `frame_ms` and the game's instrumented costs for actual stalls.
  GPU query samples can lag. Simulation cost measures a physics callback, not
  necessarily the sum of all physics callbacks in a rendered frame.
- This run contains roughly two minutes of advancing simulation per pass, not
  a multi-hour session. It cannot settle long-session memory/performance claims.

## Sampled performance

Times in milliseconds. Median frame time is not average FPS. p99 is the frame
time below which 99% of sampled frames fall. Loading is excluded from this table.

| Phase | 1440p median / p99 | Larger window median / p99 |
| --- | ---: | ---: |
| Cab, static | 16.67 / 16.77 | 16.67 / 16.76 |
| Live 32-service traffic, cab | 16.80 / 25.28 | 16.78 / 25.32 |
| Moving camera, outbound | 16.89 / 26.01 | 18.77 / 29.88 |
| Moving camera, return | 16.84 / 26.08 | 18.71 / 29.40 |
| Station revisit | 16.67 / 16.97 | 19.30 / 20.24 |
| Return to cab | 16.67 / 16.82 | 18.72 / 19.74 |

No non-loading sampled phase contained a frame longer than 50 ms. The worst
normal sampled frame was 42.91 ms. This does not include PNG/JSON capture between
stages or guarantee that all possible driving situations avoid longer stalls.

## Findings and follow-up priorities

1. **Train creation causes the worst main-thread loading pauses.** Startup has
   a 3,229 ms frame, of which the train-presentation bucket takes 3,065 ms. Return
   to the cab has a 2,068 ms frame, with 2,031 ms in the same bucket. The second
   run reproduces approximately 3.2/2.0-second stalls. `TrafficPresentation.update`
   creates a whole nearby formation synchronously through `ensure_view`, followed
   by audio setup. The bucket includes train transforms and geographic-frame
   work, so instrument those substeps before attributing every millisecond to
   mesh instantiation. Spread formation construction/activation over frames and
   preserve model/material detail. One whole formation per update is still too
   much indivisible work.
2. **The scenery cache profile misses this GPU.** `performance_profile.gd` grants
   a 10 GiB allocation threshold only to adapter names containing `rtx 4080`.
   This 4090 receives 2 GiB, below the game's approximately 3–4.4 GiB active
   allocation, so hidden chunks are repeatedly evicted. Outbound/return/revisit
   stages record zero cache hits; each whole run records only three. Replace
   the single-model rule with a justified hardware budget. This targets reuse
   and regeneration costs; it is not evidence of a steady-state FPS gain or a
   need to fill VRAM. Whole-GPU NVIDIA memory use is only around 5.5–6.3 GB.
3. **Normal movement is substantially GPU-bound.** Moving views use about
   95–97% GPU at median. Larger-window median GPU time is 18.6–18.7 ms, close to
   the 18.7–18.8 ms wall frame time. The cab uses roughly 7,900–9,000 draw calls
   and 25–26 million reported primitives across rendering passes, not that many
   unique model triangles. Profile shadow passes, draw-call submission and
   interior visibility before reducing authored asset quality. Current 8× MSAA,
   8192-pixel shadows, SSAO and SSIL also merit separate measured comparisons.
4. **Live-traffic jitter has a CPU component.** Live-cab p99 is approximately
   25.3 ms at both resolutions despite different GPU times. Simulation cost
   reaches about 9.7 ms at p99; same-frame correlation with frame time is 0.79
   in the 1440p live phase. Profile simulation/dispatch substeps rather than
   assuming a specific dispatcher routine is responsible. Low aggregate CPU
   utilization does not rule out a serial bottleneck.
5. **A few scenery tiles dominate destination loading.** Some Nagercoil tile
   jobs take 14–15 seconds despite eight active workers. Initial readiness takes
   28.7–29.5 seconds; loading Kumbalam about 13 seconds, Nagercoil about 22 seconds,
   and returning to the cab about 19.6 seconds. Instrument per-feature tile
   construction and separate work time from queue wait. More worker threads alone
   will not necessarily fix exceptionally expensive individual tiles.

Normal live/moving stages record only zero to two additional pipeline
compilations. This run does not support blaming ordinary moving-view jitter
primarily on repeated shader compilation. Memory stabilizes within phases;
there is no demonstrated VRAM exhaustion, nor sufficient duration to rule out
an eventual leak. No CPU-temperature sensor was supplied.

## AI train rendering

Player and AI trains both use `ported_train_view.gd` and the same detailed
assets/materials. Automatic mesh LOD applies to both; interior-only geometry
has a 100 m visibility range with a 15 m margin. Geographic traffic presentation
loads nearby formations within 3.2 km, draws AI trains within about 2.2 km and
unloads ordinary distant AI views beyond 4.5 km. Distance uses the nearer head
or tail. Player/followed services receive retention exceptions. All services
continue simulation while their visual representation is absent.

The supplied benchmark simulates 32 services but has only **one or two resident
train views** in the sampled phases. It does not render 32 full-detail trains
simultaneously, and it does not test a densely occupied major station's worst
case. Retain close-up fidelity while addressing creation stalls and redundant
rendering work.

No runtime settings, game assets or published build changed during this review.
