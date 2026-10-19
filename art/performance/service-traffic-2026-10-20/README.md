# Service traffic preview — 20 October 2026

Offline replay of the existing 100-service baseline, with rendering disabled.
Four independent contiguous intervals begin at verified five-minute checkpoints;
the observer records head, centre and tail chainages every two seconds. Interval
endpoints are checked against the existing railway states before the recordings
are merged. A continuous detector keeps pair history across interval boundaries.

Crossings are opposing train-centre passes. Completed overtakes require reversal
of the order of the full formations, with the centre-pass time retained for the
preview. Mere spawning, stationary nose shuffling, abandoned passes and depot
movements are excluded. Times shown in the UI are rounded to the nearest minute.
Station labels use the actual reconstructed yard bounds; interstation encounters
also show simulated route chainage.

The immutable shipping dataset is `data/service_starts/traffic.json`. Raw
recordings remain under `.local/service-traffic/`, outside the shipped game.
Screenshots in this folder use the real completed baseline, not the separately
labelled synthetic UI fixture. No extracted distribution is launched.

The native UI check runs on the development Radeon 780M at 1600×900 and
1280×720 using Compatibility for this 2D menu. Its expected screen-space-AA
warning is unrelated to gameplay rendering. Selection timings measure script
execution only, not GPU frame time or RTX 4090 Laptop performance.

## Results

- 100 services; **469 opposing crossings and 46 completed overtakes**.
- 34,801 samples, day 1 08:00 through day 2 03:20; no safety events.
- Maximum interval endpoint position difference: 0.0000213 m. Three of four
  endpoints match exactly. The longest replay worker took 1,037.841 seconds.
- Preview file: 115,080 bytes (112.4 KiB). K1 has 19 crossings and is overtaken
  three times; B001 has 16 crossings/two overtakes and B012 has 13/three.
- Nine detector tests pass: complete formations, both directions, abandoned
  passes, spawning/removal, repeated overtakes, exact alignment and midnight.
- **637 headless tests pass**, with no script/runtime errors. The unchanged
  100 departure states and 233 five-minute states pass their release gates.
- 118 native menu checks pass, including every service, controller navigation,
  stale/empty views, saved-journey exclusion and the last overnight card's full
  scroll reach. Worst measured selection script call: 19.633 ms while the
  headless suite was running; this is not a gameplay frame-rate measurement.
