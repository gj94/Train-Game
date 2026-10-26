# Candidate thirteen: both disturbed runs rejected

The original Classic and V2 jobs finished naturally after the 600-second manual
K1 intervention at 07:30. Neither completes the day or certifies recovery.
Both finish 43/208 services with zero safety events and empty stderr.

| Mode | Failure | Simulated time | Extra continuous wait |
| --- | --- | --- | --- |
| Classic | L024 at Kulitturai (KZT) | 09:19:08 | 2,702 seconds |
| V2 | V001 at Mararikulam signal MAKM-S3 | 09:17:48 | 2,702 seconds |

Exact cumulative fractions below describe these failed prefixes only. Targets
are 70%,90%,98%,100%; failed fractions are not rounded up.

| Population | Under 10 min | Under 20 min | Under 30 min | Under 45 min |
| --- | --- | --- | --- | --- |
| Classic, all locations | 155/217 | 193/217 **fail** | 212/217 **fail** | 216/217 **fail** |
| Classic, station only | 88/130 **fail** | 116/130 **fail** | 127/130 **fail** | 129/130 **fail** |
| V2, all locations | 154/213 | 192/213 | 207/213 **fail** | 212/213 **fail** |
| V2, station only | 84/121 **fail** | 109/121 | 117/121 **fail** | 121/121 |

Classic L024 reaches KZT at 08:32:55.40 and has no departure. Opposing L035,
M075, M047 and L023 consume 1,562 seconds of its waiting; receiving-platform
availability and downstream crossing protection account for 1,102 seconds,
with 38 seconds of route conflicts. L035's earlier departure still leads to
2,696 seconds of extra waiting at PASA, including successive M075/V005 passes.
L023 accumulates 2,686 seconds at NYY before leaving at 08:43:37.80.

V2 V001 waits at MAKM-S3 while Alappuzha receiving space and opposing traffic
remain constrained. Opposing M064 and S030 account for 1,164 seconds; the
remaining 1,538 seconds concern ALLP receiving availability/reservations.
At the failure snapshot L007 remains at ALLP, M008 is arriving there and M017
is moving through its approach. K1, L015, M013, M064 and S030 also move.

Both read-only failure inspections preserve the snapshot bytes and contain no
remaining future-clearance plans. Several trains move; these observations do
not establish a permanent deadlock or a runtime defect. The baseline runs are
still pending, so no causal attribution to the manual hold is made.

The verified preparation source applies manual braking for the specified
interval. Minute samples of K1's actual extents are preserved in provenance:
Classic is stationary across 07:30–07:40; V2 brakes about 13.56 metres further
by 07:31 and remains stationary through 07:40. These are sampled positions,
not fabricated exact controller-state frames.

`provenance.json` records 22 byte-exact raw files, including losslessly
compressed audits, traffic and failure snapshots; both packs; summaries; and
the read-only inspections. All 4,837 distinct current source fingerprints and
both pack hashes were independently checked. The authoring commit is e81de25a;
runtime remains 9ec3530. The existing 1,003-test source suite and four authoring
checks remain applicable; no runtime/tests/observer edits or suite rerun occurred.
Original local outputs remain intact. No partial or disturbed data is installed.
