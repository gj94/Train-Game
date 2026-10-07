# Dispatch engine and control desk

8 October 2026. This replaces the fixed dispatch overlay.

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

Press **D** or click the left stick. The roster and map select an **inspected**
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
- `tools/check_kerala_traffic.gd`: complete autonomous seven-service rehearsal,
  requiring multiple crossings and overtakes of the slow passenger.

Playtest: open D near Kumbalam, zoom to individual coach lengths, inspect K3 and
View train. Verify YOUR SERVICE stays K1; return with 4. Reopen D, select K3,
choose Take control and cancel, then confirm separately. With a controller, pan
to a wide yard, zoom and navigate map targets; power/brake must stay unchanged.
Depart late as K1 and watch higher-priority traffic receive routes as gaps permit.

Estimates are predictions, not promises. Track occupancy and the interlocking
are authoritative. Infrastructure and simultaneous terminal occupations can
make a service pack impossible without changing its schedule or layout.
