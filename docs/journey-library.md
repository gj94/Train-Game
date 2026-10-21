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
