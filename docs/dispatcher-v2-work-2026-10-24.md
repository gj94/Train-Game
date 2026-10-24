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


## 25 October 02:34 — saved ETA audit prepared, waiting on final catalogues

Reviewed the exact predicted timing points: the slow train's receiving-road
stopping marker, versus the express's road entry. A new read-only tool,
`tools/audit_saved_forecast_arrivals.gd`, is parse-checked but intentionally
uncommitted until it has run successfully. It will compare fresh saved K1 advice
with completed actual booked arrivals, requiring the same road and stopping
marker and verifying recorded checkpoint/input hashes. It does not step a railway.
The sample is sparse (five-minute checkpoints), includes external traffic holds
and may contain advice subsequently replaced; it is calibration, not certification.

The first attempt correctly could not inspect a still-running replay because
its final timeline catalogue does not exist yet. The tool now rejects that state
explicitly and defaults to the final reference checkpoint once available. No ETA
result has been obtained or claimed. Run it after V2 Standard/Intensive finishes;
do not restart or duplicate preparation to make it available. No observer remains
running. Four original baseline jobs still run with frozen inputs; latest clocks
approximately Classic Standard00:50, V2 Standard00:20, Classic Intensive20:30 and
V2 Intensive20:00. The completed disturbed audit remains valid and separate.


## 25 October 02:45 — Standard baselines complete and installed

Both 100-service days pass all calls, depot, safety and individual wait gates.
Installed separately and independently checked all 4,833 inputs, 100 departure
files and 233 exact restored timeline states per mode. Actual native home/time
loaders pass 36 checks, reciprocal roles and dispatch mode preserved. Four screens
reviewed. WASAPI unavailable on the development session, so this menu test used
the fallback dummy audio driver; no audio claim. Full source suite running as
wrapper27304; do not edit runtime/tests until it finishes.

Source Standard timings are identical. V2 reduces sub-ten-minute wait failures,
but B012 reaches ERS 691.15 seconds later after different northern crossing
interactions. B031 and B020 also regress; explicit full comparison and actual
hold reasons are retained in standard-days evidence. Do not call V2 universally
better. Local overtake optimization does not globally plan opposing traffic.
The pending saved-ETA tool now runs successfully: seven forecasts for two distinct
SRTL/STKT K1 arrivals, error -7.27 to +0.95 seconds, all source/state hashes checked.
No railway stepping; sparse calibration only. Its UID now exists.

The prepared UI checker gained optional repeated --day= filters for independent
certification. Only Standard/Standard V2 were exercised; keep it uncommitted until
Classic/V2 Intensive checks pass. Original Intensive wrappers3708/22880 continue;
Standard wrappers24548/17876 and native16588/ETA23716 have completed. No duplicate
full replay, no sim/routes/pack edit, no new executable release.


02:52 checkpoint: all 961 full source tests pass, zero failures and empty stderr.
The two Standard variants, exact-source calibration tool and comparison evidence
are ready to commit. No source/native/ETA diagnostic remains running.


## 25 October 03:04 — complete Intensive audits rejected, minimal next candidates

Both original v3 Intensive jobs finished. All 140 calls/workings/depot clearance
and safety checks pass; independently verified4,834 input hashes per run. Classic
fails station-only98% under30min:161/165=97.5758%, with B054QLN2402s,K1KPY1974s,
B055QLN1922s,B026ALLP1880s. Its all-location wait targets pass;13 K1 overtakers
span8 stations,max5KPY. V2 passes all waits but has7 K1 overtakers at6 stations,
max2PVU. Both finalizers correctly reject. No Intensive prepared files installed.
Raw compressed audits, exact candidate packs and actual comparisons are preserved
under complete-days/candidate-one before any source timing edit.

The first-candidate V2 ETA observer completed successfully before editing inputs:
7 saved forecasts for2 actual arrivals,-9.39 to+6.05s,3 excluded. Sparse calibration
only. No original v3 rehearsal/observer remains running. Both Standard catalogues
are already certified and remain untouched.

