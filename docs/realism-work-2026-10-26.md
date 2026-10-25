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
