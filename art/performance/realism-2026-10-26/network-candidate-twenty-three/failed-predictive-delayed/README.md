# Candidate 23 — original V2 delayed run rejected

The original wrapper 832 / child 10968, launched once from candidate
87de4c8a with `--network --delay=600 --delay-at=27000`, finished naturally.
At **13:26:44**, M019 failed the 45-minute extra-wait gate at **Alappuzha**:
71/208 services complete, 2,702 seconds maximum in both wait populations,
zero safety events and empty run/inspection error logs. No acceptance,
installation or recovery certificate. The original baseline remains running
at this inspection; runtime, routes, packs and observers remain frozen.
Never rerun this unchanged rejected generation.

## Exact failed-prefix gates

| Population | Under 10 min (70%) | Under 20 min (90%) | Under 30 min (98%) | Under 45 min (100%) |
| --- | --- | --- | --- | --- |
| All locations | 196/275 pass | 244/275 fail | 266/275 fail | 274/275 fail |
| Station only | 104/158 fail | 138/158 fail | 152/158 fail | 157/158 fail |

Every fraction applies only to this failed prefix. Passing its first all-location
fraction does not certify the whole day. No complete-population comparison ran.

## Actual queue and immutable inspections

M019 reached Alappuzha at 12:36:22.45 and has no departure. Its 2,702-second
extra wait comprises 1,014 seconds awaiting S013's overtake, 746 seconds of
opposing ALLP_single traffic (M018 340; S016 406), 708 seconds of Ambalappuzha
receiving protection, 170 seconds of occupied blocks and 64 seconds of route
conflicts. Booked dwell is separate from these extra waits.

The failure snapshot was inspected at AMPA without stepping the simulation.
An initial inspection and a second inspection adding M028 are both retained;
each reports byte-identical before/after captured state and no future-clearance
plans. Actual AMPA claims are M050 P3 and incoming M028 P2. M028 is moving
towards AMPA-N2. M050 waits at AMPA-N3 for compatible Alappuzha receiving
capacity associated with M101 and M019. M019 at ALLP-S3 and M101 at ALLP-S1
wait for opposing S016, which is moving towards ALLP-N2. S013 has left ALLP
and is moving south. M018, S032, M051 and M014 also move at the inspected
instant. This does not establish permanent deadlock or a runtime defect.

L025 is already stored in its Nagercoil depot. K1 left Nagercoil Town at
13:24:57.25 and is moving towards Nagercoil Junction. L026, L036, M068, M096,
S050 and M086 are also moving. These local observations beyond the earlier
southern blockage do not establish whole-day improvement or recovery.

## Provenance and disturbance

Sixteen exact raw files are listed with lengths and SHA-256 values in
`provenance.json`: lossless audit/traffic/failure snapshot, original logs,
both immutable inspections, inspection tool, actual summary, exact V2 pack
and job manifest. All 4,836 report source fingerprints matched current-at-run
sources; text checks use the report's CRLF normalization and binary checks use
raw bytes. The pack hash matches the audit and launch manifest. These source
hashes belong to candidate23 and must not be relabelled after future changes.
Original outputs remain under `.local/realism-2026-10-26/rehearsals-v23/`.

The report records the configured 600-second K1 manual hold from 07:30.
Eleven minute samples preserve K1's 27.4545764399 m braking movement by 07:31,
then unchanged recorded extents through 07:40. Samples are not exact controller
frames and do not certify recovery. The actual traffic summary records one
K1 overtake by V001 at TVCN in this prefix, not completed-day multiple-location
proof. Its `finished` flag means that the final audit exists, not that all
208 services completed. Disturbed or partial data must not be installed.
Runtime remains 9ec3530; the completed 1,003-test suite and candidate23's four
authoring guards were not rerun for evidence-only documentation.
