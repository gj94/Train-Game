# Candidate 22 — original V2 baseline rejected

Original wrapper2360/child13668 completed naturally without manual intervention.
At **12:42:04**, L025 failed the 45-minute extra-wait gate at **Neyyattinkara**:
69/208 complete,2702 seconds maximum in both wait populations,zero safety
and empty run/inspection errors. Both original v22 runs are now rejected.
Never rerun this unchanged candidate or install its partial/disturbed outputs.

| Population | Under 10 min (70%) | Under 20 min (90%) | Under 30 min (98%) | Under 45 min (100%) |
| --- | --- | --- | --- | --- |
| All locations | 197/272 pass | 245/272 pass | 263/272 fail | 271/272 fail |
| Station only | 110/163 fail | 144/163 fail | 159/163 fail | 162/163 fail |

159/163 is below98%; never round it up. All fractions apply only to this failed
prefix, not a completed population. No whole-day comparison or recovery proof.

L025 arrived NYY11:55:48.15 with no departure. Its2702s extra wait comprises
1708s opposing M096/S050/M086 (566/568/574),954s receiving-road protection at
PASA (including K1),and40s conflicts. Booked dwell remains separate.

The read-only snapshot inspection left captured bytes identical. NYY claims
M086P1 and L025P2. L025 waits at NYY-S2 for a suitable PASA road, protecting
L036/K1. L036 has just arrived PASA12:42:03.80; L026 waits at KZT-N1 for K1
in PASA_single. M086 exchanges passengers at NYY. No future-clearance plans
exist in this baseline snapshot; do not transfer the delayed snapshot's plan.
K1,L008,L024,M068,M096 move. M048 waits for an automatic block; S010 atALLP
waits for opposingM019/M023; S050 is depot-stored and S034 awaits departure.
This does not establish permanent deadlock or a runtime defect.

K1 departed NEM11:20:44.25,NYY11:52:28.75,PASA12:41:23.25. Its local movement
beyond candidate21's NEM hold does not establish whole-day improvement.
The actual traffic summary records no K1 overtakes in this prefix. Baseline
and delayed results are distinct failed populations despite nearby clocks.

Thirteen exact raw files are length/SHA-256 listed in provenance.json,including
lossless audit,traffic,failure snapshot,immutable inspection,actual summaries,
exact source pack and job manifest. All4836 report source fingerprints matched
current-at-run files (CRLF-normalized text,raw binaries); pack hash matches
report and launch. Original outputs remain in rehearsals-v22. Runtime9ec3530,
tests,routes and six observers remain unchanged; the completed1003-test suite
and four authoring guards were not rerun for evidence-only documentation.
