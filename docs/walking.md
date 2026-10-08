# Walking inside the train

Press **E** on keyboard or **Y** with the default Xbox layout to get out of the
driver's or passenger's seat. Walk through the cab, machinery aisle, passenger
aisles and vestibules. Nearby seats and interior passages display an interaction
prompt. The WAP-7 has no passenger gangway: use a passenger camera preset to enter
its coaches, then walk between the connected coaches.

## Controls

| Action | Keyboard / mouse | Xbox, either layout while on foot |
| --- | --- | --- |
| Walk / strafe | WASD | Left stick |
| Look | Right-drag, direction stays on release | Right stick |
| Run | Hold Shift | Hold RT while moving |
| Crouch / stand | C | Left-stick click |
| Sit near a seat | E | Y |
| Use displayed seat / interior doorway / gangway | Left click | A |
| Headlamp | L | D-pad right |
| Dispatch | 9 | Tap View / Back |
| Service progress | F12 | Hold View / Back |
| Return to pilot | 4 | Hold right-stick click + D-pad up |
| First / middle / last passenger coach | Alt+1 / Alt+2 / Alt+3 | Camera & passengers menu; hold RS + D-pad left cycles internal views |

On keyboard **Shift+E** now selects the right head-out view; Q still selects the
left. The default controller layout follows TSW's immersive contexts; see
[controllers.md](controllers.md) for driving, camera shift and the legacy option.

Getting up and sitting down preserve the driver and the latched power/brake
handle. Enable AI before leaving the controls if you want it to drive. Walking
does not pause the railway; dispatch and all other trains keep running. In the
default controller layout, X+A explicitly toggles AI and X+B explicitly applies
emergency braking. Menu → Train & view actions has these commands in both layouts.
Release walking keys/sticks/triggers when returning to driving or closing a menu.

Interior door leaves remain static artwork. Where a closed door or a narrow
doorway blocks the body, a prompt takes you through with a short fade. Gangways
also use this transition. This version supports interior walking; it does not
add exterior platform walking, jumping, opening exterior doors or clickable cab
instruments. Cab controls remain available from the existing driving input/menu.

## Implementation and source

`train_walk.gd` stores position inside the individual articulated vehicle. The
camera uses that car's interpolated transform, including reversed VB cars and
geographic origin shifts. The sound listener follows the walked position in the
same axle/joint coordinate system as seated views. No audio bank is regenerated.

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
