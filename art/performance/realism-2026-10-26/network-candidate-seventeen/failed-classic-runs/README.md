# Candidate seventeen: both Classic runs rejected

The original baseline16000/12508 and delayed16736/12232 ended naturally at
07:04:42 with M063 exceeding the extra-wait limit at ALLP:28/208 complete,
2,702 seconds,zero safety events and empty stderr. Both end before the planned
07:30 intervention. There was no actual manual hold or recovery certificate.
All four original v17 jobs have now finished and failed. Nothing is installed.

Cumulative failed-prefix all-location fractions are96/127,116/127,118/127,
126/127; station-only65/87,82/87,83/87,86/87. Both populations fail98% under
30 minutes and100% under45. Earlier gates pass only within these failed prefixes.
The complete service records,both wait lists and traffic bytes match between
Classic baseline/delayed, before intervention; this is not whole-day or causal
equivalence. Traffic SHA256:
`25150a9b788886510f5aea0bf4de2d5efa04bb4c11363b7396c0e267d89a3177`.
The complete-population comparator was not used.

M063 arrives ALLP06:17:38.50 and has no departure. Its2,702s wait comprises
2,516s opposing L006 section occupation and186s awaiting L006 crossing.
L006 has2,436s recorded approach wait preserving MAKM crossing capacity for
M009/S029 and ALLP capacity for L013/M063. Actual ALLP claims are L013P1,
M063P3 and incoming L006P1/P2/P3. M012 waits MAKM-N3 behind the opposing
S029/M009 section; S029 waits before MAKM for ALLP receiving space. L005 waits
at SRTL. These are actual compatible-road and onward-escape constraints.

All eleven inspected trains are stopped at this instant; K1 is exchanging
passengers. Neither inspection steps the simulation and both are byte-immutable.
One future-clearance plan exists at NYY: incomingL021P1,opponentL022P2,
vacaterL033,escapePASA_P2. Received/opponent_received aretrue,escapedfalse.
A stopped snapshot does not establish permanent deadlock or a runtime defect.
Classic M045 clears PASA05:05:26.80 with2,642s extra wait, while V2 fails there;
this local difference does not certify the Classic day.

`provenance.json` verifies4,836 current-at-run sources per report, the exact
Classic pack and24 exact raw files. Audit, traffic, failure and inspection
archives are lossless gzip with zero mtime; original outputs remain in place.
Actual `summarize-timetable-run.mjs` outputs and scoped comparisons are included.
The archiver's initial no-future-plan guard rejected the observed NYY plan before
creating any archive; it was corrected to assert the actual plan and flags.
Runtime9ec3530,routes,six observers and tests remain unchanged. No full suite
was rerun for data/evidence-only work; prior1,003 source tests and four authoring
guards remain recorded. Never relaunch these unchanged failures or relabel hashes.
