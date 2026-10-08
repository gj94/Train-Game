# Dispatch engine and control desk

8 October 2026. This replaces the fixed dispatch overlay.

## R10: station register and long trains

The user-selected CSV now supplies all 56 station platform totals. Kumbalam has
one passenger platform (game road P3) and two through roads; the morning LHB
passes without a booked call. The future-clearance transaction also supports
zero currently free passenger faces, provided the opposing train has a distinct
usable road and the vacating train has a protected escape into a free berth.
Thus K2 can wait on P1, the VB vacates P3, K1 enters P3, and K2 clears north.
The occupied platform's entrance stays red. Earlier R7 timings below describe
the previous shorter rakes and two-platform fixture, not the current timetable.

Clearance checks include full-rake length between signals, turnout fouling
zones and passenger platform ends. The map labels platform/through/storage
roads and shows platform and track counts separately; the stop-road selector
offers passenger platforms only. See [the CSV reconciliation](kerala-station-audit.md).

## R7: future platform clearances and deleting a service

The dispatcher automatically looks for a bounded three-train crossing sequence
when two approaches compete for one usable free berth and a same-direction train
is booked to vacate another within 20 minutes. It exclusively reserves the two
meeting berths, the vacater's escape section and a compatible berth that is free
at the next passing station. It rejects unrelated traffic already in either
approach, conflicting reservations, held/manual vacaters, incompatible roads and
operator platform preferences. It does not chain promises of future vacancies.

Kumbalam example: K1 approaches the north home, K2 enters P2, the VB leaves P3,
K1 enters P3, then K2 can leave north after K1's whole train is inside. Forecasts
never clear an occupied road: normal route, point, direction and tail locks are
checked on every movement. Late trains retain their promised receiving space.
Other cases use conservative receiving-capacity checks. This handles the tested
sequence; it is not a proof of globally optimal dispatch for arbitrary schedules.

In the verified opening, K1 reaches Kumbalam at 08:21:02 instead of 08:30:42 and
Turavur at 08:40:44 instead of 08:50:24. VB departure remains 08:18:00. K2 reaches
ERS at 08:27:13 instead of 08:21:51. K1 gains 9m40s while K2 costs 5m22s; VB is
unchanged. Four disruption rehearsals (K1 +10/+20 min, K2 +15 min, VB +12 min
beyond its booked departure) also completed with no safety event or circular wait.

To remove a blocking service, inspect it and choose **Delete service…**.
The confirmation names the train and defaults to **Keep service**; keyboard and
controller use the same focusable modal. Confirming removes it for this run,
releases only its authority, cancels its crossing commitments, and reassesses
traffic. Its model/audio are freed; if you were viewing it, the view returns to
your assigned train. Your assigned service is protected: hand over first if you
want to delete it. Restart restores the scenario; this does not edit a saved pack.

The world owns the dispatch engine. It runs on simulation time, independently
of the desk or camera, and requests routes through the existing interlocking.
Planning, prediction and resource diagnostics live in `sim/`. UI input can
request actions but cannot change occupancy, unlock points or bypass signals.

Available controls and behavior:

- Dynamic route alternatives, next-call reachability, receiving capacity on
  single line, priority with waiting age, actual-position forecasts and a
  bounded decision log. Distinguish planned waits from physical obstructions.
- Detect circular dependencies, reconsider discretionary holds, and describe
  impossible occupied configurations. Never teleport or skip a service to
  manufacture recovery. Preserve approach and tail locks.
- A full-screen control desk with zoom/pan, station search, whole-route overview,
  detailed train footprints, route previews, signal and point states, service
  roster, timetable, alerts and action history.
- Selecting a service only inspects it. Viewing another service preserves the
  user's train and control state; taking control requires a distinct confirmation.
- Mouse, keyboard and Xbox operation, with visible focus, map navigation and
  contextual controls. No keyboard/controller input leaks into traction while
  using the desk.

## Using the desk

