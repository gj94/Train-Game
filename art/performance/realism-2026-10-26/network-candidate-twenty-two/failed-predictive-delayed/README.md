# Candidate 22 — original V2 delayed run rejected

The original wrapper 7952 / child 19620, launched once from candidate
6d6f0518 with `--network --delay=600 --delay-at=27000`, finished naturally.
At **12:42:12**, L025 failed the 45-minute extra-wait gate at **Neyyattinkara**:
70/208 services complete, 2,702 seconds maximum in both wait populations,
zero safety events and empty run/inspection error logs. No acceptance,
installation or recovery certificate. The original baseline remains running
at this inspection; all timetable/runtime/routes/observer inputs remain frozen.
Never rerun this unchanged rejected generation.

## Exact failed-prefix gates

| Population | Under 10 min (70%) | Under 20 min (90%) | Under 30 min (98%) | Under 45 min (100%) |
| --- | --- | --- | --- | --- |
| All locations | 193/260 pass | 234/260 pass | 250/260 fail | 259/260 fail |
| Station only | 106/155 fail | 136/155 fail | 148/155 fail | 154/155 fail |

234/260 is exactly 90%. Every fraction applies only to this failed prefix;
no passing early fraction certifies the whole day. No complete-population
comparison was used.

## Actual queue and immutable inspection

L025 arrived Neyyattinkara at 11:55:56.65 and has no departure. Its 2,702-second
extra wait comprises 2,076 seconds of opposing NYY_single traffic (M096 566,
S050 570, M086 574, L036 366), 556 seconds of receiving or onward protection,
34 seconds awaiting L036's escape-approach clearance, and 36 seconds of route
conflicts. Booked dwell is separate from these extra waits.

The failure snapshot was inspected at NYY without advancing time; its
before/after captured bytes are identical. NYY claims are L025 P1, L036 P2,
and incoming K1 with P1/P2 alternatives. Those alternatives are not two
simultaneous road reservations. L025 waits at NYY-S1 for L036's escape approach.
L036 is exchanging passengers at AMVA while approaching NYY; L026 waits at
PASA-N1 because the escape section is protected for L025 at NYY.

One actual future-clearance plan is preserved: NYY incoming K1 to P1,
opponent L036 to P2, vacater L025, escape PASA_P2. At failure,
`received=false`, `opponent_received=false`, and `escaped=false`.

K1, M048, M068, M086, M096 and S010 are moving at the inspected instant;
L024 and L036 exchange passengers. L008 is already stored in its Ernakulam
depot, S050 in its TVC depot; S034 awaits its booked departure. This does
not establish permanent deadlock or a runtime defect.

K1 left TVC at 11:52:15.75 and NEM at 12:41:53.25. L026 reached PASA at
12:35:13.55 after its later departure; it has no departure there yet. L008
left TUVR at 12:02:50.75 and KUMM at 12:22:34.25 before reaching its depot.
These are local observations, not proof of whole-day improvement or recovery.

## Provenance and disturbance

Thirteen exact raw files are listed with lengths and SHA-256 values in
`provenance.json`: lossless audit/traffic/failure snapshot, original logs,
immutable inspection output and tool, actual summary, exact V2 pack and job
manifest. All 4,836 report source fingerprints matched current-at-run sources;
text checks use the report's CRLF normalization and binary checks use raw bytes.
The pack hash matches the audit and launch manifest. Original outputs remain
under `.local/realism-2026-10-26/rehearsals-v22/`.

The report records the configured 600-second K1 manual hold from 07:30.
Eleven minute samples preserve K1's 27.4545764399 m braking movement by 07:31,
then unchanged recorded extents through 07:40. Samples are not exact controller
frames and do not certify recovery. The actual traffic summary records one
K1 overtake by V001 at TVCN in this prefix, not the required completed-day
multiple-location proof. Disturbed or partial data must not be installed.
Runtime remains 9ec3530; the completed 1,003-test suite and candidate22's four
authoring guards were not rerun for evidence-only documentation.
