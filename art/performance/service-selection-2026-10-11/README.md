# R30 service and time selection checks

Source-game checks on the development Ryzen 7 7840HS / Radeon 780M, Godot
4.7.2. The playing PC is the i9-13980HX / RTX 4090 Laptop / 64 GB machine.
Native checks use Dummy audio; these results do not measure audible output or
target-PC frame rates. No extracted distribution is launched.

- `headless.stdout.log`: full 572-test suite, zero failures. The save ceiling
  then increased to 64 MiB; `save-tests.stdout.log` passes all 13 save tests,
  including the added large-payload case. The resulting suite has 573 tests.
- `timeline-tests.stdout.log`: five focused checks after improving station
  landing clearance. Covers exact moving-world restore/continued evolution,
  corrupt files, continuous five-minute catalogues, active-service filtering
  and a safe landing at every open station.
- `service-ui.json`: 23 native checks, including controller selection/sorting,
  every booked call, night/manual start, cancellation and exact save/Continue.
- `timeline-ui.json`: 28 native checks: read-only map, rapid request changes,
  controller inspection, moving AI entry, manual dispatch assignment, requested
  TVC platform, exact platform save/Continue and post-depot station visits.
- `storage.json`: complete baseline audit and compressed state sizes. All 100
  services finish/depot; no safety events, maximum extra wait 1,774 seconds.
  All 233 five-minute states restore exactly, from 08:00 through day 2 03:20.
- `departure-memory.json` / `timeline-memory.json`: tracked Godot heap deltas
  from isolated headless restores. They exclude GPU memory and process/runtime
  overhead; the browser also retains its prior preview while reading the next.
- Screenshots were inspected for service information, night lighting, readable
  occupied-train previews and station entry. The 720p capture is the separately
  labelled early UI fixture; final full-catalogue captures are 1600×900.

Prepared sources and their checksums live in `data/service_starts/` and
`data/railway_times/`; export refuses stale simulation/route fingerprints.
Preparation processes own independent serial railways. Normal-play simulation
ownership and timetable timings are unchanged.
