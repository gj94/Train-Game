TRAIN GAME - KERALA COAST R38

R38: detailed sound mixer, alternate operating day and safer route allocation.
Use Operating day on the home page to choose Standard (100 services) or
Intensive (140 services). Each has its own departures, five-minute railway
states and simulated crossings/overtakes preview. K1 is the slowest scheduled
service in Intensive, with at least ten distinct overtaking trains in its
validated AI baseline. Manual driving changes the actual encounters.
Sound settings separately control rail hiss, joint clacks, squeal, own wind,
passing air, floor thumps, metallic rattles, motors, fans, horns, compressor,
ventilation, footsteps, doors and brake air. Existing mixer settings migrate.
Through VBs prefer the clear main at Trivandrum North. Receiving-road checks
preserve platforms needed by approaching trains, and future crossing plans
cannot depend on a train continuing beyond its final station.

Includes forward planning for station crossings and earlier home clearance.
The dispatcher can reserve a future platform after an overdue AI train leaves,
while protecting the opposing arrival and the departing train's escape.
Manual driving disables automatic departure horns; your horn button still works.
AI-driven services keep their two departure calls.
Includes R35's simulated crossings and overtakes on the home page,
smoother moving-clock sunlight/shadows, consolidated lineside speed boards,
and driving RB/LB for power reduction/brake release, both stopping at coast.
Includes the controller layout pages, distance-only signal HUD, station
approaches, positional audio and all earlier improvements.

DOWNLOAD OR UPDATE
R38 supports full downloads and incremental updates. If you installed R36 or R37,
close the game and open its included Update and Play.exe to update that folder.
It downloads compressed changed blocks or the full ZIP, whichever is smaller,
and reuses unchanged data. For a fresh installation, extract the complete ZIP,
including packs/, and start TrainGame.exe or the included updater's Play.
Keep the whole installation together.
Saves and preferences live separately
in your Windows user profile. R29 and newer compatible saves remain loadable;
R28 geometry is incompatible, so start a fresh journey if upgrading from R28.

RUN ON ANOTHER PC
1. Download and extract the entire ZIP to a writable folder on your SSD.
2. Open TrainGame.exe. Keep TrainGame.pck, the packs folder and the other files
   beside it. Always extract the complete folder structure.
3. No Godot, Blender, Node.js or development checkout is needed.
4. F11 / Alt+Enter or the menu switches fullscreen/window. New installs start
   fullscreen. Graphics settings and your display choice are remembered.
5. Close the game before running Update and Play.exe for later releases.
   Keep the host PC awake and on the LAN until the download finishes.

START PLAYING
Choose any service on the landing page. K1 is the slow stopping passenger.
The timetable has 100 services, including full-route Vande Bharats in both
directions. Review each service's stops and scheduled timings before starting.
Choose Traffic or press Y for the baseline crossings/overtakes, with times,
locations and other service names. RS scrolls; Y returns to stops. These are
the simulated AI baseline, not fixed promises: your driving can change them.
You begin paused in the pilot seat. Other trains and dispatch run under AI.
Explore by time starts at a prepared five-minute point; join an active service
under AI or visit a station. These states reflect baseline AI traffic history.
Save/Load preserves your own journey; Skip forward advances that journey with
all trains under AI and rendering disabled. See guides/service-selection.md.

XBOX CONTROLLERS (360 / ONE / SERIES / ELITE)
Menu > Controller layout has Driving, Walking, Cameras and Menus pages.
LB/RB changes guide tabs; RS scrolls. Old layouts migrate to the new scheme.

Driving:
RT / LT       Increase / decrease the combined power/brake handle.
              Release to hold. LT has priority if both are held. Crossing coast
              pauses for 0.24 seconds with a light tick; release/re-pull to cross.
B             Horn, including following exterior cameras.
A             Context interaction / confirm.
Y             Stand up (AI takes over) / sit at nearby driver controls.
Tap X         Give driving to AI.
Hold X        Take manual control at coast; release controls before driving.
RB / LB       Reduce power / release brake. Both stop at coast; neither
              enters the opposite range or takes control from AI.
View          Tap dispatch / hold service progress.
Menu          Pause, settings, save/load and remaining train actions.

Cameras and walking:
D-pad L / R   From pilot, matching left/right head-out first, then cycle close,
              far, rear and head-out following views. Driving ownership stays.
