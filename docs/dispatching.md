# Southern corridor: dispatching six trains

The default route spans **21.64 km** between terminal buffers (about 22 km), with
two directional main tracks and **four 600 m platform faces at each station**.
Chennapuram, Maruthur and Kadalur use the Kumbakonam, Mayiladuthurai and Thanjavur
architectural references described in [stations.md](stations.md). The yards and
route remain fictional, with realistic metre-scale train and platform lengths.

Six eight-car MEMUs start under AI control at D1 08:00. Departures are paired at
08:01, 08:02 and 08:04, calling at Maruthur at +12 minutes with a three-minute dwell,
and booked at the other terminus at +28 minutes. See [timetables.md](timetables.md).

## Reproduce the busy-station test

1. Run the main scene (F5), then press **D** to open dispatch. Enable **AUTO DISPATCH** and **HOLD MRT**
   before the first departure. Auto dispatch requests the booked routes through
   the same interlocking used by the manual desk. HOLD MRT keeps Maruthur's
   departures at red; it does not cancel routes already set.
2. Press **2** for the Maruthur overview and choose **MRT yard** on the schematic.
   Press **T** twice for x4 time. The expanded route takes several real minutes.
3. Watch **T1 on P1, T3 on P2, T2 on P3 and T4 on P4**. All four will berth
   together. T5 and T6 queue outside the station at red. At roughly 08:16, all
   four platform roads should be red on the diagram with two trains held outside.
4. Select **MRT-HE**, then **MRT-E1**: an occupied-platform request must be refused,
   identifying the occupying train. Check locked point markers and live aspects.
5. Turn **HOLD MRT off**. Trains depart after their dwell, tails clear the points,
   the following pair enter the freed platforms, and all six reach their booked
   terminal roads. The desk shows **6 / 6**, with **RESTART SERVICES** available.
6. Select each of the six roster entries; **M** shows that service's booked and
   actual times, **Tab** takes its cab, and **A** hands driving back to AI.

The automated full-scene test performs this sequence and checks that no signal
overshoot, collision intervention or point run-through event occurs.

## Dispatch manually

Leave AUTO DISPATCH off. Signals on plain mainline blocks re-clear automatically;
you control station homes and platform starters. Automatic signals have A plates,
and their route buttons are disabled. Terminal crossovers connect either mainline
to all four platform roads. Maruthur's normal eastbound platforms are P1/P2,
westbound P3/P4. Its two arrival fans are independent; departures from two roads
onto the same running line conflict and must be dispatched successively.

| Train | Origin route | Maruthur arrival | Maruthur departure | Terminal arrival |
|---|---|---|---|---|
| T1 | CPM-E1 → W-AE1 | MRT-HE → MRT-E1 | MRT-E1 → E-AE1 | KDP-H → BUFFER:KDP_B1 |
| T2 | KDP-W3 → E-AW1 | MRT-HW → MRT-W3 | MRT-W3 → W-AW1 | CPM-H → BUFFER:CPM_B3 |
| T3 | CPM-E2 → W-AE1 | MRT-HE → MRT-E2 | MRT-E2 → E-AE1 | KDP-H → BUFFER:KDP_B2 |
| T4 | KDP-W4 → E-AW1 | MRT-HW → MRT-W4 | MRT-W4 → W-AW1 | CPM-H → BUFFER:CPM_B4 |
| T5 | CPM-E3 → W-AE1 | MRT-HE → MRT-E1 | MRT-E1 → E-AE1 | KDP-H → BUFFER:KDP_B3 |
| T6 | KDP-W2 → E-AW1 | MRT-HW → MRT-W3 | MRT-W3 → W-AW1 | CPM-H → BUFFER:CPM_B2 |

Routes sharing an entrance, destination block or point cannot be set together.
Set each subsequent movement once the previous tail has cleared the throat.
A home can route a following train to a different free platform while the first
train remains berthed. The occupied berth itself remains protected by occupancy.
The AI refuses an unbooked platform and waits for a route to its scheduled stop.

## Board and controls

The game starts with a compact HUD and a clear view of the railway. **D** opens
the dispatch workspace; returning from the cab restores whether you left it open
or closed. Track labels and event history start hidden. **F4** clears the HUD and
board, with emergency feedback retained; press it again to restore the display.
**F6** toggles track labels, **F8** event history and **F11** fullscreen.
Help pauses the simulation. Alt-tabbing pauses automatically; Esc resumes.
Restart, F2/F3 and quitting show a confirmation before discarding the current run.
For a standalone Windows copy, see [builds.md](builds.md).

