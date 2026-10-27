# Candidate26 V2 baseline failure

27 October 08:10 — both original candidate26 V2 runs rejected.

The original baseline 3728/12192 finished naturally at 15:42:26 without an
intervention: M082 exceeds 45 minutes at its booked Neyyattinkara call,
91/208 complete, maximum 2702 seconds in both wait populations, zero safety
events and empty run/summary/inspection errors. All-location counts
258/370, 328/370, 356/370, 369/370 fail all four gates; 258/370 is below 70%.
Station-only 140/209, 186/209, 203/209, 208/209 also fail all four gates.
Every passing fraction is only a failed-prefix result; no full comparison.

M082 arrives NYY at 14:53:06.25 and has not departed; current signal NYY-N1.
The 2702-second station wait comprises 2218 seconds of compatible NEM
receiving, 472 opposing M051 and 12 route conflicts with M051. Preserve the
combined receiving buckets without assigning them to individual claimants.
Actual NEM claims are S051 P1/S049 P2; NYY claims M082 P1/M051 P2; KZT claims
L028 P1/M052 P2. M082 waits for NEM; S051/S049 wait for NYY. M051 protects KZT
crossing capacity for L028/M052; both northbound trains protect NYY crossing
capacity for M051. M066 waits at ERL for KZT receiving; L004 waits behind
M066's ERL block, M102 behind L004 and S054 behind M102. M054 and S034 move;
V007/M081 await a clear TVC origin berth. The NEM, KZT and final NYY inspections
all have byte-identical before/after captures and no future clearance plans.
No permanent-deadlock or runtime-defect inference follows from this snapshot.

S031 has continued beyond the southern boundary, with NCJ passenger arrival
14:54:47.50 and portal arrival 15:00:22.30. K1/L025 are in NCJ depot storage,
with passenger arrivals 12:46:12.65 / 13:14:56.65. The baseline traffic summary
has no K1 overtakes in its prefix. Local progress is not whole-day improvement,
capacity or recovery proof. Both original v26 results are rejected; never rerun
unchanged, install them or compare them as complete populations.

Baseline evidence is in network-candidate-twenty-six/failed-predictive-baseline:
20 exact staged raw files, 4836 verified current-at-run sources, lossless audit/
traffic/failure, exact V2 pack, actual summary and three immutable inspections.
Delayed evidence remains in da75521d with 17 raw files and two inspections.
Original outputs remain. Both processes have ended; no live replay, suite,
native or diagnostic remains. Preserve candidate26 source provenance as
historical once a later departure-only candidate changes it. Network208V2 is
unaccepted/uninstalled. Runtime/tests remain unchanged; no repeated full suite
or Classic208 work. Next: coordinated departure groups from both actual queues
and full-rake samples, retaining every physical and wait gate. No new playtest.
