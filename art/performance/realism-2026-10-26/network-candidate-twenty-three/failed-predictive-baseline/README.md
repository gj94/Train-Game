# Candidate 23 — original V2 baseline rejected

Original wrapper8580 / child19068, launched once from87de4c8a with
`--network --snapshots`, finished naturally without a manual hold.
At **14:38:34**, M028 failed the 45-minute extra-wait gate at **Alappuzha**:
81/208 services complete,2702 seconds maximum in both wait populations,
zero safety events and empty run/final-inspection error logs. Both original
candidate23 V2 runs are now finished and rejected. Never rerun unchanged.

| Population | Under10min (70%) | Under20min (90%) | Under30min (98%) | Under45min (100%) |
| --- | --- | --- | --- | --- |
| All locations | 244/348 pass | 308/348 fail | 332/348 fail | 347/348 fail |
| Station only | 122/190 fail | 165/190 fail | 182/190 fail | 189/190 fail |

These fractions describe only the failed prefix, not complete populations.
No comparison, installation, acceptance or recovery certificate was produced.

M028 arrived ALLP13:51:31.85 and has no departure. Its2702-second extra wait
comprises1512 seconds opposing MAKM_single traffic (M065790; M049722),
1014 seconds compatible receiving/onward crossing protection,86 seconds
occupied blocks and90 seconds route conflicts. Booked dwell is separate.
Its earlier AMPA arrival13:29:11.30 and departure13:40:53.25 are retained.

Two read-only snapshot inspections preserve byte-identical captured state,
without stepping simulation; both report no future-clearance plans. The first
MAKM inspection has M053P3 and incoming M015P1/P2/P3 alternatives. Its stdout
and stderr were captured together in the retained combined log. The final
ALLP inspection includes M016/S012 and separate logs with empty stderr.
ALLP claims are M028P1, with incoming M016, M065 and S012 each having
P1/P2/P3 alternatives; alternatives are not simultaneous reservations.
M028 waits for M065 in MAKM_single. M065 approaches ALLP and protects its
compatible receiving capacity for M028/M016/S012. M053 waits at MAKM for
ALLP receiving roads; M016 awaits automatic block clearance, while S012
protects ALLP receiving capacity. M015, M018, M019, S013 and S016 move.
M049 and M101 exchange passengers. M050 waits at TUVR for KUMM receiving
capacity associated with M021/S015/M018. These observations do not establish
permanent deadlock or a runtime defect.

K1 and L025 are already in NCJ depot storage (NCJ arrivals12:46:12.65 and
13:14:56.65 respectively). M019 has passed its delayed-run failure location
and left VAK14:29:22.75. These are local observations, not whole-day improvement
or recovery. The actual baseline summary records no K1 overtakes in this
prefix; multiple-location overtakes remain unproven. Its `finished` flag means
that an audit exists, not that208 services completed.

Fifteen exact raw files, lengths and SHA-256 values are retained in
`provenance.json`: lossless audit, traffic, failure snapshot, both inspections,
logs, tool, actual summary, exact pack and job manifest. All4836 report source
fingerprints matched current-at-run sources, with report CRLF normalization
for text and raw bytes for binary. The pack hash matches audit and launch.
Hashes belong to candidate23 and must not be relabelled after future changes.
Original outputs remain under`.local/realism-2026-10-26/rehearsals-v23/`.
Runtime9ec3530 remains unchanged. No unchanged full suite or authoring guards
were rerun for this evidence-only increment. Pending helpers remain pending.
