# Optional predictive dispatcher V2 work record

User authorized implementation of an optional dispatcher that compares future
overtake stations using projected speeds, ETA, timetable calls and clearance,
with asynchronous multithreaded forecasting where useful. Preserve the existing
dispatcher as selectable Classic. Do not weaken the interlocking or change
track geometry to obtain better results, except for the later explicitly
authorized Kollam three/three passenger-road correction. Trains that can get fully into a safe
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

## Kollam balance checkpoint

Six CSV passenger faces split D P1/P3/P5 and U P2/P4/P6. Main roads and every
edge outside QLN remain identical. All berths 630 m, physical directional routes
validated; 800-edge independent intersection audit passes. Seven Python tests,
937 source passes and 12 corrected formation tests; two native source views.
No runtime ground code changed: old fixed 460 m QLN_P4 samples now lie inside
the bridge after the ladder change, so tests use actual bridge-end chainage.
Authored Classic 100/140 times/calling patterns unchanged apart from compatible
QLN roads/markers. Prepared states remain deliberately rejected until replayed.
KPY/STKT fixtures are now isolated from mutable prepared days and the measured
priorities/positions are retained. See evidence/kollam README via progress.

Next priorities: V2 home/journey selector and clear live/baseline labels; validate
all third-party contender changes after accepting a plan, not just the selected
pair; full-rake/route-conflict regressions. Author a separate Intensive V2 with
staggered relief departures (avoid the current 11:20–12:35 KYJ platoon), keeping
K1's schedule unchanged. Freeze sim inputs, then rehearse Classic100/140 and
V2 Standard/Intensive plus disturbed V2; prepare matching starts/time/traffic.
No full-day preparation is running yet. Keep fixed six-hour active-work window.

## 25 October 2026 — V2 selection and live contender validation

Classic/Predictive V2 Standard 100 and Intensive 140 now have independent home
choices and prepared-data paths. Journey mode switching preserves route locks;
V2 pack import/export, save and timeline loading retain and verify mode. The
dispatcher shows following/passing lateness and extra slow-train detention.
All higher-priority contenders are rechecked when their control, priority,
speed cap or calls change. Corrected UTF-8 labels from the QLN edit.

Validation: **943 source tests**, **18 Node finalizer/wait/encounter tests** and
**11 native UI checks** pass. Native 720p/900p views reviewed; evidence at
`art/performance/dispatcher-v2-2026-10-24/selection`. Authored V2 Intensive candidate
staggers relief departures without changing K1 calls/dwell/equipment; final
spatial overtake results are not yet known. Finalizer/verification now distinguish
Classic and V2 and report each K1 passing station. Four compatible full-day
rehearsals are next. Existing prepared states remain incompatible with QLN until
regenerated; never bypass signatures. R46 remains the published release.

Playtest after preparation: all four day choices, service and five-minute
entries, traffic roles, Journey dispatch toggle, and save/reload mode retention.

## 25 October 00:30 — timing and disturbance audit in progress

The first four full-day jobs were deliberately stopped before finalization to
correct a forecast that could project a passenger working beyond its final
booked call. Their partial data remains under `.local/dispatcher-v2-2026-10-24/
rehearsals`; it is **not publishable**. A later tool-host process interruption
ended the first terminal-fix source suite early. Windows had not rebooted.
The documented LAN server was restarted and R46 again returns HTTP 200.

Current full source rerun: wrapper 5896 / child 20532, logs
`terminal-full-tests.log/.err`. Do not edit runtime/tests until it finishes.
Eight single-train timing probes (ICF, LHB, VB8, VB16 in each direction) have
completed. Comparing 32 forecasts against the road actually assigned gives
cautious errors -61.23 to +14.55 s; the configured clearance uncertainty covers
all sampled errors, with at least 26.49 s remaining. This is a bounded sample,
not a general accuracy guarantee. A larger initial QLN error came from main
P1 being changed to terminal loop P3 by actual dispatch; both road identities
are now recorded instead of silently comparing different routes.

Five bounded KPY/STKT disturbance cases now pass: baseline, manual passenger
pause of 3 or 10 minutes, manual express pause of 3 minutes, and operator-held
express. Both services progress beyond STKT, no safety events; longest
continuous unbooked stand across these cases is under six minutes. Replay
budget is 30 minutes **plus the injected pause**, so the ten-minute intervention
is not incorrectly treated as a stall at the next booked dwell. This does not
replace the dense whole-day disturbed rehearsal.

Additional read-only probe found that a newly spawned higher-priority follower
can leave earlier advice valid until refresh. After the running suite finishes,
add owner validation and regression for new/reprioritized contenders, then
freeze inputs and restart the four complete preparations and a disturbed run.
No prepared files or release artifacts have been replaced. Current changes
remain uncommitted pending full/focused verification. Keep the fixed six-hour
window; continue useful work rather than counting idle gaps.

## 25 October 00:51 — robustness checkpoint and fresh complete rehearsals

The terminal suite finished with 951 passes. After the new-contender owner
guard, the full rerun finished with **953 passes, zero failures**, stderr empty.
Fifteen focused owner tests pass, including new spawns, promotions and released
holds/emergencies before acceptance and after acceptance; unrelated traffic is
not spuriously rejected. Forecast/manual guards and diagnostic tools are ready
for commit. Calibration and five bounded disturbances are passing as above.

`async-live.json` adds real nonblocking live-worker tests, 33 simulation minutes
each, including a two-minute manual passenger pause. Normal case passes at
STKT_P3; the delayed case passes at KPY_P1. Both progress beyond STKT without
safety events and cleanly close worker tasks. Native views of the QLN approach
and platforms were reviewed after regenerating the stale render-only road
cache. Actual 27-tile road geometry, all 353 profile junctions and 122 rendered
junctions pass independent checks. See committed robustness evidence.

Five fresh jobs started **00:38:55**, records in `rehearsal-jobs-v2.json` and
outputs in `.local/dispatcher-v2-2026-10-24/rehearsals-v2/`:
Classic Standard wrapper27132, Classic Intensive4472, V2 Standard25816,
V2 Intensive9324, V2 Intensive delayed15572. The last injects600s manual K1
braking at simulation11000s; it has no baseline snapshots. All remain active
without stderr errors at this checkpoint. Keep simulation, route files and
authored candidate packs frozen. No source test suite remains running.

Next: inspect full audit results, use `tools/summarize-timetable-run.mjs` for
distinct K1 overtakers, station concentration and priority-group destination
delay. Partial counts are diagnostic only. Finalize each compatible baseline
only after all gates pass; do not publish the disturbed run. If candidate
Intensive timing needs adjustment, rerun that variant without invalidating
unchanged Standard/Classic sources. Then native-check the actual prepared V2
service/time entry and reciprocal traffic previews. The new operator guide is
`docs/predictive-dispatcher.md`. Continue the unchanged six-hour window; R46
remains live and no new executable build is authorized in this task.
