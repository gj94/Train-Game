TRAIN GAME - KERALA COAST
Windows x86-64 portable playtest build

THIS BUILD
Kerala Coast R25: railway corridor rendering and bounded external cameras.
External cameras stop at 60 m above terrain; orbit zoom stops at 300 m.
The view ends at 2.2 km with distance haze. Detailed scenery is concentrated
within roughly 220 m of the railway; off-route ground and water remain.
Train simulation and the dispatcher map retain their full operating range.
Use Update and Play.exe to download changed blocks from the LAN server.
See guides/corridor-rendering-2026-10-10.md for measured GPU costs.
Add -RenderCosts to the crowded benchmark command below for category profiling.

EARLIER CHANGES
Kerala Coast R24: detailed trackside scenery and crowded-train rendering.
Nearby models retain detail; distant scenery uses LODs and baked images.
Pilot view skips seated passenger meshes; coach/platform views restore them.
The new stress test covers 5 trains, 91 vehicles and 5,580 passengers.
For only that test, open PowerShell in this folder and run:
powershell -NoProfile -ExecutionPolicy Bypass -File .\Benchmark.ps1 -CrowdedOnly -Resolution 1440p
See guides/trackside-collection.md and guides/crowded-benchmark-2026-10-10.md.
The RTX 4090 Laptop target remains i9-13980HX / 16 GB VRAM / 64 GB RAM.

BENCHMARK AND EARLIER CHANGES
Kerala Coast R23: threaded streaming and detailed target-PC benchmarking.
Double-click "Run Performance Benchmark.cmd" for automatic 1440p and 4K tests.
Allow 10-20 minutes. Leave the game focused and let it control the cameras.
Send back Documents/TrainGame-Benchmark-<date-time>.zip when it finishes.
Records frame timings, CPU/GPU/VRAM, scenery jobs, screenshots and error logs.
Full visual detail is preserved. F10 shows optional frame/worker/memory stats.
See guides/performance.md for single-resolution runs and measurement details.

Kerala Coast R22: greater researched Kerala scenery variety.
Veranda homes, laterite cottages, balcony villas, roadside shops, crops,
banana groves, boats, fishing nets, bunds and canal details across the route.
See guides/kerala-scenery.md.

Kerala Coast R21: stock-limited running and trackside speed indicators.
K1's artificial 65 km/h cap is removed: its ICF formation supports 110 km/h,
subject to the track, signals and traffic. Older built-in K1 saves upgrade too.
Yellow fishtail boards warn of lower limits; numbered triangles mark the start.
Circular T/P boards mark passenger release after full-rake clearance distance.
Read road plaques at junctions: loop restrictions apply to that road.
See guides/speed-boards.md. Use Update and Play.exe for the incremental update.

Kerala Coast R20: grounded station surroundings and denser coastal vegetation.
Connected entrance paving, organised parking, crossing/ramp, drains, planting
and precast concrete boundary fencing matching the supplied reference.
Platform backs/ends are closed; Kumbalam no longer has a redundant footbridge.
Nearby 3D grass, shrubs and denser trees respect tracks and platform clearance.
Use R3 free camera to inspect Kumbalam, Turavur, Ernakulam and Virani Alur.
See guides/station-surroundings.md. Existing saves remain compatible.
Use Update and Play.exe to download only changed blocks.

Kerala Coast R19: continuous camera movement inside every passenger coach.
Press D-pad Down/Up to choose a coach, then use LS to move/strafe and RS to look.
No Y press is needed. LS now moves you along the interior instead of zooming or
jumping between bays. The viewpoint follows that individual carriage while the
train moves and turns. A passes prompted interior doorways; L3 returns pilot.
Available in both controller layouts. Existing saves remain compatible.
Use Update and Play.exe to install this release into the same game folder.

Kerala Coast R18: logical controller camera navigation.
Pilot is the default. D-pad right/left from pilot enters right/left head-out;
repeat to cycle. D-pad down moves back one coach, up toward the pilot, no wrap.
Left stick moves around inside the cab using collision-aware walking; L3 returns
to the pilot. R3 enters free camera at eye height on the nearest open platform.
Free: LS move, RS look, RT/LT optical zoom, RB/LB raise/lower. Hold R3 for 0.65 s
to switch triggers between zoom and driving, then release controls to arm.
On foot: X + D-pad up toggles the headlamp. See guides/controllers.md.
R14-R17 saves remain compatible; new saves retain free-camera position and zoom.

