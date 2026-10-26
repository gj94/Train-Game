# Candidate 24 V2 baseline: rejected

27 October 04:47:34: the original v24 baseline 11988/12204 finished naturally
and failed S032 at TUVR-N2 at 14:13:50: 78/208 complete, maximum all-location
wait 2702 seconds, station-only 2458 seconds, zero safety events, no manual
hold and empty run/summary/inspection errors. Both original candidate24 V2
runs are now finished and rejected. Seventeen exact raw files, 4836 verified
current-at-run source fingerprints, the actual summary and two byte-immutable
inspections are preserved in `network-candidate-twenty-four/failed-predictive-baseline`.
Original outputs remain; never rerun unchanged or install either failed run.

All-location cumulative counts 228/320,288/320,310/320,319/320 fail the 30/45
minute gates (288/320 is exactly 90%). Station counts 115/177,158/177,174/177,
177/177 fail 10/20. Every passing fraction applies only to this failed prefix.
S032 left ALLP at 13:02:10.75 after arrival 12:51:07.25; its next booked call
is ERS, so the failure is a signal wait, not a booked Turavur call. The failed
wait comprises 2686 seconds opposing traffic and 16 seconds route conflict
with M065. Opposing buckets include S007/S015/M049/M065/M053/M015; combined
reason buckets are preserved without attributing their seconds to individuals.

Actual KUMM claims are incoming M021 P1/P2/P3 alternatives. Actual TUVR claims
are S032 P2, approaching M053 P3 and incoming M015 P1/P2/P3 alternatives;
these alternatives are not simultaneous reservations. S032 awaits M015/M053
in KUMM_single; M018 at SRTL awaits M065; M050/S016 at MAKM await S007;
M028 at ALLP awaits S015/S007. S012 at AMPA protects M028's onward crossing.
M015/M053/M021/M065/M019/S007/S011/S013/S015 move, M049 exchanges passengers,
and K1/L025 are already in NCJ depot. Both inspections have no future plans
and byte-identical captures. No permanent-deadlock or runtime-defect inference.
The baseline summary records no K1 overtake. Local movements do not establish
whole-day improvement or recovery; no complete-population comparison is made.

All original v24 jobs have ended, permitting coordinated departure-only planning
from both actual queues. Source hashes are current for24 and become historical
once a later candidate changes source. Runtime9ec3530, sound/gangways/portals,
legacy certifications and pending UI/category files remain unchanged. No
Classic208 job, installation or unchanged full-suite rerun. Network208V2
remains unaccepted; 208 feasibility within all gates and completion ETA remain
unproven. Gameplay is unchanged; no new playtest is requested.

`provenance.json` lists the exact raw file hashes and original locations. JSON,
traffic and failure-state archives decompress losslessly. The exact candidate24
V2 pack, inspection tool, job manifest and both inspections are retained. The
summary finished flag means that a final audit exists; it does not mean all 208
services completed. This archive does not certify installation or recovery.
