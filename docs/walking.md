# Walking inside the train and on platforms

Press **E** on keyboard or **Y** with the default Xbox layout to get out of the
driver's or passenger's seat. Walk through the cab, machinery aisle, passenger
aisles and vestibules. Nearby seats and interior passages display an interaction
prompt. The WAP-7 has no passenger gangway: use a passenger camera preset to enter
its coaches, or step out onto a platform at a stop and board a coach doorway.
The Kerala route supports platform walking beside your assigned train.

You can transfer to **any passenger coach while moving**, including behind a
WAP-7: open Pause/Start → **Go to passenger coach…** → **Go to any passenger coach…**,
select Coach 1–20/22, then
move **LS** to move around inside immediately, or press **Y/E** to stand explicitly.
The same list is under Camera & passengers. D-pad Down/Up selects each coach in
order; LS translates continuously inside that coach and RS looks around. Your
position follows its movement and rotation instead of staying behind in the world.
This changes your viewpoint without handing over your service or changing the
power/brake handle or AI setting. **Left-stick click / 4** returns to the pilot.
For quick access, D-pad left/right cycles the first, middle and last coach views;
keyboard Alt+1/2/3 does the same. Physical alighting remains restricted to a stop.

From the WAP driver's seat at ERS: keep manual control with the brake applied,
press **Y/E**, then face the cab side door beside the platform. Use **A/left
click** at **Step onto platform**, walk back along the train and board **coach 1**.
There is no walkable end connection through the locomotive coupler. The cab
prompt and F1 help now explain this; the locomotive is not counted as coach 1.

## Controls

| Action | Keyboard / mouse | Xbox, either layout while on foot |
| --- | --- | --- |
| Walk / strafe | WASD | Left stick |
| Look | Right-drag, direction stays on release | Right stick |
| Run | Hold Shift | Hold RT while moving |
| Crouch / stand | C | B |
| Sit near a seat | E | Y |
| Use displayed seat / interior doorway / gangway | Left click | A |
| Headlamp | L | Hold X + D-pad up |
| Dispatch | 9 | Tap View / Back |
| Service progress | F12 | Hold View / Back |
| Return to pilot | 4 | Left-stick click |
| External free camera | Tab, then pan to detach | Right-stick click |
| Cycle all cameras | Camera & passengers menu | D-pad left / right |
| Move viewpoint one coach toward loco / tail | PgUp / PgDn | D-pad up / down (Up ends at pilot) |

| Left head-out | Q | Left-stick click, then D-pad left |
| First / middle / last passenger coach | Alt+1 / Alt+2 / Alt+3 | Cycle with D-pad or Camera & passengers menu |

From the pilot seat or any passenger viewpoint, moving the left stick enters
continuous interior movement with no extra button. This includes a coach selected
with D-pad Down/Up, camera cycling or the passenger menu. The baked clearance keeps
movement out of walls and desks; left-stick click returns to the pilot. Explicit
Y/E standing and sitting remain available. Use A at interior-doorway prompts.

On keyboard **Shift+E** now selects the right head-out view; Q still selects the
left. The default controller layout follows TSW's immersive contexts; see
[controllers.md](controllers.md) for driving, shared camera shortcuts and the legacy option.

Getting up and sitting down preserve the driver and the latched power/brake
handle. Enable AI before leaving the controls if you want it to drive. Walking
does not pause the railway; dispatch and all other trains keep running. In the
default controller layout, X+A explicitly toggles AI and X+B explicitly applies
emergency braking. Menu → Train & view actions has these commands in both layouts.
Release walking keys/sticks/triggers when returning to driving or closing a menu.

At a stand, walk up to an exterior door on the platform side and look toward it.
Use **A / left click** when **Step onto platform** appears. Walk along the
platform, face another doorway and use **Board coach…**. The train and dispatcher
keep running; enabling AI can make your train leave while you remain outside.
Boarding requires your train to be stopped beside you. Camera shortcuts can
return to your train; boarding does not change your driving assignment.

Platform edges, columns, benches, signs and waiting passengers constrain walking.
Through roads without passenger faces cannot be used to alight. Exterior doorway
positions come from all 22 original Blender masters, including reversed VB cars.
Platform walking currently covers the geographic Kerala route and carriages of
your assigned service; it does not cross tracks, use footbridges or board other
services. Use the dispatcher handover to change service.

