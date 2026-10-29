# Incremental timetable construction — 30 October 2026

Current checkpoint02:06: all44 physical workings and all179 individual timing
calculations are complete. Shared construction has reached four categories.
Both004 outcomes are preserved; the one-Mail-placement revision004b is running.
The complete179-service shared timetable is not yet built or installed.

The user asks for a new timetable built one train at a time: calculate achievable
arrival times at every call, place the next train against that working, and
continue. VB has the fewest calls and its actual acceleration advantage;
superfast has more calls, mail/express more again, and passenger services call at
every open, physically compatible station on their route. Compare category
performance over the same route and direction, not unrelated journey lengths.

The current 179 identities are the provisional roster. A text question asks
whether to retain179 or restore208; no response has yet been received. Neither
count is a physical-capacity certificate. Do not silently remove services to
improve a score or repeat the previous departure-override/cut cycle.

## Why the earlier method failed

The old author starts from208 approximate service definitions, applies205 origin
departure edits and29 exclusions, and exports179 services. It does not allocate
an entire feasible path for every service against the shared railway. Subsequent
wait-driven edits separated fast trains from passengers, suppressing intended
overtakes. Network-wide overtake totals concealed uninteresting individual
journeys. V006 additionally demonstrates that priority aging does not preserve a
future direction change or a suitable receiving road against repeated opposing
admissions. These are authoring and dispatch-planning issues, not evidence that
the signal protections should be weakened.

## Working method

1. Measure actual running legs with unchanged stock, traction, braking, line
   limits, geometry, calls and minimum dwell. Remove inherited booked-time holds
   only inside an isolated measurement world. This is an uncongested timing
   estimate under the current driver model, not a mathematical global optimum.
2. Calculate each ID's passenger exchange separately: passenger demand is seeded
   by service ID. Share physical running legs only between identical workings;
   do not copy another train's complete elapsed journey time or dwell.
3. Construct a complete service timetable from measured legs, passenger exchange,
   minimum dwell and measured departure overhead. Keep those components separate
   from congestion and planned pathing. No category speed multipliers, extra
   passenger dwell or forced passes.
4. Add one service to an explicit ordered construction record. Anchor following
   gaps at a common station's departure, not at unrelated boundary-entry times.
   Check the catch-up location, compatible passing roads, opposing single-line
   commitments, receiving capacity and full-tail release across the whole path.
5. Validate interactions in the real simulator. Inspect individual arrivals,
   departures, accumulated signal/station waits and full-formation passing events.
   An isolated profile, static resource table or two-train result cannot certify
   a larger shared railway. Diagnose the first newly introduced conflict before
   adding more services. Earlier paths may need bounded revision.
6. A complete new day needs normal and delayed validation, all calls and terminal
   clearances, zero safety events, category comparisons and useful per-service
   interactions. Preserve the original wait statistics; R48's release exception
   must not be represented as a strict wait-quality pass for a new day.

