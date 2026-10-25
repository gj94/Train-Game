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
