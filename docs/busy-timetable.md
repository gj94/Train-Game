# Kerala Coast: 100-service operating day

The revised day has **24 full ERS–NCJ workings**, **12 ERS–TVC intercity workings**
and **64 regional workings**, including exactly **two full-route Vande Bharats,
one in each direction**. Departures run from 08:00 to 22:10; late workings finish
on day 2. K1 remains the default 08:00 WAP-7 + ICF passenger, calling at all 55
open stations. Equipment and line limits govern speed; local services are slower
because of their stops, acceleration, dwell and dispatch priority.

This is an authored, deliberately busy game operating day, **not a published
Indian Railways working timetable**. It uses the coastal route and the user's
CSV platform inventory. Long-distance services enter/leave the model at its
ERS/NCJ boundaries; off-map destinations and physical rake rotations are not
simulated. Saves retain their existing timetable: start a fresh Kerala scenario
without loading an old save to use this revision. Saved service-designer drafts
also retain their authored services; they are not silently overwritten.

| Workings | Route / role | Calling pattern |
|---:|---|---|
| 24 | ERS–NCJ, 12 each way | Two VBs, 20 expresses and two through passengers |
| 12 | ERS–TVC, 6 each way | Seated intercity; ordinary and limited-stop patterns |
| 6 | ERS–Kayamkulam, 3 each way | Coastal passenger |
| 6 | ERS–Alappuzha, 3 each way | Short coastal passenger |
| 40 | Kollam–TVC, 20 each way | Regional services, closer morning/evening intervals |
| 12 | TVC–NCJ, 6 each way | Cape passenger |

The VBs are **B001, ERS 08:35 → NCJ (8 cars)** and **B012, NCJ 09:10 → ERS
(16 cars)**. Both call at **Ernakulam Junction, Alappuzha, Kayamkulam Junction,
Kollam Junction, Thiruvananthapuram Central, Kulitturai and Nagercoil Junction**,
in their direction of travel. Both have priority 100. There are no short VB
commuter workings. K1 departs before the southbound VB, so the dispatcher must
find a safe overtaking opportunity rather than holding K1 at ERS for it.

Other priorities are 85 for limited expresses, 75 for conventional expresses,
70 for intercity, 45 for capital regional, 30 for other passengers and 20 for K1.
Actual progress, reachable receiving roads and interlocking determine crossings
and overtakes; there are no scripted passing events or forced priority signals.

WAP expresses use 22 homogeneous ICF or LHB coaches. Intercity and local workings
use 20 seated coaches, rather than assigning sleeper formations to every shuttle.
VB formations remain fixed at eight/sixteen cars. The existing asset set lacks
utility/guard/power cars; these are representative rakes, not exact real diagrams.

Calls have at least a minute of dwell, normally two at major junctions and four
at TVC for through expresses/VBs (three for passengers/intercity). Booked times
include the preceding dwell, stop acceleration/braking and distinct running
allowances for single/double line and service class. These are planning averages,
not new train speed caps. Most ERS departures are about half an hour apart;
some following evening workings are grouped to leave an opposing crossing window
on the northern single line. Full-day traffic checks, rather than a uniform
departure interval, establish whether those slots work.

Local services call at all open, directionally accessible passenger faces in
their sector. **Takazhi, Veli and Viranialur currently have only a southbound
passenger face in the CSV-based game geometry. Northbound locals omit those
three calls.** This is a documented layout limitation, not a claim about actual
railway service at those stations. Tirunettur is closed in the register.

Origin, destination and intermediate roads must have a real passenger face,
directional connectivity and full-rake clearance. Compatible alternative terminal
faces remain available dynamically. Completed trains unload and clear to depot.

## Research and adaptation

