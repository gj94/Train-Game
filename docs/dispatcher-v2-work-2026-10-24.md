# Optional predictive dispatcher V2 work record

User authorized implementation of an optional dispatcher that compares future
overtake stations using projected speeds, ETA, timetable calls and clearance,
with asynchronous multithreaded forecasting where useful. Preserve the existing
dispatcher as selectable Classic. Do not weaken the interlocking or change
track geometry to obtain better results. Trains that can get fully into a safe
receiving loop before the express should be considered for onward departure
instead of an unnecessary hold at the previous station.

Fixed further-work window begins 24 October 2026 at 22:33:56 Asia/Singapore.
User requests six more hours and at least 04:00; earliest completion is therefore
25 October at 04:33:56, plus any time needed to reach six actual active hours.
Record sessions in `.local/dispatcher-v2-2026-10-24/window.json`, excluding idle
gaps. Do not reset the start or count waiting between turns as active work.

## Implementation plan

1. Separate numerical forecasting/selection from ordered dispatch execution.
   Detached input contains train physics, calls, road capabilities, live
   availability and bounded topology. Workers never own signals or live trains.
2. Compare the current station with upcoming compatible passing stations;
   include train/equipment/track speeds, traction, braking, scheduled and
   passenger dwell, loop ingress and full-tail clearance plus uncertainty.
   Prefer natural booked stops when their timing is viable. Do not postpone
   merely because the slow train's head reaches a station first.
3. Validate proposals on the simulation owner, including stale/moved/deleted
   participants, conflicting commitments, operator holds, road capacity and
   berth availability. Existing interlocking remains the only authority.
4. Opt-in home/journey controls; preserve choice and needed commitments in saves,
   retain old save/prepared-state compatibility. Existing baseline previews must
   be identified as Classic when V2 is selected; no false V2 preview claims.
5. Unit tests, bounded KPY/STKT regressions, adversarial late/manual changes,
   save/load and asynchronous lifecycle tests. Compare compute cost and actual
   worker thread use. Run substantial Standard/Intensive operation audits before
   considering V2 complete; keep preparation outputs isolated from live data.
   User additionally requests V2-compatible prepared timetables and a new
   Intensive day with K1 overtakes distributed along the route, instead of
   concentrating at Kayamkulam/Karunagappalli. Retain Classic data separately;
   prepare V2 starts, five-minute states and encounters from the same validated
   operating-day run. Audit spatial distribution, distinct overtakers, individual
   waits and completion. Adjust authored departures/calls rather than hardcode
   dispatch locations or pad K1 dwell to force passing. Confirm the observed
   concentration from event data before changing the Intensive schedule.
6. Native UI checks, documentation and committed/pushed coherent increments.
   Keep R46 live; no release has been requested explicitly in this new task.

## Initial evidence

Latest user steering: compare both ETA/order alternatives and predicted
punctuality benefit for the higher-priority train, rather than creating passes
from priority alone. Added explicit weighted-delay comparison work. User also
authorized an interim even split of Kollam's six passenger roads (three per
direction). The current importer assigns each siding to the nearest main; QLN
has one southbound and five northbound passenger roads, not verified junction
connectivity. Full dual-line access needs actual crossover topology. Stage the
balanced reconstructed layout after owner-policy tests, then regenerate/test
all compatible Classic and V2 timetables; old geometry signatures must never be
silently accepted. Preserve the published R46 files throughout.

See `dispatch-kpy-2026-10-24.md`: K1 is assigned KPY_P1 before B002 enters the
classic four-minute conflict window; D100 occupies P4 at that earlier moment.
Later policy holds the already berthed K1 and admits B002 to P4. STKT is 7.65 km
ahead, K1 stops on a sufficiently long platform loop and B002 runs through.

No subagents. Read Git state and owned processes at each continuation. Do not
change runtime or tests while a full source suite is running. Update this record
and progress at coherent checkpoints. The map/QoL automations are complete and
must stay paused.

## Foundation checkpoint, 24 October 23:01

Detached numerical input, speed-envelope forecast, alternative-station solver
and bounded WorkerThreadPool implementation are complete but not wired into the
live dispatcher. Full source suite: 919 passed, zero failures. Sixteen new tests
cover physics/paths, capacity, multiple contenders and asynchronous ownership.
The initial K1/B002 11:40 pair forecast chooses STKT_P3 / STKT_P1 with 159 s
remaining clearance margin and about 180 s additional slow-train waiting.
Do not present these forecasts as measured live movements yet.

Ten repeated measurements per configuration give identical proposals. Mean
compute times: inline 24.60 ms, one worker 25.52 ms, two 15.99 ms, four 10.14 ms;
capture 3.13 ms, asynchronous submission 0.37–0.43 ms. Development Radeon 780M
PC; target is i9-13980HX / RTX 4090 Laptop / 64 GB RAM. No rendering benchmark.
The baseline records 14 K1 overtakers at eight stations, including five at KPY.
Next: owner-side acceptance and plan stability; connect only same-direction
overtake policy, preserve crossing/interlocking authority, then persistence/UI
and full V2-compatible operating-day preparation.

## Owner integration checkpoint, 24 October 23:35

Full source suite: **937 passed, 0 failed** (`owner-full-tests.log`). Live
proposals now pass owner-side freshness, participant, route-claim and competing
plan checks. Explicit following/overtaking comparisons measure predicted
priority-train lateness saved against lower-priority detention. Classic remains
the default; no home selector or new prepared day is delivered yet.

`order-live.json` records a 20-minute 11:35–11:55 replay of the original
Intensive state. K1 is not held for B002 at KPY; it takes STKT_P3 while B002
passes STKT_P1 above 20 m/s. No safety events. The original closely grouped
relief services still catch K1 there: this is not full-day distribution proof.
Reproduce with `tools/check_predictive_overtake.gd` on this geometry/state.

`order-worker-benchmark.json` repeats the equivalent-result benchmark after the
order comparison was added: inline 32.80 ms, one worker 33.69 ms, two 23.28 ms,
four 17.62 ms; capture 3.319 ms. Asynchronous live submission remains nonblocking.
Offline preparation/time skip joins four workers on its simulation owner.
Save/load and event rewind preserve validated plans; worker handles never enter
snapshots. A real 20-second skip matches the inline state exactly and restores
the live asynchronous strategy. These are development CPU timings, not FPS.

Next: isolate KPY/STKT regression fixtures from mutable prepared states; apply
the authorized QLN three/three platform split; expose matching Classic/V2 day
choices and regenerate/audit their service starts, timeline and encounters.
