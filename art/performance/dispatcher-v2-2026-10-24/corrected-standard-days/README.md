# Corrected-source Standard 100 baselines

Both original v6 Standard replays finished, were independently verified and are
installed for Classic and Predictive V2. They were launched once at 05:33 on
25 October 2026 using corrected runtime commit `b28e2c1`. No authored Standard
departure changed. The old `standard-days` folder remains pre-fix evidence.

Each mode completes all 100 services, every call and depot clearance, with zero
safety events. Validation checks 4,833 current source fingerprints, 1,530 actual
arrivals and 1,530 departures, 100 prepared departures, 233 exact five-minute
states, complete two-second traffic coverage and reciprocal encounter previews.
Raw complete audits are preserved as lossless gzip with SHA-256 in
`independent-checks.json`. Finalizer logs and complete summaries are included.

| Result | Classic | Predictive V2 |
| --- | ---: | ---: |
| Meaningful extra waits | 176 | 181 |
| Under 10 / 20 / 30 / 45 minutes | 77.27 / 96.02 / 100 / 100% | 85.08 / 97.24 / 100 / 100% |
| Station-call waits | 117 | 117 |
| Station waits under 10 / 20 / 30 / 45 minutes | 73.50 / 95.73 / 100 / 100% | 82.05 / 97.44 / 100 / 100% |
| Maximum continuous wait | 28m16s | 29m34s |
| K1 destination lateness | 5m46s | 7m04s |
| Distinct K1 overtakers / stations | 3 / 3 | 3 / 3 |

All all-location and station-only wait gates pass. The ten-overtaker requirement
applies to Intensive. K1's actual V2 passes are B001 at MAKM, B024 at STKT and
B002 at NYY; Classic instead passes B024 at KPY. `comparison.json` retains the
full destination and intermediate-call comparisons. Priority 85 mean lateness
improves from 653.21 to 372.50s, but priority 100 worsens from 393.10 to 688.85s.
B012 finishes 691.15s later, B031 1292.05s later and B020 1197.60s later. These
regressions remain visible; V2 is optional and not globally optimal.

## Native menu and time-browser checks

36 checks pass against the actual installed Classic/V2 Standard catalogues:
mode labels, calls, reciprocal traffic, complete departure restoration and the
real asynchronous noon timeline loader. All four 1280x720 screens were reviewed.
Classic K1 is approaching Paravur at approximately 81 km/h at noon; V2 K1 is
standing at Paravur. Both show 55 booked stops and 22 traffic events. This used
the Compatibility renderer and Dummy audio: one expected screen-space AA
availability warning is retained in `native-check.err`; there are no failed
checks. It is not an audio or target-PC performance test.

## Broader saved-ETA diagnostic

The corrected all-service diagnostic verifies all 233 saved states and 4,833
source hashes without stepping or changing the railway. Nineteen matching-road
forecasts cover eight distinct arrivals for seven trains, in both directions;
all samples are ICF stock. Actual minus predicted arrival ranges from -10.85 to
+403.69s; median -4.48s, p90 +4.69s. One sample exceeds its own arrival uncertainty.
Seven K1 samples cover only two arrivals, -7.27 to +0.95s, matching the previous
sparse K1 result. Repeated forecasts are not independent journeys.

The outlier is B042's 10:14:55 MAKM/B002 proposal. At the 10:15 saved checkpoint,
4.95s after forecast creation, B042 is stopped at Turavur with its call already
acknowledged. It actually departs at 10:20:51, 356.25s after forecast creation.
The completed Turavur extra wait totals 788s: 482s opposing B039, 246s waiting
for B002 to overtake, 56s block occupation and 4s authority. The actual B002 pass
occurs at Turavur and the later saved MAKM proposal is absent. This records an
external hold and replaced passing plan; it is not an isolated decomposition of
the 403.69s error. The exact creation frame is absent and has not been invented.
`B042-outlier-evidence.json` preserves the sample, calls, holds, history and four
hash-checked saved snapshots' selected data. The inspection source is retained.

This diagnostic is sparse calibration, not a global accuracy certificate. The
specific corrected K1/KPY dwell boundary belongs to Intensive and must still be
inspected after that new baseline finishes. The unchanged source has 964 passing
full tests. No runtime or preparation observer was edited during these replays.

Playtest from source: select each Standard mode, choose K1, inspect all Stops
and measured Traffic, then Explore by time at 12:00. Confirm the mode label and
actual restored position before joining. Both Intensive baselines are still
running at this checkpoint. R46 remains available; no executable release.