Kerala Coast R17: free-camera sound follows your actual viewpoint.
Approaching a train now brings rolling, joints and squeal closer acoustically,
matching the engine/horn receiver. The old exterior mix followed the orbit focus
instead. Approved sounds, speed response and joint timing are unchanged.
R14-R16 saves remain compatible. See guides/enhanced-audio.md for checks.
Playtest: right-stick click for free exterior; move near a moving train's bogies,
then away. Left-stick click returns to pilot. Try nearby AI trains as well.

Kerala Coast R16: improved coastal scenery and materials.
Detailed houses with recessed windows, verandas, balconies and roof fittings now
replace suitable mapped building extrusions. Includes a new Kerala bungalow.
More varied vegetation, grass/soil transitions, dusty road shoulders, weathered
platform paving and roof sheets, planted forecourts and marked parking bays.
Daylight is less yellow and surfaces no longer receive artificial bloom.
R14/R15 saves remain compatible. See guides/visual-fidelity.md for scope and checks.
Playtest: visit Kumbalam in the dispatcher, inspect its forecourt and surrounding
houses with the external free camera, then compare a cab and passenger view.

Kerala Coast R15: new coastal station architecture from the reviewed Blender masters.
52 active station models, including furnished interiors, signs and distinctive
roof/facade details. Viranialur uses its photographed open shelters. Full visible
geometry is retained; materials are translated for real-time rendering.
Platforms/tracks retain the CSV game layout. Source static yards are not overlaid.
R14 saves remain compatible. See guides/station-model-port.md for coverage.
Playtest: visit Kumbalam, Turavur, Kollam and Neyyattinkara from the dispatcher;
use the external free camera to inspect the frontages and supported floor bases.

Kerala Coast R14: Save / Load journeys from Esc or controller Menu.
Five numbered slots plus Quick save. Ctrl+S quick-saves; Ctrl+L opens Load.
Trains, signal routes, dispatcher plans, passengers, timetable/depot progress,
your controls and camera/walking position resume. Loads start PAUSED.
Overwrites retain a previous backup; loading and manual overwrite ask first.
Open saves folder lets you copy saves to another PC. Saves live separately
from this game folder and survive build updates with compatible track layouts.
There is no autosave. See guides/save-load.md for details and playtest steps.

Kerala Coast R13: fixes the Turavur overtake departure order after long waits.
Once the VB arrives alongside for an overtake, a routine crossing delay keeps
it ahead of the passenger. Earlier signal waits no longer expire a fresh
overtake plan. Normal route, occupancy and full-tail protection still apply;
unavailable trains and circular dependencies can still trigger replanning.
Start a fresh scenario. See guides/dispatcher-overhaul.md for details.

Kerala Coast R12: travelling passengers in ICF, LHB and Vande Bharat coaches.
At scheduled platform stops people alight, others board and take seats. Doors
open on the platform side; traction waits for boarding and closed doors. F12
shows aboard/boarded/alighted totals. All passengers alight before depot working.
Crowds are rendered locally with a fixed budget; all journeys stay simulated.
F11 or Alt+Enter toggles fullscreen. Esc/controller Menu also has Fullscreen.
The display choice is saved; new portable installations default to fullscreen.
Start a fresh scenario. See guides/passengers.md for controls, scope and tests.

Kerala Coast R11: completed passenger trains unload, then run as empty stock
to reserved depot berths with normal signals and full-rake tail clearance.
Passenger progress/results stay complete. The dispatcher shows depot status;
the same assigned service is handed to AI for the depot movement after unloading.
Includes detailed ERS west/east halls, TVC heritage frontage and Nagercoil
buildings/interiors from the pinned station models, plus depot workshops.
The source architecture retains full detail. Operating tracks/platforms remain
the CSV-based game layout; depot connections are gameplay reconstructions.
Start a fresh scenario. See guides/depot-workings.md and station-model-port.md.

Kerala Coast R10: full-length service rakes replace the seven-coach showcases.
K1 has 20 blue ICF coaches; WAP express trains have 22 ICF or LHB coaches.
Every LHB coach now has consistent red/grey body paint. Families never mix.
Mass, acceleration, axle sounds, visible length and dispatch occupancy agree.
Platform/siding capacity uses the clear length between signals and points.
Yard ladders preserve full-length roads and starters are clear of turnouts.
Intermittent metallic coach-body rattles are stronger in ICF and quieter in LHB.
F5 lets you select/export/import the WAP rake profile; VB remains 8/16 cars.
All 56 platform counts follow the supplied station CSV. K1 has 55 calls because
Tirunettur is closed. Kumbalam has one passenger platform and two through roads;
the dispatcher can plan K1 into the VB's platform after its actual departure.
Pause/Start > Go to passenger coach... selects any coach while moving, including
behind a WAP. Y/E stands inside; left-stick click/4 returns to the pilot.
This preserves your service, AI and power/brake setting.
WAP-7 has no passenger gangway: stop by a platform, press Y/E to stand, face
the cab side door, then A/left-click to alight. Walk to and board coach 1.
These are representative formations; utility/guard cars are not yet modelled.
Start a fresh scenario. See guides/rakes.md, guides/walking.md and the station audit.
Old Kerala service files need a fresh layout signature after the yard changes.

