# Xbox controller

Save/Load: press Menu and choose **Save journey**, **Load journey** or **Quick save**.
D-pad / left stick selects; A activates; B goes back. Load/overwrite confirmations
start on Cancel. Loaded journeys remain paused until Resume. See [Save/Load](save-load.md).

Fullscreen: press Menu and choose **Fullscreen / Windowed**.
The preference is saved. Keyboard F11 or Alt+Enter works in menus too.

Uses Godot's standard gamepad mapping for Xbox 360, One, Series and Elite pads.
Connect over USB or a Windows-supported wireless connection before or during play.
Elite paddles use the buttons assigned in the controller's own profile. The Xbox
Guide button remains a Windows function. No additional game driver is required.

## Default: TSW-style immersive

Based on Dovetail's [Train Sim World Controls Guide](https://support.dovetailgames.com/hc/en-us/articles/36105734473234-Train-Sim-World-Controls-Guide)
(consulted 8 October 2026). Train Game uses one combined power/brake handle, so
the power/brake buttons operate that handle; it does not simulate TSW's separate
train-specific handles or every cab instrument interaction.

| Control | Action |
| --- | --- |
| RT / RB | Increase / reduce power |
| LT / LB | Apply / release brake |
| Y | Stand up / sit near a seat |
| A | Use displayed on-foot interaction |
| B | Back / cancel in menus |
| X tap | Open Train & view actions |
| X held + A / B / RB / Y | AI/manual / emergency brake / coast / horn |
| Right stick | Look / orbit |
| D-pad left / right | Previous / next camera, wrapping through all available views |
| Right-stick click | External **free** camera at passenger eye height on the nearest open station platform |
| Left stick | Move around the cab (enter walking); free-camera movement; on foot walk / strafe |
| Left-stick click | Return directly to the pilot seat, including from walking |
| Hold right-stick click for 0.65 s | Toggle free-camera triggers between zoom and train control; release controls to arm |
| D-pad up / down | Forward / back one passenger coach, stopping at the pilot / last coach |
| Free-camera RT / LT | Optical zoom in / out by default |
| Free-camera RB / LB | Raise / lower viewpoint while triggers are in zoom mode |
| View / Back | Tap dispatch; hold journey progress |
| Menu / Start | Pause / back |

LT takes priority. RB stops at coast without applying a brake; LB releases a
brake without applying traction. RT moves the combined handle toward power,
including out of its braking range. Release controls to hold the selected handle.
An intentional driving-handle input takes over from AI. View-only camera presets
preserve AI; the existing cab/exterior toggle enters manual driving on return.

Fresh scenarios start in the pilot seat; loading a save restores its viewpoint.
The camera cycle is pilot → right head-out → WAP-7 assistant
seat / cab overview / machinery aisle (where supported) → first / middle / last
passenger coach → following exterior → free exterior → left head-out → pilot. Left reverses
the cycle. Switching with keyboard or menus updates the cycle's starting point.
Thus the first press from pilot always goes to the head-out on the pressed side.
Up/down visits every passenger coach in formation order, skipping non-passenger
vehicles and respecting the driving end. Neither end wraps. This also works on foot.
Free exterior stays fixed in the world until you move it; LS moves and RS turns
at your eye. Entering it places you on an open station platform near the previous
viewpoint. RT/LT change the lens without moving you. Repeated short RS clicks
keep your position. Hold RS to switch RT/LT back to train control; the HUD names
the current trigger function. A held trigger never transfers directly into driving.
L3 returns to pilot and requires release if you were holding a zoom/run trigger.
Moving LS in the cab stands into the existing cabin navigation, with desk/wall
clearance; it preserves the handle and AI. Y still stands/sits explicitly.
These three shortcuts apply in both layouts and on foot, while menus and dispatch
retain D-pad navigation. They preserve your service, AI setting and driving handle.