Hold L or R   Return to pilot; retains AI/manual state.
D-pad Up/Down Move one passenger carriage toward loco/tail, standing under AI.
Hold Up/Down  Return to locomotive standing. Y sits; hold X takes manual control.
LS / RS       Walk or move within cab/coach / look. L3 toggles walking/running;
              R3 recenters. RB is the torch when walking.
A             Interact, including sitting at a nearby passenger seat.
Y             Stand from a passenger seat. AI continues driving.
Seated L / R  Cycle the same passenger row's left head-out / interior / right.
Free camera   Available through the camera menu; AI drives, RT/LT zoom.

Menus: D-pad/LS focus, A confirm, B back, RS scroll. Emergency brake is available
through the train menu and keyboard Space, with no dedicated controller button.
Disconnecting pauses. Release all controls after resuming before driving again.
See guides/controllers.md and guides/walking.md for the full layout.

HUD AND SIGNALS
Menu > HUD, journey tools & recovery > Next-signal HUD > Distance only hides the
next aspect and clearance cues. Read the physical signal lamps; protection and
dispatch rules are unchanged. Default remains Aspect + distance. Improved lens,
visors and backplates make the lineside signals clearer at distance by day/night.

TRY THIS RELEASE
Select K1 > Traffic (Y), scroll to B001 overtaking at Mararikulam around 09:16,
then select B001 and compare its reciprocal entry. Try a night service's day-2
times. Check stationary shadows with the clock running and paused, and the
shared speed-board posts at station approaches. RB reduces power to coast;
LB releases brake to coast. Neither changes headlights or takes over from AI.

TRY THE CONTROLS
Use RT/LT through coast. Tap X and confirm triggers leave AI in charge. Hold X,
release the controls, then drive. Y -> D-pad Down -> A at a passenger seat should
let you walk/sit while AI drives. Try both row head-outs. Hold Up -> Y -> hold X
returns you to manual driving. Check guide tabs and the Distance only HUD option.

SAVE, AUDIO AND RECOVERY
Save and Load journey are available from Pause; the landing page has Saved
journeys and Continue latest save. Save before changing service or quitting.
Journey tools include three rotating recovery saves, route-ahead information,
view bookmarks and a local diagnostic ZIP. Audio settings provide presets and
separate layer volumes. AI-driven platform departures have two horn calls
3.5 simulation seconds apart; manual driving uses your horn button.
See guides/journey-audio-and-comfort.md.

GRAPHICS AND BENCHMARK
Menu > Graphics settings has individual settings and Performance/Balanced/High
presets. F10 shows frame and streaming diagnostics. For the standard benchmark,
open Run Performance Benchmark.cmd and allow 10-20 minutes with the game focused.
Send back Documents/TrainGame-Benchmark-<date-time>.zip when it finishes.
For single resolutions and the five-loaded-train test, see guides/performance.md
and guides/crowded-benchmark-2026-10-10.md. The target PC is i9-13980HX with
RTX 4090 Laptop 16 GB VRAM and 64 GB RAM. Development-PC checks do not certify
performance on that target. First launch may take time preparing shaders.

DISPLAY AND TROUBLESHOOTING
Windows 10/11 64-bit with a Vulkan-capable driver is required for Forward+.
Do not run the game inside the ZIP. The executable is an unsigned development
build. The existing native-crash investigation remains unresolved. Recovery
saves limit lost progress; retain diagnostic logs if another crash occurs:
%APPDATA%\Godot\app_userdata\Train Game\logs\godot.log
Also include journey-current.jsonl and journey-previous.jsonl from that folder.
These small local logs record location/streaming periodically without a debugger;
they do not replace a crash dump. A capture launcher is available on the LAN site.

PERSONAL PLAYTEST COPY
The approved track sound derives from the user's reference recording and is
registered for personal use only. This package is for use on your own PC.
Engine hum, traction and horn are enabled; track sound retains the approved bank.
The Kerala map is a reconstruction, not a surveyed operating diagram.
Map data (c) OpenStreetMap contributors, ODbL 1.0; NASA/USGS SRTM terrain.
See MAP-DATA-LICENSE.md, ASSET-SOURCES.md and ENGINE-LICENSES.txt.
Detailed feature guides and timetable evidence are in the guides folder.
