# Candidate 21 — original V2 delayed run rejected

The original wrapper 20296 / child 14748, launched once from candidate
74637eef with `--network --delay=600 --delay-at=27000`, finished naturally.
At **12:25:14**, L026 failed the 45-minute extra-wait gate at **Parassala**:
68/208 services complete, 2,702 seconds maximum in both wait populations,
zero safety events and empty run/inspection error logs. No acceptance,
installation or recovery certificate. The original baseline remains running;
all timetable/runtime/routes/observer inputs remain frozen. Never rerun this
unchanged rejected generation.

## Exact failed-prefix gates

| Population | Under 10 min (70%) | Under 20 min (90%) | Under 30 min (98%) | Under 45 min (100%) |
| --- | --- | --- | --- | --- |
| All locations | 194/263 pass | 237/263 pass | 252/263 fail | 262/263 fail |
| Station only | 106/157 fail | 138/157 fail | 150/157 fail | 156/157 fail |

Every fraction applies only to this failed prefix. Passing early fractions
are not whole-day certificates. No complete-population comparison was used.

## Actual queue and immutable inspection

L026 arrived Parassala at 11:38:56.85 and has no departure. Its 2,702-second
extra wait comprises 970 seconds reserving the NYY approach for M086,
916 seconds awaiting S050/M086 overtakes (326/590), 622 seconds of receiving
or onward-road protection, 130 seconds of occupied blocks, and 64 seconds
of route conflicts. Booked dwell is separate from the extra-wait population.

The read-only failure snapshot was inspected at NYY without advancing time;
its before/after captured bytes are identical. NYY claims are L025 P1 and
M086 P2. L026 waits at PASA-N2 for M086's protected approach; M086 waits at
NYY-N2 for opposing L025 in NEM_single. L025 is approaching NYY. S034 at KZT
protects the receiving/crossing capacity ahead of L025. M096 is dwelling at
TVC; L036 and S050 are already stored in their TVC depot roads.

K1, L025, M048, M068, L008 and S010 are moving at the inspected instant.
L024 waits at MQU for M068's overtake. This is not proof of permanent deadlock
or a runtime defect.

Two actual future-clearance plans are preserved, rather than assuming none:

- ALLP: incoming M014 to P2; opponent M023 to P3; vacater S010;
  escape MAKM_P1. `received=true`, `opponent_received=true`, `escaped=false`.
- NYY: incoming M086 to P2; opponent L025 to P1; vacater M096;
  escape NEM_P1. `received=true`, `opponent_received=false`, `escaped=true`.

L008 left TUVR at 12:02:50.75 and KUMM at 12:22:34.25 in this run. That is
local movement beyond its candidate20 Turavur hold; it does not prove a
whole-day improvement. Candidate21 instead fails earlier on L026 elsewhere.
K1 left TVC at 12:21:25.25 and is approaching NEM in this snapshot.

## Provenance and disturbance

Thirteen exact raw files are listed with lengths and SHA-256 values in
`provenance.json`: lossless audit/traffic/failure snapshot, original logs,
immutable inspection output and tool, actual summary, exact V2 pack and job
manifest. All 4,836 report source fingerprints matched current-at-run sources;
text checks use the report's CRLF normalization and binary checks use raw bytes.
The pack hash matches the actual audit and launch manifest. Original outputs
remain under `.local/realism-2026-10-26/rehearsals-v21/`.

The report records the configured 600-second K1 manual hold from 07:30.
Eleven minute samples preserve K1's 27.4545764399 m braking movement by 07:31,
then unchanged recorded extents through 07:40. Samples are not exact controller
frames and do not certify recovery. Disturbed or partial data must not be
installed. Runtime remains 9ec3530; the completed 1,003-test suite and candidate21's
four authoring guards were not rerun for evidence-only documentation.
