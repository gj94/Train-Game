# Kerala Coast: 100-service operating day

Fictional gameplay timetable on the existing coastal alignment and CSV-authoritative
platform inventory. It is not a published Indian Railways working timetable.
K1 remains the default full-length ICF stopping passenger, serving all 55 open
stations from Ernakulam to Nagercoil. There is no artificial speed cap.

| Services | Working | Departures | Interval per direction |
|---|---|---|---|
| K1 | ERS–NCJ, all open stations | 08:00 | One through passenger |
| B001–B010 | ERS–Kayamkulam | 08:12–12:42 | 30 minutes |
| B011–B020 | Kayamkulam–ERS | 08:00–12:30 | 30 minutes |
| B021–B050 | Kollam–TVC | 08:05–13:53 | 12 minutes |
| B051–B080 | TVC–Kollam | 08:11–13:59 | 12 minutes |
| B081–B090 | TVC–Nagercoil | 08:25–14:25 | 40 minutes |
| B091–B099 | Nagercoil–TVC | 08:05–13:25 | 40 minutes |

The repeating stock pattern is ICF passenger, LHB intercity, VB8, LHB intercity,
ICF passenger, VB16. Priorities are 35, 70, 95 and 100 respectively; K1 is 20.
Vande Bharat workings omit intermediate secondary calls. Dispatch chooses actual
crossings and overtakes dynamically; these are not scripted meets.

The double-track central section carries the highest frequency. Single-track
sections have wider headways to leave capacity for crossings and the stopping
passenger. Origin and destination roads are selected for directional reachability,
real passenger faces and full-rake clearance.

Terminal arrivals may use another compatible passenger face when their booked
platform is busy. Interlocking, full-tail clearance, lane connectivity and the
station's real passenger-face inventory still apply. A long train spanning plain
approach blocks no longer blocks its own home-signal point solely because its
tail is on the preceding block; genuine point/branch occupation stays protected.

## Service lifecycle

- Future services remain off-network until two minutes before departure. They
  take no track, route authority, passenger animation or detailed train geometry.
- Entry requires a free, unreserved full-length origin berth and retains receiving
  capacity for approaching trains. A delayed entry waits off the line.
- Completed services unload and follow ordinary signals to a reserved depot road.
  After ten minutes fully stabled, AI stock enters offstage depot storage. The
  assigned player's train remains available. Results remain in the service roster.
- Dispatch shows all 100 services. Scheduled and stored workings can be inspected;
  viewing or taking control becomes available while a train is on the railway.
- The service designer supports up to 256 services and a 2 MiB import file. Its
  “Enter from depot near departure” setting allows later departures to share an
  origin berth. Old service files keep their original on-network placement.
- Saves preserve scheduled/active/stored states; older saves default to active.

## Skip to time or a future stop

Open **Menu / Esc → Skip to time / future stop**. Choose a clock time within the
next 24 hours (minute adjustments support keyboard, mouse and controller), the
next scheduled stop, or any later unvisited stop of your assigned service.

All drivers and dispatch switch to AI. The existing railway advances through
its normal physics, stops, passengers, priorities, crossings and depot workings.
3D rendering, scenery/presentation updates and audio are disabled during the
advance; only the 2D progress screen and its controller navigation keep running.
The progress screen shows the current world clock and measured simulation rate.
**Stop advancing here**, Esc or controller Back stops at the current state.
Elapsed simulation is retained; cancellation does not roll back the railway.

A stop target means its **actual recorded arrival**, not its booked time.
New protection events stop the advance for inspection. A future-stop search is
bounded to 24 world hours; missed calls must be resolved first. Clock skips can
cross midnight. Existing operator holds remain in force.

On return, the game resets train interpolation and sound history and restores
3D rendering. You return to your train's pilot seat if it is still available;
otherwise you appear outside at the nearest station platform. Off-network stock
is hidden and cannot be entered. The completion screen pauses the game and
offers **Resume with AI driving**, **Take control of this train** when available,
**Open Dispatch**, or another skip. Normal time resumes at ×1.

## Rehearsal and profiling

Use the portable Godot console executable from `docs/pc-setup.md`:

