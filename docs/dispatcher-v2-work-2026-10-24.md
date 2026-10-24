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

## 25 October 01:06 — paused deletion/save regression

Read-only command-path probing found a structural save failure: with automatic
dispatch disabled, deleting B002 left K1's accepted V2 plan referencing that
missing service. An immediate save failed restoration with `Missing predictive
dispatcher participant`. A captured worker result could also be accepted after
deleting and reintroducing the same ID with identical inputs. Both regressions
failed before the fix. Rejected deletion must not invalidate good advice.

Validated deletion now clears forecast advice and advances its membership
generation before removal, independently of whether dispatch is running.
Pending work is rejected on receipt without a blocking join; existing route
cleanup remains unchanged. Eighteen owner tests and five deletion tests pass;
the direct probe now round-trips both enabled and disabled dispatcher saves.

The five `rehearsals-v2` jobs were explicitly stopped at01:02 and recorded as
diagnostic partials. They must never be finalized or relabelled with new source
hashes. New complete `rehearsals-v3` jobs start01:06 (see
`rehearsal-jobs-v3.json`). The full source suite is running as
`deletion-full-tests.log`; do not edit runtime/tests until it completes, and
keep sim/routes/pack inputs frozen for the new complete rehearsals.

`tools/check_predictive_prepared_ui.gd` is newly parse-checked but not yet run:
run it only once certified data is installed. It checks all four actual menu
rosters, departure mode/identity, noon timeline worker loading and reciprocal
K1 traffic. Do not commit it as validated until it has run. A read-only10:30
Standard comparison showed some priority services improving and others later;
wait for full destination-delay results rather than claiming universal gains.

## 25 October 01:16 — native command validation and comparison tooling

The paused-delete fix passes the actual dispatcher confirmation flow at720p:
11 native checks, no stderr. Keep service preserves the entire snapshot;
Delete service retains K1 and returns controller focus to its roster entry;
an immediate save then restores exactly. Two captures were visually reviewed.
Reproduction is now `tools/check_predictive_commands.gd`; committed evidence
will be under `art/performance/dispatcher-v2-2026-10-24/commands`.

A read-only `tools/compare-timetable-runs.mjs` reports matched destination delay
changes by priority, both improvements and regressions, K1's result and wait
quality. It explicitly labels comparisons with changed authored departures so
those gains are not attributed to the dispatcher alone. Eighteen assertions
cover delta signs, unchanged values, changed-departure labels, unmatched IDs,
priority mismatches and incomplete/non-stabled results; the existing completed
140-service report compared with itself produces no spurious deltas. This does
not replace the separate safety/call/wait/fingerprint finalization gates.

At this checkpoint the full source suite and five frozen v3 railway jobs are
still running without stderr errors. Do not edit sim/routes/packs or restart
these jobs. Keep the prepared-menu checker uncommitted until installed certified
data exists and it has actually run. R46 remains available; no build prepared.

## 25 October 01:17 — deletion fix fully validated

All **956 source tests pass**, zero failures and empty stderr. The verified
native command tool and18 comparison assertions also pass. The fix and evidence
are ready for commit/push; no runtime/test edits were made during the full suite.
The five v3 full-day replays continue with frozen railway inputs and no stderr.
The first two rehearsal generations remain diagnostic partials only.

Use `tools/compare-timetable-runs.mjs <classic-folder> <v2-folder>` after each
matching pair finishes, in addition to the encounter summary and finalizer.
Do not mistake the Intensive authored-departure comparison for a pure dispatcher
benchmark. The next required evidence is actual complete K1 pass distribution,
all-service safety/completion/wait quality, then compatible data installation
and real prepared menu checks. No executable release is requested here.

## 25 October 01:32 — live forecast explanation (presentation only)

Read-only worker ownership audit found no new sharing issue: detached frames and
constructor-copied topology, per-solver route caches, preallocated result slots,
one pending group, and owner-side acceptance remain intact. Existing tests cover
input mutation, worker close/reuse and parallel versus inline equality; no repeat
benchmark was needed while five full-day jobs contend for the development CPU.

