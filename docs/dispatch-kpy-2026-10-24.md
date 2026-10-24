# Karunagappalli K1/B002 overtake investigation

Read-only investigation against R46's unchanged Intensive 140-service railway.
No dispatcher, timetable, prepared-state or track changes. The recorded baseline
reproduces the reported main/loop allocation; an individual manual journey may
have different times. No player save was supplied.

## Recorded sequence

- Around 11:33:46, K1 receives the Karunagappalli home route to KPY_P1, the
  southbound main. Estimated arrivals at the station are approximately 219.5
  seconds for K1 and 578.9 seconds for B002: a 359.4-second separation, outside
  the policy's 240-second overtake window. KPY_P4, the southbound loop, is
  occupied by D100 and its departure route is set. No K1 overtake hold exists.
- K1 stops on P1 at 11:37:58 in the prepared baseline.
- Around 11:39:05, B002's estimated arrival falls below 240 seconds. The policy
  adds a hold to K1, which is already dwelling on P1. P4 is now available.
- Around 11:39:23, B002 receives the route to P4. The prepared baseline records
  its arrival at 11:44:27 and departure at 11:46:02. B002 has a booked stop here.

The main/loop allocation was therefore made before the overtake hold. The
dispatcher did not deliberately select a reversed pair of roads for a pass.
It accepted a later overtake while retaining the slower train's existing berth.

## Sasthamkotta alternative and present capability

Sasthamkotta is the next station, about 7.65 km beyond Karunagappalli. K1 calls
there and B002 does not. Its southbound main STKT_P1 has no passenger face;
K1's stop is assigned to loop STKT_P3. That loop's clear passenger capacity is
about 608.7 m, compared with K1's 466.5 m formation. The proposed combination
of K1 on the platform loop and a non-stopping B002 on the main is supported by
the model's layout and stopping patterns.

The dispatcher can execute this kind of overtake: the faster train does not
need a booked call at the passing station. Incoming trains with a detected
priority conflict prefer a loop; through trains prefer a clear directional main.
However, `priority_dispatch.conflict()` evaluates one supplied station. It does
not compare alternative passing stations, calculate the combined delay of
passing now versus following to the next station, or explicitly reward a pass
that uses only the slower train's booked dwell. Arrival prediction includes
intermediate stops but does not turn this into a multi-station overtake plan.
The future-clearance planner handles protected crossing/platform succession,
not this optimization.

Sasthamkotta is consequently a sensible candidate to evaluate, not a proven
optimal or conflict-free alternative. No counterfactual rerouting was run.

## Evidence and validation

Loaded the eleven existing five-minute Intensive states from 11:10 to 12:00.
Replayed only 11:30–11:41 from T041400 with normal dispatch and a 0.5-second
outer step; no safety events. Focused priority-dispatch tests: 12 passed.
No full timetable simulation or regeneration.

Local diagnostic scripts and reports are `.local/inspect_kpy.gd`,
`.local/kpy-snapshots.json`, `.local/replay_kpy.gd`, `.local/kpy-replay.json`
and `.local/kpy-priority-tests.log`. Relevant production logic is
`sim/priority_dispatch.gd` (`conflict`, `update`, `choose_platform`),
`sim/dispatch_prediction.gd` and `sim/dispatch_engine.gd::_prepare_approach`.

To inspect the existing behavior, select Intensive, Explore by time at 11:40,
locate K1 at Karunagappalli and observe B002's approach to P4. This is a
reproduction instruction, not a request to validate a gameplay change.