Press **D** or tap View/Back in the default Xbox layout. The roster and map select an **inspected**
train; YOUR SERVICE in the header remains your driving assignment. **View train**
moves the exterior camera and closes the desk. **4** returns to your pilot seat.
**Take control…** presents a confirmation; Keep current service / B cancels it.
Confirming gives your old traffic service to AI and transfers cab/audio ownership.

Wheel or +/− zoom around the pointed location. Drag pans both axes, including
wide terminal yards. Home / Fit shows the whole route; Locate and Follow centre
the inspected train. The station picker centres a yard; the overview strip jumps
along the route. Amber is the train's actual head-to-tail footprint, across block
and point boundaries. The muted red block highlight is the occupied section,
not the train's physical length. Mint is reserved authority. Zoom in for road
labels and coach divisions; hover a lamp for its full signal identifier.

Xbox: LS pans, LT/RT zoom, D-pad selects map targets, A inspects/activates,
LB/RB moves between desk areas, X locates, Y fits, RS scrolls the inspector.
View/Back opens the timetable, where RS also scrolls horizontally. B closes a
dropdown or cancels a confirmation before closing the desk. Menu opens Pause.

Service actions can hold the next uncommitted controlled route, change priority
or request a reachable next-call platform. Holds do not revoke a train's existing
authority. Platform changes cannot alter a committed station entry. Route control
uses the same interlocking and receiving-capacity check as automatic dispatch.
Put to red & hold prevents automatic re-clearing while preserving approach/tail
locks. Release signal hold resumes automatic requests.

`tools/check_opening_priority.gd` runs an isolated opening comparison using the
full 32-service world: first the published priorities, then K1/K2 swapped from
20/70 to 70/20 before any authority is issued. Both runs use identical AI driving;
the published timetable and build are unchanged. It records first signal
clearance, origin exits, actual station times, safety events and sampled circular
waits in `.local/opening-priority-results.json`. Each run continues until K1 and
K3 are beyond Turavur and K2 has arrived at ERS, with a two-hour timeout. This is
an opening experiment, not a replacement for the full timetable rehearsal.
Pass `-- --vacancy` to measure the baseline VB head/tail departure from Kumbalam
P3 and the ERS starter clearance, sampled every two simulation seconds.
In the baseline, the VB starts at 08:18:00, its head leaves P3 at 08:18:54,
and its rear clears at 08:19:16. K2 is already on ERS_TNU_M1 at that point;
the opposing single-line lock holds K1 until ERS-S1 clears at 08:20:56.

The 8 October comparison cleared the opening in both cases without safety
events or sampled circular waits. Baseline versus swapped: K1 leaves ERS at
08:20:55 / 08:00:00; reaches Turavur at 08:50:24 / 08:37:49; K2 arrives ERS at
08:21:51 / 08:57:03; K3 leaves Kumbalam at 08:18:00 / 08:48:52. Thus changing
priority alone gives the passenger an earlier start but delays both expresses.
The separate proposed alternative is a planned Kumbalam meet: keep K2 on P2,
receive K1 into P3 after the VB vacates it, then release K2 north. That requires
planning a future berth vacancy and preserving the VB's escape route; it has
not been implemented or validated by this priority-only experiment.

The Attention tab shows missed calls, long blocked waits and circular dependency
groups. Select an item to inspect its service. The bounded Decision log records
changes and operator actions without adding identical messages every tick.

## Simulation boundary

`RailWorld.dispatcher()` owns one `DispatchEngine` through a weak back-reference.
It assesses traffic every 0.5 simulation seconds whether the desk is open or not.
`DispatchPlanner` evaluates route alternatives and downstream receiving capacity;
`DispatchPrediction` estimates running time including acceleration/dwell;
`DispatchResources` supplies occupancy/reservation dependencies. The interlocking
in `RailWorld` remains the only way to grant a route. The old `DispatchPlan.update`
entry point is a compatibility wrapper; live play and service rehearsals use the
world clock directly.

