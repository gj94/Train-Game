# Candidate25 V2 baseline failure

The original v25 V2 baseline (wrapper 13108 / child 11232) finished naturally
and failed S031 at PASA-S2 at 15:15:14: 87/208 complete, 2702s maximum
all-location wait, 2458s station-only, zero safety events, no manual hold and
empty run/summary/inspection errors. Twenty exact raw files, 4836 verified
current-at-run source fingerprints, the actual summary and three byte-immutable
inspections are preserved in `network-candidate-twenty-five/failed-predictive-baseline`.
Original outputs remain. Both original v25 runs have now finished and failed;
never rerun unchanged or install either. Their source fingerprints remain
current for candidate25 and become historical after a later source change.

All-location cumulative counts 247/355, 312/355, 338/355, 354/355 fail ALL four
wait gates; 247/355 is below 70%, never round up. Station-only counts 130/198,
175/198, 192/198, 198/198 fail under 10/20/30 minutes. Passing fractions apply
only to this failed prefix. The two-second proximity to the delayed failure
does not establish equality of populations or a whole-day comparison.

S031 left TVC at 13:45:56.75 after arrival 13:38:38.95; its next booked KZT call
is unreached. PASA-S2 is a signal wait, not a booked Parassala call. Its failed
2702s wait comprises 2274s compatible KZT receiving, 406s opposing M082 and 22s
route conflicts with M082/S034. Combined receiving-reason buckets are retained
without attributing them to individual claimants.

Actual KZT claims are M102 P1 / M066 P2; PASA claims M082 P1 / S031 P2; NEM
claims M081 P1 / S051 P2. S031 waits for KZT receiving; M066/M102 wait for PASA
receiving. M082 at PASA protects S034's onward crossing at NYY; S034 at NYY
waits for NEM receiving occupied by M081/S051. M081/S051 at NEM protect PASA
crossing capacity for M082. L028 waits at ERL for KZT receiving; M054 waits
behind L028's occupied ERL block. M022/M049/M065/M053/M015 move, while M021
awaits booked departure and S048 is stored. All three inspections have no future
plans and byte-identical before/after captures. This saved queue does not prove
permanent deadlock or a runtime defect.

S032/M018/M050/S016 have continued beyond the northern map, with portal arrival
records 14:10:35.25 / 14:29:57.75 / 14:53:13.30 / 14:47:48.25 respectively.
K1/L025 are in NCJ depot (passenger arrivals 12:46:12.65 / 13:14:56.65).
These local observations are not whole-day improvement, capacity or recovery
proof. The baseline summary has no K1 overtakes in this failed prefix. No
complete-population comparison, recovery certificate or installation.

Next: coordinated departure-group planning from both actual v25 queues and
full-rake traffic samples. All safety, wait, physical and recovery gates remain;
only departures may change, with K1 fixed. Network208V2 remains unaccepted and
uninstalled. Runtime9ec3530, audio/gangways/portals, certified legacy choices,
R47 and pending UI/category files remain untouched. No Classic208 job, unchanged
full-suite rerun or new gameplay playtest. Feasibility and completion ETA remain
unproven.

`provenance.json` records original paths, raw byte lengths and SHA-256 hashes.
Compressed files decompress byte-for-byte to their retained original outputs.
