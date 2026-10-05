TRAIN GAME - SOUTHERN CORRIDOR
Windows x86-64 portable playtest build

RUN ON ANOTHER PC
1. Copy the ZIP and extract the entire folder to a writable location.
2. Open TrainGame.exe. Keep TrainGame.pck beside it.
3. No Godot editor, Blender, Node.js or development checkout is needed.
4. F11 switches fullscreen/window. The initial window is 1280 x 720.

START PLAYING
The game starts in a WAP-7 hauling seven mixed LHB coaches: 1A, 2A, 3A,
2S, chair car, sleeper and general seating. W/S drive; A enables AI.
Tab shows the exterior; V enters a coach and PgUp/PgDn changes coaches.
The fictional Southern corridor is 21.64 km long. D opens the dispatch board;
T cycles normal / 2x / 4x time. C opens routes for the next signal.
F2 selects a WAP-7 light engine; F3 selects WAP-7 + 20 LHB coaches.
Press the same scenario key again and confirm to select six MEMU services;
use D then AUTO DISPATCH to run their timetable.
F9 opens the imported fleet: WAP-7, WAG-9, WAG-12B, seven-class ICF/LHB
showcases, and compact 8/16-car Vande Bharat. See guides/imported-fleet.md.
Confirm a scenario change in the menu. In LHB, A drives automatically; V rides
inside a passenger coach. C opens the route desk for the next signal.

QUICK CONTROLS
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
F1            Scrollable controls, with simulation paused
F4            Clean view / restore (emergency feedback remains visible)
F6 / F8       Track labels / event history
F9            Imported Indian Rail fleet
F11           Fullscreen / window
Esc           Pause / resume; back from help or confirmation

View preferences are remembered while moving between cab and exterior.
Switching away from the game pauses it; resume with Esc when you return.
Restart, scenario changes and quitting ask first. Progress is not saved.
Detailed route and passenger controls: see the guides folder.
Realism/joint playtest: guides/track.md. Exterior zoom reaches 3 m for wheel and
joint inspection. Real gaps and fishplates stay visible with J diagnostics off.

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