R12 animates platform-side passenger doors during scheduled exchanges. Interior
doors and locomotive cab doors remain static artwork. Where a closed door or a
narrow doorway blocks the body, a prompt takes you through with a short fade.
Gangways also use this transition. Jumping and clickable cab instruments are not
included. Cab controls remain available from the existing driving input/menu.

## Implementation and source

`train_walk.gd` stores position inside the individual articulated vehicle. The
camera uses that car's interpolated transform, including reversed VB cars and
geographic origin shifts. The sound listener follows the walked position in the
same axle/joint coordinate system as seated views. No audio bank is regenerated.

`platform_navigation.gd` matches the geographic platform renderer in metre space;
the outside camera belongs to the platform, not to a moving car. It follows
floating-origin shifts. `platform_walk.gd` validates door side, platform extent,
speed, nearby standing clearance and boarding distance at interaction time.
`tools/blender/exterior_door_census.py` rebuilds `data/interiors/exterior_doors.json`
from hash-checked Blender masters in a separate background process.

`data/interiors/walkways.json` contains 8 cm floor and clearance grids for all
22 active detailed masters: WAP-7, fourteen ICF/LHB classes and seven VB car models.
`tools/blender/bake_interior_walkways.py` reads the pinned original masters in
background Blender, with embedded scripts disabled and source blob hashes checked.
It tests the evaluated visible geometry against a 16 cm body radius, 1.72 m
standing height and 1.08 m crouching height. Structural floors are two-sided,
including source slabs with reversed winding. LHB/ICF compartment side-door hints
come from the actual named door headers. Source hashes accompany each grid.

Runtime sweeps are shorter than one cell, block diagonal corner cuts and floor
steps over 21 cm, and slide along furniture. Disconnected room results are cached;
tiny isolated floor fragments cannot be standing or gangway destinations. Axial
room transitions join nearby clear spaces across the partition; lateral
compartment transitions require a source door header. Detailed visual meshes are
unchanged and are not instantiated as triangle collision bodies.

Rebuild with background Blender after downloading the pinned source masters using
the existing coach/VB/WAP source tools:

```powershell
& .local/blender/blender-5.2.1-windows-x64/blender.exe --background --factory-startup --python tools/blender/bake_interior_walkways.py
```

The JSON is explicitly included in the Windows export preset. Tests cover wall
sweeps, corners, floor steps, crouch clearance, all model profiles, seat standing
space, WAP machinery access and compartment door metadata. The native integration
harness uses `tools/check_walking_playable.gd -- --fleet=icf` (also `lhb`, `vb8`,
`vb16`; `--kerala` checks the default geographic scenario) to check the actual camera, sound listener, seating, controller contexts
and coach transitions. Legacy controller/menu/dispatch coverage remains separate.

## Playtest

R12 adds seated and boarding passengers. Occupied seats cannot be selected for
sitting. Passenger doors animate during scheduled Kerala stops, and traction
waits for the exchange to finish. Dynamic NPCs do not physically block the player.
See [Passengers](passengers.md) for behaviour, controls and remaining limits.

1. In the starting WAP-7, press Y/E, turn around, and approach the machinery door.
   Use A/left-click at the prompt. Return through it and sit back down with Y/E.
2. Enable AI using X+A (or keyboard A before standing), enter the first/middle/last
   passenger coach, stand, walk and run down the aisle. Seats and partitions should
   stop you. Crouch and try the headlamp; sit in a different seat.
3. At a coach end, look toward the next coach and use the gangway prompt. Turn
   around and return. Repeat in VB8/VB16, where the second half faces the other way.
4. Walk while the train moves and while using fast forward. The view should stay
   attached to the same coach without sliding or rail-joint sound offset.
5. Open dispatch/pause while holding RT, then close it. Release controls before
   moving again. Sit while holding W or RT: the train handle must stay unchanged
   until the control is released and deliberately pressed again.


## Passenger seats and row head-out views

Sitting in a passenger seat automatically hands driving to AI. While seated,
traction, brake, horn, reverser and AI/manual shortcuts cannot operate the train.
Stand with E / controller Y (or move the left stick from the seated interior)
before resuming normal input. AI stays in charge until an explicit takeover;
standing never silently cuts its power or brakes.

From the passenger seat, D-pad left/right cycles left head-out, the same seat,
and right head-out. Keyboard Q and Shift+E choose the two sides; pressing the
same head-out shortcut again returns inside. Both views use the exact row and
carriage, follow its motion, and account for reversed coaches. D-pad up/down
continues through coaches, and LS click returns to pilot. Save/load preserves
the selected seat and side, including its AI control lock.
