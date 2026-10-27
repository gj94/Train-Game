27 October 09:57 — candidate27 V2 baseline also rejected; both original runs ended.

The original baseline11952/20024 finished naturally at16:07:48 with M026 at
signal TUVR-N3 and96/208 complete. Maximum all-location wait is2702s;
station-only maximum2458s. Zero safety events and empty run, summary and both
inspection error logs; no manual intervention. Both original v27 V2 runs have
now failed. Never rerun either unchanged or install their partial outputs.

Evidence: network-candidate-twenty-seven/failed-predictive-baseline preserves
17 exact raw files, lossless audit/traffic/failure, exact V2 pack, actual final
summary and two byte-immutable KUMM/TUVR inspections. All4836 distinct source
hashes match current-at-run candidate899a8292. Original outputs remain. These
fingerprints must remain historical after any next candidate changes sources.

All-location cumulative275/375,342/375,364/375,374/375 fails30/45 minutes.
Station-only146/210,192/210,207/210,210/210 fails10 minutes;146/210 is below70%,
never round up. Passing fractions describe only the failed prefix. M026 left
booked Cherthala/SRTL at15:13:22.25 after arrival15:11:55.25; its next booked
ERS call is unreached. TUVR-N3 is a signal wait, NOT a booked Turavur call.
The2702s consists of1228s opposing(M06520,M053696,M021512),1128s compatible
KUMM receiving,190s occupied blocks,122s route conflicts and34s crossing
protection forM065. Preserve combined receiving/conflict buckets without
attributing them individually to the listed claimants.

Actual KUMM claims areM015P3 and incomingV003P1/P2/P3 alternatives, not three
simultaneous reservations. Actual TUVR claims areM024P2/M026P3 and approaching
M021P1. M026 awaitsM021 inKUMM_single; M024 awaits that crossing; M015 atKUMM
andM068 atSRTL await compatible TUVR space held byM024/M026. M021 moves south
at24.6m/s towardTUVR. V003/M025/M053/M065 move; M022 has just arrivedERS and
exchanges passengers. M048 has continued beyond the northern boundary, portal
arrival15:51:37.25. S033 waits forV003's block; L003/S017 await departures.
Both inspections report no future plans and byte-identical before/after state.
No permanent-deadlock or runtime-defect inference.

In the south,M097 waitsNEM forNYY receiving reported againstL004/V007; V007
atNYY waits forPASA roads reported againstM101/S054. M101 waitsPASA forS054's
conflicting route whileS054 moves north. M052/KZT andM066/ERL dwell; M102
has begun its northbound departure. S051 completes passenger exchange; S049,
S053 andM081 await departure. M051 runs empty stock towardNCJ depot after
passenger arrival16:03:15.90. M082 is inTVC depot after arrival15:13:39.30.
S031 has continued beyondNCJ, portal15:00:22.30; K1/L025 are stored atNCJ after
arrivals12:46:12.65/13:14:56.65. These local observations are not whole-day
improvement, capacity or recovery proof. The baseline summary has no K1
overtakes. No complete-population comparison or recovery certificate.

Delayed failure evidence7f49205e remains unchanged. Both original jobs ended;
only read-only diagnostics ran and are now finished. No replay, Classic208,
full-suite or native check was launched. Runtime/routes/sounds/legacy choices
remain unchanged. Next: coordinate departure groups from both actual queues,
including compatible receiving roads and full-tail clearance, before one new
V2 baseline and one new delayed test. Network208V2 remains unaccepted and
uninstalled. No gameplay playtest until a passing V2 installation.
