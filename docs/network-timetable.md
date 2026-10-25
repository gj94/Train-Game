# Coastal Network 208

Development status, 26 October: the authored day is being simulated and checked.
It is not yet installed as a validated playable timetable. R47 remains available
with its existing Standard and Intensive days.

Coastal Network represents a full day of traffic on the Ernakulam–Alappuzha–
Kollam–Thiruvananthapuram–Nagercoil corridor. It contains 208 services, including
66 departures between 22:00 and 06:00 and traffic in every hour. Late departures
continue after midnight; the last booked arrival is on the following morning.

| Category | Services | Intended character |
| --- | ---: | --- |
| Passenger local | 40 | All-stations or local sections, frequent braking and station calls |
| Mail / express | 104 | Long-distance workings with more substantial intermediate calls |
| Superfast | 56 | Fewer calls than mail/express over comparable sections |
| Vande Bharat | 8 | Limited stops and the existing multiple-unit acceleration |

For example, the authored southbound Ernakulam–Thiruvananthapuram section has
40 intermediate local calls, 12 mail/express calls, five superfast calls and
three VB calls. Booked ride times are about 290, 215–219, 195 and 182 minutes
respectively. These are schedule values; actual traffic delays are still being
measured in the full-day runs.

The hierarchy comes from calling patterns and rolling-stock performance. Trains
still obey line speeds, signals and occupied platforms. A higher-priority train
can be delayed by an opposing movement or a safe route that is not yet free.
Passing opportunities arise when faster services catch stopping trains; no
station is instructed to produce a scripted overtake.

Classic and Predictive V2 use the same 208 services, departures and calls.
Their choices remain separate under **Operating day**. K1 is a 06:00 Ernakulam–
Nagercoil stopping passenger. Locals include useful shorter sections; through
trains carry their distant origin and destination instead of pretending every
journey starts and ends on this map.

Of the 208 services, 168 enter or leave through a boundary beyond Ernakulam or
Nagercoil. A displayed boundary time means entering or leaving the simulated
corridor, not departing Mumbai, Mangaluru or another distant city. The train
must clear the railway with its full length before its on-map journey ends.
If you are riding it, the game pauses at the nearest station viewpoint and offers
Dispatch or the pause menu so you can choose your next journey.

This is a representative timetable authored for the game, not a reproduction of
a current Indian Railways schedule. The coastal Mangaluru–Thiruvananthapuram VB
route informed the northern working; extra frequencies and southern VB workings
are fictional. Research and authorship evidence are recorded in the
[foundation audit](../art/performance/realism-2026-10-26/network-foundation/README.md).

Before installation, each full day must finish every service and call without a
safety event, meet the existing station and signal waiting targets, and record
real overtakes at different locations. The comparison will report actual ride
times over matching sections, rather than compare a short local with a much
longer express journey. Final counts and delays remain pending.

The first operating candidates exposed an admission defect and then morning
departure conflicts. The admission correction is tested; the current candidate
moves two local departures, L005 to 05:20 and L033 to 06:35, with all calls,
stock and dwell retained. Its complete-day acceptance is still pending.

Once installed, try a daylight local, a limited-stop VB, a through working and
an overnight departure. Compare the Stops and Traffic lists, ride through a
natural pass, and follow a service to its boundary completion page. Manual
driving changes later traffic; the prepared Traffic list describes the AI baseline.
