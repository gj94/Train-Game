# Candidate25 V2 delayed failure — exact evidence

The original v25 V2 delayed run (wrapper22180/child19280) finished naturally
and failed S031 at PASA-S2 at15:15:12:89/208 complete,2702s maximum all-location
wait,2454s station-only,zero safety events and empty run/summary/inspection
errors after the configured600s K1 hold at07:30. Seventeen exact raw files,
4836 verified current-at-run source fingerprints, the actual summary and two
byte-immutable inspections are preserved in
`network-candidate-twenty-five/failed-predictive-delayed`. Original outputs remain;
never rerun unchanged or install this failed run. These source fingerprints are
current for candidate25 and become historical after a later source change.

All-location cumulative counts256/347,315/347,337/347,346/347 fail30/45-minute
gates. Station-only130/188,169/188,182/188,188/188 fail10/20/30;169/188 is below
90%, never round up. Every passing fraction applies only to this failed prefix.
S031 left TVC at13:37:40.75 after arrival13:34:20.90; its next booked call KZT
is unreached. PASA-S2 is a signal wait, not a booked Parassala call.

The failed wait comprises1312s compatible KZT receiving,1244s opposing traffic
(M082406,S03422,M066406,M102406,M0544),98s crossing protection for S034 and48s
route conflicts. Actual KZT claims are M054P1/L028P2; actual PASA claims are
S031P2 and incoming M054P1/P2 alternatives, not simultaneous reservations.
S031 awaits M054 in PASA_single. M054 has authority and is sounding departure
horns with brakes held; L028 awaits its conflicting route. M081NEM waits for
M066; S051NYY waits for M102. M082/S034/M066/M102/M022/M065/M053/M015 move.
M049MAKM awaits M022 crossing, M021 awaits booked departure and S048 is stored.
Both inspections have no future plans and byte-identical captures. No permanent
deadlock or runtime-defect inference follows from this failed wait.

S032/M018/M050/S016 have continued beyond the northern map boundary, with portal
arrival records14:04:43.75/14:19:39.75/14:25:05.30/14:34:29.60 respectively.
K1/L025 are in NCJ depot (passenger arrivals13:31:09.15/13:11:10.65).
These local observations are not whole-day improvement or recovery proof.
Eleven K1 minute samples show27.4545764399m braking movement by07:31 and unchanged
recorded extents through07:40; these are not exact controller frames or a
recovery certificate. The traffic prefix records one V001 overtake of K1 at
TVCN, not completed multiple-location proof. No complete-population comparison.

The original v25 baseline13108/11232 is still running; at06:09:05 it reaches
13:00 with70/208 complete, matching identities, empty errors and no final audit.
Freeze runtime/routes/packs/six observers until its outcome. Await that result
before coordinated departure-only replanning. Network208V2 remains unaccepted
and uninstalled. Runtime9ec3530, approved audio/gangways/portals, certified legacy
choices and pending UI/category files are preserved. No Classic208 job, unchanged
full-suite rerun or new gameplay playtest. Feasibility and completion ETA remain
unproven.

`provenance.json` records each raw source path, byte length and SHA-256. Gzip files
are lossless copies; the source audit and traffic retain their complete failed
populations. The original launch proof remains unchanged.