Kerala Coast R9: sprung-body jolts, vibration, curve sway and traction/brake pitch.
Cab/passenger/walking views move with the coach; wheels remain on the rails.
Head-out audio is open-air; walking coaches retain passenger acoustics.
The dispatcher prepares free home routes from the preceding automatic block.
Yellow remains correct when the next signal is red; occupied/conflicting routes
still protect at red. Start a fresh scenario. See guides/ride-dynamics.md.

Kerala Coast R8: direct camera controls, shared by both Xbox layouts.
D-pad left/right cycles all cameras backwards/forwards. Left-stick click returns
to pilot; right-stick click selects external FREE camera without following.
Use LS to pan and RS to orbit outside; hold RS + LS up/down to zoom in default
layout. The cycle includes the WAP cab positions, both head-outs, first/middle/
last passenger coaches, following exterior and free exterior.
These shortcuts also work on foot. B crouches; D-pad up toggles the walking
headlamp; X+Y sounds the horn in default layout. Menu/dispatch navigation stays
contextual, and changing cameras preserves the assigned service and AI/handle.

Kerala Coast R7: automatic future-platform crossing plans and service removal.
Start a fresh K1 scenario: you can approach Kumbalam while K2 approaches from
the other side. Wait at the home signal for the VB to leave; enter its P3,
then K2 clears north once your rear is in. Physical signals still govern entry.
The dispatcher reserves the vacating train's escape and receiving platform;
late running never makes an occupied platform safe merely because time passed.
D / View opens dispatch. Inspect an AI service, choose Delete service..., then
confirm its name to remove it from this run and reassess traffic. Keep service
is the default confirmation choice. Your assigned train cannot be deleted;
hand over to another service first. Restart restores the original scenario.

Kerala Coast R6: 32 scheduled services, with K1 the default stopping passenger.
The HUD replaces the camera label with next station, metres and estimated
in-game minutes. Signal waits are additional; fast forward retains world minutes.
D shows all services; F5 supports up to 64. Nearby detailed trains/audio stream
as you travel while every service stays active in the simulation.
Dispatcher admission now reserves compatible passenger berths across both
approaches and checks onward routes, preventing the reported Kumbalam trap.
Left-stick click returns to pilot; D-pad right then selects left head-out.
At a stopped train's platform-side doorway, A/left-click steps onto the platform;
walk to another carriage doorway and interact to board. The train can leave
while you remain outside. 4 / left-stick click returns to the pilot.
Electric engine/traction sound and horn are active again, beside the approved
clack/squeal sound. The approved sample banks are unchanged.

Kerala Coast R5: walk inside the moving train; default TSW-style Xbox layout.
Y/E stands or sits; LS/WASD walks; RS/right-drag looks; RT/Shift runs;
B/C crouches. A/left-click uses the seat, doorway or gangway prompt.
D-pad up/L toggles a headlamp. The train's driver and handle stay set.
Driving: RT/RB power, LT/LB brake. Hold X+A AI, X+B emergency, X+RB coast.
LS click pilot; RS click free exterior; D-pad left/right cameras. View tap dispatch,
View hold progress. Settings can restore the legacy controller layout.
Doorways and gangways use a short transition; animated door leaves are not
included. R6 adds Kerala platform walking. See guides/walking.md and controllers.md.

Kerala Coast R4: all fourteen ICF/LHB coach classes now use detailed v02 assets.
Class-specific furnishings, running gear, underframe equipment, exterior markings
and authored materials are preserved. Vande Bharat EC cars use the newer published
source. The four selectable formations and axle/joint audio spacing stay the same.
F9 selects ICF/LHB; V enters a coach, PgUp/PgDn changes class, Home toggles seat/aisle.
See guides/coach-detail.md for source status and remaining static mechanisms.