Added a collapsible Forecast details section to the dispatcher inspector. Either
participant can see the same valid proposal: station/roads, passenger-clear and
priority-entry ETAs, margin after allowances, following/passing lateness at the
comparison point and extra detention. Locate focuses the passing station; Inspect
changes only the inspector, retaining the player's service. Expired proposals
remove obsolete actions and restore controller focus; Classic hides the section.
Midnight ETAs identify the new operating day. Following-order advice does not claim
that a loop is allocated or that an overtake will occur.

Five focused tests and18 native Forward+ checks pass. Reviewed720p/900p expanded
views and reciprocal inspection; no stderr. Native actions preserve the complete
railway snapshot byte-for-byte. Source diagnostic:
`tools/check_forecast_details_ui.gd`; local captures/result in `forecast-ui`.
Full source suite started01:31, wrapper26996, `forecast-full-tests.log`.
Do not edit runtime/tests until complete. This presentation work changes neither
sim/routes nor packs; all five v3 complete-day jobs remain valid and running.

The prepared-menu checker still awaits installed certified data and remains
uncommitted. Candidate relief services originate KYJ/QLN; later departures are
intentionally spread through the corridor. Only actual complete encounter records
can certify the required distinct K1 passes; do not tune from raw schedule overlap.

## 25 October 01:42 — forecast inspector fully validated

All 961 source tests pass, zero failures/empty stderr. Native18 checks and reviewed
720p/900p views are committed with the read-only forecast inspector. No simulation,
route or authored-pack inputs changed; do not restart any of the five v3 jobs.
The partial12:35 encounter comparison confirms B002 passes K1 atSTKT in the full
V2 run rather thanKPY, but only three distinct passes had completed then; final
count/distribution and wait gates remain pending. Local partial notes explicitly
separate changed authored timing from planner effects. Do not certify from them.

Next remains final all-day analysis/certification, compatible data installation
and `check_predictive_prepared_ui.gd` on the real four day options. Preserve the
fixed further-work window and active-time accounting. R46 remains the release.


## 25 October 01:54 — actual passing-road witnesses

Added a read-only checkpoint observer, `tools/audit_overtake_roads.gd`, to
recover actual occupied roads during a measured overtake. It checks the
rehearsal's frozen source hashes, restores the preceding five-minute state,
uses deterministic offline forecast execution, and compares every active
train's head/centre/tail with the original two-second traffic samples. It does
not alter, finalize or install prepared data. Incomplete trailing recording
writes are skipped; malformed complete samples and stale source hashes fail.

The current Classic Intensive witness has K1 on KPY_P1/main and B002 on
KPY_P4/loop at 11:44:28, both at booked stops. The V2 candidate has K1 on
STKT_P3/loop while B002 runs through STKT_P1/main at 88.56 km/h at 11:52:36.
K1 stops at Sasthankotta and B002 does not: this is the requested kind of pass,
verified from actual railway movement rather than only a solver proposal.
The 220/89 samples match within 0.000001 m and both final runs have empty
stderr. Deliberately wrong source hashes are rejected before replay. Evidence:
`art/performance/dispatcher-v2-2026-10-24/observed-roads`.

The Intensive departure changes still confound planner-only attribution. Six
provisional K1 passes were independently recovered locally at TUVR, ALLP, STKT,
PVU (two) and KZK; the full-day count/waits remain pending. The five original v3
jobs continue with unchanged inputs; do not restart them. Source suite
`roads-full-tests.log` completed: all 961 tests pass, zero failures and empty
stderr. No source suite remains running. Prepared-menu check remains pending.

Read-only relief timing analysis is in local `relief-coexistence-notes.md` and
`calls-at-1530.json`. D100/D114 were already ahead when inserted, while several
later reliefs miss K1 before their terminal. Do not tune the frozen inputs yet;
inspect the final K1 count, then use those observed windows if the candidate
fails ten distinct overtakers. A final-day test is still required for any change.


