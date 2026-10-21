# Xbox controller

Current source controls (R45). Xbox 360, One, Series and Elite use Godot's
standard layout. Elite paddles follow the controller's own assigned buttons.

Open **Pause → Reference → Controller layout** for separate **Driving**, **Walking**,
**Cameras**, **Menus** and **Journeys** pages. LB/RB switches tabs, RS scrolls, A selects and
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
in Pause → Train & camera → Driving actions and on keyboard Space.

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
RS looks/orbits; tap R3 recenters. Up/Down enters carriage walking as described above.
L3 does not move you to pilot, and R3 does not select free camera.

Hold R3 to return to your remembered passenger seat with AI driving. Sitting
remembers the seat automatically; holding R3 while seated updates it and saves
the current look direction. Each service has its own seat, included in saved
journeys. End returns and Shift+End remembers on keyboard. Skip forward can
return you to the same passenger seat; change this on the skip menu or in its
settings. If the service finishes, you return to the platform instead.

Free observer view is under Pause → Train & camera → Cameras & walking. It starts
at the nearest station platform; LS moves, RS looks and RT/LT zooms. AI drives.
Hold horizontal D-pad to return to pilot. Holds execute without first firing taps;
focus loss, pauses and reconnects cancel incomplete gestures.

## Menus and dispatch

Pause has five sections: Journey, Train & camera, Settings, Reference and Session.
LB/RB changes section and remembers your last action in each. D-pad/LS moves,
A selects, B returns one level or resumes from the hub. Keyboard Q/E changes
sections, arrows/Enter navigate, and Esc follows the same submenu parent.

Dispatch has four focus areas: map/timetable, services, inspector and activity.
LB/RB moves between them; each remembers its last visible control. X (also L3)
returns to **your assigned train**, clears filters that might hide it and centres
the map at a useful local zoom. Y toggles following the **inspected** train and
returns to the map. Moving the map stops following. View switches the timetable.

On the map, LS pans, LT/RT zooms and D-pad chooses a visible target; A inspects.
In the other areas, D-pad/LS navigates controls and RS scrolls that area's content.
Your train is blue and marked YOU; other trains are amber, with their full occupied
length shown. Service filters offer Active, Waiting and All. Dispatch tools expand
inside the inspector. Viewing another train preserves assignment; taking control
and deleting a train retain separate confirmation screens.

The HUD indicates AI/manual ownership. A hold-progress panel explains pending
X, View and D-pad gestures. Disconnect/focus loss pauses; release controls before
resuming. Keyboard and mouse remain available.

Home and departure browsers use the same A/B and LS/D-pad navigation. In a
stock, timetable, sort or station dropdown, A commits, B cancels and LB/RB page
through the available choices. Shoulder presses stay inside that dropdown.
Explore by time: LB/RB steps five minutes when no picker is open; X finds the
selected service, Y fits the route. D-pad right from the roster enters the map;
left from the map returns to the roster. Near station filters services within
15 km along the railway. A on a roster inspects before an explicit boarding action.

Passenger menus include Choose coach (class/free seats), Find an empty seat and
Return to saved seat. Choosing a carriage stands you in its aisle with AI driving.
See [journey library](journey-library.md) for Home settings, favourites, passenger
boarding, recovery feedback and playtest steps.

## Signal HUD

Pause → **Settings → HUD, recovery & tools → Next-signal HUD** chooses
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
