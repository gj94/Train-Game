# Candidate twelve: three departure changes

This is an unaccepted timetable candidate, authored after all four v11 runs
failed. It preserves 208 identical services in Classic and V2, every call,
dwell, stock choice, priority, speed and route, and K1's 06:00 departure.

| Service | Before | After | Hypothesis from observed traffic |
| --- | --- | --- | --- |
| L002 | 05:45 | 05:05 | Reach the southern single-line sections before the opposing wave that delayed it at Eraniel and Neyyattinkara. |
| M006 | 05:50 | 05:20 | Increase its lead over S030 and reach Ambalappuzha before the observed K1/opposing queue. |
| L035 | 07:20 | 06:45 | Separate its southbound approach from M047/M061 around L024's Kulitturai arrival. |

L015 remains 08:15 and L024 remains 07:40. These are departure hypotheses, not
forced passing sites, guarantees of spare capacity or changes to live holds.
The preceding runs showed that improving one station queue can leave failures
elsewhere. The same complete-day safety, completion, waiting and overtaking
gates still decide acceptance; no new isolated-model score is claimed.

Restoring these three old departures recovers each entire predecessor pack
exactly as a JSON value. Archived predecessors match the committed pack bytes.
The author uses 205 overrides from original definitions and reproduces both
packs with --check. All four headless authoring tests pass with empty stderr.
The unchanged runtime/tests retain the earlier 1,003-test suite result; the
full suite was not repeated for these three data timings.

Counts remain 40 locals, 104 mails, 56 superfast and 8 VB, with 168 boundary
journeys, 70 overnight origins and 3–12 starts/hour. This remains an honestly
labeled representative adaptation, not a verified real-day railway timetable.
Nine exact raw diagnostic/authoring files are recorded in evidence-hashes.json.

Commit the tested candidate before launching a new isolated generation of
Classic/V2 baselines and the 600-second manual K1 disturbances at07:30 once.
Preserve frozen replay inputs until those jobs finish. Failed v11 data remains
historical and must not be installed or relabeled. Network is unavailable;
legacy certified choices, approved audio and R47 remain unchanged.
