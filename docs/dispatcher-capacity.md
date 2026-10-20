# Receiving and escape capacity

The dispatcher checks passenger faces and full-rake clearance before admitting
traffic into a single-line section. Through trains can use a road without a
platform; a booked passenger call cannot.

Admission also looks one controlled station beyond the receiving station. If
opposing trains hold all usable onward berths, the incoming service must leave
a compatible road on which at least one opponent can cross. Bipartite matching
accounts for each service's platform, length, direction and following call.

This includes physical occupants, reserved arrival roads and trains already
inside either approach section, even before their home route selects a platform.
The selected road is checked again at the home signal. Same-direction traffic
can leave away from the incoming train and does not establish this circular
wait. Existing exclusive future-clearance transactions retain their checked
escape reservation. Ordinary interlocking remains authoritative.

A future crossing cannot replace a platform route that is already committed,
including a home prepared beyond the next automatic signal. ALLP's depot access
remains part of the single-line approach after the home; that must not make an
already-routed train appear available for a second, contradictory platform promise.
Participants in an active three-train crossing follow its departure order rather
than accepting a separate advisory overtake. Reserved crossing roads are excluded
from unrelated overtaking opportunities.

A separate terminal rule keeps terminating trains on a road with access to the
outgoing running line for their empty-stock depot movement. This prevents a
northbound arrival at TVC from clearing to depot against a southbound arrival
on the same lead.

## Forward planning, 20 October 2026

An automatic train that is already overdue can still supply a future platform
vacancy. The three-train planner estimates when the opposing arrival will clear
its approach, combines that with the vacater's departure readiness and the time
needed to clear its tail, and admits an incoming train within the bounded
20-minute forecast. An incoming ETA more than five minutes beyond the estimated
vacancy is not promised. These estimates select plans; they never release a
signal, reservation or opposing departure on a timer.

Both meeting roads and a currently free escape berth remain protected. Manual,
emergency-held or operator-held vacaters, unusable platforms, conflicting plans
and unrelated traffic in either single-line section still disqualify a plan.
A later manual driving delay retains the receiving berth and holds the opponent
until the complete incoming train is inside. There is no optimistic chain of
future vacancies and no relaxation of physical interlocking.

The planner also checks other occupants of the meeting station. If an unrelated
train is already due to depart toward the vacater's exit, ordinary admission
handles that queue first. A new three-train plan must not monopolise that entire
exit against an existing ready departure. An occupant whose booked departure
is still in the future does not disqualify the plan.

Station entry preparation now follows consecutive clear automatic routes up to
the first controlled signal. It runs about three current-speed minutes ahead,
bounded to 2.5–6 km and allowing for braking distance. It includes the distance
between each signal and its edge exit. An occupied or red block, operator signal
hold, or intervening booked stop prevents preparation beyond it.

A prepared platform is attributed to its approaching train across the same
signal chain, so it cannot be counted twice or promised to another crossing.
The dispatch explanation reports the furthest continuous clearance; the desk's
immediate signal/route identifiers are retained. A green automatic followed by
a yellow home and a red platform starter still means permission to enter and
stop, not permission to depart before the booked call is complete.

The reported R36 B012 departure was replayed from the same saved railway, with
AI driving. Approximate results (old trace sampled at two seconds; new at 0.5):

| Observation | R36 | Forward planning |
|---|---:|---:|
| Stand at ERL-N2 | 4m14s | None |
| KZT home route prepared | 09:37:12, 1.55 km ahead | 09:30:05, 4.41 km ahead |
| VB stops at KZT | 09:39:48 | 09:34:36 |
| VB departs KZT | 09:41:47 | 09:38:54 |
| Opposing B088 departs KZT | 09:39:00 | 09:33:48 |

The booked KZT departure still applies; the earlier arrival does not remove
dwell or dispatch restrictions. A second replay pauses the selected driver for
ten minutes **after** the future platform is reserved. It still completes this
crossing without a circular wait, premature opposing release or safety event.
`tools/check_kzt_dispatch.gd` defaults to the committed, checksum-verified R36
fixture in `tests/fixtures/kzt-r36/` (excluded from game exports). Run with
`--require-forward`, optionally `--delay=600`, and `--output=<report.json>`.
`--starts=<catalogue-directory>` can select another saved departure explicitly.

Playtest with the NCJ 09:10 → ERS Vande Bharat: first let AI drive through ERL
and KZT, watching the planned-crossing advice and the green/yellow/red approach
sequence. Repeat with a manual delay near ERL. The opponent must wait for the
entire VB to enter its receiving road; the platform starter must retain the
booked departure/dwell restriction. Different manual timing can change the plan.

Fresh full-day validation completes all 100 services, 1,530 subsequent calls and
depot clearances with no safety events in three runs: baseline, K1 ten minutes
late at origin, and B012 paused for ten minutes from 09:23. The longest continuous
extra wait is 28m10s in each. Total baseline stationary waiting is 2.7% higher than
the preceding dispatcher, and the worst destination delay is 37m49s rather than
33m55s. These changes improve the reported approach without claiming that every
service arrives earlier. The complete operating-day comparison is in
[busy-timetable.md](busy-timetable.md).

These are bounded look-ahead checks, not a proof that every arbitrary timetable
or manual intervention is deadlock-free. Test new rosters across a full day,
including delayed driving, and retain the dispatcher's live blocker diagnostics.

Historical validation (10 October): ten exit-capacity regressions cover both arrival orders, typed
platform alternatives, nonstopping opponents, committed and unreserved approach
claims, the final home choice, a prepared home beyond an automatic signal without double-counting its owner,
and a moving three-full-rake crossing. Four
terminal tests cover directional depot clearance. Three future-clearance regressions
cover the ALLP home-route conflict and existing/new advisory overtakes during a
planned crossing. All 517 headless tests passed on 10 October 2026.
The final fresh baseline and ten-minute-late-start audits each complete all
100 services and 1,530 subsequent calls with zero safety events, then clear every
train to depot. The longest continuous delay beyond release is 28.17 minutes.
See `busy-timetable.md` and the R28 evidence for the tested scenario and limits.
