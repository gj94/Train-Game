# Southern Line: dispatching and station meets

The game starts with two eight-car MEMUs, both under AI control and stopped at red.
T1 runs Chennapuram → Kadalur; T2 runs Kadalur → Chennapuram.
Maruthur has a main platform road and a bidirectional passing loop, long enough to hold each complete rake clear of the points.
The world begins at **D1 08:00:00** on a 24-hour clock. T1 departs at **08:01**, T2 at **08:02**.
Press **M** or **TIMETABLE** to inspect the selected service's blocks, minutes from origin, planned/actual times and dwell.
The schedule format and overnight examples are in [timetables.md](timetables.md).

## First playtest

Run the main scene with Godot F5, or `powershell -ExecutionPolicy Bypass -File tools/godot.ps1 run`.
The right-hand route desk has an entrance selector, an exit selector and **SET ROUTE**.
You can select entrances on the schematic or by clicking a 3D signal. Points align automatically when the route is accepted.

Set these four routes (in any order):

| Entrance | Exit | Movement |
|---|---|---|
| CPM-S1 | MRT-HE | T1 leaves Chennapuram |
| MRT-HE | MRT-SE2 | T1 enters Maruthur P2 / loop |
| KDP-S | MRT-HW | T2 leaves Kadalur |
| MRT-HW | MRT-SW1 | T2 enters Maruthur P1 / main |

Both trains must remain stopped until their scheduled departures, even with clear signals. Press **T** twice for ×4 time, and **2** to watch Maruthur. Both trains should stop about 6 m before their starters, on different roads. The main and loop tracks on the board turn red while occupied. The single-line approaches become grey after the tails clear them.

Maruthur is a mandatory call at **+4 minutes** from each origin departure, with a **1-minute dwell**. Early trains wait until their booked departure (T1 08:06, T2 08:07); late trains still dwell for a full minute. Each arrival is recorded in the timetable. Signals continue to control authority independently of the clock.

Then set:

| Entrance | Exit displayed in the desk | Movement |
|---|---|---|
| MRT-SE2 | KDP-H | T1 leaves the loop eastbound |
| KDP-H | Platform / KDP_B | T1 enters Kadalur |
| MRT-SW1 | CPM-H | T2 leaves the main road westbound |
| CPM-H | Platform / CPM_B1 | T2 enters Chennapuram P1 |

Set these onward routes as soon as they become available. Both trains must finish the station call before moving, even with clear starters. Both should reach their terminal stopping markers gently, with arrival booked at **+8 minutes** (T1 08:09, T2 08:10). The desk reports **2 / 2** and offers **RESTART SERVICES**. The timetable records the actual arrivals and minutes early/late.

## Safety checks to try

- Before either train reaches Maruthur, set MRT-HE → MRT-SE2. Request MRT-HW → MRT-SW2: the second route must be refused because it reserves the same platform block. Use MRT-SW1 for the independent arrival instead.
- While a train occupies a block, choose a route into it. **SET ROUTE** is disabled and the desk identifies the occupied block and train.
- Click a point marker beneath an active route. It must refuse to move. The points behind a train unlock only after its tail has cleared the turnout; its occupied platform block remains reserved.
- Set an unused route and press **PUT TO RED**. It should release immediately when no train is approaching. Cancel under a moving approach and the signal goes red while the points remain locked until the train stops safely.
- In manual control, try driving through red with protection on. An emergency intervention stops the train before the signal and logs an attempted SPAD. **Space** releases the emergency brake only at a stand.
- Leave the origin signal red past its departure time: AI must wait, then depart after you set the route. Its later booked times remain anchored to the original departure.
- Route T1 towards MRT-SE1 instead of its booked MRT-SE2: it must wait at MRT-HE and report that its route must serve `mrt_loop`. Cancel the unused wrong route and set MRT-SE2 to continue.
- Pause with **Esc**: the world clock, timetable and trains must all freeze. Resume and use **T** to check the clock and trains accelerate together.

## Driving and views

| Control | Action |
|---|---|
| Service buttons | Follow T1 or T2; retain each train's AI/manual state |
| Tab / TAKE CAB | Enter selected MEMU's detailed cab and take manual control; Tab again returns to overview |
| A | Toggle selected train between AI and manual; AI obeys routes but never sets them |
| W / S, arrow up/down | Move the power/brake controller and take manual control |
| X | Coast and take manual control |
| Space | Emergency brake / release at stand |
| R | Change ends at stand after completing the timetable; return movement is unscheduled |
| C | Open the route desk on the next signal; this does **not** clear it |
| D | Show/hide dispatch board and route desk |
| M / TIMETABLE | Toggle map and selected service's timetable; route controls stay available |
| Esc / PAUSE | Pause/resume simulation and audio |
| T | ×1 / ×2 / ×4 simulation time |
| 1 / 2 / 3 | Station overview |
| F | Follow selected train in overview |
| F1 | Full help |

Overview: right-drag orbits, left-drag pans, wheel zooms. Cab: right-drag looks around, wheel changes field of view. The existing approved sound controls remain available; rail-joint debug bars now start hidden (**J**).

## Implemented rules

- A signal cannot show a proceed aspect without a set route, correctly aligned locked points, and clear protected blocks.
- Red: no authority or occupied block. Yellow: route clear but the next signal is red, or the route ends at buffers. Green: the next signal also has a proceed aspect.
- Setting a route validates every block and point before changing anything. Opposing and crossing reservations are refused, including routes sharing points but not destination blocks.
- Signal passage records the train that owns the route and returns the signal to red. Cancelling in the gap between the signal and first point cannot release it underneath that train.
- Blocks are conservative **track-edge sections**; head and tail both count. Point clearance is released separately from the station berth so opposing trains can pass.
- AI uses braking curves for downstream red signals, speed reductions, occupied blocks and terminal buffers. A hard block-boundary safeguard remains enabled even when manual red-signal protection is switched off.
- Timetabled AI also brakes for every scheduled block stop, holds for departure and dwell, and refuses a route that bypasses its next booked block. It never sets routes or points. Manual driving retains the timetable and records arrival/departure when the required stop is served.
- Maruthur starters are 100 m inside the points, with 90 m turnout clearance zones. Chennapuram's junction is beyond both straight platform roads, with starters 130 m before the throat and 105 m clearance. Small test-layout points use 12 m. New layouts should specify suitable clearance distances.

This scenario has two dated timetabled services and completion/restart. Daily recurrence, scoring and save/load remain future gameplay work. Signals require a fresh dispatcher route after each train; there is no automatic re-clearing.

## Validation and visuals

```powershell
powershell -ExecutionPolicy Bypass -File tools/godot.ps1 test
& .\.local\godot\Godot_v4.7.2-stable_win64_console.exe --headless --path . --script res://tools/check_dispatch_ui.gd
```

74 unit/regression tests plus the full-scene integration check passed. The latter exercises route buttons, cab handoff, cancellation, scheduled departures, both arrivals, timetable cells/selection, actual times, midnight display, completion UI and imported texture mipmaps. Graphical captures checked the overview, detailed cab, Maruthur meet, and timetable before departure/at the meet/after completion. Actual handling and audio balance still need the user's playtest.

The art pass includes a dark route desk, live schematic, station furniture and passengers, footbridge, villages and access roads, grass blades, revised foliage, reflective flooded fields, warm daylight, MEMU destination boards and headlights. Mipmaps are enabled on the world PBR textures; Forward+, 8× MSAA, 16× anisotropic filtering, high SSIL and 8K directional shadows are retained/enabled for the intended powerful GPU. No new third-party assets were downloaded.