Next candidate changes one Classic relief departure D10512:35->12:55 to break
B055's chained Kollam hold. Classic engine and the original hundred bookings
stay unchanged; only a new relief's name/departure change. V2 changes exactly
D10011:20->11:30,D10913:00->12:45,D11411:15->11:40. D105's V2 override stays14:15.
Field comparison proves those one/three edits only. No added dwell, changed
calls/equipment/priority/caps or forced pass station.8 headless operating-day
checks and4 Python guards pass;unchanged runtime previously961 full tests.
These timings remain unaccepted until complete replay. Run both revised Intensive
baselines with snapshots and both600s manual-K1 disturbances at11000, since the
Classic candidate also changed. Preserve the original failed evidence. No Standard
replays required. Keep simulation/routes/packs frozen for the new jobs.

## 25 October 03:15 — revised jobs running, launch isolation verified

`d01a6e3` is pushed. Four v5 replays began at03:14:04, with exact command lines,
separate output files, baseline dispatcher modes and empty stderr verified:

| Day | Wrapper / child | Output under `.local/dispatcher-v2-2026-10-24` |
| --- | --- | --- |
| Classic Intensive baseline |20980 /12884|`rehearsals-v5/classic-intensive`|
| V2 Intensive baseline |26924 /21812|`rehearsals-v5/predictive-intensive`|
| Classic 600s delayed K1 |13000 /14668|`rehearsals-v5/classic-delayed`|
| V2 600s delayed K1 |2808 /17656|`rehearsals-v5/predictive-delayed`|

Both baselines include departure/timeline snapshots. Both disturbances start at
simulation11000s and do not generate playable baseline states. Job records retain
the pack hashes and source commit; owned-processes has been refreshed. Do not
restart these or edit sim/routes/packs while they run. The original v3 jobs are
all complete and their failed-quality statuses are now explicit in the record.

The initial03:10 v4 launcher split `--output=res://` from its folder because of
PowerShell array-expression precedence. All four wrote shared root outputs; none
is valid. The newly started children were stopped after matching command lines,
creation times and parents (an initial broad stop was rejected by automatic
review; the evidence-scoped retry succeeded). Only newly created untracked root
outputs were moved into `rehearsals-v4/invalid-shared-output`, with exact resolved
paths and timestamps checked. Nothing was deleted. Fixed v5 arguments are each
one interpolated string. Their recorded command lines and files confirm isolation.
No completed v3 audit, certified Standard catalogue, editor or R46 server changed.

Next: inspect completed v5 gates and actual K1 distinct/spatial passes before any
installation. If a variant passes, certify it independently; retain all failures.
Then run actual `intensive`/`intensive_v2` native prepared-menu checks and commit
the currently untracked checker only after both pass. Standard choices already
passed36 native checks and need no repeat. No executable release requested.

## 25 October 03:21 — complete-day planner equality audit pending

Added an independent read-only diagnostic, currently uncommitted:
`tools/audit_forecast_parallel_consistency.gd`. It reads the certified Standard V2
timeline, checks source/state hashes and compares inline with one/two/four-worker
proposals at every saved five-minute state. It also checks that detached inputs
and the live restored railway remain byte-identical. This broadens the previous
single-checkpoint equality check without stepping or regenerating a timetable.
It is not a performance benchmark or proof of identical live asynchronous timing.

Parse check passed. Wrapper27208/child18800 started03:19:20; output is
`.local/dispatcher-v2-2026-10-24/parallel-consistency-standard`. No final result
yet; keep the tool uncommitted until exercised successfully. Four v5 full-day
jobs continue with frozen inputs; no runtime/preparation observer changes.

03:29 continuation: equality audit reached100/233 checkpoints with no errors;
all four v5 day jobs still run. Clarified the operator guide: switching the
planner mid-journey preserves the current timetable and delays, whereas choosing
the V2 Intensive day supplies its authored departures; baseline traffic remains
historical. Updated source preparation status and retained the measured B012
regression explicitly. These documentation edits and the audit tool remain
uncommitted pending the diagnostic's final result. No runtime inputs changed.

03:38 provisional observation: candidate-two V2 traffic through12:17 has five
distinct K1 overtakers: B001 atTUVR, B024 atALLP, and B002/D100/D114 atSTKT.
The two retimed reliefs now pass K1 instead of starting ahead of it. Three passes
at one station remain the current maximum. This is incomplete midday evidence,
not the ten-pass/spread/wait certificate; no timing edit follows from it. Local
`candidate2-midday-partial.json` retains the partial-data warning. The complete-day
planner equality audit has reached180/233 without errors; all five jobs continue.