- [Southern Railway, 27 October 2023](https://images.assettype.com/thefourthonline/2023-10/055534eb-3171-4ce5-a1a4-01ccba4bda81/Clarification_to_media_on_Vande_Bharat_trains.pdf)
  describes scheduled coastal VB crossings with Alappuzha–ERS and ERS–Kayamkulam
  passengers, plus Jan Shatabdi and Ernad traffic. It supports a mixture of
  through expresses and regional stopping trains, with planned crossing capacity.
  This is historical operating context, not a current departure-time source.
- The [Ministry of Railways list dated 18 March 2026](https://www.pib.gov.in/PressReleasePage.aspx?PRID=2242000&lang=1&reg=1)
  lists TVC–Mangaluru and TVC–Kasaragod VBs, plus NCJ–Chennai and ERS–Bengaluru
  services. The full coastal **ERS–NCJ VB pair here is the user's requested
  scenario adaptation**, not an assertion that that exact pair is published.
- Game IDs, departure slots, intermediate calling patterns, formations and
  priorities are authored for this route's current operating geometry. Stock
  families, major stations and the division between locals/intercity/expresses
  follow those service roles without inventing real train numbers.

## Service lifecycle

The [importable service file](../art/timetables/kerala-coast-100-through-services.json)
uses the existing service-file format with the corrected map's geometry signature.
In **F5 → Import**, select it, choose K1 (or another service), then use **Play**.
Export your existing draft first if you want to retain it. This map update needs
its matching game build; R28 saves and service files cannot be transferred onto
changed track geometry. Importing starts a new scenario.

The R28 results below document the prior map. Fresh full-day baseline and delayed
runs validate the corrected map separately; see [map corrections](map-corrections.md).

Regenerate the file after changing the timetable with:

```powershell
& $godot --headless --path . --script res://tools/export_busy_timetable.gd -- --output=art/timetables/kerala-coast-100-through-services.json
```

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
are not included in that delay metric. Any continuous delay over 30 minutes fails
the service-quality check, even if every train eventually finishes. The audit
continues collecting other problem slots, but aborts at 45 minutes to diagnose a
likely stalled working. These limits are audit guards, not changes to dispatch.
Diagnostic continuations retain their original schedule and are explicitly
labelled; they cannot certify a changed timetable.

The LAN site offers this timetable separately from the full game. Run
`node tools/publish-timetable.mjs` to publish a clearly labelled preview, then
add `--verified --baseline=<report.json> --delayed=<report.json>` only after
both fresh full-day audits pass. Publication checks the simulation-source digest,
every booked call, departure and priority, complete depot clearance, zero safety
events and the continuous-wait limit. The delayed run must hold K1 for at least
ten minutes. Immutable data filenames and an atomic catalogue update preserve
downloads already in progress. The catalogue binds compatibility to the current
game build; publishing another build hides the old timetable until reviewed.
Certification also compares the released simulation code with the tested runtime
(excluding timetable definitions), so a dispatcher fix cannot be certified for
an executable that does not contain it.

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

## R28 validation — full-route timetable

Both fresh operating-day audits finished at **03:16:56 on day 2**. All 100
services departed their origins, served all **1,530 subsequent arrivals** and
cleared fully to depot. Neither run recorded a safety event or a continuous
delay beyond release exceeding the 30-minute quality limit. The source hash
and per-service results are preserved in
[`timetable-through-2026-10-10`](../art/performance/timetable-through-2026-10-10/).

| Measure | Baseline | K1 held until 08:10 |
|---|---:|---:|
| Completed services in depot | 100 / 100 | 100 / 100 |
| Subsequent calls served | 1,530 / 1,530 | 1,530 / 1,530 |
| Peak active passenger workings | 23 | 23 |
| Median final arrival delay | 0.00 min | 0.00 min |
| 95th percentile final arrival delay | 17.58 min | 17.58 min |
| Worst final arrival delay | 32.70 min (B015) | 32.70 min (B015) |
| Longest continuous delay beyond release | 28.17 min (B013) | 28.17 min (B013) |

K1 actually departs at 08:00:44.95 in the baseline and 08:10:00.10 in the delayed
run. Its initial delay is absorbed during the early calls; later traffic converges,
so the identical final figures are expected. K1 is overtaken by B001 at Mararikulam,
B024 at Sasthamkotta and B002 at Neyyattinkara in both runs. These are observed
dispatch decisions, not scripted events. K1's longest extra stand is 28.03 minutes.

The roster remains busy: single-line crossings can require waits approaching half
an hour. The median reports non-negative lateness, with early arrivals counted as
zero. Waiting before booked/passenger release is excluded from the extra-delay
metric. Manual driving, operator holds and edited services may change the outcome.

All **517 headless tests** and five download-catalogue tests pass. The new
regressions cover directional terminal exits, compatible escape capacity,
prepared home-route ownership and contradictory ALLP crossing/overtake promises.
The full-day runs took 43.61 / 45.29 wall minutes while running concurrently;
these are development-PC simulation audits, not a controlled CPU comparison or
a 4090 Laptop graphics measurement. No extracted-distribution gameplay test.

Playtest R28 with a fresh Kerala scenario: inspect the two full-route VBs and
their major calls, drive K1 or use A for AI, then use Skip to inspect afternoon
crossings and the B020/B021 overtake at ALLP around 21:00. Completed services
should leave the running lines for depot. Existing saves retain their old roster.

## Historical R27 validation — superseded short-corridor timetable

The following figures belong to the older R27 timetable, not the revised full-route day.
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