Kerala Coast R3: rebuilt control desk and independent dispatch engine.
D opens the full-screen desk: wheel zoom, drag pan, whole-route overview,
actual train footprints, service inspection, route actions and decision log.
Clicking a train only inspects it. View train preserves your assignment;
Take control asks for confirmation. Press 4 to return to your pilot seat.
Xbox desk: LS pan, LT/RT zoom, D-pad targets, A inspect, LB/RB areas,
X locate, Y whole route, RS inspector scroll, B back.
Corrected double-sided multilingual nameboards, including Tamil in Tamil Nadu.
Eraniel-Nagercoil now uses the commissioned double line. All 56 stations have
a research audit; unresolved total-track/bay/platform discrepancies are recorded,
not certified as exact infrastructure. See guides/kerala-station-audit.md.

Kerala Coast R2: overhead supports now stand outside parallel tracks; wider
yards use shared gantries. Foundations clear curved tracks and platforms.
Buildings have terrain-following foundations; water crossings have continuous
bridge decks, abutments and piers. Drive the first two stops to inspect them.
Manual stops accept the whole train inside the platform instead of requiring
an exact one-metre marker. If a call was missed, PROGRESS/F12 offers a skip
button; skipped calls do not count as completed stops.
Default: K1, the slow all-stop passenger on the Kerala Coast geographic route.
Ernakulam Jn - Alappuzha - Kayamkulam - Kollam - TVC - Nagercoil Jn,
about 277 km at full scale, 56 mapped stations, 32 playable services.
K1 is the slow all-stop passenger. Priorities and actual progress determine
crossings/overtakes. The HUD names the service you should expect to wait for.
PROGRESS / F12: completed/total stops, stops left, next stop, distance and estimated
in-game time. The origin counts as the first call. Back resumes the prior state.
T: fast forward x1/2/4/8/16/32; Shift+T returns to normal. All traffic and the
clock advance together; speeds remain ordinary in-world km/h.
Enhanced full-size Vande Bharat 8/16 preserves source interiors and articulation.
Only detailed WAP-7 + ICF/LHB and Vande Bharat 8/16 are selectable.
D: choose a station yard, then VISIT YARD to explore it. F follows your train.
F5 designs and exchanges services for this route. F7 returns to the short corridor.
Initial loading and distant camera transfers prepare nearby scenery first.
This is a playable reconstruction: yards, signals, bridges and most facades are
interpreted, not a complete current survey. See guides/kerala-coast.md.
Map data (c) OpenStreetMap contributors, ODbL 1.0; NASA/USGS SRTM terrain.
See MAP-DATA-LICENSE.md for sources, attribution and editable database access.

Pilot/head-out cameras and service designer:
4 pilot seat; Q/E left/right head-out (same key returns). In driving views,
Xbox D-pad left/right cycles cameras; LS click returns pilot. These preserve the handle.
F5 designs services: formations, departures, platform stops and dwell times.
Import/export JSON timetables and rehearse AI traffic; choose any service to drive
while AI runs the other trains and dispatcher. See guides/services.md.

Visual fidelity update: textured broadleaf canopies, fuller palms, irregular verge
cover, finer rice blades, rounded masonry edges and weathered photographic station
finishes. Platform passengers have revised faces and clothing. Track stone and
sleepers have a darker, more worn finish. Detailed WAP-7 geometry is preserved.
See guides/visual-fidelity.md for comparison views, performance and playtest steps.

Audio update: corrected native filters, output-buffer timing compensation and
39 m joint spacing matching the approved website. F10 shows the audio buffer estimate.
Detailed WAP-7 39002 with both complete cabs and machinery compartment.
F2 light engine / F3 mixed LHB rake. Home cycles driver, assistant, cab overview
and machinery aisle. Right-drag look stays on release; middle-click recenters.
See guides/wap7-detail.md for the model and inspection controls.

Rebuilt scenery: station towns, villages, shops, apartments, industrial buildings,
bus stops, road traffic, tropical trees, paddy fields and detailed canal banks.
Includes full Xbox controller support and cab/passenger performance fixes.
F10 shows FPS, GPU time, audio work and pending impacts. Ride for several minutes
in cab and passenger views when comparing performance on your PC.
Press A to let AI drive, then Alt+1/2/3 to inspect the landscape from the first,
middle and last passenger coaches. See guides/stations.md for scenery details.

RUN ON ANOTHER PC
1. Copy the ZIP and extract the entire folder to a writable location.
2. Open TrainGame.exe. Keep TrainGame.pck beside it.
3. No Godot editor, Blender, Node.js or development checkout is needed.
4. F11 / Alt+Enter switches fullscreen/window. New installs start fullscreen;
   Esc/controller Menu offers the same action. Your choice is remembered.