Real working timetables include intermediate passing times and depot movements;
planning accounts for speed differences, separation, platform reuse and recovery
space. These principles inform this reconstructed game railway, rather than
claiming its tracks or service times reproduce a real Indian working timetable.
See [Network Rail's timetable explanation](https://www.networkrail.co.uk/industry-and-commercial/the-timetable/)
and [operational planning rules](https://www.networkrail.co.uk/industry-and-commercial/information-for-operators/operational-rules/).

## First construction sequence and current evidence

- Increment001: K1, Ernakulam06:00, all55 passenger calls retained. The new
  unconstrained measurement reaches Nagercoil after20429.70seconds (5h40m29.70s),
  then completes its depot working with zero safety events. This is not its
  guaranteed journey time after other trains are added.
- Increment002: add S007, the Hyderabad–TVC superfast, targeting departure from
  Ernakulam900seconds after K1. The calculated boundary entry is06:08:44; its
  boundary-entry clock is deliberately different from the common-station gap.
  Both services retain their stock, priorities, calls and minimum dwell, with
  newly calculated arrival offsets. Both actual runs completed2/2 with60
  arrivals and60 departures, cleared depot workings, zero safety events and
  passing strict wait distributions. S007 passes K1 at Turavur06:33:20.139,
  with full-tail clearance06:33:52, in both runs. K1 has366seconds extra
  station wait there. Each summary and all-service assessment ran once.
- Increment003 adds V001 six minutes after S007 at ERS. Its measured advantage
  reaches about374seconds by QLN. Original normal3964/7744 and delayed14484/11492
  launched once01:21:49+08. The delayed run completes3/3 safely but introduces
  a966-second S007 ALLP wait:438 overtaking,460 receiving/reservation,64 occupied
  block and4 authority seconds. This is not an acceptable reason to add many
  more trains merely because the aggregate wait audit passes. Inspect both
  outcomes before deciding a bounded adjustment to the VB slot.
- Add mail/express and an opposing working after this first conflict is resolved
  or explicitly justified; inspect every newly introduced interaction.
- Separately use V006's recorded replenishing opposing stream as a dispatcher
  regression case before relying on high priority to secure a corridor turn.

`tools/measure_timetable_physics.gd` completed four of44 distinct physical workings
serially, recorded once in `.local/incremental-timetable-2026-10-30/physics`.
`tools/export_timetable_planning_inputs.gd` exported179 ID-specific exchange
profiles and56 station records without advancing simulation time.
`tools/author_incremental_timetable.py` produced separate001 and002 candidates.
Two focused headless probe tests, four Python authoring tests and three
once-only assessment guard tests pass. The remaining40 distinct measurements
are running in one serial resume job, skipping all four indexed measurements.

Original002 normal1020/3012 and delayed12456/23736 were launched once at
01:03:28+08. The normal uses `--network --snapshots`; the delayed uses
`--network --delay=600 --delay-at=27000`, giving K1 a07:30 disturbance because
both worlds start at midnight. Four actual commands/parents, unique outputs and
the candidate SHA256 were preserved at01:06:28+08. Original normal source
catalogue was first observed01:09:39 and verified01:09:40, after the delayed
run naturally finished; the four-process proof is from the earlier live state.
All4836 distinct sources and six observer/five acceptance inputs match. Both002
outcomes are preserved in a32-file lossless archive under
`art/performance/incremental-timetable-2026-10-30/first-pair`. Original snapshots
remain intact. Never repeat these summaries or assessments.

The original003 normal catalogue was observed and verified01:27:56; its4836
sources and six observer/five acceptance inputs match the original launch.
Both003 inputs and the physical-measurement inputs stay frozen while their
original jobs live. No current179 installed source or runtime change is needed.

The published R48 files and all five installed choices remain unchanged. No
new timetable is installed or published yet. The prior continuation automation
remains deleted; this is a newly requested construction task.

## Refined third placement and fourth train

Both original003 trials complete3/3 with64 arrivals and64 departures, zero
safety events and strict wait audits passing. Both nevertheless hold S007 at
ALLP for966seconds. Their exact outcomes are preserved under
`three-train-first-slot`; no replay or summary was repeated.

Revision003b changes only V001: ERS departure420seconds after K1, ahead ofS007.
Both003b runs complete3/3 safely with all64 arrivals/departures and all strict
wait gates passing. V001 clears K1 at Turavur06:29:46; S007 clears K1 there06:35.
S007's ALLP extra wait falls from966 to216seconds. K1's TUVR extra wait is456s;
VB separately has68s and96s automatic-block signal waits while catching K1.
These are genuine costs of the three-train path, not omitted from the audit.
Both outcomes are preserved under `three-train-revised-slot`.

Increment004 then adds only M013 Mail, ERS departure900seconds after S007.
Its13 passenger calls onERS–TVC compare with6 superfast and4 VB calls, while
K1 serves all open compatible stations. Original004 normal13056/1812 and
delayed6944/18316 launched once01:53:54+08. Both original runs are still
being evaluated; no result is claimed yet.

Subsequent construction trials inherit the original preparation tool but omit
redundant five-minute snapshots of the empty hours before depot activation.
They retain the midnight state, service starts, active-period snapshots, every
simulation tick, the two-second traffic stream, disturbance and original wait
and safety calculations. One headless snapshot-policy test and the derived
script parse check pass. The full playable-day recorder remains unchanged.
Both added construction files are separately hashed and frozen along with the
six original observers and five acceptance/selection inputs. This is a
construction-output saving, not a different physics or acceptance policy.

The author now rejects bulk insertion, cuts, simultaneous add-and-retime, and
unpreserved preceding outcomes. It retains its own source and a fixed copy of
the measurement index in each future generation. Five authoring tests and three
launch-guard tests pass, including unchanged candidate bytes in a new folder,
partial launch intents, and post-authoring edits. The first checkpoint is LOCAL
`e400afa6`; no public Git push occurred.

## Complete physical basis and fourth placement revision

All44 physical profiles, every179 per-ID arrival calculation and57 exact source/
result files are retained under `physical-measurements`. No profile was rerun.
The first preservation command's final console-size expression failed after all
files/provenance were written; subsequent read-only hash verification confirmed
the archive. This was not a simulation or calculation failure.

Both004 runs completed4/4,77 arrivals/departures and depot workings, with zero
safety events. M013 passed K1 atALLP07:21:15.976, fully clear07:24:28. Normal
K1's ALLP extra wait is936seconds:242overtake,620receiving/reserved,70occupied
block and4authority. Station-under10 passes2/3, so the70% gate fails. Delayed
extra wait is566seconds, excluding the manual disturbance; its gates pass.
Both exact outcomes are preserved under `four-train-first-slot`.

004b revises only M013 toERS06:20, five minutes behind S007. The bounded
hypothesis is an earlier pass north ofALLP and earlier release of AMPA receiving
capacity. No saving is presumed. Original normal15640/3344 and delayed24200/21764
launched once02:05:31+08. Do not rerun or restart either. Current177 experiments,
old179 summaries and released R48 outputs are not involved in this new task.
