# Walking inside the train and on platforms

Press **E** on keyboard or **Y** with the default Xbox layout to get out of the
driver's or passenger's seat. Walk through the cab, machinery aisle, passenger
aisles and vestibules. Nearby seats and interior passages display an interaction
prompt. The WAP-7 has no passenger gangway: use a passenger camera preset to enter
its coaches, or step out onto a platform at a stop and board a coach doorway.
The Kerala route supports platform walking beside your assigned train.

D-pad Down/Up transfers to the next passenger carriage toward the tail/loco,
including while moving. You arrive standing, free to move with LS and look with RS.
AI drives whenever you get up or transfer to a carriage. Hold either vertical
D-pad direction to return to the loco standing; Y sits at the nearby controls,
then hold X to take over. Hold Left/Right to return directly to pilot, preserving AI.
The passenger-coach menu and keyboard presets remain available; press Y/E to stand
from those viewpoints. Left/right camera cycling includes exterior follow views only.

There is no walkable WAP end connection through the coupler. Use D-pad carriage
transfer, or stop beside a platform and use A/left click at the cab side door to
alight, walk along the platform, and board a passenger coach.

## Controls

| Action | Keyboard / mouse | Xbox |
| --- | --- | --- |
| Walk / strafe | WASD | Left stick |
| Look | Right-drag; direction stays on release | Right stick |
| Run | Hold Shift | L3 toggle |
| Crouch / stand | C | Camera & passengers menu |
| Sit in a passenger seat | E or left click | A interact |
| Stand / sit at nearby driver controls | E | Y |
| Use a private door / board / alight | Left click | A |
| Cross a passenger gangway | Keep walking | Keep walking |
| Headlamp | L | RB |
| Dispatch / progress | 9 / F12 | View tap / hold |
| Return to pilot | 4 | Hold Left/Right D-pad |
| Return to loco standing | 4 then E | Hold Up/Down D-pad |
| Following exterior cameras | Camera menu | Left/Right D-pad |
| Next carriage toward loco / tail | PgUp / PgDn | Up/Down D-pad |
| External free camera | Tab, then pan to detach | Camera & passengers menu |

See [controllers.md](controllers.md) and the in-game Controller layout page for
driving, walking, camera and menu contexts. Standing and sitting preserve the
latched handle initially, but AI is responsible for operating it once you get up.
Triggers never take control on foot or from a passenger seat. Returning to the
driver's seat does not silently take over: hold X explicitly. Walking does not
pause the railway or the other services.

At a stand, walk up to an exterior door on the platform side and look toward it.
Use **A / left click** when **Step onto platform** appears. Walk along the
platform, face another doorway and use **Board coach…**. The train and dispatcher
keep running; AI may depart while you remain outside.
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
Connected passenger gangways now support continuous walking without an interaction,
fade or viewpoint reset. Their main passage doors are held open; the flexible floor
follows both moving coaches, including reversed VB cars. Private compartment and
WAP machinery doors retain their prompted transition. Jumping and clickable cab instruments are not
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
compartment transitions require a source door header. Detailed meshes are not instantiated as triangle collision bodies. The 26 October
passage correction moves three LHB end partitions and one VB DTC accessible-room
assembly enough to admit the same 16 cm body radius. It preserves seats, stock
capacity, bogies and all pinned authoring masters. `passage_clearance.py` applies
the identical translation to rendered vertices and the bake.

`walkways_open.json` adds source-derived door openings and supported gangway floors
with a centered 4 cm grid (2 cm for the tight ICF 1A approach). All 21 passenger
models have a connected saloon-to-gangway path. Unconnected ends retain their
closed profile and a visible barrier; WAP couplers cannot be walked through. The
sound listener and footstep distance continue across the bridge. Open passage
profiles are rebuilt with the same command plus `-- --open-passages`.

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
and coach transitions. The current control scheme is covered by check_controller_qol.gd.

## Playtest

R12 adds seated and boarding passengers. Occupied seats cannot be selected for
sitting. Passenger doors animate during scheduled Kerala stops, and traction
waits for the exchange to finish. Dynamic NPCs do not physically block the player.
See [Passengers](passengers.md) for behaviour, controls and remaining limits.

1. In the starting WAP-7, press Y/E, turn around, and approach the machinery door.
   Use A/left-click at the prompt. Return through it and sit back down with Y/E.
2. Tap X to enable AI (standing also enables it), enter the first/middle/last
   passenger coach, stand, walk and run down the aisle. Seats and partitions should
   stop you. Crouch and try the headlamp; sit in a different seat.
3. At a coach end, keep walking through the open gangway without clicking. Turn
   around midway and return, then cross fully. Repeat in VB8/VB16, where the second
   half faces the other way. Watch for view jumps, side falls or missing floors;
   clacks should become more prominent near the neighboring bogies.
4. Walk while the train moves and while using fast forward. The view should stay
   attached to the same coach without sliding or rail-joint sound offset.
5. Open dispatch/pause while holding RT, then close it. Release controls before
   moving again. Sit while holding W or RT: the train handle must stay unchanged
   until the control is released and deliberately pressed again.


## Passenger seats and row head-out views

Sitting in a passenger seat automatically hands driving to AI. While seated,
traction, brake, horn, reverser and AI/manual shortcuts cannot operate the train.
Stand with E / controller Y to move around the carriage. AI stays in charge until an explicit takeover;
standing never silently cuts its power or brakes.

From the passenger seat, D-pad left/right cycles left head-out, the same seat,
and right head-out. Keyboard Q and Shift+E choose the two sides; pressing the
same head-out shortcut again returns inside. Both views use the exact row and
carriage, follow its motion, and account for reversed coaches. D-pad up/down
continues through coaches standing, and holding Left/Right returns to pilot. Save/load preserves
the selected seat and side, including its AI control lock.
