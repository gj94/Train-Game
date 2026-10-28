# Passenger movement, sound and a through railway — 26 October 2026

## Authorized window and scope

Started **26 October 2026 02:00:24 Asia/Singapore**, with a fixed **10:00 AM**
deadline. The user authorized continuous coach-to-coach walking through gangways,
stronger nearby bogie/clack transmission at coach ends, passenger-view passing
audio without head-turn dropouts, boundary portals for long-distance traffic,
and a sensible new timetable of **at least 200 services throughout day and night**.
Locals, mail/express, superfast and Vande Bharat should differ through their
calling patterns and stock performance; VB's distributed traction provides its
acceleration advantage. Overtakes must emerge from traffic and safe dispatch.
Do not introduce forced passing sites, padded passenger dwell or artificial
category speed caps to manufacture the result.

R47 remains the published build. The completed dispatcher work and its historical
evidence remain intact. Classic remains selectable; V2 remains asynchronous and
advisory, with interlocking the sole route authority. Preserve Kollam's authorized
six passenger roads split three per direction. No subagents.

Continuation automation: `train-game-gangways-sound-and-200-service-railway`.
Ledger: `.local/realism-2026-10-26/window.json`. Preserve the fixed start and
session history; exclude inactive gaps. At 10:00 stop adding scope, finish or
safely checkpoint verification, report remaining work honestly and delete the
continuation automation. Other completed automations remain paused.

## Implementation and evidence plan

1. Reproduce passenger audio loss with fixed-position head rotations and compare
   rail impacts/rolling against passing air. Preserve approved generated banks;
   changes belong in propagation/mixing or the source sound lab.
2. Replace prompted gangway jumps with continuous traversal, preserving world
   position and view direction across coach transforms, curves and reversed
   vehicles. Keep locomotives inaccessible from passenger coaches. Verify actual
   rendered entrances/floors and walking on ICF, LHB and VB.
3. Add safe corridor entry/exit portals and persistent off-map service identity.
   Entry must respect occupancy and routes; exit requires full-tail clearance.
   Preserve save/load and service completion accounting.
4. Research service routes and calling patterns. Clearly distinguish real-service
   references from authored additional workings and representative timings.
   Do not silently route Kottayam-only trains through Alappuzha. Author at least
   200 services, with meaningful overnight activity and midnight handling.
5. Test stock acceleration and stopping-pattern hierarchy, calls, full-day
   completion, safety, waits and naturally distributed passing. Freeze inputs
   during complete rehearsals; never relabel incompatible prepared fingerprints.
   Install only independently verified starts/time states/traffic previews.

## Initial inspection, 02:05

Clean tracked source at `676c9a1`; unrelated untracked media/imports are preserved.
No replay, test, editor or Blender job is running. Existing walking explicitly
changes coach with a fade and position jump; its navigation is per-coach baked
floor space. The audio uses real bogie sources and a stereo distance law; head
rotation should pan without removing energy. The precise dropout cause is not
yet established. Closed coach-end transmission currently lacks a separate
gangway/adjacent-bogie treatment. No code changes or new validation claims yet.

## Research status

Official Indian Railways train-schedule enquiry is the primary starting point:
https://www.indianrail.gov.in/enquiry/SCHEDULE/TrainSchedule.jsp . Service patterns,
coastal versus Kottayam routing and operating-day assumptions still require
verification. A 200-service representative game day must not be presented as an
exact current real-world timetable without evidence.

## Jobs and next checkpoint

Audio full suite 23356 completed: 969 passed, zero failures, empty stderr.
Native before/after probes 10920/14388 and old-scheduler delayed-only 23264 are
finished; actual PCM evidence is archived under `art/performance/realism-2026-10-26/audio`.
The expected old-source delayed-contact failure is preserved. Fixed-position
head turns did not reproduce a mute. Blender census 16728 completed read-only
inspection of six pinned ICF/LHB/VB model sources; no source asset was changed.
The official 2018 Southern Zone timetable PDF direct download timed out; search
index confirms table 12 is the coastal route, while 16347/48 uses table 11.
It is a historical reference, not a current timetable claim.

Next: continuous connected gangway navigation with matching visible openings,
then boundary lifecycle and the new representative operating day. No test,
native, Blender or full-day replay job remains at this checkpoint.

## Continuous gangways verified, 03:16

Continuous walking now follows actual moving coach-end frames, including reversed
VB cars and curved formations, with no fade or coach teleport. Flexible floors,
sides and roofs bridge connected cars; disconnected ends stay closed and WAP-7
locomotives remain inaccessible from passenger stock. Footstep distance continues
across the join. Private compartment prompts remain separate.

The source-derived 32 cm body clearance exposed real narrow passages in LHB 2A,
GS, SL and VB DTC. Four exported interiors received small documented partition
translations; passenger seats, capacities, stock physics and source masters stay
unchanged. All 21 passenger models now have continuous main passage navigation.
Generated material graphs match their previous used values; a new shader filename
needed explicit livery recognition. Occlusion was rebaked and all 22 asset audits
pass against documented source-derived geometry.

Validation: **976 full headless tests passed**, zero failures and empty stderr;
seven new gangway regressions; five rendered ICF/LHB/VB traversal cases; actual
main-scene controller/camera/audio integration **139 VB and 203 ICF checks**, zero
failures. The initial ICF fixture wrongly chose occupied seat zero; it now uses
the same available-seat query as the real coach directory. No sitting-distance or
NPC-occupancy rule was weakened. Native compatibility-renderer AA/SSIL warnings
are retained; Dummy audio checks do not establish hardware sound or frame rate.
Evidence and reviewed screenshots: `art/performance/realism-2026-10-26/gangways`.

Playtest: stand in an ICF, LHB or VB aisle and walk through both ends without
pressing Interact. Turn around halfway over a gangway, walk back, then continue
into the next coach on a curve; check the trailing reversed VB cab connection.
A disconnected end must block movement. Sit in an unoccupied seat and listen for
continuous footsteps and stronger nearby-bogie sound at the coach ends.

All gangway native, import, Blender and test jobs have finished. Next: safe
boundary lifecycle, representative 208-service authorship and full-day evidence.

## Boundary railway and representative authorship, 03:29

The optional extended railway adds separate entry and exit roads beyond ERS and
NCJ. The original layout remains unchanged when this option is absent. Scheduled
entries still need a free road and normal route authority. An exit is acknowledged
only beyond the last timing marker with the full formation on its outward road;
the train then leaves the active railway without a fictitious passenger stop or
depot working. Full origin/destination/category identity survives pack and save
round trips. The player receives an explicit paused continuation page and a
station camera after their train leaves the modeled section.

The new Classic and V2 packs have **the same 208 services**: 40 passenger locals,
104 mail/express, 56 superfast and eight VB. There are 168 through journeys, 67
departures between 22:00 and 06:00, and four to thirteen departures in each hour.
The final booked map endpoint is next day 04:08:12. Calls and real stock physics
create the category hierarchy: a matched coast-length route has progressively
fewer calls and shorter booked running times. No category speed cap, forced pass
station, extended K1 dwell or traction edit was added.

This is an **authored representative operating day**, not a claim that all 208
workings run in real life. The coastal Mangaluru–TVC VB is a verified route
reference; extra frequencies and southern VB workings are fictional. Distant
city names describe off-map continuations, and portal times are map-entry/exit
times, not invented departure times from those cities. Official references:
[PIB, 6 February 2026](https://www.pib.gov.in/PressReleasePage.aspx?PRID=2224512&lang=1&reg=3)
and historical Southern Zone timetable 2018 tables 12–13; the latter is not a
current schedule certificate. Kottayam-only 16347/48 was not copied onto the
Alappuzha corridor.

Focused checks pass: six boundary tests cover both actual entry/exit directions,
occupied/reserved entry rejection, partial-tail rejection and saved identity;
four network tests check authorship, same inputs in both modes, the call/traction
hierarchy and checkpoint identity. An additional gangway test preserves the
exact mid-bridge walking position through binary save/load and rejects malformed
connections. The full source suite is running; no complete-day result exists
yet. Existing prepared data correctly rejects the changed simulation fingerprint
and requires genuine regeneration, even for the unchanged original schedules.

The first native boundary harness reached and checked the north exit, but used
direct scene deletion while the new station scenery was uploading, bypassing
the game's existing safe menu-return path. It hung during harness teardown.
The rerun waits for the observer station and uses that normal menu transition;
the initial log and premature loading screenshot remain local, not acceptance
evidence. No runtime workaround or weakened check was introduced.

Next: finish the source/native checks, commit tested inputs, then launch isolated
Classic/V2 Network baselines and 600-second manual K1 disturbances plus all four
legacy baseline regenerations. The replay launcher is prepared but **not run**.
Wait, safety, every-call/completion and actual spatially distributed overtake
gates must pass before any new data is installed. Authorship alone proves none
of those outcomes.

Source/native completion: **987 full tests, zero failures, empty stderr** and
**twenty native handover/menu-return checks** now pass. Four boundary screens
were reviewed. Eight finalizer integrity tests pass, including the new network
mode, distributed overtakes, wrong terminal identity and spawned/disappeared
traffic rejection. Evidence is in `art/performance/realism-2026-10-26/network-foundation`.
No test/native/Blender job remains. The generic approach advisory still says
`No forward signal` on the final outward portal road; presentation refinement
is pending. The full replay launcher is still not run at this source checkpoint.

## Overnight failure and receiving-road correction, 03:51

The eight v1 jobs launched once at 03:33 from committed `2a280cc`; actual child
commands, isolated outputs, modes and initial source hashes were checked. All
four new Network runs subsequently failed at simulated 02:33:46: S001 continuous
wait 2,702 seconds, three of 208 finished, zero safety events. The configured
07:30 K1 disturbance had not yet happened. These are rejected partial days,
not successful disturbance evidence. Audits, failure checkpoints, traffic, logs
and exact old packs are compressed and hashed in `network-candidate-one`.

Read-only inspection of the real failure found a shared receiving-capacity
defect: non-stop S001 could use only AMPA_P1 to continue to KYJ_P1, but the
capacity check also counted AMPA_P2/P3. That admitted M001 behind it, also
requiring P1; opposing S002 could not vacate the occupied single line. Two
regressions reproduce the wrong capacity/admission, and pass after checking a
non-stop service's onward reachability to its next booked call. All ten receiving
tests pass. No passing location, stock, priority, dwell or track was changed.

The four incomplete original-day baselines were stopped by their verified owned
child PIDs before the source edit. Their partial files remain local. A fresh
generation is required for every baseline. All v1 processes have finished.

Thirty-two distant journey identities now avoid implausible cross-map city
pairings. Exact comparison confirms all 208 departures, calls, dwell, stock,
priorities and other operating fields are unchanged. Both modes retain identical
service arrays. All four network authoring tests pass. The legitimate outward
road now reports continuation instead of missing authority; a seventh boundary
regression fails before and passes after, including emergency/operator-hold
precedence. Updated native boundary screens and the full source suite are running.

The moving PCM diagnostic passes twelve ICF/LHB/VB oncoming/overtaking cases,
fixed and turning heads, with map-origin shifts. Each has eighty half-second
samples and no nearby external-rail mute. Maximum proxy position error is
0.046875 m. Evidence is in `moving-sound`. This controlled native Dummy mixer
check is not a full scenery-load reproduction or physical listening verdict.

Validation complete: **990 full source tests passed**, zero failures, empty stderr.
All 24 native boundary checks pass and four screens were reviewed. The twelve
controlled moving-sound cases pass. A separate real rendered scene diagnostic
is still running around the historical Sasthamkotta passing fixture; two earlier
harness attempts are retained locally as incomplete (compressed-file reader,
then first-frame audio metadata handling). They are not acceptance evidence.
Next: commit the tested source and launch the fresh v2 generation once.

## Corrected replay launch and rendered sound, 04:08

Tested source `66ab453` is committed and pushed. Eight v2 jobs launched once at
04:00:37: the Classic/V2 Network baselines and 600-second K1 disturbances, plus
four legacy baselines. All sixteen wrapper/child command lines, isolated output
arguments, modes, 4,839 distinct source hashes and six observer hashes were
verified. The job record and exact launch verification remain in
`.local/realism-2026-10-26`. Simulation, routes, packs and preparation observers
are frozen. No completed v2 audit exists yet; no new data is installed.

The actual rendered Sasthamkotta passenger fixture now completes: 903 quarter-
second capture bins, with 113 nearby B002 overtake bins and 114 nearby B014
oncoming bins during full head rotation. Minimum external rolling RMS is
0.000525/0.000520 respectively, with no nearby residency loss, paused sound,
receiver-position error or safety event. This uses Compatibility rendering and
Dummy audio; its two unsupported renderer-feature warnings are retained. The
historical snapshot is a hashed diagnostic fixture, not current certified data.
A separate moving-passenger Forward+ probe is running. Neither PCM check
substitutes for listening on the user's audio device or proves every reported
intermittent silence is fixed.

## Sound completion and operator guide, 04:24

The moving Forward+ probe completes 720 bins with no failures or stderr. Its
oncoming B012 interval has 35 nearby bins, both trains at 98.56 km/h, minimum
external rolling RMS 0.000909 and zero receiver-position error/residency loss.
Complete raw compressed reports and reviewed screens for both rendered probes
are archived in `rendered-sound`. The two historical snapshots and original
catalogue are also retained locally in `rendered-sound-fixtures` before future
prepared-data replacement. These are measurement fixtures, never new baselines.

Gangway help, controller reference, sound guide and operating-day documentation
now describe current behavior and clearly mark the 208-day preparation pending.
The new Network guide records category counts and same-section booked examples.
All 990 headless tests pass again with empty stderr. After that suite finished,
six existing mojibake separators in `train_walk.gd` were corrected; all eleven
focused walking tests pass. No walking mechanics or frozen replay input changed.

The LHB controller harness passed 203 checks, then 209 including explicit
interior visibility. Its stopped presentation loop and unfinished seat-to-walk
blend made the first screenshots unsuitable visual evidence. A derived harness
uses the normal presentation update, waits for the blend and checks the camera
against the walked position. The final native pass completes **215 checks,
zero failures, empty stderr**, with four reviewed Forward+ screens. The forward
post-gangway view correctly faces the berth partition at the turn into the side
aisle; an additional look-back shows the vestibule. Evidence is in
`gangways/lhb-followup`. No native, full-suite or audio probe remains running.

`tools/summarize_network_categories.mjs` is intentionally uncommitted pending a
real completed 208-service acceptance run. It reads exact current-source audits,
compares actual/booked times on matching corridor sections, and reports all
full-formation passes by category. Syntax and rejection of the actual failed
candidate pass; no positive full-day result exists yet. Use alongside, not in
place of, the existing independent acceptance/finalization tools.

## Morning Network conflicts and minimal departure edits, 04:38

The two Classic Network v2 jobs finish rejected at 05:40:04 simulated: L005
has waited 2,702s at Ernakulam, 18/208 services finish, zero safety events.
Read-only Kumbalam inspection finds moving opposing M004 and sequential
M009/M045 traffic, not the earlier non-stop receiving-road defect.

The predictive delayed job independently fails at 07:00:24 for L022 at Eraniel,
26/208 complete, zero safety events. Both Kulitturai roads hold northbound
L002/M078, both Neyyattinkara roads hold southbound L033/S045, and M061 occupies
Parassala awaiting Kulitturai. Existing onward crossing protection holds the
approaches. This is before the scheduled 07:30 manual hold, so neither delayed
run is valid disturbance acceptance. Its restored failure inspection is immutable.

The remaining predictive Network baseline child 10248 was verified by exact
command line and stopped before changing shared authored inputs. Its first
10,677 complete traffic samples match the delayed run; the interrupted trailing
line is archived unchanged and excluded from comparison. No final audit is
invented. Original folders and all failed/partial states remain preserved;
compressed exact evidence is in `network-candidate-two`.

Authoring now applies explicit validated departure overrides outside the frozen
simulation source: L005 04:55→05:20 and L033 05:40→06:35. Exact old/new comparison
confirms these are the only field changes in both packs. All 208 calls, running
offsets, dwell, stock and priorities remain unchanged; both mode service arrays
are identical. There are now 66 overnight departures, 4–14 in each hour.
No successful-day claim follows from these edits. A fresh affected-only Network
baseline/disturbance generation is required. The four legacy v2 baselines remain
running; all their 4,835/4,836 source fingerprints still match. No runtime change,
gate relaxation, forced pass site, or prepared-data installation occurred.

All four headless Network authoring tests pass after retiming, with empty stderr;
the author script parse check also passes. The prior 990-test full runtime suite
still covers unchanged simulation. Exact field and legacy fingerprint checks
are retained alongside the failed evidence. Next: commit, then launch only four
new Network jobs in isolated v3 folders.

## Affected-only relaunch and browser integration, 04:42

Retiming/evidence commit `0d84a7a` is pushed. Exactly four Network v3 jobs
launched at 04:39:13: Classic 21604/13568, Predictive 22600/17056, Classic delayed
19092/15232, Predictive delayed 1200/3760 (wrapper/child). At 04:39:51 all eight
actual command lines, isolated output arguments, both baseline modes, 4,837
distinct input fingerprints and six observer hashes passed verification; stderr
was empty. Read `rehearsal-jobs-v3.json` and `launch-v3-verification.json`.
Never rerun this launcher or duplicate the four legacy v2 baseline jobs.

Browser inspection found two integration defects: preference restoration only
recognised the original two days, and Full route excluded services whose origins
or destinations were beyond the map despite covering both termini. Two new
regressions fail before and pass after using the registered operating-day list
and actual on-map calls. All seven library tests pass. The roster now uses full
journey identities and labels boundary starts as corridor entry; ordinary
departures retain their label. This is presentation only and changes no replay
fingerprints. The complete source suite is now running (job record
`network-browser-full-test-job.json`, wrapper 1960); do not edit runtime/tests until it finishes.
Actual current-source menu/worker checks still await certified installed data.

## Browser source checks complete, 04:55

The original full suite 1960/10776 finishes with **992 passed, zero failures,
empty stderr** and both processes have exited. Exact before/after regression
and full logs are retained in `network-browser`. No new suite is needed for
these unchanged sources. The four v2 legacy baselines and four v3 Network jobs
remain active without stderr or completed audits. Current-source native menu
checks still require accepted installed outputs; no data has been installed.

## Third Network failure and crossing-capacity correction, 05:25

Both v3 delayed runs finish rejected before the 07:30 manual hold: Classic
L021 at NEM, 07:29:16, 28/208; predictive L002 at KZT, 07:07:02, 26/208.
Maximum extra wait is 2,702s and both have zero safety events. This is not valid
disturbance acceptance. Exact failed/partial evidence is in
`art/performance/realism-2026-10-26/network-candidate-three`.

The original 06:50 Classic and 06:30 predictive snapshots show three arrival
claims competing for two escape-station roads after a future-crossing promise.
Read-only restoration confirms unchanged worlds and insufficient berth matching.
The claimed road was physically empty, but L033/L022 had already departed toward
it roughly 49/133 seconds before the promise. This is a shared planning defect,
not a reason to retime another service or weaken the wait threshold.

`future_clearance.gd` now includes existing arrival/route claims when selecting
an escape berth. The transaction may remove only its departing opponent's old
claim. Two regressions fail before/pass after, the unclaimed-escape positive
case passes, and all 33 focused future-crossing tests pass. The complete source
suite finishes: **995 passed, zero failures, empty stderr**. Wrapper 21244 /
child 18120 have exited; exact `escape-full-tests.log/.err` are archived.

The six unfinished baselines were stopped by verified child identity before
this shared source change: legacy 22272/1252/12116/17960 and Network13568/17056.
Original outputs remain preserved; no prepared data has been installed. Every
baseline now needs genuine regeneration. The authored candidate-three packs
remain unchanged. `launch-network-v4.ps1` is prepared but NOT RUN: after the full
suite passes and the fix/evidence is committed, launch it once, then verify all
actual commands, modes, source hashes and stderr. It creates six baseline and
two Network disturbance jobs. Never restart earlier generations.

After new data passes and installs, test both Network menu choices, a full
long-distance journey through either portal, midnight continuation and a natural
local/express crossing. All six actual prepared choices need native verification.
The fixed 10:00 deadline and R47 publication remain unchanged.

## Corrected replay generation launched and verified, 05:29

Runtime/evidence commit `c8dec7d` is pushed. After all **995 tests passed**, eight
new v4 replays launched exactly once at **05:28:44** on that committed source:

| Job | Wrapper / child |
|---|---|
| classic-network | 12492 / 5312 |
| predictive-network | 22192 / 6392 |
| classic-network-delayed | 13272 / 9192 |
| predictive-network-delayed | 3536 / 15828 |
| classic-standard | 13188 / 18312 |
| predictive-standard | 21980 / 14968 |
| classic-intensive | 22304 / 14324 |
| predictive-intensive | 7788 / 1188 |

At 05:29 the launch check verified all sixteen actual command lines, one isolated
output argument per process, all six baseline modes, **4,839 distinct source
fingerprints** and the six preparation observer hashes; every stderr is empty.
See `rehearsal-jobs-v4.json`, `launch-v4-verification.json` and `rehearsals-v4`.
No suite, diagnostic or native job remains running. Never rerun the launcher or
duplicate/restart these jobs. Freeze sim/routes/packs and the six observers.

Earlier generations are failed/stopped historical evidence. No new compatible
data has been installed. Complete-day calls, portal/depot completion, safety,
wait distributions, spatial passes and actual installed-menu checks remain
required. Category analysis is still intentionally uncommitted pending a real
208-service positive result. Do not repeat completed gangway/PCM/native sound
checks without changes. At 10:00 stop expanding scope and safely checkpoint
in-flight validation, then remove the continuation automation as authorized.

## Prepared-menu follow-up staged, 05:44

All eight original v4 replays continue; no completed audit or stderr failure at
this checkpoint. Runtime inputs remain frozen on `c8dec7d`. No duplicate run,
new full suite or prepared-data installation was made.

The existing `tools/check_predictive_prepared_ui.gd` now also checks Network M061
in the actual roster and Full route filter, distant origin/destination labels,
portal-entry wording, the representative-service explanation, real departure
loading and per-day saved selection. It adds an actual 24:00 timeline-worker
load with day-2 display, live overnight roster and a checksummed 208-service
save/restore whose full world bytes must match without changing the displayed
world. The script parse check passes with empty stderr; these checks have NOT
run against installed Network data yet. Leave the tool uncommitted until actual
accepted data exercises both Network modes. It modifies no runtime or frozen
preparation observer. The category-analysis tool remains uncommitted for the
same missing positive-day validation. Do not fabricate fixture catalogues.

After independently accepting/installing each day, run the native checker for
all six choices, review the real images, and retain the output. Standard and
Intensive must also use the new compatible source generation. Fixed10AM deadline
and R47 availability are unchanged.

## Fourth Network candidate rejected, 06:04

Both v4 Network delayed runs failed before the 07:30 hold: Classic at
07:24:04 (27/208) and predictive at 07:07:02 (26/208), each L002 extra
wait 2,702s and zero safety events. All 4,836 source hashes per report match
the unchanged committed source. Exact audits, failed worlds, traffic, packs
and read-only receiving inspections are preserved in network-candidate-four.
Six unfinished baselines were stopped by verified child identity before any
shared runtime correction; their original outputs and compressed traffic remain.

The recorded arrangements have a compatible free receiving road for V005 at
NYY / M078 at PASA, but the onward-exit recheck holds these already admitted
trains outside it. The original world remains byte-identical after inspection.
A four-train regression is running on the unchanged planner; correction and
full validation remain pending. No retiming, data installation or acceptance.
A guarded v5 launcher is prepared but NOT RUN; wait for regression/full-suite
results and a committed fix. All six baselines must regenerate if source changes.

The admission correction passes both new tests, including complete safe drainage
of the four-train crossing. Existing exit-capacity13 and future33 tests pass.
Actual failed-state read-only inspections now permit the free P2 while rejecting
occupied P1; worlds remain unchanged. Full suite4752 started06:08:48, expected997,
logs admitted-full-tests.log/.err. Limited historical continuations14840/12896
started alongside it; their reports are diagnostic only. Runtime/tests frozen
until completion. No new full-day job exists.

## 06:21 results and remaining congestion

Full suite4752/20128 finishes997passed0failed,stderr0; both diagnostic jobs
finish too. V005 and M078 clear their original approaches after42s/74s, but
the other three monitored services each remain on their original roads after
3600simulatedseconds,zero safety events. Preserve both unsuccessful drainage
results. The admitted-arrival correction is independently verified but does
not repair the already-congested surrounding arrangement. Investigate upstream
admission before launching v5; the prepared launcher is STILL NOT RUN.
No full suite, diagnostic or full-day job remains.

## Downstream queue correction under validation, 06:30

Verified arrival correction/evidence0404fd2 pushed;997fullsuite passed. Both
600s follow-up state captures confirm the surrounding four southern yards
remain full: same-direction occupants cannot leave into the next opposing
yard, despite the old admission assumption that they can clear away. These
are diagnostic continuations of old failed states, never baseline evidence.

The planner now follows same-direction blocked crossing queues monotonically
through a bounded downstream lookahead, treating unresolved bounded capacity conservatively.
It still allows a genuinely free downstream road. New blocked-yard regression
fails before/passes after; free-road positive passes both. Six-train three-yard
completion test passes safely, and all51focused checks pass (3new,2admitted,
13exit,33future). Full1000suite launched once: see downstream-full-tests-job.json
and downstream-full-tests.log/.err. Runtime/tests frozen until it finishes.
No suite from the previous997 run or diagnostic remains. No full-day jobs run.

After fullpass, archive final log, update docs, commit/push only verified planner,
new test and downstream-capacity evidence; preserve pending UI/category tools.
Then launch guarded launch-network-v5.ps1 ONCE (still NOT RUN), verify actual
commands/modes/current hashes/stderr with verify-launch-v5.py. Eight genuine
full-day jobs required; authored208packs stay unchanged. Never relabel earlier
failed/partial outputs. Deadline10AM and R47 unchanged.

## Final downstream source suite passes, 06:42

The original1000suite16796/17780 finished at06:38:16 with1000passed0failed
and empty stderr. No source/test edits occurred while it ran. Both processes
and all earlier diagnostics are gone. Archive final logs in downstream-capacity,
commit/push the tested planner/test/evidence increment, then launchv5once.
Do not repeat the source suite unchanged. Authored208packs and all safeguards
remain unchanged; whole-day acceptance still outstanding.

## Eight corrected-source replays verified, 06:45

`f3a1fda` is committed and pushed with the downstream-capacity correction,
three new regressions and exact evidence. The final full suite passes all
1,000 tests with zero failures and empty stderr. No suite remains running.

The guarded v5 launcher ran ONCE at 06:43:04. All sixteen actual wrapper/child
commands have one isolated output argument and the expected options; all six
baseline modes, 4,839 distinct source hashes and six preparation-observer
hashes match. Every stderr is empty. Source is frozen on `f3a1fda`; authored
Network packs are unchanged. Do not run the launcher again or restart jobs.

| Day | Wrapper | Child |
| --- | ---: | ---: |
| classic-network | 12240 | 9660 |
| predictive-network | 12868 | 8436 |
| classic-network-delayed | 9360 | 6004 |
| predictive-network-delayed | 10984 | 2964 |
| classic-standard | 12492 | 13108 |
| predictive-standard | 11196 | 7004 |
| classic-intensive | 17300 | 3168 |
| predictive-intensive | 17768 | 10760 |

Authoritative process/options files are rehearsal-jobs-v5.json,
launch-v5-verification.json, owned-processes.json and latest-job-status.json
under .local/realism-2026-10-26. Originals are in rehearsals-v5/<day>.
The two delayed Network runs apply 600s manual K1 hold at simulation27000 and
remain evidence only; the six baselines include actual snapshots. No complete
audit or current-source prepared installation exists yet. Earlier generations
remain preserved failures/partials. Never install them or relabel hashes.

Next: accept completed runs against every call/completion/safety/wait and
actual passing gate, finalize each passing baseline independently, then exercise
its installed native UI. Network also requires category comparisons, actual
midnight worker/save/restore checks and reviewed screenshots. The UI/category
tools remain uncommitted pending that evidence. No repeated full suite or
completed audio/gangway audit is needed. R47 and the fixed10AM deadline remain.


## Fifth Network failure and affected-only retiming, 07:28

Both v5 Network delayed jobs finished rejected: Classic28284s/30of208/M043 NEM,
V225704s/26of208/M061PASA; each2702s wait and zero safety events. Each4836source
hashes plus raw pack hash verified before edits. V2 fails before27000hold;
Classic reaches beyond the configured27000–27600window. Neither is accepted.
Read-only saved-world inspections are immutable and show moving southern traffic.
Exact raw gzip audits/traffic/failure worlds, old packs, actualcalls and original
stopped baseline catalogues are in network-candidate-five. Do not install them.

Only L02205:45→06:55 and L03406:10→04:30 change in BOTH Network packs, spreading
northbound locals originally bunched05:15/05:45/06:10. No other service field,
stock, dwell, priority, physical speed or runtime changed. Four headless authoring
tests pass after retiming, emptystderr. Runtime1000fullpass remains current.
Networkbaseline12240/9660 and12868/8436 stopped by exact child command identity;
delayed9360/6004 and10984/2964 had finished. Originals preserved. All four legacy
v5 Standard/Intensive baselines continue and every4835/4836source hash matches.

Guarded launch-network-v6.ps1 is prepared, NOT YET RUN: only four Network jobs,
allowing the four live legacy jobs. After committing/pushing the verified pack
increment, run it ONCE and verify-launch-v6.py; never relaunch v5. Preserve
runtime/routes/observers and new packs throughout replays. No fake catalogues or
stale signatures. UI/category tools remain uncommitted until accepted actualdata.
Fixed10AM deadline and R47 remain. Completed audio/gangway checks need no repeat.


## Affected-only v6 launch verified, 07:29

`bbdf49a` is committed and pushed: both departure adjustments, four passing
authoring tests and exact rejected evidence. All28 archived staged byte hashes
match their originals. The four legacy v5 runs remain untouched and compatible.

The v6 launcher ran ONCE at07:28:23. Eight actual wrapper/child command lines,
single isolated output arguments, both baseline modes, 4,837 distinct source
hashes and six observer hashes are verified; stderrempty. The initial verifier
ran before catalogues existed; it was retried after startup, without relaunching
anything, and passed. Source and authored inputs now stay frozen.

| Network run | Wrapper | Child |
| --- | ---: | ---: |
| classic-network | 18968 | 12220 |
| predictive-network | 17028 | 21860 |
| classic-network-delayed | 13752 | 9084 |
| predictive-network-delayed | 21252 | 2120 |

Legacy v5 Standard12492/13108,11196/7004 and Intensive17300/3168,17768/10760
continue. No full suite, native, diagnostic or Git operation remains. Run the
read-only .local/realism-2026-10-26/inspect-current-replays.py for concise mixed
v5/v6 clocks and final-audit status. No accepted current-source data is installed.
Do not duplicate or restart any current jobs; do not use earlier failed/partial
generations. All current acceptance and native-menu gates remain pending.


## Completed crossing promises retain stale reservations, 08:13

Both v6 Network delayed runs failed: Classic07:46:04/M043NEM/30of208 and
V207:12:16/M045ALLP/27of208, each2702s,zero safety. V2 precedes the configured
manual hold. Read-only saved worlds remain byte-identical. Classic's NYY plan
has received/opponent_received/escaped all true; vacaterL021 is already atERL,
yet PASA_P1 and NYY escape corridor stay reserved until opponentL002 departs.
L002 cannot reach fullNEM, while V005 cannot use physically free PASA_P1.
This is a shared transaction-lifetime defect, not grounds for more retiming.

Six unfinished baselines stopped by exact child PID/parent/command identities:
v5Standard12492/13108,11196/7004; Intensive17300/3168,17768/10760;
v6Network18968/12220,17028/21860. Both delayed jobs already finished. All original
outputs preserved;42 exact raw evidence files and4839distinct pre-fix source
hashes verified in network-candidate-six. future_clearance.gd verified against
pre-fixHEAD bytes, not relabelled as matching the corrected file. Packsunchanged.

Three new tests use the current real layout: completed promises release while
opponent remains berthed without changing signals/occupancy; restored staleplan
releases the vacated escapeberth; vacater tail must clear first. All failbefore
and passafter;30 existingfuturecrossing tests pass. First local prototype used
an altered historical fixture and correctly failed compatibility, excludedfrom
validbefore evidence; no signature bypass. Runtimefix only changes completion
to received AND opponent_received AND escaped; physical interlocking unchanged.

Full1003 suite20300/19764 started08:11:07, logscompleted-plan-full-tests.log/.err;
freeze runtime/tests until finalresult. Historical1200s checks7124/352 and
9992/18360 running, diagnostic only. No full-day job. Guardedlaunch-network-v7.ps1
andverify-launch-v7.py prepared NOTRUN: afterfullpass/archivelogs/docs/explicit
commitpush, launchall8 once and verifyactualcommands/modes/currenthashes. Do not
rerunv5/v6. Currentauthoredcandidate-six staysfixed. PendingUI/categorytools await
acceptedinstalleddata; nofakecatalogues. R47/fixed10AM remain. Atdeadline safely
checkpoint any unfinished validation rather than claiming certified208traffic.


08:15 diagnostic completion: both1200s historical continuations finish with
zero safety events but all_cleared=false. ClassicV005 clearsinitialroad52s,
M043128s; L002/L033/M078 remain. V2L006796s,M0081130s; M045/S028 remain. These
are limited evidence for removing the original stale claim, not full recovery
or timetable acceptance. Exactoutputs/script archived in candidate-six with
hashes. Full1003 suite20300/19764 stillrunning/emptystderr, no other jobs.
Afterfullpass completefinalevidence/docs/commit thenlaunchv7once, notbefore.


## Completed crossing fix passes full suite, 2026-10-26T08:20:04+08:00

All1,003 source tests pass, zero failures and empty stderr. The final source and
three-test file exactly match their archived after-test bytes. Full-suite logs
are added to candidate-six provenance. Both historical diagnostics have ended;
keep their incomplete-recovery limits explicit. No running suite or diagnostic
remains. No current-source prepared timetable is installed.

Commit/push the small runtime correction, three regressions, exact rejected-run
evidence and these records, excluding pending prepared-UI/category tools and
unrelated files. Then launch-network-v7.ps1 ONCE and verify-launch-v7.py. All
eight fresh runs use unchanged candidate-six authored packs. Their source and
six preparation observers remain frozen during replay. Stop scope expansion at
10:00, safely checkpoint unfinished validation and delete the automation. R47
stays available; no executable is published from these incomplete timetable runs.


## Fresh v7 preparation launched and verified, 2026-10-26T08:21:36.534629+08:00

Correction and exact evidence **`9ec3530`** are committed and pushed. All 1,003
source tests passed with zero failures and empty stderr. The six old partial
baselines and two failed audits remain historical evidence. No inputs were
retimed for this source correction.

The guarded launcher ran once at 2026-10-26T08:20:40.5706725+08:00. All sixteen actual
wrapper/child command lines have the correct isolated output and mode options.
All six initial baseline catalogues match the corrected source: 4,839 distinct
input hashes and all six preparation-observer hashes verified. Every stderr
is empty. Do not duplicate or restart these jobs.

| Run | Wrapper | Child |
| --- | ---: | ---: |
| classic-network | 5248 | 6380 |
| predictive-network | 21820 | 12472 |
| classic-network-delayed | 18252 | 17940 |
| predictive-network-delayed | 9620 | 11328 |
| classic-standard | 12052 | 21916 |
| predictive-standard | 16856 | 6856 |
| classic-intensive | 18308 | 14120 |
| predictive-intensive | 18084 | 17900 |

Records: rehearsal-jobs-v7.json, launch-v7-verification.json, owned-processes.json
and latest-job-status.json under .local/realism-2026-10-26. Outputs are in
rehearsals-v7/<day>. The status inspector now selects v7 automatically. Network
delayed runs apply the same 600-second K1 manual hold at 07:30 and are evidence
only; the other six runs create real departure and time snapshots.

Freeze simulation, routes, authored packs and the six observers throughout
these runs. Accept each complete baseline independently against every service,
call, depot/portal full-tail completion, safety, waits and actual passing gate.
Install only compatible passing data, then exercise the real native menus.
Network category comparisons and midnight/save/restore checks remain pending.
The prepared-UI and category tools remain uncommitted until those real checks.

No full suite, diagnostic or Git operation is needed while unchanged. R47 is
preserved. At 10:00 stop expanding scope; safely checkpoint any unfinished
validation and delete the continuation automation. Do not call partial or
failed data complete and do not publish an executable from it.


## Morning queue failures and affected departure spacing, 2026-10-26T09:04:24.099575+08:00

Both v7 Network delayed runs rejected: Classic L002 at NYY 07:50:40,32/208;
V2 M045 at ALLP 07:12:16,27/208. Each2,702s station/continuous wait andzero
safety. V2 fails before07:30hold; Classicafter. V2services/rawtraffic exactly
match v6 failedprefix only. Classicreadonlyinspection immutable, movingtraffic
andno stalecompletedNYYtransaction. Exactaudits/traffic/failureworlds/oldpacks
andstoppedbaselinecatalogues archived network-candidate-seven,4,837unique
currentinputhashes verified beforeedits. Oldoutputs preserved,neverinstall.

ONLYbothpacks M10106:10->07:25 andL03306:35->07:55 change; semanticcheck
provesallotherfieldsidentical. Rationale/actualwaitcauses in evidenceREADME.
Fourauthoringtestspass;unchangedruntime9ec3530 has1003fullpass. Allfour
continuingv7legacycatalogues stillmatch4835Standard/4836Intensivehashes.
Theirpairs12052/21916,16856/6856,18308/14120,18084/17900 mustcontinue.
OnlyNetworkbaselines5248/6380 and21820/12472 wereidentity-stopped.

Guarded launch-network-v8.ps1 andverify-launch-v8.py prepared NOTRUN. After
explicitcommit/push launchfouraffectedNetworkjobs once;inspectactualcommands,
modes,isolatedoutputs/sourcehashes. Inspectorselectsmixedv7legacy/v8Network.
No runtime/tests/observers changed. PendingUI/categorytools remainuncommitted
untilacceptedrealdata; nofakecatalogues. Full-day/native/category/midnightgates
pending. R47andfixed10AM preserved; checkpointunfinishedvalidationanddelete
automationatthedeadline.


## Affected v8 Network launch verified, 2026-10-26T09:05:56.713741+08:00

Departure spacing and exact failed-run evidence are committed and pushed in
`ac69057`. The guarded launcher ran once at 2026-10-26T09:04:57.9243245+08:00. All eight
actual wrapper/child commands have a single isolated output and the expected
pack and baseline/disturbance options. Both baseline modes and all 4,837
distinct source hashes match; the six preparation-observer hashes are recorded.
All four stderr files are empty. Do not rerun the launcher or restart jobs.

| Run | Wrapper | Child |
| --- | ---: | ---: |
| classic-network | 20172 | 11600 |
| predictive-network | 10012 | 23432 |
| classic-network-delayed | 10828 | 22028 |
| predictive-network-delayed | 20596 | 6276 |

The four unchanged v7 legacy baselines also retain their original identities:
Standard 12052/21916 and 16856/6856; Intensive 18308/14120 and 18084/17900.
At 09:05 their clocks are 16:40/16:30 and 15:10/14:50 respectively, with no
final audits and empty stderr. No complete-day acceptance is implied by these
partial results. The v8 Network baselines are at 00:10 and disturbances 00:40.

Read rehearsal-jobs-v8.json, launch-v8-verification.json, latest-job-status.json
and rehearsals-v8 outputs. inspect-current-replays.py now selects the mixed
v7 legacy/v8 Network jobs. Simulation, routes, active packs and observers are
frozen. No suite, diagnostic, native check or Git operation remains after this
checkpoint. The prepared-UI and category tools remain pending real accepted
data. R47 is preserved. At 10:00 stop expanding scope, safely checkpoint any
unfinished validation, report incomplete work and delete the automation.


## v8 disturbances rejected; preserve deadline checkpoint, 2026-10-26T09:49:33.953442+08:00

Both disturbance jobs have ended: Classic 10828/22028 fails at 07:46:04,
29/208 complete, M043 NEM continuous wait 2,702 seconds (longest station
wait 2,524 seconds). V2 20596/6276 fails at 07:51:52, 31/208 complete,
L006 AMPA station/continuous wait 2,702 seconds. Both record zero safety
events and reach beyond the 07:30–07:40 K1 manual hold interval.

Read-only inspections of the actual failed worlds are byte-immutable. Classic
shows S046 and M078 moving north, with L002 already at KZK; V2 shows M010
leaving AMPA ahead of L006 and M008 north of ALLP. Neither has an active
future-crossing transaction. Actual wait causes and exact raw audits, traffic,
worlds and packs are preserved in network-candidate-eight; 4,837 distinct
source hashes verified. This is failed evidence, never baseline data.

The two original v8 Network baselines and four original v7 legacy baselines
continue. Do not duplicate them or change frozen inputs. No new timing or
runtime patch is justified without another complete validation cycle this
close to 10:00. Source tests remain 1,003 passing, current authoring tests four.
Use remaining time to independently verify any completed baselines. At 10:00
stop scope expansion, safely checkpoint unfinished runs, report all incomplete
acceptance/native/category/midnight work and delete the continuation automation.
R47 remains published. Pending prepared-UI/category tools are not certified.


## Standard pair installed and native-verified, 2026-10-26T09:58:37.848983+08:00

Both fresh v7 Standard baselines passed all100 services,1530arrivals and1530
departures each, depot completion, zero safety and both wait distributions.
100 real starts,233exacttime states,4835currenthashes each. Independent
installed verifiers pass. Old674prepared files copied and hash-verified in
pre-realism-standard-data before replacement. Data commits8d0d67d and3e3aa46;
Git push is in flight at this checkpoint (session36428), inspect beforeanother
Git operation. Native23536 finished:36checks0failures,4screens reviewed,
realdeparture/noonworker/mode/reciprocaltraffic. Compatibility AA warning only;
Dummy audio, no audio/FPSclaim. Exact raw/evidence standard-realism-v7.

Keep regressions: V2B020+891.05s,B012+691.15s,K1+78s. This is Standard only;
Network208 request remains incomplete. Working preparedUItool contains
untested Network branches and remainsuncommitted; executedcopy archived.
No source/tests changed;1003full remainscurrent. Intensive originals continue.
Classicv8Networkbaseline now rejected sameM0437:46:04,29/208,zero safety;
exact baseline evidence added to candidate-eight. V2baseline stillfinishing
at09:57. No additional jobs or runtime/timing changes. Fixed10AM cleanup next.


## Historical deadline checkpoint, 2026-10-26T10:02:37.354809+08:00

The user deadline has passed; no further scope expansion or new jobs. The
continuation automation was deleted through the app at10:00:17; deletion
confirmed, its config is absent, and the other Train Game automations remain
paused. Standard data8d0d67d/3e3aa46 and evidence0315da1 are pushed; the former
in-flight Git push and native23536 have ended.

Both v8 Network baselines are now rejected: Classic M043 at07:46:04,29/208,
2,702s continuous and2,524s station maximum; V2 S046 at07:59:52,32/208,
2,702s continuous and2,570s station maximum. Zero safety events each. Both
disturbances also rejected. All four exact current-source audits/traffic/failed
worlds and incomplete baseline catalogues are archived in candidate-eight.
No Network installation, no acceptance claim, no further retiming.

Two original finite Intensive runs remain: Classic18308/14120 at23:20,133/140;
V218084/17900 at22:20,128/140, empty stderr and verified command identities.
They may finish to existing rehearsals-v7 folders without any new automatic
work. Keep simulation/routes/packs/six observers frozen. On an authorized next
turn, inspect those exact jobs before acting; independently verify complete
audit gates before installing either, then run actual native Intensive menus.
Do not rerun Standard or unchanged audio/gangway checks. Network needs further
scheduling investigation and a genuinely passing complete baseline/disturbance
pair before installation and category/midnight/save-load menu checks.

Pending local tools: check_predictive_prepared_ui.gd has unvalidated Network
branches; summarize_network_categories.mjs lacks an accepted208 positivecase.
Their work is preserved, not falsely certified. Exact executed Standard checker
is archived. R47 and unrelated files remain. Scope implemented: continuous
gangways, spatial bogie/clack/air corrections, controlled head-turn continuity,
safe full-tail boundary portals,208 honestly labelled representative authored
services. Scope incomplete: acceptable208 operating day and its real-data
validation; Intensive preparation/native checks. No new executable.


## User resumed until ready, 2026-10-26T10:25:46.736680+08:00

The user explicitly extended work beyond the deadline and emphasized finite
single-line capacity. Original deadline and stopped-automation records remain
historical; the active ledger session is resumed without a replacement cutoff.
No subagents. Preserve R47 and the existing tested gangway/audio/portal scope.

Both original v7 Intensive jobs have finished. Independently checked and
installed current-source data: 140 services, 1,726 arrivals and departures,
zero safety, all station/all-location wait targets, 140 departure states and
233 five-minute states per mode, 4,836 fingerprints. Old 754 prepared files
were copied and hash-verified before replacement. Classic 12 K1 overtakers at
8 stations, maximum 5 KPY; V2 11 at 7, maximum 3 STKT. Native wrapper3316 has
finished with55checks0failures; four1280x720screens reviewed. Dummy audio and
Compatibility AA availability warning only. Data commits4c58ab3/2be158a;
full evidence intensive-realism-v7. Preserve priority75/85 regressions and the
15 authored-departure confound. No new executable. Runtime9ec3530 unchanged;
1003 passing full tests remain current. No full-day replay remains active.

Two isolated physical-profile measurements run from the same unchanged source:
part0 wrapper2912/child14628, part1 wrapper8588/child6576. Each covers22 distinct
stock/call profiles with one train in an isolated world. Outputs are
solo-profiles-0/1.json; source hashes included, no shared prepared data writes.
Do not duplicate these measurements. They are departure-planning diagnostics,
not complete-day traffic certification. Static section export reflects actual
single_line_sections grouped between passing places. Planning includes opposing
occupancy and same-direction headway; the sum of individual occupancy times is
not a one-train-at-a-time capacity limit for a section permitting followers.

The proposal script plan-network-spacing.py only emits JSON, never edits packs.
It must wait for all44 profiles, then proposed departures must be reviewed and
verified to leave every other service field unchanged. Calls, stock, dwell,
priorities, speeds, routes and interlocking stay fixed. Preserve candidate-eight
failure evidence. Repair the authoring override record to reproduce the actual
packs before the next affected Network replay. Complete baseline/disturbance,
category, midnight/save and actual menu gates remain mandatory.


Authoring continuation: `author_network_timetable.gd --check` now reproduces
both current packs without writing them. The old override record omitted
L022/L034/M101 and retained the old L033 departure; repaired to exactly match
candidate eight. A final-code negative test against the previous override
correctly rejects, and all four Network guards pass. The comparison uses the
author's actual JSON serialization precision, with no fingerprint exceptions.
Both operating pack bytes and runtime remain unchanged. Evidence is in
`authoring-reproduction`. Original solo measurements continue; do not duplicate.
The new continuation automation `complete-train-game-realism-and-network-208`
runs every ten minutes until all readiness work is complete; delete it then.
Other completed Train Game automations stay paused.


## Capacity-aware candidate nine, 10:48

Both original isolated-profile jobs finished 22 profiles each, all 44 safe and 4,835
current source hashes verified. No diagnostic job remains. Search proposal 1
reduced opposing overlap but increased peak fleet from 39 to 46; rejected without any
pack edit. Revised search adds following-batch/overall load penalties; candidate
peak 34, 3–13 departures/hour, 68 overnight. These are planning estimates, not full
traffic performance. All 203 departure-only changes are semantically verified;
K1 remains at 06:00, all other fields identical, both modes have identical 208 services. Old packs,
overrides, all measurements/scripts, rejected first proposal and new proposal are archived
in network-capacity-plan. Current authoring overrides reproduce both packs.
Four Network guards pass. Runtime 9ec3530 is unchanged; all legacy data remains
compatible. Do not repeat unchanged legacy menus, audio or gangway checks.

Full source suite wrapper 13240 is NOW RUNNING, capacity-full-tests.log/.err,
expected 1,003. Freeze runtime/tests until it ends. Do not duplicate. Before
launch: require full pass, archive final logs, update records, explicitly commit/push
only coherent capacity pack/override/evidence/docs. Guarded launch-network-v9.ps1
and verify-launch-v9.py are prepared but NOT RUN. After commitment launch four affected Network jobs
ONCE, verify eight actual commands, modes, isolated outputs, current hashes and six observers.
All earlier replays ended; no full-day job is active now. Keep prepared UI Network
branches/category helper local until accepted real data; preserve unrelated files.
The new continuation automation complete-train-game-realism-and-network-208 is active,
with no 10 AM cutoff; stop/delete only when all authorized readiness validation is complete.


## Capacity candidate validated, 10:56

The original full-suite wrapper 13240 and child 2296 have finished: 1,003 passed,
zero failed, empty stderr. Final log, error file, timings and job identity are
archived in network-capacity-plan with exact raw hashes. The final pack check
confirms 203 departure-only changes in each mode and every other field unchanged.
No suite or diagnostic remains active. Commit/push these coherent inputs, then
launch the guarded v9 script once and verify live command lines and fingerprints.
No full-day v9 job has been launched at this checkpoint. Legacy choices remain
certified; no unchanged legacy replay or native checks are needed.


## Candidate nine full-day launch, 11:02–11:04

Capacity candidate a24151d3 is committed and pushed after all 1,003 full source
tests passed. The commit completed automatic Git maintenance before pushing.
The guarded launch-network-v9.ps1 was executed ONCE at 11:02:33. Four affected
Network jobs are now active, recorded in rehearsal-jobs-v9.json:

- Classic baseline wrapper 7684 / child 23444.
- V2 baseline wrapper 22912 / child 240.
- Classic manual-delay wrapper 10888 / child 17992.
- V2 manual-delay wrapper 15504 / child 8840.

Each has its own rehearsals-v9 output folder and exactly one --output argument.
Both baselines record actual starts and time snapshots; both disturbances use
a 600-second manual K1 hold at simulation time 27,000 (07:30). After initial
catalogues appeared, all eight actual commands, baseline dispatcher modes,
4,837 distinct current source hashes and six frozen preparation observer hashes
were verified; stderr is empty. The initial check merely preceded catalogue
creation and was retried once data existed. No job was restarted or duplicated.
Exact launch script, verifier, initial records and verification are archived in
network-capacity-plan. The local inspector now follows certified v7 legacy and
active v9 Network jobs; it preserves historical rejected v8 evidence.

Freeze sim, routes, authored packs and all six preparation observers. Do not
rerun launch-network-v9.ps1. No suite/native/diagnostic/Git job remains after
this records commit. All four legacy choices stay certified and unchanged.
Network acceptance, category comparisons, installation and actual Network
menu/midnight/save-load checks remain pending. The pending prepared UI Network
branches and category helper must await real accepted traffic. Keep all failed
evidence and limitations; no baseline installation from disturbances or partials.

The continuation automation complete-train-game-realism-and-network-208 remains
active every ten minutes with the new process identities and current records.
The user extended work until ready; the historical 10:00 cutoff does not apply.
Delete this automation only once all authorized readiness work is finished.


## Candidate nine rejected; stricter planning search, 11:27–11:38

All four original v9 jobs finished naturally and failed; no process was restarted
or stopped early. Classic baseline and delayed fail S002 at 03:58:08, 5/208
finished, maximum continuous 2,702 seconds and station maximum 2,676. V2 baseline
and delayed fail M040 at 04:03:24, 6/208, both maxima 2,702. Zero safety events and
empty stderr throughout. Each audit has 4,836 current source hashes; 4,837
unique inputs verified across modes. Exact raw audit, traffic, failure state,
logs, packs and two immutable read-only inspections are preserved in
network-candidate-nine with 27 raw file hashes. Full service records and traffic
hashes match baseline/delayed within each mode over the failed prefix only;
neither reaches the 07:30 manual hold. No disturbance success claim is valid.

Both inspected snapshots have no future-clearance promises; several trains
are moving. Do not call this an immovable deadlock. Station receiving capacity,
repeated overtake holds and opposing flows make actual timing diverge from the
isolated profiles. The candidate's lower conflict score and estimated peak did
not predict acceptable traffic. Preserve failed evidence; no Network installed.

A local authoring-only constraint solver was installed under ignored
.local/realism-planning-deps, leaving the shared Python runtime and game inputs
unchanged. OR-Tools 9.15.6755 and exact downloaded dependency hashes are recorded
in planning-dependency-install.json. Official installation/API references:
https://developers.google.com/optimization/install and
https://github.com/google/or-tools/blob/stable/ortools/sat/python/cp_model.py.

plan-network-constraints.py emits proposals only. Original search process 22460
is running a bounded 180-second feasibility search: 208 departures, 15,816
pairwise separation constraints over the actual shared single-line groups,
three-minute following separation/no catching inside those groups, one-minute
section-end allowance, 3–13 starts/hour and isolated recurring fleet bound 34.
K1 remains 06:00; local/VB shifts bounded to 90 minutes, others 240 minutes.
These are planning constraints, never authored dwell or interlocking controls.
The model still omits interaction-induced delays and receiving-road detail;
feasibility would not certify real traffic. UNKNOWN would not prove infeasibility.
Do not edit the running script or duplicate this diagnostic. No runtime/tests,
prepared observers or timetable packs changed. No source suite/native/Git/full-day
job remains beyond this diagnostic and the existing editor/bridge/server.


## Planning continuation, 11:46

Failed v9 evidence is committed/pushed f977bbf2. Both read-only inspections have
finished. Additional exact actual-versus-solo call timing shows M003 at ALLP
arrives 02:04:41 in both, then actually leaves 02:56:19. M041 incurs an earlier
Ernakulam hold while two superfast trains follow about twenty minutes apart.
This timing divergence matters before any opposing-flow model can be trusted.
The selected-call comparison is diagnostic, not a full accuracy certificate.

The first strict solver process 22460 finished UNKNOWN after 180.247 seconds,
with empty stderr and no departure proposal. Preserve its script, final logs,
result and source pack hash in network-planning-revision; UNKNOWN does not prove
208 services infeasible. OR-Tools dependency versions/download hashes are recorded
there; the full pip report remains local. No game/Python-global changes occurred.

Two independent authoring diagnostics are now active, neither edits any pack:
- PID 16028: plan-network-constraints-v2.py, started 11:40:23, bounded 900 seconds.
  This broadens mail/superfast origins while keeping local/VB within 90 minutes
  and K1 fixed. Output network-constraint-proposal-v2.json; log/err/job record
  constraint-search-v2.*. No actual timetable acceptance follows from a result.
- PID 11944: plan-network-spacing-v3.py, started about 11:44. Output
  network-spacing-proposal-v3.json; logs/job record network-spacing-search-v3.*.
  Adds a 35-minute same-direction SF/VB approach-spacing penalty to limit repeated
  holds by successive expresses. This is a soft authoring target, never a runtime
  limit, forced pass location, dwell change or guarantee of actual separation.

Inspect existing diagnostic processes and results, do not duplicate them or edit
running scripts. Review station capacity, actual available separation and daily
coverage before applying any departure-only proposal. New pack changes still
need exact author reproduction, appropriate headless guards, explicit commit and
four affected Network baseline/disturbance replays. No current full-day job is
running. All four legacy choices and runtime hashes remain unchanged. The
continuation automation now describes these actual jobs instead of the ended v9
replays. Preserve pending UI/category tools and unrelated files; continue until
all authorized readiness gates pass, then delete that automation.

## Independent proposal review, 12:11

Both original diagnostics have finished with empty stderr. Strict v2 returned
UNKNOWN after 901.128 seconds; no solution or infeasibility proof. Heuristic v3
proposes 110 departure changes from candidate nine, with 69 overnight services
and 3–13 starts per hour. This proposal has NOT been applied. Candidate nine's
packs, all runtime/observer sources and all certified legacy data remain unchanged.

The independent hash-checked arithmetic review shows 240 to seven shared-section
SF/VB pair gaps below 35 minutes, minimum 20 seconds to 31.8 minutes, but opposing
overlap instances increase 329 to 382 and summed pair overlap 988.80 to 1,099.93
minutes. These periodic isolated-profile measurements are not observed delays.
The read-only physical yard export succeeds for 56 stations. Conservative visit
estimates still reach four trains at three-road ALLP and AMPA; ten passing yards
exceed total road counts somewhere in the proposal. Total roads are only an upper
bound; actual passenger faces, directional connectivity, full-tail berth fit,
route conflicts and escape roads remain stricter. This is a planning warning,
not an actual occupancy or admission proof. Exact 16 raw files are preserved
with hashes in network-planning-revision.

One new authoring diagnostic is running: plan-network-spacing-v4.py, PID 3760,
recorded in network-spacing-search-v4.job.json. It seeds from v3, adds a conservative
minute-cell yard over-capacity penalty and increases opposing-overlap weight.
Calls, dwell, stock, priorities and speeds remain untouched. The 35-minute express
gap remains a soft departure-planning target, not a runtime hold or forced pass.
Twenty incremental-versus-direct yard-cost comparisons pass; detailed local result
is yard-cost-arithmetic-check.json. Output will be network-spacing-proposal-v4.json.
Inspect the existing process/output first; do not duplicate or edit its live script.
No full-day, suite, native or diagnostic Godot job remains. Full 1,003 source tests
and four authoring guards remain current because their inputs have not changed.
Readiness is still pending; R47 and unrelated work are preserved.

## Compatible receiving-road planning, 12:22

Search v4 PID 3760 finished normally with empty stderr, producing 198 proposed
origin changes. The independent review shows no nominal total-road overflows,
but seven passenger-face capacity warnings, eleven following order reversals,
159 following-gap conflicts and peak isolated fleet 35. Opposing overlap falls
to 253 pair instances / 786.50 summed minutes; 14 SF/VB pair gaps remain below
35 minutes, minimum 29.4. These are estimates, not acceptance; v4 is not applied.

The final local export-planning-berths-v2.gd now uses the existing runtime
receiving_berths rule on an empty world for all 44 stock/call profiles, including
full-rake berth capacity, legal approach/onward route, passenger faces and terminal
compatibility. Its 4,835 source hashes and exact pack hash match current files.
KUMM stopping traffic shares only P3 in both directions; AMPA southbound traffic
has only P1, while northbound uses P2/P3. QLN retains the authorized 3/3 split.
The local first export rejected its flawed road-name filter; a subsequent export
needed exact origin-road membership so portal-fed arrivals were not omitted.
All are finished; only final v2 inventory is used. No runtime fix/change was needed.

The new static model constructs 108 compatible-road subset capacity constraints.
Direct bipartite matching agrees in 83,520 minute-cell cases across candidate nine
and v4. V4 still has 746 unmatched nominal yard-minute cells at 20 yards, against
897 at 26 originally. Counts are not observed waiting times. The 110 origin visits
use explicit physical passenger-road upper bounds; actual depot supply, reservations,
receiving escape and interaction delays are not certified by this model.

ONE authoring search is now running: plan-network-spacing-v5.py, PID 18712,
network-spacing-search-v5.job.json/log/err, output network-spacing-proposal-v5.json.
It seeds from v4, strengthens following separation and uses compatible-road subset
penalties. Twenty incremental/direct cost checks pass. All earlier search/export
jobs ended. Do not duplicate this search or edit its live script. Candidate nine
packs are unchanged, and no Network replay or suite is running. Both proposals
must remain unapplied until reviewed; any later selected times need exact author
reproduction, appropriate headless checks and committed inputs before four genuine
Network baseline/disturbance replays. Preserve pending UI/category and unrelated
files. Full 1,003 tests and four authoring guards remain current for unchanged inputs.

## Candidate ten authored, 12:31

Search v5 PID 18712 finished normally with empty stderr. It proposes 202 origin
changes; independent review leaves only three conservative unmatched yard-minute
cells, but opposing overlap increases. Two small repairs move L031 18:30 to 18:31
and L023 05:50 to 05:47. Strict zero-target repair attempts within five and fifteen
minutes cannot remove the final TVC clash without creating another modeled issue.
The scripts are preserved; this is a planning limit, not a change to actual gates.
One nominal cell at minute 1,310 remains, with M069/S019 both needing TVC P1.

The final proposal still has 202 changes from candidate nine. It has 485 modeled
opposing-overlap pair instances / 1,935 summed minutes, 47 following-gap conflicts,
zero following-order reversals, twelve SF/VB gaps below the 35-minute soft target
(minimum 31.53), and isolated peak fleet 35. These figures are not observed waits,
capacity acceptance or a performance claim. Genuine full-day simulation must
resolve this tradeoff rather than continuing to optimize an incomplete model.

The normal authoring tool wrote both packs using 205 overrides from the original
definitions. An exact field proof restores old departures and recovers each
whole predecessor pack byte-value structure; every non-departure field is unchanged.
Both modes have identical 208 services, 168 boundary journeys, 69 overnight origins,
3–12 departures/hour and K1 at 06:00. Exact author --check and all four headless
authoring tests pass, empty stderr. The prior exact packs/overrides are preserved
in candidate-ten-before and match the committed candidate-nine evidence.

Full suite wrapper 1276 / child 11920 is RUNNING on the new packs, logs
candidate-ten-full-tests.log/.err, job record candidate-ten-full-tests.job.json.
Inspect this existing job first; do not duplicate it or edit runtime/tests while
it runs. Runtime9ec3530 remains unchanged. Nothing new is committed yet: pending
coherent work is the three Network authored files, candidate-ten evidence and docs.
Preserve the unrelated pending prepared-UI Network checker/category helper.
Once the full suite passes, archive its final logs, commit/push exact paths, then
run prepared launch-network-v10.ps1 ONCE and verify-launch-v10.py against actual
process identities/modes/isolated outputs/current sources/six observers. Neither
v10 script has been run. All v9 replay jobs and all authoring diagnostics finished.
All four legacy choices remain installed/current/native-tested; no Network data
is installed. R47 is unchanged. Original actual wait/safety/call/completion/overtake
gates remain mandatory, followed by category and actual Network UI/save/midnight checks.

## Candidate ten full suite complete, 12:45

The original wrapper1276/child11920 finished: 1,003 passed, zero failed and empty
stderr. No suite process remains. All three authored hashes are unchanged from
launch. The final log/err/job and exact hashes are now archived in candidate-ten
evidence. No runtime/tests or observer edits occurred. Proceed with the explicit
candidate-ten commit/push and the already-prepared v10 launcher exactly once;
v10 output folders are still absent. This source-suite result is not full-day
traffic acceptance, installation or a new executable release.

## Candidate ten committed and v10 launched, 12:47

Candidate-ten packs, diagnostics and full 1,003-test evidence are committed/pushed
as a5e93191. All 26 staged raw evidence files and both packs match exact hashes.
The override JSON has only Git's CRLF-to-LF normalization; both hashes and exact
JSON equality are explicitly recorded, not relabeled. No prepared fingerprint
was altered. The only remaining tracked change outside this checkpoint is the
previous pending Network UI checker; unrelated untracked files remain untouched.

launch-network-v10.ps1 ran ONCE at 12:46:13 from that commit. Existing process pairs:
- Classic baseline: wrapper20756 / child8912.
- V2 baseline: wrapper11764 / child2888.
- Classic delayed: wrapper21044 / child17784.
- V2 delayed: wrapper11944 / child17700.

All eight actual commands match their recorded modes/options and have exactly one
distinct isolated output under rehearsals-v10. Both initial baseline catalogues
have the correct mode and current source hashes; 4,837 distinct source fingerprints
and all six observer hashes are verified. Empty stderr for all four. At 12:47,
baselines reached 00:20 and delayed runs 00:40; these prefixes prove no whole-day
acceptance. No final audits yet. Baselines save real snapshots; disturbances apply
600 seconds of manual K1 holding at clock27,000 and must never be installed.

Frozen scope: runtime/routes/packs and six preparation observers. Do not rerun the
launcher or restart/duplicate these jobs. Inspector now follows original v10 jobs
only, with the completed candidate-ten full suite as its source-test evidence.
No source suite, authoring diagnostic, native or Git operation remains running.
Five exact launch evidence files/hashes are saved beside candidate-ten proof.
Continue real full-day acceptance, independent installations, category comparisons
and actual Network menu/midnight/save-load checks before calling this ready.

## Candidate ten disturbed failures, 13:27

Both original delayed jobs have finished naturally and failed at 08:00:10 with
L005's 2,702-second wait at Alappuzha, 32/208 completed, zero safety, empty stderr.
The 600-second K1 manual hold at 27,000 was exercised; no recovery claim follows.
All-location under30 fractions143/146 and139/142; station92/94 and87/89: all below
98%, with under45 failing too. No rounded-up acceptance. Full-day comparison
requires complete populations and was not misapplied to these failed prefixes.

Both existing read-only inspections pass byte-immutability. L005's ALLP reasons
include1,208s reserved for M044 plus earlier V002 crossing/L015/receiving queues.
One future plan remains with M044/K1 received and V002's MAKM escape not yet
reached; several trains move. No deadlock or runtime-defect conclusion. No edits
to runtime, routes, packs or frozen observers. Exact4,837distinct hashes and both
pack hashes pass;22 raw diagnostic/replay files archived losslessly with hashes.

Two original baselines20756/8912 and11764/2888 continue; at13:26 both07:20, no
final audit and empty stderr. Never restart/duplicate them. Need their genuine
results before attributing disturbance effects or departure-only repairs.
All1003 source/four authoring checks remain current. PendingUI/category and
unrelated files preserved, no Network data installed, R47 unchanged.

## All v10 jobs finished rejected, 13:35

The two original baseline pairs have exited naturally. Both fail L005ALLP at
08:00:10,2702s,32/208,zero safety,empty stderr. All four v10 jobs are finished.
Two new read-only inspections preserve bytes, with no future plans remaining
in these baseline failures. Service records differ from disturbed runs, but
same failed gate/time proves the manual hold is not necessary for this failure.
Exact22 raw baseline files/4837current hashes preserved with prefix comparison.
No Network installation; no runtime changes, no new full suite necessary for
read-only evidence. Existing1003 source and four authoring checks remain current.

Actual L013/L015 ALLP departures07:04/07:25 bunch with L005's07:13 arrival and
opposing V002/M044, then M064/L014. L002 also has2622s extra wait atPASA after
1188s atERL; opposing L021/V005/M095/M075 form the southern queue. EarlierL022
passes the same corridor without >10min station waits in this prefix. Next test:
L01506:55->08:15 to free the ALLP origin/receiving conflict, L00206:10->05:45
behind L022 but before the opposing wave. These are hypotheses needing actual
new replays; preserve every other field, including K106:00 and all208 services.

## Candidate eleven authored and guarded

Changed only L00206:10->05:45 and L01506:55->08:15 using normal author overrides.
Both resulting whole packs recover the exact committed predecessors by restoring
those two departures; every other field remains unchanged. Identical services
both modes, K106:00,208total/168boundary/70overnight/3-12perhour. Categorycounts
remain40local,104mail,56SF,8VB. Normal --check reproduction and all4authoring
tests pass,emptyerrs. No runtime/test/observer edits; prior1003full source result
retained explicitly, no needless repeated full suite for two data timings.

All44failedv10rawfiles are already preserved in two evidence commits, including
22baseline hashes verified before ac1c4f16 push. Candidate11before preserves
three exact prior authored files. Nine completed candidate11 diagnostic/authoring
files and field/hash proof are in network-candidate-eleven. Small changes are
hypotheses based on actual queues, not traffic acceptance. Prepared launcher
launch-network-v11.ps1/verifier exist but have not yet run. Commit this tested
data, then launch four isolated actual baselines/disturbances once and freeze
inputs. PendingUI/category/unrelated preserved, Network notinstalled,R47intact.

## Candidate eleven committed; v11 launched once, 13:43

Candidate8056ea2f committed/pushed after9exact staged diagnostic files and both
pack hashes verified. launch-network-v11.ps1 ran ONCE13:42. Original process pairs:
Classic18724/5380,V216164/4076,Classicdelay13332/1016,V2delay16736/15508.
All8actual commands/options/single isolated outputs,baseline modes,4837distinct
currentfingerprints and6observers verified. First verifier attempted before the
initial departurecatalogue existed; later completecheck passes withoutrestart.
At13:43baselines00:10,delayed00:40,emptyerrs,noaudits. No acceptance frompartials.

Five exact launchfiles/hashmanifest archived alongside candidate11proof. Inputs
frozen:runtime/routes/packs/sixobservers. No suite/native/diagnostic/Gitoperation
left aftercheckpoint;onlyfour originalv11replays. Do not rerunlauncher,duplicate
or restart. Allv10failures preserved;legacychoicescertified,R47unchanged. Need
fulloriginalgates thenindependentinstall,category/native/midnight/save-load. Only
pendingUItracked/categoryuntracked andunrelatedfilesremainoutsidecommittedwork.

## Candidate eleven disturbed failures preserved, 14:22

Both original disturbed jobs finished naturally. Classic rejects M006 at AMPA
08:52:40 with 38/208 complete; V2 rejects L002 at NYY07:56:50 with32/208.
Both record2702s extra waiting, zero safety and empty stderr, after the actual
07:30-07:40 K1 hold. All shorter cumulative wait gates pass in the prefixes,
but all-location under45 fractions179/180 and142/143, station110/111 and85/86,
fail the required100%. No complete-day comparison or recovery certificate.

L005 clears ALLP07:28:45.80/07:28:30.30, with816/802s extra station waiting;
Classic's maximum all-location wait for this service is818s, a distinct metric.
This fixes the previously observed local obstruction only. Classic M006 then
waits for S030/overtaking and opposing K1/L007/receiving queues at AMPA. V2
L002 instead waits at NYY for successive opposing services and NEM capacity.
Classic L002 left NYY07:12:31.30, before the manual intervention; that divergence
cannot be attributed to the later hold. Await both baseline results before
further departure-only repairs. No runtime-defect or immovable-deadlock claim.

Both headless read-only inspections pass byte-immutability; no future-clearance
plan remains in either failure snapshot and several trains still move. All4837
distinct current fingerprints and exact authored packs verify.24 raw files are
archived losslessly with hashes in network-candidate-eleven/failed-disturbances.
Original outputs remain intact. No suite/source/packs/observer changes or new
installation. Runtime1003 source tests/four authoring checks remain current.
Two original baselines18724/5380 and16164/4076 continue, both07:20 at14:22,
empty stderr/no audit. Frozen inputs and pendingUI/category/unrelated preserved;
R47 unchanged. No diagnostic/Git operation remains after this checkpoint.

## V2 baseline also rejected; Classic continues, 14:31

The original V2 baseline16164/4076 finished naturally at07:56:50 with L002
NYY2702s,32/208,zero safety,empty stderr. All shorter cumulative wait gates
pass in this prefix; under45 all141/142 and station84/85 fail100%. L002's
entire service record and station-wait rows exactly match its disturbed run,
but whole service records and traffic hashes differ. This local failure does
not require the K1 hold. No full-day comparison or uniform equivalence claim.

Read-only headless inspection is byte-immutable, with no future plan and other
trains moving. Verified4,836 source hashes/exact V2 pack and14 exact raw files,
including scoped comparison, archived in failed-predictive-baseline. Original
outputs remain. No runtime/packs/observer/test edits; no new suite required for
this read-only evidence. Existing1,003 source/four authoring checks stand.
Classic18724/5380 remains the sole live replay, at09:10 and41/208 at14:31,
empty stderr/no audit. Preserve frozen inputs until that actual result. Pending
UI/category/unrelated files remain unchanged; Network uninstalled,R47 intact.

## All v11 runs finished rejected; next departure hypothesis

Classic18724/5380 finished at09:23:20: L024 atKZT2702s,44/208,zero safety,
empty stderr. Under30 all197/202 and station119/123 miss98%; under45 also fails.
L024 reachesERL07:57:44.50, leaves08:22:45.80 after1362s extra, then reaches
KZT08:37:07 and waits for M047/L035 and later S045/M061 receiving-space queues.
Read-only inspection preserves bytes; no future plan remains, several trains move.
Classic M006 clearsAMPA08:07:40.80 without the manual hold; its disturbed run
fails there.13 exact raw files and4836source hashes verified for Classic failure.
All original outputs remain, no Network data installed. No replay/suite active.

Next bounded hypothesis: L00205:45->05:05 to move its northbound approach ahead
of the observed ERL/NEM opposing wave; M00605:50->05:20 to increase its lead over
S030 and reach AMPA before the K1/opposing queue; L03507:20->06:45 to separate
its southbound approach from M047/M061 around L024's KZT arrival. L015 stays
08:15 and L024 stays07:40. Every other field, K106:00 and208 services must stay
unchanged. These are timetable hypotheses, not guarantees or forced pass sites.
Check exact author reproduction and headless authoring guards, then commit and
launch a new isolated generation once. Runtime/tests remain unchanged from1003
passing source tests; preserve all failed evidence and pendingUI/category files.

## Candidate twelve authored and guarded

The three planned departure edits are authored through the normal205override
pipeline. Restoring only L002/L035/M006 departures exactly recovers each whole
predecessor pack; both predecessor byte hashes match committed candidate eleven.
All other fields and identical Classic/V2 services remain, K106:00,L01508:15,
L02407:40.208 services/168boundary/70overnight/3-12starts perhour, category mix
40local/104mail/56SF/8VB unchanged. Exact --check reproduction and all4headless
authoring tests pass with empty stderr. No runtime/tests/observer edits or new
full suite; existing1003source result remains explicit. Nine raw evidence files
archived. Candidate remains unaccepted. Guarded v12 launcher/verifier prepared
but NOT RUN; commit/push tested data first, then launch four isolated jobs ONCE.
All earlier jobs/diagnostics are finished. Preserve pendingUI/category/unrelated.

## Candidate twelve committed; four v12 jobs launched once, 14:42

Candidatec8856a27 is committed/pushed after9staged evidence hashes and both
exact pack hashes verify. launch-network-v12.ps1 ran ONCE14:42:16. Original
wrapper/child pairs: Classic21244/3532,V25504/5044,Classicdelay4720/13732,
V2delay2636/8496. All8actual commands/options/single distinct outputs, both
baseline modes,4837current source hashes and six observers verify. At14:42
baselines are starting, disturbed clocks00:20/00:30,stderr empty,no finalaudit.
No acceptance from prefixes. Five exact launchfiles/hashmanifest archived.
Inspector now follows existingv12. Do not restart,duplicate or rerunlauncher.

Freeze runtime/routes/packs/sixobservers while jobs run. No suite/native/search/
diagnostic/Git operation remains aftercheckpoint. Allv11 failures preserved:
disturbed6be9de56,V2baselinee9bdccd2,Classicbaselinec65925e8. Old fingerprints
remain historical after the new authored pack change; never relabel. Legacy
certifications unchanged,Network unavailable,R47 preserved. PendingUI/category
and unrelated files remain outside coherent committed work. Need original full
acceptance gates, independent baseline installations and actualcategory/native/
midnight/save-load checks before declaring ready.


## Candidate twelve V2 delayed run rejected before intervention, 15:12

The original 2636/8496 pair finished naturally at 06:38:42 with S025 waiting
2,702 seconds at PASA-S2. Only 24/208 services complete, zero safety events,
empty stderr. It never reaches the scheduled 07:30 manual K1 hold. All-location
under30 is 111/114 and under45 is 113/114, both failed; station-only gates pass
within this failed prefix, maximum1,810 seconds. No full-day or recovery claim.

S025 records2,242 seconds of Kulitturai roads reserved for S030/L022,446 seconds
of opposing L002 occupation and14 seconds of route conflict. Read-only inspection
is byte-immutable with no future plans: S025/M077 occupy both Parassala roads,
S030 waits at KZT-N2 for Parassala, L022 waits before Kulitturai while preserving
Parassala crossing space. All eight inspected trains are stopped at this instant;
no permanent-deadlock or runtime-defect conclusion from one snapshot. Wider
NYY/NEM receiving queues are preserved in the raw evidence.

Thirteen exact raw files, the V2 pack and4,836 current source hashes verified;
lossless failed-predictive-delayed evidence is archived under candidate twelve.
No source/packs/observers changed, no full suite repeated, no Network install.
Both original baselines and Classic delayed remain live; await actual results
before selecting departure-only repairs. Preserve all earlier evidence, pending
UI/category helpers, legacy certifications and R47. No diagnostic remains running.


## Both v12 delayed jobs rejected before their scheduled hold

Classic4720/13732 has now finished at07:21:20: L002 waits2,702s atNYY after
arrival06:35:08.70,28/208 complete,zero safety,empty stderr. All-location under30
128/131 and station80/82 fail98%; under45130/131 and81/82 fail100%. The manual
K1hold scheduled07:30 never occurs in either v12 delayed prefix. Neither is a
recovery certificate. L002 records1,640s opposing M079/L033/L021 section traffic,
38s route conflicts and1,024s NEM receiving availability/reservations.

Read-only snapshot inspection is byte-immutable with no future-clearance plans.
L002/L021 occupy NYY;L035/M095 occupy NEM;L021 awaits PASA. L033/M079 still move.
No immovable-deadlock/runtime-defect conclusion. Another13 exact raw files and
4,836 current source hashes/exact Classic pack verified, original outputs kept.
Both original baselines21244/3532 and5504/5044 remain live; await actual results
before retiming. No input/observer/source changes, duplicate jobs, suite or
native diagnostic remains. Network uninstalled; pending UI/category preserved.


## V2 baseline also rejected at the same pre-intervention queue

The original5504/5044 pair has finished S025 PASA06:38:42,24/208,2,702s,
zero safety and empty stderr. Full service records, station waits, signal waits
and traffic bytes exactly match the V2 delayed failed prefix. Both end before
07:30; this is scoped prefix equality, not recovery or full-day equivalence.
The actual byte hashes and equality checks are preserved separately, without
misapplying the complete-population comparator. The fresh read-only inspection
is byte-immutable, no future plans, same eight inspected trains stopped.

Fourteen exact raw files and4,836 current source hashes/exact pack verified.
The local archive guard initially expected the delayed default delay_at in a
baseline; corrected only that diagnostic assertion to compare clock<27000,
before any archive directory was created. No simulation/replay edits or rerun.
Only Classic21244/3532 remains live. Await its result before retiming. Inputs
remain frozen, pendingUI/category and R47/legacy data preserved, no Network install.


## All v12 jobs finished rejected; next ordered departure hypothesis

Classic21244/3532 also fails L002 NYY07:21:20,28/208,2,702s,zero safety,
empty stderr. Its full service records,both wait lists andtraffic bytes match
the Classic delayed failed prefix. Both stop before07:30; no recovery/full-day
certificate. Another14 raw files and4,836 current hashes verified,immutable
inspection,no future plans,L033/M079 moving. All original v12 outputs remain.
No replay/suite/diagnostic is active. No Network installation or changed gates.

Next limited hypothesis: L00205:05->04:20, following M06404:10 and preceding
L03404:30, avoids the shared05:05 origin with faster S030. It aims to preserve
northbound order before the observed southern opposing wave; no guarantee of
capacity or complete-day improvement. Keep all other service fields, M00605:20,
L03506:45,K106:00 unchanged. Require exact reproduction/four authoring guards,
then explicit commit and new isolated four-run generation. No full-suite repeat
for a departure-only data edit; the runtime/tests are unchanged from1003 passed.


## Candidate thirteen authored and guarded

Only L00205:05->04:20 changes. Restoring its old departure recovers each whole
predecessor pack; predecessor bytes match committed candidate twelve. Identical
mode services,208total/70overnight/3–12hourly,40local/104mail/56SF/8VB remain.
K106:00,M00605:20,L03506:45,L01508:15,L02407:40 unchanged. Normal authoring
through205 overrides and exact --check reproduction pass. All4 headless authoring
tests pass,emptystderr;runtime/tests unchanged from1003 full source tests,not
rerun for one departure edit. Nine exact raw files archived. No acceptance claim.
Prepared launch-network-v13.ps1 and verifier, NOT RUN; commit/push tested inputs
before launching four new isolated actual replays once. Old v12 fingerprints
are historical after pack change; never relabel. PendingUI/category/unrelated
preserved. No suite/diagnostic remains active.


## Candidate thirteen committed; v13 launched once at15:28

Candidatee81de25a committed/pushed after9raw evidence and both stagedpack hashes
verify. Launch-network-v13.ps1 ran once15:28:43. Wrapper/child pairs:
Classic12028/21668,V25080/14780,Classicdelay1180/18720,V2delay18248/10524.
All8actualcommands/options,single distinctoutputs,baseline modes,4,837distinct
source fingerprints and6observerhashes verify. First verifier was before initial
catalogue creation; retry passed, no jobs restarted. Five exact launchfiles archived.
Inspector now follows existingv13. Do not relaunch,duplicate or restart.

Freeze runtime/routes/packs/sixobservers throughout the four runs. No suite,
native,authoringsearch,diagnostic or Git operation remains aftercheckpoint.
All v12 failures preserved:084590b0(V2delayed),55a0aa8b(Classicdelayed),
21314ee5(V2baseline),6407d5a9(Classicbaseline). Old fingerprints are historical
following the new pack;never relabel. Existing1003source/fourauthorchecks stand.
Network unaccepted/uninstalled,R47/legacycertifications and pendingUI/category/
unrelated files preserved. Need genuine complete-day gates,independentinstall,
actual category/menu/midnight/save-load before readiness.


## Candidate thirteen: disturbed failures preserved, baselines still pending

Both original delayed jobs have finished naturally: Classic1180/18720 fails
L024 at KZT09:19:08; V218248/10524 fails V001 at MAKM-S3 09:17:48. Each has
43/208 completions,2,702 seconds extra waiting,zero safety and empty stderr.
Both traverse the actual07:30–07:40 manual K1 intervention; no recovery certificate.
Minute K1 extent samples show Classic stationary and V2 braking13.56m further
by07:31 before remaining stationary. These are sampled positions,not invented
controller-state snapshots. Both station and all-location cumulative gates fail;
exact fractions are in network-candidate-thirteen/failed-disturbances/README.md.

L024 reaches KZT08:32:55.40 with no departure. Its wait includes1,562s opposing
L035/M075/M047/L023,1,102s receiving/downstream crossing protection and38s
route conflicts. L035 still accumulates2,696s at PASA, L0232,686s at NYY.
V001's MAKM wait includes1,164s opposing M064/S030,1,250s ALLP receiving
availability/reservations,168s occupied blocks and120s route conflicts.
At inspection L007 waits atALLP,M008 arrives,M017
moves; K1/L015/M013/M064/S030 also move. Both read-only snapshots remain
byte-immutable, no future plans. No permanent-deadlock/runtime-defect conclusion.

Twenty-two exact raw files and4,837 distinct current source hashes verified,
including both packs,lossless audits/traffic/snapshots,summaries and inspections.
Original baseline12028/21668 and5080/14780 remain live; at16:12 Classic07:50
(32/208),V207:40(31/208),emptyerrs,noaudits. Wait for these outcomes before
attribution or departure-only repair. No frozen input/runtime/test edits,duplicates,
installation or full-suite repetition;1003 source/four authoring checks stand.
R47,legacy certifications,pending UI/category helpers and unrelated files preserved.


## All v13 runs finished rejected; move two origins outside observed waves

Classic baseline12028/21668 fails L007 ALLP09:07:06,41/208; V2baseline5080/14780
fails L024 KZT09:19:08,44/208. Both2,702s extra wait,zero safety,empty stderr.
Both wait distributions fail; exact fractions and24 raw files are preserved in
network-candidate-thirteen/failed-baselines. All4,837 distinct current hashes
verified. Read-only snapshots remain immutable,no future plans,several trains
move. No permanent-deadlock/runtime-defect conclusion or Network installation.
V2 baseline L024's entire record/station waits match Classic delayed at the
same clock, but whole services/traffic differ. No full-population comparison.

Classic L007 arrivesALLP08:20:02.65,then1,088s awaiting M013's pass and646s
opposing L014 plus other recorded receiving/block/conflict waits. L015 leaves
ALLP08:33:16.30,M01308:57:13.30; M008/S006 wait atAMPA and S030 atALLP.
V001,M013,M006,M017,K1 move. L024's southern opposing-wave failure also occurs
without the manual hold. All four v13 jobs are now finished naturally.

Next limited hypothesis moves L02407:40->09:20 after the observed southbound
wave and L01508:15->10:05 after the crowded ALLP receiving/origin interval.
This retains at most13 starts/hour. These are not acceptance or capacity proof;
later queues remain unknown. Preserve every other field,identical modes,K106:00;
require exact normal authoring and four headless guards before commit/launch.
No full-suite repeat for data-only edits; runtime/tests remain1003passed.


## Candidate fourteen authored and checked

Only L02407:40->09:20 and L01508:15->10:05 changed through normal authoring.
Restoring the two departures recovers whole predecessor packs exactly; modes
have identical services,K106:00,L00204:20,M00605:20,L03506:45 unchanged.
208services,168boundary,70overnight,3–13hourly,40local/104mail/56SF/8VB.
Exact --check reproduction and four headless authoring guards pass,emptyerrs.
Runtime/tests unchanged from1003fullsuite,not repeated for two data edits.
Ten exact proof files and predecessor backups preserved. No traffic acceptance.
Prepared launch-network-v14.ps1/verifier are not run; commit testedinputs first.
All v13jobs finished,baselineproof7342da7d pushed; no source suite/diagnostic active.


## Candidate fourteen committed; four verified v14 runs launched once

Candidate433be026 committed/pushed after10staged proof hashes and both pack
hashes verified; override JSON matches despite Git text normalization.
Launch-network-v14.ps1 ran once16:32:06. Classic baseline19884/3816;
V2baseline22452/10152; Classic delayed18440/20884; V2delayed22416/6768.
All8actual commands/options,single distinctoutputs,both baseline modes,
4,837 distinct current source fingerprints and6observer hashes verify.
Waited for catalogue creation before verifier; no jobs restarted. Five exact
launch files/hashmanifest preserved. Inspector now follows existingv14 first.
At16:32 baselines00:10,delayed00:40,allidentitiesmatch,emptyerrs,no finalaudits.

Freeze runtime/routes/packs/sixobservers until all finish. No suite/native/search/
diagnostic remains. Preserve all v13failure evidence with historical hashes;
do not relabel after pack changes. No partial acceptance/installation. Need
genuine full-day and disturbance gates plus independent prepared and actual
category/menu/midnight/save-load validation. PendingUI/category/unrelated and
R47/legacycertifications unchanged.

## Candidate fourteen Classic disturbance rejected; other runs pending

Original Classic delayed18440/20884 ended naturally at09:30:48: M064 waits2,702s
atMAKM-N2,46/208 services complete,zero safety,empty stderr. The actual600s
K1 manual hold at07:30 is reflected by unchanged minute extent samples through
07:40; no recovery certificate. All-location cumulative153/211,187/211,208/211,
210/211 fails under20/45; station92/130,117/130,130/130,130/130 passes only this
prefix. No rounding,complete-population comparison or installation.

M064's failed wait records2,194s opposing section occupation,346s awaitingV001,
142s receiving availability,20s conflicts. EarlierALLPwait1,326s includes1,308s
protectingL007's escape atMAKM. Two byte-immutable read-only inspections find no
future plans. M064/S030 waitMAKM-N2/N1,S009 protects compatible receiving roads,
M017 waits for automatic block clearance. K1,L007,M013,M044,V001 move; no
permanent-deadlock/runtime-defect conclusion.17 exact raw files and4,836 current
source hashes preserved in network-candidate-fourteen/failed-classic-delayed.

At17:16 both original baselines07:50(32/208),V2delayed10:00(50/208),identities
match,emptystderr,no audits. Wait for their outcomes before departure-only
repairs; runtime/routes/packs/sixobservers remain frozen. No duplicate/restarted
jobs,source-suite repetition or pendingUI/category edits. R47 and legacy
certifications remain unchanged. Network208 is unaccepted and uninstalled.

## Candidate fourteen V2 disturbance also rejected

Original22416/6768 ended naturally at10:35:04: L002ALLP2,702s extra wait,
57/208finished,zero safety,empty stderr after the07:30 manualhold. All-location
fractions197/273,250/273,270/273,272/273 fail under45. Station99/142,128/142,
140/142,141/142 fail under10 and45;99/142 is below70%,not a rounded pass.
L002 arrivesALLP09:48:00.75 withoutdeparture;968s awaitingS008pass,280M017crossing,
912receiving/onward protection,452opposing occupation,78blocks,12conflicts.

Immutable inspection: ALLPclaimsL015P1,L002P2,M019P3;S013 waits atMAKM forALLP.
M019,M011,M017,S008,K1move,M013exchanges passengers. One future plan atSRTL:
incomingS008P3,vacaterM008,opponentS031P2,escapeTUVRP3;receipt/escape flagsfalse.
No permanent-deadlock/runtime-defect inference.13 exact raw files and4,836
current source hashes preserved in failed-predictive-delayed. Both disturbances
are rejected; no recoverycertificate or installation. Original baselines remain
live at17:20 Classic08:20(35/208),V208:30(36/208),identitymatches,emptyerrs,noaudits.
Freezeinputs and await their outcomes before any departure-only repair.

## Candidate fourteen Classic baseline rejected; V2 baseline still running

Original19884/3816 ended naturally at09:34:44,withoutmanualhold: M008AMPA2,702s,
47/208finished,zero safety,empty stderr. Cumulative all154/211,195/211,208/211,
210/211 and station91/130,119/130,128/130,129/130 fail both under45 gates. Earlier
targets pass only within these failed-prefix populations,not whole-day evidence.
M008arrAMPA08:48:33.20,nodeparture:1,194s opposingS009/M013/V001,748receiving,
662S006overtake,74occupiedblocks,24conflicts. Immutableinspection,no futureplans:
M008waitsAMPA-N2,M017waitsALLP-S2 behindS009. M013,M064,S006,S009,S030,V001,K1
move,L007exchangespassengers. M064approachesERS instead of its disturbedMAKM
failure; no universal equivalence/permanent-deadlock/runtime-defect inference.

13 exactrawfiles and4,836current sourcehashes preserved in failed-classic-baseline.
At17:35 originalV2baseline22452/10152 remainslive11:00,59/208,identitymatches,
emptyerr,noaudit. Await its outcome before altering frozen departures/observers.
No duplicate jobs,source/test edits,repeated suite or installations. Network
unaccepted;R47,legacycertifications,pendingUI/category/unrelatedpreserved.

## All v14 runs finished rejected

OriginalV2baseline22452/10152 ends naturally11:28:50: S047NEM-S1 wait2,702s,
62/208finished,zero safety,emptyerr,withoutmanualhold. All-location cumulative
249/329,307/329,326/329,328/329 failsunder45;station124/171,158/171,170/171,
171/171 passes onlywithinprefix,max2040s,not a waiver. S047wait1796s opposing
S032/M048/M050/M084,858receiving/onwardPASAprotection,48conflicts. Immutable
inspection,no futureplans:L024NYYP2awaitsM068approachingP1,L036PASAwaitS050;
M048,M050,S032,M068,L025,L026move,M084returnsTVCdepot. No permanent-deadlock/
runtime-defect conclusion.13exactrawfiles/4836currenthashespreserved in
network-candidate-fourteen/failed-predictive-baseline. Allv14jobsfinished;
do not rerun unchanged. No Networkacceptance/installation. Plan only departure
repairs from actualqueueevidence,preserve all otherfields and source/testguards.

## Candidate fifteen departure-only hypothesis

Candidate fifteen now changes only M064 04:10→03:40, L002 04:20→03:50,
M008 06:25→05:55 and S047 10:35→10:00. These earlier departures aim to avoid
observed opposing and receiving queues; no complete-day improvement is claimed.
Restoring them recovers both whole predecessor JSON objects, with every other
field unchanged, identical mode services and K1 fixed at 06:00. There are 208
services, 168 boundary journeys, 71 overnight origins and 3–13 starts/hour.
Normal author reproduction and four headless authoring checks pass with empty
stderr. The unchanged runtime/tests retain the completed 1,003-test source suite;
it was not rerun for these data edits. Ten exact proof files are preserved in
network-candidate-fifteen evidence.
Fresh isolated runs remain required; Network is not accepted or installed.

## Verified v15 launch

Candidate `81875feb` is committed/pushed. Four v15 replays launched once at
17:57:11: Classic baseline 21452/12244, V2 baseline 7968/9656, Classic delayed
14684/21820 and V2 delayed 22140/3124 (wrapper/child). All eight actual commands
and options, distinct single output arguments, initial baseline modes, 4,837
distinct source fingerprints and six observer hashes are verified. Verification
waited for initial catalogues; no jobs restarted. Five exact launch files are
archived with hashes. At 17:57 both baselines reach 00:10 and disturbances 00:30,
with empty stderr and no final audits. These partial clocks do not certify traffic.
Inputs/observers are frozen while the original jobs run. Baselines save genuine
snapshots; delayed runs apply a 600-second K1 manual hold at 07:30 and cannot be
installed. No source suite, native test, authoring search or diagnostic remains.

## 18:01 original v15 checkpoint

At 18:01 the four original v15 process pairs still match their recorded commands.
Classic baseline reaches 01:10 and V2 01:20 (0/208); both delayed runs reach
02:00 (1/208), before the planned 07:30 hold. All stderr files remain empty and
no final audit exists. Inputs and observers remain frozen; continue inspecting
these original jobs. No repeated tests, duplicate jobs, partial acceptance or
installation. The 1,003 source tests and four authoring checks remain unchanged.

## 18:10 original v15 checkpoint

At 18:10 the four original v15 process pairs still match their recorded commands.
Both baselines reach 03:20 (2/208); both delayed runs reach 04:30 (9/208), before
the planned 07:30 hold. All stderr files remain empty and no final audit exists.
Inputs and observers remain frozen; continue inspecting these original jobs.
No repeated tests, duplicate jobs, partial acceptance or installation. The 1,003
source tests and four authoring checks remain unchanged.

## Three v15 failures before the intervention

At 18:22 three v15 jobs have finished and failed before the planned 07:30 hold.
V2 baseline and delayed both fail M045 at TVC_NEM_M5-SH, 05:22:18, 14/208;
their entire service records, both wait lists and traffic bytes match within
that failed prefix. Classic delayed fails S030 at PASA-N2, 06:37:06, 22/208.
All have 2,702-second waits, zero safety events and empty stderr. No recovery
or whole-day certificate follows. Forty exact raw files and 4,836 current
source fingerprints per report are preserved in candidate-fifteen evidence,
with three byte-immutable inspections and no remaining future-clearance plans.
V2's inspected active queues are stopped; Classic still has moving trains.
Neither snapshot proves permanent deadlock or a runtime defect.
Only Classic baseline 21452/12244 remains running (05:20 at 18:22, 16/208),
with matching identities, empty stderr and no final audit. Await its outcome
before any departure-only repair; inputs and observers stay frozen.

V2 M045 wait: 2,564 seconds preserving NYY crossing capacity plus 138 seconds protecting compatible NEM receiving roads. M078 occupies NEM_P2 and waits for M045; M044/M064 wait at NYY, L002/S046 at PASA. Seven active inspected trains stop, M001 is stored. V2 cumulative all49/62,52/62,53/62,61/62; station30/37,32/37,32/37,37/37. Classic S030 wait: 1,504s receiving,1,172s opposing,26s conflicts. NYY claimsS027P1/L034P2;M071/M077/S025/S027move. Classic cumulativeall92/116,106/116,112/116,115/116;station57/72,67/72,70/72,72/72. These failed-prefix populations miss multiple unchanged targets.

## All v15 runs rejected before the intervention

The original Classic baseline 21452/12244 has now ended naturally at 06:37:06:
S030 waits 2,702 seconds at PASA-N2, 22/208 services finish, zero safety events
and empty stderr. All four v15 runs are rejected before the scheduled hold.
Classic baseline and delayed entire service records, both wait lists and traffic
bytes match within this failed prefix only. Fourteen additional exact raw files,
4,836 current source fingerprints and an immutable inspection are preserved in
candidate-fifteen/failed-classic-baseline. No future-clearance plans remain;
M071, M077, S025 and S027 still move. The failed-prefix fractions and queue reasons
match Classic delayed. No permanent-deadlock, runtime-defect or whole-day claim.
No Network installation; plan the next departure-only repair from actual queues.

## Candidate sixteen departure-only hypothesis

Candidate sixteen changes only M045 00:45→00:00 and S030 05:05→04:20 from v15.
The earlier departures aim to precede the observed NEM/NYY receiving cluster
and PASA opposing wave; actual full-day improvement remains unproven. Both
whole predecessor JSON objects recover exactly when these departures are
restored; every other field, identical mode services and K1 06:00 remain.
There are208 services,168 boundary journeys,71 overnight origins and3–13 starts/hour.
Exact normal author reproduction and four headless authoring checks pass with
empty stderr. The unchanged runtime retains its completed1,003-test source suite;
it was not rerun for two data timings. Ten exact proof files are preserved in
[candidate-sixteen evidence](../art/performance/realism-2026-10-26/network-candidate-sixteen/README.md).
Fresh isolated runs are required. Network208 remains unaccepted and uninstalled.

## Verified v16 launch

Candidate146339ab is committed/pushed. Four v16 replays launched once at18:36:57:
Classic baseline1200/9828, V2baseline13572/12168, Classicdelayed16820/21556,
V2delayed9104/5132 (wrapper/child). All eight actual commands/options, distinct
single output arguments, initial baseline modes,4,837 distinct source hashes
and six observer hashes are verified. Verification waited for initial catalogues;
no jobs restarted. Five exact launch files and hashes are archived. At18:37
baselines are starting and delayed runs reach00:10,empty stderr,no final audits.
Partial clocks are not acceptance. Inputs/observers are frozen throughout these
original runs. Baselines save genuine snapshots; delayed runs apply600s K1hold
at07:30 and cannot be installed. No suite,native,search,diagnostic or Git job remains.

## 18:44 v16 checkpoint

At the 18:44 checkpoint, all four original v16 wrapper/child identities still
match. Classic/V2 baselines reach 02:00/02:10 (1/208 complete each); delayed
runs reach 03:00/03:10 (2/208 each), before the planned 07:30 intervention.
All stderr files are empty and no final audit exists. These are partial runs,
not acceptance. Runtime, routes, packs and the six observers remain frozen;
no jobs were duplicated or restarted and no unchanged tests were repeated.
Network 208 remains unaccepted and uninstalled.

## 18:51 v16 checkpoint

At the 18:51 checkpoint, all four original v16 wrapper/child identities still
match. Both baselines reach 03:20 (2/208 complete); both delayed runs reach
04:30 (9/208), before the planned 07:30 intervention. All stderr files are
empty and no final audit exists. Partial runs do not establish acceptance.
Runtime, routes, packs and the six observers remain frozen; no jobs were
duplicated or restarted and no unchanged checks were repeated. Network 208
remains unaccepted and uninstalled.

## All v16 runs rejected before intervention

All four original v16 runs have ended naturally and are rejected: M045 at
NYY 04:45:52, 13/208 complete, 2,702 seconds extra waiting, zero safety events
and empty stderr, before the planned 07:30 intervention. Both wait populations
fail under-30/45 targets. Within each mode, baseline/delayed entire service
records, both wait lists and traffic bytes match this failed prefix only;
across modes M045's record matches but wider traffic differs. Forty-five exact
raw files, 4,837 distinct current source hashes and four immutable read-only
inspections are preserved in [v16 failed-run evidence](../art/performance/realism-2026-10-26/network-candidate-sixteen/failed-runs/README.md).
No future plans remain; multiple trains move. M045's wait includes 2,196s
opposing occupation, 468s receiving/downstream protection and 38s conflicts.
No permanent-deadlock, runtime-defect or full-day claim. No v16 job remains;
never rerun this unchanged candidate. Network remains unaccepted/uninstalled.

## Candidate seventeen departure-only hypothesis

Candidate seventeen changes only M100 03:05→02:00 and M078 03:20→02:10.
These northbound mails move ahead of S026/M092/M076, aiming to create a gap
for M045 through the observed NYY/PASA opposing wave. Earlier queues and
complete-day performance remain unproven. Every other whole-pack field is
unchanged; predecessor JSON restoration, identical modes and K1 06:00 are
verified. There are208 services,168 boundary journeys,71 overnight origins,
3–13 starts/hour. Exact normal reproduction and four headless authoring tests
pass with empty stderr. The unchanged1,003-test source suite was not rerun.
Ten exact proof files are preserved in [candidate-seventeen evidence](../art/performance/realism-2026-10-26/network-candidate-seventeen/README.md).
Fresh isolated replays are required; Network remains unaccepted/uninstalled.

## Verified v17 launch

Candidate5ffdb3da is committed/pushed. Four v17 replays launched once at19:08:12:
Classic baseline16000/12508, V2baseline15064/2092, Classicdelayed16736/12232,
V2delayed10492/17808 (wrapper/child). All eight actual commands/options, distinct
single outputs, initial baseline modes,4,837 distinct source hashes and six
observer hashes are verified. Verification waited for initial catalogues;
no jobs restarted. Five exact launch files and hashes are archived. At19:08
baselines are starting,delayed00:20,empty stderr,no final audits. Partial clocks
are not acceptance. Runtime/routes/packs/observers are frozen. Baselines save
real snapshots; delayed runs apply600s K1hold07:30–07:40 and cannot be installed.
No suite,native,search or diagnostic job remains.

## 19:12 v17 checkpoint

At19:12, all four original v17 process identities match, stderr is empty and
no final audits exist. Both baselines reach01:10 (0/208 complete); both delayed
runs reach02:00 (1/208), before the planned07:30 intervention. Runtime, routes,
packs and six observers remain frozen. No duplicates, restarts, unchanged test
repeats, partial acceptance or installations. Await the original runs' outcomes.

## 19:21:59 v17 checkpoint

At19:21:59, all four original v17 process identities match, stderr is empty
and no final audits exist. Both baselines reach03:20 (2/208 complete); Classic
delayed reaches04:30 (10/208), V2 delayed04:20 (7/208), before the planned07:30
intervention. Runtime, routes, packs and six observers remain frozen. No jobs
were duplicated or restarted and no unchanged checks were repeated. Partial
runs are not acceptance; Network208 remains unaccepted and uninstalled.

## Both v17 V2 runs rejected before intervention

Both original v17 V2 runs ended naturally and failed M045 at PASA05:06:26,
16/208complete,2,702s extra wait,zero safety,empty stderr,before the planned
07:30 hold. Their entire service records,both wait lists and traffic bytes
match within this failed prefix only.24 exact raw files,4,836 current source
hashes per report and two immutable inspections are preserved in
[V2 failure evidence](../art/performance/realism-2026-10-26/network-candidate-seventeen/failed-predictive-runs/README.md).
All-location55/59,58/59,58/59,58/59 failsunder45;station35/38,37/38,37/38,37/38
failsunder30/45. M045 leaves NYY04:09:46.30 then reachesPASA04:20:11.70 without
departure:1,690s opposing occupation,976s KZT receiving reservations,36s conflicts.
No future plans remain;several trains move. No recovery,whole-day acceptance,
permanent-deadlock or runtime-defect claim. The two original Classic runs are
still pending; inputs/observers remain frozen and Network remains uninstalled.

## Both v17 Classic runs rejected before intervention

Both original v17 Classic runs ended naturally and failed M063 at ALLP07:04:42,
28/208complete,2,702s extra wait,zero safety,empty stderr,before the plannedhold.
All four v17 runs are now rejected.24 exact raw files,4,836 current-at-run source
hashes per report,two byte-immutable inspections and a scoped baseline/delayed
comparison are preserved in [Classic failure evidence](../art/performance/realism-2026-10-26/network-candidate-seventeen/failed-classic-runs/README.md).
Complete service records,both wait lists and traffic bytes match within this
Classic failed prefix only. All-location96/127,116/127,118/127,126/127 and
station65/87,82/87,83/87,86/87 both failunder30/45 gates. M063 arrivesALLP06:17:38.50,
withoutdeparture:2,516s opposingL006 occupation+186s crossing. L006 waits2,436s
beforeALLP preservingMAKM crossing capacity forM009/S029 andALLP forL013/M063.
ActualALLPclaimsL013P1/M063P3/incomingL006P1P2P3. All11inspectedtrains stopped,
K1exchangespassengers. OneNYYfutureplan hasL021P1received,L022P2received,
L033vacater,escapePASA_P2notyetescaped. No permanent-deadlock/runtime-defect,
recovery orwhole-dayequivalence claim. Inputs remainunchanged pending departure
planning; Network208 remains unaccepted/uninstalled. Originaloutputs retained.

## Candidate eighteen: two departure hypotheses

Candidate eighteen changes only S03004:20→04:50 and L00604:40→04:05.
The later S030 aims to open KZT receiving space for M045 after L002; the earlier
L006 aims to reach ALLP before the observed M063/L013/S029/M009 queue forms.
These are traffic hypotheses, with earlier/later conflicts still possible.
Whole predecessor JSON restoration, every other field unchanged, identical
modes and K1 06:00 are verified. The208 services,168 boundary journeys,
71 overnight origins and3–13 starts/hour remain. All205 overrides reproduce
both packs normally; exact --check and four headless authoring tests pass with
empty stderr. Runtime/tests remain unchanged from the completed1,003-test suite,
which was not rerun. Ten exact proof files are in
[candidate eighteen evidence](../art/performance/realism-2026-10-26/network-candidate-eighteen/README.md).
Network remains unaccepted/uninstalled; all actual full-day gates remain required.

## Candidate eighteen: original replay launch verified

Candidate9559f4f7 is committed/pushed. Four v18 replays launched once at19:51:50:
Classic baseline3816/13752, V2 baseline22532/11016, Classic delayed13112/460,
V2 delayed10336/9808 (wrapper/child). All eight actual commands/options,
exactly one distinct isolated output each, initial baseline modes,4,837 distinct
source fingerprints and six observer hashes are verified. Verification waited
for initial catalogues; no jobs restarted. Five exact launch files and hashes
are archived. Both baselines save genuine snapshots; delayed runs apply600s
manual K1hold at07:30 and can never be installed. Runtime, routes, packs and
six observers are frozen. No suite/native/search/diagnostic/Git job remains.
Partial clocks are not acceptance. Await these original outcomes before edits.

## 19:55:03 v18 checkpoint

At19:55:03 all four original v18 wrapper/child identities match, stderr is
empty and no final audits exist. Both baselines reach01:00 (0/208 complete);
both delayed runs reach01:50 (1/208), before the planned07:30 intervention.
Runtime, routes, packs and six observers remain frozen. No jobs were duplicated
or restarted and no unchanged tests were repeated. These partial runs are not
acceptance; Network208 remains unaccepted and uninstalled. Await the original
outcomes before departure-only repairs. Legacy certifications and pending
Network UI/category work remain preserved.

## 20:05:02 v18 checkpoint

At20:05:02 all four original v18 process identities match, stderr is empty,
and no final audits exist. Both baselines reach03:10 (2/208 complete); Classic
delayed reaches04:20 (7/208), V2 delayed04:10 (6/208), before the planned07:30
hold. Runtime, routes, packs and six observers remain frozen. No duplicate
jobs, restarts, repeated unchanged tests, partial acceptance or installation.
Await the original outcomes; Network208 remains unaccepted and uninstalled.

## 20:15:00 v18 checkpoint

At20:15:00 all four original v18 wrapper/child identities match, stderr is
empty and no final audits exist. Classic/V2 baselines reach04:50 with15/208
and16/208 complete respectively. Classic delayed reaches06:20 (23/208),
V2 delayed06:10 (22/208), before the planned07:30 hold. These are partial runs,
not acceptance or proof of improvement. Runtime, routes, packs and six observers
remain frozen. No duplicates, restarts, unchanged test repeats or installations.
Await the original outcomes; Network208 remains unaccepted and uninstalled.

## v18 Classic delayed failure before intervention

The original v18 Classic delayed run13112/460 ended naturally and failed
S030 at PASA-N1 06:35:52,23/208 complete,2,702s extra wait,zero safety and empty
stderr. It ended before the planned07:30hold, so no actual intervention or
recovery occurred.13 exact raw files,4,836 current source hashes and a byte-
immutable inspection are preserved in [Classic delayed failure evidence](../art/performance/realism-2026-10-26/network-candidate-eighteen/failed-classic-delayed/README.md).
All-location77/106,97/106,103/106,105/106 failsunder30/45. Station-only
51/70,64/70,69/70,70/70 passes only this failed prefix, not the whole day.
S030's wait is1,460s NYY receiving,1,216s opposing M077/S027/M079 occupation
and26s conflicts. NYY claims L034P1/M079P2;L034 waits for NEM's L033/L021.
Several trains move; no future plans remain. No permanent-deadlock/runtime-
defect claim. Both baselines and V2 delayed remain pending; inputs/observers
stay frozen. Network208 remains unaccepted and uninstalled.

## v18 Classic baseline failure and progress assessment

The original v18 Classic baseline3816/13752 also ended naturally and failed
S030 at PASA-N1 06:35:52 without a manual hold:23/208 complete,2,702s maximum
extra wait,1,912s station maximum,zero safety,empty stderr.14 exact raw files,
4,836 current-at-run source hashes and an immutable inspection are preserved
in [Classic baseline failure evidence](../art/performance/realism-2026-10-26/network-candidate-eighteen/failed-classic-baseline/README.md).
Classic baseline/delayed full service records,both wait lists and traffic bytes
match only these failed prefixes before intervention. Both fail all-location
under30/45; station-only targets pass only the prefix. No recovery certificate,
whole-day equivalence or permanent-deadlock/runtime-defect claim. Both original
V2 runs remain live at20:27:12:baseline06:40 (25/208),delayed08:40 (37/208),
identities match,empty stderr,no final audit. Inputs remain frozen.

The user asked whether this is solvable, whether progress is real, and for an
ETA. A feasible208-service day within all wait gates is still unproven. Local
M045/L006 improvements coexist with a Classic S030 failure; no steady whole-day
improvement or reliable completion ETA is claimed. Await both V2 outcomes, then
coordinate opposing departure groups across connected single-line sections
using actual queues rather than continuing isolated one-train fixes. Preserve
all non-departure fields, identical modes, K1 and every acceptance gate.

## v18 V2 delayed failure after intervention

The original v18 V2 delayed run10336/9808 finished naturally and failed V001
at MAKM-S3 09:30:08 after the600s K1hold:47/208complete,2,702s extra wait,
2,454s station maximum,zero safety,empty stderr.13 exact raw files and4,836
current-at-run sources are preserved in [V2 delayed failure evidence](../art/performance/realism-2026-10-26/network-candidate-eighteen/failed-predictive-delayed/README.md).
All-location137/197,178/197,190/197,196/197 failsunder10/30/45; station-only
75/119,105/119,114/119,119/119 failsunder10/20/30. These are failed prefixes;
137/197 is below70%, never rounded up. V001's failed wait is1,254s opposing,
1,150s receiving,184s blocks,114s conflicts. Immutable inspection: ALLPclaims
S006P1/S009P2/L002P3,no futureplans,several trains move. No permanent-deadlock
or runtime-defect inference. K1 minute samples brake27.4546m by07:31 then
remain unchanged through07:40; sampled extents are not exact controllerframes.
No recovery/full-day certificate or installation. The original V2 baseline
22532/11016 remains running,08:10 (33/208) at20:36:16,matching identity,empty
stderr,no audit. Inputs remain frozen until its outcome; then coordinate
opposing departure groups using actual queues. Legacy readiness is unchanged.

## Final v18 baseline failure

The final original v18 V2 baseline22532/11016 has finished naturally and
failed M013 at SRTL08:46:28,37/208complete,2,702s maximum extra wait in both
populations,zero safety,empty stderr,without a manual hold.13 exact raw files,
4,836 current-at-run source hashes and a byte-immutable inspection are in
[V2 baseline failure evidence](../art/performance/realism-2026-10-26/network-candidate-eighteen/failed-predictive-baseline/README.md).
All119/169,154/169,162/169,168/169 failsunder30/45; station66/103,93/103,
100/103,102/103 failsunder10/30/45. M013 arrives SRTL07:59:29.75 with no
departure;2,634s opposing M044/M064,66s receiving and2s V001pass. ActualSRTL
claimsM013P1 and incomingM044/M064/V001P1P2P3;approaching trains protect
compatible roads,M006/M008 await onward crossing atMAKM,S009 awaitsSRTL.
K1,L002,L007,S030move;no futureplans,no permanentdeadlock/runtimebugclaim.
All four original v18 runs have now failed. No acceptance/install/recovery
certificate or unchanged rerun. Next: coordinate opposing departure groups
across connected single lines from actual queues, preserving non-departure
fields,identical modes,K1 and all gates. Legacy readiness remains complete.

## Network208 scope narrowed to V2; candidate nineteen

The user removed Classic dispatcher work from Network208. Readiness now
requires only V2 baseline and V2 disturbed validation; legacy Classic choices
stay certified and available. No Classic Network replay/native/install is
required. Candidate19 narrows the unlaunched14-timing draft to seven V2-focused
departures:V00107:20->08:30,S00908:10->08:40,M01307:20->08:50,M01708:15->09:10,
M01108:35->09:25,S01309:10->10:20,M01909:15->10:35. These coordinate the later
southbound group across KUMM/TUVR/SRTL/MAKM/ALLP using both completed V2 queues.
The seven Classic-only draft edits were restored before launch; that draft
is preserved locally and was never committed or replayed. Actual sampled
full-rake envelopes are planning inputs, not future-capacity proof. All other
pack fields, identical authored services,K106:00,runtime/routes/observers and
approved sounds remain unchanged.208services168boundary71overnight3–13hour.
Normal authoring/exact reproduction/four headless authoring guards pass with
empty stderr; prior1,003-source suite unchanged,not rerun. Eleven exact raw
proofs are in [candidate19 evidence](../art/performance/realism-2026-10-26/network-candidate-nineteen/README.md).
Network208 remains unaccepted/uninstalled. Next launch only two V2 replays
once in isolatedv19outputs, then freeze inputs and require every existing gate.

## Candidate19 two-job launch

Candidate9192c022 is committed/pushed. Exactly two V2 replays launched once
at20:56:38:baseline9132/15716 anddelayed7124/15688 (wrapper/child). All four
actual commands/options,distinct single outputs,predictive baseline mode,
4,836 source fingerprints and six observer hashes were verified after the
initial catalogue appeared. Five exact launch files and their manifest are
preserved in candidate19 evidence. No restart or Classic Network launch.
At20:56:58 baseline is starting and delayed00:10,identities match,empty stderr,
no final audit. Baseline saves genuine snapshots; delayed applies600s manual
K1hold at07:30 and can never be installed. Runtime/routes/packs/six observers
are frozen. Await these original outcomes; no pending suite/native/search/
diagnostic/Git job remains. Network208V2 is not accepted or installed. Classic
Network readiness is explicitly out of scope; legacy Classic remains intact.

## 21:01:08 v19 V2 checkpoint

At21:01:08 both original v19 V2 wrapper/child identities still match,
stderr is empty and no final audits exist. Baseline reaches01:30 and delayed
02:10 (1/208 each), before the planned07:30 intervention. Runtime/routes/
packs/six observers remain frozen. No duplicate or Classic208 jobs,restarts,
unchanged test repeats,partial acceptance or installation. Await the original
outcomes; Network208V2 remains unaccepted/uninstalled. Legacy readiness and
pending NetworkV2 UI/category work remain preserved.

## 21:14:58 v19 V2 checkpoint

At 21:14:58 both original v19 V2 wrapper/child identities still match,
stderr is empty and no final audits exist. The baseline reaches 04:10
(6/208 complete); the delayed run reaches 05:30 (17/208), before its planned
07:30 intervention. These are partial clocks, not acceptance or full-day
improvement evidence. Runtime, routes, packs and six observers remain frozen.
No duplicate or Classic Network jobs, restarts, repeated unchanged tests,
partial acceptance or installation. Await both original outcomes before any
departure changes. Network208V2 remains unaccepted and uninstalled; legacy
readiness and pending NetworkV2 UI/category work remain preserved.

## 21:21:07 v19 V2 checkpoint

At 21:21:07 both original v19 V2 wrapper/child identities still match,
stderr is empty and no final audits exist. The baseline reaches 05:10
(16/208 complete); the delayed run reaches 06:30 (25/208), before its planned
07:30 intervention. Partial clocks do not certify the complete day. Runtime,
routes, packs and six observers remain frozen. No duplicate or Classic
Network jobs, restarts, repeated unchanged tests, acceptance or installation.
Await both original outcomes before departure changes. Network208V2 remains
unaccepted and uninstalled; legacy readiness and pending NetworkV2 UI/category
work remain preserved.

## 21:31:02 v19 V2 checkpoint

At 21:31:02 both original v19 V2 wrapper/child identities still match,
stderr is empty and no final audits exist. The baseline reaches 06:40
(25/208 complete); the delayed run reaches 08:30 (36/208), beyond its configured
07:30-07:40 intervention window. Its final disturbance and recovery audit is
still pending. Partial clocks and maximum waits do not certify the complete
day. Runtime, routes, packs and six observers remain frozen. No duplicate or
Classic Network jobs, restarts, repeated unchanged tests, acceptance or
installation. Await both original outcomes before departure changes.
Network208V2 remains unaccepted and uninstalled; legacy readiness and pending
NetworkV2 UI/category work remain preserved.

## 21:41:02 v19 V2 checkpoint

At 21:41:02 both original v19 V2 wrapper/child identities still match,
stderr is empty and no final audits exist. The baseline reaches 08:00
(33/208 complete); the delayed run reaches 10:30 (57/208). Its disturbance
and recovery audit is still pending. These partial results do not establish
complete-day improvement or acceptance. Runtime, routes, packs and six
observers remain frozen. No duplicate or Classic Network jobs, restarts,
repeated unchanged tests, acceptance or installation. Await both original
outcomes before departure changes. Network208V2 remains unaccepted and
uninstalled; legacy readiness and pending NetworkV2 UI/category work remain
preserved.

## Candidate19 V2 results

Both original v19 V2 runs have finished naturally and failed the 45-minute
wait gate: baseline M008 at TUVR-N3 09:52:28,51/208; delayed S047 at NYY-S1
11:06:08,60/208. Both maximum all-location waits are2702s,zero safety,empty
stderr. Baseline all-location135/191,173/191,186/191,190/191 failsunder30/45;
station74/116,104/116,114/116,116/116 failsunder10/20. Delayedall181/255,
235/255,247/255,254/255 failsunder30/45;station88/135,121/135,129/135,135/135
failsunder10/20/30. Passing fractions certify only failed prefixes.
M008wait1628s opposing northern group,564receiving,354crossing,96blocks,
60conflicts;S047wait2072opposing southern group,592receiving/onward,38conflicts.
Two immutable inspections show several moving trains and no future plans;
no permanent-deadlock/runtime-defect inference.23 exact raw files and4836
current-at-run source hashes per report are preserved in
[v19 V2 failure evidence](../art/performance/realism-2026-10-26/network-candidate-nineteen/failed-predictive-runs/README.md).
K1 delayed minute samples show27.4546m braking then unchanged extents through
07:40;not exact controller frames or recovery certification. No installation
or complete-population comparison. Both original jobs are finished; next
coordinate departure groups from these actual queues, retaining every gate,
K1, all non-departure fields and V2-only scope.

## Candidate20 departure-group hypothesis

Candidate20 changes twelve departures from19 to coordinate northern batches
and the southern opposing flow. M017/M011/S031 become10:00/10:10/10:20;
M051/M023/S013/M019/S011/M049/M065/M053 become11:05/11:15/11:25/11:35/11:45/
11:55/12:05/12:15;S047 becomes08:50. Actual19queues and sampled full-rake
section envelopes motivate intended gaps forM008/S006 thenL002/S008, and
S047 joining the earlier southern group. Future gaps/receiving capacity and
whole-day improvement remain unproven. Restoring these departures recovers
both entire predecessor objects; every other field,common-author service
consistency,K106:00,runtime/routes/observers/sounds remain unchanged.
208services168boundary71overnight3-13starts/hour. Normal reproduction and all
four headless authoring guards pass,emptystderr; unchanged1003suite notrerun.
Eleven raw proofs are in [candidate20 evidence](../art/performance/realism-2026-10-26/network-candidate-twenty/README.md).
V2-only readiness remains unaccepted/uninstalled. Next launch exactly two
V2 replays once, then freeze inputs through their actual outcomes.

## Candidate20 V2 launch

Candidate7d7f91ea is committed/pushed. Exactly two original V2 replays have
launched once in isolatedv20outputs: baseline20044/380 anddelayed4108/21748
(wrapper/child). All four actual commands/options, one distinct output per
job, initial predictive baseline mode,4,836 source fingerprints and six
observer hashes are verified. Five exact launch files and their manifest
are in candidate20 evidence. At22:02:04 baseline is starting and delayed
00:30; both identities match,emptystderr,no final audits. No job restarted
and no Classic Network job launched. Baseline saves genuine snapshots;
delayed uses600s manual K1hold at27000/07:30 and must never be installed.
Runtime/routes/packs/six observers remain frozen through these original
outcomes. No suite/native/search/diagnostic/Git job remains. Network208V2 is
unaccepted/uninstalled; all legacy readiness and unrelated work are preserved.

## Candidate20 checkpoint — 22:10

At 22:10:04, both original candidate20 V2 jobs remain live with verified
process identities: baseline 20044/380 reaches 02:20 (1/208 complete), and
delayed 4108/21748 reaches 03:20 (2/208). Both error logs are empty and
neither final audit exists. These are partial clocks, not acceptance or
recovery results. No jobs were restarted or added; runtime, routes, packs
and all six observers remain frozen. Network208V2 remains unaccepted and
uninstalled. Await both original outcomes before departure-only replanning.

## Candidate20 checkpoint — 22:16

At 22:16:14, both original candidate20 V2 jobs remain live with verified
process identities: baseline 20044/380 reaches 03:40 (2/208 complete), and
delayed 4108/21748 reaches 04:50 (16/208). Both error logs are empty and
neither final audit exists. These are partial clocks, not acceptance or
recovery results. No jobs were restarted or added; runtime, routes, packs
and all six observers remain frozen. Network208V2 remains unaccepted and
uninstalled. Await both original outcomes before departure-only replanning.

## Candidate20 checkpoint — 22:26

At 22:26:06, both original candidate20 V2 jobs remain live with verified
process identities: baseline 20044/380 reaches 05:30 (17/208 complete), and
delayed 4108/21748 reaches 06:50 (26/208). Both error logs are empty and
neither final audit exists. These are partial clocks, not acceptance or
recovery results. No jobs were restarted or added; runtime, routes, packs
and all six observers remain frozen. Network208V2 remains unaccepted and
uninstalled. Await both original outcomes before departure-only replanning.

## Candidate20 checkpoint — 22:36

At 22:36:05, both original candidate20 V2 jobs remain live with verified
process identities: baseline 20044/380 reaches 07:20 (29/208 complete), and
delayed 4108/21748 reaches 09:40 (50/208). Both error logs are empty and
neither final audit exists. These are partial clocks, not acceptance or
recovery results. No jobs were restarted or added; runtime, routes, packs
and all six observers remain frozen. Network208V2 remains unaccepted and
uninstalled. Await both original outcomes before departure-only replanning.

## Candidate20 checkpoint — 22:46

At 22:46:04, both original candidate20 V2 jobs remain live with verified
process identities: baseline 20044/380 reaches 09:30 (48/208 complete), and
delayed 4108/21748 reaches 12:10 (66/208). Both error logs are empty and
neither final audit exists. These are partial clocks, not acceptance or
recovery results. No jobs were restarted or added; runtime, routes, packs
and all six observers remain frozen. Network208V2 remains unaccepted and
uninstalled. Await both original outcomes before departure-only replanning.

## Candidate20 original V2 delayed failure

The original candidate20 V2 delayed run 4108/21748 finished naturally and
failed L008 at Turavur, 12:47:48, with 69/208 complete and 2,702 seconds of
extra wait in both populations. Zero safety events; empty run/inspection errors.
All-location fractions 229/308, 277/308, 296/308, 307/308 fail under20/30/45;
station-only 113/166, 146/166, 159/166, 165/166 fail all four gates.
277/308 is below90%; do not round up. Every fraction covers only this failed
prefix. L008's wait is 2,626s opposing S011/M049/M065/M053/S007, 52s receiving,
12s blocks and12s conflicts. Immutable inspection shows connected TUVR/SRTL/
MAKM receiving queues, KUMM claim M015 P1, M011/M017 moving and no future plans.
No permanent-deadlock or runtime-defect conclusion. Thirteen exact raw files,
4,836 verified current-at-run source hashes, lossless audit/traffic/failure,
exact pack and immutable inspection are preserved in
[candidate20 delayed evidence](../art/performance/realism-2026-10-26/network-candidate-twenty/failed-predictive-delayed/README.md).
K1 minute samples brake27.4545764399m by07:31 then retain extents through07:40;
samples are not exact controller frames or recovery proof. No installation,
acceptance or complete-population comparison. The original baseline20044/380
remains running (11:30,63/208 at22:56:02), empty errors and no final audit.
Keep runtime/routes/packs/six observers frozen until its original outcome.

## Candidate20 original V2 baseline failure

Both original candidate20 V2 runs are now finished and rejected. The baseline
20044/380 failed K1 at NEM at11:52:24,65/208 complete,2,702s in both wait
populations,zero safety,empty errors and no manual hold. All-location
198/272,246/272,264/272,271/272 fails under30/45; station-only
101/151,134/151,148/151,150/151 fails under10/20/45. Passing fractions apply
only to this failed prefix. K1 arrivedNEM11:06:17.70 with no departure;
1,990s opposingM084/L024/M048/M068/S050,630s receiving/onward protection,
22s crossing and60s conflicts. Immutable inspection: NYY claims L036P2 and
incomingM096P1; L036 awaitsM096's overtake. Several trains move, no future
plans; no permanent-deadlock/runtime-defect conclusion. Thirteen exact raw
files and4,836 current-at-run source hashes are preserved in
[candidate20 baseline evidence](../art/performance/realism-2026-10-26/network-candidate-twenty/failed-predictive-baseline/README.md).
The delayed L008 failure is preserved in89ddee21. Both results extend beyond
candidate19's failure points, but neither provides whole-day acceptance or
recovery. No installation or complete-population comparison. Next coordinate
the actual northern and southern opposing queues; preserveK1 and every gate.

## Candidate21 departure-group hypothesis

Candidate21 changes twelve departures from20 after both original V2 failures
were preserved (91fdba59 baseline,89ddee21 delayed). Northern S011/M049/M065/
M053/S007/M015/S015/M021 become12:45/12:55/13:05/13:15/13:25/13:35/13:45/13:55,
aiming for an L008 crossing interval afterM019. Southern L036/M068/M096/S050
become10:20/10:30/10:40/10:50, aiming for a K1 receiving interval afterL024/M048.
Actual20 queues and sampled full-rake section envelopes support these timing
hypotheses, not guaranteed clearance, assigned roads or capacity proof. Later
queues and the disturbedK1 wait may worsen. All actual gates remain required.
Restoring12departures recovers both entire predecessor objects; common service
records,all non-departure fields andK106:00 remain unchanged.208services,
168boundary journeys,71overnight origins,3–12starts/hour.205overrides reproduce
both packs normally; exact --check and four headless authoring guards pass,
empty stderr. Unchanged1003-test runtime suite was not rerun. Eleven rawproofs
are in [candidate21 evidence](../art/performance/realism-2026-10-26/network-candidate-twenty-one/README.md).
Network208V2 remains unaccepted/uninstalled. Next launch only two V2 runs
once in isolatedv21, then freeze inputs through their original outcomes.

## Candidate21 V2 launch

Candidate74637eef is committed/pushed. Exactly two original V2 replays
launched once at23:09:51 in isolatedv21: baseline26756/20168 and delayed
20296/14748 (wrapper/child). All four actual commands/options, one distinct
output each, initial predictive baseline mode,4,836 source fingerprints and
six observer hashes are verified. Five exact launch files and their manifest
are in candidate21 evidence. At23:10:26 baseline is starting and delayed
00:30; identities match,empty errors,no final audits. Initial catalogue wait
only; no job restarted and no Classic208 job launched. Baseline saves genuine
snapshots; delayed uses600s manual K1hold at27000/07:30 and must never be
installed. Freeze runtime/routes/packs/six observers through these original
outcomes. No suite/native/search/diagnostic/Git job remains. Network208V2 is
unaccepted/uninstalled; all completed legacy readiness is preserved.

## Candidate21 checkpoint — 23:17

At 23:17:23, both original candidate21 V2 jobs remain live with matching
process identities: baseline 26756/20168 reaches 02:10 (1/208 complete), and
delayed 20296/14748 reaches 03:10 (2/208). Both error logs are empty and
neither final audit exists. These are partial clocks, not acceptance or
recovery results. No jobs were restarted or added; runtime, routes, packs
and all six observers remain frozen. Network208V2 remains unaccepted and
uninstalled. Await both original outcomes before departure-only replanning.
No gameplay change or new playtest is available at this checkpoint.

## Candidate21 checkpoint — 23:27

At 23:27:07, both original candidate21 V2 jobs remain live with matching
process identities: baseline 26756/20168 reaches 04:00 (5/208 complete), and
delayed 20296/14748 reaches 05:20 (16/208). Both error logs are empty and
neither final audit exists. These are partial clocks, not acceptance or
recovery results. No jobs were restarted or added; runtime, routes, packs
and all six observers remain frozen. Network208V2 remains unaccepted and
uninstalled. Await both original outcomes before departure-only replanning.
No gameplay change or new playtest is available at this checkpoint.

## Candidate21 checkpoint — 23:37

At 23:37:09, both original candidate21 V2 jobs remain live with matching
process identities: baseline 26756/20168 reaches 05:40 (18/208 complete), and
delayed 20296/14748 reaches 07:10 (28/208). Both error logs are empty and
neither final audit exists. These are partial clocks, not acceptance or
recovery results. No jobs were restarted or added; runtime, routes, packs
and all six observers remain frozen. Network208V2 remains unaccepted and
uninstalled. Await both original outcomes before departure-only replanning.
No gameplay change or new playtest is available at this checkpoint.

## Candidate21 checkpoint — 23:47

At 23:47:08, both original candidate21 V2 jobs remain live with matching
process identities: baseline 26756/20168 reaches 07:10 (28/208 complete), and
delayed 20296/14748 reaches 09:20 (45/208). Both error logs are empty and
neither final audit exists. These are partial clocks, not acceptance or
recovery results. No jobs were restarted or added; runtime, routes, packs
and all six observers remain frozen. Network208V2 remains unaccepted and
uninstalled. Await both original outcomes before departure-only replanning.
No gameplay change or new playtest is available at this checkpoint.

## Candidate21 checkpoint — 23:57

At 23:57:09, both original candidate21 V2 jobs remain live with matching
process identities: baseline 26756/20168 reaches 08:40 (37/208 complete), and
delayed 20296/14748 reaches 11:30 (64/208). Both error logs are empty and
neither final audit exists. These are partial clocks, not acceptance or
recovery results. No jobs were restarted or added; runtime, routes, packs
and all six observers remain frozen. Network208V2 remains unaccepted and
uninstalled. Await both original outcomes before departure-only replanning.
No gameplay change or new playtest is available at this checkpoint.

## Candidate21 original V2 delayed failure — 27 October

The original candidate21 V2 delayed run 20296/14748 finished naturally and
failed L026 at Parassala, 12:25:14, with 68/208 complete, 2,702s maximum extra
wait in both populations, zero safety events and empty errors. All-location
194/263,237/263,252/263,262/263 fails under30/45; station-only
106/157,138/157,150/157,156/157 fails all four gates. Fractions cover only this
failed prefix. L026 arrived11:38:56.85 with no departure:970s NYY approach
reservation forM086,916s overtakes,622s receiving/onward,130s blocks,64s conflicts.
Immutable inspection shows NYY claims L025P1/M086P2; several trains move.
Two actual future plans are preserved: ALLP M014/M023/vacaterS010 toMAKM_P1
(received/opponent_received true,escaped false), and NYY M086/L025/vacaterM096
toNEM_P1 (received/escaped true,opponent_received false). No permanent-deadlock
or runtime-defect inference. L008 now leaves TUVR12:02:50.75 and KUMM12:22:34.25;
this local improvement is not whole-day progress, and this run fails earlier
elsewhere. Thirteen exact raw files and4,836 current-at-run source hashes are in
[candidate21 delayed evidence](../art/performance/realism-2026-10-26/network-candidate-twenty-one/failed-predictive-delayed/README.md).
K1 minute samples show27.4545764399m braking then unchanged extents through07:40;
not exact controller frames or recovery proof. No installation or complete-
population comparison. The original baseline26756/20168 remains running
(10:40,59/208 at00:07:06 on27October), empty errors and no final audit.
Inputs remain frozen pending its original outcome. Network208V2 is unaccepted.

## 27 October 00:22 — candidate21 baseline rejected

Candidate21's original V2 baseline26756/20168 has now failed naturally at
11:52:24: K1 atNEM,65/208 complete,2702s maximum in both wait populations,
zero safety,empty errors,no manual hold. All-location182/251,225/251,243/251,
250/251 fails under20/30/45; station102/150,133/150,147/150,149/150 fails
under10/20/45. 225/251 remains below90%. K1NEM arrival11:06:17.70 has no
departure:1638s opposing,994s receiving/onward,22s crossing,48s conflicts.
Immutable snapshot has NYY L036P2/incomingS050 P1/P2 alternatives; M096,
S050,L024,S034,L008 move, and no future plans exist. No permanent-deadlock
or runtime-defect inference. Both21 runs are now rejected; no live owned
jobs remain. Evidence in network-candidate-twenty-one/failed-predictive-baseline
preserves13 exact raw files and4836 current-at-run source hashes. Original
outputs remain; no rerun,installation,full-population comparison or recovery
certificate. Prior1003 tests and four authoring guards remain applicable;
no unchanged tests rerun. Next departure-only grouping must address both
actual southern queues. Network208V2 readiness remains unproven.

## 27 October — candidate22 southern group hypothesis

Candidate22 changes only15 southern departures from21: M06810:50,M09611:00,
S05011:10,M08611:20,L03611:35,L02611:45,S03412:45,M06612:55,M10213:05,
S04813:20,M08213:40,M05414:00,S05214:20,M05214:40,S05415:00. Faster trains
precede the two locals, with a longer intended interval before the following
wave. Actual21 baseline NEM/NYY and delayed PASA/NYY queues and sampled
full-rake envelopes inform this hypothesis; no guaranteed gap/assigned road,
capacity proof or whole-day improvement. Later queues and delayed K1 may worsen.
Whole predecessor restoration proves all other fields unchanged; K1 remains
06:00,common services identical,208 total,168 boundary,71 overnight,3–12/hour.
Normal author/exact reproduction and four headless guards pass,empty errors;
205 overrides. Runtime/tests unchanged from1003-test suite; no unchanged
suite rerun. Eleven exact raw proofs in network-candidate-twenty-two. Next
commit/push and exactly two new isolatedV2 replays; no Classic208 job or
readiness requirement. Network208V2 remains unaccepted/uninstalled.

## 27 October 00:29 — verified V2 v22 launch

Candidate6d6f0518 committed/pushed; exactly two original V2 v22 replays
launched once at2026-10-27T00:28:56.3993166+08:00: baseline2360/13668 and delayed7952/19620
(wrapper/child). All four actual commands/options,distinct isolated outputs,
initial predictive baseline mode,4836 source hashes and six observer hashes
verified. Five exact launch files and manifest preserved. At00:29:16 baseline
is starting,delayed00:10,identities match,empty errors,no final audits. No
restart/duplicate/Classic208 job. Baseline uses snapshots; delayed uses600s
manual K1hold at27000/07:30. Runtime/routes/packs/six observers now frozen.
Partial clocks are not acceptance; Network208V2 unaccepted/uninstalled.
No suite/native/search/diagnostic/Git job remains after this checkpoint.

## 27 October 00:32 — original v22 jobs continue

27 October 00:32:06 checkpoint: both original v22 V2 jobs remain active
with matching wrapper/child identities. Baseline2360/13668 is at01:00
(0/208 complete); delayed7952/19620 is at01:50 (1/208). Both error logs
are empty and neither final audit exists. These partial clocks are not
acceptance. Runtime/routes/packs/six observers remain frozen; no duplicate,
restart,Classic208 job,unchanged test rerun or installation. Pending UI/category
helpers and unrelated files are preserved. Await the original outcomes.

## 27 October 00:42 — original v22 jobs continue

27 October 00:42:04 checkpoint: both original v22 V2 identities match.
Baseline2360/13668 is at03:20 (2/208 complete); delayed7952/19620 is at04:20
(7/208). Both error logs are empty and no final audits exist. Partial clocks
are not acceptance. Frozen inputs, original jobs, pending helpers and unrelated
files are preserved; no duplicate/restart/Classic208 job, unchanged tests or
installation. Await the original baseline and disturbed outcomes.

## 27 October 00:52 — original v22 jobs continue

27 October 00:52:01 checkpoint: both original v22 V2 jobs remain active
with matching identities. Baseline2360/13668 is at05:00 (16/208 complete);
delayed7952/19620 is at06:20 (23/208), still before its configured intervention.
Both error logs are empty and no final audits exist. Partial clocks/waits
are not acceptance. Frozen inputs, original jobs, pending helpers and unrelated
files are preserved. No duplicate/restart/Classic208 job, unchanged test rerun
or installation. Await original outcomes before any departure replanning.

## 27 October 01:02 — original v22 jobs continue

27 October 01:02:01 checkpoint: both original v22 V2 identities match.
Baseline2360/13668 is at06:30 (25/208 complete); delayed7952/19620 is at08:20
(34/208), past its configured hold window; final disturbance/recovery proof
remains pending. Both error logs are empty and no final audits exist. Partial
clocks/waits are not acceptance. Frozen inputs, original jobs, pending helpers
and unrelated files are preserved; no duplicate/restart/Classic208 job,
unchanged tests or installation. Await original outcomes before replanning.

## 27 October 01:12 — original v22 jobs continue

27 October 01:12:03 checkpoint: both original v22 V2 identities match.
Baseline2360/13668 is at08:10 (33/208 complete); delayed7952/19620 is at10:50
(60/208). Both error logs are empty and no final audits exist. Partial clocks
and wait maxima are not acceptance or recovery proof. Runtime/routes/packs/
six observers remain frozen. Original jobs, pending helpers and unrelated
files are preserved; no duplicate/restart/Classic208 job, unchanged tests
or installation. Await original outcomes before departure replanning.

## 27 October 01:27 — original v22 delayed run rejected

Candidate22 original V2 delayed7952/19620 finished naturally and failed L025
at NYY12:42:12:70/208 complete,2702s in both wait populations,zero safety,
empty run/inspection errors after the configured600s K1hold at07:30.
Thirteen exact raw files,4836 verified current-at-run source hashes,lossless
reports/traffic/failure,exact pack,actual summary and byte-immutable inspection
are preserved in network-candidate-twenty-two/failed-predictive-delayed.
All-location193/260,234/260,250/260,259/260 fails under30/45;station106/155,
136/155,148/155,154/155 fails all four gates.234/260 is exactly90%;passing
fractions apply only to this failed prefix. No whole-population comparison,
recovery certificate or installation; never rerun this unchanged failure.

L025 arrived NYY11:55:56.65 with no departure:2076s opposingM096/S050/M086/L036,
556s receiving/onward,34s escape-approach clearance,36s conflicts. NYY claims
L025P1,L036P2,incomingK1P1/P2 alternatives,not simultaneous reservations.
One actual NYY future plan:incomingK1P1,opponentL036P2,vacaterL025,escapePASA_P2;
received/opponent_received/escaped all false. L036 exchanges passengers atAMVA;
L026PASA waits for L025's protected escape. K1,M048,M068,M086,M096,S010 move;
L008 and S050 are depot-stored. No permanent-deadlock/runtime-defect inference.
K1 leftTVC11:52:15.75 and NEM12:41:53.25. These are local observations only.
Eleven K1 minute samples preserve27.4545764399m braking then unchanged extents
through07:40,not exact controller frames or recovery proof. Original baseline
2360/13668 remains running at inspection;all inputs frozen until its outcome.
No Classic208 job,unchanged tests,duplicate,restart or installation. Pending
UI/category helpers,original outputs and unrelated files remain preserved.

At01:27:25 the original baseline2360/13668 identity matches,at11:00
(61/208 complete),empty errors and no final audit. This remains partial.

## 27 October 01:32 — original v22 baseline continues

27 October 01:32:03 checkpoint: original v22 V2 baseline2360/13668 remains
active with matching identity,at11:50 (65/208 complete),empty errors and no
final audit. Delayed failure evidence remains committed/pushed511eb04a.
Baseline clocks are partial; no acceptance or recovery claim. Runtime/routes/
packs/six observers remain frozen until its original outcome. No duplicate,
restart,Classic208 job,unchanged test rerun or installation. Pending helpers,
original outputs and unrelated files are preserved.

## 27 October 01:45 — original v22 baseline rejected

Both original candidate22 V2 runs are now naturally finished and rejected.
Baseline2360/13668 failedL025NYY12:42:04,69/208,2702s both populations,zero
safety,empty errors,no manualhold. Thirteen exact raw files,4836 verified
current-at-run source hashes,lossless reports/traffic/failure,exact pack and
immutable inspection are preserved in network-candidate-twenty-two/failed-predictive-baseline.
All197/272,245/272,263/272,271/272 failsunder30/45;station110/163,144/163,
159/163,162/163 failsALL.159/163<98%;passingfractions applyonlyfailedprefix.
L025arrNYY11:55:48.15nodep:1708s opposingM096/S050/M086,954sPASAreceiving,
40sconflicts. NYYclaimsM086P1/L025P2;L036justarrPASA,L026KZTawaitsK1.
No futureplans inbaseline. K1/L008/L024/M068/M096move,M086exchanges;
M048awaitsblock,S010ALLPawaitsM019/M023,S050depot,S034awaitsdeparture.
K1depNEM11:20:44.25/NYY11:52:28.75/PASA12:41:23.25. Localmovementonly,
notwhole-dayimprovement. BaselinesummaryhasnoK1overtakes inprefix.
No permanentdeadlock/runtime-defect claim,populationcomparison,recoveryproof
orinstallation. Delayed evidence511eb04a remains distinct. No existingjobs
remain;departure-only group replanning can now use bothactualV2queues.

## 27 October — candidate23 departure groups

Candidate23 changes only13 southern departures from22: M06811:35,M09611:45,
S05011:55,M08612:05,L03612:20,L02612:30,S04813:25,M08213:35,S03413:45,
M06613:55,M10214:05,M05414:20,S05214:30. The six-service first wave moves45m
later,aiming for K1/L025 southbound full-rake clearance afterL024/M048;following
fast group starts55originminutes afterL026. Actual22 queues and sampled
full-rake envelopes inform this hypothesis,not guaranteed gaps/assignedroads.
Later locals/opposing queues may worsen;no newmodelscore/full-dayclaim.

Normal authoring and exact--check reproduce both packs from205overrides;
all4headlessguards pass,empty errors. Restoring13departures recovers entire
predecessorJSON objects,common208services identical,K106:00,40local/104mail/
56superfast/8VB,71overnight,3–13starts/hour. Runtime/routes/tests/sixobservers
unchanged;completed1003suite notrerun.11exactrawproofs preserved;exact22
predecessors in candidate-twenty-three-before. Initial uncommitted/unlaunched
draft failed local14-start-hour guard;exactdraft retained in candidate-twenty-three-draft-density-rejected.
Following group revised before final passing checks. Network208V2 remains
unaccepted/uninstalled. Commit/push then one V2baseline and one600s07:30
K1delayed run inisolatedv23. NoClassic208 work;pendinghelpers preserved.

## 27 October 01:50 — verified original V2 v23 launch

Candidate87de4c8a committed/pushed; exactly two original V2 v23 replays
launched once at2026-10-27T01:50:35.8812222+08:00: baseline8580/19068,
delayed832/10968 (wrapper/child). Four actualcommands/options,distinctoutputs,
initialpredictivebaselinemode,4836sourcehashes and sixobserverhashes verified.
Five exactlaunchfiles/hashmanifest preserved. At01:50:51 baseline starting,
delayed00:10;identitiesmatch,emptyerrors,nofinalaudits. No restart,duplicate
orClassic208 job. Baselineuses snapshots;delayed600smanualK1hold07:30.
Runtime/routes/packs/sixobservers frozen. Partialclocksnotacceptance;
Network208V2unaccepted/uninstalled. No suite/native/search/diagnostic job
remains. PendingUI/categoryhelpers and unrelatedfiles preserved.

## 27 October 01:53 — original v23 jobs continue

27 October 01:53:07 checkpoint: both original v23 V2 identities match.
Baseline8580/19068 is at00:50 (0/208 complete); delayed832/10968 is at01:30
(1/208),before its configured intervention. Both error logs are empty and
neither final audit exists. Partial clocks/waits are not acceptance. Frozen
inputs,original jobs,pending helpers and unrelated files are preserved;
no duplicate,restart,Classic208 job,unchanged tests or installation.

## 27 October 02:05 — original v23 jobs continue

27 October 02:05:32 checkpoint: both original v23 V2 process identities match.
Baseline 8580/19068 has reached 03:40 (2/208 complete); delayed 832/10968
has reached 04:50 (16/208), before its configured 07:30 intervention.
Both error logs are empty; neither final audit exists. These partial results
are not acceptance. Runtime, routes, source packs and all six observers remain
frozen. The original jobs continue without duplicates or restarts. Network208V2
remains unaccepted and uninstalled; no Classic208 work or unchanged checks ran.

## 27 October 02:13 — original v23 jobs continue

27 October 02:13:05 checkpoint: the original v23 V2 baseline 8580/19068
has reached 04:50 (16/208 complete); delayed 832/10968 has reached 06:20
(23/208), before the configured 07:30 hold. Both identities match, both error
logs are empty and neither final audit exists. These are partial runs, not
acceptance. All frozen inputs and original processes are preserved. No new
replay, Classic208 work, unchanged tests or installation was performed.

## 27 October 02:23 — original v23 jobs continue

27 October 02:23:01 checkpoint: original v23 V2 baseline 8580/19068 has
reached 06:20 (23/208 complete); delayed 832/10968 has reached 08:20 (34/208).
The delayed log includes 07:30 and 07:40, but its partial clock is not a recovery
certificate. Both process identities match, error logs remain empty and neither
final audit exists. Runtime, routes, packs and six observers remain frozen.
No duplicate, restart, Classic208 job, unchanged checks or installation occurred.
Network208V2 remains unaccepted; await the original runs' actual final reports.

## 27 October 02:33 — original v23 jobs continue

27 October 02:33:05 checkpoint: original v23 V2 baseline 8580/19068 has
reached 08:00 (33/208 complete); delayed 832/10968 has reached 10:40 (59/208).
Both process identities match, both error logs are empty and neither final audit
exists. Partial clocks and wait maxima do not establish acceptance or recovery.
The original jobs continue with runtime, routes, packs and six observers frozen.
No duplicate, restart, Classic208 work, unchanged tests or installation occurred.
Network208V2 remains unaccepted and uninstalled pending the actual final reports.

## 27 October 02:43 — original v23 jobs continue

27 October 02:43:03 checkpoint: original v23 V2 baseline 8580/19068 has
reached 09:30 (48/208 complete); delayed 832/10968 has reached 12:50 (69/208).
Both process identities match, both error logs are empty and neither final audit
exists. The delayed clock is beyond candidate22's failure time, but this partial
run is not a complete-population improvement or recovery certificate. Runtime,
routes, packs and six observers remain frozen. No duplicate, restart, Classic208
work, unchanged tests or installation occurred. Network208V2 remains unaccepted.

## 27 October 02:53 — original v23 delayed failure preserved

Candidate23 original V2 delayed832/10968 finished naturally and was rejected:
M019 at ALLP13:26:44,71/208 complete,2702s maximum in both wait populations,
zero safety events and empty errors after the configured600s K1hold07:30.
All-location196/275,244/275,266/275,274/275 fails under20/30/45; station-only
104/158,138/158,152/158,157/158 fails all four gates. These are failed prefixes.
M019arrALLP12:36:22.45 has no departure:1014s S013overtake,746s opposing
M018/S016,708s AMPAreceiving,170s blocks,64s conflicts. Two byte-immutable
inspections retain no future-clearance plans; final AMPAclaimsM050P3/incoming
M028P2. M019/M101 await moving S016; M050 awaits ALLPreceiving forM101/M019.
Several trains move; no permanent-deadlock or runtime-defect inference.
L025 is in its NCJdepot; K1leftNJT13:24:57.25 and approachesNCJ. These local
movements beyond the earlier southern blockage are not whole-day improvement.
Sixteen exact raw files and4836 current-at-run sources are verified in
network-candidate-twenty-three/failed-predictive-delayed. Eleven K1minute
samples preserve braking then unchanged extents through07:40, not exact
controller frames or recovery proof. Summary has one V001overpass ofK1 atTVCN,
not completed multiple-location evidence. No comparison,certificate or install.
At02:53:02 the original baseline8580/19068 remains live at11:40 (64/208),
identitymatching,emptyerrors,no finalaudit. Keep all inputs frozen until it ends;
never rerun unchangedv23. Pending helpers and unrelated files are preserved.

## 27 October 03:03 — original v23 baseline continues

27 October 03:03:03 checkpoint: the original v23 V2 baseline 8580/19068
remains active at13:30 (73/208 complete), with matching identity, empty error
log and no final audit. Its partial clock beyond the delayed failure does not
establish whole-day success. The original delayed failure is preserved in
7c47e1bf and was not rerun. Runtime, routes, packs and six observers remain
frozen until the baseline ends. No duplicate, Classic208 work, unchanged tests
or installation occurred; Network208V2 remains unaccepted and uninstalled.

## 27 October 03:13 — both original v23 runs rejected

Candidate23 original V2 baseline8580/19068 finished naturally and failed
M028 at ALLP14:38:34:81/208 complete,2702s maximum in both wait populations,
zero safety events and empty run/final-inspection errors, without manual hold.
All-location244/348,308/348,332/348,347/348 fails under20/30/45; station-only
122/190,165/190,182/190,189/190 fails all four gates. Every fraction is a failed
prefix. M028arrALLP13:51:31.85 has no departure:1512s opposingM065/M049,
1014s receiving/onward protection,86s blocks,90s conflicts. Two byte-immutable
inspections have no future plans; MAKM claimsM053P3/incomingM015P1/P2/P3,
ALLPclaimsM028P1 plus incomingM016/M065/S012 alternative roads. M028 awaits
M065; M065/M053/S012 protect ALLP receiving capacity, M016 awaits its block.
Several trains move; no permanent-deadlock/runtime-defect inference.
K1 and L025 are in NCJdepot, arrivals12:46:12.65/13:14:56.65. M019 has left
VAK14:29:22.75. Local movement is not whole-day improvement or recovery.
Baseline summary has no K1overtakes. Fifteen exact raw files and4836 source
fingerprints verified in network-candidate-twenty-three/failed-predictive-baseline;
first inspection has a combined log, final inspection has separate empty stderr.
Both original23 runs are finished and rejected; delayed evidence7c47e1bf
remains preserved. No duplicate/restart,Classic208 job,unchanged tests,
complete-population comparison,installation or certificate. Network208V2 is
unaccepted. Replan departure groups only after preserving this baseline proof.

## 27 October — candidate24 northern groups authored

Candidate24 changes13 northern departures from23: S01311:25->10:55,
M05111:05->11:10,M02311:15->11:25,M01911:35->11:40,S00713:25->12:55,
S01513:45->13:05,M04912:55->13:25,M06513:05->13:35,M05313:15->13:45,
M01513:35->13:55,M02113:55->14:05,S03314:10->15:00,M02514:45->15:05.
Hypothesis: faster S013 before the first mail group; unchanged S01112:45 then
S007/S015 ahead of the next mail group, with S033/M025 together later. Uses
actual23 M019 overtake/AMPA receiving waits and M028 opposing/MAKM receiving
waits; origin spacing is not a guaranteed physical gap. Opposing waits and
later local/V003 interactions may worsen. No isolated-model or whole-day claim.
Southern23 timings unchanged. Restoring13 departures recovers both complete
predecessor JSON objects; every other field unchanged, identical common-author
services,K1=06:00,208services,168boundary journeys,71overnight,3–12/hour.
205 overrides reproduce both packs normally; exact --check and all four headless
authoring guards pass with empty errors. Eleven exact raw proofs retained in
network-candidate-twenty-four. Actual23 sampled envelopes retain hashes and
censoring, not live clearance/receiving certificates. Runtime/tests/observers
unchanged; no unchanged1003-test suite rerun. Both23 failures preserved in
cceb1bca/7c47e1bf, source hashes now historical. Commit/push before one V2
baseline plus one delayed run in new isolatedv24 outputs. No Classic208 work,
acceptance,comparison,installation or recovery certificate. Pending helpers
and unrelated files remain untouched.

## 27 October 03:24 — original v24 V2 launch verified

Candidate24 c71d550c committed/pushed. Exactly two original V2 v24 replays
launched once at2026-10-27T03:24:05.1420854+08:00: baseline11988/12204,
delayed14452/4928 (wrapper/child). Four actual commands/options, unique outputs,
initial predictive baseline mode,4836 source fingerprints and six observer
hashes verified; five exact launch files/hash manifest retained. At03:24:18
baseline starting,delayed00:10; both identities match,empty errors,no final
audits. Baseline uses --network --snapshots; delayed uses --network --delay=600
--delay-at=27000. No duplicate,restart or Classic208 job. Freeze runtime/routes/
packs/six observers throughout either run. No suite/native/search/diagnostic
job remains. Partial clocks are not acceptance. Network208V2 remains unaccepted
and uninstalled. Pending UI/category helpers and unrelated files preserved.

## 27 October03:27 — original v24 runs continue

27 October03:27:52 checkpoint: original v24 V2 baseline11988/12204 reaches
01:10 (0/208 complete); delayed14452/4928 reaches02:00 (1/208). Both process
identities match, error logs are empty and neither final audit exists. These
partial clocks are not acceptance. Inputs remain frozen; no duplicate,restart,
Classic208 work,unchanged tests or installation. Network208V2 remains
unaccepted/uninstalled. Continue checking these original jobs for final audits.

## 27 October03:37 — original v24 runs continue

27 October03:37:31 checkpoint: original v24 V2 baseline11988/12204 reaches
03:20 (2/208 complete); delayed14452/4928 reaches04:20 (7/208). Both process
identities match, error logs are empty and neither final audit exists. Runtime,
routes,packs and six observers remain frozen. No duplicate,restart,Classic208
work,unchanged tests or installation. These partial clocks do not establish
acceptance; continue checking the original jobs. Network208V2 remains unaccepted.

## 27 October03:47 — original v24 runs continue

27 October03:47:39 checkpoint: original v24 V2 baseline11988/12204 reaches
05:00 (16/208 complete); delayed14452/4928 reaches06:30 (25/208). Both process
identities match, error logs are empty and neither final audit exists. Keep
runtime/routes/packs/six observers frozen until both original outcomes. Partial
clocks and waits do not certify acceptance. No duplicate,restart,Classic208
work,unchanged tests or installation; Network208V2 remains unaccepted.

## 27 October 04:00 — original v24 runs continue

27 October 04:00:18 checkpoint: the original v24 V2 baseline (11988/12204)
reaches 07:00 with 27/208 services complete; the delayed run (14452/4928)
reaches 09:00 with 42/208 complete. Both process identities match, error logs
are empty and neither final audit exists. The V2 pack and all six observer
hashes still match the launch records. Keep runtime, routes, packs and observers
frozen until both original outcomes. These partial results do not certify
acceptance. Network208V2 remains unaccepted and uninstalled; no gameplay or
playtest change, duplicate run, Classic208 work or unchanged test rerun.

## 27 October 04:07 — original v24 runs continue

27 October 04:07:31 checkpoint: original v24 V2 baseline (11988/12204)
reaches 08:00 with 33/208 services complete; delayed (14452/4928) reaches
10:50 with 60/208 complete. Both original process identities match, error logs
are empty and neither final audit exists. Runtime, routes, packs and six
observers remain frozen until both original outcomes. These partial results
do not establish acceptance. Network208V2 remains unaccepted and uninstalled.
No gameplay change or new playtest; continue checking the original runs.

## 27 October 04:17 — original v24 runs continue

27 October 04:17:32 checkpoint: original v24 V2 baseline (11988/12204)
reaches 09:40 with 49/208 services complete; delayed (14452/4928) reaches
12:50 with 69/208 complete. Both original process identities match, error logs
are empty and neither final audit exists. Runtime, routes, packs and six
observers remain frozen until both original outcomes. These partial results
do not establish acceptance. Network208V2 remains unaccepted and uninstalled.
No gameplay change or new playtest; continue checking the original runs.

## 27 October 04:27 — original v24 runs continue

27 October 04:27:32 checkpoint: original v24 V2 baseline (11988/12204)
reaches 11:20 with 61/208 services complete; delayed (14452/4928) reaches
14:30 with 83/208 complete. Both original process identities match, error logs
are empty and neither final audit exists. Runtime, routes, packs and six
observers remain frozen until both original outcomes. Partial progress beyond
an earlier failure clock is not a whole-day improvement or recovery certificate.
Network208V2 remains unaccepted and uninstalled. No gameplay change or new
playtest; continue checking the original runs.

## 27 October 04:39 — candidate 24 delayed failure preserved

27 October 04:39:35: original v24 delayed 14452/4928 finished naturally and
failed M050 at TUVR-N3 at 14:43:20: 84/208 complete, maximum all-location wait
2702 seconds, station-only maximum 2454 seconds, zero safety events and empty
run/inspection errors. Candidate24 c71d550c remains unaccepted/uninstalled.
Seventeen exact raw evidence files, 4836 verified current-at-run source hashes,
the actual summary and two byte-immutable inspections are preserved under
`network-candidate-twenty-four/failed-predictive-delayed`. Original outputs remain.
All-location cumulative counts 239/334,294/334,324/334,333/334 fail the 20/30/45
minute gates; station counts 121/183,159/183,178/183,183/183 fail 10/20/30.
Passing fractions apply only to this failed prefix; never round failures up.

M050 left SRTL at 13:48:55.25; the failed signal wait comprises 2100 seconds
opposing M049/M065/M053 (730/696/674), 546 receiving, 26 blocks and 30 conflicts.
Actual KUMM claims are M021 P1/M015 P2; both await TUVR capacity for S016/M050.
Actual TUVR claims are S016 P2/M050 P3/approaching M053 P1. M050/S016 await
M053 in KUMM_single; M028 at SRTL also waits for TUVR capacity. M049 waits at
MAKM for S012. M053/M065/M019/S007/S011/S012/S015 move; both inspections have
no future plans and byte-identical captures. No permanent-deadlock or runtime-defect inference. M019 now leaves ALLP 13:03:17.75 and VAK 14:35:31.75;
K1/L025 are in NCJ depot (passenger arrivals 13:31:09.15/13:11:10.65). These
local observations do not prove whole-day improvement or recovery. One V001
pass of K1 at TVCN is a prefix observation. Eleven K1 minute samples brake
27.4545764399 metres by 07:31, then preserve extents through 07:40; they are
not exact controller frames or a recovery certificate.

The original baseline 11988/12204 still runs: 13:40, 74/208 complete, matching
identities, empty errors and no final audit at 04:39:35. Keep runtime, routes,
packs and six observers frozen until its outcome; then use both actual queues
for coordinated departure-only planning. No duplicate/restart, Classic208 run,
installation, complete-population comparison or unchanged test rerun. Gameplay
is unchanged; no new playtest is requested. Source hashes are current for24
and must become historical after a later candidate changes source.

## 27 October 04:47 — candidate 24 baseline failure preserved

27 October 04:47:34: the original v24 baseline 11988/12204 finished naturally
and failed S032 at TUVR-N2 at 14:13:50: 78/208 complete, maximum all-location
wait 2702 seconds, station-only 2458 seconds, zero safety events, no manual
hold and empty run/summary/inspection errors. Both original candidate24 V2
runs are now finished and rejected. Seventeen exact raw files, 4836 verified
current-at-run source fingerprints, the actual summary and two byte-immutable
inspections are preserved in `network-candidate-twenty-four/failed-predictive-baseline`.
Original outputs remain; never rerun unchanged or install either failed run.

All-location cumulative counts 228/320,288/320,310/320,319/320 fail the 30/45
minute gates (288/320 is exactly 90%). Station counts 115/177,158/177,174/177,
177/177 fail 10/20. Every passing fraction applies only to this failed prefix.
S032 left ALLP at 13:02:10.75 after arrival 12:51:07.25; its next booked call
is ERS, so the failure is a signal wait, not a booked Turavur call. The failed
wait comprises 2686 seconds opposing traffic and 16 seconds route conflict
with M065. Opposing buckets include S007/S015/M049/M065/M053/M015; combined
reason buckets are preserved without attributing their seconds to individuals.

Actual KUMM claims are incoming M021 P1/P2/P3 alternatives. Actual TUVR claims
are S032 P2, approaching M053 P3 and incoming M015 P1/P2/P3 alternatives;
these alternatives are not simultaneous reservations. S032 awaits M015/M053
in KUMM_single; M018 at SRTL awaits M065; M050/S016 at MAKM await S007;
M028 at ALLP awaits S015/S007. S012 at AMPA protects M028's onward crossing.
M015/M053/M021/M065/M019/S007/S011/S013/S015 move, M049 exchanges passengers,
and K1/L025 are already in NCJ depot. Both inspections have no future plans
and byte-identical captures. No permanent-deadlock or runtime-defect inference.
The baseline summary records no K1 overtake. Local movements do not establish
whole-day improvement or recovery; no complete-population comparison is made.

All original v24 jobs have ended, permitting coordinated departure-only planning
from both actual queues. Source hashes are current for24 and become historical
once a later candidate changes source. Runtime9ec3530, sound/gangways/portals,
legacy certifications and pending UI/category files remain unchanged. No
Classic208 job, installation or unchanged full-suite rerun. Network208V2
remains unaccepted; 208 feasibility within all gates and completion ETA remain
unproven. Gameplay is unchanged; no new playtest is requested.

## 27 October — candidate25 opposing departure groups

Candidate25 changes only nine departures from candidate24:
M049 13:25->14:15, M065 13:35->14:30, M053 13:45->15:00,
M015 13:55->15:15, M021 14:05->15:30, S033 15:00->16:00,
M025 15:05->16:05, L003 15:10->16:20, L009 16:00->17:00.
Earlier candidate24 fast-group timings and candidate23 southern timings remain.
K1 stays06:00; restoring these departures recovers each whole predecessor JSON
object. Every non-departure field and both common-author service arrays match.

Both original24 V2 runs are rejected and preserved: baseline dc5eaf49,
delayed7c3076a4,17 exact raw files and4836 source fingerprints each, two
immutable inspections each. Their source hashes are now historical after25;
never relabel or rerun them. Baseline S032 failsTUVR-N2 at14:13:50,78/208;
delayed M050 failsTUVR-N3 at14:43:20,84/208. Each has2702-second maximum
all-location wait and zero safety events. These are failed prefixes, not a
complete-population comparison or whole-day improvement/recovery proof.

The hypothesis is to leave an origin gap after S01513:05 for the observed
northbound S032/M018/M050/S016 group, then run M049/M065 at14:15/14:30 and
M053/M015/M021 at15:00/15:15/15:30. The30 origin minutes between M065/M053
aim to interrupt repeated southbound occupancy. All five mails move, including
M015/M021 whose actual24 delayed claims occupied KUMM receiving roads.
Baseline S032 waited2686s opposing traffic; delayed M050 waited2100s opposing
M049/M065/M053 and546s for compatible receiving. Actual24 KUMM axis envelopes
end13:42:38 for baselineS015 and13:36:46 for delayedS007; M049 overlaps from
13:40:50/14:04:50 respectively. Those observations motivate the changed groups,
but do not predict exact crossing order or guarantee legal full-tail clearance.

S033/M025 move to16:00/16:05; L003 moves behind them to16:20 and L009 to17:00.
V00315:50, S01716:35 and L01116:45 stay unchanged. Later opposing traffic,
local waits and fast overtakes may worsen; these interactions are unproven.
Origin gaps are not compatible receiving roads, full-tail clearance, protected
escape or a full-day capacity certificate. No isolated-model score is claimed.

`sampled-groups.json` retains actual24 traffic from10:30 to each failure,
continuous full-rake axis-envelope overlaps, static bounds, exact source hashes,
sample intervals (maximum about2s), censoring and the overlap formula. The
ALLP-AMPA envelope retains the station-center/half-width+200m exclusion basis.
The sampling script is retained. These are geometric planning inputs, not exact
interlocking ownership, assigned receiving roads or guaranteed future gaps.

Normal authoring and exact --check reproduce both packs from205 overrides.
All four headless authoring guards pass with empty errors. There are208 services
(40local,104mail,56superfast,8VB),168 boundary journeys,71 overnight origins
and3-13 starts/hour. Twelve exact raw proof files have byte lengths/SHA-256;
exact predecessors remain in candidate-twenty-five-before. Runtime9ec3530,
routes/tests/six observers, sound/gangways/portals and certified legacy choices
are unchanged. The completed1003-test suite still applies; no unchanged rerun.
Common-author consistency does not certify Classic208 readiness.

Commit/push before launching exactly one V2 baseline with snapshots and one
V2 delayed run (600s K1 hold07:30) in new isolatedv25 outputs. All208 services,
all calls/departures/full-tail completions, zero safety, both cumulative wait
populations, actual multiple-location overtakes and disturbance recovery remain
required. Network208V2 remains unaccepted/uninstalled. No Classic208 job/check.
Pending UI/category helpers and unrelated files remain outside this work. No
installed gameplay change or new playtest; native NetworkV2 checks follow only
accepted installation. Feasibility and completion ETA remain unproven.

## 27 October 04:56 — original v25 V2 runs launched and verified

Candidate25 2dd2b9f8 committed/pushed. Exactly two original V2 runs launched
once at2026-10-27T04:56:13.0519617+08:00: baseline wrapper13108/child11232,
delayed wrapper22180/child19280, new isolated rehearsals-v25 outputs.
Baseline uses --network --snapshots; delayed --network --delay=600
--delay-at=27000. All four actual commands/options, unique outputs, initial
predictive baseline mode,4836 source fingerprints and six observer hashes
verified. Five exact launch files/hash manifest retained. The first read-only
verification attempt preceded creation of the initial catalogue; it stopped
without restarting either run. Verification succeeded once the original
baseline wrote its catalogue. At04:56:53 baseline00:10/delayed00:30, matching
identities, empty errors and no final audits. Partial clocks are not acceptance.

Freeze runtime/routes/packs/six observers while either original run lives.
Do not rerun launch-network-v25.ps1, duplicate or restart. No Classic208 job,
suite/native/search/diagnostic job remains. Both original24 runs are finished
and rejected; their fingerprints remain historical. Network208V2 remains
unaccepted/uninstalled; all safety/wait/full-tail/recovery gates remain. Pending
UI/category helpers and unrelated files preserved. No new gameplay playtest.

## 27 October 04:59 — original v25 runs continue

27 October 04:59:05 checkpoint: original v25 V2 baseline13108/11232 reaches
01:00 (0/208 complete); delayed22180/19280 reaches01:40 (1/208). Both process
identities match, error logs are empty and neither final audit exists. The V2
pack and all six observer hashes still match launch. Runtime/routes/packs/
observers remain frozen until both original outcomes. Partial clocks are not
acceptance; Network208V2 remains unaccepted/uninstalled. No duplicate/restart,
Classic208 work, unchanged tests or new gameplay playtest. Continue the originals.

## 27 October 05:09 — original v25 runs continue

27 October 05:09:05 checkpoint: original v25 V2 baseline13108/11232 reaches
03:20 (2/208 complete); delayed22180/19280 reaches04:20 (7/208). Both original
process identities match, error logs are empty and neither final audit exists.
Runtime/routes/packs/six observers remain frozen. No duplicate/restart,
Classic208 work, unchanged tests or installation. Partial clocks are not
acceptance; Network208V2 remains unaccepted/uninstalled. No gameplay change or
new playtest; continue checking the original runs for their final outcomes.

## 27 October 05:19 — original v25 runs continue

27 October 05:19:02 checkpoint: original v25 V2 baseline13108/11232 reaches
05:00 (16/208 complete); delayed22180/19280 reaches06:20 (23/208). Both original
process identities match, error logs are empty and neither final audit exists.
Runtime/routes/packs/six observers remain frozen until both original outcomes.
Partial clocks and waits do not establish acceptance. Network208V2 remains
unaccepted/uninstalled. No duplicate/restart, Classic208 work, unchanged tests
or new gameplay playtest; continue checking the original runs.

## 27 October 05:29 — original v25 runs continue

27 October 05:29:05 checkpoint: original v25 V2 baseline13108/11232 reaches
06:30 (25/208 complete); delayed22180/19280 reaches08:20 (34/208). Both original
process identities match, error logs are empty and neither final audit exists.
Runtime/routes/packs/six observers remain frozen until both original outcomes.
Partial clocks and waits do not establish acceptance. Network208V2 remains
unaccepted/uninstalled. No duplicate/restart, Classic208 work, unchanged tests
or new gameplay playtest; continue checking the original runs.

## 27 October 05:39 — original v25 runs continue

27 October 05:39:10 checkpoint: original v25 V2 baseline13108/11232 reaches
08:00 (33/208 complete); delayed22180/19280 reaches10:40 (59/208). Both original
process identities match, error logs are empty and neither final audit exists.
Runtime/routes/packs/six observers remain frozen until both original outcomes.
Partial clocks and waits do not establish acceptance. Network208V2 remains
unaccepted/uninstalled. No duplicate/restart, Classic208 work, unchanged tests
or new gameplay playtest; continue checking the original runs.

## 27 October 05:49 — original v25 runs continue

27 October 05:49:06 checkpoint: original v25 V2 baseline13108/11232 reaches
09:40 (49/208 complete); delayed22180/19280 reaches12:50 (69/208). Both original
process identities match, error logs are empty and neither final audit exists.
The V2 pack and all six observer fingerprints still match launch, using the
launch proof's UTF-8/LF normalization for observer text. Runtime/routes/packs/
observers remain frozen until both original outcomes. Partial clocks and waits
do not establish acceptance; Network208V2 remains unaccepted/uninstalled.
No duplicate/restart, Classic208 work, unchanged tests or new gameplay playtest;
continue checking the original runs.

## 27 October 05:59 — original v25 runs continue

27 October 05:59:03 checkpoint: original v25 V2 baseline13108/11232 reaches
11:20 (61/208 complete); delayed22180/19280 reaches14:30 (84/208). Both original
process identities match, error logs are empty and neither final audit exists.
Runtime/routes/packs/six observers remain frozen until both original outcomes.
Partial clocks and waits do not establish acceptance. Network208V2 remains
unaccepted/uninstalled. No duplicate/restart, Classic208 work, unchanged tests
or new gameplay playtest; continue checking the original runs.

## 27 October 06:09 — original v25 delayed failure

The original v25 V2 delayed run (wrapper22180/child19280) finished naturally
and failed S031 at PASA-S2 at15:15:12:89/208 complete,2702s maximum all-location
wait,2454s station-only,zero safety events and empty run/summary/inspection
errors after the configured600s K1 hold at07:30. Seventeen exact raw files,
4836 verified current-at-run source fingerprints, the actual summary and two
byte-immutable inspections are preserved in
`network-candidate-twenty-five/failed-predictive-delayed`. Original outputs remain;
never rerun unchanged or install this failed run. These source fingerprints are
current for candidate25 and become historical after a later source change.

All-location cumulative counts256/347,315/347,337/347,346/347 fail30/45-minute
gates. Station-only130/188,169/188,182/188,188/188 fail10/20/30;169/188 is below
90%, never round up. Every passing fraction applies only to this failed prefix.
S031 left TVC at13:37:40.75 after arrival13:34:20.90; its next booked call KZT
is unreached. PASA-S2 is a signal wait, not a booked Parassala call.

The failed wait comprises1312s compatible KZT receiving,1244s opposing traffic
(M082406,S03422,M066406,M102406,M0544),98s crossing protection for S034 and48s
route conflicts. Actual KZT claims are M054P1/L028P2; actual PASA claims are
S031P2 and incoming M054P1/P2 alternatives, not simultaneous reservations.
S031 awaits M054 in PASA_single. M054 has authority and is sounding departure
horns with brakes held; L028 awaits its conflicting route. M081NEM waits for
M066; S051NYY waits for M102. M082/S034/M066/M102/M022/M065/M053/M015 move.
M049MAKM awaits M022 crossing, M021 awaits booked departure and S048 is stored.
Both inspections have no future plans and byte-identical captures. No permanent
deadlock or runtime-defect inference follows from this failed wait.

S032/M018/M050/S016 have continued beyond the northern map boundary, with portal
arrival records14:04:43.75/14:19:39.75/14:25:05.30/14:34:29.60 respectively.
K1/L025 are in NCJ depot (passenger arrivals13:31:09.15/13:11:10.65).
These local observations are not whole-day improvement or recovery proof.
Eleven K1 minute samples show27.4545764399m braking movement by07:31 and unchanged
recorded extents through07:40; these are not exact controller frames or a
recovery certificate. The traffic prefix records one V001 overtake of K1 at
TVCN, not completed multiple-location proof. No complete-population comparison.

The original v25 baseline13108/11232 is still running; at06:09:05 it reaches
13:00 with70/208 complete, matching identities, empty errors and no final audit.
Freeze runtime/routes/packs/six observers until its outcome. Await that result
before coordinated departure-only replanning. Network208V2 remains unaccepted
and uninstalled. Runtime9ec3530, approved audio/gangways/portals, certified legacy
choices and pending UI/category files are preserved. No Classic208 job, unchanged
full-suite rerun or new gameplay playtest. Feasibility and completion ETA remain
unproven.

27 October 06:19:06 checkpoint: the original v25 V2 baseline 13108/11232
reaches 14:50 with 86/208 complete, matching process identities, empty errors
and no final audit. The delayed failure remains preserved in 1b5bfcab.
Runtime/routes/packs/six observers remain frozen until the baseline finishes.
Partial progress is not acceptance; Network208V2 remains unaccepted/uninstalled.
No duplicate, restart, Classic208 work, unchanged tests or new gameplay playtest.

## 27 October 06:29 — original v25 baseline failure

The original v25 V2 baseline (wrapper 13108 / child 11232) finished naturally
and failed S031 at PASA-S2 at 15:15:14: 87/208 complete, 2702s maximum
all-location wait, 2458s station-only, zero safety events, no manual hold and
empty run/summary/inspection errors. Twenty exact raw files, 4836 verified
current-at-run source fingerprints, the actual summary and three byte-immutable
inspections are preserved in `network-candidate-twenty-five/failed-predictive-baseline`.
Original outputs remain. Both original v25 runs have now finished and failed;
never rerun unchanged or install either. Their source fingerprints remain
current for candidate25 and become historical after a later source change.

All-location cumulative counts 247/355, 312/355, 338/355, 354/355 fail ALL four
wait gates; 247/355 is below 70%, never round up. Station-only counts 130/198,
175/198, 192/198, 198/198 fail under 10/20/30 minutes. Passing fractions apply
only to this failed prefix. The two-second proximity to the delayed failure
does not establish equality of populations or a whole-day comparison.

S031 left TVC at 13:45:56.75 after arrival 13:38:38.95; its next booked KZT call
is unreached. PASA-S2 is a signal wait, not a booked Parassala call. Its failed
2702s wait comprises 2274s compatible KZT receiving, 406s opposing M082 and 22s
route conflicts with M082/S034. Combined receiving-reason buckets are retained
without attributing them to individual claimants.

Actual KZT claims are M102 P1 / M066 P2; PASA claims M082 P1 / S031 P2; NEM
claims M081 P1 / S051 P2. S031 waits for KZT receiving; M066/M102 wait for PASA
receiving. M082 at PASA protects S034's onward crossing at NYY; S034 at NYY
waits for NEM receiving occupied by M081/S051. M081/S051 at NEM protect PASA
crossing capacity for M082. L028 waits at ERL for KZT receiving; M054 waits
behind L028's occupied ERL block. M022/M049/M065/M053/M015 move, while M021
awaits booked departure and S048 is stored. All three inspections have no future
plans and byte-identical before/after captures. This saved queue does not prove
permanent deadlock or a runtime defect.

S032/M018/M050/S016 have continued beyond the northern map, with portal arrival
records 14:10:35.25 / 14:29:57.75 / 14:53:13.30 / 14:47:48.25 respectively.
K1/L025 are in NCJ depot (passenger arrivals 12:46:12.65 / 13:14:56.65).
These local observations are not whole-day improvement, capacity or recovery
proof. The baseline summary has no K1 overtakes in this failed prefix. No
complete-population comparison, recovery certificate or installation.

Next: coordinated departure-group planning from both actual v25 queues and
full-rake traffic samples. All safety, wait, physical and recovery gates remain;
only departures may change, with K1 fixed. Network208V2 remains unaccepted and
uninstalled. Runtime9ec3530, audio/gangways/portals, certified legacy choices,
R47 and pending UI/category files remain untouched. No Classic208 job, unchanged
full-suite rerun or new gameplay playtest. Feasibility and completion ETA remain
unproven.

## 27 October — candidate26 coordinated southern groups

Candidate TWENTY-SIX changes twelve southern departures from candidate25:

- S034: 13:45 -> 13:35
- M082: 13:35 -> 13:50
- M066: 13:55 -> 14:45
- M102: 14:05 -> 14:55
- M054: 14:20 -> 15:40
- S051: 13:55 -> 14:45
- S049: 14:30 -> 15:05
- M081: 14:10 -> 15:40
- M085: 15:10 -> 16:20
- M087: 15:40 -> 16:35
- M083: 16:25 -> 17:15
- L037: 16:30 -> 17:30

Restoring these twelve departure strings recovers each entire predecessor JSON
object. Every other field is unchanged, both common-author packs retain identical
service records and K1 remains 06:00. Candidate25 northern timings remain unchanged.
There are 208 services (40 local, 104 mail, 56 superfast, 8 VB), 168 boundary journeys,
71 overnight origins and 3-13 starts/hour. All 205 overrides reproduce both packs
normally and under exact --check; all four headless authoring guards pass with
empty errors. Runtime/tests remain unchanged from the completed candidate10
1003-test suite; no unchanged full-suite rerun. Twelve raw proofs, both source-pack
hashes and override JSON are checked after staging. Exact predecessors remain in
.local/realism-2026-10-26/candidate-twenty-six-before. V2 pack SHA-256:
99f96b7a22920f58de52ca4567a354d0e367fe4422f0bf800ea8cf76bfee12bc.

The hypothesis puts S034 ahead of slower M082 at 13:35/13:50, then delays M066,
M102 and M054 to reduce KZT receiving pressure while S031 crosses south. Actual25
baseline S031 accumulated 2274s receiving wait with M066/M102 holding KZT; delayed
S031 accumulated 1312s receiving and 1244s opposing, with M054/L028 claiming KZT.
S048 13:25, S052 14:30, M052 14:40, S054 15:00 and L028 14:20 remain and can still
constrain this interval. The proposed gap between mail origins is not a free-track
or compatible-road guarantee.

The opposing TVC group becomes S051 14:45, S049 15:05, retained V007 15:30, M081
15:40, retained S053 16:10, M085 16:20 and M087 16:35, followed by M083 17:15 and
L037 17:30. In actual25 baseline, M081/S051 fill NEM P1/P2 and block S034's onward
reception, which holds M082 at PASA and the KZT queue. The hypothesis aims to leave
receiving capacity for S034/M082 before this southbound group enters. Actual25
delayed NEM full-rake envelopes S034 14:42:24-14:48:48 and M082 15:01:38-15:08:02
are observations, not predictions for candidate26. Later opposing traffic,
local waits and overtakes can worsen and remain unproven.

sampled-groups.json retains actual25 full-rake axis overlaps from 11:00 to each
failure, continuous intervals, static bounds, formulas, hashes, about two-second
sample spacing and censoring. Southern bounds are retained from candidate23;
ALLP-AMPA uses report centers with half-width plus 200m exclusion. The initial
read-only sampler inherited only northern bounds; it was corrected to include
the retained southern bounds before this plan was authored. No simulation rerun.
These are planning inputs, not interlocking ownership, assigned receiving roads,
guaranteed clearances, escape or full-day capacity proof. No isolated-model score
or whole-day improvement claim.

Both v25 failures are preserved (baseline 7260820d, delayed 1b5bfcab); all their
source fingerprints are now HISTORICAL after candidate26 and must not be relabelled.
Next: commit/push the verified candidate, then launch exactly one new isolated V2
baseline with snapshots and one delayed V2 run with the 600s K1 hold at 07:30.
No Classic208 replay, readiness check or installation is required. All existing
safety/wait/physical/recovery gates remain unchanged. Network208V2 is not accepted
or installed; runtime9ec3530, approved sound, gangways/portals, legacy certification,
R47 and pending UI/category files remain unchanged. No new gameplay playtest until
passing installation. Feasibility and completion ETA remain unproven.

27 October 06:38 — candidate26 V2-only launch verified.

Candidate26 is committed/pushed as 5e7379de. Exactly two original V2 runs were
launched once at 06:37:37: baseline wrapper 3728 / child 12192 in
rehearsals-v26/predictive-network with --network --snapshots; delayed wrapper
16324 / child 14784 in rehearsals-v26/predictive-network-delayed with --network
--delay=600 --delay-at=27000. All four actual commands/options, unique output
folders, initial predictive baseline catalogue, 4836 distinct source hashes and
six observer hashes are verified. Five exact launch files and their raw hash
manifest are preserved in network-candidate-twenty-six. Verification waited for
the original baseline catalogue to exist and succeeded without a failed attempt.

At 06:38:30 the baseline reaches 00:20 and delayed 00:40, matching original
process identities, with empty error logs and no final audits. Partial clocks
are not acceptance. Do not rerun launch-network-v26.ps1, duplicate or restart.
Freeze runtime/routes/packs/six observers while either original run lives.
inspect-current-replays.py now selects v26 first. No Classic208, suite, native,
search or diagnostic job remains. Network208V2 is unaccepted/uninstalled;
continue checking these original runs. No new gameplay playtest.

27 October 06:42 — original v26 runs checkpointed.

At 06:42:21 the original baseline (3728/12192) reaches 01:30, 1/208 complete,
and the original delayed run (16324/14784) reaches 02:20, 1/208 complete.
Both identities match, error logs are empty and neither final audit exists.
The V2 pack and all six observer hashes still match the verified launch.
Only these four owned Godot processes are present; no duplicate or Classic208
job was started. Runtime/routes/packs/observers stay frozen. Partial clocks
are not acceptance; Network208V2 remains unaccepted and uninstalled.
No source change, repeated headless suite or gameplay playtest in this checkpoint.

27 October 06:50 — original v26 runs remain active.

At 06:50:05 the original baseline (3728/12192) reaches 03:20, 2/208 complete,
and the original delayed run (16324/14784) reaches 04:20, 7/208 complete.
Both original command lines and parent/child identities match the launch;
error logs are empty and neither final audit exists. Only the four original
Godot processes are present. The V2 pack and six observer hashes remain unchanged.
Continue these original runs with runtime/routes/packs/observers frozen.
Partial clocks are not acceptance. Network208V2 remains unaccepted/uninstalled;
no duplicate, Classic208, repeated test or native job was launched. No new playtest.

27 October 07:00 — original v26 runs checkpointed.

At 07:00:08 the original baseline (3728/12192) reaches 05:00, 16/208 complete,
and the original delayed run (16324/14784) reaches 06:20, 23/208 complete.
Both retain their original commands and parent/child identities, with empty
error logs and no final audits. The V2 pack and all six observer hashes match
the launch. Only the four original Godot processes are present. Keep these
runs and frozen inputs unchanged; partial clocks and waits are not acceptance.
Network208V2 remains unaccepted/uninstalled. No duplicate, Classic208, suite
or native job was launched; no new gameplay playtest.

27 October 07:10 — original v26 runs remain active.

At 07:10:08 baseline 3728/12192 reaches 06:30 with 25/208 complete; delayed
16324/14784 reaches 08:20 with 34/208 complete. Both retain their original
commands and parent/child identities, empty error logs and no final audits.
Only these four Godot processes are present. The V2 pack and all six observer
hashes still match the launch. Continue the original runs with frozen inputs;
partial clocks do not establish acceptance or disturbance recovery.
Network208V2 remains unaccepted/uninstalled. No duplicate, Classic208, repeated
suite or native job was launched. No new gameplay playtest.

27 October 07:20 — original v26 runs checkpointed.

At 07:20:04 baseline 3728/12192 reaches 08:00 with 33/208 complete; delayed
16324/14784 reaches 10:40 with 59/208 complete. Both retain their original
commands and parent/child identities, empty error logs and no final audits.
Only these four Godot processes are present. The V2 pack and all six observer
hashes still match the verified launch. Continue these original runs with
runtime/routes/packs/observers frozen. Partial clocks and waits are not
acceptance or recovery proof. Network208V2 remains unaccepted/uninstalled.
No new replay, Classic208, suite or native job; no new gameplay playtest.

27 October 07:30 — original v26 runs remain active.

At 07:30:10 baseline 3728/12192 reaches 09:40 with 49/208 complete; delayed
16324/14784 reaches 12:50 with 69/208 complete. Exact launch commands and
parent/child identities still match. Both error logs are empty, neither final
audit exists, and only the four original Godot processes are present. V2 pack
and six observer hashes remain unchanged. Keep runtime/routes/packs/observers
frozen while these original runs continue. These are partial clocks, not
acceptance or recovery proof; Network208V2 remains unaccepted/uninstalled.
No duplicate, Classic208, suite or native job was launched. No new playtest.

27 October 07:42 — original v26 runs remain active.

At 07:42:13 baseline 3728/12192 reaches 11:40 with 64/208 complete; delayed
16324/14784 reaches 15:10 with 90/208 complete. Exact launch commands and
parent/child identities still match. Both error logs are empty, neither final
audit exists, and only the four original Godot processes are present. The V2
pack and six observer hashes remain unchanged. Keep runtime/routes/packs and
observers frozen while these original runs continue. These partial clocks do
not establish acceptance or recovery; Network208V2 remains unaccepted and
uninstalled. No duplicate, Classic208, suite or native job was launched.
No new gameplay playtest.

27 October 07:50 — candidate26 V2 delayed run rejected; baseline still live.

The original delayed run 16324/14784 finished naturally at 16:06:14 after the
configured 600-second K1 hold at 07:30. M051 exceeds the 45-minute wait gate
at its booked Parassala call: 97/208 services complete, maximum all-location
and station-only wait 2702 seconds, zero safety events, empty run/summary/
inspection error logs. Preserve this failed result; never rerun unchanged or
install it. Candidate26 remains unaccepted/uninstalled.

All-location cumulative counts are 286/383, 350/383, 372/383, 382/383,
failing under 30 and 45 minutes. Station-only counts are 143/206, 186/206,
200/206, 205/206, failing under 10, 30 and 45 minutes; 143/206 is below 70%,
never round it up. Passing fractions describe only this failed prefix.
M051 arrives Parassala at 15:18:17.75 and has not departed. This is a booked
station wait, with current signal PASA-S1, unlike S031's prior signal wait.
Its 2702 seconds comprise 1354 opposing (L028 550, M052 398, M066 406),
1312 compatible KZT receiving, and 36 conflicts (12 each for those trains).
The combined receiving reason buckets remain preserved without assigning
all their time to individual claimants.

Actual KZT claims are L004 P2 and approaching M102 P1; PASA claims are M051 P1
and M066 P2. M051 waits for KZT receiving; L004 awaits M102's overtake, while
M102 is moving toward its KZT call. M066 waits for NYY receiving reported
against M052/S051; S051 at NYY waits for both PASA roads. S049 at NEM waits
for opposing M052. S054 at ERL also waits for KZT receiving; M054 waits behind
S054's ERL block. L028, M052, M102 and S034 move; V007/M081 await a clear TVC
origin berth. The initial KZT and final PASA inspections have byte-identical
before/after captures and no future clearance plans. This is not evidence
of permanent deadlock or a runtime defect.

S031 has continued beyond the southern boundary, with NCJ passenger arrival
15:01:47.90 and portal arrival 15:07:22.80. M082 is in TVC depot storage after
arrival 15:23:28.35. K1/L025 are in NCJ depot with passenger arrivals
13:31:09.15 / 13:11:10.65. These are local observations, not whole-day
improvement, capacity or recovery proof. Eleven K1 minute samples show
27.4545764399 m braking by 07:31, then unchanged recorded extents through
07:40; these samples are not exact controller frames or a recovery certificate.
The actual final-report traffic summary records one V001 overtake of K1 at
TVCN, not completed multiple-location proof. No complete-population comparison.

Evidence: art/performance/realism-2026-10-26/network-candidate-twenty-six/
failed-predictive-delayed. Seventeen exact raw files preserve lossless audit,
traffic, failure snapshot, exact V2 pack, actual summary and both immutable
inspections. All 4836 source hashes and the pack hash match current-at-run
candidate26; preserve their provenance when any later candidate changes sources.
Original outputs remain. Runtime/tests and all frozen source inputs are unchanged;
no repeated suite, Classic208 run or native check was needed for this evidence.

At 07:50:06 the original baseline 3728/12192 is still live at 12:50, 69/208,
with empty stderr and no final audit. Its exact command and parent identities,
the V2 pack and all six observer hashes still match the launch. Only those two
original Godot processes remain after the completed inspections. Keep all frozen
inputs unchanged until the baseline finishes; then plan coordinated opposing
groups using both actual queues, compatible roads and full-tail clearance.
No new gameplay playtest is ready.

27 October 08:00 — original v26 baseline remains active.

At 08:00:11 baseline 3728/12192 reaches 14:40 with 84/208 complete, empty
stderr and no final audit. The two original process identities, exact commands,
V2 pack and six observer hashes still match the launch. Continue this original
baseline with frozen inputs. Its partial clock is not acceptance. The delayed
M051/Parassala failure remains rejected and preserved in da75521d; no unchanged
rerun or installation. Network208V2 remains unaccepted/uninstalled. No duplicate,
Classic208, suite, native or diagnostic job was launched. No new gameplay playtest.

27 October 08:10 — both original candidate26 V2 runs rejected.

The original baseline 3728/12192 finished naturally at 15:42:26 without an
intervention: M082 exceeds 45 minutes at its booked Neyyattinkara call,
91/208 complete, maximum 2702 seconds in both wait populations, zero safety
events and empty run/summary/inspection errors. All-location counts
258/370, 328/370, 356/370, 369/370 fail all four gates; 258/370 is below 70%.
Station-only 140/209, 186/209, 203/209, 208/209 also fail all four gates.
Every passing fraction is only a failed-prefix result; no full comparison.

M082 arrives NYY at 14:53:06.25 and has not departed; current signal NYY-N1.
The 2702-second station wait comprises 2218 seconds of compatible NEM
receiving, 472 opposing M051 and 12 route conflicts with M051. Preserve the
combined receiving buckets without assigning them to individual claimants.
Actual NEM claims are S051 P1/S049 P2; NYY claims M082 P1/M051 P2; KZT claims
L028 P1/M052 P2. M082 waits for NEM; S051/S049 wait for NYY. M051 protects KZT
crossing capacity for L028/M052; both northbound trains protect NYY crossing
capacity for M051. M066 waits at ERL for KZT receiving; L004 waits behind
M066's ERL block, M102 behind L004 and S054 behind M102. M054 and S034 move;
V007/M081 await a clear TVC origin berth. The NEM, KZT and final NYY inspections
all have byte-identical before/after captures and no future clearance plans.
No permanent-deadlock or runtime-defect inference follows from this snapshot.

S031 has continued beyond the southern boundary, with NCJ passenger arrival
14:54:47.50 and portal arrival 15:00:22.30. K1/L025 are in NCJ depot storage,
with passenger arrivals 12:46:12.65 / 13:14:56.65. The baseline traffic summary
has no K1 overtakes in its prefix. Local progress is not whole-day improvement,
capacity or recovery proof. Both original v26 results are rejected; never rerun
unchanged, install them or compare them as complete populations.

Baseline evidence is in network-candidate-twenty-six/failed-predictive-baseline:
20 exact staged raw files, 4836 verified current-at-run sources, lossless audit/
traffic/failure, exact V2 pack, actual summary and three immutable inspections.
Delayed evidence remains in da75521d with 17 raw files and two inspections.
Original outputs remain. Both processes have ended; no live replay, suite,
native or diagnostic remains. Preserve candidate26 source provenance as
historical once a later departure-only candidate changes it. Network208V2 is
unaccepted/uninstalled. Runtime/tests remain unchanged; no repeated full suite
or Classic208 work. Next: coordinated departure groups from both actual queues
and full-rake samples, retaining every physical and wait gate. No new playtest.

27 October 08:20 — candidate27 authored; V2 tests pending launch.

Candidate TWENTY-SEVEN changes thirteen southern departures from candidate26:

- S051: 14:45 -> 15:40
- S049: 15:05 -> 16:10
- M081: 15:40 -> 17:10
- M085: 16:20 -> 17:30
- M087: 16:35 -> 18:00
- M083: 17:15 -> 19:00
- L037: 17:30 -> 19:20
- S054: 15:00 -> 15:20
- M052: 14:40 -> 15:35
- M066: 14:45 -> 15:45
- M102: 14:55 -> 16:00
- M054: 15:40 -> 17:00
- L028: 14:20 -> 17:20

Restoring these departure strings recovers each entire predecessor JSON object.
Every other field is unchanged; both common-author packs retain identical service
records and K1 remains 06:00. Northern departure groups remain unchanged. There
are 208 services (40 local, 104 mail, 56 superfast, 8 VB), 168 boundary journeys,
71 overnight origins and 3-13 starts/hour. All 205 overrides reproduce both packs
normally and under exact --check. All four headless authoring guards pass, with
empty errors. Runtime/tests are unchanged from the completed candidate10
1003-test suite; no unchanged full-suite rerun. Twelve raw proofs, both pack
hashes and override JSON are verified after staging. Exact predecessors remain
in .local/realism-2026-10-26/candidate-twenty-seven-before. V2 pack SHA-256:
ccd57ce978ce77335291c58ebf721fbf8e7ae64176edbf1824aace00ab9fad76.

The hypothesis delays S051/S049 until 15:40/16:10, retaining V007 15:30 and S053
16:10, then moves M081/M085/M087 to 17:10/17:30/18:00 and M083/L037 to 19:00/19:20.
Actual26 baseline S051/S049 occupy both NEM roads while M082/M051 occupy both NYY
roads; M082 waits 2218s for compatible NEM receiving. Actual26 delayed M082's NEM
full-rake envelope is 15:08:22-15:14:46 and its TVC envelope is 15:15:40-15:21:22.
The later opposing group aims to leave NEM receiving capacity for M082. These
observations are not candidate27 predictions or guaranteed clearance windows.

The northbound group becomes S054 15:20, M052 15:35, M066 15:45, M102 16:00,
M054 17:00 and L028 17:20. Actual26 baseline L028/M052 occupy both KZT roads and
protect M051's NYY crossing. Delayed M051 waits 1354s opposing L028/M052/M066 and
1312s for compatible KZT receiving, eventually against L004/approaching M102.
Retain S052 14:30 and L004 14:55; moving M102 farther behind L004 aims to reduce
its overtake hold. Retained L004 and later S036 16:10, M070 16:30, M072 16:55,
S038 17:10, L030 17:25 and L038 17:35 may still constrain receiving and opposing
traffic. Later local waits, overtakes and origin queues remain unproven.

sampled-groups.json retains actual26 full-rake axis overlaps from 11:00 to each
failure, continuous intervals, static bounds, formulas, source hashes, about
two-second sampling and censoring. Southern bounds are retained from candidate23;
ALLP-AMPA uses report centers with half-width plus 200m exclusion. These are
planning inputs, not interlocking ownership, assigned roads, guaranteed gaps,
full-tail escape or full-day capacity proof. No isolated-model score or whole-day
improvement claim. Origin-hour arithmetic alone does not establish capacity.

Both v26 failures remain preserved: baseline cc621f55 (20 raw files, three immutable
inspections), delayed da75521d (17 raw files, two inspections), 4836 current-at-run
source hashes each. Their fingerprints are HISTORICAL after candidate27; never
relabel, rerun unchanged or install either failed result. Original outputs remain.
Next: commit/push this verified candidate, then launch exactly one new isolated V2
baseline with snapshots and one V2 delayed run with the 600s K1 hold at 07:30.
No Classic208 replay or readiness requirement. Every safety, physical, wait and
recovery gate remains unchanged. Network208V2 is unaccepted/uninstalled. Runtime,
approved sound, gangways/portals, certified legacy choices, R47 and pending
UI/category files are unchanged. No new gameplay playtest until passing
installation. Feasibility and completion ETA remain unproven.

27 October 08:22 — candidate27 V2 launch verified, inputs frozen.

Candidate899a8292 was committed/pushed after exact author reproduction, all four
headless authoring guards and staged-byte verification. Exactly two new V2 runs
were launched once at 08:21:22 in rehearsals-v27: baseline wrapper11952/child20024
with --network --snapshots, and delayed wrapper20640/child27164 with --network
--delay=600 --delay-at=27000. All four actual commands/options, unique outputs,
the original predictive baseline catalogue, 4836 distinct source hashes and six
observer hashes are verified. Verification waited for the original catalogue
and succeeded without a failed attempt or restart. Five exact launch files plus
their hash manifest are preserved in network-candidate-twenty-seven.

At 08:21:51 the baseline has no first progress line yet; delayed reaches 00:20.
Both original process pairs match; errors are empty and neither final audit
exists. These partial clocks do not establish acceptance. Freeze runtime, routes,
packs and all six observers while either original run lives. No duplicate,
Classic208, full suite, native, search or diagnostic job was launched. Source
suite remains the completed 1003-test candidate10 result; four authoring guards
cover this departure-only change. Both v26 failures remain rejected and their
source fingerprints are historical. Network208V2 is unaccepted/uninstalled.
Next: inspect these original final reports against every completion, safety,
wait, physical and recovery gate. No new gameplay playtest until installation.

27 October 08:25 — original v27 replays remain active.

At 08:25:14 the original baseline 11952/20024 reaches 01:20 with 0/208
complete; delayed 20640/27164 reaches 02:00 with 1/208 complete. Both have
empty errors and no final audit. All four original identities and commands,
V2 pack and six observer hashes still match. Keep inputs frozen and inspect
these original final reports when ready; partial clocks are not acceptance.
Network208V2 remains unaccepted/uninstalled. No duplicate, Classic208, repeated
suite, native or diagnostic job was launched. No new gameplay playtest.

27 October 08:35 — original v27 replays remain active.

At 08:35:18 baseline 11952/20024 reaches 03:30 with 2/208 complete; delayed
20640/27164 reaches 04:30 with 10/208 complete. Both original pairs and exact
commands match, errors are empty and neither final audit exists. The V2 pack
and six observer hashes remain unchanged. Continue these original runs with
frozen inputs; partial clocks are not acceptance. Network208V2 remains
unaccepted/uninstalled. No duplicate, Classic208, repeated suite, native or
diagnostic job was launched. No new gameplay playtest.

27 October 08:45 — original v27 replays remain active.

At 08:45:13 baseline 11952/20024 reaches 05:10 with 16/208 complete; delayed
20640/27164 reaches 06:30 with 25/208 complete. Both original process pairs and
exact commands match, errors are empty and no final audits exist. The V2 pack
and six observer hashes remain unchanged. Keep inputs frozen and continue
these original runs. Partial clocks are not acceptance; Network208V2 remains
unaccepted/uninstalled. No duplicate, Classic208, repeated suite, native or
diagnostic job was launched. No new gameplay playtest.

27 October 08:55 — original v27 replays remain active.

At 08:55:15 baseline 11952/20024 reaches 06:40 with 25/208 complete; delayed
20640/27164 reaches 08:40 with 38/208 complete. Original identities and exact
commands match, errors are empty and neither final audit exists. The V2 pack
and all six observer hashes remain unchanged. Continue these original runs
with frozen inputs; partial clocks are not acceptance. Network208V2 remains
unaccepted/uninstalled. No duplicate, Classic208, repeated suite, native or
diagnostic job was launched. No new gameplay playtest.

27 October 09:05 — original v27 replays remain active.

At 09:05:17 baseline 11952/20024 reaches 08:10 with 33/208 complete; delayed
20640/27164 reaches 11:00 with 61/208 complete. All four original identities,
parent relationships and exact commands match; errors are empty and neither
final audit exists. The V2 pack and six observer hashes remain unchanged.
Continue these original runs with frozen inputs; partial clocks are not
acceptance. Network208V2 remains unaccepted/uninstalled. No duplicate,
Classic208, repeated suite, native or diagnostic job was launched. No new
gameplay playtest.

27 October 09:15 — original v27 replays remain active.

At 09:15:16 baseline 11952/20024 reaches 09:50 with 51/208 complete; delayed
20640/27164 reaches 13:00 with 69/208 complete. All four original process
identities, parents and exact commands match; errors are empty and neither
final audit exists. The V2 pack and six observer hashes remain unchanged.
Keep inputs frozen and continue these original runs. Partial clocks are not
acceptance; Network208V2 remains unaccepted/uninstalled. No duplicate,
Classic208, repeated suite, native or diagnostic job was launched. No new
gameplay playtest.

27 October 09:25 — original v27 replays remain active.

At 09:25:21 baseline 11952/20024 reaches 11:30 with 63/208 complete; delayed
20640/27164 reaches 15:00 with 89/208 complete. All four original process
identities, parents and exact commands match; errors are empty and neither
final audit exists. The V2 pack and six observer hashes remain unchanged.
Continue these original runs with frozen inputs; partial clocks are not
acceptance. Network208V2 remains unaccepted/uninstalled. No duplicate,
Classic208, repeated suite, native or diagnostic job was launched. No new
gameplay playtest.

27 October 09:38 — candidate27 V2 delayed run rejected; original baseline continues.

The original delayed wrapper20640/child27164 finished naturally with M097 at
signal NEM-S1 at 16:47:40, 102/208 services complete. Maximum all-location
wait is 2702s; station-only maximum is 2454s. Zero safety events and empty run,
summary and all three inspection errors follow the configured 600s K1 hold at
07:30. This is not an accepted timetable or a recovery certificate. The original
baseline11952/20024 is still live: at09:37:47 it reaches13:20,72/208, with empty
errors and no audit. Exact original commands/parents, V2 pack and six observer
hashes still match; only its two Godot processes remain. Keep inputs frozen.

Evidence: network-candidate-twenty-seven/failed-predictive-delayed retains 20
exact raw files, lossless audit/traffic/failure, the exact V2 pack, actual final
summary and three byte-immutable NYY/PASA/NEM inspections. All 4836 distinct
source hashes match current-at-run candidate899a8292. Original outputs remain;
never rerun this unchanged rejected test. Do not relabel these fingerprints
after a later candidate changes their sources.

All-location cumulative counts are289/390,353/390,378/390,389/390: the30/45-minute
gates fail. Station-only141/207,185/207,200/207,207/207 fails10/20/30 minutes;
185/207 is below90%, never round up. Every passing fraction describes only this
failed prefix. M097 arrivedTVC15:52:14.40 and departed15:55:19.25; its next booked
NYY call is unreached. NEM-S1 is a signal wait, NOT a booked NEM station call.
Its2702s comprises1486s opposing traffic (L004594,S054446,M052446),998s compatible
NYY receiving,182s onward crossing protection forL004 and36s route conflicts
(12 each). Preserve combined receiving buckets without attributing them to
individual claimants.

Actual NEM claims areM097P1/M052P2. M097 awaitsM052's conflicting route; M052 is
moving north through NEM. Actual NYY claim is incomingM066P1. At PASA,M066P2 is
occupied, M101 approachesP1 and incomingM102 reportsP1/P2 alternatives, not two
simultaneous reservations. M066 awaitsM101 clearing its escape approach;
M101 moves south toward PASA after NYY departure16:41:53.25. M102 approaches
PASA and S036 exchanges passengers at KZT. L004 runs north beyond TVC; S054
moves empty stock into its TVC depot. S051 waitsTVC forM052, S049/S053 await a
clear TVC origin berth, and M081 awaits its booked departure.

Two actual future clearance plans exist in all three immutable inspections:
PASA incomingM102/P2, opponentM101/P1, vacaterM066, escapeNYY_P1; and KUMM
incomingS017/P3, opponentM024/P1, vacaterL003, escapeTUVR_P2. Both have received=false,
opponent_received=false and escaped=false. L003 waits forM024's escape approach;
M025 protectsL003's escape section. S017/M024/M021/S033/V003/M065 move and L017
exchanges passengers. This snapshot does not establish permanent deadlock or
a runtime defect.

M051 has reached NCJ depot after passenger arrival16:03:15.90. M082 is in TVC
depot after arrival15:16:03.65. S031 continues beyond the southern boundary,
NCJ arrival15:01:47.90 and portal15:07:22.80. K1/L025 remain in NCJ depot after
13:31:09.15/13:11:10.65 arrivals. These are local observations, not whole-day
improvement, capacity or recovery proof. Eleven K1 minute samples show
27.4545764399m braking by07:31 then unchanged recorded extents through07:40;
these are sampled positions, not exact controller frames or recovery proof.
The actual summary records one V001 overtake ofK1 atTVCN, not completed
multiple-location evidence.

No complete-population comparison, acceptance or installation was performed.
Wait for the original baseline before departure-only replanning around actual
opposing groups, compatible receiving roads and full-tail clearance. No new
replay, Classic208, full suite or native job was launched. Network208V2 remains
unaccepted/uninstalled; legacy readiness and runtime remain unchanged. No new
gameplay playtest until an accepted V2 installation.

27 October 09:45 — original v27 baseline remains active.

At 09:45:26 baseline11952/20024 reaches14:50 with85/208 complete, peak34 and
maximum wait41.0m. Its original commands and parents match; errors are empty
and no final audit exists. The V2 pack and all six observer hashes match using
the launch verifier's text normalization. An initial raw-byte observer check
was corrected to that recorded normalization; no source file was changed.
The delayed run remains rejected with its exact evidence preserved in7f49205e;
its processes have ended. Only the original baseline pair remains live.
Continue with frozen inputs; partial progress is not acceptance. Network208V2
remains unaccepted/uninstalled. No duplicate, Classic208, repeated suite, native
or diagnostic job was launched. No new gameplay playtest.

27 October 09:57 — candidate27 V2 baseline also rejected; both original runs ended.

The original baseline11952/20024 finished naturally at16:07:48 with M026 at
signal TUVR-N3 and96/208 complete. Maximum all-location wait is2702s;
station-only maximum2458s. Zero safety events and empty run, summary and both
inspection error logs; no manual intervention. Both original v27 V2 runs have
now failed. Never rerun either unchanged or install their partial outputs.

Evidence: network-candidate-twenty-seven/failed-predictive-baseline preserves
17 exact raw files, lossless audit/traffic/failure, exact V2 pack, actual final
summary and two byte-immutable KUMM/TUVR inspections. All4836 distinct source
hashes match current-at-run candidate899a8292. Original outputs remain. These
fingerprints must remain historical after any next candidate changes sources.

All-location cumulative275/375,342/375,364/375,374/375 fails30/45 minutes.
Station-only146/210,192/210,207/210,210/210 fails10 minutes;146/210 is below70%,
never round up. Passing fractions describe only the failed prefix. M026 left
booked Cherthala/SRTL at15:13:22.25 after arrival15:11:55.25; its next booked
ERS call is unreached. TUVR-N3 is a signal wait, NOT a booked Turavur call.
The2702s consists of1228s opposing(M06520,M053696,M021512),1128s compatible
KUMM receiving,190s occupied blocks,122s route conflicts and34s crossing
protection forM065. Preserve combined receiving/conflict buckets without
attributing them individually to the listed claimants.

Actual KUMM claims areM015P3 and incomingV003P1/P2/P3 alternatives, not three
simultaneous reservations. Actual TUVR claims areM024P2/M026P3 and approaching
M021P1. M026 awaitsM021 inKUMM_single; M024 awaits that crossing; M015 atKUMM
andM068 atSRTL await compatible TUVR space held byM024/M026. M021 moves south
at24.6m/s towardTUVR. V003/M025/M053/M065 move; M022 has just arrivedERS and
exchanges passengers. M048 has continued beyond the northern boundary, portal
arrival15:51:37.25. S033 waits forV003's block; L003/S017 await departures.
Both inspections report no future plans and byte-identical before/after state.
No permanent-deadlock or runtime-defect inference.

In the south,M097 waitsNEM forNYY receiving reported againstL004/V007; V007
atNYY waits forPASA roads reported againstM101/S054. M101 waitsPASA forS054's
conflicting route whileS054 moves north. M052/KZT andM066/ERL dwell; M102
has begun its northbound departure. S051 completes passenger exchange; S049,
S053 andM081 await departure. M051 runs empty stock towardNCJ depot after
passenger arrival16:03:15.90. M082 is inTVC depot after arrival15:13:39.30.
S031 has continued beyondNCJ, portal15:00:22.30; K1/L025 are stored atNCJ after
arrivals12:46:12.65/13:14:56.65. These local observations are not whole-day
improvement, capacity or recovery proof. The baseline summary has no K1
overtakes. No complete-population comparison or recovery certificate.

Delayed failure evidence7f49205e remains unchanged. Both original jobs ended;
only read-only diagnostics ran and are now finished. No replay, Classic208,
full-suite or native check was launched. Runtime/routes/sounds/legacy choices
remain unchanged. Next: coordinate departure groups from both actual queues,
including compatible receiving roads and full-tail clearance, before one new
V2 baseline and one new delayed test. Network208V2 remains unaccepted and
uninstalled. No gameplay playtest until a passing V2 installation.

27 October 10:07 — candidate28 departure groups authored and guarded; not yet replayed.

Exactly sixteen departures change from candidate27:

- M053: 15:00 -> 15:40
- M015: 15:15 -> 15:50
- M021: 15:30 -> 16:00
- M025: 16:05 -> 16:25
- L003: 16:20 -> 16:50
- L011: 16:45 -> 16:55
- L009: 17:00 -> 17:15
- M097: 14:45 -> 15:30
- S051: 15:40 -> 17:20
- S049: 16:10 -> 17:40
- S053: 16:10 -> 18:00
- M081: 17:10 -> 19:00
- M085: 17:30 -> 19:20
- M087: 18:00 -> 19:40
- M083: 19:00 -> 20:00
- L037: 19:20 -> 20:20

Restoring these departure strings recovers each entire predecessor JSON object.
Every non-departure field is unchanged; common-author service records are
identical in both packs and K1 remains06:00. There are208 services(40local,
104mail,56superfast,8VB),168 boundary journeys,71 overnight origins and3-13
starts/hour. All205 overrides reproduce both packs normally and under exact
--check. All four headless authoring guards pass with empty errors. Runtime/tests
are unchanged from the completed candidate10 1003-test suite; no unchanged
full-suite rerun. Twelve raw authoring proofs are preserved alongside both pack
hashes and the exact predecessor copies in candidate-twenty-eight-before.
V2 pack SHA256:864c60fac44cea82fadc0438d6ea15d836963b808b25f41b543ce1f725532faf.

The northern hypothesis delays M053/M015/M021 to15:40/15:50/16:00, leaving a
larger origin gap after retainedM06514:30. M025 and the following locals move
together to16:25/16:50/16:55/17:15. RetainM04914:15,V00315:50,S03316:00,S01716:35.
Actual27 baselineM026 waits1228s opposingM065/M053/M021 and1128s for compatible
KUMM receiving. M048's KUMM full-rake axis envelope15:24:54-15:35:28 is followed
byM05315:36:42-15:47:16, M02215:48:30-15:59:02 andM02116:00:18-failure. Moving
the replenishing mail group aims to leave an opportunity forM026 and following
northbound trains. Retained fast trains may change crossing/overtaking order.

The southern hypothesis movesM097's QLN departure45minutes later to15:30 and
holds following TVC groups untilS05117:20,S04917:40,S05318:00, thenM08119:00,
M08519:20,M08719:40,M08320:00,L03720:20. RetainM10112:45,V00715:30,L00414:55 and
all candidate27 northbound southern departures. Actual27 delayedM097 leftTVC
15:55:19.25 then accumulated2702s atNEM-S1, including1486s opposingL004/S054/M052
and998s compatibleNYY receiving. Their observed NEM full-rake envelopes end
16:23:42/16:34:34/16:47:26. LaterM097 and the gap before following southbound
trains aim to avoid that queue without filling both NEM roads. M066/M102/S036
and later groups remain constraints; later local waits, overtakes and origin
queues remain unproven. These observed times are not candidate28 predictions.

sampled-groups.json/sample-groups.py retain actual27 overlaps from11:00 to each
failure, continuous intervals, static bounds, hashes, formulas, about2s sampling
and censoring. Southern bounds remain from23; ALLP-AMPA uses report centers
with half-width+200m exclusion. These are planning inputs, not interlocking
ownership, assigned roads, guaranteed crossing gaps, escape or full-day capacity
proof. No isolated-model score or whole-day improvement claim. Several in-memory
hourly-arithmetic alternatives were discarded before authoring; no rejected
source draft or replay exists for them.

Both original27 runs are rejected: baseline7fc287b1(17raw files,two immutable
inspections), delayed7f49205e(20raw files,three inspections),4836 current-at-run
sources each. Their fingerprints are now HISTORICAL after candidate28. Preserve
all evidence and original outputs; never relabel, rerun unchanged or install.
Next: commit/push the exact guarded candidate and launch one isolated V2 baseline
with snapshots and one delayed test with600s K1 hold at07:30. No Classic208
readiness requirement. All completion,safety,wait,physical and recovery gates
remain unchanged. Network208V2 remains unaccepted/uninstalled. Legacy choices,
runtime,approved sound,gangways/portals,R47 and pending UI/category helpers are
unchanged. No gameplay playtest until a passing V2 installation; feasibility
and completion ETA remain unproven.

27 October 10:10 — candidate28 V2 launch verified, inputs frozen.

Candidate22078135 was committed/pushed after exact author reproduction, all four
headless authoring guards and verification of twelve staged raw proofs, both pack
hashes and override JSON. Exactly two new V2 runs were launched once at10:10:13
in rehearsals-v28: baseline wrapper26840/child26252 with --network --snapshots,
and delayed wrapper8232/child6576 with --network --delay=600 --delay-at=27000.
All four actual commands/options, unique outputs, the original predictive
baseline catalogue,4836 distinct source hashes and six observer hashes are
verified. Verification waited for the original catalogue and succeeded without
a failed attempt or restart. Five exact launch files plus their hash manifest
are preserved in network-candidate-twenty-eight.

At10:10:34 the baseline has no first progress line yet; delayed reaches00:10.
Both original process pairs match; errors are empty and neither final audit
exists. These partial clocks do not establish acceptance. Freeze runtime, routes,
packs and all six observers while either original run lives. No duplicate,
Classic208, full suite, native, search or diagnostic job was launched. The source
suite remains the completed1003-test candidate10 result; four authoring guards
cover this departure-only change. Both v27 failures remain rejected and their
source fingerprints are historical: baseline7fc287b1 and delayed7f49205e.
Network208V2 is unaccepted/uninstalled. Next: inspect these original final reports
against every completion, safety, wait, physical and recovery gate. No new
gameplay playtest until a passing V2 installation. Feasibility and ETA remain
unproven; the continuation automation stays active.

27 October 10:13 — original candidate28 runs continue.

At10:13:12, baseline26840/26252 reaches01:00,0/208,peak10,maxwait0.1m;
delayed8232/6576 reaches01:40,1/208,peak14,maxwait6.1m. Both original command
lines and parents match the launch proof; errors are empty and final audits are
absent. The V2 pack, six observers and all frozen source paths remain unchanged.
These partial clocks are not acceptance. No duplicate, Classic208, suite, native,
search or diagnostic job was launched. Next: continue the same original runs,
then inspect their actual final reports. Network208V2 remains unaccepted and
uninstalled; no new gameplay playtest is available. Historical v27 failures and
all certified legacy choices remain preserved.

27 October 10:23 — original candidate28 runs continue.

At10:23:12, baseline26840/26252 reaches03:20,2/208,peak23,maxwait6.1m;
delayed8232/6576 reaches04:20,7/208,peak29,maxwait9.3m. All four original
commands and parents match the launch proof; errors are empty and final audits
are absent. The V2 pack, six observers and frozen source paths remain unchanged.
Partial progress is not acceptance. No duplicate, Classic208, suite, native,
search or diagnostic job was launched. Continue the same original runs, then
inspect their actual final reports. Network208V2 remains unaccepted/uninstalled;
no new gameplay playtest is available. Historical evidence and certified legacy
choices remain preserved.

27 October 10:33 — original candidate28 runs continue.

At 10:33:14, baseline 26840/26252 reaches 05:00 with 16/208 complete, peak 29
and maximum wait 26.0 minutes. Delayed 8232/6576 reaches 06:20 with 23/208
complete, peak 31 and maximum wait 31.1 minutes. All four original commands
and parents match the launch proof. Error logs are empty; final audits are absent.
The V2 pack, six observers and frozen source paths remain unchanged.

These partial results do not establish acceptance or a complete-population
comparison. Continue the same original runs and inspect their actual final reports.
No duplicate, Classic208, suite, native, search or diagnostic job was launched.
Network208V2 remains unaccepted/uninstalled. No new gameplay playtest is available;
historical evidence and certified legacy choices remain preserved.

27 October 10:43 — original candidate28 runs continue.

At 10:43:12, baseline 26840/26252 reaches 06:30 with 25/208 complete, peak 31
and maximum wait 31.1 minutes. Delayed 8232/6576 reaches 08:20 with 34/208
complete, peak 31 and maximum wait 35.8 minutes. All four original commands
and parents match the launch proof. Error logs are empty; final audits are absent.
The V2 pack, six observers and frozen source paths remain unchanged.

These partial results do not establish acceptance, recovery or a complete-population
comparison. Continue the same original runs and inspect their actual final reports.
No duplicate, Classic208, suite, native, search or diagnostic job was launched.
Network208V2 remains unaccepted/uninstalled. No new gameplay playtest is available;
historical evidence and certified legacy choices remain preserved.

27 October 10:55 — original candidate28 runs continue.

At 10:55:38, baseline 26840/26252 reaches 08:30 with 35/208 complete, peak 31
and maximum wait 35.8 minutes. Delayed 8232/6576 reaches 11:20 with 61/208
complete, peak 31 and maximum wait 40.9 minutes. All four original commands
and parents match the launch proof. Error logs are empty; final audits are absent.
The V2 pack, six observers and frozen source paths remain unchanged.

These partial results do not establish acceptance, recovery or a complete-population
comparison. Continue the same original runs and inspect their actual final reports.
No duplicate, Classic208, suite, native, search or diagnostic job was launched.
Network208V2 remains unaccepted/uninstalled. No new gameplay playtest is available;
historical evidence and certified legacy choices remain preserved.

27 October 11:03 — original candidate28 runs continue.

At 11:03:14, baseline 26840/26252 reaches 09:40 with 49/208 complete, peak 31
and maximum wait 35.8 minutes. Delayed 8232/6576 reaches 12:50 with 69/208
complete, peak 32 and maximum wait 40.9 minutes. All four original commands
and parents match the launch proof. Error logs are empty; final audits are absent.
The V2 pack, six observers and frozen source paths remain unchanged.

These partial results do not establish acceptance, recovery or a complete-population
comparison. Continue the same original runs and inspect their actual final reports.
No duplicate, Classic208, suite, native, search or diagnostic job was launched.
Network208V2 remains unaccepted/uninstalled. No new gameplay playtest is available;
historical evidence and certified legacy choices remain preserved.

27 October 11:13 — original candidate28 runs continue.

At 11:13:12, baseline 26840/26252 reaches 11:20 with 61/208 complete, peak 31
and maximum wait 40.1 minutes. Delayed 8232/6576 reaches 14:50 with 87/208
complete, peak 34 and maximum wait 40.9 minutes. All four original commands
and parents match the launch proof. Error logs are empty; final audits are absent.
The V2 pack, six observers and frozen source paths remain unchanged.

These partial results do not establish acceptance, recovery or a complete-population
comparison. Continue the same original runs and inspect their actual final reports.
No duplicate, Classic208, suite, native, search or diagnostic job was launched.
Network208V2 remains unaccepted/uninstalled. No new gameplay playtest is available;
historical evidence and certified legacy choices remain preserved.

27 October 11:23 — original candidate28 runs continue.

At 11:23:11, baseline 26840/26252 reaches 12:40 with 69/208 complete, peak 31
and maximum wait 40.1 minutes. Delayed 8232/6576 reaches 16:40 with 103/208
complete, peak 34 and maximum wait 40.9 minutes. All four original commands
and parents match the launch proof. Error logs are empty; final audits are absent.
The V2 pack, six observers and frozen source paths remain unchanged.

These partial results do not establish acceptance, recovery or a complete-population
comparison. Continue the same original runs and inspect their actual final reports.
No duplicate, Classic208, suite, native, search or diagnostic job was launched.
Network208V2 remains unaccepted/uninstalled. No new gameplay playtest is available;
historical evidence and certified legacy choices remain preserved.

27 October 11:38 — candidate28 original V2 delayed run rejected; baseline continues.

The original delayed wrapper8232/child6576 finished naturally with M068 at
signal TUVR-N1 at 16:58:22, 106/208 complete, peak34, maximum all-location
wait2702s and station-only2454s. Zero safety events and empty run, summary and
both inspection errors follow the configured600s K1 hold at07:30. The original
baseline26840/26252 remains live: at11:38:15 it reaches15:40,93/208,peak34,
maximum wait41.0m, with empty errors and no final audit. Its original identity
matches. Runtime/routes/packs/six observers remain frozen and unchanged.

Evidence in network-candidate-twenty-eight/failed-predictive-delayed preserves
17 exact raw files, lossless audit/traffic/failure, exact V2 pack, actual final
summary and two byte-immutable KUMM/TUVR inspections. All4836 distinct source
hashes match current-at-run candidate22078135. Original outputs remain. Never
rerun this unchanged rejected test or relabel these fingerprints after a later
candidate changes sources. No acceptance or installation has occurred.

All-location cumulative290/389,354/389,380/389,388/389 fails under30/45 minutes.
Station-only142/208,187/208,203/208,208/208 fails under10/20/30 minutes;
187/208 is below90%, never round up. Every passing fraction applies only to this
failed prefix. M068 arrivedSRTL15:56:12.65 and departed16:04:26.75; next booked
ERS is unreached. TUVR-N1 is a signal wait, not a booked Turavur station call.
Its2702s comprises1850s opposing traffic (M015748,V003668,S033434),750s compatible
KUMM receiving,62s blocks (M02418,M01522,V00322) and40s route conflicts
(M01520,V00320). Combined receiving buckets remain preserved without individual
attribution:200V003/M015,34V003/M024/M015,92M021/S033/M025,92approachingM015/M021,
332approachingV003/M015/M024.

Actual KUMM claims areM021P1/M025P3/approachingS017P2. M021 andM025 await TUVR
receiving capacity forM068/S014/S033. Actual TUVR claims areM068P1/S014P2 and
incomingS033P1/P2/P3 alternatives, not three simultaneous reservations. M068 and
S014 awaitS033 inKUMM_single; S033 moves24.6m/s towardTUVR. S017 approachesKUMM
at16.4163m/s. L003 waitsERS forKUMM receiving, L011 awaits its ERS origin berth,
and L009 is not due until17:15. V003 waitsMAKM for opposingM020, which moves
24.6m/s. M015 approachesSRTL at3.914m/s; M053 exchanges passengers atAMPA and
M065 has just leftKPY. Both inspections retain byte-identical captures and no
future clearance plans. This does not establish permanent deadlock or a runtime
defect.

M026/M022/M024/M048 continued beyond the northern boundary, with actual portal
arrival records15:43:42.75/16:13:42.75/16:39:00.25/14:55:28.30. M097 leftTVC
16:52:39.75 after arrival16:49:34.90 and moves towardNEM-S1 at16.606m/s; it has
not cleared NEM or completed its journey. M052 waitsNEM forM097's crossing,
M066 waitsNYY forNEM receiving andS036 protects that crossing atPASA. M101
waitsPASA forKZT receiving reported againstM102/M070; M102 waitsKZT forPASA
capacity reported againstS036/M101, whileM070 moves north towardKZT. L004
exchanges atKaniyapuram; S054 is in its TVC north depot. V007 continued beyond
the southern boundary at16:38:45. S051/S049/S053 are not due yet. M051/M082 are
inNCJ/TVC depots after passenger arrivals16:03:15.90/15:16:03.65; K1/L025 remain
inNCJ depot after13:31:09.15/13:11:10.65. These local observations are not
whole-day improvement, capacity or recovery proof.

Eleven K1 minute samples show27.4545764399m braking by07:31, then unchanged
recorded extents through07:40. These samples are not exact controller frames
or recovery proof. The actual final summary records one V001 overtake ofK1 at
TVCN, not completed multiple-location evidence. No complete-population comparison,
recovery certificate or installation was performed. Wait for the original baseline
before departure-only replanning around opposing groups, compatible receiving
roads and full-tail clearance. No duplicate replay, Classic208, full suite or
native job was launched; unchanged runtime/tests retain the completed1003-test
suite and candidate28's four passing authoring guards. Network208V2 remains
unaccepted/uninstalled. No new gameplay playtest until an accepted V2 installation.

27 October 11:43 — original candidate28 baseline continues.

At11:43:16, baseline26840/26252 reaches16:30 with101/208 complete, peak34 and
maximum wait41.0 minutes. Both original commands and parents match the launch
proof. Its error log is empty and no final audit exists. V2 pack, six observers
and frozen source paths remain unchanged. The delayed run remains rejected;
its final evidence is committed/pushed3ed49c30 and was not rerun.

These partial baseline results do not establish acceptance, recovery or a
complete-population comparison. Continue the original run and inspect its final
report before departure-only replanning. No duplicate, Classic208, suite, native,
search or diagnostic job was launched. Network208V2 remains unaccepted/uninstalled.
Historical evidence and certified legacy choices are preserved. No new gameplay
playtest is available until an accepted V2 installation.

27 October 11:55 — both original candidate28 V2 runs finished naturally and failed.

Original baseline26840/26252 failed M068 at signalTUVR-N1 at16:56:04,104/208,
peak34,maximum all-location2702s/station-only2458s,zero safety and empty run,
summary and both inspection errors, without a manual hold. Its17 exact raw files
in network-candidate-twenty-eight/failed-predictive-baseline preserve lossless
audit/traffic/failure, exactV2pack, actual final summary and two byte-immutable
KUMM/TUVR inspections. All4836 distinct hashes match current-at-run22078135.
Original outputs remain. The delayed failure is already committed3ed49c30.
Both original process pairs have ended; never rerun unchanged or install either.

All-location cumulative300/411,375/411,401/411,410/411 fails under30/45 minutes.
Station-only155/225,206/225,222/225,225/225 fails under10 minutes. Passing fractions
apply only to this failed prefix. M068 arrivedSRTL16:00:47 and departed16:02:13.25;
next bookedERS is unreached. TUVR-N1 is a signal wait, not a booked Turavur call.
Its2702s comprises1986s opposing(M015718,V003694,S033574),632s compatibleKUMM
receiving,42s blocks(M01522,V00320),42s conflicts(M01520,V00322). Preserve combined
receiving buckets without individual attribution:200M015/V003,90M021/S033/M025,
32M024/M015/V003,206approachingM015/V003/M024,12approachingV003/M015/M024,
52approachingV003/M021,16approachingV003/M021/S033,24approachingS033/V003/M021.

ActualKUMM claims areM021P1/S017P2/M025P3, all waiting forTUVR receiving capacity
reported againstM068/S014. ActualTUVR claims areM068P1/S014P2/approachingS033P3.
M068/S014 awaitS033 inKUMM_single; S033 moves24.6m/s with authority towardTUVR.
L003 waitsERS forKUMM capacity, L011 awaitsERS origin berth andL009 is not due.
M015 waitsMAKM forM020's crossing; M020 moves23.4068m/s. V003 waitsSRTL for
MAKM receiving reported againstM015/S018; S018 moves24.6m/s towardMAKM.
M053 approachesAMPA23.3352m/s; M065 exchanges passengers atKPY. Both immutable
inspections have no future clearance plans. No permanent-deadlock or runtime-defect
inference follows from this failed snapshot.

M026/M022/M024/M048 northern portal arrivals are15:57:13.30/16:13:42.75/
16:34:29.25/15:51:48.25. M097 leftTVC16:52:16.25 after16:49:11.20 arrival and
moves24.6m/s towardNEM-S1; itsNEM clearance and complete journey remain unproven.
M052 waitsNEM forM097, M066 waitsNYY forNEM receiving. M101 exchanges atNCJ
(arrival16:54:10.05) and has not reached its exit portal. M102 moves24.6m/s toward
PASA; S036 waitsERL for opposingV007 andM070 waits behindS036's ERL block.
V007 moves south beyondKZT, L004 approachesKZK andS054 is inTVC north depot.
S051/S049/S053 are not due. M051/M082 are inNCJ/TVC depots after passenger
arrivals16:03:15.90/15:13:39.30; K1/L025 are inNCJ depot after12:46:12.65/
13:14:56.65 arrivals. These local observations are not whole-day improvement,
capacity or recovery proof. The actual baseline summary records noK1 overtakes.

No complete-population comparison, recovery certificate or installation was
performed. Preserve both failures, then replan coordinated departure groups using
actual opposing flows, compatible receiving roads and full-tail clearance.
All non-departure fields,K1,runtime/routes/six observers and approved assets remain
unchanged. No Classic208, duplicate, full-suite or native job was launched.
The unchanged1003-test suite and four candidate28 authoring guards remain valid;
no new gameplay playtest exists before an acceptedV2 installation. Network208V2
remains unaccepted/uninstalled and feasibility within every gate remains unproven.

27 October 12:01 — candidate29 authors twenty northern departures after both original28 V2 failures.

Only these departure strings change from candidate28:
V003 15:50 -> 16:35; S033 16:00 -> 16:45; M015 15:50 -> 16:55; M021 16:00 -> 17:10; M025 16:25 -> 17:25; S017 16:35 -> 17:40; S035 17:45 -> 18:00; M067 17:50 -> 18:15; M057 18:00 -> 18:30; M069 18:15 -> 18:45; S019 18:40 -> 19:00; L003 16:50 -> 19:20; L011 16:55 -> 19:40; L009 17:15 -> 20:00; M055 18:45 -> 20:15; M033 18:55 -> 20:30; M027 19:05 -> 20:45; M031 19:20 -> 21:00; M029 19:30 -> 21:15; M035 19:40 -> 21:30.
Restoring them recovers each entire predecessor JSON object. Every other field
is unchanged, both common-author packs have identical service records and K1
remains06:00. Retain M05315:40/M04914:15/M06514:30 and all southern departures,
including M09715:30,S05117:20,S04917:40,S05318:00,M08119:00,M08519:20,
M08719:40,M08320:00,L03720:20,M10112:45,V00715:30,L00414:55,S05415:20,
M05215:35,M06615:45,M10216:00,M05417:00,L02817:20. Later unchanged
S02120:20,M05920:25,S02321:20 and opposing M020/S018 remain constraints.

Both actual28 failures involve M068 at signalTUVR-N1. Opposing M015/V003/S033
account for1986s baseline/1850s delayed, with632s/750s compatibleKUMM receiving.
Actual M053 KUMM full-rake axis envelopes end16:06:24/16:05:16; M024 follows
until16:18:20/16:22:50, then M015/V003/S033 replenish the section. Actual M068
TUVR envelopes begin16:03:16/16:05:30, S014 at16:22:12/16:22:28. Retaining
M05315:40 and moving V003/S03316:35/16:45 aims to leave a northbound opportunity
before the faster pair leads M01516:55,M02117:10,M02517:25,S01717:40. Following
northern fast/mail/local groups move together through21:30 to avoid bunching.
KUMM actually holds M021/S017/M025 and TUVR M068/S014/S033 in the baseline
failure; the delayed S017 approach and S033 incoming alternatives are preserved
in its inspection. Origin gaps do not establish crossing order, compatible
receiving roads, full-tail clearance, escape or capacity. Later opposing
traffic, local waits, overtakes and origin queues remain unproven.

208 services retain40 local/104 mail/56 superfast/8 VB,168 boundary journeys,
71 overnight origins and3–13 starts/hour. All205 overrides reproduce both packs
normally and with exact --check. All four headless authoring guards passed with
empty errors. Runtime/tests and six observers are unchanged from the completed
1003-test candidate10 suite; no unchanged full-suite rerun. The common-author
consistency is not Classic208 readiness. V2 pack SHA256 is
53e6fc5d44b89930330ac97eb0e342c60877bfa49c47b0bd70eae580f006e9da.
Twelve exact raw authoring files and their hashes are preserved here; exact
predecessors remain in candidate-twenty-nine-before. Staged bytes and pack
hashes must be verified before commit/push.

sampled-groups.json/sample-groups.py retain actual28 overlaps from11:00 to each
failure, continuous full-rake intervals, static bounds, hashes, formulas,
about2s sampling and censoring. Southern bounds remain from23; ALLP–AMPA uses
report centers with half-width+200m exclusion. These are planning inputs, not
interlocking ownership, assigned roads, guaranteed gaps or full-day proof.
No isolated-model score or whole-day improvement claim. In-memory hourly
arithmetic alternatives were discarded before authoring; no rejected source
draft or replay exists.

Both original28 runs ended naturally and failed: baseline f12eba19, M068 at
16:56:04 with104/208; delayed3ed49c30, M068 at16:58:22 with106/208. Both have
zero safety events but fail wait gates. Their17+17 exact raw files,4836 verified
current-at-run source hashes each and four byte-immutable inspections remain.
Their source fingerprints are now HISTORICAL after candidate29; never relabel,
rerun unchanged or install. No full-population comparison or recovery certificate.

Next: commit/push exact guarded29, then launch one new isolated V2 baseline
with snapshots and one delayed600s K1 hold at07:30, once each. No Classic208
job or acceptance requirement. Every completion, safety, wait, physical and
recovery gate remains unchanged. Network208V2 remains unaccepted/uninstalled.
Legacy choices, runtime, approved sound, gangways/portals, R47 and pending
UI/category helpers remain unchanged. No gameplay playtest until a passing V2
installation. Feasibility and completion ETA remain unproven.

27 October 12:03 — candidate29 V2 launch verified; frozen inputs.

Candidate01be15f8 was committed/pushed after exact normal author reproduction,
--check, all four headless authoring guards and staged verification of twelve
raw proofs, both pack hashes and override JSON. Exactly two new V2 runs launched
once at12:02:18 in rehearsals-v29: baseline wrapper164/child7484 with
--network --snapshots; delayed wrapper832/child25904 with --network --delay=600
--delay-at=27000. All four actual commands/options, unique outputs, the ORIGINAL
predictive baseline catalogue,4836 distinct source hashes and six observer
hashes were verified. Verification waited for the original catalogue and passed
without a failed attempt, duplicate or restart. Five exact staged launch files
plus their hash manifest preserve the process/source evidence.

At12:02:51 the baseline has no first progress line; delayed reaches00:20.
Both original process pairs match, errors are empty and neither final audit
exists. These partial clocks are not acceptance. Runtime, routes, packs and six
observers remain frozen while either original run lives. No Classic208, full
suite, native, search or diagnostic job exists. The completed1003-test source
suite is unchanged; four authoring guards cover this departure-only candidate.

Both original28 results remain rejected: baseline f12eba19 M068TUVR-N1 at
16:56:04,104/208 and delayed3ed49c30 at16:58:22,106/208, both zero safety but
failed wait gates. Their17+17 exact raw files,4836 hashes each and four immutable
inspections are historical after candidate29. Never rerun unchanged or install.
Next: inspect the original29 final reports against every completion, safety,
wait, physical and recovery gate. Network208V2 remains unaccepted/uninstalled;
no gameplay playtest until a passing V2 installation. Continuation remains
active; feasibility and completion ETA remain unproven.

27 October 12:05 — original candidate29 runs continue; no final result.

At12:05:18 baseline164/7484 reaches01:00,0/208,peak10,maxwait0.1m;
delayed832/25904 reaches01:40,1/208,peak14,maxwait6.1m. Both original
commands/parents match launch55cace53; errors are empty and final audits absent.
The V2 pack and six observer hashes match, and frozen runtime/tests/routes/packs
have no Git changes. These partial populations are not acceptance or comparison
proof. No other Godot job exists; no duplicate, Classic208, suite or native run
was launched. Keep original29 running with frozen inputs. Next inspect their
actual final reports against all gates; Network208V2 remains unaccepted and
uninstalled. No gameplay playtest is due. Continuation remains active.

27 October 12:15 — original candidate29 V2 runs remain active.

At12:15:17 baseline164/7484 reaches03:20,2/208,peak23,maxwait6.1m;
delayed832/25904 reaches04:20,7/208,peak29,maxwait9.3m. Both original
commands/parents match launch55cace53; empty errors, no final audits. The V2
pack/six observer hashes and frozen Git paths match. No other Godot job exists.
No duplicate, Classic208, suite or native run was launched. Partial clocks and
populations are not acceptance, recovery or complete-population comparison.
Keep the original runs and frozen inputs; inspect their actual final reports
against all gates when available. Network208V2 remains unaccepted/uninstalled.
No gameplay playtest is due; continuation remains active.

27 October 12:25 — original candidate29 V2 runs continue with frozen inputs.

At12:25:14 baseline164/7484 reaches05:00,16/208,peak29,maxwait26.0m;
delayed832/25904 reaches06:20,23/208,peak31,maxwait31.1m. Both original
commands/parents match launch55cace53; empty errors, no final audits. V2 pack,
six observer hashes and frozen Git paths match. No other Godot job exists.
No duplicate, Classic208, suite or native run was launched. Partial clocks and
wait maxima do not establish full-day acceptance or recovery. Keep original29
running unchanged; inspect its actual final reports against all completion,
safety, wait, physical and recovery gates. Network208V2 remains unaccepted and
uninstalled. No gameplay playtest is due; continuation remains active.

27 October 12:36 — original candidate29 V2 runs continue with frozen inputs.

At 12:36:53, baseline 164/7484 reaches 06:40, 25/208 complete, peak 31,
maximum wait 31.9 minutes; delayed 832/25904 reaches 08:50, 40/208 complete,
peak 31, maximum wait 40.9 minutes. Both original command/parent identities
match launch 55cace53. Errors are empty and neither run has a final audit.
The V2 pack, all six observer hashes and frozen Git paths match the launch
inputs. No duplicate or Classic208 run was launched. These partial clocks,
counts and wait maxima do not establish full-day acceptance or recovery.
Keep both original runs unchanged and inspect their actual final reports
against every completion, safety, wait, physical and recovery gate.
Network208V2 remains unaccepted and uninstalled; continuation remains active.
No gameplay change or playtest is due.

27 October 12:45 — original candidate29 V2 runs remain active.

At 12:45:10, baseline 164/7484 reaches 08:00, 33/208 complete, peak 31,
maximum wait 35.8 minutes; delayed 832/25904 reaches 10:40, 59/208 complete,
peak 31, maximum wait 40.9 minutes. Both original command/parent identities
match launch 55cace53. Errors are empty and neither run has a final audit.
The V2 pack, six observer hashes and frozen Git paths remain unchanged.
No duplicate, Classic208, suite or native run was launched. Partial clocks,
counts and wait maxima are not full-day acceptance or recovery evidence.
Continue both originals unchanged; evaluate actual final reports against all
completion, safety, wait, physical and recovery gates. Network208V2 remains
unaccepted and uninstalled. No gameplay change or playtest is due.

27 October 12:55 — original candidate29 V2 runs remain active.

At 12:55:13, baseline 164/7484 reaches 09:40, 49/208 complete, peak 31,
maximum wait 35.8 minutes; delayed 832/25904 reaches 12:50, 69/208 complete,
peak 32, maximum wait 40.9 minutes. Both original command/parent identities
match launch 55cace53. Errors are empty and neither run has a final audit.
The V2 pack, six observer hashes and frozen Git paths remain unchanged.
No duplicate, Classic208, suite or native run was launched. Partial clocks,
counts and wait maxima are not full-day acceptance or recovery evidence.
Continue both originals unchanged; evaluate actual final reports against all
completion, safety, wait, physical and recovery gates. Network208V2 remains
unaccepted and uninstalled. No gameplay change or playtest is due.

27 October 13:05 — original candidate29 V2 runs remain active.

At 13:05:11, baseline 164/7484 reaches 11:20, 61/208 complete, peak 31,
maximum wait 40.1 minutes; delayed 832/25904 reaches 14:40, 86/208 complete,
peak 34, maximum wait 40.9 minutes. Both original command/parent identities
match launch 55cace53. Errors are empty and neither run has a final audit.
The V2 pack, six observer hashes and frozen Git paths remain unchanged.
No duplicate, Classic208, suite or native run was launched. Partial clocks,
counts and wait maxima are not full-day acceptance or recovery evidence.
Continue both originals unchanged; evaluate actual final reports against all
completion, safety, wait, physical and recovery gates. Network208V2 remains
unaccepted and uninstalled. No gameplay change or playtest is due.

27 October 13:15 — original candidate29 V2 runs remain active.

At 13:15:12, baseline 164/7484 reaches 12:40, 69/208 complete, peak 31,
maximum wait 40.1 minutes; delayed 832/25904 reaches 17:00, 107/208 complete,
peak 34, maximum wait 40.9 minutes. Both original command/parent identities
match launch 55cace53. Errors are empty and neither run has a final audit.
The V2 pack, six observer hashes and frozen Git paths remain unchanged.
No duplicate, Classic208, suite or native run was launched. The delayed run
has passed candidate28's failure clock, but this partial prefix is not a
whole-day improvement, capacity or recovery proof. Continue both originals
unchanged; evaluate actual final reports against all completion, safety,
wait, physical and recovery gates. Network208V2 remains unaccepted and
uninstalled. No gameplay change or playtest is due.

27 October 13:29 — candidate 29 original V2 delayed run rejected; baseline continues.

The original delayed wrapper 832/child 25904 finished naturally with M097 at its
booked Parassala/PASA call at 18:23:46, 112/208 complete, peak 37, maximum 2702s in
BOTH wait populations. Zero safety events and empty run, summary and all three
inspection errors follow the configured 600s K1 hold at 07:30. At 13:29:00 the
original baseline 164/7484 reaches 14:50, 85/208, peak 34, maxwait 41.0m, with empty
errors and no final audit. Original baseline command/parent identity matches
launch 55cace53. Runtime/routes/packs/six observers remain frozen and unchanged.

Evidence in network-candidate-twenty-nine/failed-predictive-delayed preserves
20 exact raw files, lossless audit/traffic/failure, exact V2 pack, actual final
summary and three byte-immutable inspections: initial KZT, NEM and final PASA.
All 4836 distinct source hashes match current-at-run candidate 01be15f8. Original
outputs remain. Never rerun this unchanged rejected test or relabel these
fingerprints after a later candidate changes sources. No acceptance/installation.

All-location cumulative 333/443, 403/443, 432/443, 442/443 fails under 30/45 minutes.
Station-only 160/237, 211/237, 229/237, 236/237 fails ALL four gates. Every passing
fraction applies only to the failed prefix. M097 arrived PASA17:37:34.25 with
no departure; its current signal is PASA-S1. This IS a booked station wait.
Its 2702s comprises 2294s compatible KZT receiving, 396s opposing M072 and 12s route
conflict M072. Preserve the receiving buckets without individual attribution:
198M054, 1408 combined M054/S038, 52M054/M072, 198M072, 116 approaching M054/S038,
322 approaching M072/M054.

Actual KZT claims are M054P1/S038P2; actual PASA claims are M097P1/L027P2.
Both KZT trains await PASA receiving for M097/L027, and both PASA trains await
KZT receiving for M054/S038. L028 waits ERL for KZT; L030 waits for L028's ERL
block, and L038 waits behind L030. Actual NEM claims M049P1/M103P2; both await
NYY receiving reported against S051/M072. M072 waits NYY for NEM receiving,
while S051 waits NYY for PASA receiving. S049 waits TVC for NEM capacity and M065
waits behind S049's TVC block. S053 awaits a clear TVC origin berth; M081 is not
due until 19:00. All three inspections preserve byte-identical before/after
captures and have no future clearance plans. This does not establish permanent
deadlock or a runtime defect. M052/M070/M102/S036 and northern V003/S033/M015/
M021/M025/S017 move; M053 and M066 dwell at PVU/QLN respectively.

M068/S014/M024/M020/S018 continued beyond the northern boundary, with actual
portal arrivals 16:42:53.30/17:04:36.75/16:37:27.75/18:13:28.60/17:49:36.75.
M101/V007 continued beyond the southern boundary at 17:48:19.80/16:38:45.
M051/M082 remain in NCJ/TVC depots after passenger arrivals 16:03:15.90/15:16:03.65;
K1/L025 remain in NCJ depot after 13:31:09.15/13:11:10.65. These local observations
are not whole-day improvement, capacity or recovery proof.

Eleven K1 minute samples show 27.4545764399m braking by 07:31, then unchanged
recorded extents through 07:40. These are not exact controller frames or recovery
proof. The actual final summary records one V001 overtake of K1 at TVCN, not
completed multiple-location evidence. No complete-population comparison,
recovery certificate or installation was performed. Wait for the original
baseline before departure-only replanning around opposing groups, compatible
receiving roads and full-tail clearance. No duplicate replay, Classic 208, full
suite or native job was launched. Unchanged runtime/tests retain the completed
1003-test suite and candidate 29's four passing authoring guards. Network 208V2
remains unaccepted/uninstalled; feasibility within all gates and ETA remain
unproven. No new gameplay playtest until an accepted V2 installation.

27 October 13:35 — original candidate29 V2 baseline remains active.

At 13:35:11, original baseline 164/7484 reaches 16:10, 98/208 complete,
peak 34 and maximum wait 41.0 minutes. Its commands and parent identities
match launch55cace53; errors are empty and no final audit exists. The V2 pack,
six observer hashes and frozen Git paths remain unchanged. Original delayed
832/25904 remains ended and rejected, with exact evidence in53cbc1c4; it was
not rerun. No duplicate, Classic208, suite or native job was launched.
Continue the original baseline unchanged and inspect its actual final report
before departure-only replanning. Partial clocks and completion counts are
not acceptance, whole-day improvement, capacity or recovery proof.
Network208V2 remains unaccepted/uninstalled. No gameplay change or playtest
is due; continuation remains active.

27 October 13:45 — original candidate29 V2 baseline remains active.

At 13:45:12, original baseline 164/7484 reaches 18:00, 110/208 complete,
peak 37 and maximum wait 41.0 minutes. Its commands and parent identities
match launch55cace53; errors are empty and no final audit exists. The V2 pack,
six observer hashes and frozen Git paths remain unchanged. Original delayed
832/25904 remains ended and rejected, with exact evidence in53cbc1c4; it was
not rerun. No duplicate, Classic208, suite or native job was launched.
Continue the original baseline unchanged and inspect its actual final report
before departure-only replanning. Partial clocks and completion counts are
not acceptance, whole-day improvement, capacity or recovery proof.
Network208V2 remains unaccepted/uninstalled. No gameplay change or playtest
is due; continuation remains active.

27 October 13:59 — candidate 29 original V2 baseline rejected; both original runs ended.

The original baseline wrapper164/child7484 finished naturally with M097 at its
booked Parassala/PASA call at 18:07:58, 110/208 complete, peak37, maximum2702s in
BOTH wait populations. Zero safety events and empty run, summary and all three
inspection errors; no manual hold. Original delayed832/25904 is already rejected
in53cbc1c4. No replay was restarted. Neither failed test may be rerun unchanged
or installed. No original29 process remains.

Evidence in network-candidate-twenty-nine/failed-predictive-baseline preserves
20 exact raw files, lossless audit/traffic/failure, exact V2 pack, actual final
summary and three byte-immutable inspections: initialKZT, NEM and finalPASA.
All4836 distinct source hashes match current-at-run candidate01be15f8. Original
outputs remain. These fingerprints must remain historical after a later source
change; never relabel. Runtime/routes/packs/six observers remain unchanged.

All-location cumulative321/443,404/443,433/443,442/443 fails under30/45 minutes;
433/443 is below98%, never round up. Station-only168/248,226/248,244/248,247/248
fails under10/45 minutes. Every passing fraction applies only to the failed
prefix. M097 arrivedPASA17:21:46.75 with no departure, current signalPASA-S1.
This IS a booked station wait. Its2702s comprises1698s opposing traffic
(M070356,M072778,M054406,S038158),968s compatibleKZT receiving and36s route
conflicts (12 each M070/M072/M054). Preserve receiving buckets without individual
attribution:90S038,198combinedM054/S038,182M072,276approachingS038/L028,
132approachingM054,14approachingM054/M072,76approachingM072/M054.

ActualKZT claims L028P1 and incomingL030P1/P2 alternatives, not simultaneous
reservations. L028 approachesKZT at3.1848m/s; L030 moves15.7618m/s after leaving
ERL; L038 waits behind L030's ERL block. ActualPASA claims M097P1 and incoming
S038P1/P2 alternatives. M097 awaits S038 inPASA_single; S038 moves24.2454m/s
with authority towardPASA. M054 has leftPASA18:03:56.25 and moves24.6m/s towardNYY;
L027 waitsNYY for M054. ActualNEM claims S051P2/M072P1; S051 awaits opposingM072,
which moves24.6m/s towardNEM. S049 waitsTVC for NEM receiving reported against
S051; M103 waits for S049's TVC block and M049 waits behind M103. S053 awaits a
clearTVC origin; M081 is not due until19:00. All three inspections preserve
byte-identical before/after captures and have no future clearance plans. This
does not establish permanent deadlock or a runtime defect.

M068/S014/M024/S018 continued beyond the northern boundary, with actual portal
arrivals16:42:12.80/17:04:36.75/16:34:29.25/17:49:36.75. M020 has arrivedERS18:01:12.35
but awaits S034's portal block; S034 moves20.2181m/s toward its portal, so neither
is counted here as cleared beyond the boundary. M101/V007 reached the southern
portal16:59:44.80/17:18:18.50. M051/M082 remain in NCJ/TVC depots after passenger
arrivals16:03:15.90/15:13:39.30; K1/L025 remain in NCJ depot after12:46:12.65/13:14:56.65.
M015/M025/S017/V003 and M052/M066/M070/M102/S036 move; M021 awaits L010's TUVR
crossing, and S033 awaits opposingV004 atALLP. L010 has authority with departure
horns and brakes held; V004 moves24.6m/s. M053/M065 dwell atQLN/TVCN respectively.
These local observations are not whole-day improvement, capacity or recovery
proof. The actual baseline summary records noK1 overtakes. The baseline and
delayed failed populations differ; no complete-population comparison, recovery
certificate or installation was performed.

Both original29 results now support departure-only planning around the actual
southern opposing groups, compatible receiving roads and full-tail clearance.
Baseline M097 waits mostly for opposing M070/M072/M054/S038, while delayed M097
waits mostly for receiving roads held by M054/S038, with L027 also fillingPASA.
Origin gaps alone do not guarantee crossing order, compatible roads, escape or
capacity. No duplicate replay, Classic208, full suite or native job was launched.
Unchanged runtime/tests retain the completed1003-test suite and candidate29's
four passing authoring guards. Network208V2 remains unaccepted/uninstalled;
feasibility within all gates and ETA remain unproven. No new gameplay playtest
until an accepted V2 installation.

27 October 14:04 — candidate30 authors twenty-two southern departures after both original29 V2 failures.

Only these departure strings change from candidate29:
S038 17:10 -> 17:50; M072 16:55 -> 18:05; M054 17:00 -> 18:20; V008 18:25 -> 18:35; M098 17:50 -> 18:50; M090 18:00 -> 19:05; M104 18:30 -> 19:20; M088 18:40 -> 19:35; M058 18:55 -> 19:50; M056 19:10 -> 20:05; L028 17:20 -> 20:20; L030 17:25 -> 20:40; L038 17:35 -> 21:00; L032 19:25 -> 21:20; S051 17:20 -> 18:30; S049 17:40 -> 18:50; S053 18:00 -> 19:10; M081 19:00 -> 19:40; M085 19:20 -> 20:00; M087 19:40 -> 20:20; M083 20:00 -> 20:40; L037 20:20 -> 21:00.
Restoring them recovers each entire predecessor JSON object. Every other field
is unchanged, both common-author packs have identical service records and K1
remains06:00. All northern origins remain at candidate29 values. Retain southern
M09715:30,L02715:00,M10315:20,M07016:30, plus M10112:45,V00715:30,L00414:55,
S05415:20,M05215:35,M06615:45,M10216:00,S03616:10. Later through M049/M065/M053
and M09919:35, M09121:00/M07321:10/M08921:20, S04021:40 remain constraints.

Both actual29 runs fail M097 at its bookedPASA call. Baseline has1698s opposing
M070/M072/M054/S038 plus968s compatibleKZT receiving; delayed has396s opposing
M072 plus2294s receiving, ultimately KZT M054/S038 opposite PASA M097/L027.
Actual M070 PASA full-rake axis envelopes end17:28:52 baseline/17:22:26 delayed;
M097 arrivesPASA17:21:46.75/17:37:34.25. Retaining M07016:30 and leaving80 origin
minutes before S03817:50 aims to interrupt repeated northbound replenishment
while M097 and following L027 cross south. S038/M072/M054/V008 lead the mails
through20:05, then the local group moves together20:20-21:20 to reduce renewed
overtaking pressure. TVC southbound S051/S049/S053 move18:30/18:50/19:10, followed
by M081/M085/M087/M083/L03719:40-21:00, aiming to leave NEM receiving capacity.
Actual29 delayed NEM roads hold M049/M103 opposite M072/S051 atNYY. These are
observations, not candidate30 predictions. Origin gaps do not guarantee crossing
order, compatible roads, full-tail clearance, escape or capacity. Later opposing
traffic, local waits, overtakes and origin queues remain unproven.

208 services retain40local/104mail/56superfast/8VB,168 boundary journeys,
71 overnight origins and3-13 starts/hour. All205 overrides reproduce both packs
normally and with exact --check. All four headless authoring guards passed with
empty errors. Runtime/tests and six observers are unchanged from the completed
1003-test candidate10 suite; no unchanged full-suite rerun. Common-author service
consistency is not Classic208 readiness. V2 pack SHA256 is
b8d52a1686c311dc67a06c6b5388f695b97fda57c572858b8b659bd0ada70b49.
Twelve exact raw authoring files and their hashes are preserved here; exact
predecessors remain in candidate-thirty-before. Staged raw bytes, both pack
hashes and override JSON must be verified before commit/push.

sampled-groups.json/sample-groups.py preserve actual29 continuous full-rake axis
overlap intervals from11:00 to each failure, static bounds, hashes, formulas,
about2s sampling and censoring. Southern bounds remain from23; ALLP-AMPA uses
report centers with half-width+200m exclusion. Planning inputs only, not exact
interlocking ownership, assigned roads, guaranteed gaps or full-day proof.
No isolated-model score or whole-day improvement claim. In-memory hourly
arithmetic alternatives were discarded before authoring; no rejected source
draft or replay exists.

Both original29 runs ended naturally and failed: baseline e3e9160c at18:07:58,
110/208; delayed53cbc1c4 at18:23:46,112/208. Both M097 bookedPASA failures have
2702s in both wait populations, peak37, zero safety events and empty errors.
Their20+20 exact raw files,4836 verified current-at-run source hashes each,
lossless reports/exact packs/actual summaries and six byte-immutable inspections
remain. These fingerprints are now HISTORICAL after candidate30; never relabel,
rerun unchanged or install. Baseline all321/443,404/443,433/443,442/443 fails30/45;
station168/248,226/248,244/248,247/248 fails10/45. Delayed all333/443,403/443,
432/443,442/443 fails30/45; station160/237,211/237,229/237,236/237 failsALL.
All passing fractions apply only to failed prefixes. No complete-population
comparison, recovery certificate or installation. The baseline evidence heading
was corrected from an inadvertently premature14:01 label to the actual13:59
archive/commit checkpoint; original process and provenance timestamps are intact.

Next: commit/push exact guarded30, then launch one new isolated V2 baseline
with snapshots and one delayed600s K1 hold at07:30, once each. No Classic208
job or acceptance requirement. All completion, safety, wait, physical and recovery
gates remain unchanged. Network208V2 remains unaccepted/uninstalled. Legacy
choices, approved sound, gangways/portals, R47 and pending UI/category helpers
remain unchanged. No gameplay playtest until a passing V2 installation.
Feasibility and completion ETA remain unproven.

27 October 14:05 — candidate30 V2 launch verified; frozen inputs.

Candidate d82d37ed was committed/pushed after exact normal author reproduction,
--check, all four headless authoring guards and staged verification of twelve
raw proofs, both pack hashes and override JSON. Exactly two new V2 runs launched
once at14:04:54 in rehearsals-v30: baseline wrapper21528/child21596 with
--network --snapshots; delayed wrapper21816/child8612 with --network --delay=600
--delay-at=27000. All four actual commands/options, unique outputs, the ORIGINAL
predictive baseline catalogue,4836 distinct source hashes and six observer
hashes were verified. The original catalogue existed before verification;
no failed verification attempt, duplicate or restart. Five exact staged launch
files plus their hash manifest preserve the process/source evidence.

At14:05:15 the baseline has no first progress line; delayed reaches00:10.
Both original process pairs match, errors are empty and neither final audit
exists. These partial clocks are not acceptance. Runtime, routes, packs and six
observers remain frozen while either original run lives. No Classic208, full
suite, native, search or diagnostic job remains. The completed1003-test source
suite is unchanged; four authoring guards cover this departure-only candidate.

Both original29 results remain rejected: baseline e3e9160c M097 bookedPASA at
18:07:58,110/208 and delayed53cbc1c4 M097 bookedPASA at18:23:46,112/208, both
zero safety but failed wait gates. Their20+20 exact raw files,4836 hashes each
and six immutable inspections are historical after candidate30. Never rerun
unchanged, relabel their hashes or install. Next: inspect the original30 final
reports against every completion, safety, wait, physical and recovery gate.
Network208V2 remains unaccepted/uninstalled; no gameplay playtest until a passing
V2 installation. Continuation remains active; feasibility and completion ETA
remain unproven.

27 October 14:07 — original candidate30 V2 runs remain active.

At14:07:12 the original baseline21528/21596 reaches00:50,0/208,peak8,
maxwait0.1m; delayed21816/8612 reaches01:20,0/208,peak13,maxwait2.4m.
Both original commands and parent identities match launch59bdb842; errors are
empty and no final audits exist. The V2 pack, six observers and frozen Git
paths are unchanged. Continue these original runs without restarting; no
Classic208, duplicate replay, suite or native job was launched. Partial clocks
are not acceptance or recovery proof. Network208V2 remains unaccepted/uninstalled.
No gameplay change or new playtest is due; continuation remains active.

27 October 14:19 — original candidate30 V2 runs remain active.

At14:19:34 the original baseline21528/21596 reaches03:40,2/208,peak27,
maxwait7.4m; delayed21816/8612 reaches04:40,13/208,peak29,maxwait18.6m.
Both original commands and parent identities match launch59bdb842; errors are
empty and no final audits exist. Both source packs, six observers and frozen
Git paths remain unchanged. Continue these original runs without restarting;
no Classic208, duplicate replay, suite or native job was launched. Partial
clocks are not acceptance, capacity or recovery proof. Network208V2 remains
unaccepted/uninstalled. No gameplay change or new playtest is due;
continuation remains active.

27 October 14:27 — original candidate30 V2 runs remain active.

At14:27:18 the original baseline21528/21596 reaches04:50,16/208,peak29,
maxwait26.0m; delayed21816/8612 reaches06:20,23/208,peak31,maxwait31.1m.
Both original commands and parent identities match launch59bdb842; errors are
empty and neither final audit exists. Both source packs, six observers and
frozen Git paths remain unchanged. Continue the original runs without restart.
No Classic208, duplicate replay, full suite or native job was launched. Partial
clocks and wait maxima are not acceptance or recovery proof. Network208V2 remains
unaccepted/uninstalled. No gameplay change or new playtest is due;
continuation remains active.

27 October 14:37 — original candidate30 V2 runs remain active.

At14:37:14 the original baseline21528/21596 reaches06:20,23/208,peak31,
maxwait31.1m; delayed21816/8612 reaches08:20,34/208,peak31,maxwait35.8m.
Both original commands and parent identities match launch59bdb842; errors are
empty and neither final audit exists. Both source packs, six observers and
frozen Git paths remain unchanged. Continue the original runs without restart.
No Classic208, duplicate replay, full suite or native job was launched. Partial
clocks and wait maxima are not acceptance, capacity or recovery proof.
Network208V2 remains unaccepted/uninstalled. No gameplay change or new playtest
is due; continuation remains active.

27 October 14:47 — original candidate30 V2 runs remain active.

At14:47:14 the original baseline21528/21596 reaches08:00,33/208,peak31,
maxwait35.8m; delayed21816/8612 reaches10:40,59/208,peak31,maxwait40.9m.
Both original commands and parent identities match launch59bdb842; errors are
empty and neither final audit exists. Both source packs, six observers and
frozen Git paths remain unchanged. Continue the original runs without restart.
No Classic208, duplicate replay, full suite or native job was launched. Partial
clocks and wait maxima are not acceptance, capacity or recovery proof.
Network208V2 remains unaccepted/uninstalled. No gameplay change or new playtest
is due; continuation remains active.

27 October 14:57 — original candidate30 V2 runs remain active.

At14:57:19 the original baseline21528/21596 reaches09:30,48/208,peak31,
maxwait35.8m; delayed21816/8612 reaches12:50,69/208,peak32,maxwait40.9m.
Both original commands and parent identities match launch59bdb842; errors are
empty and neither final audit exists. Both source packs, six observers and
frozen Git paths remain unchanged. Continue the original runs without restart.
No Classic208, duplicate replay, full suite or native job was launched. Partial
clocks and wait maxima are not acceptance, capacity or recovery proof.
Network208V2 remains unaccepted/uninstalled. No gameplay change or new playtest
is due; continuation remains active.

27 October 15:07 — original candidate30 V2 runs remain active.

At 15:07:24, baseline 21528/21596 reaches 11:20, 61/208, peak 31,
maximum wait 40.1m; delayed 21816/8612 reaches 14:40, 86/208, peak 34,
maximum wait 40.9m. Both original commands and parent identities match
launch59bdb842; errors are empty and neither final audit exists. Both source
packs, six observers and frozen Git paths remain unchanged. Continue the
original runs without restart. No Classic208, duplicate replay, full suite
or native job was launched. Partial clocks and wait maxima are not acceptance,
capacity or recovery proof. Network208V2 remains unaccepted/uninstalled.
No gameplay change or new playtest is due; continuation remains active.

27 October 15:17 — original candidate30 V2 runs remain active.

At 15:17:22, baseline 21528/21596 reaches 12:40, 69/208, peak 31,
maximum wait 40.1m; delayed 21816/8612 reaches 17:00, 107/208, peak 34,
maximum wait 40.9m. Both original commands and parent identities match
launch59bdb842; errors are empty and neither final audit exists. Both source
packs, six observers and frozen Git paths remain unchanged. Continue the
original runs without restart. No Classic208, duplicate replay, full suite
or native job was launched. Partial clocks and wait maxima are not acceptance,
capacity or recovery proof. Network208V2 remains unaccepted/uninstalled.
No gameplay change or new playtest is due; continuation remains active.

27 October 15:27 — original candidate30 V2 runs remain active.

At 15:27:26, baseline 21528/21596 reaches 14:00, 77/208, peak 34,
maximum wait 41.0m; delayed 21816/8612 reaches 18:50, 113/208, peak 36,
maximum wait 40.9m. Both original commands and parent identities match
launch59bdb842; errors are empty and neither final audit exists. Both source
packs, six observers and frozen Git paths remain unchanged. Continue the
original runs without restart. No Classic208, duplicate replay, full suite
or native job was launched. Partial clocks and wait maxima are not acceptance,
capacity or recovery proof. Network208V2 remains unaccepted/uninstalled.
No gameplay change or new playtest is due; continuation remains active.

27 October 15:43 — candidate 30 original V2 delayed run rejected; baseline continues.

The original delayed wrapper 21816/child 8612 finished naturally with M072 at
its booked Eraniel/ERL call at 19:14:14, 116/208 complete, peak 41, maximum 2702s
in BOTH wait populations. Zero safety events and empty run, summary and both
inspection errors follow the configured 600s K1 hold at 07:30. At 15:42:31 the
original baseline 21528/21596 reaches 17:00, 106/208, peak 34, maxwait 41.0m,
with empty errors and no final audit. Its original command/parent identity
matches launch 59bdb842. Runtime/routes/packs/six observers remain frozen.

Evidence in network-candidate-thirty/failed-predictive-delayed preserves 17
exact raw files, lossless audit/traffic/failure, exact V2 pack, actual final
summary and two byte-immutable inspections: initial KZT and final ERL.
All 4836 distinct source hashes match current-at-run candidate d82d37ed.
Original outputs remain. Never rerun this unchanged rejected test or relabel
these fingerprints after a later candidate changes sources. No installation.

All-location cumulative 347/452, 414/452, 441/452, 451/452 fails under 30/45
minutes; 441/452 is below 98%, never round up. Station-only 172/245, 221/245,
238/245, 244/245 also fails under 30/45 minutes. Every passing fraction applies
only to this failed prefix. M072 arrived ERL at 18:27:15.30 with no departure;
its current signal is ERL-N2. This IS a booked station wait. Its 2702s comprises
1826s opposing traffic (L027 416s, M103 658s, M049 668s, S051 84s), 838s compatible KZT
receiving and 38s route conflicts (L027 14s, M103 12s, M049 12s). Preserve receiving
buckets without individual attribution: 190s M103, 198s M065, 162s M049, 38s combined
M049/M065, 146s combined S051/M065, 104s approaching M065/S051.

Actual KZT claims are S051 P1 / M065 P2; actual ERL claims are M072 P2 and incoming
S051 P1/P3 alternatives, not simultaneous reservations. M072 awaits S051 in
KZT_single. S051 left KZT at 19:12:55.75 and moves at 16.2631m/s with authority toward
ERL. M065 has no KZT departure and waits for S051's planned overtake. M054 waits
for M072's ERL_P2 block, V008 waits behind M054 and M098 behind V008; M090 moves
north from NCJ. S049 moves south toward PASA, S053 toward NEM; M081 awaits its
19:40 departure. L028/L030/L038 are not yet due. Both inspections have identical
before/after captures and no future clearance plans. This does not establish
permanent deadlock or a runtime defect.

M097 left PASA at 17:38:48.25 and continued beyond the southern boundary with
portal arrival 18:19:39.30. M103 also continued beyond it at 19:13:21.00. L027 is
in NCJ depot after passenger arrival 18:58:18.15. M049 moves toward NCJ after
ERL departure 19:07:18.75. These local observations are not whole-day improvement,
capacity or recovery proof. M052/M066/M070/M102/S036/S038 and northern M015/M021/
S017/V003/S033/M053 move. M025 awaits S035's ALLP depot-access block; L010 moves
empty toward ERS depot after passenger arrival 19:09:36.00, not yet stabled.
M020/S034/S018/M068/S014 continued beyond the northern boundary; M101/V007
remain beyond the southern boundary. M051/M082 remain in NCJ/TVC depots after
16:03:15.90/15:16:03.65 passenger arrivals; K1/L025 remain in NCJ depot after
13:31:09.15/13:11:10.65 arrivals.

Eleven K1 minute samples show 27.4545764399m braking by 07:31, then unchanged
recorded extents through 07:40. These are not exact controller frames or recovery
proof. The actual final summary records one V001 overtake of K1 at TVCN, not
completed multiple-location evidence. No complete-population comparison,
recovery certificate or installation was performed. Wait for the original
baseline before departure-only replanning around opposing groups, compatible
receiving roads and full-tail clearance. No duplicate replay, Classic208,
full suite or native job was launched. Unchanged runtime/tests retain the
completed 1003-test suite and candidate 30's four passing authoring guards.
Network208V2 remains unaccepted/uninstalled; feasibility within all gates and
ETA remain unproven. No new gameplay playtest until an accepted V2 installation.

27 October 15:47 — original candidate 30 V2 baseline continues.

At 15:47:33, baseline 21528/21596 reaches 18:10, 111/208 complete,
peak 34 and maximum wait 41.0m, with empty errors and no final audit.
Its original command and parent identities match launch 59bdb842. Both source
packs, six observers and frozen Git paths remain unchanged. Original delayed
21816/8612 remains rejected in feb07f44: M072 at its booked ERL call, 19:14:14,
116/208, zero safety events and failed 30/45-minute gates in both wait populations.
Its exact evidence is preserved; no replay was restarted. Wait for the original
baseline before departure-only replanning. No Classic208, duplicate replay,
full suite or native job was launched. This partial baseline is not acceptance,
capacity or recovery proof. Network208V2 remains unaccepted/uninstalled.
No gameplay change or new playtest is due; continuation remains active.

27 October 15:59 — candidate 30 original V2 baseline rejected; both original runs ended.

The original baseline wrapper 21528/child 21596 finished naturally with M072
at its booked Eraniel/ERL call at 19:14:14, 116/208 complete, peak 41, maximum
2702s in BOTH wait populations. Zero safety events and empty run, summary and
both inspection errors; no manual hold. Original delayed 21816/8612 is already
rejected in feb07f44. No original30 process remains; neither test was restarted.
Runtime/routes/packs/six observers remained unchanged throughout both runs.

Evidence in network-candidate-thirty/failed-predictive-baseline preserves 17
exact raw files, lossless audit/traffic/failure, exact V2 pack, actual final
summary and two byte-immutable inspections: initial KZT and final ERL.
All 4836 distinct source hashes match current-at-run candidate d82d37ed.
Original outputs remain. Never rerun unchanged, relabel these fingerprints
after a later source change or install either failed result.

All-location cumulative 348/468, 427/468, 456/468, 467/468 fails under 30/45
minutes; 456/468 is below 98%, never round up. Station-only 186/264, 240/264,
259/264, 263/264 fails under 45 minutes. Every passing fraction applies only
to this failed prefix. Matching failure clocks/counts do not establish equal
populations or whole-day performance; baseline and delayed wait populations
differ. No complete-population comparison, recovery certificate or installation.

M072 arrived ERL at 18:27:15.30 with no departure; current signal ERL-N2.
This IS a booked station wait. Its 2702s comprises 1896s opposing traffic
(L027 416s, M103 658s, M049 668s, S051 146s, combined S051/M065 8s), 768s
compatible KZT receiving and 38s route conflicts (L027 14s, M103 12s, M049 12s).
Receiving buckets: 190s M103, 198s M065, 92s M049, 108s combined M049/M065,
146s combined S051/M065 and 34s approaching M065/S051. Preserve combined
buckets without attributing them to individual trains.

Actual KZT claims M065 P2; ERL claims M072 P2, incoming M065 P1 and incoming
S051 P1/P3 alternatives, not simultaneous reservations. M072 awaits S051/M065
in KZT_single. S051 left KZT19:11:45.75 and moves23.7262m/s toward ERL with
authority. M065 left KZT19:14:10.75 and moves0.4589m/s with authority toward
KZT_PYD_M0-SA. M054 waits for M072's ERL_P2 block, V008 behind M054, M098 behind
V008; M090 moves from NCJ. S049/S053 move south; M081 awaits19:40 departure,
L028/L030/L038 are not due. Both inspections preserve byte-identical captures
and no future clearance plans. No permanent-deadlock or runtime-defect inference.

M097 left PASA17:29:10.25 and continued beyond the southern boundary with portal
arrival18:10:01.30; M103 portal arrival19:13:21.00. L027 is in NCJ depot after
18:58:18.15 passenger arrival. M049 moves toward NCJ after ERL19:07:18.75 departure.
M052/M066/M070/M102/S036/S038 and northern M015/M021/S017/V003/S033/M053 move.
M025 awaits S035's ALLP depot-access block; S035 moves16.2667m/s with authority.
L010 moves empty toward ERS depot after19:09:36.00 arrival, not yet stabled.
M020/S034/S018/M068/S014 continued beyond the northern boundary; M101/V007
beyond the southern boundary. M051/M082 remain in NCJ/TVC depots after
16:03:15.90/15:13:39.30 arrivals; K1/L025 in NCJ depot after12:46:12.65/13:14:56.65.
These local observations are not whole-day improvement, capacity or recovery
proof. The actual baseline summary records no K1 overtakes.

Both original30 results are rejected. The delayed evidence retains its 17 exact
raw files, 4836 current-at-run source hashes and two immutable inspections.
Next: coordinated departure-only planning using both actual queues, opposing
groups, compatible receiving roads and full-tail clearance. No duplicate,
Classic208, unchanged full suite or native job was launched. Runtime/tests
retain the completed 1003-test suite and candidate30's four passing authoring
guards. Network208V2 remains unaccepted/uninstalled; feasibility and ETA remain
unproven. No gameplay playtest until an accepted V2 installation.

27 October 16:09 — candidate31 authors twenty-three southern departures after both original30 V2 failures.

Only these departure strings change from candidate30:
M072 18:05 -> 18:50; M054 18:20 -> 19:05; M098 18:50 -> 19:20; M090 19:05 -> 19:35; M104 19:20 -> 19:50; M088 19:35 -> 20:05; M058 19:50 -> 20:20; M056 20:05 -> 20:35; L028 20:20 -> 20:50; L030 20:40 -> 21:10; L038 21:00 -> 21:30; L032 21:20 -> 21:50; S051 18:30 -> 19:30; S049 18:50 -> 19:50; S053 19:10 -> 20:10; M081 19:40 -> 20:40; M085 20:00 -> 21:00; M087 20:20 -> 21:20; M083 20:40 -> 21:40; M091 21:00 -> 22:15; M073 21:10 -> 22:30; M089 21:20 -> 22:45; L037 21:00 -> 23:15.
Restoring them recovers each entire predecessor JSON object. Every non-departure
field is unchanged, both common-author packs retain identical service records,
and K1 remains06:00. All northern origins remain at candidate29 values. Retain
S03817:50 and V00818:35, M07016:30, M09715:30, L02715:00, M10315:20 and all earlier
southern departures. Through M04914:15/M06514:30/M05315:40 remain constraints.

Both actual30 runs fail M072 at its booked ERL call at19:14:14,116/208,peak41,
maximum2702s in both wait populations, zero safety and empty errors. Actual KZT
full-rake axis overlaps are L02718:23:42–18:36:08, M10318:40:36–18:50:30 and
M04918:55:10–19:05:10 in both. S051 overlaps from19:12:50 baseline/19:14:00 delayed
to failure (right-censored). These are observations, NOT candidate31 predictions.
M065 waits for S051's planned overtake; baseline leavesKZT19:14:10.75, delayed
has no departure. Baseline M072 waits1896s opposing+768s receiving+38s conflicts;
delayed1826s opposing+838s receiving+38s conflicts. Combined reason buckets remain
preserved without individual attribution.

The hypothesis retains faster V00818:35 to lead M07218:50/M05419:05 and following
northbound mails through20:35; the following locals move together20:50–21:50.
This moves M072 away from the recorded L027/M103/M049 opposing group. Delaying
TVC S051/S049/S053 to19:30/19:50/20:10 aims to let M065 seek KZT clearance without
its actual30 S051 overtake and leave receiving space for the northbound group.
Following TVC mails move20:40–21:40, then M091/M073/M08922:15/22:30/22:45 behind
retained S05522:05; L03723:15 follows those mails and retained S04123:00. This
coordinates the later group instead of replenishing the earlier queue. Retained
M053, later through services, M09919:35, S04021:40, opposing M06222:35/M04222:55/
S04423:05 and S04323:55 remain constraints. Origin gaps do NOT guarantee crossing
order, compatible receiving roads, full-tail clearance, escape or capacity.
Later waits, overtakes, local delays, origin queues and midnight completion remain
unproven; shifting these starts later is not evidence of whole-day improvement.

208 services retain40local/104mail/56superfast/8VB and168 boundary journeys.
There are now75 overnight origins (previously71), with3–13 starts/hour. All205
overrides reproduce both packs normally and exact --check. All four headless
authoring guards pass with empty errors. Runtime/tests/six observers are unchanged
from the completed1003-test candidate10 suite; no unchanged full-suite rerun.
Common-author consistency is not Classic208 readiness. V2 pack SHA256 is
65f9f73256c87db2f42713fad50d2ff16e89607d08b135bc00beb43cf6e07089.
Twelve exact raw authoring proofs and hashes are retained here; exact predecessors
remain in candidate-thirty-one-before. Staged bytes, both pack hashes and override
JSON must be verified before commit/push. A local preparation helper initially
stopped after writing overrides because its Python namespace reused a path variable;
the guard helper was then prepared before authoring. No rejected source draft or
replay exists; earlier hourly arithmetic alternatives were discarded in memory.

sampled-groups.json/sample-groups.py preserve actual30 continuous full-rake axis
overlap intervals from11:00 to each failure, bounds, source/report hashes, formula,
about2s sampling and censoring. Southern bounds remain from23; ALLP–AMPA uses
report centers with half-width+200m exclusion. These are planning inputs only,
not exact interlocking ownership, assigned roads, guaranteed gaps or full-day proof.
No isolated-model score or whole-day improvement claim.

Original30 baseline8b0c7c47 and delayedfeb07f44 retain17+17 exact raw files,
4836 verified current-at-run source hashes each, lossless reports/exact packs,
actual summaries and four byte-immutable inspections. Their fingerprints are now
HISTORICAL after candidate31; never relabel, rerun unchanged or install. Baseline
all348/468,427/468,456/468,467/468 fails30/45; station186/264,240/264,259/264,263/264
fails45. Delayed all347/452,414/452,441/452,451/452 fails30/45; station172/245,
221/245,238/245,244/245 fails30/45. Passing fractions apply only to failed prefixes;
matching failure clocks and counts do not equate the populations. No complete
population comparison, recovery certificate or installation. Both original30 runs
ended naturally before source changes. No Classic208/full-suite/native job launched.
Network208V2 remains unaccepted/uninstalled, feasibility and ETA unproven. Next:
commit/push the verified candidate, launch exactly one baseline and one delayed V2
run in a new generation, verify actual identities/options/source hashes and freeze
inputs until both original31 runs end. No gameplay playtest until accepted V2 install.

27 October 16:11 — candidate31 V2 launch verified; frozen inputs.

Candidate91969531 was committed/pushed after exact normal author reproduction,
--check, all four headless authoring guards and staged verification of twelve raw
proofs, both pack hashes and override JSON. Exactly two V2 runs launched once at
16:10:11/16:10:12 in rehearsals-v31: baseline wrapper2108/child24676 with
--network --snapshots; delayed wrapper13884/child3528 with --network --delay=600
--delay-at=27000. All four actual commands/options, unique outputs, the ORIGINAL
predictive baseline catalogue,4836 distinct source hashes and six observer hashes
were verified. The original catalogue existed before verification; no failed
verification attempt, duplicate or restart. Five exact staged launch files plus
their hash manifest preserve process/source evidence.

At16:10:50 baseline reaches00:10 and delayed00:30, both0/208; original process
pairs match, errors are empty and neither final audit exists. Partial clocks
are not acceptance. Runtime/routes/packs/six observers remain frozen while either
original run lives. No Classic208, full-suite, native, search or diagnostic job
remains. The unchanged completed1003-test source suite and candidate31's four
passing authoring guards remain; no unchanged full-suite rerun.

Both original30 runs ended naturally and failed M072 bookedERL19:14:14,116/208,
peak41,max2702s both wait populations,zero safety. Baseline8b0c7c47 and delayed
feb07f44 preserve17+17 exact raw files,4836 current-at-run hashes each,lossless
reports/exact packs/actual summaries and four immutable inspections. These hashes
are HISTORICAL after candidate31; never relabel, rerun unchanged or install.
Baseline all348/468,427/468,456/468,467/468 fails30/45; station186/264,240/264,
259/264,263/264 fails45. Delayed all347/452,414/452,441/452,451/452 fails30/45;
station172/245,221/245,238/245,244/245 fails30/45. Passing fractions apply only to
failed prefixes. Matching clocks/counts do not equate populations. No complete
population comparison, recovery certificate or installation.

Next: inspect the two original31 final reports against every completion, safety,
wait, physical and recovery gate. Network208V2 remains unaccepted/uninstalled;
no gameplay playtest until a passing V2 installation. Continuation remains active;
feasibility and completion ETA remain unproven. Do not rerun launch-network-v31.ps1.

27 October 16:13 — original candidate31 V2 runs continue; inputs remain frozen.

At16:13:31 baseline2108/24676 reaches01:10,0/208,peak12,maxwait0.1m;
delayed13884/3528 reaches01:50,1/208,peak16,maxwait6.1m. Both original process
pairs and commands match launcha01417ed, errors are empty and neither final audit
exists. Current V2 pack and all six observer hashes match their launch proof.
These are partial clocks, not acceptance or recovery evidence. No source change,
new replay, Classic208, native or unchanged full-suite job was launched.

Next: inspect the original31 final reports when they finish naturally; keep
runtime/routes/packs/six observers frozen meanwhile. Preserve historical30 failures
8b0c7c47/feb07f44 without relabelling their hashes. Network208V2 remains unaccepted
and uninstalled. No gameplay playtest until accepted V2 installation. Continuation
remains active, with feasibility and completion ETA unproven.

27 October 16:24 — original candidate31 runs continue without errors.

At16:23:54 baseline2108/24676 reaches03:30,2/208,peak25,maxwait7.4m;
delayed13884/3528 reaches04:30,10/208,peak29,maxwait9.3m. All four original
process IDs, parents and complete commands match launcha01417ed. Both error logs
are empty and no final audit exists. Runtime/tests/routes/packs/six observers
remain unchanged since candidate91969531. Partial progress is not acceptance;
the delayed run has not yet reached its configured07:30 K1 hold.

No replay was duplicated or restarted; no Classic208, native or unchanged test
suite was launched. Continue inspecting the original31 final reports when ready,
keeping frozen inputs unchanged. Network208V2 remains unaccepted/uninstalled,
with no gameplay playtest until a passing V2 installation and no reliable ETA.

27 October 16:37 — original candidate31 V2 runs remain active.

At16:37:05 baseline2108/24676 reaches05:40,18/208,peak29,maxwait31.1m;
delayed13884/3528 reaches07:10,28/208,peak31,maxwait35.8m. All four original
process IDs, parents and complete commands match launcha01417ed. Both error logs
are empty and neither final audit exists. Runtime/tests/routes/packs/six observers
remain unchanged since candidate91969531. These partial clocks do not establish
acceptance; the delayed run has not yet reached its configured07:30 K1 hold.

Keep inputs frozen until both original31 runs finish naturally, then inspect
the actual final reports against all gates. No replay was duplicated or restarted;
no Classic208, native or unchanged suite was launched. Network208V2 remains
unaccepted/uninstalled. No gameplay playtest until accepted V2 installation;
feasibility and completion ETA remain unproven. Continuation remains active.

27 October 16:43 — original candidate31 V2 runs continue with frozen inputs.

At 16:43:29, baseline 2108/24676 reaches 06:30, 25/208 complete, peak31,
maximum wait31.1m; delayed 13884/3528 reaches 08:30, 36/208 complete, peak31,
maximum wait40.9m. All four original process IDs, parent IDs and complete commands
match launch a01417ed. Both error logs remain empty and neither final audit exists.
The delayed clock has passed its configured 07:30 hold interval; actual final
reports are still required to establish the disturbance and recovery outcome.

Runtime/tests/routes/packs and six observers remain unchanged since candidate
91969531. The V2 pack and all six observer hashes match launch. No replay was
duplicated or restarted; no Classic208, native or unchanged suite was launched.
Keep inputs frozen until both original31 runs end naturally. Partial progress is
not acceptance. Network208V2 remains unaccepted/uninstalled, with no gameplay
playtest until a passing V2 installation. Feasibility and ETA remain unproven.

27 October 16:53 — both original candidate31 V2 runs are still running.

At 16:53:38, baseline 2108/24676 reaches 08:10, 33/208 complete, peak31,
maximum wait35.8m; delayed 13884/3528 reaches 10:50, 60/208 complete, peak31,
maximum wait40.9m. All four original process IDs, parents and complete commands
match launch a01417ed. Error logs are empty and neither final audit exists.
Runtime/tests/routes/packs/six observers remain unchanged since candidate91969531.

Continue waiting for the original final reports with all inputs frozen. Partial
clocks and counts are not acceptance or recovery evidence. No duplicate/restart,
Classic208, native or unchanged full-suite job was launched. Network208V2 remains
unaccepted/uninstalled; no gameplay playtest until a passing V2 installation.
Continuation remains active; feasibility and completion ETA remain unproven.

27 October 17:03 — original candidate31 V2 runs remain active without errors.

At 17:03:25, baseline 2108/24676 reaches 09:40, 49/208 complete, peak31,
maximum wait35.8m; delayed 13884/3528 reaches 13:00, 69/208 complete, peak32,
maximum wait40.9m. All four original process IDs, parents and complete commands
match launch a01417ed. Both error logs are empty and neither final audit exists.
Runtime/tests/routes/packs/six observers remain unchanged since candidate91969531.

These are partial runs, not acceptance or recovery certificates. Keep inputs
frozen until both original31 runs end naturally, then inspect every final gate.
No replay was duplicated or restarted; no Classic208, native or unchanged suite
was launched. Network208V2 remains unaccepted/uninstalled; no gameplay playtest
until a passing V2 installation. Continuation remains active, with feasibility
and completion ETA unproven.

27 October 17:16 — original candidate31 V2 runs continue; final reports remain pending.

At 17:16:08, baseline 2108/24676 reaches 11:50, 65/208 complete, peak31,
maximum wait40.1m; delayed 13884/3528 reaches 15:40, 95/208 complete, peak34,
maximum wait40.9m. All four original process IDs, parents and complete commands
match launch a01417ed. Both error logs are empty and neither final audit exists.
Runtime/tests/routes/packs/six observers remain unchanged since candidate91969531.

Keep inputs frozen until both original31 runs end naturally, then inspect every
final gate. These partial clocks and counts are not acceptance or recovery proof.
No duplicate, restart, Classic208, native or unchanged suite job was launched.
Network208V2 remains unaccepted/uninstalled; no gameplay playtest until a passing
V2 installation. Continuation remains active; feasibility and ETA are unproven.

27 October 17:23 — both original candidate31 V2 runs remain active.

At 17:23:31, baseline 2108/24676 reaches 12:50, 69/208 complete, peak33,
maximum wait40.1m; delayed 13884/3528 reaches 17:10, 108/208 complete, peak34,
maximum wait40.9m. All four original process IDs, parents and complete commands
match launch a01417ed. Both error logs are empty and neither final audit exists.
Runtime/tests/routes/packs/six observers remain unchanged since candidate91969531.

Inputs remain frozen until both original31 runs end naturally. Final completion,
safety, both wait populations, physical clearance and recovery still require
inspection; partial progress is not acceptance. No duplicate, restart, Classic208,
native or unchanged suite job was launched. Network208V2 remains unaccepted and
uninstalled, with no gameplay playtest until a passing V2 installation.
Continuation remains active; feasibility and completion ETA remain unproven.

27 October 17:33 — original candidate31 V2 runs continue with frozen inputs.

At 17:33:24, baseline 2108/24676 reaches 14:10, 78/208 complete, peak34,
maximum wait41.0m; delayed 13884/3528 reaches 19:00, 113/208 complete, peak34,
maximum wait40.9m. All four original process IDs, parents and complete commands
match launch a01417ed. Both error logs are empty and neither final audit exists.
Runtime/tests/routes/packs/six observers remain unchanged since candidate91969531.

Keep inputs frozen until both original31 runs end naturally. Inspect every final
completion, safety, wait, physical and recovery gate when reports are available;
these partial runs establish no acceptance. No replay was duplicated or restarted,
and no Classic208, native or unchanged suite job was launched. Network208V2
remains unaccepted/uninstalled, with no gameplay playtest until a passing V2
installation. Continuation remains active; feasibility and ETA remain unproven.

27 October 17:48 — candidate31 original V2 delayed run rejected; baseline continues.

The original delayed wrapper13884/child3528 finished naturally with M025 at its
booked Alappuzha/ALLP call at19:35:06,118/208 complete,peak36,maximum2702s in
BOTH wait populations. Zero safety events and empty run,summary and both
inspection errors follow the configured600s K1 hold at07:30. At17:47:24 the
original baseline2108/24676 reaches16:50,105/208,peak34,maxwait41.0m,with empty
errors and no final audit. Its original identity matches launch a01417ed.
Runtime/routes/packs/six observers remain frozen while the original baseline lives.

Evidence in network-candidate-thirty-one/failed-predictive-delayed preserves17
exact raw files,lossless audit/traffic/failure,exact V2 pack,actual final summary
and two byte-immutable inspections: initial AMPA and final ALLP. All4836 distinct
source hashes match current-at-run candidate91969531. Original outputs remain.
Never rerun this rejected test unchanged or relabel these fingerprints after a
later source change. No acceptance or installation.

All-location cumulative355/459,423/459,449/459,458/459 fails under30/45 minutes;
449/459 is below98%,never round up. Station-only176/250,227/250,243/250,249/250
also fails under30/45 minutes. Passing fractions apply only to this failed prefix.
M025 arrived ALLP18:48:02.05 with no departure,current signal ALLP-S3. This IS a
booked station wait. Its2702s comprises1032s overtakes (516 each S017/S035),804s
compatible AMPA receiving,586s opposing M052,214s blocks and66s route conflicts.
Receiving buckets:168 unnamed,84 combined S035/M052,84 M052,186 approaching S035,
172 approaching S017 and110 approaching M021. Preserve combined buckets without
individual attribution. The conflict buckets are48 M067 and18 combined M052/M067.

Actual AMPA claims S036P2,approaching M066P3 and incoming M067P1. Actual ALLP
claims M052P2/M025P3. M025 awaits M067's ALLP_PUPR_M0 block;M067 left ALLP19:33:04.75
and moves20.1973m/s with authority toward AMPA. M052 arrived ALLP19:33:43.85 and
dwells until19:35:43. S036 awaits M067 in ALLP_single;M066 approaches at24.6m/s.
S017 left ALLP19:00:01.25 and S03519:12:39.75,both moving south. M015/M021/M057/
S019/S033/L003 move;M069 waits behind M057's SRTL block. L011/L009 are not due.
Both inspections have identical before/after captures and no future clearance
plans. This does not establish permanent deadlock or a runtime defect.

M072 now leaves ERL19:27:20.25 and moves toward KZT;M054 leaves ERL19:31:48.75.
M065 leaves KZT19:15:59.75 and ERL19:29:19.30,moving toward NCJ. These local
movements are NOT whole-day improvement,capacity or recovery proof. V008 waits
at NYY for M053,which moves south after TVC19:23:16.25 departure. S051 awaits a
clear TVC origin;S049/S053/M081 and L028/L030/L038 are not due. M098/M090 move.
V003 awaits L029's TVP block;L029 moves12.1775m/s with authority toward TVC.
M097/M103 remain beyond the southern boundary,portal arrivals18:19:39.30/19:13:21.
M049/L027 are in NCJ depot after passenger arrivals19:22:19.10/18:58:18.15.
L010 is now in ERS depot after19:09:36 arrival. M051/M082 remain in NCJ/TVC depots
and K1/L025 in NCJ depot after13:31:09.15/13:11:10.65 passenger arrivals.

Eleven K1 minute samples show27.4545764399m braking by07:31,then unchanged
recorded extents through07:40. These are not exact controller frames or recovery
proof. The actual final summary records one V001 overtake of K1 at TVCN,not
completed multiple-location evidence. No complete-population comparison,recovery
certificate or installation. Wait for the original baseline before coordinated
departure-only replanning around opposing groups,compatible roads and full-tail
clearance. No duplicate,restart,Classic208,full-suite or native job was launched.
Unchanged runtime/tests retain the completed1003-test suite and candidate31's
four passing authoring guards. Network208V2 remains unaccepted/uninstalled;
feasibility and ETA remain unproven. No gameplay playtest until accepted V2 install.

27 October 17:53 — original candidate31 V2 baseline continues with frozen inputs.

At 17:53:32, original baseline 2108/24676 reaches 18:10, 111/208 complete,
peak 34 and maximum wait 41.0m. Both original process IDs, parents and full
commands match launch a01417ed; the error log is empty and no final audit exists.
The V2 pack and six observer hashes match launch, and frozen Git inputs remain
unchanged. This partial progress is not acceptance or recovery proof.

Original delayed 13884/3528 remains rejected in f4fc8b9d: M025 booked ALLP at
19:35:06, 118/208, zero safety events, with both wait populations failing 30/45
minutes. Its 17 exact raw files, 4836 current-at-run source hashes and two
immutable inspections remain preserved; never rerun unchanged or install.
Wait for the original baseline before coordinated departure-only replanning.
No duplicate, restart, Classic208, native or unchanged suite job was launched.
Network208V2 remains unaccepted/uninstalled; no gameplay playtest until a passing
V2 installation. Continuation stays active; feasibility and ETA remain unproven.

27 October 18:03 — original candidate31 V2 baseline remains active.

At 18:03:19, original baseline 2108/24676 reaches 19:50, 121/208 complete,
peak 36 and maximum wait 42.5m. Both original process IDs, parents and full
commands match launch a01417ed; the error log is empty and no final audit exists.
The V2 pack and six observer hashes match launch, and frozen Git inputs remain
unchanged. Passing the delayed run's failure clock does not establish acceptance,
whole-day improvement, equal populations or recovery.

Original delayed 13884/3528 remains rejected in f4fc8b9d: M025 booked ALLP at
19:35:06, 118/208, zero safety events, with both wait populations failing 30/45
minutes. Its 17 exact raw files, 4836 current-at-run source hashes and two
immutable inspections remain preserved; never rerun unchanged or install.
Wait for the original baseline before coordinated departure-only replanning.
No duplicate, restart, Classic208, native or unchanged suite job was launched.
Network208V2 remains unaccepted/uninstalled; no gameplay playtest until a passing
V2 installation. Continuation stays active; feasibility and ETA remain unproven.

27 October 18:15 — candidate31 original V2 baseline rejected; both original runs ended.

The original baseline wrapper2108/child24676 finished naturally with M102 at its
booked Ambalappuzha/AMPA call at20:31:58,123/208 complete,peak41,maximum2702s in
BOTH wait populations. Zero safety events and empty run,summary and all three
inspection errors; no manual hold. Original delayed13884/3528 is already rejected
in f4fc8b9d. No original31 process remains; neither test was restarted.
Runtime/routes/packs/six observers remained unchanged throughout both runs.

Evidence in network-candidate-thirty-one/failed-predictive-baseline preserves20
exact raw files,lossless audit/traffic/failure,exact V2 pack,actual final summary
and three byte-immutable inspections: initial ALLP,initial AMPA,and final AMPA
including its actual claimant L004. All4836 distinct source hashes match
current-at-run candidate91969531. Original outputs remain. Never rerun unchanged,
relabel these fingerprints after a later source change,or install either result.

All-location cumulative395/530,483/530,517/530,529/530 fails under30/45 minutes;
517/530 is below98%,never round up. Station-only214/302,273/302,295/302,301/302
also fails under30/45;295/302 is below98%. Passing fractions apply only to this
failed prefix. Baseline and delayed populations differ; no complete-population
comparison,recovery certificate or installation.

M102 arrived AMPA19:45:45.15 with no departure,current signal AMPA-N2. This IS a
booked station wait. Its2702s comprises1270s opposing traffic (M067564,M069562,
S019144),1232s compatible ALLP receiving,130s S036 blocks and70s route conflicts
(S03644,M06712,M06914). Receiving buckets remain combined where recorded:
156M057,52M057/S036,86M067,82M067/M066,96M069/M057/M066,104M069/M066,
196S019/M057/S036,58approachingM057/S019,184approachingM057/S019/S036,
90approachingM067/M066/M069,128approachingM067/M069. Do not attribute combined
buckets to individual trains.

Actual ALLP claims M057P2/S036P3. Actual AMPA claims M102P2/L004P3/incomingS019P1.
M102 and L004 await S019 in ALLP_single. S019 left ALLP20:29:39.25 and moves
22.5786m/s with authority toward AMPA; M057 waits for S019's ALLP_PUPR_M0 block.
S036 awaits compatible MAKM receiving reported against M066/L003/L011; M066
waits at MAKM-N1 for opposing L003/L011 in SRTL_single. L003 approaches MAKM at
2m/s and L011 moves24.6m/s south from SRTL. M069 exchanges at HAD and M067 dwells
at KYJ. All three inspections have identical before/after captures and no future
clearance plans. This does not establish permanent deadlock or a runtime defect.

M025 leaves ALLP19:32:15.25 and AMPA19:44:17.75,then moves south toward QLN.
M072 leaves TVC20:20:35.75 and TVCN20:28:48.75; M054 approaches TVC. M065 has
continued beyond the southern boundary at19:48:12.30. V008 is in TVC depot after
passenger arrival19:54:29.05. These local movements are NOT whole-day improvement,
capacity or recovery proof. M052 leaves ERS20:31:57.25 and has authority toward
its portal but has NOT cleared it. M070 waits behind M102/L004 at AMPA. M098
waits NYY for S051,which moves south; M090 waits PASA for L029,which moves with
authority after NYY departure20:29:56.75. M104 waits KZT for opposing M053;
M053 left PASA20:28:27.25 and moves south. M088 waits ERL for KZT receiving.
S049/S053 await a clear TVC origin; later mails and L028 are not due. M015/M021/
S017/S035/L009 move; S033 awaits M054 at TVC. M097/M103 remain beyond the southern
boundary, M049/L027 in NCJ depot,L010 in ERS depot,M051/M082 in NCJ/TVC depots,
and K1/L025 in NCJ depot. The actual baseline summary records no K1 overtakes.

Both original31 results are rejected. Delayed evidence f4fc8b9d retains17 exact
raw files,4836 current-at-run hashes and two immutable inspections; its M025
bookedALLP failure at19:35:06 completes118/208 with zero safety and failed30/45
wait gates in both populations. Next: coordinated northern departure-group
planning using BOTH actual queues,opposing groups,compatible receiving roads and
full-tail clearance. No duplicate,Classic208,unchanged suite or native job was
launched. Runtime/tests retain the completed1003-test suite and candidate31's
four passing authoring guards. Network208V2 remains unaccepted/uninstalled;
feasibility and ETA remain unproven. No gameplay playtest until accepted V2 install.

27 October 18:23 — candidate32 authors ten northern departures after both original31 V2 failures.

Only these departure strings change from candidate31:
S019 19:00 -> 17:50; M025 17:25 -> 18:15; M067 18:15 -> 18:55;
M057 18:30 -> 19:10; M069 18:45 -> 19:25; M055 20:15 -> 19:45;
M059 20:25 -> 19:55; L003 19:20 -> 20:00; L011 19:40 -> 20:20;
L009 20:00 -> 20:40.
Restoring them recovers each entire predecessor JSON object. Every non-departure
field is unchanged,both common-author packs retain identical service records,
and K1 remains06:00. All southern origins and earlier northern origins remain
at candidate31 values; retain M01516:55/M02117:10,S01717:40/S03518:00.

Actual31 delayed M025 waits1032s for S017/S035 overtakes,804s compatible AMPA
receiving and586s opposing M052,plus214s blocks and66s conflicts. Actual31 baseline
M102 waits1270s opposing M067/M069/S019,1232s compatible ALLP receiving,130s S036
blocks and70s conflicts. These are different failed populations. Baseline actual
ALLP-AMPA full-rake axis overlaps are M02519:33:26-19:42:06,M06619:43:34-19:52:38,
M06719:54:32-20:02:46,M06920:07:26-20:15:40,S03620:17:00-20:26:04,S01920:30:42
until failure (right-censored). Delayed M052 overlaps19:24:14-19:32:46 followed by
M06719:34:08 until its failure. These are observations,NOT candidate32 predictions.
Baseline M066 waits at MAKM for L003/L011,which constrain S036's ALLP departure;
M102 and L004 occupy AMPA's northbound roads. Preserve finite compatible roads,
opposing groups and full-tail clearance rather than treating origin gaps as
capacity guarantees.

The hypothesis puts S01917:50 with retained S01717:40/S03518:00 ahead of M02518:15
to reduce its successive overtakes and remove S019's later opposing refill.
M06718:55/M05719:10/M06919:25 move after a40-minute origin gap following M025,
aiming to leave a clearance opportunity for M052/M066/S036/M102. M05519:45 and
M05919:55 join that mail group ahead of the locals. L003/L011/L009 move together
to20:00/20:20/20:40 to reduce their earlier opposing approach at MAKM while the
northbound group seeks receiving roads. Retained S02120:20,S02321:20 and mails
M03320:30/M02720:45/M03121:00/M02921:15/M03521:30 remain following/overtake
constraints. Advancing S019 may increase M015/M021's waits; later local waits,
origin queues,opposing services and midnight completion remain unproven. Origin
gaps do NOT guarantee crossing order,compatible receiving roads,full-tail
clearance,escape or capacity. No whole-day improvement claim.

208 services retain40local/104mail/56superfast/8VB,168 boundary journeys,
75 overnight origins and3-13 starts/hour. All205 overrides reproduce both packs
normally and exact --check. All four headless authoring guards pass with empty
errors. Runtime/tests/six observers are unchanged from the completed1003-test
candidate10 suite; no unchanged full-suite rerun. Common-author consistency is
not Classic208 readiness. V2 pack SHA256 is
466098a33f256b8a3bcc5a057b927780793137dd69e5456fbe586a57a3a32b2a.
Twelve exact raw authoring proofs and hashes are retained here; exact predecessors
remain in candidate-thirty-two-before. Verify staged bytes,both pack hashes and
override JSON before commit/push. In-memory hourly alternatives were discarded
before authoring; no rejected source draft or replay exists.

sampled-groups.json/sample-groups.py preserve actual31 continuous full-rake axis
overlap intervals from11:00 to each failure,bounds,source/report hashes,formula,
about2s sampling and censoring. Southern bounds remain from23; ALLP-AMPA uses
report centers with half-width+200m exclusion. Planning inputs only,not exact
interlocking ownership,assigned roads,guaranteed gaps,escape or full-day proof.
No isolated-model score or whole-day improvement claim.

Both original31 runs ended naturally before source changes and are rejected:
baseline e90c8ede M102 bookedAMPA20:31:58,123/208,peak41; delayed f4fc8b9d M025
bookedALLP19:35:06,118/208,peak36. Both have2702s maxima in BOTH wait populations,
zero safety and empty errors. Their20+17 exact raw files,4836 current-at-run hashes
each,lossless reports/exact packs/actual summaries and five immutable inspections
remain. These fingerprints are now HISTORICAL after candidate32; never relabel,
rerun unchanged or install. Baseline all395/530,483/530,517/530,529/530 and station
214/302,273/302,295/302,301/302 both fail30/45; delayed all355/459,423/459,449/459,
458/459 and station176/250,227/250,243/250,249/250 both fail30/45. Passing fractions
apply only to failed prefixes; no complete-population comparison,recovery
certificate or installation. Next: commit/push the verified candidate,launch
exactly one baseline and one delayed V2 run in a new generation,verify actual
identities/options/source hashes and freeze inputs until both original32 runs end.
No Classic208/full-suite/native job launched. Network208V2 remains unaccepted/
uninstalled,feasibility and ETA unproven. No gameplay playtest until accepted V2 install.

27 October 18:25 — candidate32 V2 launch verified; frozen inputs.

Candidate ddbeedb5 was committed/pushed after exact normal author reproduction,
--check,all four headless authoring guards and staged verification of twelve raw
proofs,both pack hashes and override JSON. Exactly two new V2 runs launched once
at18:24:21 in rehearsals-v32: baseline wrapper27304/child14984 with --network
--snapshots; delayed wrapper26020/child26688 with --network --delay=600
--delay-at=27000. All four actual commands/options,unique outputs,the ORIGINAL
predictive baseline catalogue,4836 distinct source hashes and six observer hashes
were verified. The original catalogue existed before verification; no failed
verification attempt,duplicate or restart. Five exact staged launch files plus
their hash manifest preserve process/source evidence.

At18:24:44 the baseline has no first progress line and delayed reaches00:20,0/208.
Both original process pairs match,errors are empty and neither final audit exists.
These partial clocks are not acceptance. Runtime/routes/packs/six observers remain
frozen while either original32 run lives. No Classic208,full-suite,native,search
or diagnostic job remains. The completed1003-test source suite is unchanged;
four passing authoring guards cover this departure-only candidate.

Both original31 runs ended naturally and failed: baseline e90c8ede M102 booked
AMPA20:31:58,123/208,peak41; delayed f4fc8b9d M025 bookedALLP19:35:06,118/208,
peak36. Both have2702s maxima in BOTH wait populations,zero safety,empty errors
and failed30/45 wait gates. Their20+17 exact raw files,4836 current-at-run hashes
each,lossless reports/exact packs/actual summaries and five immutable inspections
are HISTORICAL after candidate32. Never relabel,rerun unchanged or install.
Passing fractions apply only to failed prefixes. No complete-population
comparison,recovery certificate or installation.

Next: inspect both original32 final reports against every completion,safety,wait,
physical and recovery gate. Network208V2 remains unaccepted/uninstalled; no gameplay
playtest until a passing V2 installation. Continuation remains active; feasibility
and ETA are unproven. Do not execute launch-network-v32.ps1 again.

27 October 18:29 — original candidate32 V2 runs continue; inputs unchanged.

At18:29:35 the original baseline27304/14984 reaches01:40,1/208,peak14,maxwait6.1m;
the original delayed26020/26688 reaches02:30,1/208,peak21,maxwait6.1m. Both process
pairs retain their original launch identities,errors are empty and neither final
audit exists. These are partial clocks,not acceptance or a population comparison.
All4836 source hashes match the original candidate32 baseline catalogue; all six
observer hashes match launch2a53f9ed. Runtime/routes/packs/observers remain frozen.
No duplicate,restart,Classic208,full-suite,native or diagnostic job was launched.

Both candidate31 failures remain rejected and historical after candidate32;
their evidence and fingerprints are unchanged. Wait for the original32 final
reports before evaluating every completion,safety,wait,physical and recovery gate.
Network208V2 remains unaccepted/uninstalled. No gameplay playtest until accepted
V2 installation; feasibility and ETA remain unproven. Continuation remains active.

27 October 18:39 — original candidate32 V2 runs remain live.

At18:39:38 baseline27304/14984 reaches03:40,2/208,peak27,maxwait7.4m;
delayed26020/26688 reaches04:50,16/208,peak29,maxwait26.0m. Both original
command/parent identities match launch2a53f9ed,errors are empty,and neither
final audit exists. These are partial observations only. Runtime/routes/packs
remain unchanged from ddbeedb5 and all six observer hashes match their launch.
No duplicate,restart,Classic208,full-suite,native or diagnostic job was launched.
Continue waiting for both original final reports with inputs frozen; no acceptance,
installation or gameplay playtest. Network208V2 feasibility and ETA remain unproven.

27 October 18:51 — original candidate32 V2 runs remain live.

At 18:51:50 baseline 27304/14984 reaches 05:40, 18/208, peak 29, maximum wait
31.1m; delayed 26020/26688 reaches 07:10, 28/208, peak 31, maximum wait 35.8m.
Both original command/parent identities match launch 2a53f9ed, errors are empty,
and neither final audit exists. These partial observations are not acceptance.
Runtime/routes/packs remain unchanged from ddbeedb5 and all six observer hashes
match launch. Inputs remain frozen while either original run lives. No duplicate,
restart, Classic208, full-suite, native or diagnostic job was launched.
Network208V2 remains unaccepted/uninstalled; feasibility and ETA remain unproven.

27 October 18:59 — original candidate32 V2 runs continue with frozen inputs.

At 18:59:25 baseline 27304/14984 reaches 06:50, 26/208, peak 31, maximum wait
35.2m; delayed 26020/26688 reaches 08:50, 40/208, peak 31, maximum wait 40.9m.
Both original command/parent identities match launch 2a53f9ed, errors are empty,
and neither final audit exists. No additional Godot process is present.
Runtime/routes/packs remain unchanged from ddbeedb5; all six observer hashes
match launch. These partial observations do not establish any acceptance gate.
Continue awaiting both original final reports with inputs frozen. No duplicate,
restart, Classic208, unchanged full suite, native check or installation was run.
Network208V2 remains unaccepted/uninstalled; feasibility and ETA remain unproven.

27 October 19:09 — original candidate32 V2 runs remain live.

At 19:09:24 baseline 27304/14984 reaches 08:20, 34/208, peak 31, maximum wait
35.8m; delayed 26020/26688 reaches 11:20, 61/208, peak 31, maximum wait 40.9m.
Original command/parent identities match launch 2a53f9ed, both error logs remain
empty, and neither final audit exists. No additional Godot process is present.
Runtime/routes/packs remain unchanged from ddbeedb5 and six observer hashes match
launch. Keep inputs frozen until both original runs end; no duplicate, restart,
Classic208, unchanged full suite or native check was launched. Partial progress
is not acceptance, a complete-population comparison or recovery certification.
Network208V2 remains unaccepted/uninstalled; feasibility and ETA remain unproven.

27 October 19:19 — original candidate32 V2 runs remain live.

At 19:19:24 baseline 27304/14984 reaches 10:00, 51/208, peak 31, maximum wait
40.1m; delayed 26020/26688 reaches 13:10, 69/208, peak 34, maximum wait 40.9m.
Both original command/parent identities match launch 2a53f9ed, errors remain
empty, and neither final audit exists. No additional Godot process is present.
Runtime/routes/packs remain unchanged from ddbeedb5 and all six observer hashes
match launch. Keep inputs frozen until both original runs end. These partial
observations are not acceptance, a complete-population comparison or recovery
certification. No duplicate, restart, Classic208, unchanged full suite or native
check was launched. Network208V2 remains unaccepted/uninstalled; feasibility and
ETA remain unproven.

27 October 19:29 — original candidate32 V2 runs continue with frozen inputs.

At 19:29:17 baseline 27304/14984 reaches 11:40, 64/208, peak 31, maximum wait
40.1m; delayed 26020/26688 reaches 15:10, 90/208, peak 34, maximum wait 40.9m.
Both original command/parent identities match launch 2a53f9ed, errors are empty,
and neither final audit exists. No additional Godot process is present.
Runtime/routes/packs remain unchanged from ddbeedb5; all six observer hashes
match launch. Inputs remain frozen until both original runs end. Partial clocks
and counts do not establish acceptance, complete-population comparison or
recovery. No duplicate, restart, Classic208, unchanged full suite or native check
was launched. Network208V2 remains unaccepted/uninstalled; feasibility and ETA
remain unproven.

27 October 19:39 — original candidate32 V2 runs remain live.

At 19:39:20 baseline 27304/14984 reaches 13:00, 70/208, peak 33, maximum wait
40.1m; delayed 26020/26688 reaches 17:30, 108/208, peak 34, maximum wait 40.9m.
Both original command/parent identities match launch 2a53f9ed, errors remain
empty, and neither final audit exists. No additional Godot process is present.
Runtime/routes/packs remain unchanged from ddbeedb5 and all six observer hashes
match launch. Keep inputs frozen until both original runs end. Partial progress
is not acceptance, complete-population comparison or recovery certification.
No duplicate, restart, Classic208, unchanged full suite or native check was
launched. Network208V2 remains unaccepted/uninstalled; feasibility and ETA remain
unproven.

27 October 19:49 — original candidate32 V2 runs remain active.

At 19:49:22 baseline 27304/14984 reaches 14:20, 80/208, peak 34, maximum wait
41.0m; delayed 26020/26688 reaches 19:20, 117/208, peak 34, maximum wait 40.9m.
Both original command/parent identities match launch 2a53f9ed, errors remain
empty, and neither final audit exists. No additional Godot process is present.
Runtime/routes/packs remain unchanged from ddbeedb5 and all six observer hashes
match launch. Keep inputs frozen until both original runs end. These partial
observations do not establish acceptance, whole-day improvement or recovery.
No duplicate, restart, Classic208, unchanged full suite or native check was
launched. Network208V2 remains unaccepted/uninstalled; feasibility and ETA remain
unproven.

27 October 20:02 — candidate32 original V2 delayed run rejected; baseline continues.

The original delayed wrapper26020/child26688 finished naturally with S035 at
its booked Alappuzha/ALLP call at19:52:26,122/208 complete,peak35,maximum2702s
in BOTH wait populations. Zero safety events and empty run,summary and both
inspection errors follow the configured600s K1 hold at07:30. At20:01:55 the
original baseline27304/14984 reaches16:50,105/208,peak34,maxwait41.0m,with empty
errors and no final audit. Its original command/parent identity matches launch
2a53f9ed. Runtime/routes/packs/six observers remain frozen and unchanged.

Evidence in network-candidate-thirty-two/failed-predictive-delayed preserves17
exact raw files,lossless audit/traffic/failure,exact V2 pack,actual final summary
and two byte-immutable inspections: initial AMPA and final ALLP. All4836 distinct
source hashes match current-at-run candidateddbeedb5. Original outputs remain.
Never rerun this rejected test unchanged or relabel these fingerprints after a
later source change. No acceptance or installation.

All-location cumulative370/473,437/473,462/473,472/473 fails under30/45 minutes;
462/473 is below98%,never round up. Station-only186/259,236/259,251/259,258/259
also fails under30/45 minutes. Passing fractions apply only to this failed
prefix. S035 arrived ALLP19:05:23.60 with no departure,current signal ALLP-S3.
This IS a booked station wait. Its2702s comprises1252s compatible AMPA receiving,
1122s opposing traffic,208s blocks and120s route conflicts. Opposing buckets:
586M052,142S036,294combinedM066/S036 and100combinedS036/M066. Receiving buckets:
212unnamed,36combinedM025/S036/M066,186M052,36combinedM021/M052,
198combinedS036/M066,84S019,186approachingM021,90approachingS036/M025,
96approachingS036/M066/M025 and128approachingS019. Preserve combined buckets
without individual attribution. Blocks106M021,90M025,12M052; conflicts52M021,
48M025 and20combinedM052/M025. No overtake reason is recorded in this failed wait.

Actual AMPA claims L004P2/M102P3. Actual ALLP claims S036P1/S035P3 plus incoming
M066P1/P2/P3 alternatives,not simultaneous reservations. S035 awaits S036/M066
in ALLP_single. S036 approaches ALLP at16.2668m/s; M066 moves north at24.6m/s
after AMPA departure19:45:57.75 with authority toward ALLP. L004 arrived AMPA
19:46:34.50 and awaits M102's planned overtake; M102 arrived19:50:32 and awaits
ALLP receiving reported against S036/S035/M066. M052 left ALLP19:36:41.75 and
waits at MAKM-N3 for opposing M067. M067 waits at TRVZ_MAKM_M3-SH to preserve
ALLP crossing capacity for S036/M066/M052; M057 waits at SRTL for S036/M066.
Both inspections preserve identical before/after captures and no future clearance
plans. These observations do not establish permanent deadlock or a runtime defect.

M025 now leaves ALLP19:33:57.75 and AMPA19:45:27.75,moving south at27.3778m/s.
S017 left ALLP18:48:17.25 and exchanges at QLN; S019 left ALLP19:03:54.25 and
KYJ19:36:12.25,moving south. M021 left ALLP19:14:21.75 and AMPA19:25:55.25,now
exchanging at KYJ. M015 moves beyond QLN; M069/M070 move, M055 has departure
horns with brakes held and authority at ERS. M059,L003/L011/L009,S021/S023 are
not due. M025 clearing the earlier failed area does NOT establish whole-day
improvement,capacity or recovery: another service now fails and the populations
differ. No complete-population comparison is appropriate.

M072 left PASA19:51:32.25 and moves north; M054 waits at KZT for PASA receiving
reported against M053/M072. M053 arrived PASA19:52:10.25 and exchanges; M098/M090/
M104 move. S051 waits TVC for opposing V008,which approaches TVC at22.3624m/s.
S049 awaits a clear TVC origin; S053/M081/L028 are not due. V003 is in the TVC
south depot after passenger arrival19:43:55.60. M065 has continued beyond the
southern boundary at19:48:12.30; M097/M103 remain beyond it after18:19:39.30/
19:13:21 arrivals. M049/L027 remain in NCJ depot after19:22:19.10/18:58:18.15
passenger arrivals,L010 in ERS depot after19:09:36,M051/M082 in NCJ/TVC depots
after16:03:15.90/15:16:03.65,and K1/L025 in NCJ depot after13:31:09.15/13:11:10.65.
These local observations are not full-day completion or recovery evidence.

Eleven K1 minute samples show27.4545764399m braking by07:31,then unchanged
recorded extents through07:40. These are not exact controller frames or recovery
proof. The actual final summary records one V001 overtake of K1 at TVCN,not
completed multiple-location evidence. No recovery certificate or installation.
Wait for the original baseline before coordinated departure-only replanning
around opposing groups,compatible receiving roads and full-tail clearance.
No duplicate,restart,Classic208,full-suite or native job was launched. Unchanged
runtime/tests retain the completed1003-test suite and candidate32's four passing
authoring guards. Network208V2 remains unaccepted/uninstalled; feasibility and
ETA remain unproven. No gameplay playtest until an accepted V2 installation.

27 October 21:44 — reboot interruption preserved; user authorizes modest service trimming.

The user restarted the PC for unrelated reasons and asked to resume overnight
until the timetable is done, trimming a few services if needed. The observed boot
is 20:09:08+08. No Godot process survived. Original32 baseline27304/14984 last
logged17:20 simulated,109/208 complete,peak34,maxwait41.0m,empty stderr and NO
final audit. This is interrupted, neither passed nor naturally failed. Its six
exact raw files include lossless traffic and original catalogue; all346 surviving
files, including342 snapshots retained in the original local folder, have exact
hashes in interrupted-predictive-baseline/provenance.json. All4836 source hashes
were verified against current-at-run candidate32 before any source change.
Do not execute launch-network-v32.ps1 again or treat the prefix as completion.

Original32 delayed failure bc0118b1 remains rejected: S035 bookedALLP19:52:26,
122/208,2702s in both wait populations,zero safety,failed30/45 gates. Its17 raw
files and two immutable inspections remain. The next candidate targets200
services by removing eight evening mails from both authored source packs while
retaining every remaining service object, K1 and all gates. Raw208 template,
runtime and six original observers remain unchanged to preserve legacy evidence.
No new replay has launched. Full-day feasibility and ETA remain unproven.
Active work resumed21:34:58+08; the idle/reboot gap is excluded from the ledger.
Historical running statements below describe their recorded checkpoints only.

27 October 21:57 — candidate33 selects200 services; complete source suite passes.

Following the user's overnight continuation and modest-trimming authorization,
exactly eight evening mails are removed from candidate32: M02117:10,M02518:15,
M05719:10,M06718:55 southbound and M05215:35,M06615:45,M09019:35,M09819:20 northbound.
All200 retained service JSON objects are identical to32: no departure, call,
dwell, stock, priority, speed or route edit; K1 remains06:00. Both common-author
packs have identical service records. The explicit selection is separate from
the unchanged raw208 template. Common-author equality is not Classic readiness.
There are40local/96mail/56superfast/8VB,160 boundary journeys,75 overnight origins
and3–13 starts each hour. No reduction below the original200-service minimum.

The hypothesis reduces successive northern evening block/receiving pressure
(M021/M025), removes an opposing pair M052/M066 and their later northern conflict
partners M067/M057, and reduces southern replenishment M090/M098. Actual32 delayed
S035 waited1252s for compatible AMPA receiving and1122s opposing traffic; M021/M025
accounted for recorded blocks, while M052/M067 constrained the next crossing and
M057 followed. S035, S036, M102, L004 and all locals/fast trains remain. Removing
these whole workings may change crossing/overtaking order and is NOT proof of
full-day capacity, shorter waits or recovery. Finite compatible roads, opposing
groups and full-tail clearance remain mandatory. No isolated-model score claimed.

Normal authoring and exact --check pass. All five Network authoring guards pass;
the single source suite22324/18976 launched21:46:24 ended naturally with1004 passed,
0 failed and empty stderr. Fifteen exact raw proofs and their hashes are retained
in network-candidate-thirty-three. All4835 railway inputs other than the changed
Network pack and the six original observers are unchanged. Runtime9ec3530 and
legacy certification remain; no unchanged legacy/native checks were repeated.
V2 pack SHA256 be42428170c7bbd8388c1c2bdfae0d33dab51f39390c8fc3fa3a06e8c2784ddf.

Network-only population checks bind exact200 IDs and the pack hash, with2 positive
and17 rejection fixtures plus JavaScript syntax checks. The dedicated
finalize_network_timetable.mjs --network --predictive preserves the old finalizer
bytes and every existing wait/safety/call/clearance gate; it additionally checks
source inventory and exact service IDs. Network disturbance verification retains
all gates and checks actual overtakes at multiple locations. These are code/guard
checks, NOT positive full-day acceptance. Native UI/category helper200-count
support remains pending until a passing V2 installation; those helpers remain
outside this commit. NetworkV2 metadata now names200; legacy and Classic choices
remain unchanged. No installation or gameplay playtest yet.

Candidate32 baseline interruption is preserved in3a34ed00 (109/208 at17:20,no final
audit); delayed failure inbc0118b1 (S03519:52:26,122/208,failed30/45,zero safety).
Their hashes are HISTORICAL after33; never relabel, rerun unchanged or install.
Next: commit/push the verified candidate, launch one fresh V2 baseline and one
600s-delayed V2 run in generation33, verify actual identities/options/catalogue
and hashes, then freeze inputs and acceptance tools while either run lives.
Full-day feasibility and completion ETA remain unproven. No Classic Network job.

27 October 22:03 — candidate33 V2 runs launched once; inputs frozen.

Candidate f5c5d999 was committed/pushed after the1004-test source suite, five
headless authoring guards, exact author reproduction and staged verification of
fifteen raw proofs, both pack hashes, selection and unchanged override JSON.
Exactly two new V2 runs launched at22:02:38 in rehearsals-v33: normal baseline
wrapper14144/child5236 with --network --snapshots, delayed wrapper15508/child24420
with --network --delay=600 --delay-at=27000. All four actual commands/options,
unique outputs, ORIGINAL baseline catalogue and4836 distinct source hashes were
verified. The six original observer hashes equal32; five additional acceptance/
selection hashes are recorded. Five exact launch files plus their hash manifest
are preserved in network-candidate-thirty-three/launch-proof. No failed launch,
duplicate or restart. Do not execute launch-network-v33.ps1 again.

At22:03:00 the baseline has no first progress line; delayed reaches00:10,0/200.
Both original process pairs match, errors are empty and neither final audit
exists. Partial clocks are not acceptance. Runtime/routes/packs/six original
observers plus new Network acceptance tools and selection remain frozen while
either original33 run lives. No Classic, suite, native or diagnostic job remains.
Network200V2 remains unaccepted/uninstalled; no gameplay playtest until passing
installation. Actual full-day completion, waits, safety, clearance, overtakes and
recovery remain required. Continued overnight work is active; no reliable ETA.

Candidate32 interruption3a34ed00 and delayed failurebc0118b1 remain historical,
with exact evidence preserved; never relabel, rerun unchanged or install them.
The original start/deadline remain historical and idle/reboot gaps are excluded.

27 October 22:08 — original33 V2 runs continue; frozen inputs verified.

At22:08:13 baseline14144/5236 reaches01:40 simulated,1/200 complete,peak14,
maxwait6.1m; delayed15508/24420 reaches02:30,1/200,peak21,maxwait6.1m. Both original
command/parent identities match; stderr is empty and neither final audit exists.
All4836 railway input hashes, six original observer hashes and five additional
acceptance/selection hashes remain unchanged. These early partial clocks are not
acceptance. No duplicate, restart, Classic, suite or native job was launched.
Continue the two original runs with inputs frozen. Network200V2 remains unaccepted
and uninstalled; no gameplay playtest until a passing installation.

27 October 22:17 — original33 V2 runs continue; inputs remain frozen.

At22:17:32 baseline14144/5236 reaches03:40 simulated,2/200 complete,peak27,
maxwait7.4m; delayed15508/24420 reaches04:40,13/200,peak29,maxwait18.6m.
Both original command/parent identities match, errors are empty and neither
final audit exists. All4836 source hashes, six original observers and five
acceptance/selection hashes match launch. No new job or source edit. These are
partial results only; Network200V2 remains unaccepted/uninstalled. Wait for both
original runs; no gameplay playtest until passing V2 installation.

27 October 22:27 — original33 V2 runs continue; inputs remain frozen.

At22:27:37 baseline14144/5236 reaches05:20 simulated,16/200 complete,peak29,
maxwait31.1m; delayed15508/24420 reaches06:40,25/200,peak31,maxwait31.9m.
Both original command/parent identities match, stderr is empty and neither final
audit exists. All4836 input hashes, six original observers and five acceptance/
selection hashes match launch. No new job, source edit, duplicate or restart.
Partial results are not acceptance; continue both original runs with frozen
inputs. Network200V2 remains unaccepted/uninstalled; no gameplay playtest yet.

27 October 22:37 — original33 V2 runs continue; frozen inputs verified.

At22:37:45 baseline14144/5236 reaches06:40 simulated,25/200 complete,peak31,
maxwait31.9m; delayed15508/24420 reaches08:40,38/200,peak31,maxwait40.9m.
Both original command/parent identities match, errors are empty and neither
final audit exists. All4836 source hashes, six original observer hashes and five
acceptance/selection hashes remain unchanged. No new job, restart or source edit.
These partial clocks are not acceptance or recovery proof. Continue both original
runs with frozen inputs; Network200V2 is unaccepted/uninstalled, no playtest yet.

27 October 22:47 — original33 V2 runs continue; all frozen hashes match.

At22:47:30 baseline14144/5236 reaches08:10 simulated,33/200 complete,peak31,
maxwait35.8m; delayed15508/24420 reaches11:00,61/200,peak31,maxwait40.9m.
Both original command/parent identities match, errors are empty and neither final
audit exists. All4836 railway inputs, six original observers and five acceptance/
selection hashes remain unchanged. No duplicate, restart, source edit or new job.
These partial results are not acceptance or recovery proof. Continue both
original runs with frozen inputs; Network200V2 remains unaccepted/uninstalled.
No gameplay playtest until a passing V2 installation.

27 October 22:57 — original33 V2 runs continue; frozen inputs verified.

At22:57:35 baseline14144/5236 reaches09:50 simulated,51/200 complete,peak31,
maxwait35.9m; delayed15508/24420 reaches13:00,69/200,peak32,maxwait40.9m.
Both original command/parent identities match, stderr is empty and neither final
audit exists. All4836 source hashes, six original observers and five acceptance/
selection hashes match launch. No new job, duplicate, restart or source edit.
Partial progress is not acceptance or recovery proof. Continue both original
runs with inputs frozen; Network200V2 remains unaccepted/uninstalled. No gameplay
playtest until a passing V2 installation.

27 October 23:10 — original33 V2 runs continue; frozen inputs verified.

At23:10:17 baseline14144/5236 reaches11:50 simulated,65/200 complete,peak31,
maxwait40.1m; delayed15508/24420 reaches15:40,95/200,peak34,maxwait40.9m.
Both original command/parent identities match, stderr is empty and neither final
audit exists. All4836 source hashes, six original observers and five acceptance/
selection hashes match launch. No new job, duplicate, restart or source edit.
Partial progress is not acceptance or recovery proof. Continue both original
runs with inputs frozen; Network200V2 remains unaccepted/uninstalled. No gameplay
playtest until a passing V2 installation.

27 October 23:17 — original33 V2 runs continue; frozen inputs verified.

At23:17:28 baseline14144/5236 reaches12:50 simulated,69/200 complete,peak33,
maxwait40.1m; delayed15508/24420 reaches17:30,109/200,peak34,maxwait40.9m.
Both original command/parent identities match, stderr is empty and neither final
audit exists. All4836 source hashes, six original observers and five acceptance/
selection hashes match launch. No new job, duplicate, restart or source edit.
These partial results are not acceptance or recovery proof. Continue both
original runs with frozen inputs; Network200V2 remains unaccepted/uninstalled.
No gameplay playtest until a passing V2 installation.

27 October 23:27 — original33 V2 runs continue; frozen inputs verified.

At23:27:19 baseline14144/5236 reaches14:10 simulated,78/200 complete,peak34,
maxwait41.0m; delayed15508/24420 reaches19:40,120/200,peak34,maxwait40.9m.
Both original command/parent identities match, stderr is empty and neither final
audit exists. All4836 source hashes, six original observers and five acceptance/
selection hashes match launch. No new job, duplicate, restart or source edit.
These partial results are not acceptance or recovery proof. Continue both
original runs with frozen inputs; Network200V2 remains unaccepted/uninstalled.
No gameplay playtest until a passing V2 installation.

27 October 23:42 — candidate33 original V2 delayed run rejected; baseline continues.

The original delayed wrapper15508/child24420 ended naturally at21:14:24 simulated
with M054 at its booked Neyyattinkara/NYY call,127/200 complete,peak39 and maximum
2702s in BOTH wait populations. Zero safety events and empty run, summary and
all three inspection errors follow the configured600s K1 hold at07:30. At23:42:34
the original baseline14144/5236 remains running: 16:40:00 complete=103/200 peak=34 max_wait=41.0m wall=5960.0s.
Its command/parent identity matches launch99a1d769. Runtime, routes, packs, six
original observers and five acceptance/selection inputs remain frozen. No restart.

Evidence in network-candidate-thirty-three/failed-predictive-delayed preserves21
exact raw files, lossless audit/traffic/failure, exact V2 pack, actual final
summary and three byte-immutable inspections at NEM,KZT,NYY. All4836 distinct
source hashes match current-at-run f5c5d999, with all eleven observer/acceptance
hashes unchanged. Original outputs remain. Never rerun this rejected test
unchanged, relabel these fingerprints after a later source change, or install it.

All-location cumulative385/496,458/496,482/496,495/496 fails under30/45 minutes;
station-only195/270,247/270,261/270,269/270 also fails under30/45. Passing fractions
apply only to this failed prefix. M054 arrived NYY20:28:09.15 with no departure,
current signal NYY-N1; this IS a booked station wait. Its2702s comprises1764s
opposing traffic (S049394,S033448,S053446,M081476),890s compatible NEM receiving
and48s conflicts (12 each S049/S033/S053/M081). Receiving buckets are176L031,
488combinedL031/M099,96combinedL031/S053,22S033,68approachingL031/M081 and
40approachingS033/L031. Preserve combined buckets without individual attribution.

Actual NEM claims L031P1/M099P2, both waiting for NYY receiving reported against
M054/M081. S019 appears in NEM claims with NO road, while moving empty stock at
TVC; it must not be described as a reserved NEM road. Actual NYY claims M054P1/
M081P2. M081 arrivedNYY21:07:00.10 and awaits PASA receiving for S053/M104.
S053 waits at PASA-S1 for M104's conflicting route; M104 moves14.513m/s toward
PASA after KZT departure21:07:40.25. L031 arrivedNEM20:41:20.70 with no departure;
M099 leftTVC21:00:05.25. All three inspections have identical before/after
captures and no future clearance plans. This is not permanent-deadlock or
runtime-defect proof. A local reporting print stopped after the saved NEM
inspection by calling the integer st_size; it was corrected without repeating
that inspection or any replay. KZT and NYY inspections then completed normally.

M088's booked ERL wait is2676s after arrival20:27:37.85, no departure, signalERL-N2:
2260s opposing traffic,396s compatible KZT receiving and20s S051 conflicts.
Opposing buckets are660L029,260combinedL029/S051,430S051,610S049,230S033,
2combinedS033/S049 and68combinedS049/S033; receiving190combinedL029/M104,
114combinedS049/M104 and92M104. KZT has no current claims, but S033 moves24.6m/s
south through KZT_single after KZT departure21:09:29.80. M058 waits for M088's
ERL block; M056/L028 wait behind it, L030 moves north and L038/L032 are not due.
S049 moves south beyondERL; S051 heads toward its southern portal afterNCJ
21:13:35.25 departure, not yet recorded cleared. M085 awaits a clear TVC origin;
M087/M083/L037 are not due. L029 moves afterNJT21:14:21.25 departure.

S036 has continued beyond the northern boundary at21:02:29.75; M102 is in ALLP
depot after19:58:04.70 arrival. L004 now waitsTUVR for opposingS021; M070 waits
SRTL for L011. S021/L003/L011/M031/M069/M055/M072/S038 move. L009 waitsKUMM for
M031's overtake; M027 preserves L004's onward crossing; M033 waitsSRTL for S022's
crossing and M059 waitsALLP for S022. M029/M035/S023 are not yet due. S035 waits
behind S019's TVC block. S017/S019 are moving empty to TVC depots after passenger
arrivals21:05:39.90/21:12:05.45, not yet stabled. M015 is in TVC depot after20:44:02.65
arrival; V003/V008 are there after19:43:55.60/19:55:59.55. M065 is beyond the southern
boundary at19:47:13.30. K1/L025 remain in NCJ depot after13:31:09.15/13:11:10.65
passenger arrivals. These local movements are not whole-day improvement,
capacity or recovery proof.

Eleven K1 minute samples show27.4545764399m braking by07:31, then unchanged
recorded extents through07:40; these are not exact controller frames or recovery
proof. The actual final summary records one V001 overtake of K1 at TVCN, not
completed multiple-location evidence. No complete-population comparison,
recovery certificate or installation. Wait for the original baseline before
coordinated planning using both actual queues, opposing groups, compatible
receiving roads and full-tail clearance. No Classic Network, duplicate, source
suite or native job launched. The completed1004-test source suite and five
authoring guards remain current. Network200V2 remains unaccepted/uninstalled;
feasibility and ETA remain unproven. No gameplay playtest until passing V2 install.

27 October 23:47 — original33 V2 baseline continues.

At23:47:17 the original14144/5236 pair reaches17:50 simulated,110/200 complete,
peak34,maxwait41.0m. Exact command/parent identity matches, stderr is empty and
no final audit exists. All4836 source hashes,six observers and five acceptance/
selection hashes remain unchanged. Delayed33 remains rejected in7f5d44ad; its
21 exact raw files and three immutable inspections are preserved. No new job,
source change, restart or installation. Continue the original baseline with
inputs frozen; these partial results are not acceptance or recovery proof.
Network200V2 remains unaccepted/uninstalled; no gameplay playtest until passing install.

27 October 23:57 — original33 V2 baseline continues.

At23:57:18 the original14144/5236 pair reaches19:50 simulated,121/200 complete,
peak34,maxwait41.0m. Exact command/parent identity matches, stderr is empty and
no final audit exists. All4836 source hashes,six observers and five acceptance/
selection hashes remain unchanged. Delayed33 remains rejected in7f5d44ad; its
21 exact raw files and three immutable inspections are preserved. No new job,
source change, restart or installation. Continue the original baseline with
inputs frozen; these partial results are not acceptance or recovery proof.
Network200V2 remains unaccepted/uninstalled; no gameplay playtest until passing install.

28 October 00:10 — candidate33 original V2 baseline rejected; both originals ended.

The original baseline wrapper14144/child5236 ended naturally at21:14:24 simulated
with M054 at its booked Neyyattinkara/NYY call,127/200 complete,peak39 and maximum
2702s in BOTH wait populations. Zero safety events, empty run/summary/three
inspection errors and no manual hold. Original delayed15508/24420 is rejected
in7f5d44ad. No original33 process remains and neither run was restarted. All
runtime, routes, packs, six original observers and five acceptance inputs stayed
unchanged throughout both runs. Network200V2 remains unaccepted/uninstalled.

Baseline evidence in network-candidate-thirty-three/failed-predictive-baseline
preserves21 exact raw files, lossless audit/traffic/failure, exact V2 pack, actual
final summary and three byte-immutable NEM/KZT/NYY inspections. All4836 distinct
source hashes and eleven observer/acceptance hashes match current-at-run
f5c5d999. Original outputs remain. Never rerun unchanged, relabel fingerprints
after a later source change, or install failed results.

All-location388/512,471/512,497/512,511/512 and station203/286,262/286,279/286,
285/286 FAIL under30/45 minutes. Passing fractions apply only to this failed
prefix. Baseline and delayed have different wait populations despite the same
failure clock/count; no complete-population comparison or recovery certificate.
M054 arrivedNYY20:28:09.15 without departure,NYY-N1:2702s=1764s opposing
(S049394,S033448,S053446,M081476)+890s compatible NEM receiving+48s conflicts.
Receiving176L031,488combinedL031/M099,96combinedL031/S053,22S033,
68approachingL031/M081,40approachingS033/L031; preserve combined buckets.

Actual NEM L031P1/M099P2 await NYY M054P1/M081P2; M054 awaits NEM receiving.
NEM claim S019 has no road and refers to empty stock moving at TVC, not a NEM
road reservation. M081 awaits PASA S053/M104; M104 moves14.513m/s toward PASA
after KZT21:07:40.25 departure, while S053 awaits its conflicting route.
M088 has2676s booked ERL wait (2260opposing+396receiving+20conflicts), waiting
for S033 inKZT_single. KZT has no current claims; S033 moves24.6m/s south after
KZT21:09:29.80 departure. M058/M056/L028 queue behind M088; L030 moves north.
All three inspections retain identical before/after captures and no future
clearance plans. These observations do not prove permanent deadlock or a runtime
fault. The matching M054/M088 waits are local records, not population equality.

S036 has cleared the northern boundary21:02:29.75; M102 is in ALLP depot after
19:56:57.80 arrival. L004 waitsTUVR forS021 and M070 waitsSRTL forL011. S021/L003/
L011/M031/M069/M055/M072 move; S038 also moves at19.998m/s towardAMPA. L009 waits
for M031's overtake, M027 protects L004's onward crossing and M033/M059 await
S022. S035 waits behind S019's TVC block; S017/S019 move empty stock but are not
yet stabled. M015/V003/V008 are in TVC depots after20:44:02.65/19:42:25.10/19:54:29.05
passenger arrivals. M065 cleared the southern boundary19:47:13.30. K1/L025 remain
in NCJ depots after12:46:12.65/13:14:56.65 arrivals. Local movements are not
whole-day improvement/capacity/recovery proof; actual baseline summary has no
K1 overtakes. Delayed has one atTVCN, not completed multiple-location evidence.

Both original33 results are rejected. Next: coordinated evening departure-group
planning using both actual queues, opposing groups, compatible receiving roads
and full-tail clearance; preserve200 services and all retained non-departure
fields,K1,selection and acceptance gates. No Classic Network, duplicate, full
suite or native job launched. Unchanged1004-test suite and five authoring guards
remain current. No gameplay playtest until passing V2 install. Feasibility and
completion ETA remain unproven.

28 October 00:22 — candidate34 authors eight coordinated southern departures after both original33 failures.

Only these departure strings change from candidate33:
S04919:50 ->20:50; S05320:10 ->21:10; M08120:40 ->21:30;
M08521:00 ->21:45; M08721:20 ->22:20; M08321:40 ->22:35;
L03118:31 ->19:35; M09919:35 ->20:35.
Restoring them recovers each entire predecessor JSON object. The selected200 IDs,
eight excluded mails, every non-departure field and K1 at06:00 are unchanged.
Both common-author packs have identical service records; this is not Classic
Network readiness. All northern and southern northbound origins remain at33.
Retain S05119:30, L02917:55, M05419:05, M10419:50, M08820:05 and through S03316:45.

Both actual33 runs fail M054 at bookedNYY21:14:24,127/200,peak39,max2702s in BOTH
wait populations,zero safety. M054 waits1764s opposing S049/S033/S053/M081,
890s compatible NEM receiving and48s conflicts. Actual NEM L031P1/M099P2 fill
both roads opposite NYY M054P1/M081P2. M088 has2676s at bookedERL,including2260s
opposing and396s compatible KZT receiving; M058/M056/L028 queue behind it.
Actual NEM full-rake envelopes in both: M07220:03:16–20:09:36,
S05120:10:50–20:17:14,S04920:29:32–20:35:56,S03320:38:12–20:44:38,
S05320:47:26–20:53:52,M08120:59:40–21:06:04. Actual KZT envelopes include
L02920:35:34–20:49:38,S05120:46:38–20:57:00,S04921:00:22–21:10:20,
then S03321:10:34 to failure,right-censored. Overlap at a common axis interval
is not proof of a shared occupied interlocking resource. These are actual33
observations, not candidate34 predictions or guaranteed clearance times.

The hypothesis delays S049/S053 and their following TVC mails to interrupt the
repeated opposing refill after retained S051, leaving an opportunity around
retained through S033 for M054/M104/M088 and following northbound traffic.
L031 moves64 origin minutes later and M09960 to avoid their actual33 paired NEM
receiving-road claims during that queue. Later M087/M083 join retained S05522:05,
M09122:15,M07322:30,M08922:45; through services and locals remain constraints.
Origin gaps do not guarantee crossing order, compatible roads, full-tail
clearance, escape or capacity. Later southbound waits, overtakes, origin queues
and midnight completion remain unproven; no whole-day improvement claim.

200 services retain40local/96mail/56superfast/8VB and160 boundary journeys.
There are77 overnight origins(previously75),3–14 starts/hour. The aggregate
maximum rises13 to14 at22 across different origins. The authoritative density
guard requires at least3/hour and has no maximum; the old local13 assertion
was descriptive, not a capacity or acceptance gate. Every completion,safety,
wait,physical and recovery gate is unchanged. All205 overrides reproduce both
packs normally and with exact --check. Five headless authoring guards pass,
errors empty. Runtime/tests retain the completed1004-test candidate33 suite;
no unchanged full-suite rerun. All4835 prior railway inputs except the Network
pack and all eleven observer/acceptance inputs remain unchanged.
V2 pack SHA256 f27e4d92e33254dc44e0a5bebf6f206695dd566c4dac7975db6ee03fa600671d.
Thirteen exact raw authoring proofs and hashes are retained in
network-candidate-thirty-four; exact predecessors remain locally in
candidate-thirty-four-before. Verify staged raw bytes, both pack hashes and
override JSON before commit/push. In-memory timing alternatives were discarded
before authoring; no rejected source draft or replay exists.

candidate-thirty-four-sampled-groups.json and sample-v33-groups-for34.py preserve
actual33 continuous full-rake axis overlaps from11:00 to each failure, static
bounds, source/report hashes, formula, about2s sampling and censoring. Southern
bounds are retained from23; ALLP–AMPA uses report centers plus half-width+200m
exclusion. Planning inputs only, not exact interlocking ownership, assigned
roads, guaranteed gaps, escape or full-day proof. No isolated-model score.

Both original33 runs ended naturally before source changes. Baseline f9aa1305
and delayed7f5d44ad preserve21+21 exact raw files,4836 current-at-run source
hashes each,lossless reports,exact packs,actual summaries and six immutable
inspections. Their fingerprints are now HISTORICAL after34; never relabel,
rerun unchanged or install. Baseline all388/512,471/512,497/512,511/512 and station
203/286,262/286,279/286,285/286 fail30/45; delayed all385/496,458/496,482/496,495/496
and station195/270,247/270,261/270,269/270 fail30/45. Passing fractions apply only
to failed prefixes. Equal failure clock/count does not equate populations.
No complete-population comparison,recovery certificate or installation.
Next: commit/push verified34, launch exactly one V2 baseline and one V2 delayed
run in a new generation, verify actual identities/options/source hashes and
freeze all inputs until both originals end. No Classic Network/full-suite/native
job. Network200V2 remains unaccepted/uninstalled; feasibility and ETA unproven.
No gameplay playtest until passing V2 installation.

28 October 00:24 — candidate34 V2 launch verified; frozen inputs.

Candidate655e46bb was committed/pushed after exact normal author reproduction,
--check,five headless authoring guards and staged verification of thirteen raw
proofs,both pack hashes and override JSON. Exactly two V2 runs launched ONCE at
00:23:25 in rehearsals-v34: baseline wrapper22164/child21660 with --network
--snapshots; delayed wrapper5648/child2636 with --network --delay=600
--delay-at=27000. All four actual commands/options,unique outputs,the ORIGINAL
predictive baseline catalogue,4836 distinct input hashes,six original observers
and five acceptance/selection hashes were verified. The catalogue existed before
verification; no failed verification attempt,duplicate or restart. Five exact
launch files plus their hash manifest are preserved in candidate34/launch-proof.

At00:23:55 the baseline has no first progress line and delayed reaches00:20,
0/200. Both original process identities match,errors are empty and neither final
audit exists. Partial clocks are not acceptance. Runtime/routes/packs/six
observers/five acceptance inputs remain frozen while either original34 run lives.
No Classic Network,full-suite,native,search or diagnostic job remains. The
completed1004-test runtime/tests suite is unchanged; five authoring guards cover
this departure-only candidate. inspect-current-replays.py selects34 first.
Do not execute launch-network-v34.ps1 again.

Both original33 runs ended naturally and failed M054 bookedNYY21:14:24,127/200,
peak39,max2702s BOTH populations,zero safety and failed30/45 wait gates. Baseline
f9aa1305 and delayed7f5d44ad preserve21+21 exact raw files,4836 hashes each,
lossless reports,exact packs,actual summaries and six immutable inspections.
All33 fingerprints are HISTORICAL after34; never relabel,rerun unchanged or
install. Matching failure clocks/counts do not equate populations. No complete
population comparison,recovery certificate or installation.
Next: inspect both ORIGINAL34 final reports against every completion,safety,
wait,physical and recovery gate. Network200V2 remains unaccepted/uninstalled;
no gameplay playtest until passing V2 installation. Continuation stays active;
feasibility and completion ETA remain unproven.

28 October 00:28 — both original34 V2 tests continue with frozen inputs.

At00:28:18 baseline22164/21660 reports 01:30:00 complete=1/200 peak=14 max_wait=6.1m wall=263.6s.
Delayed5648/2636 reports 02:20:00 complete=1/200 peak=19 max_wait=6.1m wall=279.0s.
All four exact command/parent identities match launchda4ff140; errors are empty
and neither final audit exists. All4836 source hashes,six original observers
and five acceptance/selection hashes remain unchanged. No new job,restart,
source edit or installation. Continue both original tests; these partial clocks
are not completion,capacity or recovery proof. Network200V2 remains unaccepted/
uninstalled; no gameplay playtest until a passing V2 installation.

28 October 00:38 — both original34 V2 tests continue with frozen inputs.

At00:38:20 baseline22164/21660 reports 03:40:00 complete=2/200 peak=27 max_wait=7.4m wall=889.2s.
Delayed5648/2636 reports 04:40:00 complete=13/200 peak=29 max_wait=18.6m wall=863.7s.
All four exact command/parent identities match launchda4ff140; errors are empty
and neither final audit exists. All4836 source hashes,six original observers
and five acceptance/selection hashes remain unchanged. No new job,restart,
source edit or installation. Continue both original tests; these partial clocks
are not completion,capacity or recovery proof. Network200V2 remains unaccepted/
uninstalled; no gameplay playtest until a passing V2 installation.

28 October 00:48 — both original34 V2 tests continue with frozen inputs.

At00:48:18 baseline22164/21660 reports 05:20:00 complete=16/200 peak=29 max_wait=31.1m wall=1487.9s.
Delayed5648/2636 reports 06:40:00 complete=25/200 peak=31 max_wait=31.9m wall=1457.6s.
All four exact command/parent identities match launchda4ff140; errors are empty
and neither final audit exists. All4836 source hashes,six original observers
and five acceptance/selection hashes remain unchanged. No new job,restart,
source edit or installation. Continue both original tests; these partial clocks
are not completion,capacity or recovery proof. Network200V2 remains unaccepted/
uninstalled; no gameplay playtest until a passing V2 installation.

28 October 00:58 — both original34 V2 tests continue with frozen inputs.

At00:58:17 baseline22164/21660 reports 06:40:00 complete=25/200 peak=31 max_wait=31.9m wall=2048.3s.
Delayed5648/2636 reports 08:40:00 complete=38/200 peak=31 max_wait=40.9m wall=2065.3s.
All four exact command/parent identities match launchda4ff140; errors are empty
and neither final audit exists. All4836 source hashes,six original observers
and five acceptance/selection hashes remain unchanged. No new job,restart,
source edit or installation. Continue both original tests; these partial clocks
are not completion,capacity or recovery proof. Network200V2 remains unaccepted/
uninstalled; no gameplay playtest until a passing V2 installation.

28 October 01:08 — both original34 V2 tests continue with frozen inputs.

At01:08:23 baseline22164/21660 reports 08:10:00 complete=33/200 peak=31 max_wait=35.8m wall=2649.3s.
Delayed5648/2636 reports 11:00:00 complete=61/200 peak=31 max_wait=40.9m wall=2667.2s.
All four exact command/parent identities match launchda4ff140; errors are empty
and neither final audit exists. All4836 source hashes,six original observers
and five acceptance/selection hashes remain unchanged. No new job,restart,
source edit or installation. Continue both original tests; these partial clocks
are not completion,capacity or recovery proof. Network200V2 remains unaccepted/
uninstalled; no gameplay playtest until a passing V2 installation.

28 October 01:18 — both original34 V2 tests continue with frozen inputs.

At01:18:19 baseline22164/21660 reports 09:50:00 complete=51/200 peak=31 max_wait=35.9m wall=3285.6s.
Delayed5648/2636 reports 13:00:00 complete=69/200 peak=32 max_wait=40.9m wall=3253.4s.
All four exact command/parent identities match launchda4ff140; errors are empty
and neither final audit exists. All4836 source hashes,six original observers
and five acceptance/selection hashes remain unchanged. No new job,restart,
source edit or installation. Continue both original tests; these partial clocks
are not completion,capacity or recovery proof. Network200V2 remains unaccepted/
uninstalled; no gameplay playtest until a passing V2 installation.

28 October 01:28 — both original34 V2 tests continue with frozen inputs.

At01:28:19 baseline22164/21660 reports 11:30:00 complete=63/200 peak=31 max_wait=40.1m wall=3889.3s.
Delayed5648/2636 reports 15:00:00 complete=89/200 peak=34 max_wait=40.9m wall=3890.4s.
All four exact command/parent identities match launchda4ff140; errors are empty
and neither final audit exists. All4836 source hashes,six original observers
and five acceptance/selection hashes remain unchanged. No new job,restart,
source edit or installation. Continue both original tests; these partial clocks
are not completion,capacity or recovery proof. Network200V2 remains unaccepted/
uninstalled; no gameplay playtest until a passing V2 installation.

28 October 01:38 — both original34 V2 tests continue with frozen inputs.

At01:38:15 baseline22164/21660 reports 12:50:00 complete=69/200 peak=33 max_wait=40.1m wall=4473.4s.
Delayed5648/2636 reports 17:20:00 complete=109/200 peak=34 max_wait=40.9m wall=4480.0s.
All four exact command/parent identities match launchda4ff140; errors are empty
and neither final audit exists. All4836 source hashes,six original observers
and five acceptance/selection hashes remain unchanged. No new job,restart,
source edit or installation. Continue both original tests; these partial clocks
are not completion,capacity or recovery proof. Network200V2 remains unaccepted/
uninstalled; no gameplay playtest until a passing V2 installation.

28 October 01:48 — both original34 V2 tests continue with frozen inputs.

At01:48:17 baseline22164/21660 reports 14:10:00 complete=78/200 peak=34 max_wait=41.0m wall=5067.1s.
Delayed5648/2636 reports 19:40:00 complete=120/200 peak=34 max_wait=40.9m wall=5066.1s.
All four exact command/parent identities match launchda4ff140; errors are empty
and neither final audit exists. All4836 source hashes,six original observers
and five acceptance/selection hashes remain unchanged. No new job,restart,
source edit or installation. Continue both original tests; these partial clocks
are not completion,capacity or recovery proof. Network200V2 remains unaccepted/
uninstalled; no gameplay playtest until a passing V2 installation.

28 October 01:58 — both original34 V2 tests continue with frozen inputs.

At01:58:16 baseline22164/21660 reports 15:30:00 complete=92/200 peak=34 max_wait=41.0m wall=5626.1s.
Delayed5648/2636 reports 21:20:00 complete=129/200 peak=37 max_wait=40.9m wall=5631.3s.
All four exact command/parent identities match launchda4ff140; errors are empty
and neither final audit exists. All4836 source hashes,six original observers
and five acceptance/selection hashes remain unchanged. No new job,restart,
source edit or installation. Continue both original tests; these partial clocks
are not completion,capacity or recovery proof. Network200V2 remains unaccepted/
uninstalled; no gameplay playtest until a passing V2 installation.

28 October 02:12 — candidate34 original V2 delayed run rejected; baseline continues.

The original delayed wrapper5648/child2636 ended naturally at21:48:28 with L004
at its booked Turavur/TUVR call,133/200 complete,peak38,maximum2702s in BOTH wait
populations. Zero safety events and empty run,summary and four inspection errors
after the configured600s K1 hold at07:30. At02:11:25 original baseline22164/21660
reaches18:20,113/200,peak34,maxwait41.0m with empty errors and no final audit.
Its original command/parent identities match launchda4ff140. Runtime/routes/packs,
six original observers and five acceptance/selection inputs remain frozen.

Evidence in network-candidate-thirty-four/failed-predictive-delayed preserves24
exact raw files,lossless audit/traffic/failure,exact V2 pack,actual final summary
and four byte-immutable inspections: KUMM,TUVR,SRTL,then MAKM including newly
identified S022/M032 dependencies. All4836 distinct source hashes match current-
at-run candidate655e46bb. Original outputs remain. Never rerun this rejected test
unchanged,install it or relabel these fingerprints after a later source change.

All-location cumulative395/521,482/521,510/521,520/521 and station-only202/283,
261/283,276/283,282/283 fail the30/45-minute gates.510/521 and276/283 are below98%;
never round up. Passing fractions apply only to this failed prefix. No complete-
population comparison,recovery certificate or installation.

L004 arrivedTUVR21:02:15.10 with no departure,current signalTUVR-N3. Its2702s
comprises1742s opposing traffic,948s compatible KUMM receiving and12s M027 route
conflict. Opposing buckets:50L009,716combinedL009/M027,108combinedL009/S021,
258M027,432S021,178combinedS021/L009. Receiving buckets:166combinedM027/S021,
46combinedM027/S021/L009,544combinedM029/M031/S023,and approaching48combined
M027/S021/L009,128combinedS021/L009,16combinedS021/L009/M027. Preserve combined
buckets without individual attribution. KUMM stopping services still requireP3.

Actual KUMM claims M029P1/M031P2/S023P3; all wait for compatible TUVR receiving.
TUVR claims incomingM070P1/M027P2/L004P3. M027 protects M070's SRTL escape.
M070 leftSRTL21:47:20.75 and moves9.3222m/s with authority toward TUVR; its tail
still claimsSRTL_P3. Actual SRTL claims S021P1/L009P2/M070P3 plus incomingS022
P1/P2/P3 alternatives,not three simultaneous reservations. L009 arrivedSRTL
21:48:00.95 and dwells until21:49:11. S021 protects S022's approach; S022 waits
for M070 to clearP3. One actual future plan atSRTL: incomingS022P3/opponentL009P2,
vacaterM070/escapeTUVR_P1,received=false,opponent_received=true,escaped=false.
All four inspections preserve that same plan and identical before/after captures.
MAKM claims M032P1/L011P2/M033P3. M032 approachesMAKM-N1 at14.8618m/s while its
next departure decision protects S022; L011 awaits M032's conflicting route and
M033 its occupied block. This is not permanent-deadlock or runtime-defect proof.

M054 now leavesQLN21:42:14.75 and moves north; M104 moves north beyondKZK after
21:34:56.30 departure. M088 is inTVCdepot after21:31:24.30 arrival. These local
movements are NOT whole-day improvement,capacity or recovery proof. M058/M056
move north; L028 waitsERL for movingS049,with L030/L038 behind. L031 moves toward
NEM afterTVC21:42:56.75; M099 dwellsTVC until21:49:51. S053/M081/M085 await a
clearTVC origin; laterM087/M083/L037 are not due. L032 awaits itsNCJ origin.
L029 is inNCJdepot after21:30:35.65 arrival. S017/S019 are now stabled inTVC,
S035 moves south and S033 moves toward its southern portal but has not cleared.
S036 remains beyond the northern boundary; M102,K1,L025 remain in their depots.

Eleven K1 minute samples show27.4545764399m braking by07:31 then unchanged
recorded extents through07:40,not exact controller frames or recovery proof.
The actual final summary records one V001 overtake ofK1 atTVCN,not completed
multiple-location evidence. Wait for the ORIGINAL baseline final report before
coordinated replanning from BOTH actual queues,opposing groups,compatible roads
and full-tail clearance. No duplicate,restart,Classic Network,full-suite or native
job launched. The unchanged runtime/tests retain the1004-test suite and candidate34
five passing authoring guards. Network200V2 remains unaccepted/uninstalled;
feasibility and ETA remain unproven. No gameplay playtest until passing V2 install.

28 October 02:18 — original34 V2 baseline continues with frozen inputs.

At02:18:15 original baseline22164/21660 reports 19:40:00 complete=120/200 peak=34 max_wait=41.0m wall=6846.7s.
Both exact command/parent identities match launchda4ff140; errors are empty and
no final audit exists. All4836 source hashes,six original observers and five
acceptance/selection hashes remain unchanged. Original delayed5648/2636 is
already rejected and preserved in cdade7d7; no delayed process remains.
No new job,restart,source edit or installation. Wait for the original baseline
final report before coordinated replanning using both results. Partial progress
is not completion,capacity or recovery proof. Network200V2 remains unaccepted/
uninstalled; no gameplay playtest until a passing V2 installation.

28 October 02:28 — original34 V2 baseline continues with frozen inputs.

At02:28:17 original baseline22164/21660 reports 21:20:00 complete=129/200 peak=37 max_wait=41.0m wall=7476.1s.
Both exact command/parent identities match launchda4ff140; errors are empty and
no final audit exists. All4836 source hashes,six original observers and five
acceptance/selection hashes remain unchanged. Original delayed5648/2636 is
already rejected and preserved in cdade7d7; no delayed process remains.
No new job,restart,source edit or installation. Wait for the original baseline
final report before coordinated replanning using both results. Partial progress
is not completion,capacity or recovery proof. Network200V2 remains unaccepted/
uninstalled; no gameplay playtest until a passing V2 installation.

28 October 02:43 — candidate34 original V2 baseline rejected; both original runs ended.

The original baseline wrapper22164/child21660 ended naturally at21:48:28 with
L004 at booked TUVR,134/200 complete,peak38,maximum2702s in BOTH wait populations,
zero safety events and empty run/summary/four inspection errors. No intervention.
No Godot replay remains. Delayed5648/2636 already failed133/200 at the same clock
and is preserved in cdade7d7. Matching failure clocks/local queues do not equate
populations. Neither run is accepted or installed; no gameplay playtest.

Baseline all-location cumulative401/538,497/538,526/538,537/538 FAIL30/45 minutes.
Station-only211/299,276/299,294/299,298/299 PASSES10/20/30 but FAILS45. The delayed
station30 gate failed; do not copy that outcome onto the baseline. Passing
fractions apply only to failed prefixes; no complete-population comparison.

Baseline evidence in network-candidate-thirty-four/failed-predictive-baseline
preserves24 exact raw files,lossless audit/traffic/failure,exact source pack,
actual summary and four byte-immutable KUMM/TUVR/SRTL/MAKM inspections. All4836
source hashes and six original plus five acceptance/selection hashes match the
current-at-run candidate655e46bb. Originals remain. No rerun or relabeling after
future source changes. No full-day safety/wait/completion/recovery certificate.

Actual baseline L004 arrivedTUVR21:02:15.10 and has no departure; TUVR-N3 wait
2702s comprises1742opposing+948compatibleKUMMreceiving+12M027conflict. Opposing:
50L009,716combinedL009/M027,108combinedL009/S021,258M027,432S021,
178combinedS021/L009. Receiving:166combinedM027/S021,46combinedM027/S021/L009,
544combinedM029/M031/S023; approaching48combinedM027/S021/L009,
128combinedS021/L009,16combinedS021/L009/M027. Combined buckets are not individual
attributions. KUMM stopping road remains P3 only in both directions.

All four actual baseline inspections confirm KUMM M029P1/M031P2/S023P3 waiting
for TUVR M027/L004; TUVR incomingM070P1/M027P2/L004P3. M027 protects M070's SRTL
escape. M070 departedSRTL21:47:20.75,moves9.322222m/s with authority towardTUVR,
and its tail still claimsSRTL_P3. SRTL S021P1/L009P2/M070P3 plus incomingS022
P1/P2/P3 alternatives,not three simultaneous reservations. L009 arrived21:48:00.95
and dwells until21:49:11. One unchanged actual future plan: incomingS022P3,
opponentL009P2,vacaterM070,escapeTUVR_P1;received=false,opponent_received=true,
escaped=false. MAKM M032P1/L011P2/M033P3;M032 moves14.861818m/s towardMAKM-N1
while its next departure decision protectsS022,L011 awaitsM032conflict andM033
itsblock. These observations do not establish permanent deadlock/runtime defect.

Baseline S033 has cleared the southern boundary at21:48:21.30 and is stabled;
delayed S033 was still approaching at failure. Baseline M054 leftQLN21:41:02.25,
M104 leftKZK21:34:56.30,M088 arrivedTVCdepot21:31:24.30. Other trains still move,
while later TVC/NCJ origins remain queued or not due. These are local movements,
not whole-day improvement/capacity/recovery. Baseline summary has noK1overtakes;
delayed has oneV001atTVCN,not completed multiple-location proof.

Next: coordinated departure-only replanning from BOTH actual queues and full-rake
movements,with the same200selected services,unchanged non-departure fields,K1,
runtime and acceptance gates. Full-day feasibility remains unproven; no reliable ETA.

28 October 02:46 — candidate35 authored; original34 failures preserved before departure changes.

Candidate35 changes only seven northern departure strings from34:
S02120:20->21:45;L00920:40->22:00;M02720:45->22:15;M03121:00->22:30;
M02921:15->22:45;S02321:20->23:00;M03521:30->23:15.
Restoring those strings recovers the entire predecessor JSON in both common-author
packs. All other fields/services,K1at06:00,selection and raw208template unchanged.
Both common-author packs have identical service records; this is not Classic readiness.
All southern and northbound departures remain; L01120:20/M03320:30 and preceding
L003/M059/M055/M069 are retained. Same200=40local96mail56superfast8VB,160boundary
journeys;83overnight origins(previously77),3–18starts/hour. The aggregate maximum
18 at22 is descriptive; the authoritative density guard requires at least3/hour
with no maximum. Safety/wait/physical/recovery/completion gates remain unchanged.

Both actual34 runs show L004 atTUVR21:02:15.10. Retained L011/M033 geometric
KUMM envelopes end20:59:38/21:02:22; S021 follows21:11:12,L00921:18:38,
M02721:23:56,then actual receiving claimantsM031/M029/S023. The hypothesis moves
these followers plusM035 later to seek KUMM stoppingP3 forL004 and full-tail
progress forM070/S022/M032. Retained later S03722:05,M04322:10,M00322:25,
M04122:55,S03922:55 constrain the new group. Origin queues,opposing through trains,
compatible roads,overtakes and completion beyond midnight remain unproven.
No origin gap guarantees crossing order,escape,capacity or whole-day improvement.

candidate-thirty-five-sampled-groups.json/sample-v34-groups-for35.py preserve BOTH
actual34 full-rake geometric overlaps from11:00 tofailure,static bounds,source
and report hashes,formula,approximately2s samples and censoring. Northern KUMM,
TUVR,SRTL and MAKM samples informed this revision. They are planning inputs,
not exact interlocking ownership,assigned roads or guaranteed clearance intervals.
Overlapping geometric envelopes do not prove shared occupied interlocking resources.

Normal author and exact--check reproduce both packs from205overrides and the
unchanged8-mail exclusion. Five headless authoring guards PASS with empty errors.
All4835 previous railway inputs exceptNetworkpack and all11 observer/acceptance
inputs are unchanged. Retain the completed1004-test candidate33 source suite;
do not repeat unchanged full-suite/legacy checks. Thirteen exact raw authoring
proofs are preserved in network-candidate-thirty-five. V2 raw SHA256:
1bedbdb8ff9fa5fb7ae9a720c015de13aa87551591e64e7b4e283fe64d8a6e27.
Exact predecessor files remain in candidate-thirty-five-before.

Both original34 runs ended naturally and FAILED before source35. Baseline2618efbd
preserves24raw/four immutable inspections,134/200;delayedcdade7d7 preserves24raw/
four immutable inspections,133/200. Each failedL004at21:48:28,peak38,max2702s both,
zero safety. Baselineall401/538,497/538,526/538,537/538 fail30/45;station211/299,
276/299,294/299,298/299 pass10/20/30 butfail45. Delayedbothfail30/45. All34source
fingerprints are now HISTORICAL; never relabel,rerun unchanged or install them.
Matching clocks/localqueues do not equate populations. No complete-population
comparison,recovery certificate or installation. Earlier evidence remains intact.

Next: commit/push this verified authoring increment,then launch exactly one new
V2normal--network--snapshots and one delayed--network--delay=600--delay-at=27000
in isolated rehearsals-v35. Verify actual identities/options/originalcatalogue/
4836distinctsources/11observers and freeze while either original35run lives.
Network200V2 remains unaccepted/uninstalled; no gameplay playtest. No reliable ETA.

28 October 02:47 — candidate35 V2 launch verified; frozen inputs.

Author5de392dc73c0f1411396dff0381faf1f5ab2f48f was committed/pushed after normal
reproduction,exact--check,five headless authoring guards and exact staged proofs.
Exactly two new V2 runs launched ONCE at02:46:30 in rehearsals-v35:
baseline wrapper14568/child15696 with --network --snapshots; delayed wrapper6764/
child4340 with --network --delay=600 --delay-at=27000. All four actual commands,
options,unique outputs,the ORIGINALbaselinecatalogue,4836distinct input hashes,
six original observers and five acceptance/selection hashes were verified. The
original catalogue existed before verification; no failed verification,duplicate
or restart. Five exact launch files plus manifest are retained in candidate35/
launch-proof. inspect-current-replays.py selects35first. Do not execute
launch-network-v35.ps1 again. Runtime/routes/packs/11observers remain frozen
while either original35run lives.

At02:46:44 baseline has no first progress line; delayed reaches00:10,0/200,
peak3,max0.1m. Both original identities match launch,errors are empty,no final
audits. Partial progress is not acceptance. No Classic Network,source suite,
native,search or diagnostic job remains. Completed1004source tests are retained;
unchanged legacy certificates remain. Pending UI/category helpers remain pending.

Both original34 runs ended naturally and failed before35: baseline2618efbd
134/200,delayedcdade7d7 133/200,eachL004bookedTUVR21:48:28,peak38,max2702s BOTH,
zero safety. Baselineallfails30/45,stationpasses30butfails45;delayedbothfail30/45.
24+24 exact raw files,4836current-at-run hashes each,eight immutable station
inspections and original outputs retained. ALL34fingerprints are HISTORICAL
after35; never relabel,rerun unchanged or install. Matching clocks and local
queues do not equate populations; no complete-population comparison or recovery
certificate. S033 completed the southern boundary only in the baseline prefix.

Candidate35 has seven departure-only northern changes,retains all200selected
services and allnondeparturefields,K106:00; no lower population or relaxed gate.
Its later22:00 hour has18starts across origins,descriptive only. Both full-day
results remain unproven. Next: inspect both ORIGINAL35finalreports,preserve
failures and actual queues before any new source change. Network200V2 remains
unaccepted/uninstalled; no gameplay playtest until passing V2 install. No reliable
completion ETA. The continuation remains active until all V2readiness is done.

28 October 02:49 — both original35 V2 runs continue with frozen inputs.

At02:49:18 baseline14568/15696 reports 01:00:00 complete=0/200 peak=10 max_wait=0.1m wall=163.7s.
Delayed6764/4340 reports 01:30:00 complete=1/200 peak=14 max_wait=6.1m wall=146.8s.
All four exact command/parent identities match launch968f3301. Both have empty
errors and no final audit. All4836 source hashes,six original observers and five
acceptance/selection hashes remain unchanged. No source edit,new job,restart or
installation. Wait for both original final reports before coordinated replanning.
Partial progress is not completion,capacity or recovery proof. Network200V2
remains unaccepted/uninstalled; no gameplay playtest until passing V2 install.

28 October 02:59 — both original35 V2 runs continue with frozen inputs.

At02:59:17 baseline14568/15696 reports 03:10:00 complete=2/200 peak=23 max_wait=6.1m wall=716.0s.
Delayed6764/4340 reports 04:10:00 complete=6/200 peak=29 max_wait=8.9m wall=728.1s.
All four original command/parent identities match launch968f3301. Both have empty
errors and no final audit. All4836 input hashes,six original observers and five
acceptance/selection hashes remain unchanged. No new job,restart,source edit or
installation. Both original results remain pending; partial progress is not
acceptance,capacity or recovery proof. No gameplay playtest before passing V2 install.

28 October 03:09 — both original35 V2 runs continue with frozen inputs.

At03:09:56 baseline14568/15696 reports 05:00:00 complete=16/200 peak=29 max_wait=26.0m wall=1387.6s.
Delayed6764/4340 reports 06:20:00 complete=23/200 peak=31 max_wait=31.1m wall=1371.5s.
All four original command/parent identities match launch968f3301. Both have empty
errors and no final audit. All4836 source hashes,six original observers and five
acceptance/selection hashes remain unchanged. No source edit,new job,restart or
installation. Both original results remain pending; partial progress is not
acceptance,capacity or recovery proof. No gameplay playtest before passing V2 install.

28 October 03:19 — both original35 V2 runs continue with frozen inputs.

At03:19:16 baseline14568/15696 reports 06:20:00 complete=23/200 peak=31 max_wait=31.1m wall=1929.4s.
Delayed6764/4340 reports 08:10:00 complete=33/200 peak=31 max_wait=35.8m wall=1949.8s.
All four original command/parent identities match launch968f3301. Both have empty
errors and no final audit. All4836 source hashes,six original observers and five
acceptance/selection hashes remain unchanged. No source edit,new job,restart or
installation. Both original results remain pending; partial progress is not
acceptance,capacity or recovery proof. No gameplay playtest before passing V2 install.

28 October 03:29 — both original35 V2 runs continue with frozen inputs.

At03:29:16 baseline14568/15696 reports 07:50:00 complete=32/200 peak=31 max_wait=35.8m wall=2544.3s.
Delayed6764/4340 reports 10:20:00 complete=58/200 peak=31 max_wait=40.9m wall=2535.1s.
All four original command/parent identities match launch968f3301. Both have empty
errors and no final audit. All4836 source hashes,six original observers and five
acceptance/selection hashes remain unchanged. No source edit,new job,restart or
installation. Both original results remain pending; partial progress is not
acceptance,capacity or recovery proof. No gameplay playtest before passing V2 install.

28 October 03:39 — both original35 V2 runs continue with frozen inputs.

At03:39:16 baseline14568/15696 reports 09:20:00 complete=45/200 peak=31 max_wait=35.8m wall=3126.4s.
Delayed6764/4340 reports 12:30:00 complete=67/200 peak=31 max_wait=40.9m wall=3119.4s.
All four original command/parent identities match launch968f3301. Both have empty
errors and no final audit. All4836 source hashes,six original observers and five
acceptance/selection hashes remain unchanged. No source edit,new job,restart or
installation. Both original results remain pending; partial progress is not
acceptance,capacity or recovery proof. No gameplay playtest before passing V2 install.

28 October 03:49 — both original35 V2 runs continue with frozen inputs.

At03:49:15 baseline14568/15696 reports 11:00:00 complete=61/200 peak=31 max_wait=40.1m wall=3723.6s.
Delayed6764/4340 reports 14:20:00 complete=82/200 peak=34 max_wait=40.9m wall=3749.9s.
All four original command/parent identities match launch968f3301. Both have empty
errors and no final audit. All4836 source hashes,six original observers and five
acceptance/selection hashes remain unchanged. No source edit,new job,restart or
installation. Both original results remain pending; partial progress is not
acceptance,capacity or recovery proof. No gameplay playtest before passing V2 install.

28 October 03:59 — both original35 V2 runs continue with frozen inputs.

At03:59:16 baseline14568/15696 reports 12:30:00 complete=67/200 peak=31 max_wait=40.1m wall=4335.7s.
Delayed6764/4340 reports 16:30:00 complete=100/200 peak=34 max_wait=40.9m wall=4332.6s.
All four original command/parent identities match launch968f3301. Both have empty
errors and no final audit. All4836 source hashes,six original observers and five
acceptance/selection hashes remain unchanged. No source edit,new job,restart or
installation. Both original results remain pending; partial progress is not
acceptance,capacity or recovery proof. No gameplay playtest before passing V2 install.

28 October 04:09 — both original35 V2 runs continue with frozen inputs.

At04:09:17 baseline14568/15696 reports 13:50:00 complete=75/200 peak=34 max_wait=41.0m wall=4943.5s.
Delayed6764/4340 reports 19:00:00 complete=114/200 peak=34 max_wait=40.9m wall=4947.6s.
All four original command/parent identities match launch968f3301. Both have empty
errors and no final audit. All4836 source hashes,six original observers and five
acceptance/selection hashes remain unchanged. No source edit,new job,restart or
installation. Both original results remain pending; partial progress is not
acceptance,capacity or recovery proof. No gameplay playtest before passing V2 install.

28 October 04:19 — both original35 V2 runs continue with frozen inputs.

At04:19:28 baseline14568/15696 reports 15:20:00 complete=89/200 peak=34 max_wait=41.0m wall=5574.8s.
Delayed6764/4340 reports 21:00:00 complete=127/200 peak=34 max_wait=40.9m wall=5534.6s.
All four original command/parent identities match launch968f3301. Both have empty
errors and no final audit. All4836 source hashes,six original observers and five
acceptance/selection hashes remain unchanged. No source edit,new job,restart or
installation. Both original results remain pending; partial progress is not
acceptance,capacity or recovery proof. No gameplay playtest before passing V2 install.

28 October 04:32 — original35 delayed run failed naturally; baseline still running.

Original delayed wrapper6764/child4340 ended at22:10:34 simulated with M033
waiting at MAKM-S3:136/200 complete,peak34,maximum all-location wait2702s,
maximum station wait2454s,zero safety events. Run,actual-summary and three
inspection error files are empty. All-location cumulative396/516,478/516,
507/516,515/516 passes10/20/30 but FAILS45. Station-only205/285,264/285,
280/285,285/285 passes all four gates for this incomplete prefix. No rounding,
complete-population comparison,recovery certificate,acceptance or installation.

Preserved21 exact raw files under network-candidate-thirty-five/failed-predictive-delayed,
including lossless audit/traffic/failure,exact pack,actual summary and three
byte-immutable MAKM/ALLP/AMPA inspections. All4836 current-at-run source hashes,
six original observers and five acceptance/selection hashes verified unchanged.
Original outputs remain. Never rerun unchanged,install failed data or relabel
these fingerprints after a future source change. The unchanged1004-test source
suite and five candidate35 authoring guards remain the existing validation;
no duplicate suite or Classic/native run was launched.

M033 departed booked SRTL21:14:59.25; MAKM is a signal wait,not a booked call.
Its2702s=1374 opposing+1166 ALLP receiving+88 occupied-block+74 route-conflict.
Opposing buckets preserve618 M032,376 S022,154 S038,66 combinedS038/M034,
160 combinedM034/S038. Receiving buckets preserve no-free96 combinedL003/M032,
48 combinedM034/L003/M032,150 combinedM034/S038,72 combinedM034/S038/L011;
approaching116 combinedL003/M032/M034,88 combinedL003/M034,180 combinedM034/L011,
304 combinedM034/L011/S038,112 combinedM034/S038/L011. Do not attribute combined
buckets to individual trains. Occupied blocks:64 L011,12 M032,12 S022;
conflicts:50 L011,12 combinedM032/L011,12 S022.

Actual MAKM claims M033P3,S038P1,incomingM034 P1/P2/P3 alternatives. M033 awaits
opposingM034/S038. Both move north24.6m/s after ALLP departures22:06:52.75 and
22:04:18.75 respectively. Actual ALLP claims L011P3,incomingL012 P1/P2/P3
alternatives,not three simultaneous reservations. L011 arrived22:04:42 with no
departure and awaits ALLP_single held by L012. L012 leftAMPA22:05:48.25 and
moves14.5083m/s toward bookedPunnapra,occupyingPUPR_AMPA_M0. AMPA has no claims.
All three inspections have no future plans and byte-identical before/after
captures. Moving opponents and these snapshots do not prove permanent deadlock
or a runtime defect. Final full-rake axis samples are preserved in provenance;
geometric envelopes alone do not identify shared occupied interlocking resources.

L004 reachedERS21:30:25 and is stabled; M070 cleared the northern boundary
21:50:41.75; S022 reachedERS22:08:38.55 and dwellsuntil22:14:12. M032 leftSRTL
21:58:41.75 and waitsTUVR for movingS021. These are local observations,not
whole-day improvement/capacity/recovery. M054/M104/M058/M056/L028/L031 move;
M088/K1 are in depots. S033 clearedsouth21:49:33.80; S049 stillapproaches.
L030 awaits movingS035 atERL,L038 follows,L032 awaits automatic clearance.
M099 awaitsM056 atNEM;S053 awaitsM099'sNEMreceivingroad;M081/M085 awaitTVCorigin;
M087/M083/L037 are not yet due. L009/M043 move fromnorth,S037 dwellsERS and
M027/M031/M029/S023/M035 are not due. Later-wave and midnight results unproven.
Eleven K1 minute samples preserve braking27.4545764399m by07:31 then unchanged
extents through07:40 after600s hold07:30; not exact controller/recovery proof.
Actual summary has one V001 overtake of K1 atTVCN,not completed multiple-location proof.

At04:31:49 original baseline14568/15696 reports17:30:00,109/200,peak34,
maxwait41.0m,emptyerrors,noaudit. Its command/parent identities still match the
original launch. All runtime/routes/packs/observers/acceptance inputs stay frozen.
Next: wait for this original baseline's final report,preserve its actual queues,
then coordinate departure-only changes from BOTH outcomes. Network200V2 remains
unaccepted/uninstalled; no gameplay playtest and no reliable readiness ETA.

28 October 04:39 — original35 baseline continues with frozen inputs.

At04:39:20 original baseline14568/15696 reports 19:10:00 complete=116/200 peak=34 max_wait=41.0m wall=6759.6s.
Its exact process/parent/command identities match launch968f3301; errors remain
empty and no final audit exists. All4836 source hashes,six original observers
and five acceptance/selection hashes remain unchanged. Original35 delayed failure
is already preserved in71357fb7; no replay or completed inspection repeated.
No source edit,new job,restart or installation. Wait for the original baseline
before coordinated replanning from both outcomes. Partial progress is not
acceptance,capacity or recovery proof; no gameplay playtest before passing V2 install.

28 October 04:49 — original35 baseline continues with frozen inputs.

At04:49:19 original baseline14568/15696 reports 21:00:00 complete=127/200 peak=34 max_wait=41.0m wall=7360.5s.
Its exact process/parent/command identities match launch968f3301; errors remain
empty and no final audit exists. All4836 source hashes,six original observers
and five acceptance/selection hashes remain unchanged. Original35 delayed failure
is already preserved in71357fb7; no replay or completed inspection repeated.
No source edit,new job,restart or installation. Wait for the original baseline
before coordinated replanning from both outcomes. Partial progress is not
acceptance,capacity or recovery proof; no gameplay playtest before passing V2 install.

28 October 05:01 — both original35 runs have ended naturally; baseline evidence preserved.

Original baseline14568/15696 failed at22:10:34 simulated with M033 signalMAKM-S3,
136/200 complete,peak34,all-location maximum2702s,station maximum2458s,zero safety
events,empty run/summary/three inspection errors. All-location404/535,495/535,
525/535,534/535 passes10/20/30 but FAILS45. Station215/302,280/302,299/302,302/302
passes all four gates for the incomplete prefix. Delayed remains396/516,478/516,
507/516,515/516 and205/285,264/285,280/285,285/285 with station maximum2454s.
Matching clocks,finished counts and M033 buckets do not equate populations.

Preserved21 exact raw baseline files under network-candidate-thirty-five/failed-predictive-baseline:
lossless audit/traffic/failure,exact pack,actual summary and three byte-immutable
MAKM/ALLP/AMPA inspections. All4836 current-at-run source hashes and all11
observer/acceptance hashes verified. Baseline original catalogue and final source
hashes match. Three inspection claims match the delayed local queue: MAKM M033P3,
S038P1,incomingM034 P1/P2/P3 alternatives; ALLP L011P3,incomingL012 P1/P2/P3
alternatives; AMPA empty. No future plans in any inspection; alternative road
lists are not simultaneous reservations. Full before/after snapshot bytes match.

Baseline M033 signal-wait records are identical to the delayed records:
2702s=1374 opposing+1166 ALLP receiving+88 occupied-block+74 route-conflict,
with every combined reason bucket preserved separately. M034/S038 move north;
L011 awaits movingL012 on ALLP_single. No permanent-deadlock/runtime-defect proof.
Selected northern paths/calls/speeds match for M033/M034/M032/S022/L011/L003/L004;
small numerical and call-time differences elsewhere remain in the exact reports.
Do not turn local matches into a complete-population or recovery comparison.
Baseline actual summary has no K1 overtakes; delayed has one V001 atTVCN.
Neither is completed multiple-location overtake proof. No acceptance or install.

Both original jobs are absent; no Classic,suite,native,search or diagnostic job
remains. Delayed evidence was already pushed71357fb7; originals remain untouched.
Next: coordinate departure-only candidate36 from BOTH actual failed queues and
full-rake movement records. Retain200 selected services,all non-departure fields,
K1 and all safety/wait/physical/recovery gates. No unchanged rerun or gameplay playtest.

28 October 05:06 — candidate36 authored after both original35 failures were preserved.

Candidate36 changes only M033 departure20:30->21:25. Restoring that one string
recovers each entire predecessor JSON. All other services and non-departure
fields,K1at06:00,raw208template and exact selected200 IDs remain unchanged.
Both common-author packs have identical service records; no Classic readiness claim.
Retain L01120:20,L00320:00,M05919:55,M05519:45,M06919:25,all northbound/southern
departures and candidate35's seven northern shifts. Same200=40local96mail56superfast
8VB,160boundary journeys,83overnight origins,3–18starts/hour. The aggregate maximum
18 at22 is descriptive; authoritative minimum3/hour and all acceptance gates remain.

Both actual35 runs show M033's2702s MAKM-S3 signal wait after bookedSRTL21:14:59.25.
Actual MAKM geometric envelopes include S02221:22:44–21:31:48,M03221:39:14–21:48:18,
L01121:49:34–22:03:30,then S03822:05:22 and M03422:07:56,still moving at failure.
Moving M03355minutes later seeks a later MAKM/ALLP approach after that opposing
flow and L011 receiving occupation,while retaining all opposing departures.
Actual KUMM northbound M070 ends21:34:32,S022 ends21:59:10; retained S021's
southbound envelope begins22:00:50. Those are observations of35,not predictions
for36. M033 now departs20minutes before retainedS02121:45 and meets laterL00922:00,
S03722:05,M04322:10,M02722:15 and northbound through trains. Its changed approach
can alter the crossing order. Compatible roads,full-tail clearance,origin queues,
overtakes,later waves and midnight completion remain unproven. No gap guarantees
crossing order,escape or capacity; no whole-day improvement claim.

candidate-thirty-six-sampled-groups.json/sample-v35-groups-for36.py preserve BOTH
actual35 full-rake axis overlaps11:00–failure,source/report hashes,static bounds,
formula,approximately2s samples and censoring. ALLP–AMPA bounds are station centres
with half-width+200m exclusion; southern bounds retained from23. These are planning
inputs,not exact interlocking ownership,assigned roads or guaranteed clearance.
Overlapping envelopes do not prove shared occupied interlocking resources.

Normal author and exact--check reproduce both packs from205overrides and unchanged
selection. Five headless authoring guards PASS,emptyerrors. All4835 previous
railway inputs exceptNetworkpack and all11 observer/acceptance hashes unchanged.
Retain the completed1004-test candidate33 source suite; no unchanged full-suite or
legacy checks repeated. Thirteen exact raw authoring proofs are preserved under
network-candidate-thirty-six; exact predecessors in candidate-thirty-six-before.
V2 raw SHA256:1e21a45136b74cffae499192ef3e2bbb4d9fcdb83e576ae6f0e160410284dd45.

Original35 baselinea496f8d5 and delayed71357fb7 preserve21+21 exact raw files,
4836 source hashes each and six immutable MAKM/ALLP/AMPA inspections. Both failed
M03322:10:34,136/200,peak34,all-location2702s,zero safety. Baseline station2458s,
delayed2454s; each station population passes all gates only for its failed prefix,
all-location fails45. All35 fingerprints are now HISTORICAL after36; never relabel,
rerun unchanged or install. Equal clocks/local wait records do not equate complete
populations; no recovery certificate. Older evidence remains intact.

Next: commit/push this verified authoring increment,then launch exactly one new
normal V2 --network --snapshots and one delayed --network --delay=600 --delay-at=27000
in isolated rehearsals-v36. Verify actual identities/options,original baseline
catalogue,4836 distinct sources and11 observer/acceptance hashes; freeze inputs
while either original36run lives. Network200V2 remains unaccepted/uninstalled.
No gameplay playtest and no reliable readiness ETA.

28 October 05:06 — original candidate36 V2 pair launched once and verified.

Author3b3ac4ba6b952ecf7b7527bc0aea65646a3e0862 was committed/pushed before launch.
Both original jobs launched once05:05:47 in fresh isolated rehearsals-v36:
normal wrapper18424/child6760 with --network --snapshots;
delayed wrapper18356/child23568 with --network --delay=600 --delay-at=27000.
All four actual command/parent identities,options and unique output paths verified.
The original baseline catalogue existed before verification;4836 distinct source
hashes,six original observers and five acceptance/selection hashes verified.
Five exact launch files plus manifest are preserved under
network-candidate-thirty-six/launch-proof. inspect-current-replays.py selects36first.

At05:06:24 baseline reports 00:10:00 complete=0/200 peak=3 max_wait=0.1m wall=31.8s.
Delayed reports 00:30:00 complete=0/200 peak=4 max_wait=0.1m wall=28.0s.
Both have empty errors and no final audit. Partial clocks are not acceptance.
DO NOT execute launch-network-v36.ps1 or verify-launch-v36.py again,duplicate or
restart. Freeze runtime/routes/packs,the six original observers and five acceptance/
selection files while either original36run lives. No Classic,suite,native,search or
diagnostic job remains. Both35 failures are historical and preserved separately
in baselinea496f8d5/delayed71357fb7; no failed/partial/disturbed data was installed.
Next: inspect BOTH original36 final reports,preserve actual queues before further
coordinated departure-only replanning. Network200V2 remains unaccepted/uninstalled;
no gameplay playtest and no reliable readiness ETA.

28 October 05:09 — both original candidate36 V2 runs remain active.

At 05:09:18, baseline 18424/6760 reports 01:10 simulated, 0/200 complete,
peak 12 and maximum wait 0.1 minutes. Delayed 18356/23568 reports 01:50,
1/200 complete, peak 16 and maximum wait 6.1 minutes. Both error logs are
empty and neither final audit exists. All four process/parent/command records
match the original launch; all 4836 distinct source hashes, six observer hashes
and five acceptance/selection hashes remain unchanged. Inputs remain frozen;
no job was launched or restarted. Partial progress is not acceptance.

Await both original final reports before coordinated departure-only replanning.
Network 200 V2 remains unaccepted and uninstalled; no gameplay playtest or
reliable readiness ETA. Existing source and authoring test results are retained;
this checkpoint changes documentation only.

28 October 05:19 — original candidate36 runs continue; final audits pending.

At 05:19:32, baseline 18424/6760 reports 03:30 simulated, 2/200 complete,
peak 25 and maximum wait 7.4 minutes. Delayed 18356/23568 reports 04:30,
10/200 complete, peak 29 and maximum wait 9.3 minutes. Both error logs remain
empty, with no final audits. All four original process/parent/command identities,
4836 source hashes and 11 observer/acceptance hashes match launch records.
No additional Godot job is present. All simulation inputs remain frozen.

No launch, restart, source change or installation occurred. Retain the existing
1004-test source suite and five authoring guards. Await both original final
reports; partial progress is not acceptance. Network 200 V2 remains unaccepted
and uninstalled, with no gameplay playtest or reliable readiness ETA.

28 October 05:29 — candidate36 original runs remain active.

At 05:29:20, baseline 18424/6760 reports 05:00 simulated, 16/200 complete,
peak 29 and maximum wait 26.0 minutes; delayed 18356/23568 reports 06:30,
25/200 complete, peak 31 and maximum wait 31.1 minutes. Both error logs are
empty and final audits are absent. All four process/parent/command identities
match launch records; 4836 source hashes and all 11 observer/acceptance hashes
remain unchanged. No other Godot job is present. Inputs remain frozen, with
no launch, restart, source edit or installation. Existing source/authoring test
results remain applicable. Await both original final reports; partial clocks
and waits are not acceptance. Network 200 V2 remains unaccepted/uninstalled;
full-day feasibility and readiness ETA remain unproven. No gameplay playtest.

28 October 05:39 — original candidate36 runs still await final audits.

At 05:39:23, baseline 18424/6760 reports 06:30 simulated, 25/200 complete,
peak 31, maximum wait 31.1 minutes. Delayed 18356/23568 reports 08:20,
34/200 complete, peak 31, maximum wait 35.8 minutes. Both error logs remain
empty; neither final audit exists. All four original identities and commands,
4836 source hashes and 11 observer/acceptance hashes remain unchanged.
No other Godot job is present. Inputs stay frozen; no launches, source edits,
installation or gameplay playtest occurred. Existing test results are retained.
Await both original final reports before replanning; these partial results do
not establish acceptance or full-day feasibility. Network 200 V2 remains
unaccepted and uninstalled, with no reliable readiness ETA.

28 October 05:49 — original candidate36 pair continues with inputs frozen.

At 05:49:20, baseline 18424/6760 reports 08:00 simulated, 33/200 complete,
peak 31 and maximum wait 35.8 minutes; delayed 18356/23568 reports 10:40,
59/200 complete, peak 31 and maximum wait 40.9 minutes. Both error logs are
empty and neither final audit exists. Four original process/parent/command
identities, all 4836 source hashes and 11 observer/acceptance hashes match.
No additional Godot job is present. Existing tests remain applicable; no jobs
were launched or restarted and no simulation input or installed data changed.
Await both original final reports before replanning. Partial progress is not
acceptance; Network 200 V2 remains unaccepted/uninstalled, with full-day
feasibility unproven, no reliable readiness ETA and no gameplay playtest.

28 October 05:59 — original candidate36 pair remains active.

At 05:59:22, baseline 18424/6760 reports 09:40 simulated, 49/200 complete,
peak 31, maximum wait 35.8 minutes; delayed 18356/23568 reports 12:50,
69/200 complete, peak 32, maximum wait 40.9 minutes. Both error logs are empty;
no final audit exists. All four original identities, 4836 source hashes and 11
observer/acceptance hashes match. No other Godot job is present. Inputs remain
frozen; no launch, restart, source change, installation or gameplay playtest.
Existing tests are retained. Await both original final reports before replanning.
Partial results are not acceptance; Network 200 V2 remains unaccepted/uninstalled,
with full-day feasibility unproven and no reliable readiness ETA.

28 October 06:09 — original candidate36 runs continue; final audits pending.

At 06:09:21, baseline 18424/6760 reports 11:20 simulated, 61/200 complete,
peak 31, maximum wait 40.1 minutes; delayed 18356/23568 reports 14:40,
86/200 complete, peak 34, maximum wait 40.9 minutes. Both error logs are empty
and neither final audit exists. All four original identities, 4836 source hashes
and 11 observer/acceptance hashes remain unchanged; no other Godot job is present.
Inputs remain frozen, existing tests retained, and no launch, restart, source edit
or installation occurred. Await both original final reports before replanning.
Partial results are not acceptance; Network 200 V2 remains unaccepted/uninstalled,
with no gameplay playtest, proven full-day feasibility or reliable readiness ETA.

28 October 06:19 — original candidate36 runs continue with no final audits.

At 06:19:19, baseline 18424/6760 reports 12:40 simulated, 69/200 complete,
peak 31, maximum wait 40.1 minutes; delayed 18356/23568 reports 17:10,
109/200 complete, peak 34, maximum wait 40.9 minutes. Both error logs are empty.
All four original process/parent/command identities, 4836 source hashes and 11
observer/acceptance hashes match launch records; no other Godot job is present.
Inputs remain frozen and existing tests retained. No launch, restart, source edit,
installation or gameplay playtest occurred. Await both original final reports
before replanning. Network 200 V2 remains unaccepted/uninstalled; these partial
results do not prove full-day feasibility, and no reliable readiness ETA exists.

28 October 06:29 — original candidate36 pair still awaits final reports.

At 06:29:19, baseline 18424/6760 reports 14:00 simulated, 77/200 complete,
peak 34, maximum wait 41.0 minutes; delayed 18356/23568 reports 19:30,
118/200 complete, peak 34, maximum wait 40.9 minutes. Both error logs remain
empty and final audits are absent. All four original process/parent/command
identities, 4836 source hashes and 11 observer/acceptance hashes match launch
records; no additional Godot job is present. Inputs stay frozen, tests retained,
with no launch, restart, source edit, installation or gameplay playtest.
Await both original final reports before replanning. Partial results are not
acceptance; Network 200 V2 remains unaccepted/uninstalled, full-day feasibility
unproven and readiness ETA unavailable.

28 October 06:39 — original candidate36 runs remain active.

At 06:39:20, baseline 18424/6760 reports 15:30 simulated, 92/200 complete,
peak 34, maximum wait 41.0 minutes; delayed 18356/23568 reports 21:30,
130/200 complete, peak 34, maximum wait 40.9 minutes. Both error logs are empty;
neither final audit exists. All four original identities, 4836 source hashes and
11 observer/acceptance hashes remain unchanged. No other Godot job is present.
Inputs stay frozen and existing tests are retained. No launch, restart, source
edit, installation or gameplay playtest occurred. Await both original final
reports before replanning; partial progress is not acceptance. Network 200 V2
remains unaccepted/uninstalled, with full-day feasibility and readiness ETA unproven.

28 October 06:49 — original candidate36 pair remains active; no final audits.

At 06:49:20, baseline 18424/6760 reports 17:00 simulated, 108/200 complete,
peak 34, maximum wait 41.0 minutes; delayed 18356/23568 reports 23:00,
140/200 complete, peak 37, maximum wait 40.9 minutes. Both error logs are empty.
All four original process/parent/command identities, 4836 source hashes and 11
observer/acceptance hashes match; no other Godot job is present. Inputs remain
frozen, existing tests retained, and no launch, restart, source edit, installation
or gameplay playtest occurred. Await both original final reports before replanning.
Partial clocks and counts do not establish acceptance, recovery or whole-day
improvement. Network 200 V2 remains unaccepted/uninstalled; full-day feasibility
is unproven and there is no reliable readiness ETA.

28 October 07:07 — candidate36 delayed failed naturally at S055's TVC origin; original baseline remains running.

The original delayed wrapper18356/child23568 ended at 23:17:32 simulated after
its configured 600-second K1 intervention at 07:30. The actual final audit has
142/200 complete, peak40, zero safety events, and maximum2702 seconds in both
wait populations. S055's failed wait is the booked TVC origin (call0), not a
recorded signal-wait entry; it has not departed. Run, actual summary and all
four saved-state inspection error logs are empty. Summary `finished` means the
final audit exists, not that all200 services completed.

Exact cumulative counts under10/20/30/45 minutes: all-location413/563,
504/563,539/563,562/563 pass10 but fail20/30/45; station-only213/305,
277/305,293/305,304/305 fail10/30/45 and pass20. In particular213/305 is
below70%,504/563 below90%; neither is rounded up. These are failed-prefix
populations, not an equal complete-population comparison or recovery certificate.

Preserved24 exact raw files in
`art/performance/realism-2026-10-26/network-candidate-thirty-six/failed-predictive-delayed`:
lossless audit/traffic/failure and final receiving inspection, original logs,
actual summary, four immutable NEM/NYY/PASA/KZT inspections, exact pack,
inspection tool and jobs record. Provenance verifies all4836 distinct source
hashes against current frozen inputs, the six original observers and five
acceptance/selection hashes, plus equality with the original baseline catalogue.
The original files remain; no replay or station inspection was repeated.

S055's2702-second wait comprises154 seconds with M081 as NEM receiving
blocker,2528 with combinedM081/M085, and20 with combinedM081/M085 approaching
capacity. Combined buckets are not apportioned to individual trains.
Actual NEM claims are M081P1/M085P2; both stopped, awaiting NYY roads held by
S053P1/L028P2. S053 is passing NYY, not calling there, and awaits PASA receiving
capacity: M099P1 plus incomingL030's P1/P2 alternatives, not two simultaneous
reservations. M099 arrived PASA22:46:08.75 without departure and has1814 audited
extra-wait seconds for L030 holding PASA_single; L030 is stopped before
PASA_KZTW_M0-NH, preserving a crossing road at NYY for S053, while its P1
alternative is occupied by M099. L028 arrived NYY22:36:23.35 without departure
and now awaits NEM M081/M085; its2402 seconds preserve2338 combined receiving
plus64 earlier future-arrival wait for S053 after M099. All four inspections
have no future-clearance plans and identical before/after world captures.

M081/M085 departed TVC22:26:18.25/22:29:26.25 and now have2634/2446 audited
signal-extra-wait seconds at NEM. Dispatcher continuous ages2731/2543 seconds
are different measures. KZT's sole claim is L038P2, stopped and preserving NYY
crossing capacity for S053. S040 waits at ERL for L038's onward route with
M099 also constraining the exit; L032 waits behind S040. L031 is stabled in
NCJ depot. M087/M083/M091/M073/M089/L037 await the TVC origin berth. These
actual dependencies do not by themselves prove permanent deadlock or a runtime
defect; no physical rule or acceptance gate has changed.

Other actual delayed observations: M033 departed SRTL22:06:28.75, arrived
ALLP22:36:08.35 and departed23:09:58.25; it is moving24.6m/s toward AMPA.
Its ALLP1908-second wait includes1210 waiting for S021's overtake and154 for
M072 to cross, with all remaining buckets preserved in raw evidence. M027 left
ERS23:04:48.75 after2562 extra-wait seconds and moves south; M003 and the moving
M031 next-departure decision await TUVR S038/M043/incomingM027. M043 approaches
TUVR while awaiting SRTL L012/M072/S037 capacity; S038 awaits opposingM027.
S037 moves9.322222m/s toward SRTL-S3 under authority south; M072 awaits its
point/route clearance, L012 waits for M072's overtake, and M054 awaits S037 at
MAKM. Later M029 moves, S023 awaits S039 at the northern entry, and M035 awaits
a clear origin berth. M104/M058/M056 move. M032/M034/M070/S022 and S033/S049
are stabled beyond their map portals; K1/L004/M088 are in depots.
The final31 two-second full-rake samples are preserved, including moving
M033/S037 and stationary L030. Axis envelopes alone do not prove shared occupied
interlocking resources. These local observations are not whole-day improvement,
capacity, escape or recovery evidence.

Eleven K1 minute samples show braking27.4545764399m by07:31 with unchanged
extents through07:40, not an exact controller trace or recovery proof. The actual
summary contains one V001 overtake of K1 at TVCN, not completed multiple-location
proof. Later waves and midnight completion remain unproven.

At07:04:23 the original baseline18424/6760 still reports20:10 simulated,
124/200 complete,peak34,maxwait41.0minutes,empty errors,no final audit. Its
exact process/parent/command identities match the launch. All inputs remain
frozen until it ends; preserve its actual evidence before coordinated departure-only
replanning from both outcomes. No Classic/suite/native/search job remains;
retain the existing1004-test candidate33 suite and five authoring guards. Network
200 V2 remains unaccepted/uninstalled, with no gameplay playtest, proven full-day
feasibility or reliable readiness ETA.

28 October 07:09 — original candidate36 baseline continues; no final audit.

At07:09:32, baseline18424/6760 reports21:00 simulated,128/200 complete,
peak34,maxwait41.0minutes,empty errors. Exact process/parent/command identities,
all4836 source hashes and11 observer/acceptance hashes remain unchanged; no
additional Godot job is present. The delayed failure remains preserved in1773eafe;
its summary and four station inspections were not repeated. Inputs stay frozen,
existing tests retained, with no launch, restart, source edit or installation.
Await the original baseline final audit and preserve its actual queues before
replanning from both outcomes. Partial progress is not acceptance. Network200V2
remains unaccepted/uninstalled; no gameplay playtest or reliable readiness ETA.

28 October 07:19 — original candidate36 baseline remains running.

At07:19:26, baseline18424/6760 reports22:30 simulated,138/200 complete,
peak35,maxwait41.0minutes,empty errors,no final audit. Both original process/
parent/command identities,4836 source hashes and11 observer/acceptance inputs
match the launch; no additional Godot job is present. Delayed failure1773eafe
and its completed summary/four inspections remain preserved without repetition.
All inputs stay frozen. No launch, restart, source edit, installation or playtest;
existing tests are retained. Await the original baseline's actual final report
before preserving its queues and replanning from both outcomes. Partial progress
is not acceptance; Network200V2 remains unaccepted/uninstalled, full-day
feasibility unproven and readiness ETA unavailable.

28 October 07:32 — both original candidate36 runs ended naturally and failed; baseline evidence preserved.

Original baseline18424/6760 failed at23:17:16 simulated on S055's booked TVC
origin(call0), with142/200 complete,peak40,max2702seconds in both wait
populations and zero safety events. Its delay/delay_at are0/0; actual summary has
no K1 overtakes. Run/summary/four inspection errors are empty. Baseline final
clock differs from delayed23:17:32; matching completion counts and local claims
do not equate wait populations or complete operating days.

Baseline all-location420/580,519/580,556/580,579/580 pass10 but fail20/30/45;
station223/321,292/321,312/321,320/321 fail10/30/45 and pass20. No rounding:
519/580 is below90%,223/321 below70%,312/321 below98%. Delayed remains
413/563,504/563,539/563,562/563 and213/305,277/305,293/305,304/305,
respectively. All fractions describe incomplete failed prefixes. No acceptance,
complete-population comparison, recovery certificate or installation.

The baseline archive preserves24 exact raw files, including lossless audit,
traffic/failure/receiving state, actual summary, four byte-immutable NEM/NYY/PASA/
KZT inspections, exact pack, original logs, tool and jobs record, at
`art/performance/realism-2026-10-26/network-candidate-thirty-six/failed-predictive-baseline`.
All4836 current-at-run source hashes, six observers and five acceptance/selection
hashes match unchanged inputs and the original baseline catalogue. Original
files remain. The delayed archive is already pushed in1773eafe; no summary,
inspection or original rehearsal was repeated. Both original pairs are absent;
no other Godot job remains. Source edits have not yet begun.

Baseline S055 has not departed:2702seconds=152M081 NEM receiving+2530combined
M081/M085 receiving+20combinedM081/M085 approaching capacity. Preserve those
combined buckets without individual attribution. NEMclaimsM081P1/M085P2;
NYYclaimsS053P1/L028P2; PASAclaimsM099P1 with incomingL030 P1/P2 alternatives,
not two simultaneous reservations; KZTclaimL038P2. All eight baseline/delayed
inspections have no future-clearance plans and identical before/after captures.

Baseline M081/M085 departed TVC22:26:01.75/22:29:09.25, now stopped at NEM
awaiting S053/L028 at NYY. Audited signal-extra waits2636/2448 each preserve
1980combined receiving plus656/468 reserved S053 approach. Dispatcher continuous
ages2731.5/2544 are distinct measures. S053 leftTVC22:18:23.75 and waits at
NYY-S1 for PASA M099/incomingL030; audited2344=1980combined+364L030 alone.
L028 arrivedNYY22:35:13.75,nodeparture,now awaitsNEMM081/M085;
2456=2392combined receiving+64earlier S053 future arrival afterM099.
M099 arrivedPASA22:44:58.75,nodeparture,1868seconds for L030 holdingPASA_single.
L030 stopped beforePASA_KZTW_M0-NH, preserving a NYY crossing road forS053;
its P1alternative is occupied byM099. Its2068audited signal seconds preserve
1980combinedS053/M099+88S053. L038 waitsKZT for that NYY crossing capacity;
S040 waitsERL for L038's onward route withM099 exit constraint;L032 follows.
These actual stopped dependencies do not prove permanent deadlock/runtime defect.

Baseline M033 leftALLP23:09:25.75 and moves24.6m/s towardAMPA. S037 moves
9.322222m/s towardSRTL-S3 with authoritysouth whileM072 awaits its point/route
clearance;M054 waits forS037 atMAKM. M104 moves20.479109m/s north. L031 is
stabledNCJdepot. All selected services, waits, claims and the final31two-second
full-rake samples are preserved. Geometry alone is not shared-resource ownership
proof; local movements are not whole-day improvement/capacity/recovery claims.

Next: use BOTH actual36 outcomes for coordinated departure-only replanning,
retaining selected200IDs, all non-departure fields and all acceptance gates.
The completed1004-test candidate33 suite and five candidate36 authoring guards
remain valid for their unchanged inputs. No Classic work, installation or gameplay
playtest; Network200V2 is still unaccepted/uninstalled, full-day feasibility
unproven and readiness ETA unavailable.

28 October 07:38 — candidate37 disperses seven evening TVC mails; authoring proof passes, full runs pending.

Both original36 runs ended naturally and their exact failed evidence is pushed:
baseline65a46d28 and delayed1773eafe. Source37 changes only seven departure
strings: M08121:30->12:05,M08521:45->12:20,M09122:15->13:05,
M08722:20->14:35,M07322:30->16:25,M08322:35->17:10,M08922:45->18:10.
Undoing those strings recovers each entire predecessor JSON. Same selected200
IDs, exact eight-mail exclusion, all retained non-departure fields, K106:00,
and identical common-author services. Equality does not establish Classic readiness.
All northbound and northern-origin departures remain unchanged, including36's
M03321:25 and35's seven northern shifts. RetainM09920:35,S05321:10,S05522:05,
L03922:50,S04123:00,L03723:15,S04323:55 and all other superfast/local/VB services.

The coordinated hypothesis addresses both36's actual evening chain: M081/M085
hold both NEM roads; L028 cannot leave NYY; S053 waits for PASA M099/incomingL030;
M099 waits for L030's single line and L030 preserves a NYY crossing road.
Moving only the first two mails later would let the following mails replace them.
This candidate instead spreads those seven mails across daytime origin slots,
retaining the evening superfast/local group and every opponent. It is not a claim
that removing those seven evening origins guarantees the remaining trains' escape.

Both actual36 traffic streams were sampled11:00 through each distinct failure;
`sample-v36-groups-for37.py` and `candidate-thirty-seven-sampled-groups.json`
preserve the static bounds, formula, source/report hashes, two-second sampling,
censoring and full-rake overlaps. The12:05/12:20 choices follow observed L025/K1
NEM envelope endings11:52/12:06 before northboundM06812:48; NYY's southbound
samples extend to12:12/12:22 before M06812:36. These are36 observations, not37
passage predictions. M096/S050/M086/L036/L026/S048/S034/M082 and retained
S031/M051/M101/V007 constrain13-15; L004/S054/M102/S036/M070 withM097/L027/
M103 constrain16-18; M049/M065,S038/V008 constrain18:10. All remain retained.
Geometric bounds are not exact interlocking ownership, assigned roads, guaranteed
gaps, capacity, onward escape or full-tail clearance. No isolated-model score.
Earlier changes can alter the entire later railway and cause new waits.

205 overrides reproduce both packs normally and with exact --check; five
headless Network authoring guards pass with empty errors. Preserve the completed
1004-test candidate33 suite: runtime/tests and4835 railway inputs other than the
Network pack, plus all11 observer/acceptance inputs, remain unchanged. Thirteen
exact authoring proof files are archived in network-candidate-thirty-seven;
predecessor copies remain in candidate-thirty-seven-before. V2 raw SHA256
`ef937c228e5e1c617529b65e160634b08ba5512353230d3b25a3329b28964c94`.
Population remains40local/96mail/56superfast/8VB,160boundary journeys;
overnight origins78(previously83),hourly starts3-15. Maximum15at23 is descriptive,
not an acceptance cap; the authoritative density minimum remains3/hour.
All36 fingerprints are now historical; never relabel them as source37 evidence.

Next: exactly one new isolated V2 baseline --network --snapshots and one delayed
--network --delay=600 --delay-at=27000. Verify originals/options/unique outputs,
original baseline catalogue,4836distinct hashes and11 frozen inputs, then freeze
until both original37 runs end. No Classic work, changed runtime, weakened gate,
installation or gameplay playtest. Network200V2 remains unaccepted/uninstalled;
full-day feasibility, multiple-location overtake/recovery and midnight completion
remain unproven, with no reliable readiness ETA.

28 October 07:39 — both original candidate37 V2 runs launched once and verified; inputs frozen.

Author2f4a9c35787b34031f91b44c91ee13df91745f06 is pushed. The new isolated
baseline23304/6112 and delayed11576/1016 launched once at07:39:06. Baseline
uses --network --snapshots; delayed uses --network --delay=600 --delay-at=27000.
Their original baseline catalogue existed before verification. All four actual
commands, parent identities and options, two unique outputs,4836distinct source
hashes, six original observers and five acceptance/selection inputs were verified.
Five exact launch files plus their raw manifest are preserved in
network-candidate-thirty-seven/launch-proof and verified against staged bytes.
Do not execute launch-network-v37.ps1 or verify-launch-v37.py again.

At07:39:23 baseline has no first progress line; delayed00:10 simulated,0/200,
peak3,maxwait0.1minutes. Both error logs are empty and neither final audit exists.
inspect-current-replays.py now selects37 first. No Classic, full suite, native,
search or diagnostic job remains. Freeze runtime/routes/packs and all11 inputs
while either original37 run lives. Wait both actual final reports before any
further departure-only replan. All36 fingerprints are historical; both failed
archives65a46d28/1773eafe remain intact. Partial progress is not acceptance.
Network200V2 remains unaccepted/uninstalled; no gameplay playtest or reliable ETA.

28 October 07:44 — original candidate37 pair continues; no final audit.

At07:44:29 original baseline23304/6112 reports01:40 simulated,1/200 complete,
peak14,maxwait6.1minutes; original delayed11576/1016 reports02:30,1/200,
peak21,maxwait6.1minutes. Both error logs are empty and final audits absent.
All four exact process/parent/command identities still match the original launch;
4836 source hashes, six observers and five acceptance/selection hashes remain
unchanged. No other Godot job exists. No restart, duplicate, source edit,
summary, inspection, installation or gameplay playtest was performed. Inputs
remain frozen while either original37 lives. Partial progress is not acceptance;
Network200V2 remains unaccepted/uninstalled with no reliable readiness ETA.

28 October 07:54 — original candidate37 pair continues; no final audit.

At07:54:25 original baseline23304/6112 reports03:40 simulated,2/200 complete,
peak27,maxwait7.4minutes; original delayed11576/1016 reports04:40,13/200,
peak29,maxwait18.6minutes. Both error logs are empty and final audits absent.
All four exact process/parent/command identities still match the original launch;
4836 source hashes, six observers and five acceptance/selection hashes remain
unchanged. No other Godot job exists. Inputs remain frozen while either original37
lives; no restart, duplicate or source change. Partial progress is not acceptance.
Network200V2 remains unaccepted/uninstalled with no gameplay playtest or reliable
readiness ETA. The completed candidate33 suite and candidate37 authoring guards
were retained without rerunning unchanged checks.

28 October 08:04 — original candidate37 runs remain active; final audits pending.

At08:04:27 original baseline23304/6112 reports05:20 simulated,16/200 complete,
peak29,maxwait31.1minutes; original delayed11576/1016 reports06:40,25/200,
peak31,maxwait31.9minutes. Both error logs are empty and final audits absent.
All four exact process/parent/command identities match the original launch;
4836 source hashes and all11 observer/acceptance hashes remain unchanged.
Only the original pair is running. Inputs remain frozen; no new rehearsal,
source edit, repeated suite, installation or gameplay playtest. Partial progress
is not acceptance. Await both original37 final reports; Network200V2 remains
unaccepted/uninstalled and full-day feasibility has no reliable ETA.

28 October 08:14 — original candidate37 pair active; inputs remain frozen.

At08:14:29 original baseline23304/6112 reports06:40 simulated,25/200 complete,
peak31,maxwait31.9minutes; original delayed11576/1016 reports08:40,38/200,
peak31,maxwait40.9minutes. Error logs remain empty and neither final audit exists.
The four exact process/parent/command identities match the original launch;
all4836 source hashes, six observers and five acceptance/selection hashes remain
unchanged. Only the original pair is running. No source edit, duplicate, restart,
repeated suite, installation or gameplay playtest. Await both original37 finals.
Partial progress is not acceptance; Network200V2 remains unaccepted/uninstalled.
Full-day feasibility remains unproven and no reliable readiness ETA is available.

28 October 08:24 — original candidate37 pair continues with unchanged inputs.

At08:24:26 original baseline23304/6112 reports08:10 simulated,33/200 complete,
peak31,maxwait35.8minutes; original delayed11576/1016 reports10:50,60/200,
peak31,maxwait40.9minutes. Both error logs are empty and final audits absent.
All four exact process/parent/command identities still match the original launch;
4836 source hashes, six observers and five acceptance/selection hashes are unchanged.
No other Godot job exists. Inputs remain frozen while either original37 lives;
no restart, duplicate, source change, repeated suite, installation or playtest.
Await both original final reports before replanning. These partial prefixes do not
establish acceptance, recovery or whole-day improvement. Network200V2 remains
unaccepted/uninstalled; full-day feasibility and a reliable ETA remain unproven.

28 October 08:34 — original candidate37 runs continue; no final audit.

At08:34:24 original baseline23304/6112 reports09:40 simulated,49/200 complete,
peak31,maxwait35.8minutes; original delayed11576/1016 reports12:50,69/200,
peak34,maxwait40.9minutes. Both error logs remain empty and final audits absent.
All four exact process/parent/command identities match the original launch;
4836 source hashes and all11 observer/acceptance hashes remain unchanged.
No other Godot job exists. Inputs remain frozen until both original37 runs end.
No source edit, duplicate, restart, repeated suite, installation or gameplay
playtest. Partial progress is not acceptance or proof of whole-day improvement.
Network200V2 remains unaccepted/uninstalled; full-day feasibility remains
unproven and no reliable readiness ETA is available.

28 October 08:44 — original candidate37 pair remains active; no final audit.

At08:44:25 original baseline23304/6112 reports11:20 simulated,61/200 complete,
peak31,maxwait40.1minutes; original delayed11576/1016 reports14:30,85/200,
peak37,maxwait40.9minutes. Both error logs are empty and final audits absent.
All four exact process/parent/command identities match the original launch;
4836 source hashes, six observers and five acceptance/selection hashes remain
unchanged. Only the original pair is running. Inputs remain frozen until both
original37 runs end. No restart, duplicate, source edit, repeated suite,
installation or gameplay playtest. Partial progress is not acceptance or
whole-day capacity/recovery proof. Network200V2 remains unaccepted/uninstalled;
full-day feasibility remains unproven and readiness ETA is unavailable.

28 October 08:57 — original candidate37 delayed failed at booked NYY; baseline remains frozen and running.

Original delayed11576/1016 ended naturally at16:04:44 simulated, failing M051's
booked Neyyattinkara call14, not a signal-wait entry. It completed98/200,peak37,
maximum2702seconds in both wait populations,zero safety events, after600seconds
K1 hold at07:30. Run, actual-summary and four inspection error logs are empty.
All-location272/377,333/377,363/377,376/377 pass10 but fail20/30/45minutes;
station-only135/207,181/207,198/207,206/207 fail all four gates. No rounding,
complete-population comparison, recovery certificate, acceptance or installation.

24 exact raw files are preserved in
`art/performance/realism-2026-10-26/network-candidate-thirty-seven/failed-predictive-delayed`:
lossless audit/traffic/failure and receiving state, exact pack, original logs,
actual summary, four NEM/NYY/PASA/KZT inspections, inspection tool and jobs record.
Provenance verifies all4836 current-at-run source hashes against the original
baseline catalogue and all11 observer/acceptance inputs. Every inspection has
identical before/after captures and no future clearance plans. Originals remain;
never rerun unchanged, install failed data or relabel these hashes after source edits.

M051 reachedNYY15:18:33.80 and never departed. Its2702audited extra seconds are
1710opposing (S052568,S034568,M082574),956PASA receiving (M087178,
combinedM087/S052408,combinedM087/M08262,S034308),and36route conflicts
(12eachS052/S034/M082). Preserve combined buckets without individual attribution.
Its current next-signal decision NYY-S1 awaits M087 onPASA_P1; the recorded
2702.5dispatcher continuous age differs from2702audited extra seconds.

Actual claims: NEM V007P2 plus incomingM082 P1/P2 alternatives, not simultaneous
reservations; NYY M051P1/M082P2; PASA M087P1/S054P2; KZT L004P2.
M087 reachedPASA15:25:32.25,never departed,2286extra seconds:1166opposing,
1096receiving and24conflicts. It now awaits movingS054 inPASA_single.
S054 leftKZT15:58:28.75 and moves16.267826m/s towardPASA-N2,occupying
PASA_KZTW_M0/PASA_RLEAD_U; its next decision awaitsNYY M051/M082.
M082 leftNYY16:03:40.75 and moves14.664539m/s north under authority while
its tail still occupiesNYY_P2/NYY_LLEAD_U. V007 waitsNEM-S2 forM082,
with1336audited signal extra seconds versus1433dispatcher continuous age.
L004 reachedKZT15:42:11.90,never departed,1286audited extra seconds and
1287dispatcher age,now awaitsM087 atPASA. Moving opponents and these snapshots
are not proof of permanent deadlock, available escape or a runtime defect.

M081/M085/M091 are stabled beyond the southern portal after13:56:05.30,
14:10:42.80 and14:35:21.00; S031 cleared14:58:05.30. K1/L025/L036 are
in depots. These local completions do not prove whole-day improvement/capacity.
M101 awaits movingS052's point/route clearance atTVC;S052 moves6.544444m/s.
L026,M097,M103,M102 andS034 move;L027 dwellsuntil16:04:54. M049approaches
AMPA,M065waitsitsreceivingroad. M073/M083/M089 and the later northern/evening
wave are not due. Final31two-second full-rake samples are preserved; geometric
axis envelopes alone do not identify shared occupied interlocking resources.
Eleven K1 minute samples show27.4545764399m braking movement by07:31, then
unchanged extents through07:40; these do not prove exact controller/recovery
behavior. The actual summary has oneV001 overtake atTVCN, not completed
multiple-location/recovery proof.

At08:57:13 original baseline23304/6112 reports13:10 simulated,70/200 complete,
peak37,maxwait40.1minutes,empty errors,no final audit. Exact original identities
match; no other job remains. Freeze runtime/routes/packs and all11 inputs while
baseline lives. Await its actual final report and preserve its queues before any
coordinated departure-only replan from BOTH37 outcomes. No repeated summary or
completed inspections; no Classic work, installation or gameplay playtest.
Network200V2 remains unaccepted/uninstalled; full-day feasibility and ETA unproven.

28 October 09:09 — both original candidate37 V2 runs failed; baseline Parassala evidence preserved.

Original baseline23304/6112 ended naturally at14:23:20 simulated, failing M091's
booked Parassala call2, not a signal-wait entry. It reachedPASA13:34:10.70 and
never departed.82/200 complete,peak37,maximum2702seconds in BOTH wait
populations,zero safety events,delay0/delay_at0. Run, actual-summary and all five
inspection error logs are empty. All-location231/331,297/331,320/331,330/331
and station-only124/186,165/186,181/186,185/186 FAIL all four cumulative gates.
231/331 is below70%,297/331 below90%; never round failures up. This failed
prefix differs from delayed98/200, whose all-location10-minute gate passed.
Neither population is complete; no complete-population comparison or recovery proof.

27 exact raw files are preserved in
`art/performance/realism-2026-10-26/network-candidate-thirty-seven/failed-predictive-baseline`:
lossless audit/traffic/failure/receiving state, original logs, actual summary,
five NEM/NYY/PASA/KZT/ERL inspections, exact pack, inspection tool and jobs.
All4836 current-at-run source hashes match the original baseline catalogue;
all11 observer/acceptance hashes remain unchanged. Every inspection has identical
before/after captures and no future clearance plans. Originals remain.

M091's2702extra seconds comprise1356opposing (L036546,M086406,S048404),
1308Kulitturai receiving and38route conflicts (L03612,M08612,S04814).
Receiving no-free: L026240,L036188,combinedL036/L0264,combinedS048/L026198.
Receiving approaching: combinedL026/S034112,L036130,combinedL036/L026276,
combinedL036/M08616,combinedM086/L036144. Preserve combined buckets without
individual attribution. Dispatcher continuous age2701.5 differs from audited2702.

Claims: NEM empty;NYY L036P1/S031P2;PASA M091P1/S048P2;
KZT L026P2/S034P1;ERL M082P2. M091 currently awaitsL026 KZT_P2.
L026 reachedKZT13:59:04.50,never departed,1386audited extra seconds versus1387
continuous age,now awaitsS034 overtake. S034 moves24.6m/s under authority
north towardKZT,occupyingKZT_PYD_M2/M3; its KZT claim is an approach.
S048 leftKZT14:13:14.25,now stoppedPASA-N2 awaitingNYY L036/S031,
146audited signal extra seconds versus241.5continuous age. S031 passesNYY,
next bookedKZT,awaitsL036 NYY_single:1466audited signal extra versus1562.5
continuous age. L036 moves16.266745m/s arrivingNYY,occupyingNYY_AMVA_M0,
NYY_P1/NYY_RLEAD_D after leavingAmaravila14:21:11.10.
M082 reachedERL14:17:58.15,never departed,256extra seconds versus255.5
continuous age,awaitsL026 KZT. These actual moving opponents and snapshots
are not permanent-deadlock, runtime-defect, available-escape or capacity proof.

M081/M085 are stabled beyond the southern portal after13:28:46.80/13:50:43.80;
K1/L025/M080/V006/S050 are in depots. M086 reachedTVC14:22:00.15 and unloads.
M051/M101/M096/M050/M068/M049 move. M087 and later relocated mails and
northern/evening services are not yet due. Final31two-second full-rake samples
are preserved; geometric extents alone do not identify shared occupied resources.
Baseline summary has no K1 overtakes. Delayed's oneV001 atTVCN does not prove
completed multiple-location overtakes or recovery. Local completions and the
later delayed failure clock do not establish whole-day improvement.

Both original37 jobs are now absent and finished-rejected. Delayed evidence is
already pushed06a0f06ea907eeaa580cd1ee8a95779b00458050; do not repeat its
summary or four inspections. No Classic, suite, native, search or diagnostic job
remains. Next: coordinated departure-only replanning from BOTH37 actual queues
and full-rake movements, retaining all200 and every gate. Source37 fingerprints
become historical only after the next source change. Retain the unchanged1004-test
candidate33 suite and five passing candidate37 authoring guards. No installation
or gameplay playtest; Network200V2 feasibility and ETA remain unproven.

28 October 09:14 — candidate38 authored and guarded; exactly two departure changes.

Both original37 runs ended naturally and failed before this source change.
Baseline evidence e47798d6 preserves82/200, M091 bookedPASA14:23:20;
delayed06a0f06e preserves98/200, M051 bookedNYY16:04:44. All37 source
fingerprints are now HISTORICAL, including the exact original summaries and
nine byte-immutable station inspections. No unchanged replay or repeated inspection.

Candidate38 changes ONLY M09113:05 to15:55 and M08714:35 to18:50.
Restoring these two departure strings recovers the ENTIRE predecessor JSON in
both common-author packs. Preserve all other departures, exact selected200 and
eight-mail exclusion, all non-departure fields, and K106:00. M08112:05,
M08512:20,M07316:25,M08317:10,M08918:10 remain; all local/superfast/VB,
northbound/northern-origin and other departures remain, includingM03321:25,
M09920:35,S05321:10,S05522:05 and35's seven northern shifts.
Common-author equality is required and is not Classic readiness.

Hypothesis: remove the baseline M091 Parassala occupation across the early
northbound group and the delayed M087 Parassala occupation that held M051
atNYY. Retiming both avoids substituting one for the other in those observed
queues. Baseline M091 encountered L036/M086/S048 opposing flow and Kulitturai
L026 awaiting movingS034; delayed M087 awaited movingS054 while M051 awaited
its receiving road. Both actual37 full-rake samples11:00 to each failure,
source/report hashes, static bounds, formula, ~2-second sample interval and
censoring are retained in candidate-thirty-eight-sampled-groups.json and its
sample-v37-groups-for38.py. Southern bounds remain from23; ALLP-AMPA bounds
remain from25. Axis overlap does not prove shared interlocking occupation.

M09115:55 follows V00715:30 and precedes retained M07316:25; M101 through
traffic and L004/S054 then M102/S036/M070 north still constrain onward passage.
M08718:50 follows M08918:10, shares the TVC origin time with northboundM032,
and meets the retained M034/S022 origin wave plus S038/V008 and M072/M054
north, M053/S051 south. Candidate36 later samples remain HISTORICAL planning
inputs, not37/38 passage predictions. Earlier changes can alter the entire later
railway. Origin gaps do not guarantee crossing order, compatible receiving roads,
full-tail clearance, onward escape or capacity. No isolated-model score or
whole-day improvement claim; origin queues, later waves and midnight remain unproven.

200services:40local96mail56superfast8VB,160boundary journeys,78overnight
origins unchanged;3-15starts/hour. Aggregate maximum15at23 is descriptive;
authoritative density guard requires at least3/hour and has no maximum.
205overrides reproduce both packs normally and with exact--check. Five headless
authoring guards PASS, empty errors. Retain unchanged1004-test candidate33 suite;
no repeat of full suite or legacy checks. All4835 prior railway inputs except
Networkpack and all11 observers/acceptance inputs are unchanged.
13 exact raw authoring proofs, both pack hashes and override bytes are preserved
in network-candidate-thirty-eight; exact predecessors in candidate-thirty-eight-before.
V2 rawSHA256:373749dcdcc40ef97f66b8b1d10f4887c37560c5de2118b4faaaef0b9c9932e8.

Next: launch exactly one normal V2 --network --snapshots and one delayed V2
--network --delay=600 --delay-at=27000 in fresh generation38. Verify actual
processes/options, unique outputs, ORIGINAL baseline catalogue,4836distinct
input hashes and all11 frozen inputs, then freeze while either lives. No Classic,
installation or gameplay playtest. All completion, safety, wait, physical and
recovery gates remain unchanged. Network200V2 unaccepted; no reliable ETA.

28 October09:16 — both original candidate38 V2 runs launched once and verified; freeze inputs.

Author d0a58daa3a534ee3543becd67c9ebb4a18e89e82 is pushed. Exactly one normal
V2 baseline5852/23404 and one delayed24424/16440 launched09:15:48.
Normal has --network --snapshots; delayed has --network --delay=600
--delay-at=27000; both use the current V2 pack and unique generation38 folders.
The ORIGINAL baseline starts/catalogue.json existed before launch verification.
All four actual command lines, parent identities and exact mode options are
verified; only these four Godot processes remain. All4836 distinct source hashes,
six original observers and five acceptance/selection inputs match. Five exact
raw launch files plus manifest are preserved in network-candidate-thirty-eight/launch-proof.
Never execute launch-network-v38.ps1 or verify-launch-v38.py again.

At09:16:33 baseline00:10 simulated,0/200,peak3,maxwait0.1minute; delayed00:40,
0/200,peak6,maxwait0.1minute. Both error logs empty, neither has a final audit.
These partial clocks are not acceptance. inspect-current-replays.py selects38
first; rehearsal-jobs-v38.json,launch-v38-verification.json,latest-job-status.json
and owned-processes.json track these originals. Freeze runtime/routes/packs and
all11 observer/acceptance inputs while either lives. No Classic,suite,native,
search or diagnostic job remains. Await BOTH original final reports before any
further coordinated departure-only replanning; summarize actual finals and
preserve exact failures and queues. Prior37 evidence remains historical in
e47798d6 baseline/06a0f06e delayed, with no repeated inspections.
Network200V2 remains unaccepted/uninstalled; no gameplay playtest or reliable ETA.

28 October 10:57 — both original candidate38 V2 runs failed; exact evidence preserved.

Original baseline5852/23404 and delayed24424/16440 both ended naturally.
Baseline failed14:41:24 simulated at S031 signal NYY-S2:84/200,peak36,
maximum all-location2702seconds,station maximum2458seconds,zero safety events,
delay0/delay_at0. Neyyattinkara is NOT a booked S031 call; its next booked
call7 is Kulitturai. Delayed failed19:13:26 at S038 booked Kulitturai call2,
not a signal-wait entry:121/200,peak37,maximum2702seconds BOTH populations,
zero safety events,600seconds K1 hold at07:30. S038 reachedKZT18:23:21.45
and never departed. Both run/actual-summary/five-inspection error logs are empty.

Baseline all-location235/334,301/334,323/334,333/334 PASS10/20 butFAIL30/45.
Station128/189,169/189,185/189,189/189 FAIL10/20/30 butPASS45.
Delayed all-location339/455,417/455,445/455,454/455 PASS10/20 butFAIL30/45.
Station182/264,238/264,258/264,263/264 FAIL10/30/45 butPASS20.
185/189 and445/455 are below98%;169/189 is below90%; never round up.
These unequal incomplete prefixes are not complete-population comparisons,
recovery certificates, acceptance or installation.

Each failure archive contains27 exact raw files in
art/performance/realism-2026-10-26/network-candidate-thirty-eight/failed-predictive-{baseline,delayed}:
lossless audit/traffic/failure/receiving state, exact pack, logs, actual summary,
five NEM/NYY/PASA/KZT/ERL inspections, inspector and jobs. Both final reports
bind all4836 unchanged current-at-run source hashes and all11 unchanged
observer/acceptance inputs. AllTEN inspections have identical before/after
captures and no future plans. Originals remain. Do not repeat these summaries,
inspections or unchanged replays; fingerprints become historical after source edits.

Baseline S031's2702 signal extra seconds comprise1922opposing (L036870,
M08622,S048568,S034462),290planned M086 crossing,452PASA receiving,
and38conflicts (L03614,M08612,S04812). Receiving:62combinedL026/S034,
192combinedL026/S048 no-free and198combinedL026/S048 preserving a KZT
crossing platform. Preserve combined buckets without individual attribution.
S031 leftTVC13:41:43.75; now stoppedNYY_P2 awaiting movingS034 NYY_single.
Its2799dispatcher continuous seconds differ from2702audited extra seconds.
Claims:NEMempty,NYY S031P2/S034P1,PASA L026P1/M082P2,KZTempty,ERLempty.
S034 moves24.6m/s north atAmaravila under authority towardNYY; its claim
is an approach. L026 reachedPASA14:17:18.40,never departed,1370extra versus
1371continuous seconds,awaitsM082 overtake. M082 leftKZT14:35:10.75 and
moves16.269757m/s intoPASA,occupyingPASA_KZTW_M0/PASA_RLEAD_U.
S048 moves17.881748m/s north onTVC_NEM_M5;L036 moves6.544444m/s
arrivingTVC_P4 with tailTVC_LADDER_RU1. M086 is stabled inTVCdepot.
M081/M085 cleared the southern portal13:28:46.80/13:50:43.80 and are
stabled;K1/L025depots. M051/M101/M096 and other services move. Later
relocated mails and the evening wave remain untested in this baseline.

Delayed S038's2702extra seconds comprise1014opposing (M103398,M049404,
M089212),1662PASA receiving,and26conflicts (M10312,M04914).
Receiving no-free:M103186,M049198,M089200,combinedM065/M089234,
combinedM049/M103564,combinedM049/M089228; approaching combinedM049/M08928
andcombinedM089/M06524. Preserve combined buckets. Dispatcher continuous
2701.5seconds differs from audited2702. S038 now awaitsM089 PASA_single.
Claims:NEMempty,NYYempty,PASA M065P1 plus incomingM087 P1/P2 alternatives,
not simultaneous reservations;KZT S038P2/M089P1;ERL V008P2/M049P1.
M089 leftPASA19:09:59.75,moves24.6m/s south onPASA_KZTW_M3 towardKZT.
M065 reachedPASA19:07:17.30,never departed,waitsS038's KZT receiving road;
M087 leftNYY19:11:28.75,moves19.594418m/s south,full rake onNYY_AMVA_M0/M1.
M049 leftKZT19:08:30.25,moves24.6m/s south with full rake onPYD_P1/KZT_PYD_M5.
V008 waitsERL-N2 forM049 KZT_single,1036audited extra versus1113.5continuous
seconds;M072 follows,waitingERL_P2 occupiedV008. M103 moves26.361363m/s
south afterERL19:07:09.25. No assertion that these moving opponents guarantee
available escape, capacity, permanent deadlock or a runtime defect.

DelayedM091/M073/M083 are stabled beyond the southern portal after17:30:24.50,
17:55:00.30/19:11:12.50;S031 cleared15:08:25.80. M081/M085 cleared13:56:05.30/
14:21:08.30. K1/L025/L026/L027/L036/M082 depots;S034 beyondnorthportal.
M032/M054/M070/M102/S022/S033/S036 move;M034 awaitsS022 blockclearance.
These local completions/movements do not prove whole-day improvement or capacity.

Each archive preserves final31two-second full-rake samples and11K1minute
samples. DelayedK1 brakes27.4545764399m by07:31,then extents remain unchanged
through07:40; this is not exact controller/recovery proof. Baseline summary has
noK1overtakes; delayed has oneV001 atTVCN,not completed multiple-location proof.
Geometric axis envelopes alone do not identify shared occupied interlocking resources.

No original38 job remains, nor any Classic/suite/native/search/diagnostic job.
Retain1004-test candidate33 suite and five passing38authoring guards; unchanged
full suite/legacy checks are not repeated. Next: coordinated departure-only
replanning from BOTH38 actual queues/full-tail movements, preserving exact200,
all non-departure fields, physical constraints and every acceptance gate.
Network200V2 remains unaccepted/uninstalled; no gameplay playtest, full-day
feasibility claim or reliable ETA.

**28 October 11:03 — candidate 39 authored from both actual 38 failures; V2 full-day tests pending.**

- Both original38 runs failed naturally and their exact evidence is committed/pushed in `5facebaaacd69b385eda38cd4e811f81da23ed9b`; all38 fingerprints are historical after this authoring. Candidate39 changes ONLY S03110:20→11:00, M08918:10→19:45 and M08718:50→20:05. Undoing these three departure strings recovers the entire predecessor JSON in both common-author packs. Selected200 IDs, exact8-mail exclusion, every other departure, K106:00 and all non-departure fields are unchanged. Common-author equality is not Classic readiness.
- The hypothesis uses BOTH actual38 queues: baseline S031 at signalNYY-S2 encounters moving northbound groups and L026/M082 Parassala receiving occupation; delayed S038 at bookedKZT encounters M103/M049/M089 southbound traffic with incomingM087 behind M065. Move S03140minutes later; move both M089/M087 beyond that observed evening queue to avoid direct replacement. S031 now follows S01310:55 and precedes M05111:10 at the northern origin; M089 follows S05119:30; M087 precedes retained M09920:35/S05321:10. All opposing/through trains and remaining departures stay. Earlier changes can alter every later queue, so these choices do not guarantee order, compatible roads, full-tail clearance, escape, capacity or improvement.
- `candidate-thirty-nine-sampled-groups.json` / `sample-v38-groups-for39.py` preserve BOTH actual38 full-rake axis overlaps11:00 through each failure, hashes/formula/staticbounds/~2second samples/censoring. Retained23 southern bounds and25 ALLP–AMPA centers with halfwidth+200m exclusion are planning inputs; geometry does not establish shared occupied interlocking resources or candidate39 passage times.
- 205overrides reproduce both200 packs normally and exact`--check`; five headless authoring guards PASS with empty errors. The unchanged candidate33 1004-test suite is retained, not rerun. All4835 prior railway sources except the Networkpack and all11 observer/acceptance inputs are unchanged. Population remains40local/96mail/56superfast/8VB,160boundary journeys,78overnight origins,3–15starts/hour; at least3/hour is the density guard, maximum15 is descriptive.
- Thirteen exact raw authoring proofs and provenance are preserved in `art/performance/realism-2026-10-26/network-candidate-thirty-nine`; exact predecessor files remain in `.local/realism-2026-10-26/candidate-thirty-nine-before`. V2 raw SHA256 `0db8dd44e1f6bc8dd9150780da8f8f139370d401a0c3698089a2eb0648c05eaf`. No acceptance, installation, gameplay playtest or full-day feasibility claim. Next: exactly one fresh normalV2`--network --snapshots` and one delayedV2`--network --delay=600 --delay-at=27000`, verify original catalogue/identities/hashes and freeze all inputs until both finish. No Classic run or repeated legacy checks.

**28 October 11:05 — original candidate39 V2 pair launched once and verified; all inputs frozen.**

- Author `782997ea1e3abf3f6e0f27de3f08c49388b33671` is pushed. Both original39 runs launched ONCE at11:04:00+08: normal wrapper16952/child19840 with `--network --snapshots`; delayed wrapper23728/child9884 with `--network --delay=600 --delay-at=27000`. Four actual commands/parent identities, exact options and distinct outputs match. The ORIGINAL baseline `starts/catalogue.json` existed before launch verification; all4836 distinct current source hashes and six original observers plus five acceptance/selection hashes verified unchanged. No Classic/suite/native/search/diagnostic job remains.
- At11:04:39 baseline00:10sim/0of200/peak3/max0.1m; delayed00:30sim/0of200/peak4/max0.1m, both error streams empty and no final audits. These are partial progress only. Five exact raw launch files plus manifest are preserved under `network-candidate-thirty-nine/launch-proof`.
- Read `rehearsal-jobs-v39.json`, `launch-v39-verification.json`, `rehearsals-v39`, `latest-job-status.json` and `owned-processes.json`. `inspect-current-replays.py` selects39 first. DO NOT execute `launch-network-v39.ps1` or `verify-launch-v39.py` again, duplicate or restart. Freeze all inputs while either original39 lives and await both actual outcomes before coordinated replanning. Both38 failures are preserved in5facebaa and historical after39; do not repeat their summaries or ten completed immutable inspections. Network200V2 remains unaccepted/uninstalled, no gameplay playtest; full-day feasibility and reliable ETA remain unproven.

**28 October 12:47 — both original candidate39 V2 runs failed naturally; exact evidence preserved.**

Original baseline16952/19840 failed14:38:40 simulated at M050 signal MAKM-N2,
not a booked Mararikulam call; next booked call16 is Cherthala. It completed
84/200, peak36, all-location maximum2702seconds, station maximum2148seconds,
zero safety events, delay0/delay_at0. Original delayed23728/9884 failed21:16:14
at M089 signal NEM-S2, not a booked Nemom call; next booked call1 is Neyyattinkara.
It completed134/200, peak38, all-location maximum2702seconds, station maximum
2676seconds, zero safety events after600seconds K1 hold at07:30. Both run and
actual-summary error logs are empty. Neither failed prefix is accepted or installed.

Baseline all-location221/326,287/326,314/326,325/326 FAIL all four10/20/30/45
minute gates. Station124/188,167/188,184/188,188/188 FAIL10/20/30 and PASS45.
Delayed all-location401/560,506/560,538/560,559/560 PASS10/20, FAIL30/45.
Station209/316,283/316,304/316,316/316 FAIL10/20/30 and PASS45.
184/188 is below98%;283/316 is below90%; never round failures up. Unequal
incomplete populations do not support complete-population comparisons or recovery.

The baseline archive contains30 exact raw files; delayed contains27, under
`art/performance/realism-2026-10-26/network-candidate-thirty-nine/failed-predictive-{baseline,delayed}`.
Each binds4836 distinct current-at-run source hashes, the exact pack, six original
observers and five acceptance/selection inputs. Lossless audit/traffic/failure,
logs, actual summary, inspection source and jobs record are preserved; originals
remain. Six baseline MAKM/SRTL/ALLP/AMPA/NEM/TUVR and five delayed NEM/NYY/PASA/
KZT/ERL inspections each preserve identical before/after captures and empty errors.
No original39 or diagnostic process remains. Do not repeat either summary or these
11 inspections, relabel fingerprints after later source edits, or rerun unchanged39.

Baseline M0502702seconds =2366 opposing (172 S007 alone +2194 combined S007/S015)
+336 Cherthala receiving (no-free200 combined S015/S007,78 combined S032/S015/S007;
approaching58 combined S015/S007/S032). Preserve combined buckets without individual
attribution. M050 left ALLP13:42:24.25, is stopped on MAKM_P2, dispatcher continuous
age2798 differs from audited2702. S007 is stopped TRVZ_MAKM_M3 before its entry
signal, S015 behind on M2, S016 northbound stopped MAKM_KAVR_M0. S007/S015/S016
MAKM P1/P2/P3 are incoming alternatives, not three simultaneous reservations each.
S007 and S016 both await MAKM capacity with M050 and the other admitted services;
S015 awaits S007's block. SRTL has no claims; TUVR has incoming M049 P1/P2/P3 alternatives.
ALLP M016P1/S012P2/M028P3 all await MAKM; M028 arrived14:02:40.95, no departure,
2038 audited extra /2038.5 continuous. AMPA M026P2/M048P3 both await those ALLP roads.
Their continuous waits are275.5/990.5; S0121181 and M01628 at ALLP.

The baseline has ONE NEM future plan: incomingS034 futureNEM_P2, opponentS031
NEM_P1, vacaterL036, escapeTVC_P2; received/opponent_received/escaped all false.
NEM claims S031P1/L036P2 plus incomingS034 P1/P2 alternatives. S031 leftTVC14:34:59.75,
moves24.6m/s south on TVC_NEM_M2 under NEM-S1 authority. L036 stopped NEM_P2,
237 continuous seconds awaiting S031 to clear the escape approach. S034 moves
24.6m/s north on BRAM_P1. L026 moves0.870705m/s arriving Amaravila after PASA
14:27:55.75; M082 moves13.844155m/s arriving PASA with tail on PASA_RLEAD_D.
M081/M085 stabled south after13:28:46.80/13:50:43.80; S032 stabled north14:33:32.75.
K1/L025/S013 depots. M051/M101/M019/S011/M096 move; later relocated mails are not due.
Local movement/completion is not whole-day improvement, capacity or escape proof.

Delayed M0892702seconds =1156 S033 reserved NYY_P1 approach +1546 combined
S033/M054 no-free NYY receiving. M0872406=860 reserved approach+1546 same combined
receiving. They leftTVC20:23:53.25/20:28:49.25 and occupy NEM_P2/P1, both stopped.
Dispatcher continuous ages2798/2502 differ from audited2702/2406. NYY claims
S033P1/M054P2; S033 passes NYY (next booked KZT), stopped awaiting PASA L029/M104.
M054 arrivedNYY20:36:30.30, never departed,2312 extra =50 earlier S033 admission
following L029 +2262 combined M087/M089 receiving; continuous2311.5.
S033 NYY-S1 extra2214=42 no-free unnamed +626 M104 +1546 combined L029/M104;
continuous2337.5. PASA L029P1/M104P2, KZT M088P1/M058P2, ERL M056P2.
L029 PASA arrived20:51:13.95, awaits KZT M088/M058; M104 PASA arrived20:41:19,
awaits NYY S033/M054,2024 extra=478 protected L029 escape+1546 combined receiving.
M088/M058 KZT arrived21:00:45.40/21:03:37.05, await PASA L029/M104; M056 ERL
arrived21:00:21.15, awaits KZT M088/M058; L028 waits behind M056. No future plans
remain. Actual fixed road claims and stopped queues do not prove a permanent
deadlock, runtime defect or candidate infeasibility.

Delayed S031 stabled south16:06:31.80; M050/S016 stabled north15:16:11.25/
14:51:21.75; S007/S015 depots. M091/M073/M083 stabled south17:37:45.50/18:00:47.30/
18:54:20.00; M103/M065 south19:25:43.50/19:47:55.80; M049/V008 depots.
M099 moves25.163322m/s south MQU_KXP_D2, M07227.377778m/s north IRP_MYY_U1/U2.
S038 awaits AMPA M032/M034, L030 dwells at NJT, S053 awaits TVC origin berth,
S055/L038 are not due. These are local outcomes only; later waves/midnight unproven.

Each archive retains31 final two-second full-rake samples,11 K1 minute samples
and last sampled changes above1mm for the failed queue. Baseline M050/S007/S015/
S016 last changed at13:53:40/14:08:14/14:09:56/14:12:34; delayed M089/M087 at
20:31:14/20:36:10. Sampling is not exact stop timing or shared interlocking-resource
ownership. Delayed K1 intervention samples remain raw; braking extents are not
an exact controller/recovery certificate. Actual baseline summary has no K1
overtakes; delayed has one V001 at TVCN, not completed multiple-location proof.

The unchanged1004-test candidate33 suite and five passing39 authoring guards are
retained; no repeated legacy/full suite. Next: coordinated departure-only replanning
from BOTH actual39 queues and full tails, retaining selected200, all non-departure
fields and every acceptance gate. Network200V2 remains unaccepted/uninstalled;
no gameplay playtest, full-day feasibility claim or reliable ETA.

**28 October 12:52 — candidate40 authored from both actual39 failures; V2 full-day tests pending.**

- Both original39 failures are preserved in `b3f5b3eb96042390ebe6ad32e47d6baa8d596fa3`:57 exact raw files,4836 source hashes per run and11 immutable inspections. All39 fingerprints are historical after this authoring; never rerun unchanged39 or repeat its completed summary/inspections.
- Candidate40 changes ONLY S01513:05→13:45, M08919:45→21:45 and M08720:05→22:40. Undoing these three departure strings recovers the entire predecessor JSON in both common-author packs. All200 selected IDs and exact8-mail exclusion, K106:00, S03111:00, every other departure and all non-departure fields remain. Common-author equality is not Classic readiness.
- The baseline hypothesis separates S015 from S007's approach after actual39 M050 at signalMAKM-N2 encountered both opposing S007/S015 with S016 approaching from the south. Keep S00712:55, M05009:15, S01611:20 and M04914:15. The delayed hypothesis removes both M089/M087 from the observed NEM two-road occupation that blocked M054's northbound NYY exit while S033 awaited PASA L029/M104. M089 now follows S04920:50/S05321:10 and precedes S05522:05; M087 follows55minutes later, after S055 and before L03922:50. All opponents and through services remain. Later departure slots exceed the failed prefix and are unproven; origin spacing is not a receiving-road, full-tail clearance, escape or capacity certificate.
- `sample-v39-groups-for40.py` and `candidate-forty-sampled-groups.json` preserve BOTH actual39 full-rake axis overlaps from00:00 through each failure, static bounds, source/report hashes, exact formula, approximately two-second sampling and censoring. Early hours show dense opposing groups, not a free corridor. Actual39 movement times are not40 predictions. No isolated-model score or improvement claim.
- 205overrides reproduce both200 packs normally and exact`--check`; five affected headless authoring guards PASS, empty errors. Retain the unchanged candidate33 1004-test suite without repeating legacy/full-suite checks. All4835 prior railway inputs except the Networkpack and all11 observer/acceptance inputs remain unchanged.
- Thirteen exact raw authoring proofs are preserved in `art/performance/realism-2026-10-26/network-candidate-forty`; exact predecessors remain in `candidate-forty-before`. Population remains40local/96mail/56superfast/8VB,160boundary journeys, now79overnight origins,3–15starts/hour. At least3/hour is the authoritative density guard; maximum15at23 is descriptive. V2 raw SHA256 `8e6e02d73950b3b668fe03b9bf6f01e27b21e1e05a00663f9236dc6d1ebd72a2`.
- Network200V2 remains unaccepted/uninstalled. Next: exactly one fresh normalV2`--network --snapshots` and one delayedV2`--network --delay=600 --delay-at=27000`, verify actual identities/options/original baseline catalogue/4836sources/11frozen inputs, then freeze until both end. No Classic job, gameplay playtest, full-day feasibility claim or reliable ETA.

**28 October 12:55 — original candidate40 V2 pair launched once and verified; all inputs frozen.**

- Author `4df7cc15895185ce41b7d6e1dbb7232a8c8d7feb` is pushed. Both original40 runs launched ONCE at12:52:51+08: normal wrapper14748/child21172 with `--network --snapshots`; delayed wrapper16404/child20992 with `--network --delay=600 --delay-at=27000`. All four actual commands/parent identities, exact user-option lists and two distinct outputs verified. The ORIGINAL baseline `starts/catalogue.json` existed before verification; all4836 distinct source hashes, six original observers and five acceptance/selection hashes verified unchanged. The catalogue grows as service snapshots are added; its changing raw output digest is not a source change. No Classic/suite/native/search/diagnostic job remains.
- At12:54:19+08, predictive-network: 00:30:00 complete=0/200 peak=4 max_wait=0.1m wall=70.3s; predictive-network-delayed: 01:00:00 complete=0/200 peak=10 max_wait=0.1m wall=75.0s. Both error streams are empty and neither has a final audit. Partial clocks are not acceptance. Five exact raw launch files plus manifest are preserved under `network-candidate-forty/launch-proof`.
- Read `rehearsal-jobs-v40.json`, `launch-v40-verification.json`, `rehearsals-v40`, `latest-job-status.json` and `owned-processes.json`. `inspect-current-replays.py` selects40 first. DO NOT execute `launch-network-v40.ps1` or `verify-launch-v40.py` again, duplicate or restart. Freeze all inputs while either original40 lives; await both outcomes before coordinated departure-only replanning. Both39 failures are preserved in b3f5b3eb and historical after40; do not repeat their summaries or11 immutable inspections. Network200V2 remains unaccepted/uninstalled, with no gameplay playtest, full-day feasibility claim or reliable ETA.

**28 October 13:11 — user authorized a few more service cuts if needed.**

- The user said, "Cut a few more services later if needed." This supersedes the previous 200-service minimum for future V2 candidates. Modest additional cuts are authorized when warranted by both actual run outcomes; no fixed new target count is assumed.
- Candidate40 remains the selected200 timetable. Keep its packs, runtime, routes, six observers and five acceptance/selection inputs frozen while either original40 run lives. Wait for both original outcomes, preserve exact evidence and inspect actual queues/full-tail movements before any coordinated departure changes or additional cuts. Do not duplicate or restart either run.
- Preserve the raw208 template and every retained service's non-departure fields. If a future selection changes, update and test authoring/population contracts against its exact selected IDs, count and pack hash while retaining every completion, safety, wait-quality and overtaking gate. Installation and later V2 UI/category checks must use the accepted population. No trimming or railway-input change is made by this authorization checkpoint.

**28 October 14:54 — original candidate40 delayed V2 run failed naturally; baseline still frozen and running.**

- Original delayed wrapper16404/child20992 ended naturally at simulated **22:52:20**, with **144/200** services complete, peak38, zero safety events and empty run/summary error streams after the600s K1 hold at07:30. The failure is **S035 at signal PASA-S2**, not a booked Parassala call; callindex7 is its next booked Kulitturai stop, which it has not reached. Maximum all-location wait2702s; station-only maximum2454s. Normal original40 wrapper14748/child21172 was still running at archival; preserve its inputs and wait for its actual final report before any coordinated replan or newly authorized modest cuts. No restart, duplicate run, installation or gameplay playtest.
- Actual all-location cumulative waits: **423/603,542/603,583/603,602/603** under10/20/30/45minutes: PASS10, FAIL20/30/45. Station-only: **223/338,303/338,328/338,338/338**: FAIL10/20/30, PASS45.542/603 and303/338 are below90%;328/338 is below98%. Do not round up or compare this incomplete prefix to a complete population.
- S035's2702s =1440 opposing (M05614,L028548,L030548,S040330) +1224 Kulitturai receiving (no-free L03074,L038158,combined S040/L038352; approaching combined L028/L030516,combined L030/L038124) +38 route conflicts (M05614,L02812,L03012). Preserve combined buckets without individual attribution. S035 reachedTVC21:27:10.70/departed21:30:15.75; its full rake is stopped onPASA_P2 awaiting movingS040 inPASA_single. Dispatcher continuous2799s differs from audited2702s; last sampled axis change22:07:20 is approximately2s sampling, not an exact stop time.
- Five immutable PASA/NEM/NYY/KZT/ERL inspections have identical before/after world captures, no future plans and empty errors. Claims: PASA S035P2/incomingS040P1; NEM M099P2/incomingL028P1; NYY L031P2/incomingL030P1/P2 alternatives; KZT L038P2/incomingL032P1/P2 alternatives; ERLempty. Alternatives are not simultaneous reservations. S040 leftKZT22:46:54.75 and moves24.6m/s north with its full rake onPASA_KZTW_M1 underPASA-N1 authority. Moving opponents and the failed snapshot do not prove permanent deadlock, a runtime defect, escape, capacity or infeasibility.
- L028 leftPASA22:27:45.30/NYY22:44:16.75, moves24.6m/s north onNEM_BRAM_M2 underNEM-N1 authority. L030 leftPASA22:45:35.75, reached **Dhanuvachapuram(DAVM)**22:51:22.90 and dwells onDAVM_P1 until22:52:33; Amaravila is its next stop. L038 reachedKZT22:32:09.90, no departure,1144 audited/continuous seconds awaitingS035'sPASA receiving road. L031 reachedNYY22:17:18.95, no departure,2034 audited/2034.5 continuous seconds awaitingL030 inNYY_single. L032 leftERL22:48:24.25, moves24.6m/s north with full rake onPYD_ERL_M3/M4 towardKZT.
- M099 leftTVC22:20:10.75, is stoppedNEM_P2 awaiting movingL028;1490 signal-extra seconds differ from1586.5 continuous. S053 has not departed its bookedTVC origin,1746 audited/1747 continuous seconds awaitingM099 receiving atNEM. S055/M089/M087/L039 await a clearTVC origin berth; the two relocated mails have not departed. M054 leftNYY20:54:18.75/TVC21:14:06.25 and is moving north at27.377778m/s onKYJ_OCR_U2/U3. M104 moves24.600011m/s towardKPY;M05611.465458m/s arrivesKZK;M058 just moves fromVAK. S031/M050/S016 are beyond portals;S007/S015/K1/L029/M088/V001 are in depot storage. Local completions are not whole-day improvement or recovery proof.
- The same immutable capture retains the northern queue: M027 atERS awaitsKUMM S037/M043/incomingM034 (1814 extra/1813.5 continuous); M043KUMM_P3 andS037KUMM_P1 awaitM034, which moves24.6m/s north onAROR_EZP_M2. S038 atTUVR awaitsKUMM receiving;M031/M029 queue behindERS. M033 atALLP awaitsAMPA capacity reserved forS021, moving24.6m/s south onALLP_PUPR_M1/M2;M072 moves north onKAVR_TMPY_M3/M4;L012 atSRTL awaitsL009. No separate northern station-claim inspection or capacity conclusion is asserted here.
- **27 exact raw files** plus provenance under `art/performance/realism-2026-10-26/network-candidate-forty/failed-predictive-delayed` preserve the actual summary, lossless audit/traffic/failure, exact pack, job record and five inspections. All4836 current-at-run source hashes, six observers and five acceptance/selection hashes verified unchanged against the original40 launch; baseline's ORIGINAL catalogue agrees.31 final two-second full-rake samples,11 K1 minute samples and last sampled axis changes above1mm are preserved. K1 brakes27.4545764399m by07:31 and retains sampled extents through07:40; this is not exact controller/recovery proof. Actual summary has oneV001/K1 overtake atTVCN, not completed multiple-location proof.
- Source40 remains current and frozen while its original baseline lives. Do not repeat the completed delayed summary or five inspections, rerun unchanged40, relabel fingerprints after later source changes, or install this failed result. Further modest service cuts below200 are already authorized if needed after both outcomes are preserved; all acceptance gates and retained non-departure fields remain mandatory. NetworkV2 readiness and full-day feasibility remain unproven, with no reliable ETA.

**28 October 15:19 — original candidate40 baseline failed naturally; both outcomes preserved before replanning.**

- Original baseline14748/21172 ended naturally at **21:49:44** simulated, **138/200** complete, peak36, zero safety events, delay0/delay_at0 and empty run/summary errors. **M055 failed at its booked Alappuzha call3**, arrived21:02:41.30 and never departed; this is not a signal-wait audit entry. Maximum2702s in both wait populations. Both original40 runs have now ended; delayed failure and five inspections are already preserved in908ab779 and were not repeated.
- All-location cumulative **414/578,532/578,564/578,577/578** under10/20/30/45minutes: PASS10/20, FAIL30/45. Station-only **221/325,298/325,319/325,324/325**: FAIL10/45, PASS20/30.564/578 is below98%; do not round up or copy delayed40 gate results.138/200 and144/200 failed prefixes are not complete equal populations or recovery evidence.
- M0552702s =1208 reserved approach forM032 toALLP_P1 +478 opposing(S038456,S02222) +718 AMPA receiving(no-free combinedL003/M034/S03830,combinedM059/M03220,M032198,combinedM034/S038160;approachingM05944,combinedM032/M059144,combinedM034/S038/L003122) +136 plannedS022 crossing +100 occupied blocks byM059(12/42/46) +62 conflicts(M05950,S02212). Combined buckets remain combined. M055 occupiesALLP_P3, continuous2702s, currently awaits movingS038 inALLP_single. Its last sampled axis change21:02:42 is a two-second observation, not exact stop timing.
- Six immutable ALLP/AMPA/MAKM/ERL/KZT/PASA inspections have identical before/after captures, no future plans and empty errors. ALLP claimsM055P3/incomingS038P2/incomingL011P1/P2/P3 alternatives; AMPA M034P2/L012P3; MAKMempty; ERL M056P2/incomingS049P1; KZTempty; PASA incomingS053P1/incomingM058P2. Alternatives are not simultaneous reservations. S038 moves24.6m/s north, full rakeALLP_PUPR_M2 underALLP-N2 authority. M032 leftALLP21:32:55.75, moves24.6north with full rakeSRTL_TRVZ_M0/M1. S022 leftALLP21:27:01.75, moves24.6north onVAY_P1/VAY_SRTL_M0. M059 leftAMPA21:18:53.80/KYJ21:46:58.75, moves27.377778southKYJ_OCR_D2.
- M034 arrivedAMPA21:26:13.60, no departure,1342 audited/1341.5continuous seconds, andL012 arrived21:47:31.95, no departure,67continuous seconds; both awaitALLP M055/incomingL011. L011 leftMAKM21:43:05.75/Kalavur21:48:36.65, moves19.0658south with full rakeKAVR_P1/KAVR_TMPY_M0. L003 leftAMPA21:44:05.75 and dwellsTZH_P1 until21:50:14. M033 approachesTUVR16.31415m/s with full rakeEZP_TUVR_M3/TUVR_LLEAD_U awaitingS022's single-line clearance. Moving opponents and local progress do not prove permanent deadlock, runtime defect, escape, capacity or full-day improvement.
- Southern baseline queue: M056 reachedERL21:33:43.15, no departure,892continuous seconds awaiting movingS049. L028/L030/L038 queue behind onERL_VRLR_U0/U1/U2; last sampled changes21:34:58/21:36:00/21:45:48. M058 leftERL21:30:22.25/KZT21:43:35.75, moves16.305537north arrivingPASA with full rakePASA_KZTW_M0/PASA_RLEAD_U. S049 moves24.6southPYD_ERL_M3/M4 underERL-S1. S035 leftTVC21:30:43.25 and waitsNEM_P2 forM088,702 signal-extra versus798continuous seconds. L031 occupiesTVC_P1 waiting forS035'sNEM receiving road, withM099 queued behind. S053 departedTVC21:10:04.75 and moves towardPASA; M089 has not departed, M087/S055 are not due. Do not substitute delayed40's later positions or times.
- **30 exact raw files** plus provenance in `art/performance/realism-2026-10-26/network-candidate-forty/failed-predictive-baseline` preserve the exact pack, lossless audit/traffic/failure, actual summary, six inspections and job record. All4836 current-at-run source hashes and11 frozen observer/acceptance inputs match the original40 launch and baseline catalogue.31 final two-second full-rake samples,11 baselineK1 minute samples and last axis changes above1mm are preserved. Actual baseline summary has noK1 overtakes; geometry is not shared interlocking resource ownership. Originals remain; no replays or completed inspections repeated.
- Both40 results are rejected and uninstalled. Source40 fingerprints are current at preservation and become historical after any next candidate. Next: use BOTH actual queues for coordinated changes, with modest additional cuts below200 already authorized; retain every retained service field and all completion/safety/wait/overtaking requirements. No gameplay playtest, full-day feasibility claim or reliable ETA. Retain unchanged1004-test candidate33 suite; these six headless immutable inspections passed.

**28 October 15:25 — candidate41 removes four further mails; all196 retained service records unchanged.**

- Both original40 failures ended naturally and are preserved before this change: baseline49747e9e (30raw/six immutable inspections), delayed908ab779 (27raw/five). All40 source fingerprints are now historical; never relabel, rerun unchanged or repeat completed summaries/inspections. The user's28October13:11 instruction authorized a few further cuts below200 if needed.
- Candidate41 removes exactly **M03218:50, M05519:45, M05620:35, M05820:20**, in addition to the prior eight excluded mails. The selected population is **196 =40local+92mail+56superfast+8VB**, with156 boundary journeys,79 overnight origins and3–15 starts/hour. At least3/hour remains mandatory;15 is descriptive. Every retained departure and non-departure field, K106:00, the raw208 template and all205 departure overrides are byte/field-verified unchanged. Pack count labels change to196; common-author equality does not establish Classic readiness.
- The two actual40 outcomes inform modest reductions in two opposing groups. AtALLP, baseline M055 failed and its occupied road constrainedM034/L012;1208seconds were attributed toM032's reserved approach. Delayed M032 also accumulated1054seconds atAMPA, though M055 progressed south without a500second wait. In the southern group, baseline M058 accumulated2066seconds atERL ahead ofM056/local followers; M056 occupiedERL_P2 withL028/L030/L038 behind. Delayed M058 had814seconds atERL plus2034signal seconds on its approach;M056 had932atERL and signal waits1240/1046 before preceding the local/superfast group encountered byS035. Removing these services may change the entire railway; this is not a capacity, receiving-road, full-tail escape, recovery or improvement certificate.
- Updated explicit service selection, common authoring guards and V2 population contract to the exact196 IDs and12 excluded IDs. The contract now additionally rejects same-count substituted pack IDs against the raw208 ID set; it still binds the raw pack hash and requires the full selected report population. V2 installed-variant count is196. Dedicated normal finalizer, disturbed verifier, all six original observers, runtime and all4835 prior railway inputs except the changed Network pack are unchanged. No completion/safety/wait/overtaking gate was relaxed; Classic execution/installation remains out of scope.
- Both packs generated normally and reproduced exactly with`--check`. Five affected headless authoring guards PASS, empty errors; population fixtures **2positive/21negative PASS**, including stale200/substituted/newly-excluded IDs; changed JS parses. Retain the unchanged1004-test candidate33 suite, without repeating legacy/full-suite checks. Fixtures are synthetic guards, not a positive full-day exercise. Exact predecessors, plan, actual40 report hashes and field proof are in`candidate-forty-one-before` and corresponding local JSON; raw authoring evidence is archived under`network-candidate-forty-one`.
- V2 raw pack SHA256 **e1448c474a8db393ffa8367d607661bfd287a4e6379c2b37f77bec1e7d8179f9**. Next: launch exactly one new normalV2`--network --snapshots` and one delayedV2`--network --delay=600 --delay-at=27000`, verify actual identities/options/original baseline catalogue/4836 sources/11 frozen hashes, then freeze until both original41 outcomes. Network196V2 remains unaccepted/uninstalled. No gameplay playtest, full-day feasibility claim or reliable ETA.

**28 October 15:27 — original candidate41 V2 pair launched once and verified; all196 inputs frozen.**

- Candidate41 author6193fa805c0269384481215455f324cb44e77d1b is pushed. Exactly one normal original41 launched15:25:55+08 with wrapper23588/child10024 and`--network --snapshots`; one delayed original41 with wrapper24452/child1160 and`--network --delay=600 --delay-at=27000`. Four actual commands/parent identities/exact option lists, two unique outputs and the ORIGINAL baseline catalogue were verified. All4836 distinct source hashes, six original observers and five tested acceptance/selection inputs match. Five exact raw launch files plus manifest are in`network-candidate-forty-one/launch-proof`. Catalogue growth is output growth, not a source change.
- At15:26:40, baseline00:10sim0/196,peak3,max0.1m; delayed00:40sim0/196,peak6,max0.1m. Both error streams are empty and neither has a final audit. These partial clocks are not acceptance. No Classic/suite/native/search/diagnostic job remains. Read`rehearsal-jobs-v41.json`,`launch-v41-verification.json`,`rehearsals-v41`,`latest-job-status.json`,`owned-processes.json`;`inspect-current-replays.py` now selects41 first.
- DO NOT execute`launch-network-v41.ps1` or`verify-launch-v41.py` again, restart or duplicate. Freeze packs/runtime/routes, six observers and five acceptance/selection inputs while either original41 lives. Await both outcomes before coordinated changes. Both original40 failures are preserved49747e9e/908ab779 and historical after41; do not repeat their summaries or11 completed immutable inspections. Network196V2 remains unaccepted/uninstalled; no gameplay playtest, full-day feasibility claim or reliable ETA.