## 25 October 03:43 — all prepared-state worker comparisons pass

Read-only equality audit completed233/233 Standard V2 states and699 worker
comparisons with no failures or stderr. Every detached input and full restored
railway remained byte-identical.4,833 source fingerprints and all state hashes
checked; maximum23 active planning inputs. Both directions and pass/follow
proposals are represented:154 northbound/144 southbound,246 follow/52 pass.
These are proposal observations across time, not counts of actual overtakes.
Wrong-mode negative check exits1 and writes no report. Wrapper27208/child18800
have finished. Evidence is in `art/performance/dispatcher-v2-2026-10-24/parallel-consistency`.

The diagnostic and clarified operator guide are ready to commit. No runtime,
route, pack or preparation observer input changed; prior961 source tests still
apply, and the new diagnostic itself has completed its full headless acceptance
and rejection checks. Four original v5 day jobs continue. Do not repeat the
Standard replay or its native menu checks. Intensive prepared-data/UI gates
remain pending. No executable release requested.

## 25 October 03:59 — candidate-two afternoon evidence, not final certification

Read-only traffic through14:55 records ten distinct K1 overtakers across six
stations: B001TUVR, B024ALLP, B002/D100/D114STKT, D101/D109PVU,
B055/D102KVU and B025KZK. Maximum three at one station; the revised timings
have now produced the intended added encounters. The source jobs are still
running; do not install or claim complete safety/wait certification from this.
Local `candidate2-afternoon-partial.json` retains its partial-data warning.

Independent read-only extraction of both15:00 snapshots, with unchanged file
hashes, shows Classic B055 departing QLN13:03:36 versus first-candidate13:18:36
(a fifteen-minute improvement). B054 still leaves12:41:08. V2 K1 reaches
TVC14:51:38/departs14:54:43; STKT11:44:31–12:01:05, PVU12:51:50–13:02:16,
KVU13:35:48–13:47:18 and KZK14:22:12–14:24:47. These actual calls are saved
in `candidate2-calls-at-1500.json`; origin arrival fields marked-1 are not failed
calls. No railway stepping/mutation or full simulation restart was involved.

Continue the four original v5 days, then verify the complete wait denominators,
all calls/depot/safety, source hashes and final encounter distribution. Current
partial success does not justify more timing changes. Standard data/checks are
unchanged. No executable release requested.

## 25 October 04:27 — revised disturbed days completed and verified

Both original v5 manual-delay jobs have finished: Classic20980 is still its
baseline wrapper, but Classic disturbed13000/14668 and V2 disturbed2808/17656
are complete. Rehearsal records now identify them as completed_verified.
Each audit has140 completed services,1726 valid arrivals/1726 departures,
all stabled,zero safety events and4834 matching source hashes. Independent
wait accounting passes both station-only and all-location70/90/98/100 targets.
Classic all-location79.52/97.59/99.60/100%,station73.94/96.97/99.39/100%;
V2 all-location86.69/98.29/100/100%,station82.12/97.77/100/100%.
Max continuous waits31m22s/27m32s; K1 lateness28m39s/28m14s. Both K1s have
11 distinct overtakers across9 stations; maximum2 Classic/3 V2 at one station.

New independent headless verifier derives encounters directly from each run,
checks source hashes, complete traffic sample coverage/final clock, all calls,
wait reason totals and gzip byte round-trips. Baseline and wrong-mode negative
cases reject exit1 with no evidence output. A local initial import typo and raw
versus normalised pack-hash assertion were corrected by checking the actual
observer semantics; final verifier passes both complete runs. No railway input
or preparation observer changed; prior961 full source tests remain applicable.

Evidence and exact raw packs: complete-days/candidate-two. Do not publish either
manual-delay run as baseline states. Classic20980/12884 and V226924/21812 baseline
jobs remain running with frozen inputs. Continue final safety/wait/call/hash/
distribution gates, then compatible installs and actual Intensive menu checks.
No further timing edit follows from provisional success; no executable release.