The schematic is generated from the real track graph. **Whole line** compresses
rural distances; the three yard buttons enlarge points, platforms and signals.
Red tracks are occupied, mint tracks reserved, amber points locked, and white
tracks preview the selected route. Click a train label to follow it, a signal to
select its entrance. Click a point marker in the 3D world to request a manual throw. Hover on the board for signal IDs.
The right panel retains all six service buttons and route controls when viewing
the timetable. Refusal reasons explain occupied blocks and conflicting locks.

| Control | Action |
|---|---|
| D | Show/hide dispatch board and desk |
| M / TIMETABLE | Selected service's timetable / diagram |
| C | Select the next signal; does not clear it |
| Tab / TAKE CAB | Selected train's driving cab / overview |
| A | AI/manual driver; route automation is a separate desk option |
| W / S, Up / Down | Power/brake and take manual control |
| X | Coast and take manual control |
| Space | Emergency brake / release at stand |
| R | Change ends at stand after timetable completion; LHB requires a run-round |
| Esc / MENU | Pause world clock, trains and audio; resume / back |
| T | x1 / x2 / x4 simulation time |
| 1 / 2 / 3 | Station overview |
| F | Follow selected train |
| F2 / F3 | WAP-7 light engine / full LHB rake, toggle back to MEMU services |
| F1 | Scrollable help; pauses the simulation |

Overview uses right-drag to orbit, left-drag to pan, wheel to zoom. Cab uses
right-drag to look and wheel for field of view. F2/F3 also use the expanded route.
The 500.562 m LHB rake fits wholly alongside each 600 m platform.

## Signalling and checks

- Left-hand double-line running, six-metre mainline centres, four sections per
  direction between stations, 110 km/h mainline, 65 km/h normal platform roads,
  30 km/h loops/crossovers. These are chosen layout dimensions and operating values.
- Red means no valid clear authority. Yellow means the route is clear but its next
  signal is red (or it ends at buffers). Green requires the next signal to proceed.
- Homes stand 250 m before the first points. Plain-line automatic signals are also
  set back 250 m from their edge ends; reservations include that space beyond the
  next signal. Blocks conservatively cover whole graph edges, including train tails.
- Point alignment and reservations validate atomically. Signal passage assigns the
  movement owner and restores red. Points release only after tail clearance: 195 m
  at platform fans, 155 m at terminal crossover points. Starters stand 270 m inside
  the platform edge ends; the AI stopping marker is another 6 m before the signal.
- Try **MRT-E1 → E-AE1**, then **MRT-E2 → E-AE1**. The second must refuse while the
  first reserves their merging throat. Independent opposite-direction arrivals
  **MRT-HE → MRT-E1** and **MRT-HW → MRT-W3** may coexist.
- **PUT TO RED** releases an unused route immediately if no train approaches.
  Cancellation under an approaching train retains locks until it is safe to release.
- AI braking respects red signals, occupied blocks, limits, scheduled stops and
  buffers. Timetables never override signal authority. Check pause, early departure
  holds, three-minute actual dwell after a late arrival, and the recorded delay in M.

Principles were checked against [RDSO automatic signalling guidance](https://rdso.indianrailways.gov.in/uploads/Handbook%20on%20Automatic%20Signalling%20with%20MSDAC%20using%20OFC_August%202021.pdf)
and [Railway Board signalling essentials](https://indianrailways.gov.in/railwayboard/uploads/directorate/signal/2023/7-Essential%20of%20Signalling.pdf).
This is a three-aspect game implementation with whole-edge blocks, not a replica
of a particular real station's interlocking. Calling-on, degraded working, shunting,
relay failures, daily recurrence, scoring and save/load are not implemented.

## Validation

```powershell
powershell -ExecutionPolicy Bypass -File tools/godot.ps1 test
& ./.local/godot/Godot_v4.7.2-stable_win64_console.exe --headless --path . --script res://tools/check_corridor_playable.gd
& ./.local/godot/Godot_v4.7.2-stable_win64_console.exe --headless --path . --script res://tools/check_stations.gd
```

The suite passes 98 tests, including seven new corridor cases: directional tracks,
independent/conflicting routes, terminal platform access, continuous turnout paths,
full-length LHB berthing, WAP-7 round trip and six-service station saturation/recovery. The scene check
adds the real roster, route chooser, timetable and completion UI. Earlier two-train,
WAP-7 and LHB scene checks retain the small layout as an explicit regression fixture.
The WAP-7 also completes an outward/return run on the expanded corridor.
Reviewed live captures are under `art/stations/corridor_*.png`. Final handling,
visual performance and audio balance remain part of the user's playtest.
