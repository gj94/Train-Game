# Choosing a service at launch

The game opens on a controller-friendly Kerala Coast service screen. It lists
the bundled 100-service operating day, with departure filters, search, route,
formation, complete booked calling pattern, route distance, booked duration and
starting time. Sort by departure, scheduled average speed (either direction),
or service name. Average speed is track distance between booked stop markers
divided by origin departure to destination arrival, including intermediate dwell.
Search also matches intermediate station names. Arrival/departure columns mark
times after midnight as day 2.
K1 remains the first/default 08:00 stopping passenger. **Night** filters the
evening departures so you can begin after dark without replaying the day locally.

Select a row, review the journey, then choose **Drive this service**. The railway
loads at the service's origin, normally about two minutes before departure. If
the origin berth was occupied, the starting time can be later. Actual signals,
occupied roads, passenger exchange and traffic delays still apply. You begin
paused in the pilot seat, under manual control with brakes applied. Resume when
ready; the other trains and dispatcher are controlled by AI.

**Continue latest save** restores the newest valid primary/backup save. **Saved
journeys** lists the available manual, quick-save and backup slots. Saved journeys
retain the real progress, delays and viewpoint of that run. Loading never
replaces an ongoing journey with the baseline. Invalid or incompatible saves
report their error on the menu without starting a different service.

From play, **Menu → Choose another service / main menu** asks for confirmation,
then returns to selection. Save first to retain progress. **Restart current
services** reloads the chosen departure state for journeys begun from this screen,
including after saving and continuing them.

## Explore by time

**Explore by time** opens a second browser for the complete operating day in
five-minute blocks. Drag the time slider, use the ±5/±30 minute buttons, or use
LB/RB for five-minute steps. A worker reconstructs one prepared railway at a time.
Rapid changes discard obsolete reads before displaying the latest requested time.

The zoomable dispatcher preview shows actual occupied train footprints, signals,
reserved routes and station roads in that baseline state. Select a station to
inspect its yard, click a train to inspect it, or use the active-service list.
Inspection cannot set routes, release signals or change a driver. Explicit entry:

- **Join selected service**: paused in its pilot seat, with AI still driving and
  its existing speed, power/brake handle and authority intact. Resume with AI or
  take over using normal driving controls. Stored, future, completed and
  empty-stock depot workings are not offered as passenger services.
- **Visit station platform**: paused in the requested station's bounded walking
  mode. All trains remain under AI. Walk, board or use Dispatch to select another
  active service. Spawn locations use existing platform collision/obstacle rules;
  every open station has a verified landing.

The map supports wheel zoom/drag pan. With map focus, LS pans, triggers zoom and
Y fits the route. D-pad up leaves the map for the station picker, down moves to
the entry action, and left to the roster. A on a train list inspects before entry;
A on the entry button commits. B returns to departures.

These are new baseline journeys, **not a rewind of your current save**. A future
preview shows what the AI-run baseline did; it cannot promise the same crossings
or overtakes after your driving changes the traffic. Use in-game **Skip forward**
to advance your current railway instead. Restarting a time-browser journey opens
the browser at its original time, including after save/load.

## Controls

- Mouse selects a service; double-click/Enter moves focus to its start button.
- D-pad or left stick navigates; A on the list moves to the start button, and A
  there starts the selected journey. B returns to the list or cancels a load.
- LB/RB cycles departure filters. X cycles sorting; the Sort by dropdown also
  supports mouse/keyboard/controller. Right stick scrolls the full calling list.
- Keyboard arrows/Tab/Enter navigate. F11 or Alt+Enter changes fullscreen.

The browser itself loads no train models or 3D world. Checkpoint reading and
railway reconstruction run on a worker. Cancelling waits for that read to finish
without entering the game. The normal nearby-scenery loading follows selection.
Both the landing screen and gameplay loading screen show the build identity.

## How prepared departures preserve the timetable

`tools/prepare_service_starts.gd` runs the unchanged railway under AI from 08:00.
When each service first becomes active, it saves a complete, stopped origin state:
all 100 services, passenger progress, train positions, points, signals, route
locks, depot occupancy and dispatcher commitments. It restores each checkpoint
and checks byte-for-byte state equality before retaining it. The replay continues
until all services have finished and cleared to depot; safety events, stalls or
extra waits over 30 minutes prevent catalogue completion.

The resulting `data/service_starts/` contains compressed, checksummed binary
states and a lightweight catalogue. The game validates engine compatibility,
layout compatibility, file integrity and the selected train's origin readiness.
It only changes the selected train's driving assignment on handover. A source
fingerprint gate refuses export after simulation/timetable changes until starts
have been regenerated. Track signatures are checked when restoring a state.

These are **new journeys with an all-AI history before you take over**. They do
not reproduce delays from another saved game. The ordinary Skip forward feature
still advances your current railway and preserves your driving history.

Instant starts currently cover the bundled operating day. The F5 service designer
and import/export retain their existing behavior for custom timetables; those
packs do not silently reuse the built-in prepared states. They require their own
preparation support before instant departures can be offered for them.

