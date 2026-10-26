# Candidate20: original V2 baseline failure

The original baseline 20044/380 finished naturally at **11:52:24**, with
**65/208 services complete**, failing K1 at NEM after **2,702 seconds** of
extra station wait. Maximum all-location and station-only waits are both
2,702 seconds. Zero safety events, empty run/inspection stderr, no manual hold.
Both original candidate20 runs have now finished and failed. Neither is
accepted or installed; there is no full-day or recovery certificate.

Source candidate `7d7f91ea`, launch proof `56a0a590`. The separate delayed
failure is preserved in `../failed-predictive-delayed` (commit `89ddee21`).
The earlier statement there that the baseline was live is historical.

## Wait gates in this failed prefix

| Population | Under 10 min | Under 20 min | Under 30 min | Under 45 min |
|---|---:|---:|---:|---:|
| All locations | 198/272 pass | 246/272 pass | 264/272 fail | 271/272 fail |
| Station only | 101/151 fail | 134/151 fail | 148/151 pass | 150/151 fail |

Passing fractions apply only to this failed prefix. Every call, departure and
full-tail completion has not been established for all 208 services. No
complete-population comparison was performed. The delayed result differs;
this is not a claim of baseline/delayed equivalence or causal improvement.

## Actual queue

K1 reaches NEM at 11:06:17.70 and has no departure by failure. The failed wait
comprises 1,990 seconds of opposing section occupation by M084/L024/M048/
M068/S050, 630 seconds protecting NYY receiving or onward crossing capacity,
22 seconds awaiting M084 crossing, and 60 seconds of route conflicts.

Read-only inspection restores the actual failure snapshot without stepping;
before/after captures are byte-identical and there are no future clearance
plans. NYY claims L036 on P2 and incoming M096 on P1. L036 is held for M096's
overtake; K1 waits at NEM-S2 because NYY has no free suitable receiving road.
M096, M068, S050, L024, S034 and L008 are moving. M048 exchanges passengers,
M084 is already in depot storage, and S047 has continued beyond the map.
This snapshot alone proves neither permanent deadlock nor a runtime defect.

## Preserved evidence

`provenance.json` identifies 13 exact raw files and SHA-256 hashes: losslessly
compressed audit, traffic, failure snapshot and immutable inspection; original
logs; actual summarizer output; exact source V2 pack; inspection tool and
job identities/options. All 4,836 report source hashes were verified against
current-at-run sources. Original output files remain intact. Historical
source hashes must not be relabelled after future departure edits.

Next coordinate departure groups using both actual queues. Preserve K1 at
06:00, every non-departure field, common-author consistency, compatible
receiving roads, full-tail clearance and every acceptance gate. Classic
Network208 remains outside the user's requested readiness scope.
