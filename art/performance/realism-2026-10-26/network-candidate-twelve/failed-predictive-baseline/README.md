# Candidate twelve: V2 baseline rejected at the same early queue

The original V2 baseline also stops at **06:38:42** with S025 waiting 2,702
seconds at PASA-S2. Only 24/208 services finish, with zero safety events and
empty stderr. All-location under-30 and under-45 cumulative gates fail at
111/114 and 113/114; station-only gates pass within this failed prefix only.

This baseline's complete service records, station waits, signal waits and
traffic bytes match the V2 delayed run up to their common failure time. Both
traffic SHA-256 hashes are
`f3eec9c1e08320ab033747b3600b396c7110950d89cc08d4793ad7da73033c8f`.
Both prefixes stop before the delayed run's planned 07:30 intervention. This is
scoped prefix equality, not full-day equivalence or a recovery certificate.
The comparison is preserved in `baseline-vs-delayed.json`; the full-population
comparison tool was not misapplied to incomplete populations.

Read-only inspection leaves world bytes unchanged. No future-clearance plan
remains, and the same inspected PASA/KZT/NYY/NEM queue is present. All eight
inspected trains are stopped at this instant. This alone does not prove a
permanent deadlock or runtime defect. See the adjacent V2 delayed evidence for
the recorded receiving-road and opposing-traffic wait breakdown.

All 4,836 source fingerprints and the exact V2 pack hash were verified.
Fourteen exact raw files are preserved with raw hashes in `provenance.json`;
gzip files decompress byte-for-byte. Original local outputs remain. No runtime,
pack or frozen observer changed. The unchanged 1,003-test source result and
four authoring checks remain current; no full suite was repeated for evidence.
Only the original Classic baseline remains running. No Network data is accepted
or installed, and these failed outputs must never be installed as baselines.
