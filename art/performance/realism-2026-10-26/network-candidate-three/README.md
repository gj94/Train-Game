# Third Network candidate: rejected crossing promises

These are failed or interrupted replays, never prepared baseline data. Both
delayed runs fail before the scheduled 07:30 / 600s manual K1 hold:

| Mode | Failure clock | Train | Completed | Maximum extra wait | Safety events |
|---|---|---|---:|---:|---:|
| Classic | 07:29:16 | L021 at NEM | 28/208 | 2,702s | 0 |
| Predictive | 07:07:02 | L002 at KZT | 26/208 | 2,702s | 0 |

Both modes expose the same shared future-crossing defect. A physically empty
escape road was promised without checking the claims of trains already admitted
from the station's other approach. The interlocking correctly kept the resulting
conflicting movements stopped, but the planning promise created a deadlock.

The original Classic 06:50 state has L021 on NEM P2, L033 approaching from TVC,
and a crossing promise assigning NEM P1 to L002. The predictive 06:30 state has
L002 on KZT P2, L022 approaching from Eraniel, and KZT P1 promised to M061.
In both restored states three compatible arrival claims cannot fit two roads.
`escape-plan-claims.json` verifies this without changing either restored world.
The four exact original compressed states and their SHA-256 hashes are retained.

Actual departure records and two-second traffic put L033's departure at
24,351.30s before the 24,400.05s promise, and L022's Eraniel departure at
23,143.30s before the 23,276.55s promise. The exact promise-creation frame was not
saved; do not describe these five-minute states as that frame. The adjacent
traffic sample places L022 physically inside KZT_single, while L033 is still
within the TVC departure yard after its recorded departure. The regressions
cover both an occupied approach and a granted departure route.

The correction filters candidate escape roads through the existing berth
matching rule, including occupied, committed-route and admitted-approach claims.
Only the known opponent's old claim is released because its departure precedes
the vacater's arrival in this bounded transaction. No physical route is granted
by this check, no extra road is invented, and ordinary tail/interlocking rules
remain authoritative. Both on-approach and already-granted-departure regressions
fail before and pass after; the unclaimed-escape positive case still passes.
All 33 focused future-crossing checks pass. The complete source suite finishes
with 995 passed, zero failures and empty stderr; exact logs are included.

All six unfinished baselines were stopped after verifying the exact owned child
commands, before changing the shared source. The four legacy partials are also
obsolete. Their original local folders remain intact. Network baseline prefixes
match their respective failed delayed runs for 12,409 / 11,812 complete samples;
interrupted trailing lines remain archived unchanged and are excluded from that
comparison. This proves only observed prefix equality, not future completion.

`provenance.json` records raw file hashes and job dispositions. Audits, failed
worlds and traffic are gzip copies with decompressed byte equality checked.
The exact candidate-three authored packs are included. No departure, call,
dwell, stock or priority was changed for this runtime correction. Fresh complete
replays of all six baselines and both Network disturbances are required.
