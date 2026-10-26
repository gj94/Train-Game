# Candidate thirteen: order L002 between the earlier northbound entries

Only **L002's departure changes, from 05:05 to 04:20**. This places it after
M064's 04:10 entry and before L034's 04:30 local, instead of sharing 05:05 with
S030. The aim is to avoid the observed origin/overtaking conflict and reach the
southern single-line sections before the later opposing wave. This is an
unaccepted timetable hypothesis, not a capacity or traffic-performance proof.

All four previous candidate-twelve runs failed before their planned 07:30 hold.
Classic failed L002 at NYY 07:21:20; V2 failed S025 at PASA 06:38:42. Their
baseline/delayed records match only within those failed prefixes. Exact raw
evidence remains in the adjacent candidate-twelve folders.

Restoring L002's old departure recovers both whole predecessor packs exactly.
Both modes have identical services; no other field changes. There are still
208 services, 168 boundary journeys, 70 overnight origins and 3–12 departures
per hour: 40 locals,104 mails,56 superfast,8 VB. K1 stays06:00; M00605:20,
L03506:45,L01508:15,L02407:40 remain. Calls, dwell, stock, priorities, speeds,
tracks and interlocking are unchanged. No passes are forced.

Normal authoring through205 overrides reproduces both packs. All four headless
authoring checks pass with empty stderr. Runtime and test sources remain those
of the completed1,003-test suite; that full suite was not repeated for this
single departure edit. Nine exact diagnostic files have recorded SHA-256 hashes.
Predecessor files remain locally in candidate-thirteen-before and match the
committed candidate-twelve packs.

New real baseline and 600-second K1 disturbance runs must pass every unchanged
service, call, departure, full-tail completion, safety and both wait-distribution
gates before installation. Actual category/menu/midnight/save-load validation
also remains required. Network data is unaccepted; R47 and legacy prepared data
remain available.


The tested candidate is committed as e81de25a. Four isolated v13 runs launched
once at15:28:43. Wrapper/child pairs: Classic12028/21668,V25080/14780,
Classic delayed1180/18720,V2 delayed18248/10524. Actual eight commands/options,
separate single output arguments, baseline modes,4,837 distinct current source
hashes and six observer hashes are verified. An initial verifier attempt occurred
before catalogue creation; its retry passed without restarting jobs. Five exact
launch files are archived with hashes. Inputs stay frozen throughout the replays.
