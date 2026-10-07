# Xbox controller

Uses Godot's standard gamepad mapping for Xbox 360, One, Series and Elite pads.
Connect over USB or a Windows-supported wireless connection before or during play.
Elite paddles use the buttons assigned in the controller's own profile. The Xbox
Guide button remains a Windows function. No additional game driver is required.

## Driving and cameras

| Control | Action |
| --- | --- |
| RT / LT | Increase / decrease the combined power/brake handle |
| A | Toggle AI/manual driving |
| B | Emergency brake; press again at a stand to release |
| X | Coast |
| Y | Cab / exterior |
| View / Back | Passenger / cab |
| Menu / Start | Pause / back |
| Right stick | Look in cab/passenger; orbit outside |
| LB / RB | Zoom out / in |
| Right stick click | Centre look; restore follow outside |
| Left stick | Pan outside; left/right moves through passenger positions |
| Left stick click | Open / close dispatch |
| D-pad left / right | Pilot/head-out: lean out left/right or return; other views: previous/next coach |
| D-pad up / down | Pilot/head-out: up returns pilot; otherwise up first coach; down last coach |

Triggers adjust the handle at a rate proportional to their deflection. Release
them to hold the handle. LT takes priority if both are pressed. A deliberate
trigger input takes over from AI. The middle coach is available under
Menu → Passenger views. Non-passenger vans are skipped.

## Menus and dispatch

D-pad or left stick moves focus; A selects and B goes back. LB/RB moves between
controls, including between route selectors and service buttons. In dropdowns,
LB/RB moves by a page. B closes a dropdown before closing the desk. The right
stick scrolls Help/settings and the timetable, including its horizontal columns.
View/Back switches the open dispatch desk between map and timetable.

Menu → Train & view actions contains the other commands: horn, change ends,
next signal routes, manual point control, station views, seat/aisle, original LHB
berths, simulation speed, train protection, event history and sound diagnostics.
The sound/diagnostics group also exposes the live performance overlay (F10).
Manual point control uses the same occupancy and route locks as mouse input.
The pause menu also exposes display settings, all fleet choices, restart and quit.

## Settings and safety

Menu → Controller settings & layout adjusts stick deadzone, look sensitivity,
vertical inversion and vibration strength. Settings persist in
`user://controller.cfg`. Emergency braking produces a brief vibration where the
Windows connection supports it; connection-specific vibration needs hardware testing.

One controller owns driving at a time. Other pads do not move the selected train.
Disconnecting the active pad or losing application focus pauses the game.
Reconnecting does not resume it. After menus close or focus returns, release the
sticks, triggers and buttons before applying driving input. Keyboard and mouse
remain available and replace the controller hints when used.

## Playtest

1. Start a fresh six-service scenario with the pad connected. Check RT/LT partial
   input, releasing to hold, X coast, A AI takeover and B emergency/release.
2. Use Y, both sticks, bumpers and stick clicks. Use D-pad first/last/next/previous
   coach, then Menu → Passenger views → Middle. Compare camera and audio positions.
3. Navigate Help and settings without the mouse. Scroll the text and all pause
   buttons. Change a setting, restart the game, and check that it persists.
4. Open dispatch with L3. Select a signal and destination, set a safe route, put it
   to red, switch services and view the timetable. Try a locked point: it must refuse.
5. Hold RT while pausing/resuming: the handle must wait for release and a fresh
   press. Disconnect/reconnect while moving, then Alt-Tab: the game must pause.
6. Cancel restart/quit with B and use keyboard Space after closing the desk.

Automated checks inject standard-layout events into the real Godot viewport and
exercise the game, native dropdowns and focus navigation. They do not substitute
for testing a physical pad, its wireless driver, vibration or the feel of the controls.
