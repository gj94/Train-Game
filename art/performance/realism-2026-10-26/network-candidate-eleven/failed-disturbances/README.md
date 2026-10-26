# Candidate-eleven disturbed runs rejected

Both original v11 disturbed runs finished naturally and failed the unchanged
45-minute wait gate. Classic stops at 08:52:40 with M006 at Ambalappuzha,
38/208 services completed. V2 stops at 07:56:50 with L002 at Neyyattinkara,
32/208 completed. Each failure records 2,702 seconds of extra waiting, zero
safety events and empty stderr. Both runs passed through the scheduled
07:30–07:40 manual K1 hold; neither certifies recovery or a complete operating day.
The two original baseline jobs remain independently pending.

All shorter cumulative wait targets pass within these failed prefixes. The
under-45-minute all-location fractions are 179/180 (Classic) and 142/143 (V2);
station-only fractions are 110/111 and 85/86. Each is below the required 100%.
These are exact partial-population counts, not estimates for the whole day.
The completed-day comparison tool was not applied to incomplete populations.

L005 now leaves Alappuzha at 07:28:45.80 in Classic and 07:28:30.30 in V2,
after arriving at 07:13:01.75 in both. Its recorded extra wait there falls to
816/802 seconds from the previous disturbed runs' 2,702-second rejection.
This is a local improvement, not acceptance of the two departure changes.

Classic M006 arrives at Ambalappuzha at 08:04:15.70 and has not departed at
rejection. Its extra-wait reasons include 1,216 seconds awaiting S030's overtake,
608 seconds of opposing K1 occupation, 410 seconds of opposing L007 occupation,
and 306 seconds preserving M064's onward crossing. The raw audit retains all
reasons. At inspection, M006 and S030 wait for L007's opposing section clearance;
L007 is exchanging passengers, while K1 and V001 are moving.

V2 L002 arrives at Neyyattinkara at 07:10:39.10 and has not departed at rejection.
Its reasons include successive opposing M095, V005, M075 and L023 movements,
and unavailable or reserved receiving space at Thiruvananthapuram South.
Classic L002 leaves Neyyattinkara at 07:12:31.30, before the manual K1 hold,
so this particular divergence predates that intervention. The baseline results
are still needed before attributing later differences to the disturbance.

Both read-only inspections leave the restored snapshots byte-identical.
Neither failure snapshot contains a future-clearance plan; several trains
remain moving. This is not an immovable-deadlock or runtime-defect conclusion.
No runtime, route, authored pack or observer was edited during these runs.

All 4,837 distinct current source fingerprints and both exact authored pack
hashes were verified. `provenance.json` records 24 exact raw files, including
the packs, audits, traffic, failure snapshots, logs and immutable inspections.
Compressed files round-trip to their original bytes. The summary tool's
`finished` flag means a final audit exists, not that all 208 services completed;
the embedded audit is explicitly rejected. Original local outputs are retained.
No Network data is installed; legacy certified choices and R47 are unchanged.