## 25 October 05:09 — both baseline variants and all four menu choices accepted

All v5 jobs have completed. Both undisturbed 140-service days pass every call,
depot clearance, zero-safety gate, source fingerprint and both wait-distribution
checks. Installed Classic and V2 each have 140 departure snapshots and 233 exact
five-minute states, checked independently after finalization. No source or
observer hash was relabelled. Earlier failed candidates and manual-delay audits
remain separate evidence. No further authoring changes are needed.

Classic station-only waits under thirty minutes now pass 160/163 (98.1595%).
Classic K1 has twelve distinct overtakers across eight stations, maximum five
at KPY. V2 has eleven across seven stations, maximum three at STKT; K1 delay
561.70s versus Classic 2811.65s. V2 station waits under ten minutes are 83.63%
versus 73.62%; all V2 waits are under thirty minutes. Keep the tradeoffs explicit:
fifteen authored departures differ, priority 75/85 destination means regress,
and B003/B020 finish 1067.90/1197.60s later. Actual call/hold evidence is retained
in intensive-days/priority-hold-evidence.json.

55 native checks pass for real Intensive service and noon-time restoration;
four screenshots reviewed. Combined with previous 36 Standard checks, all four
menu choices are exercised. Actual V2 noon K1 is STKT_P3 loop and D114 main P1
at about 89 km/h. Full source suite after install: 961 passed, zero failed,
empty stderr. Wrapper16584 and native27580 finished. The prepared UI checker
can now be committed. Raw audits, summaries, comparisons, verification logs,
source tests and native evidence live in intensive-days.

Playtest: Predictive V2 / Intensive 140 / K1, inspect 55 stops and 37 encounters;
check reciprocal service roles, then Explore12:00 and join K1 at STKT. Manual
lateness can change future events; fresh Forecast details are advisory. No
executable release. Continue useful read-only ETA validation to finish the
remaining actual six-hour requirement; do not repeat accepted full-day replays.

## 25 October 05:18 — all-service ETA audit caught a real dwell boundary defect

Read-only audit:233 states,4834 fingerprints,34 samples/16 actual arrivals/14
trains, both directions and ICF/LHB. Six optimistic observations beyond own
uncertainty represent three arrivals. B042/D129 have intervening holds and
changed pass stations. K1's 149.08s error is explained by losing its150s KPY
dwell when a forecast is captured0.5s before berth acknowledgement, inside the
old one-metre skipped-call threshold. Source and trace evidence retained in
eta-dwell-boundary; no exact missing forecast frame is fabricated.

Two new regressions fail on old source (14 focused passes,2 failures), then
pass after retaining pending calls down to the existing1cm route tolerance
(16 passes). Both directions,exact marker and later booked departures covered.
Full source suite wrapper5996 is running; freeze runtime/tests until complete.
No other simulation/track/authoring changes. Classic data commit36298eb pushed;
V2 pre-fix data remains local/uncommitted and is preserved in originalv5 output.
Do not push obsolete prepared data as final. All four variants need matching
fresh preparation because the source manifest changed. Also rerun both140-day
manual-delay audits. Keep all acceptance gates unchanged. R46 remains live.

Next: finish source tests,commit/push coherent fix+diagnostic+evidence,then start
one isolated v6 job per required variant. Keep six preparation observers and
runtime/routes/packs frozen during those jobs. Old source evidence remains
historical; do not relabel hashes. Repeat native menu checks only after newly
compatible data is installed. Useful broader validation,not idle waiting,counts
toward the remaining active-work requirement.

05:25 final boundary review: first correction passes all963 source tests, empty
stderr. An additional manual-overshoot case within the1.1m berth tolerance
showed that an unacknowledged past call could still be skipped. The pending-call
input contract requires declining onward advice instead. Regression fails
before (16pass/1fail) and passes after (17pass), both directions. Final complete
suite wrapper18140 now runs in dwell-final-full-tests.log/.err. Do not edit
runtime/tests during it. This is the final intended runtime change before v6.