```powershell
& $godot --headless --path . --script res://tools/check_busy_timetable.gd -- --output=.local/busy.json
& $godot --headless --path . --script res://tools/check_busy_timetable.gd -- --delay=600 --output=.local/busy-delay.json
& $godot --headless --path . --script res://tools/profile_timetable.gd -- --seconds=600 --output=.local/profile.json
& $godot --headless --path . --script res://tests/run_tests.gd -- --timings=.local/test-times.json
# Use the native renderer for this source UI integration check:
& $godot --path . --script res://tools/check_time_skip.gd
```

The operating-day audit records all arrivals, completed calls, stationary delay
beyond booked/passenger release, the longest such continuous delay, active-train
peak, depot completion, safety events and elapsed wall time. Early arrival waits
are not included in that delay metric. A wait over 30 minutes stops the audit for diagnosis; passing
that guard alone is not a satisfactory service-quality result.

The physics remains in 50 ms slices. A two-second rehearsal request performs 40
physics slices; it does not skip signals or replace train motion with arithmetic
arrival times. The in-game rehearsal shares the main thread with rendering and
has a 4 ms budget per frame. Smaller rehearsal batches keep that UI responsive.

Optimisations reuse occupancy within a step while updating it after each train's
movement, index live route claims and single-line direction locks, avoid scanning
untouched automatic routes for release, and bound physical obstruction searches
by the necessary braking/movement horizon. External queries rebuild state rather
than trusting a stale cache. Trains entering or leaving depot refresh occupancy.

A complete unexplained standstill ends a rehearsal after five simulated minutes,
without waiting for the two-hour timetable timeout. Booked departures, passenger
exchange, depot release and manual/operator holds are exempt.

## Recorded validation — 10 October 2026

Both complete operating days finished at 15:58. All 100 services departed their
origins, recorded all 467 subsequent booked arrivals and cleared fully to depot.
K1 served all 55 open stations. Neither run recorded a safety protection event.

| Measure | Baseline | K1 starts 10 minutes late |
|---|---:|---:|
| Completed services in depot | 100 / 100 | 100 / 100 |
| Peak active passenger workings | 25 | 24 |
| Median final arrival delay | 2.28 min | 2.21 min |
| 95th percentile final arrival delay | 16.99 min | 18.00 min |
| Worst final arrival delay | 28.81 min (B012) | 37.56 min (B008) |
| Longest continuous delay beyond release | 13.03 min (K1) | 13.03 min (K1) |

This is a busy day, not a promise of zero waiting. The northern single-track
crossings and overtakes account for the largest accumulated arrival delays.
K1 accumulates 48.27 minutes of stationary delay beyond release in the baseline,
spread across its whole journey; its final arrival still fits its stopping
schedule. No timetable padding was added to hide the measured outliers.
Manual driving, additional holds and edited services can change these results.

The raw `completed_calls` field counts arrivals and excludes each origin
departure; it should equal `calls - 1`. Origin departures were also checked
against the hourly audit checkpoint. Full results and metric definitions:
[`art/performance/timetable-2026-10-10/`](../art/performance/timetable-2026-10-10/).
The two all-day audits ran concurrently with other work; their 22–23 minute wall
times are not controlled performance comparisons.

An isolated 32-service, 600-simulation-second CPU comparison fell from **27.75 s
to 14.15 s**: about **49% less wall time**, or **1.96× throughput**. The final
measurement also includes the gradual predictive AI driver. These are local
Radeon 780M development-PC CPU results, not measurements on the playing PC's
Core i9 / RTX 4090 Laptop GPU.

Initially dispatch/signalling cost 39% and AI driving 30% of the sample; route
release added 12%. After optimisation, dispatch/signalling is the largest
remaining phase (about 61%). Simulation has to execute the real railway for
hundreds of thousands of 50 ms slices; GPU rendering is not the headless-test
bottleneck. An intentionally blocked timetable now ends early rather than
running to its two-hour deadline.

The combined headless suite passes 491 tests. Native source integration checks
cover 20 skip/return cases and 19 journey/traffic cases. The graphics benchmark
retains its original 32-service fixture so prior GPU comparisons remain useful.
