# Candidate sixteen: all four original runs rejected

All four runs ended naturally at 04:45:52, before the planned 07:30 K1 hold.
M045 exceeded the unchanged wait limit at NYY with 2,702 seconds of extra
station waiting; 13/208 services completed, zero safety events, empty stderr.
No intervention occurred. No whole-day acceptance or recovery certificate.

| Failed prefix | All-location cumulative under 10/20/30/45 minutes | Station-only cumulative |
| --- | --- | --- |
| Classic baseline and delayed | 39/45, 44/45, 44/45, 44/45 | 26/32, 31/32, 31/32, 31/32 |
| V2 baseline and delayed | 41/46, 45/46, 45/46, 45/46 | 27/32, 31/32, 31/32, 31/32 |

Both populations fail the 98% under-30 and 100% under-45 targets in every run.
44/45 and 45/46 are below 98%; no rounding. Earlier targets only pass within
these failed prefixes. The summarizer's finished flag means a final audit
exists; it does not mean all 208 services completed. The complete-population
comparator was not used.

Within each dispatcher mode, baseline and delayed service records, both wait
lists and traffic bytes match exactly before the intervention. Across modes,
M045's service record matches, but whole services, wait lists and traffic differ.
The scoped comparison records exact hashes; this is not causal or whole-day
equivalence.

M045 reaches TVC 03:37:12.70, leaves 03:42:27.80 and reaches NYY 03:57:01.10,
with no NYY departure. Its failed wait comprises 2,196 seconds of opposing
NYY single-line occupation (S042, M100, M078, M044), 468 seconds of PASA
receiving/downstream crossing protection, and 38 seconds of route conflicts.
The exact receiving-reason allocation differs between modes and is retained.

All four read-only inspections preserve snapshot bytes and have no remaining
future-clearance plans. NYY claims M045 P1 and incoming M044 P2. M044, M078,
M100 and S030 move in both modes; Classic M064 approaches PASA while V2 M064
awaits S046's pass. S042 is already in depot storage. These snapshots do not
establish permanent deadlock or a runtime defect.

45 exact raw files include losslessly compressed audits, traffic, failure
snapshots and immutable inspections, original logs, summaries, both exact packs,
inspection tool, job identities and scoped comparisons. Every report's 4,836
source hashes was checked against current inputs (4,837 distinct across modes).
Original local outputs remain. Runtime and observers were unchanged, and the
1,003-test source suite was not repeated. Never install or rerun these unchanged
failed generations; use their actual opposing/receiving queues for any next
departure-only candidate.
