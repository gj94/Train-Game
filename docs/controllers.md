# Xbox controller

Current source controls (after R34). Xbox 360, One, Series and Elite use Godot's
standard layout. Elite paddles follow the controller's own assigned buttons.

Open **Menu → Controller layout** for separate **Driving**, **Walking**,
**Cameras** and **Menus** pages. LB/RB switches tabs, RS scrolls, A selects and
B returns to the caller. Controller preferences retain deadzone, look sensitivity,
vertical inversion and vibration. Old layout preferences migrate to this scheme.

## Driving

| Input | Action |
| --- | --- |
| RT / LT | Increase / decrease the combined power/brake handle |
| B | Horn, including following exterior views |
| Tap X | Give driving to AI |
| Hold X (0.65 s) | Take manual control at coast; release inputs before driving |
| Y | Stand up; AI takes over |
| A | Context interaction / confirm |
| RB | Reduce power toward coast; never applies braking |
| LB | Release braking toward coast; never applies power |
| Menu | Pause, save/load, settings and remaining actions |
| Tap View / hold View | Dispatch / service progress |

Hold a bumper to reduce its matching range; release to hold. Bumpers stop at
coast, override simultaneous triggers and never take control from AI. Walking
keeps RB as the torch; headlights no longer use a driving bumper.

Released triggers hold the selected handle. LT wins simultaneous trigger input.
Crossing zero pauses at coast for 0.24 seconds with a light vibration. Continue
holding to cross, or release/re-pull to cross immediately. Triggers never silently
take driving from AI. There is no emergency-brake face/bumper binding; it remains
in Menu → Train & view actions and on keyboard Space.

## Walking and passenger seats

| Input | Action |
| --- | --- |
| LS / RS | Walk and strafe / look |
| L3 | Toggle walk/run |
| A | Interact, sit in an available passenger seat, use doors and gangways |
| Y | Stand from a seat, or sit at nearby driver controls |
| RB | Torch |
| D-pad Down / Up | Move one passenger carriage toward tail / locomotive, standing |
| Hold either Up/Down (0.65 s) | Return to locomotive standing |

Getting up, changing carriage and entering free observer view give driving to AI.
Returning to the driver's seat leaves AI enabled until explicit takeover. Taking
manual control is blocked on foot or in a passenger viewpoint. D-pad transfers
work in a moving WAP formation despite the lack of a physical locomotive gangway.
The end of the rake does not wrap. Vertical order follows the active driving end.

At a passenger seat, D-pad Left/Right cycles the row's left head-out, interior and
right head-out. It preserves the selected coach and seat. Y stands up. At a stopped
platform, use A at the appropriate doorway to board/alight.

## Cameras

From pilot, the first D-pad Right is right head-out and the first Left is left
head-out. Subsequent horizontal taps cycle only these following views:

Right head-out → close exterior → far exterior → rear of train → left head-out.

The cycle wraps; holding either horizontal direction returns to pilot. It does
not visit passenger or free cameras. These camera changes preserve driver/handle.
LS changes distance and angle in a following exterior view without detaching.
RS looks/orbits; R3 recenters. Up/Down enters carriage walking as described above.
L3 does not move you to pilot, and R3 does not select free camera.

Free observer view is under Camera & passengers in Train & view actions. It starts
at the nearest station platform; LS moves, RS looks and RT/LT zooms. AI drives.
Hold horizontal D-pad to return to pilot. Holds execute without first firing taps;
focus loss, pauses and reconnects cancel incomplete gestures.

## Menus and dispatch

D-pad/LS navigates, A confirms, B goes back, RS scrolls, LB/RB changes focus areas.
In Dispatch, LS pans, triggers zoom, D-pad selects a target, A inspects, X locates,
Y fits the route and View opens the timetable. Inspecting another train does not
hand over your service. Save/load and fullscreen remain under Pause.

The HUD indicates AI/manual ownership. A hold-progress panel explains pending
X, View and D-pad gestures. Disconnect/focus loss pauses; release controls before
resuming. Keyboard and mouse remain available.

## Signal HUD

Pause → **HUD, journey tools & recovery → Next-signal HUD** chooses
**Aspect + distance** (existing default) or **Distance only**. Distance-only mode
has a neutral distance readout with no aspect word/colour. It also suppresses
proceed notifications/chimes and automatic return to ×1 on clearance, which would
otherwise reveal the hidden aspect. Dispatch remains a complete operational view.
The preference persists independently of saved journeys.

## Validation and playtest

The current source-scene regression is `tools/check_controller_qol.gd`, supporting
`--fleet=lhb`, `icf`, `vb8` and `vb16`. The camera/navigation entry points delegate
to it. Walking geometry/acoustics retain their separate fixture. Headless tests
cover handle shaping/detent, ownership, menu parents and signal presentation.

On a physical controller: cross coast slowly in both directions; check the vibration
and hold duration. Stand with Y, walk, tap Down through coaches, sit using A and
try both row head-outs. Hold Up to the loco, Y to sit and X to take over. Check that
following views retain manual driving. Read all guide tabs and try distance-only
signals in daylight/night. Synthetic event tests do not validate physical pad feel.