Receiving capacity is service-specific: passenger calls require a platform face,
the whole formation must fit, terminal roads must match, and the road must reach
the following booked call. Both approaches to a station participate in one
berth assignment. A through main without a platform cannot count as spare
capacity for a stopping passenger. The planner checks this before allowing entry
to a single-line approach, rather than waiting for a circular dependency inside
the throat. Occupied and already committed roads are excluded, and incoming
claims are matched to compatible roads rather than compared as simple counts.
Crossing/overtake predictions share that eligibility rule; a crossing hold is
withdrawn if the opposing service no longer has a usable receiving platform.

Uncommitted requests use service priority plus waiting age. Long overtake holds
and circular advisory dependencies can be released for a fresh route assessment;
the interlocking still refuses conflicting movements. These measures reduce
avoidable deadlocks. They cannot solve every physically impossible timetable,
fully occupied destination or arbitrary manually imposed arrangement. A circular
dependency alert is a diagnostic, not proof that every alternative is impossible.

## Verification and playtest

- `tests/run_tests.gd`: interlocking, dispatch commands, receiving capacity,
  alternative platforms, aging, circular dependencies, predictions, footprints,
  imported service definitions and route infrastructure.
- `tools/check_dispatch_desk.gd`: native 1600×900/1280×720 layout, zoom anchor,
  real train lengths, map/roster inspection and confirmation cancellation.
- `tools/check_controller_playable.gd`: synthetic standard Xbox input through
  the real scene, including traction isolation, dropdowns, handover and camera.
- `tools/check_dispatch_delays.gd`: autonomous Kerala traffic with 0/8/20-minute
  player departure delays; no safety events and progression beyond Kumbalam.
- `tools/check_manual_admission.gd`: manual K1 with an early approach and 10/20-minute
  late departures; actual Kumbalam geometry, opposing K2 and parked K3.
- `tools/check_kerala_traffic.gd`: complete autonomous 32-service rehearsal,
  requiring multiple crossings and overtakes of the slow passenger.

Playtest: open D near Kumbalam, zoom to individual coach lengths, inspect K3 and
View train. Verify YOUR SERVICE stays K1; return with 4. Reopen D, select K3,
choose Take control and cancel, then confirm separately. With a controller, pan
to a wide yard, zoom and navigate map targets; power/brake must stay unchanged.
Depart late as K1 and watch higher-priority traffic receive routes as gaps permit.

Estimates are predictions, not promises. Track occupancy and the interlocking
are authoritative. Infrastructure and simultaneous terminal occupations can
make a service pack impossible without changing its schedule or layout.
# R9 approach signal preparation

The dispatcher now prepares a controlled entrance while the train approaches
the final clear automatic block before it, within a bounded braking lookahead.
Previously it only worked from the next signal; the automatic approach stayed
yellow because the home was unset, then the home stayed briefly red until the
next dispatch cycle after passing the automatic.

In this game's three-aspect model, a prepared home with its platform starter
red shows yellow; the preceding automatic can then show green. A yellow home
for a stopping service is therefore expected. Busy platforms, conflicts and
holds can still legitimately leave the home red and its approach yellow.
Preparation cannot look through a red/occupied approach, skip a booked stop,
override operator holds or bypass the existing interlocking, admission and
future-clearance plan. No signal is cosmetically forced to green.

Eight regressions cover clear/occupied approaches, starter protection, holds,
manual assignment, read-only assessment and intermediate calls. The complete
32-service rehearsal finished safely in 1,430.6 seconds, including 19 crossings
and three overtakes of K1; largest arrival delay remained 40.2 minutes. This
is a completion/safety check, not a globally optimal timetable claim.

## R11 terminal clearance

The separate depot engine now reserves a finite berth and sends completed Kerala
services there as empty stock after unloading. Passenger results remain recorded;
normal interlocking and full-tail clearance protect every move. The desk reports
unloading/working/stabled states and the number in depot. See [depot workings](depot-workings.md).
The full rehearsal's success condition includes stabling, so platform parking can
no longer be hidden behind a passenger-arrival-only completion report.
