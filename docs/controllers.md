# Xbox controller

Fullscreen: press Menu and choose **Fullscreen / Windowed** (second item after
Resume). The preference is saved. Keyboard F11 or Alt+Enter works in menus too.

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
| Right-stick click | External **free** camera; repeated clicks stay in free camera |
| Left stick | Cab zoom; exterior pan; on foot walk / strafe |
| Left-stick click | Return directly to the pilot seat, including from walking |
| Hold right-stick click + left stick up / down | Zoom the free exterior camera |
| D-pad up / down | Select driving end at rest, where supported |
| View / Back | Tap dispatch; hold journey progress |
| Menu / Start | Pause / back |

LT takes priority. RB stops at coast without applying a brake; LB releases a
brake without applying traction. RT moves the combined handle toward power,
including out of its braking range. Release controls to hold the selected handle.
An intentional driving-handle input takes over from AI. View-only camera presets
preserve AI; the existing cab/exterior toggle enters manual driving on return.

The camera cycle is pilot → left head-out → right head-out → WAP-7 assistant
seat / cab overview / machinery aisle (where supported) → first / middle / last
passenger coach → following exterior → free exterior → pilot. Left reverses
the cycle. Switching with keyboard or menus updates the cycle's starting point.
Free exterior stays fixed in the world until you pan it; LS pans and RS orbits.
These three shortcuts apply in both layouts and on foot, while menus and dispatch
retain D-pad navigation. They preserve your service, AI setting and driving handle.

On foot, RT runs, A uses the displayed seat/doorway/gangway/platform prompt, B
crouches and D-pad up toggles a headlamp. Walking inputs cannot alter traction. See [walking.md](walking.md)
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
| LB / RB | Zoom out / in |
| Right stick click | External free camera |
| Left stick | Pan outside; left/right moves through passenger positions |
| Left stick click | Return to pilot |
| D-pad left / right | Previous / next camera, same cycle as the default layout |
| D-pad up / down | Pilot/head-out: up returns pilot; otherwise up first coach; down last coach |

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
