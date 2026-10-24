# Observed B002 / K1 passing roads

These are observations recovered from the current v3 Intensive rehearsals,
not forecast promises or final full-day certification. Each witness restores
its existing five-minute checkpoint, retains deterministic four-worker V2
execution, and compares every active train's centre/head/tail against the
original two-second traffic recording. No timetable or railway input changes.

| Rehearsal | Observed alignment | Station | K1 road | B002 road | B002 speed | B002 booked stop here |
| --- | --- | --- | --- | --- | --- | --- |
| Classic Intensive | 11:44:28 | Karunagappalli (KPY) | P1, main | P4, loop | 0 km/h | Yes |
| V2 Intensive candidate | 11:52:36 | Sasthankotta (STKT) | P3, loop | P1, main | 88.56 km/h | No |

K1 has a booked stop at both locations. The V2 observation therefore verifies
that it can use the passenger-only stop to let B002 pass on the main. The
Classic snapshot shows both trains at their booked station stops; it is not
proof that Classic routed a non-stopping B002 through a loop at full speed.
Game road labels are not official platform numbers.

All 961 source tests pass with zero failures and empty stderr.
The two witnesses compare 220 and 89 original traffic samples respectively.
Maximum position difference is below 0.000001 m in both; no safety event or
stderr error. The observer also rejects a deliberately incorrect railway
source hash before restoring or advancing any state. A broader provisional
six-pass observation is retained locally; full-day pass totals and waits are
still awaiting the original jobs.

The Intensive candidates have different authored relief departure times.
This comparison demonstrates the actual road choices, not a planner-only
punctuality improvement. The separately running Standard pair keeps identical
booked departures for that comparison.

Reproduction: first use `tools/summarize-timetable-run.mjs` to produce an
encounter JSON, then run `tools/audit_overtake_roads.gd` headlessly with
`--folder=res://<rehearsal> --events=res://<summary.json>
--output=res://<witness.json> --train=B002`. The tool checks frozen source
hashes and marks partial rehearsals explicitly; it never installs prepared data.

When certified data is installed, playtest Predictive V2 Intensive around
11:40â€“11:55 with K1 and B002 under AI. Inspect the forecast, then watch K1's
Sasthankotta loop stop and B002's main-line passage. Manual driving can move
the passing station; the recorded result is an AI-baseline observation.
