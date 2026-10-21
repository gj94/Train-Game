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
first passenger carriage with AI driving and a remembered seat. Boarding does
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
