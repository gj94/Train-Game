TRAIN GAME - KERALA COAST R45

R45: Easier journey discovery, passenger boarding and controller navigation.
Favourites, stock/full-route filters and remembered departure choices. Explore
by time offers passenger boarding and nearby services within 15 km of a station.
Native dropdowns: A confirm, B cancel, LS/D-pad move, LB/RB page choices.
Controller layout has a Journeys tab explaining the new browsing controls.
Home includes the full sound mixer and controller preferences. Continue previews
your saved service, time, seat and progress, including backup recovery.
Cancelled/failed loads return to the initiating menu with visible feedback.
Required recovery saves verify before leaving or loading another journey;
failed writes retain your railway and offer cancel, retry or explicit discard.
Coach directories show class and free seats; find an empty seat or recall your
remembered seat. Dispatcher tags are clearer, with an overview at wide zoom.
Simulation and prepared timetable data are unchanged from R44.
See guides/journey-library.md for detailed controls and playtest steps.
R45 supports full downloads and incremental updates through Update & Play v4.

Includes R44: New home screen, passenger seat memory and forward scenery preparation.
Choose a journey, continue, explore by time or configure graphics/controller
options before loading the railway. The service browser remembers your choices.
Sitting remembers a passenger seat. Hold R3 while seated to update it (including
look direction); hold R3 elsewhere to return with AI driving. Tap R3 recentres.
Keyboard End returns; Shift+End remembers. Skip ahead can return you to the same
seat after an event, time or stop skip. Toggle this in Skip ahead / Settings.
Scenery prepares hidden sections along your train's route with bounded memory.
The visible draw distance is unchanged. Very fast travel can still need loading.
Simulation and prepared timetable data are unchanged from R43.
See guides/streaming-and-passenger-qol.md and guides/controllers.md.
R44 supports full downloads and incremental updates through Update & Play v4.

Includes R43: A new pause hub, clearer dispatcher and more informative loading.
Pause has Journey / Train & camera / Settings / Reference / Session sections.
LB/RB changes sections, D-pad/LS navigates, A selects and B returns/resumes.
Keyboard Q/E changes sections. Each section remembers the selected action.
Dispatch: X finds YOUR train, Y follows the inspected train, LB/RB moves between
map, service list, inspector and activity. Triggers zoom while the map is focused.
Your train is blue and labelled YOU. View train does not hand over your service.
Loading now shows station preparation, queued/building/attaching scenery and
elapsed time. Final scene attachment gets more time while the loading screen is up.
Simulation and all prepared timetable data are unchanged from R42.
See guides/menu-qol.md and guides/controllers.md.
R43 supports full downloads and incremental updates through Update & Play v4.

Includes R42: Correct main-line speeds beside depot junctions and stationary departure horns.
Shared depot-access track follows the adjoining running-line speed; the 25 km/h
restriction applies to the diverging depot lead, with 15 km/h inside the yard.
A whole train must clear the restricted track before accelerating.
AI passenger trains sound both departure calls before moving, including your
service after handing driving to AI. Booked departure, doors and route clearance
must permit departure first. Manual takeover cancels the automatic sequence.
Previously cleared starters retain their departure order, preventing a later
advisory overtake hold from trapping trains behind the same reserved route.
Arriving trains are distinguished from trains waiting to depart, so temporary
approach occupancy does not cancel a promised overtake (K1/B024 at Alappuzha).
R41 saves and imported service plans remain compatible with this speed correction.
R42 supports full downloads and incremental updates through Update & Play v4.

Includes R41: Skip to the next event with a live dispatcher following your train.
Pause > Journey > Skip ahead. Settings > Time-skip events selects stop
approaches, crossings, overtaking, being overtaken and signal clearance separately.
Stops return at 1 km or earlier for braking; encounters return about a minute
before the first coaches pass. A holding red changing to yellow or green counts.
Safety and service completion always interrupt event searches. Return paused
with AI still driving, then take control when ready. B / Esc cancels safely.
Clock and future-stop targets remain available. See guides/event-skip.md.

Includes the optional Epic graphics preset, integrated with R39 scenery fixes.
Open Pause > Settings > Graphics & performance > Use Epic preset. High remains the default.
Epic adds filtered surface detail on terrain, roads, platforms, track and water,
sharper sky reflections, nearby station-lamp shadows and longer detail ranges.
All effects can be adjusted individually. Dense nighttime stations cost more GPU
time; disable Nearby station lamp shadows first if needed. Screen-space
reflections remain off by default. See guides/extreme-visuals.md.
Connected overhead equipment, road bridges and station clearances are retained.
Authored service times and sound banks are retained; prepared railway states
and traffic previews are regenerated for R42 departure and line-speed changes.
The included v4 updater supports signed, verified incremental LAN updates.

Includes the detailed sound mixer, alternate operating day and safer route allocation.
Use Operating day on the home page to choose Standard (100 services) or
Intensive (140 services). Each has its own departures, five-minute railway
states and simulated crossings/overtakes preview. K1 is the slowest scheduled
service in Intensive, with 14 distinct overtaking trains in its
validated AI baseline. Manual driving changes the actual encounters.
Sound settings separately control rail hiss, joint clacks, squeal, own wind,
passing air, floor thumps, metallic rattles, motors, fans, horns, compressor,
ventilation, footsteps, doors and brake air. Existing mixer settings migrate.
Through VBs prefer the clear main at Trivandrum North. Receiving-road checks
preserve platforms needed by approaching trains, and future crossing plans
cannot depend on a train continuing beyond its final station.
Wait quality is audited across the day: at least 70% of meaningful extra waits
under 10 minutes, 90% under 20, 98% under 30 and all under 45. Ten minutes is
not a hard signal timeout. Slow passengers may accumulate substantial lateness
while yielding; existing route and crossing protections always apply.
These are whole-day targets, not a guarantee for each manually driven journey.

Includes forward planning for station crossings and earlier home clearance.
The dispatcher can reserve a future platform after an overdue AI train leaves,
while protecting the opposing arrival and the departing train's escape.
Manual driving disables automatic departure horns; your horn button still works.
AI-driven passenger services finish both departure calls before moving.
Includes R35's simulated crossings and overtakes on the home page,
smoother moving-clock sunlight/shadows, consolidated lineside speed boards,
and driving RB/LB for power reduction/brake release, both stopping at coast.
Includes the controller layout pages, distance-only signal HUD, station
approaches, positional audio and all earlier improvements.

DOWNLOAD OR UPDATE
R45 supports full downloads and incremental updates. For an older installation,
download the small updater ZIP from the host page and replace Update and Play.exe
once while the updater is closed. The title identifies the v4 launcher.
Then close the game and open Update and Play.exe to update the existing folder.
It batches verified compressed blocks, uses four bounded transfer workers and
reuses unchanged data. It can choose the full ZIP if that should finish sooner.
The full R45 ZIP includes v4. For a fresh installation, extract the complete ZIP,
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
The selected day has 100 or 140 services, including full-route Vande Bharats in both
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