On foot, RT runs, A uses the displayed seat/doorway/gangway/platform prompt, B
crouches and X + D-pad up toggles a headlamp. Walking inputs cannot alter traction. See [walking.md](walking.md)
for keyboard equivalents, current door transitions and a complete playtest.

## Optional previous Train Game layout

Select **Controller settings & layout → Layout** to restore these bindings.
While on foot, the walking bindings above apply in both layouts. Use Menu →
Train & view actions → Camera & passengers → Stand up / sit down to leave a seat
in the legacy layout.

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
| LB / RB | Zoom out / in; lower / raise in free-camera zoom mode |
| Right stick click | External free camera |
| Left stick | Move inside cab; pan outside; left/right moves through passenger positions |
| Left stick click | Return to pilot |
| D-pad left / right | Previous / next camera, same cycle as the default layout |
| D-pad up / down | Forward / back one passenger coach, stopping at pilot / tail |

Both layouts use RT/LT for free-camera zoom by default. Hold RS for 0.65 s to
toggle train control, then release all controls before using the new function.

Triggers adjust the handle at a rate proportional to their deflection. Release
them to hold the handle. LT takes priority if both are pressed. A deliberate
trigger input takes over from AI. The middle coach is available under
Menu → Go to passenger coach. Choose a preset, or Go to any passenger coach
for the numbered list. This works while moving behind a WAP-7. Y stands inside;
left-stick click returns to pilot without changing your driving assignment.
Non-passenger vans are skipped.

## Menus and dispatch

D-pad or left stick moves menu focus; A selects and B goes back. In the dispatcher,
LS pans the map, LT/RT zoom, D-pad selects targets, LB/RB switches desk areas,
X locates the inspected train and Y fits the whole route. In dropdowns,
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

Menu → Controller settings & layout selects TSW-style/legacy and adjusts stick deadzone, look sensitivity,
vertical inversion and vibration strength. Settings persist in
`user://controller.cfg`. Emergency braking produces a brief vibration where the
Windows connection supports it; connection-specific vibration needs hardware testing.

One controller owns driving at a time. Other pads do not move the selected train.
Disconnecting the active pad or losing application focus pauses the game.
Reconnecting does not resume it. After menus close or focus returns, release the
sticks, triggers and buttons before applying driving input. Keyboard and mouse
remain available and replace the controller hints when used.

## Playtest

1. In the legacy layout, start a fresh scenario with the pad connected. Check RT/LT partial
   input, releasing to hold, X coast, A AI takeover and B emergency/release.
2. Cycle every camera in both directions with D-pad left/right. L3 must return
   to pilot and R3 to free exterior from each view. Leave the train moving under
   AI: free camera stays behind; following exterior follows it. Stand up and
   repeat the shortcuts; verify a held run trigger cannot become traction.
   From pilot, Right must first choose right head-out and Left the left one.
   Step Down through the full rake, then Up to pilot; neither end wraps.
   Move LS in the cab and check movement around the desk; L3 returns to the seat.
   R3 should place you on a nearby platform. RT/LT zoom without changing power;
   hold R3 to switch to driving, release everything, then use a fresh trigger.
   Hold R3 again to restore zoom. RB/LB raise/lower the free camera in zoom mode.
3. Navigate Help and settings without the mouse. Scroll the text and all pause
   buttons. Change a setting, restart the game, and check that it persists.
4. Open dispatch using View (default layout) or Train & view actions. Select a signal and destination, set a safe route, put it
   to red, switch services and view the timetable. Try a locked point: it must refuse.
5. Hold RT while pausing/resuming: the handle must wait for release and a fresh
   press. Disconnect/reconnect while moving, then Alt-Tab: the game must pause.
6. Cancel restart/quit with B and use keyboard Space after closing the desk.

Automated checks inject standard-layout events into the real Godot viewport and
exercise the game, native dropdowns and focus navigation. They do not substitute
for testing a physical pad, its wireless driver, vibration or the feel of the controls.
