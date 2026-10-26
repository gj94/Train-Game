# Candidate fifteen: earlier departures around observed opposing waves

| Service | Previous | New | Hypothesis from actual v14 queues |
| --- | --- | --- | --- |
| M064 | 04:10 | 03:40 | Give the northbound mail more time to clear MAKM/SRTL before S009/M017. |
| L002 | 04:20 | 03:50 | Follow M064 and reach ALLP before the S008/M017/M019 receiving wave and L015 origin supply. |
| M008 | 06:25 | 05:55 | Increase lead over S030/S006 and approach AMPA before opposing V001/M013/S009. |
| S047 | 10:35 | 10:00 | Enter the southern corridor before the observed M050/S032/M084/M048 northbound wave. |

All four v14 runs failed. Exact evidence is preserved in the adjacent candidate-fourteen folders: Classic baseline 0aa59a1f, V2 baseline 9cde0e52, Classic delayed 299e0dcf and V2 delayed cb02aaaa. These four changes are traffic hypotheses; later queues and complete-day performance remain unknown. No isolated-model score is claimed.

Restoring these four departures recovers each entire predecessor JSON object. Every other field is unchanged, both modes have identical services and K1 stays 06:00. L024 remains 09:20, L015 10:05, L035 06:45 and M006 05:20. There are 208 services (40 local, 104 mail, 56 superfast, 8 VB), 168 boundary journeys, 71 overnight origins and 3–13 starts/hour. This is a representative adaptation, not a verified real railway operating day.

Normal authoring through 205 overrides and exact --check reproduction pass. All four headless authoring tests pass with empty stderr. Runtime and tests remain unchanged from the completed 1,003-test source suite on candidate ten; the full suite was not rerun for four data timings. Ten exact diagnostic files and their SHA-256 hashes are preserved here. Exact predecessor files remain in candidate-fifteen-before.

Fresh Classic/V2 baselines and 600-second K1 disturbances must meet every unchanged service/call/departure/full-tail completion, safety and both wait-distribution gates. Actual overtakes, matched-section category comparisons, prepared menu/midnight/save-load and independent installation remain required. Network 208 is not accepted or installed. R47, legacy certifications, pending helpers and unrelated files are preserved.

Candidate `81875feb` is committed/pushed. Four v15 replays launched once at
17:57:11: Classic baseline 21452/12244, V2 baseline 7968/9656, Classic delayed
14684/21820 and V2 delayed 22140/3124 (wrapper/child). All eight actual commands
and options, distinct single output arguments, initial baseline modes, 4,837
distinct source fingerprints and six observer hashes are verified. Verification
waited for initial catalogues; no jobs restarted. Five exact launch files are
archived with hashes. At 17:57 both baselines reach 00:10 and disturbances 00:30,
with empty stderr and no final audits. These partial clocks do not certify traffic.
Inputs/observers are frozen while the original jobs run. Baselines save genuine
snapshots; delayed runs apply a 600-second K1 manual hold at 07:30 and cannot be
installed. No source suite, native test, authoring search or diagnostic remains.
