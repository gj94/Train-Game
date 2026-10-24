# Corrected-source Intensive disturbance validation

These are fresh v6 replays of the candidate-two authored packs, launched at
05:33 on 25 October 2026 from source commit `b28e2c1`. They include the imminent
call/dwell correction and replace the previous source's disturbance validation.
The earlier `candidate-two` evidence remains historical and unchanged.

Both Classic and Predictive V2 complete all 140 services after manually braking
K1 for 600 seconds at simulation time 11000 (11:03:20), then returning it to AI.
Each run has zero safety events and all services clear to depot. Independent
verification checks all 1,726 arrivals and 1,726 departures, chronological travel
and dwell, every wait-reason total, 4,834 current source fingerprints and the
separate raw authored-pack hash. The 34,801 two-second traffic samples cover
08:00 through the following 03:20 without a missing sample.

| Result | Classic | Predictive V2 |
| --- | ---: | ---: |
| Meaningful extra waits | 249 | 293 |
| Under 10 / 20 / 30 / 45 minutes | 79.52 / 97.59 / 99.60 / 100% | 86.69 / 98.29 / 100 / 100% |
| Station-call waits | 165 | 179 |
| Station waits under 10 / 20 / 30 / 45 minutes | 73.94 / 96.97 / 99.39 / 100% | 82.12 / 97.77 / 100 / 100% |
| Maximum continuous wait | 31m22s | 27m32s |
| K1 destination lateness | 28m39s | 28m14s |
| K1 distinct overtakers / stations | 11 / 9 | 11 / 9 |
| Most K1 passes at one station | 2 | 3 |

Every all-location and station-only 70/90/98/100% cumulative wait gate passes.
Booked dwell and the injected pause are excluded from extra waits. Exact counts
and fractions are in the independently verified summaries; percentages above
are presentation only. Disturbed overtaker counts are descriptive and may differ
from the separate baseline requirement.

`delayed-comparison.json` retains destination and intermediate-call punctuality,
including regressions. Priority 75 mean lateness rises from 394.78 to 555.16s;
priority 85 rises from 818.80 to 822.18s. Unchanged-departure B056 finishes
1391.85s later and B020 1197.60s later. Fifteen relief departures differ between
the packs, so this compares the planner and authored timetable together. It does
not establish global optimality, general disturbance resilience or target-PC FPS.

`previous-source-comparison.json` compares each fresh v6 run against its own v5
counterpart. All service records and the complete traffic-file hash are identical
for these two cases; the only changed input fingerprint is
`sim/dispatch_forecast.gd`. This is an observed result of new complete replays,
not hash relabelling or a proof of equivalence for all states. The corrected
saved-state ETA boundary still needs inspection once the new baselines finish.

The raw audits and authored packs are gzip-compressed without changing their
bytes; audit SHA-256 and traffic SHA-256 are recorded in each summary. The
provenance record identifies the launch, source, exact options and output folder.
`*-run-summary.json` comes from `summarize-timetable-run.mjs`; the independent
`*-delayed-summary.json` comes from `verify_disturbed_timetable.mjs`, which also
checks source identity, calls and wait accounting directly.

Verification commands from the repository root:

```powershell
node tools/verify_disturbed_timetable.mjs .local/dispatcher-v2-2026-10-24/rehearsals-v6/classic-delayed art/performance/dispatcher-v2-2026-10-24/complete-days/eta-corrected classic
node tools/verify_disturbed_timetable.mjs .local/dispatcher-v2-2026-10-24/rehearsals-v6/predictive-delayed art/performance/dispatcher-v2-2026-10-24/complete-days/eta-corrected predictive
```

**These runs are disturbance evidence only. Never install them as baseline
starts, five-minute states or traffic previews.** The four original v6 baseline
jobs are still running at this checkpoint. Runtime, route, pack and preparation
observer inputs remain frozen. The 964-test source suite already passed on this
unchanged source. R46 remains the published executable.