The guarded six-job launcher is prepared at .local/dispatcher-v2-2026-10-24/
launch-v6.ps1 but NOT EXECUTED. After final tests, commit/push the source fix,
three regression tests, exercised ETA audit/UI checker and historical evidence.
Keep obsolete untracked data/timetables/intensive_v2 separate until regenerated.
Then launch v6 once: four baseline mode/day combinations with snapshots and both
Intensive600s manualK1 disturbances at11000. All authored packs remain unchanged.
The launcher refuses existing v6 outputs or active preparation jobs and records
full isolated options/PIDs/source commit in rehearsal-jobs-v6.json. Verify actual
child command lines, modes and stderr. No earlier full-day job remains active.

## 25 October 05:32 — final ETA correction passes the complete source suite

Final source:964 tests passed,zero failed,empty stderr. Wrapper18140/child13936
have finished. Logs are archived in eta-dwell-boundary. All three new regression
tests have failed before their corresponding correction and passed afterward.
The source fix, exercised all-service ETA diagnostic and native prepared-menu
checker can now be committed with historical evidence. No pending test process
remains. Six fresh compatible preparations will use this exact committed source;
all previous prepared measurements remain clearly labelled pre-correction.

## 25 October 05:33 — six compatible v6 runs launched and verified

`b28e2c1` is committed and pushed: final forecast boundary fix, three regressions,
all-service saved-ETA audit, actual four-menu checker and historical evidence.
964 full source tests pass, empty stderr. v6 launcher ran once after confirming
no old preparation process remained; all child command lines and separate output
arguments were independently checked. Initial baselines match planner mode and
corrected forecast fingerprint; stderr is empty for all six.

Original v6 wrappers/children:
- Classic Standard15212/2408; V2 Standard28212/27324.
- Classic Intensive23696/12848; V2 Intensive18904/19932.
- Classic delayed7700/19636; V2 delayed16160/28452.

Read rehearsal-jobs-v6.json and rehearsals-v6 folders. Both delayed cases use
manual K1 for600s at simulation11000 and never become baseline states. Preserve
runtime/routes/packs/six preparation observer inputs until completion. No more
authoring or runtime changes are planned. The next useful work is full outcome
analysis, independent finalization and current source-native menu checks, then
all-service ETA calibration on the new actual states. Avoid repeating old
unchanged validations. No executable release; R46 remains available.

## 25 October 06:51 — corrected-source disturbed days independently accepted

Both v6 manual-delay processes have finished. Fresh source b28e2c1, unchanged
candidate-two authored packs, 600s manual K1 brake at simulation11000. Each
140-service run has every call/departure/depot complete, zero safety events,
4834 matching current source hashes, 1726 arrivals and1726 departures, and34801
unbroken two-second traffic samples. Both all-location and station-only
70/90/98/100% wait gates pass; Classic maximum1882s, V2 maximum1652s.
K1 lateness1719.2s/1694.2s, eleven distinct overtakers/nine stations each,
maximum2/3 at one station. Independent verifier, run summarizer and comparison
all exit0. Evidence is in complete-days/eta-corrected; old candidate-two retained.

New replays reproduce the previous service records and traffic hashes exactly
for these two interventions; only sim/dispatch_forecast.gd differs among input
hashes. This is limited observed equality, not global runtime equivalence or
hash relabelling. Destination and intermediate-call regressions remain visible:
priority75 mean394.78->555.16s, priority85 mean818.80->822.18s; B056+1391.85s,
B020+1197.60s. Fifteen authored departures differ between Classic and V2, so no
planner-only attribution. Never install disturbed runs as baseline data.

The original four v6 baselines remain active: ClassicStandard15212/2408,
V2Standard28212/27324, ClassicIntensive23696/12848, V2Intensive18904/19932.
No runtime/route/pack/preparation observer edits or additional replays. The964
passing source tests remain applicable. Final baselines, native all-four-menu
checks and corrected all-service saved-ETA inspection are still pending.

## 25 October 07:14 — corrected Standard pair verified and native-tested

Both original v6 Standard jobs completed. Finalizers and independent installed
starts/times/traffic verifiers pass: every100 service/call/depot,1530 arrivals
and1530 departures each,zero safety events,4833 current source fingerprints,
100 starts and233 exact five-minute states. Both all-location and station-only
wait gates pass. Classic maximum1696s, V2 maximum1774s; three distinct K1 passes
per mode (the ten-pass gate belongs to Intensive). Classic data6713f65 pushed;
V2 data17d8672 committed with its separate push. Old v3 source evidence remains
historical. Current evidence: art/performance/dispatcher-v2-2026-10-24/
corrected-standard-days, including raw gzip audits, comparisons and finalizers.

