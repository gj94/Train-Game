> Preparation status: all four days have been regenerated, independently
> certified and checked in the actual menus on the corrected forecast source.
> Both Intensive manual-delay audits also pass. Historical pre-fix results are
> retained separately. R47 packages these prepared days with the optional V2 dispatcher.

# Predictive dispatcher V2

V2 is an optional overtake planner for the Kerala Coast railway. Classic remains
available. The home operating-day selector provides Standard 100 and Intensive
140 choices for each dispatcher. The corresponding prepared departures, time
states and traffic previews must pass their own full-day replay before use.
All four variants are now prepared and checked in source. The revised V2
Intensive baseline gives K1 eleven distinct overtakers across seven stations.
R47 includes both engines. Start a new R47 journey: Kollam's layout change can
make R46 saves incompatible. Save files and preferences are retained.

## Choosing a dispatcher

For a new journey, select the named Classic or Predictive V2 operating day on
Home, then choose a service or Explore by time. Stops and Traffic describe that
exact day's prepared railway. An unfinished or incompatible day cannot substitute
another day's snapshots.

For an existing journey, open **Journey tools → Dispatcher** to switch between
Classic and Predictive V2. This changes the planner for your current railway;
it does not replace departure times, reset delays, move trains or cancel already
committed routes. A Classic Intensive journey switched to V2 keeps its Classic
service timings. To use the separately staggered V2 Intensive departures, begin
a new journey from that operating day. Save/Continue retains
your chosen mode and actual railway progress.

Use **Dispatch → inspect your train → Forecast details** to see a current plan.
The plan can change as you drive. The home Traffic preview remains a record of
the selected AI baseline, so it is not updated to promise your altered journey's
future encounters.

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

Expand **Forecast details** in either participant's inspector to see the same
current proposal, both arrival/clearance times and the margin remaining after
allowances. **Locate [station] on map** focuses the proposed passing location.
**Inspect [service] · keep your train** selects the counterpart in the inspector
without changing the service you control. Use LB/RB to reach the inspector and
the right stick to scroll its details; X still locates your assigned train.
Expired advice removes its old actions and explains that routing has fallen back
to Classic while V2 reassesses. A following-order proposal does not allocate a
passing loop. The panel is hidden in Classic mode.

## Scope and validation

This is a bounded rolling forecast, not a globally optimal timetable solver or a
proof against every possible deadlock. It does not invent platform crossovers,
assume an operator-held train will leave, or know a manual driver's future input.
Other route conflicts can still make actual ETAs later than free-running ones.

An empty main road does not by itself make it available: an approach can already
be committed, a crossing can require an escape road, or the road can lack room
for the complete train. A passenger already stopped on the main cannot be moved
sideways to a loop; the planner chooses a better road before arrival when there
is a feasible opportunity. Signals and the current hold reason remain the source
of movement authority, even when a forecast proposes onward running.

Kollam's interim reconstructed layout has three passenger roads per direction:
southbound P1/P3/P5 and northbound P2/P4/P6, each with 630 m usable berth length.
Game road IDs are not official platform numbers. Universal access from both
running lines has not been modelled. Its layout change requires new compatible
Classic and V2 prepared states; old signatures are never relabelled as valid.

Evidence and completed whole-day gates are in
[the work record](dispatcher-v2-work-2026-10-24.md) and
[the validation artifacts](../art/performance/dispatcher-v2-2026-10-24/README.md).
Rehearsals check every service's completion, all calls, depot clearance, safety
events and individual wait distributions. Intensive additionally requires at
least ten distinct K1 overtakers and reports their station distribution. Authored
departure changes may spread encounters; no station is a forced passing site and
K1's booked dwell is not padded to manufacture them.

The checked Standard comparison improves the share of extra waits below ten
minutes from 77.27% to 85.08%, but does not improve every service. Northbound
VB B012 finishes 11m31s later after changed crossing interactions. See
[the complete Standard comparison](../art/performance/dispatcher-v2-2026-10-24/corrected-standard-days/README.md)
for call-level results and limitations. Predictive planning is not a promise of
globally optimal dispatch or a hard maximum wait for an individual player.

The revised Intensive comparison meets every wait target, with 86.86% of extra
waits below ten minutes and all below thirty in V2. K1 reaches Nagercoil 9m22s
late versus Classic's 46m52s. These results include fifteen authored departure
changes and are not a planner-only comparison: priority 75 and 85 mean destination
lateness increases, while the two Vande Bharats' mean improves. The complete
[Intensive comparison and regressions](../art/performance/dispatcher-v2-2026-10-24/corrected-intensive-days/README.md)
retains actual intermediate calls and hold reasons, including B003 and B020.
