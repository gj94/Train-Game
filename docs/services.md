# Service designer and driving cameras

Open **F5**, **Menu → Service designer / import / export**, or **D → Design
services**. The current run pauses while you edit a separate draft. The first
draft contains the current route's mixed passenger services; reopening an authored
run edits its original definitions.

## Create and play

1. Set the timetable name, world start time and day.
2. Select a service, or Add / Duplicate one. Give it a unique ID and name; choose
   detailed WAP-7 + LHB, WAP-7 + ICF, or Vande Bharat 8/16. Set departure time,
   day, direction, priority (1–100, higher first), and service speed cap.
3. Choose each stop's platform/block. The first row is the origin, with arrival
   offset **0**. Later arrival offsets are minutes after booked departure, and
   must include preceding dwell. The last row is the destination. Add, remove or
   reorder stops as needed. Origin dwell is ignored.
4. Leave the head marker blank for the automatic stopping point, normally six
   metres before the starter. An explicit marker is measured from the block's
   start, not from the train. It must fit the whole train and precede its signal.
5. **Validate** checks stock, times, layout, full-length markers, starting
   occupancy and forward connectivity. **Rehearse AI traffic** runs a separate
   simulation while the live game remains paused. It reports completion and the
   greatest final-arrival delay, safety events, or services still held two hours
   after the last planned arrival. Click again to cancel. Editing invalidates
   the rehearsal result.
6. Select the service you want, click **Play selected service…**, then **Start
   driving**. This replaces the run at the timetable's world start. Your train
   begins with the service brake applied; the other trains use AI. Automatic
   dispatch requests routes for everyone through the existing interlocking.

During play, **D → service roster** switches to another working; take its cab
with **Tab** when viewing from outside. In a driving view, selecting a service
hands the old service to AI and takes manual control of the new one. **A** lets
AI drive your selected service. **Restart** retains the authored timetable and
the service chosen at launch. F9's built-in traffic/solo choices leave the
authored scenario. F1 describes the selected working and booked stops.

## Import, export and limits

Import/Export use the Windows file picker and a portable UTF-8 **JSON** file.
Copy it to the other PC and import it there. Imports are checked before replacing
the draft; rejected files leave both draft and live run intact. Exports require
a valid draft. Edits autosave the last **valid** draft to
**%APPDATA%\Godot\app_userdata\Train Game\services-draft.json**. Invalid edits stay
in the editor for the current session; correct them to save. Back keeps the
current draft and returns to pause.

Files describe services for the current layout. They are not running savegames
or track-layout files. A geometry/signalling signature rejects files for a
different or changed railway; scenery changes do not affect compatibility.

- 1–12 simultaneously placed services, 2–64 stops per service.
- All trains occupy their origins at world start, even if booked later. Two
  origins cannot share a block. A duplicate needs its own free origin.
  Off-map spawning and rolling-stock reuse are not implemented.
- Each working travels forward. Automatic reversals and run-rounds are not
  supported; choose the appropriate direction and platform sequence.
- A train remains at its terminal. Two services terminating in the same block
  can prevent completion; the rehearsal identifies this.
- Departures fall within 24 hours of world start; final booked arrivals within
  48 hours. Use the next day for a departure after midnight.
- A passed AI rehearsal is evidence for AI operation; manual driving can change
  the outcome. An unrehearsed timetable can be played, with that status shown in
  the start confirmation.

JSON envelope: format "train-game-services", version 1, layout,
layout_signature, name, world_start, day and a services array. Each service has
id, name, stock, departure, day and stops. Optional `priority` defaults to 50;
`speed_limit_kmh` defaults to the stock maximum and cannot exceed it. Stock
identifiers are `lhb`, `icf`, `vb8`, `vb16`. On Kerala Coast, the dispatcher uses
actual running and priority to select passing roads and arrange overtakes;
imported files do not contain scripted crossing/overtaking gates. Stop fields follow
[timetables.md](timetables.md). Export gives a complete editable example with
the current layout signature. Maximum import size: 256 KiB.

## Pilot and head-out views

- **4**: pilot seat, including return from machinery/passenger/exterior views.
- **Q / E**: left / right head-out. Press the same side again to return to pilot.
- **Xbox D-pad left / right**, in pilot/head-out: same side toggles. **D-pad up**
  returns to pilot. In other views the passenger shortcuts remain.
- **Tab / Y** switches onboard/exterior; **V / View** passenger/cab.
- Right-drag / right stick looks around. Releasing the mouse retains the chosen
  direction. Middle-click / right-stick click recentres.

The head-out eye clears the body at the active cab window, follows rendered
train motion, and uses the outside listening position. Both sides work in both
directions and at reversible stock's other cab. Pilot/head-out shortcuts preserve
AI/manual state and the handle. Tab's take-cab action still takes manual control,
now without resetting the power/brake handle.

## Verification

The headless suite covers validation, JSON round-trip, midnight, arbitrary IDs,
isolation, safe six-service completion and blocked terminals. The focused source
checks are tools/check_services_playable.gd (native UI and real scene reload),
tools/check_driving_camera.gd (moving transitions and cab reversal), and
tools/check_controller_playable.gd (existing Xbox workflow).
