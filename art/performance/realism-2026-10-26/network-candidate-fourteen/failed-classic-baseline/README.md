# Candidate fourteen: rejected Classic baseline

The original Classic baseline launched once at 16:32 on 26 October 2026 from
`433be026` and ended naturally at simulated 09:34:44. M008 exceeded the unchanged
45-minute extra-wait limit at AMPA: 2,702 seconds, 47/208 services complete,
zero safety events and empty stderr. This baseline has no manual K1 hold.
The original V2 baseline remains pending; neither a complete-day certificate
nor Network installation follows from this failed prefix.

| Meaningful extra waits | Under 10 min | Under 20 min | Under 30 min | Under 45 min |
|---|---:|---:|---:|---:|
| All locations | 154/211 | 195/211 | 208/211 | 210/211 |
| Station only | 91/130 | 119/130 | 128/130 | 129/130 |

Both under-45 gates fail. The first three targets pass only within these
failed-prefix populations. No rounded acceptance or complete-population
comparison is used.

M008 arrives at AMPA at 08:48:33.20 and has no departure. Its extra wait records
1,194 seconds of opposing S009/M013/V001 section occupation, 748 of ALLP
receiving availability/reservations, 662 awaiting S006's overtake, 74 of occupied
blocks, and 24 of route conflicts.

The read-only inspection leaves the restored snapshot byte-identical and finds
no remaining future-clearance plans. M008 waits at AMPA-N2 for opposing S009;
M017 waits at ALLP-S2 behind S009's occupied block. M013, M064, S006, S009, S030,
V001 and K1 move, while L007 exchanges passengers. M064 is approaching ERS in
this baseline, unlike its earlier MAKM failure in the disturbed run. These
different failed prefixes do not establish full-day performance or a general
causal equivalence. No permanent-deadlock or runtime-defect conclusion.

`provenance.json` records 4,836 verified current source fingerprints, the exact
Classic pack hash, original job/options, selected records and 13 raw-file
hashes. Compressed audit/traffic/snapshot files restore the original bytes.
Local originals remain untouched. Runtime/tests and all frozen observers are
unchanged; the 1,003-test source result and four authoring guards were not
repeated. Await the original V2 baseline before departure-only replanning.
