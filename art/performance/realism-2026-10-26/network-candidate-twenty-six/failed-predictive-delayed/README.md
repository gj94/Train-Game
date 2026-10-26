# Candidate26 V2 delayed failure

27 October 07:50 — candidate26 V2 delayed run rejected; baseline still live.

The original delayed run 16324/14784 finished naturally at 16:06:14 after the
configured 600-second K1 hold at 07:30. M051 exceeds the 45-minute wait gate
at its booked Parassala call: 97/208 services complete, maximum all-location
and station-only wait 2702 seconds, zero safety events, empty run/summary/
inspection error logs. Preserve this failed result; never rerun unchanged or
install it. Candidate26 remains unaccepted/uninstalled.

All-location cumulative counts are 286/383, 350/383, 372/383, 382/383,
failing under 30 and 45 minutes. Station-only counts are 143/206, 186/206,
200/206, 205/206, failing under 10, 30 and 45 minutes; 143/206 is below 70%,
never round it up. Passing fractions describe only this failed prefix.
M051 arrives Parassala at 15:18:17.75 and has not departed. This is a booked
station wait, with current signal PASA-S1, unlike S031's prior signal wait.
Its 2702 seconds comprise 1354 opposing (L028 550, M052 398, M066 406),
1312 compatible KZT receiving, and 36 conflicts (12 each for those trains).
The combined receiving reason buckets remain preserved without assigning
all their time to individual claimants.

Actual KZT claims are L004 P2 and approaching M102 P1; PASA claims are M051 P1
and M066 P2. M051 waits for KZT receiving; L004 awaits M102's overtake, while
M102 is moving toward its KZT call. M066 waits for NYY receiving reported
against M052/S051; S051 at NYY waits for both PASA roads. S049 at NEM waits
for opposing M052. S054 at ERL also waits for KZT receiving; M054 waits behind
S054's ERL block. L028, M052, M102 and S034 move; V007/M081 await a clear TVC
origin berth. The initial KZT and final PASA inspections have byte-identical
before/after captures and no future clearance plans. This is not evidence
of permanent deadlock or a runtime defect.

S031 has continued beyond the southern boundary, with NCJ passenger arrival
15:01:47.90 and portal arrival 15:07:22.80. M082 is in TVC depot storage after
arrival 15:23:28.35. K1/L025 are in NCJ depot with passenger arrivals
13:31:09.15 / 13:11:10.65. These are local observations, not whole-day
improvement, capacity or recovery proof. Eleven K1 minute samples show
27.4545764399 m braking by 07:31, then unchanged recorded extents through
07:40; these samples are not exact controller frames or a recovery certificate.
The actual final-report traffic summary records one V001 overtake of K1 at
TVCN, not completed multiple-location proof. No complete-population comparison.

Evidence: art/performance/realism-2026-10-26/network-candidate-twenty-six/
failed-predictive-delayed. Seventeen exact raw files preserve lossless audit,
traffic, failure snapshot, exact V2 pack, actual summary and both immutable
inspections. All 4836 source hashes and the pack hash match current-at-run
candidate26; preserve their provenance when any later candidate changes sources.
Original outputs remain. Runtime/tests and all frozen source inputs are unchanged;
no repeated suite, Classic208 run or native check was needed for this evidence.

At 07:50:06 the original baseline 3728/12192 is still live at 12:50, 69/208,
with empty stderr and no final audit. Its exact command and parent identities,
the V2 pack and all six observer hashes still match the launch. Only those two
original Godot processes remain after the completed inspections. Keep all frozen
inputs unchanged until the baseline finishes; then plan coordinated opposing
groups using both actual queues, compatible roads and full-tail clearance.
No new gameplay playtest is ready.
