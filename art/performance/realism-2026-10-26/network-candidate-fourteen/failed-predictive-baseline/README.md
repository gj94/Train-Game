# Candidate fourteen: rejected V2 baseline

The original V2 baseline launched once at 16:32 on 26 October 2026 from
`433be026` and ended naturally at simulated 11:28:50. S047 exceeded the unchanged
45-minute extra-wait limit at NEM-S1: 2,702 seconds, 62/208 services complete,
zero safety events and empty stderr. This baseline has no manual K1 hold.
All four v14 runs are now finished and rejected. Nothing is installed.

| Meaningful extra waits | Under 10 min | Under 20 min | Under 30 min | Under 45 min |
|---|---:|---:|---:|---:|
| All locations | 249/329 | 307/329 | 326/329 | 328/329 |
| Station only | 124/171 | 158/171 | 170/171 | 171/171 |

All-location under-45 fails. Station-only gates pass within this prefix, with
a 2,040-second maximum; they do not waive the all-location gate or establish
complete-day performance. No complete-population comparison is used.

S047's NEM-S1 wait records 1,796 seconds of opposing S032/M048/M050/M084 section
occupation, 858 of NYY receiving availability and onward PASA crossing-space
protection, and 48 of route conflicts. The read-only inspection is byte-immutable
and has no remaining future-clearance plans. L024 occupies NYY P2 waiting for
M068 to pass; M068 approaches P1. L036 waits at PASA for S050. M048, M050, S032,
M068, L025 and L026 move, and M084 is returning to its TVC depot. This does not
establish a permanent deadlock or a runtime defect.

`provenance.json` records 4,836 verified current source fingerprints, the exact
V2 pack hash, original job/options, selected service/wait records and 13 raw-file
hashes. Compressed files restore their source bytes; local originals remain.
All runtime/tests and observers are unchanged. The 1,003-test source result and
four authoring guards remain separate from rejected traffic acceptance.
