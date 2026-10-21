# Journey library and passenger departures

Follow-up QoL work after R44; not yet in the downloadable R44 build.

The departure browser combines train type, time of day, full-route and favourite
filters. Full route means Ernakulam Junction to Nagercoil Junction, in either
direction. Searching multiple words matches all of them across the service,
stock and calling stations. Reset clears the filters without changing timetable.

Use the star beside the service title, L3 or F2 to favourite a service.
Favourites are separate for Standard and Intensive: the same ID can describe
different workings. The browser remembers the chosen timetable and each day's
selected service. B returns from service details to the roster before Home.

Drive starts at the controls as before. Ride as passenger starts paused in the
first passenger carriage with space, with AI driving and a remembered seat. A full train opens in the aisle instead. Boarding does
not advance time or change surrounding traffic, routes or the selected train's
AI control state. The prepared departure is still the same baseline. Saves keep
the departure role so restarting a passenger journey remains a passenger start.

Playtest:

1. Favourite K1 in Standard, switch to Intensive and enable Favourites. It should
   not treat Intensive K1 as the same favourite. Add an Intensive service.
2. Combine Vande Bharat and Full route, then try a station/stock query. Reset
   should restore the full service list; reopening should retain your choices.
3. Select a service with A, move right to Ride as passenger, then B to the list.
   Confirming the Ride button should start paused in a passenger seat with AI.
4. Stand, visit the pilot seat, then hold R3 to return. Save/load and restart the
   ride; repeat with a WAP rake and a Vande Bharat.

## Preferences before travelling

Home → Settings & controls now includes controller deadzone, look sensitivity,
vertical inversion and vibration, plus the full independent sound mixer. These
use the same settings as the in-journey menus. Changing the clacks does not
change wind; mute retains your level, and choosing a listening preset explicitly
resets the mix. Reference mode warns that it bypasses gameplay layer controls.

A changes the focused row. B returns to its parent and keeps the relevant row
focused. LB/RB change sections in the controller guide. Settings report write
failures in the visible panel; they never claim a failed write was saved.

Playtest Home at 720p and 900p: change controller sensitivity and sound levels,
enter a service and check that they carry over. In the mixer, raise clacks,
mute/unmute, then use B twice to return through the category. Restore a preset
and verify its reset warning and the selected listening mode.

## Boarding from Explore by time

The time browser offers separate Pilot seat (AI), Passenger seat and station
platform actions. Passenger boarding starts paused in a remembered seat, even
when the selected service is moving in the baseline. It does not advance time
or recalculate traffic. X locates the selected service after panning away; Y
fits the entire route. Opposite triggers cancel map zoom, and releasing one
continues the other trigger's zoom direction.

At 20:00, select a moving service with A, move right to Passenger seat, then
confirm. Resume to ride; Hold R3 can recall the seat after exploring. Check that
the last time block offers station visits with both boarding buttons disabled.

## Saved journeys and recovery

Saved journeys have a dedicated view with search, viewpoint, AI/manual driving
mode, completed scheduled stops and the checkpoint's purpose. Older saves still
load; missing new metadata is simply omitted. Unreadable primary saves stay in
the list with loading disabled and directions to their previous backup.
Continue uses the most recent readable entry.

Returning Home, restarting, switching scenarios, quitting and loading another
save now wait for the required recovery write to verify. If it fails, you stay
in the current railway. Cancel is first; retry or explicitly leave/load without
saving. The optional five-minute autosave setting does not disable these
transition safeguards. Existing manual saves are retained.

Playtest: save from a passenger seat, return Home and inspect its role/progress.
Load paused and check seat/AI state. The save-failure and damaged-primary cases
are tested with isolated fixture files; do not damage your actual saves to try
them. Cancel/Back must retain the current journey; explicit discard is the only
path past a failed recovery write.


## Finding a carriage or seat

Pause → Camera & passengers → Go to passenger coach → Choose coach shows
class, free passenger seats, your current carriage and your remembered seat.
Coach numbers stay fixed along the formation: WAP locomotives are separate from
Coach 1; Vande Bharat uses Car 1–8/16. The list follows the driving end.

Select a carriage to stand in its aisle; AI takes over. Find an empty passenger
seat checks the current carriage first and then the rest of the train. A full
train keeps you where you are and reports that no seats are free. These view
transfers do not reserve seats or change the simulated passenger manifest.
Return to saved seat is available directly in both passenger menus. Hold R3
still recalls it from gameplay; while seated, holding R3 saves your view angle.

Playtest with K1 and a Vande Bharat: open the coach list, select a different
class/car, walk with LS, then find an empty seat. Return to the remembered seat
from the menu and with R3. From a reverse-ended VB driving cab, D-pad down must
visit the nearest carriage and continue away from that cab. On a platform,
the return-to-pilot prompt now correctly says to hold D-pad left/right.

## Reading busy dispatcher maps

Train tags keep their speed/length text inside the tag and avoid each other,
including at screen edges. Leader lines connect a moved tag to its train.
Clicking a tag inspects that train even if another body is underneath it; no
control handover occurs. Controller navigation selects each service once.

Above an 18 km span the map shows a labelled chainage overview. Zooming in
restores each station's roads and the full occupied train lengths. At very
crowded zoom levels, secondary tags may be hidden with a zoom-in hint; train
bodies stay selectable and your/inspected service tags receive priority.

Playtest at 720p: Explore by time → 20:00, inspect nearby trains, zoom out to the
whole route and back into a station. Check tag clicks, X locate, Y fit/follow
(as labelled on each screen), controller focus, and that viewing another
service keeps your existing service assigned.


## Finding services near a station

Explore by time → Near station lists active passenger services within 15 km
along the route, nearest first. The list shows distance from the selected
station. All active restores the full list; clicking a train outside the filter
also restores it before inspecting that train. The map still shows all traffic.

Use LS or D-pad to move through the roster; right enters the map and left returns
to the roster. In a station/stock/timetable dropdown, A confirms, B cancels,
up/down or LS move and LB/RB page through choices. These shoulder presses do not
change the preview time while a dropdown is open. Outside it, LB/RB step five
minutes as labelled.

An unavailable preview clears old boarding choices and offers Retry with its
failure reason. It never boards a stale railway. A closed station with no
accessible passenger platform disables its visit action. At the end of the day,
station visits remain available even when there are no active passenger trains.

Playtest at 20:00: choose Kazhakuttam, turn on Near station and inspect B007/B064.
Page through the station dropdown with RB and cancel with B; the clock and
station selection must stay unchanged. Select a new station with A. Check LS
roster navigation and map focus, then use Passenger seat to join a service.
