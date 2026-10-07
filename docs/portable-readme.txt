TRAIN GAME - SOUTHERN CORRIDOR
Windows x86-64 portable playtest build

THIS BUILD
Pilot/head-out cameras and service designer:
4 pilot seat; Q/E left/right head-out (same key returns). In driving views,
Xbox D-pad left/right leans out and up returns pilot. These preserve the handle.
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
4. F11 switches fullscreen/window. The initial window is 1280 x 720.

START PLAYING
You are randomly assigned one of six passenger services: WAP-7/LHB,
WAP-7/ICF and Vande Bharat. The other five trains use AI. Automatic dispatch
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
F2 selects a detailed WAP-7 light engine; F3 selects WAP-7 + mixed LHB classes.
Press the same scenario key again and confirm to select six MEMU services;
use D then AUTO DISPATCH to run their timetable.
F9 offers New random traffic service, plus solo imported fleet drives:
WAP-7, WAG-9, WAG-12B, ICF/LHB and Vande Bharat. Restart current services
keeps the same assignment. See guides/dispatching.md and imported-fleet.md.
Confirm a scenario change in the menu. In LHB, A drives automatically; V rides
inside a passenger coach. C opens the route desk for the next signal.

XBOX CONTROLLERS (360 / ONE / SERIES / ELITE)
RT/LT adjust power/brake; release to hold. A AI/manual; B emergency; X coast.
Y cab/exterior; View/Back passenger/cab; Menu/Start pause and controller settings.
Right stick looks; LB/RB zoom; left stick pans outside or changes position inside.
In pilot/head-out: D-pad left/right head-out, up pilot. Else left/right changes
coach and up first coach; down last coach. L3 opens/closes dispatch.
In menus: D-pad/LS focus, A select, B back, LB/RB previous/next control, RS scroll.
Menu > Train & view actions reaches routes, points, horn and all other commands.
Disconnecting pauses. Release all controls after resuming before driving again.
See guides/controllers.md for the full layout, settings and hardware playtest.

QUICK KEYBOARD CONTROLS
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
The current track-only mode mutes horn/engine layers deliberately.
Asset sources and engine licence notices are included in this folder.