Native actual-menu/time check:36 passed,zero failures,four1280x720 screens
reviewed. Compatibility renderer emits one screen-space-AA availability warning;
Dummy audio used. No audio/FPS claim. Noon Classic K1 approachesPVU at81km/h,
V2 stands atPVU. Both show55 booked stops and22 reciprocal traffic events.

Corrected all-service ETA audit:233 states,4833 hashes,19 comparable forecasts
for8 arrivals/7 trains,both directions,ICF only. Error(actual-predicted)
-10.85..+403.69s,median-4.48,p90+4.69;one uncertainty exceedance. B042 forecast
at10:14:55 proposesMAKM/B002, but remains atTUVR until10:20:51 (356.25s later).
At10:15 saved state its call is acknowledged and passenger_release already past;
this is not the omitted imminent dwell case. Actual788s TUVR extra wait includes
482s opposingB039,246s B002 pass,56s block,4s authority; actualB002 pass isTUVR
and later saved plan absent. Four hashed snapshot selections and full calls/holds
preserved. Exact origin frame is absent; do not claim isolated causal proof.
K1 seven forecasts/two arrivals still-7.27..+0.95s. Sparse calibration only.

Standard B012+691.15s,B031+1292.05s,B020+1197.60s and K1+78s remain reported.
Both Intensive baselines still run:23696/12848 and18904/19932,stderr empty.
The original964 passing source suite applies; no runtime/test/observer edits,
new full-day launch, or executable release. Final Intensive acceptance/native
checks and the specific corrected KPY boundary audit are next.

## 25 October 07:33 — corrected Intensive accepted; all validation complete

The original v6 Intensive baselines completed and are independently certified
and installed: 140 services, all calls and depot clearances, zero safety events,
all exact station-only and all-location wait targets, 4,834 current fingerprints,
140 departure states and 233 exact five-minute states each. Classic has twelve
K1 overtakers across eight stations; V2 has eleven across seven. Classic data
is pushed as `d993880`; V2 as `8e20eca`. The 55 actual Intensive menu/time checks
pass with four reviewed screens, completing 91 checks across all four corrected
choices. The unchanged source retains its 964 passing full tests. Both corrected
manual-delay audits already pass and remain disturbance evidence only.

The corrected Intensive ETA audit checks 233 states and 34 forecasts for sixteen
arrivals/fourteen trains. The affected K1 forecast changes from 149.08s early to
13.70s late after retaining the imminent KPY call; all other matched samples are
unchanged apart from state hashes. Five B042/D129 uncertainty exceedances remain,
with later holds and replaced passing plans documented. Sparse sampled forecasts
are not a global accuracy certificate. Priority 75/85 means and B003/B020 still
regress; fifteen authored departure changes prevent planner-only attribution.
[Complete corrected Intensive evidence](../art/performance/dispatcher-v2-2026-10-24/corrected-intensive-days/README.md).

Playtest both Intensive choices: select K1, inspect 55 Stops and Traffic, then
Explore at 12:00. Classic waits at KPY; V2 waits in the STKT loop while D114
passes on the main. Standard pair checks and ETA evidence are already complete.
R46 remains available; no new executable release. No replay, suite, native or
ETA job remains, and no additional runtime or authored changes are planned.

## Final handoff — 25 October 07:35 Asia/Singapore

All requested current-source validation is complete and pushed. The fixed
22:33:56 start was preserved, the 04:33:56 deadline passed, and at least
21,607 actual active seconds are recorded including this session, excluding
idle gaps. Full data/evidence commits: d993880, 8e20eca and 1b73641.
The local ledger retains every work session and will close after final cleanup.
The continuation automation was deleted through the app; no additional work is required.
Other completed map/QoL automations remain paused. R46's LAN landing page returns
HTTP 200 and its existing 3,589,389,055-byte ZIP remains available. No release
files were changed. Tracked source is unchanged from the 964-test correction;
all original replay and diagnostic jobs are finished.
