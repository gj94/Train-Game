# Predictive dispatcher V2

V2 is an optional overtake planner for the Kerala Coast railway. Classic remains
available. The home operating-day selector provides Standard 100 and Intensive
140 choices for each dispatcher. The corresponding prepared departures, time
states and traffic previews must pass their own full-day replay before use.
Preparation is still in progress; the published R46 download remains Classic.

## What the planner compares

For a lower-priority train and each higher-priority follower, V2 examines up to
four upcoming passing stations within 30 km. It estimates arrival using the
actual formation, current speed, traction, braking, line limits, restrictions
still beneath the train's tail, intermediate calls and departure dwell. A
forecast ends at the service's final booked call. A stopped manual driver has
no assumed future departure time.

Each candidate compares two orders at a common downstream timing point:

1. Let the faster service follow the slower service.
2. Receive the slower service into a suitable loop and let the faster one pass.

The useful gain is the faster train's **lateness saved**, rather than simply
its running-time saving. Booked slack can make following acceptable. That gain
is weighted by the trains' priorities and compared with the slower train's
additional detention. A booked stop can absorb some or all of the pass; an
unbooked stop incurs an additional penalty. Future through movements prefer
the directional main. An already berthed train keeps its actual road.

For example, with priorities 75 and 20, saving six minutes of express lateness
has weight `(10 + 75) / (10 + 20)`, or about 2.83. Six minutes of added passenger
detention then leaves a positive weighted gain. If both orders keep the express
on time, priority alone supplies no punctuality gain and does not justify a new
V2 hold. This is a game policy calculation, not an Indian Railways rule.

To continue to a later loop, the passenger must fit and clear before the
follower, including a 45-second margin and forecast uncertainty. Uncertainty is
at least 15 seconds, grows with projected running time and is larger for manual
driving. Nearby higher-priority followers are all considered. A follower that
cannot be forecast prevents certification of onward progress.

## Live operation and safe fallback

Every five simulation seconds, the simulation owner captures detached train and
route data. Up to four worker tasks calculate proposals using immutable track
topology. The live dispatcher polls completion without waiting for an unfinished
task. Rendering and workers never edit the railway together. Offline timetable
preparation and time skip join the same parallel calculation in a fixed order
so that replay remains repeatable.

The owner rechecks returned advice against train identity, control mode,
priority, progress, calls, speed caps, road occupancy, reservations and operator
actions. New or newly eligible followers invalidate an older certificate.
Advice expires after 15 simulation seconds. Overlapping proposals cannot both
claim the same roads over the same interval.

Only the existing interlocking grants routes and signals. V2 cannot cancel an
already committed express route to change its passing order. Missing, stale or
rejected forecasts fall back to Classic. Crossing protection, opposing movements,
receiving capacity and full-tail route release remain authoritative. A displayed
passing plan therefore does not guarantee an immediate green signal.

The dispatch inspector shows the planned station, receiving/through roads,
projected following/passing lateness and added lower-priority detention. Journey
settings can switch dispatch mode without cancelling committed routes. Saves and
time skips retain the mode and validated advice; worker task handles are never
saved. Home traffic lists are observed AI-baseline encounters, not live promises.

## Scope and validation

This is a bounded rolling forecast, not a globally optimal timetable solver or a
proof against every possible deadlock. It does not invent platform crossovers,
assume an operator-held train will leave, or know a manual driver's future input.
Other route conflicts can still make actual ETAs later than free-running ones.

Kollam's interim reconstructed layout has three passenger roads per direction:
southbound P1/P3/P5 and northbound P2/P4/P6, each with 630 m usable berth length.
Game road IDs are not official platform numbers. Universal access from both
running lines has not been modelled. Its layout change requires new compatible
Classic and V2 prepared states; old signatures are never relabelled as valid.

Evidence and pending whole-day gates are in
[the work record](dispatcher-v2-work-2026-10-24.md) and
[the validation artifacts](../art/performance/dispatcher-v2-2026-10-24/README.md).
Rehearsals check every service's completion, all calls, depot clearance, safety
events and individual wait distributions. Intensive additionally requires at
least ten distinct K1 overtakers and reports their station distribution. Authored
departure changes may spread encounters; no station is a forced passing site and
K1's booked dwell is not padded to manufacture them.