`tools/prepare_railway_times.gd` prepares every five-minute boundary from the
start of the day through final depot clearance. It accelerates offline work by
loading the latest preceding verified service checkpoint and advancing the same
serial railway in two-second steps. Every resulting state is restored and compared
byte for byte, with no safety events permitted. The time catalogue is tied to the
exact departure catalogue, engine and simulation sources. Both catalogues must
verify before export. Binary files are compressed simulation data; no meshes,
textures or scenery are duplicated. The UI keeps the current preview and a
transient incoming state in memory, not the entire day. The PowerShell wrapper
below divides the day into independent contiguous ranges and verifies/merges
them after all workers finish. This parallelizes offline preparation; it does
not alter normal gameplay's simulation ownership or timestep.

## Snapshot storage and memory

The 100 departure states occupy 173,878,584 bytes (165.8 MiB), averaging
1.66 MiB per service. States get larger as the railway accumulates passenger
and completed-service records. The 22:08 B011 departure is 3,777,641 bytes
compressed and 30,631,772 bytes as a serialized checkpoint. Restoring it in a
headless Godot process adds 172,952,503 bytes (165.0 MiB) of tracked heap;
decoding and restoring together briefly add 312,361,347 bytes (297.9 MiB).
These are simulation allocations, not process working set or graphics memory.
The browser additionally retains its old preview while the next state loads.
It never reconstructs all 100 departures or all five-minute states at once.

The complete five-minute set has **233 states, 08:00 through day 2 03:20**,
occupying 568,414,642 bytes (542.1 MiB). The mean is 2.33 MiB and the largest
compressed state is 3.85 MiB. The final 03:20 state restores to 177.0 MiB of
tracked Godot heap, with 321.4 MiB transient decode+restore. Both prepared sets
together occupy 707.9 MiB before the catalogue files. These measurements are
from the development PC; the playing PC has 64 GB RAM.

Measure again after changing passenger records or the timetable:

```powershell
& .local/godot/Godot_v4.7.2-stable_win64_console.exe --headless --path . --script res://tools/measure_service_start.gd
& .local/godot/Godot_v4.7.2-stable_win64_console.exe --headless --path . --script res://tools/measure_service_start.gd -- --timeline
```

## Developer checks and regeneration

```powershell
& .local/godot/Godot_v4.7.2-stable_win64_console.exe --headless --path . --script res://tools/prepare_service_starts.gd
& .local/godot/Godot_v4.7.2-stable_win64_console.exe --headless --path . --script res://tools/complete_service_briefings.gd
node tools/verify-service-starts.mjs
powershell -NoProfile -ExecutionPolicy Bypass -File tools/prepare-railway-times.ps1 -Workers 4
node tools/verify-railway-times.mjs
& .local/godot/Godot_v4.7.2-stable_win64_console.exe --headless --path . --script res://tests/run_tests.gd
& .local/godot/Godot_v4.7.2-stable_win64_console.exe --path . --audio-driver Dummy --script res://tools/check_service_selection.gd
& .local/godot/Godot_v4.7.2-stable_win64_console.exe --path . --audio-driver Dummy --script res://tools/check_railway_timeline.gd
```

Regeneration is a full operating-day simulation on the development PC. It is
performed before shipping, not on each player's first launch. A partial catalogue
cannot be selected or exported. Do not run the editor importer during these
checks. The native check uses isolated save slots and source gameplay; it does
not launch or extract a distribution. `--preview` is a separately labelled,
temporary partial-catalogue UI check and is not a release validation.

The normal benchmark arguments bypass the landing screen; `--direct` provides
the old direct start for development. Native tools that explicitly load
`game/main.tscn` also retain their existing behavior.

## Playtest the release

1. Launch; use LB/RB to select Night, choose a service and press A twice. Check
   the displayed origin and time, dark sky, stopped train and surrounding traffic.
2. Resume and depart when cleared. Use A for AI driving if desired. Verify that
   approaching/crossing trains continue their existing movements.
3. Save, return to the main menu, then Continue. Clock, service, driving mode,
   passenger progress and viewpoint must return paused exactly where saved.
4. Start K1, B001 (VB8) and B012 (VB16) from their daytime departures. Test
   search, both controller sticks, cancel loading, and fullscreen.
5. Return from a later service and select another. Confirm no stale train,
   camera or custom-timetable settings leak into the new journey.
6. Sort fastest/slowest; compare a VB and a stopping passenger. Scroll their
   ARR/DEP columns and check day-2 labels on overnight arrivals.
7. Explore by time → 20:00. Inspect/zoom a yard, join a moving train, resume under
   AI, then take over. Signal routing must continue after handover.
8. Return and visit TVC at 20:00. Walk along the platform, save and continue.
   Verify the requested station, night lighting and all-AI traffic remain.
9. Rapidly scrub times and cancel/back while loading. No stale preview or unwanted
   train entry should appear; the chosen time must match the displayed clock.