## 25 October 02:13 — full-traffic live worker stress

`tools/check_predictive_busy_async.gd` validates every frozen rehearsal input and
restores T045300 from the actual V2 Intensive run. Its detached live railway
advances 30 minutes with 30 active services and five new arrivals. Nine owner
commands exercise manual K1 braking/AI handover, D101 operator hold/release,
D108 reprioritization/restoration, both mode switches, then exact save/reload
while a forecast job is pending. No safety events or missed calls; K1/D101/D108
advance 10.42/27.75/22.74 km. Forecast work occurs off-owner, restored state has
no worker handles, and shutdown joins cleanly. This is a functional test under
five competing replay processes, not a performance or full-day certification.
Evidence is in `art/performance/dispatcher-v2-2026-10-24/busy-async`.

No sim/routes/packs changed. All five v3 full-day jobs continue and must finish
before baseline tuning. The full source suite passed 961 at the previous
unchanged-runtime checkpoint; all 18 focused predictive owner tests also pass
with empty stderr. No suite or stress observer remains running. Do not repeat native UI checks for this tool-only
increment. The actual prepared-menu checker still awaits certified data.


## 25 October 02:15 — first-candidate K1 count fails the target

K1 has completed and is stored in the17:15 V2 Intensive checkpoint, arriving
NCJ16:34:52. Its complete working has seven distinct overtakers across six
stations (maximum two atPVU), so the first candidate does not meet the requested
ten. B003 atERL is the final recorded pass. The full railway is still running;
finish its wait/completion audit before altering frozen inputs. This is a
candidate rejection, not a reason to weaken the gate or change dispatch policy.

Local `calls-at-1715.json`, `partial-v2-0214.json` and updated
`relief-coexistence-notes.md` explain the missed relief overlap and a minimal
three-departure hypothesis. No timings have changed yet. After all current jobs
finish, retain their evidence and rerun affected V2 Intensive baseline/disturbed
variants after any authored adjustment. Classic/Standard certification is
independent; do not restart unaffected variants. No new build was prepared.


## 25 October 02:22 — complete disturbed day passes

The first V2 Intensive candidate with a 600-second manual K1 brake at simulation
11000 has completed all 140 services and all calls/departures, with depot clearance
and no safety events. Independent verification checks 4,834 source hashes and
recomputes every wait distribution/reason total. Of meaningful extra waits, 86.81%
are under ten minutes and 98.26% under twenty; all are under thirty. Station calls
alone meet the gates too (82.29% / 97.71% / 100%). Maximum continuous wait is
27m32s; K1 arrives 26m56s late. Its nine distinct passes span seven stations.
This validates the disturbance, not the ten-pass baseline; never install it as
prepared data. Compressed raw audit and summary are in the `complete-days`
validation artifacts. Wrapper10876/child21092 have finished; the four baseline
jobs continue unchanged. Finish them before changing any authored timing.

Added four fast Python guards for the permitted authoring boundary: preserve
Classic/Standard, only declared Intensive departures/names may change, K1 working
is identical, and generated files match the authoring source. All pass. No sim,
route or pack input was edited and no new baseline was started.


## 25 October 02:25 — inspect intermediate punctuality too

Extended the independent comparison tool to measure each matched arrival and
departure, grouped by priority. Destination recovery can otherwise hide the
express delays V2 is meant to avoid. Platform changes retain station identity;
midnight remains an absolute day time; origin arrivals/terminal departures are
excluded; missing actual calls fail and changed calling patterns are reported.
Changed scheduled event times remain explicit. Each call is one observation,
not a per-service or passenger-weighted result.

21 new assertions and 18 existing comparison assertions pass. A complete real
audit self-comparison covers all 3,452 booked events with no missing comparisons
or spurious changes. Four authoring guards pass too. These are tools only, not
among the six frozen preparation observers or railway input hashes. All four
baseline jobs retain unchanged inputs; no extra full-day work has been started.
