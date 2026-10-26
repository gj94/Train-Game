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
