# Candidate thirteen: both baselines rejected

All four original v13 runs have now finished naturally. The Classic baseline
fails L007 at Alappuzha at 09:07:06 after 41/208 completions. The V2 baseline
fails L024 at Kulitturai at 09:19:08 after 44/208 completions. Each exceeds the
45-minute continuous extra-wait limit at 2,702 seconds, with zero safety events
and empty stderr. No Network data is installed.

These cumulative fractions describe failed prefixes, not a complete day:

| Population | Under 10 min | Under 20 min | Under 30 min | Under 45 min |
| --- | --- | --- | --- | --- |
| Classic, all locations | 144/203 | 189/203 | 198/203 **fail** | 202/203 **fail** |
| Classic, station only | 85/123 **fail** | 113/123 | 119/123 **fail** | 122/123 **fail** |
| V2, all locations | 157/217 | 201/217 | 211/217 **fail** | 216/217 **fail** |
| V2, station only | 86/126 **fail** | 117/126 | 121/126 **fail** | 125/126 **fail** |

Classic L007 reaches ALLP at 08:20:02.65 and does not depart. Its extra wait
includes 1,088 seconds awaiting M013's overtake and 646 seconds opposing L014,
alongside receiving-platform reservations, occupied blocks and route conflicts.
L015 starts from ALLP at 08:33:16.30 and occupies the same southern corridor;
M013 leaves ALLP at 08:57:13.30. At failure M008 and S006 wait at AMPA for ALLP
space while S030 waits at ALLP for opposing V001. V001, M013, M006, M017 and K1
are moving. This is not proof of permanent deadlock or a runtime defect.

V2 L024 reaches KZT at 08:32:55.40 and does not depart. Its whole service record
and station-wait rows exactly match the **Classic delayed** run at the same
failure clock. Whole service records and traffic bytes differ; the comparison
is explicitly scoped and is not a causal or complete-population equivalence.
The L024 failure also occurs without a manual K1 hold. L035 and L023 have
accumulated 2,696 and 2,686 seconds of station waiting at PASA and NYY. M047,
L035 and S045 are moving in the final inspection.

Both inspections preserve snapshot bytes and show no future-clearance plans.
The 24 exact raw files in provenance preserve audits, traffic, failure states,
logs, summaries, inspections and both packs. All 4,837 distinct current source
fingerprints, pack hashes and staged raw hashes are verified. Original outputs
remain intact. Runtime/tests/observers are unchanged from the existing checks.

Next departure-only hypothesis: move L024 from 07:40 to 09:20, after the
observed concentrated southbound wave rather than inserting it into that wave;
move L015 from 08:15 to 10:05, freeing ALLP origin/receiving space during the
observed L007/M013/V001 and opposing S030/M008/S006 movements. This also keeps
the hourly count at most thirteen. Later traffic may still invalidate these
times. Exact authoring checks and entirely new real replays are required; no
acceptance, modeled score or guaranteed improvement is claimed.