START PLAYING
You start in the K1 stopping passenger among 32 Kerala Coast services: WAP-7/LHB,
WAP-7/ICF and Vande Bharat. The other 31 trains use AI. Automatic dispatch
sets safe routes for everyone, including your manually driven service.
Wait at red while earlier trains clear shared routes and occupied platforms.
F1 opens your scenario briefing: your service, stops, expected traffic and job.
W/S drive; A enables AI for your train so you can ride as a passenger.
Tab shows the exterior; V enters a coach and PgUp/PgDn changes coaches.
Alt+1 / Alt+2 / Alt+3 directly enter the first / middle / last passenger coach.
While riding, 1 / 2 / 3 switch those views. Esc also has a Passenger views menu.
The current sound includes the new benchmark squeal and speed-dependent rolling;
see guides/enhanced-audio.md for the listening test and controls.
The fictional Southern corridor is 21.64 km long. D opens the dispatch board;
T cycles normal / 2x / 4x time. C opens routes for the next signal.
F2 selects WAP-7 + ICF; F3 selects WAP-7 + mixed LHB classes.
F9 offers traffic services and solo imported fleet drives:
WAP-7 + ICF/LHB and Vande Bharat 8/16. Restart current services
keeps the same assignment. See guides/dispatching.md and imported-fleet.md.
Confirm a scenario change in the menu. In LHB, A drives automatically; V rides
inside a passenger coach. C opens the route desk for the next signal.

XBOX CONTROLLERS (360 / ONE / SERIES / ELITE)
Default TSW-style: RT/RB power, LT/LB brake; release to hold. Y stand/sit.
X tap actions; hold X+A AI/manual, X+B emergency, X+RB coast, X+Y horn.
RS looks; RS click external free; LS click pilot. D-pad left/right cycles all
cameras; D-pad Down/Up selects the next/previous passenger coach. LS moves inside
the cab or coach, RS looks. Free camera: RT/LT zoom; hold RS switches to driving.
On foot LS walks, RT runs, B crouches, A interacts; X + D-pad up toggles headlamp.
View tap dispatch/hold progress. Menu/Start pause and controller settings.
In menus: D-pad/LS focus, A select, B back, LB/RB previous/next control, RS scroll.
Menu > Train & view actions reaches routes, points, horn and all other commands.
Disconnecting pauses. Release all controls after resuming before driving again.
See guides/controllers.md for the full layout, settings and hardware playtest.

QUICK KEYBOARD CONTROLS
E             Stand / sit near a seat
Shift+E / Q   Right / left head-out view
On foot       WASD walk, Shift run, C crouch, L headlamp, 9 dispatch
W / Up        More power
S / Down      Reduce power / increase brake
X             Coast
Space         Emergency brake; press again at a stand to release
Tab           Cab / exterior (entering the cab takes manual control)
A             Selected train AI / manual
D / M         Dispatch board / timetable
F / 1 / 2 / 3 Follow train / station views
Right-drag    Orbit outside, look around inside
Mouse wheel   Zoom
Comma / .     Decrease / increase second-axle clang balance
F1            Your scenario briefing and controls; simulation pauses
F4            Clean view / restore (emergency feedback remains visible)
F6 / F8       Track labels / event history
F9            New random traffic service / solo imported fleet
F10           Live FPS, GPU time, audio CPU time and queued-impact diagnostics
F11           Fullscreen / window
Esc           Pause / resume; back from help or confirmation

View preferences are remembered while moving between cab and exterior.
Switching away from the game pauses it; resume with Esc when you return.
Restart, scenario changes and quitting ask first. Progress is not saved.
Detailed route and passenger controls: see the guides folder.
Realism/joint playtest: guides/track.md. Exterior zoom reaches 3 m for wheel and
joint inspection. Real gaps and fishplates stay visible with J diagnostics off.
Impact pitch and timbre follow the approved website bank; event spacing follows
physical wheel positions and train speed. The newer benchmark supplies squeal.

DISPLAY AND TROUBLESHOOTING
This build keeps the project's Forward+ renderer and high graphics quality.
Use a Windows 10/11 64-bit PC with a Vulkan-capable graphics driver. Integrated
graphics can be slow with this detailed route. First launch may take time while
the graphics driver prepares shaders. Do not run directly inside the ZIP.
If something fails, include the log from:
%APPDATA%\Godot\app_userdata\Train Game\logs\godot.log
The executable is an unsigned personal development build.

PERSONAL PLAYTEST COPY
The approved track sound is derived from the user's reference recording and is
registered for personal use only. This package is for use on your own PC.
Engine hum/traction and horn are enabled; track sound retains the approved bank.
Asset sources and engine licence notices are included in this folder.
