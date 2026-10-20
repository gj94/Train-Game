# Forward dispatch and manual departure horns — 20 October 2026

The same 100-service timetable is replayed from 08:00 through depot clearance.
All three final audits are fresh runs with identical simulation sources, not
continuations from a failed checkpoint. The two disturbances brake K1 for ten
minutes at the origin, or B012 from 09:23 after its future platform is promised.

| Run | Depot-cleared | Calls | Longest stand (min) | Total wait (train-min) | Max destination delay (min) | Safety events |
|---|---:|---:|---:|---:|---:|---:|
| R36 baseline | 100/100 | 1530 | 29.23 | 800.13 | 33.91 | 0 |
| Forward planning | 100/100 | 1530 | 28.17 | 822.03 | 37.81 | 0 |
| K1 held 10 min at origin | 100/100 | 1530 | 28.17 | 822.03 | 37.81 | 0 |
| B012 held 10 min after promise | 100/100 | 1530 | 28.17 | 815.73 | 37.81 | 0 |

Waiting excludes booked dwell and the deliberately braked driver. Calls exclude
100 origin entries. These figures are scenario validation, not a claim of global
optimality: some services gain time and others lose time. Per-service differences
are in `summary.json`. Runs shared the development PC; wall times are not a
controlled performance comparison.

## KZT regression

The immutable R36 B012 departure fixture preserves the reported case. Normal and
10-minute-late replays both pass. ERL stand falls from about 4m14s to none; KZT
home is prepared about 4.41 km ahead instead of 1.55 km. B088 remains held until
the entire VB enters its assigned receiving road. The freshly generated R37
departure repeats the 4.41 km result without an ERL stand. See both `kzt-final`
reports and `kzt-new-departure.json`.

An earlier candidate finished the day but failed the 30-minute wait gate: a new
ALLP future-clearance plan delayed an already-ready departure (B034, 38m32s).
That candidate was not published. The final guard declines a new plan when an
unrelated platform occupant is already due to use the same exit. A protected
live transaction is never cancelled to manufacture an earlier clearance.

## Verification

- 654 headless tests pass: 650 independent tests run alongside traffic generation,
  then all four traffic tests use the finished data. Targeted approach/future/horn
  cases are included. The temporary core runner is the normal source runner with
  only `test_service_traffic.gd` deferred to that second run.
- Four existing delayed-crossing rehearsals pass, plus both fixed KZT replays.
- Five-train native audio check passes using Godot's Dummy mixer. This verifies
  player state, automatic-pair cancellation, manual horn independence and mix
  bounds; it is not a listening test on the target laptop.
- Native dispatcher desk check passes. The legacy `check_corridor_playable.gd`
  harness still assumes the obsolete six-MEMU default and fails that setup
  assertion; it is not used to claim current 100-service gameplay coverage.
- Regenerated 100 departures and 233 exact five-minute states.
  Traffic replay records 470 crossings and 40 completed overtakes.
  All 1020 service-perspective cards are checked in the real launch UI:
  Crossing / You overtake / Overtakes you, times, other service, location and Y
  switching between Stops/Traffic. Actual play can change these baseline events.

## Player checks

1. Start the NCJ 09:10 to ERS VB. Let AI handle ERL/KZT, then repeat with a manual
   delay near ERL. Watch earlier home preparation and protected opposing traffic.
2. Take control between the two AI departure horns. The second must stay silent;
   B/H must still sound your horn. AI services keep their pair at later departures.
3. In the service browser, press Y for Traffic. Select both services in an overtake
   to see reciprocal wording, and inspect an overnight service's day-2 times.
