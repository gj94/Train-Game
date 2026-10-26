# Candidate twelve: V2 delayed run rejected before intervention

The original V2 delayed replay, launched from `c8856a27` with a 600-second K1
hold scheduled at 07:30, stops at **06:38:42**. S025 exceeds the unchanged
45-minute continuous extra-wait limit at **PASA-S2, Parassala**: 2,702 seconds.
Only 24 of 208 services are complete. Safety events: zero. Stderr: empty.
The intervention has not occurred; this is neither a recovery test result nor
a complete-day traffic result. Do not install this output as prepared data.

The all-location cumulative wait gates under 30 and 45 minutes fail at
111/114 and 113/114. Its shorter gates pass. Station-only gates pass within
this failed prefix (50/62, 60/62, 61/62, 62/62); the longest station wait is
1,810 seconds. Station-only success does not override the all-location failure.
No percentage is rounded up to turn a failure into a pass.

S025's recorded Parassala wait includes 2,242 seconds of Kulitturai receiving
roads reserved for approaching S030/L022, 446 seconds of opposing L002 section
occupation and 14 seconds of route conflict. The read-only snapshot inspection
finds S025 and M077 occupying Parassala's two roads, S030 waiting at KZT-N2 for
Parassala space, and L022 waiting before Kulitturai while the dispatcher preserves
crossing space at Parassala. The other inspected trains form queues through
Neyyattinkara and Thiruvananthapuram South. All eight inspected trains are stopped
at this instant. No future-clearance plan remains. This snapshot alone is not a
proof of a permanent deadlock or a runtime defect; the other original replays
must finish before selecting another departure-only repair.

The inspection does not step the world and leaves its captured bytes unchanged.
All 4,836 report source hashes and the exact authored V2 pack hash were checked
against the source in use. Thirteen raw files are preserved with raw SHA-256
hashes in `provenance.json`; gzip files decompress byte-for-byte to their original
audit, traffic, failure snapshot and inspection. Original local outputs remain.

The existing summarizer was run on the actual final report. Its `finished` flag
means an audit exists, not that all 208 services completed. The full-population
comparator was not applied. No source, timetable or frozen observer changed.
The unchanged runtime retains its 1,003-test result; the candidate's four
authoring checks and exact reproduction remain current. Both baseline replays
and Classic's delayed replay continue in their original isolated outputs.
