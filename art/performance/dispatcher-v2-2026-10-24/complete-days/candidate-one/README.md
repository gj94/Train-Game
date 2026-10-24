# First complete Intensive candidates: rejected for publication

Frozen source: `a8e6609`; exact original authored packs are preserved here.
Both complete-day replays ran all 140 services through every call and depot
clearance with zero safety events. Independent checks verify all 4,834 recorded
input hashes for each run. Their finalizers correctly reject publication for
different quality reasons; neither run was installed as prepared data.

| Gate | Classic Intensive | Predictive V2 Intensive |
| --- | ---: | ---: |
| All calls and depot completion | Pass | Pass |
| Safety events | 0 | 0 |
| All-location waits under 30 minutes | 98.42% | 100% |
| Station-only waits under 30 minutes | **97.58%: fails 98%** | 100% |
| Maximum continuous wait | 40m02s | 27m32s |
| Distinct K1 overtakers | 13 | **7: fails 10** |
| Passing stations | 8 | 6 |
| Maximum K1 passes at one station | 5 | 2 |

Classic's four station waits over 30 minutes are B054 at QLN (2402s), K1 at
KPY (1974s), B055 at QLN (1922s), and B026 at ALLP (1880s). Of 165 meaningful
station waits, 161 are below 30 minutes. Do not round that fraction up or relax
the acceptance gate. B054/B055 are held through consecutive relief expresses;
the full recorded reasons are retained in the summary and raw compressed audit.

V2 distributes the first candidate's passes more widely and meets all wait
targets, but D100/D114 began ahead of K1 and later reliefs did not catch K1 before
their own terminals. Its seven passes do not satisfy the requested busy day.
The full comparison is retained, including regressions: priority-75 destination
delay averages 415.07s in Classic versus 578.52s in V2. Authored departures differ,
so this comparison must not be attributed solely to the planner. K1 reaches NCJ
on time in V2 versus 54m56s late in Classic.

The read-only saved-advice calibration checks seven fresh forecasts for only
two distinct actual K1 arrivals: errors -9.39 to +6.05 seconds. Three sampled
proposals are excluded by the matching checks. Sparse same-road observations
are not a general accuracy or safety guarantee.

## Next authored candidate

Classic D105 moves from12:35 to12:55 to open a departure window for B055 after
D104 at Kollam. This alters one additional relief working; the original hundred
services, equipment, calls, booked dwell and the Classic dispatch engine remain
unchanged. The existing long waits still need an actual new replay, not a timing
assumption. No quality gate is changed.

V2 changes only D10011:20->11:30, D10913:00->12:45 and D11411:15->11:40. These
use actual first-candidate overlap to put D100/D114 behind K1 and give D109 time
to catch it before TVC. No passing station is forced, no K1 dwell is added, and
no stock/priority/speed change is made. The V2 D105 override stays14:15, so the
Classic correction has no additional effect on that V2 service.

Both revised Intensive days require new baseline and ten-minute manual-K1
braking replays. Standard variants remain compatible and are not regenerated.
All eight headless operating-day tests and four Python authoring guards pass;
JSON field comparisons prove the one/three permitted departure-and-name edits.
The unchanged runtime last passed all961 source tests. These small checks do
not certify either new full operating day. Keep the current R46 download live.
