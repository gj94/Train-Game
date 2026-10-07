# Permanent way and rolling-stock finish

Updated 6 October 2026. The visual target is realistic railway equipment, replacing
the earlier cartoon/low-poly treatment. Rendering remains separate from simulation.

## Track

`game/track_view.gd` constructs the railway in local 64 m sections. The rail-head
datum remains 0.5 m above the track graph, so existing wheels and platforms retain
their vertical alignment. Rail centres are 0.874 m either side of the centreline:
with 72 mm heads this leaves **1,676 mm between the gauge faces**. The previous
0.84 m rail-centre approximation made the visible gauge too narrow.

The shaped rail is 172 mm high with a 150 mm foot, rounded head corners and a
separate worn running surface. Dark oxidised webs/feet, material roughness, cast
concrete sleepers, resilient pads, cast-in shoulders and bent spring clips replace
the previous uniformly shiny rail and box sleeper. Normal sleepers are 2.75 m long,
at 1,660/km (about 602 mm centres). Cast faces/chamfers, rail-seat dirt, coarse
granite normal maps, scattered angular stones and irregular shoulders provide detail
at wheel height. Fine hardware fades with distance; the rail/ballast alignment stays.

Reference dimensions: [IRICEN PSC sleeper description](https://www.iricen.gov.in/ModelRoom/C7_PSC%20Sleeper.html),
[Indian Railways AT Welding Manual 2022](https://www.iricen.gov.in/iricen/Track_Manuals/ATWeldManual-2022.pdf),
and the [Indian Railways Permanent Way Manual](https://www.iricen.gov.in/iricen/Track_Manuals/IRPWM%202024%20Corrected%20Up%20To%20ACS%20-%205%20%2817.06.25%29.pdf).
These are dimensional/art references, not a claim that this fictional railway is an
engineering-certified reconstruction.

## Points and joints

The two outer stock rails, two tapered moving tongues, longer shared concrete
bearers, motor/slide chairs, drive/detection rods, crossing nose, wing rails and
opposite check rails are distinct geometry. Tongues and rods follow the actual
interlocking's normal/reverse state. Animation uses elapsed time; the visual model
cannot throw a locked switch. Bright cyan/orange discs have been replaced by small
unlit indicators; F6 still exposes dispatcher labels and route state.

The geometry fits the existing graph's curved fans and crossovers. It is a
representative mechanism, not an exact RDSO 1:12 turnout drawing. The game still
uses its existing centreline train physics: no flange-contact simulation, rail cant,
wear deformation or mechanical blade travel time in the interlocking is implied.

`game/rail_joint_layout.gd` is the single source for visible joints and sound:
**39 m spacing, 6.5 m offset from each edge start, 10 mm open gap**. Meshes split at
both sides of every gap and expose their end faces. Six-bolt fishplates support the
web on both sides of each rail. This is intentionally jointed track to match the
user's approved sound calibration; it is not a claim that modern Indian mainlines
have exposed joints every 39 m. The user selected the approved website's default
39 m SWR rhythm on 7 October. Point assemblies use shared, rail-specific
interface metadata in `track_contacts.gd`, suppressing periodic gaps inside them.

The active enhanced player is described in [`enhanced-audio.md`](enhanced-audio.md).
It retains the original **BODY V2** impact and rolling bank from
`platform-body-v2-approved-20261006-022055`, replacing the earlier joint-video
adapter. Eight lossless 48 kHz impact variants retain their full **341.333 ms**
decay and **21.333 ms** pre-contact attack. Each bogie emits the approved rolling
bed with its original phase staggering, distance law and power normalization.
There is no added reverb, metallic oscillator or impact pitch/speed gain.
The sibling Railway Sound Lab owns `tools/export-body-v2-godot.mjs` and
`profiles/platform-body-v2/`; do not edit generated WAVs/constants directly.
Source, mix rules and validation are detailed in [`body-v2-audio.md`](body-v2-audio.md).

The new website port sounds **multiple actual joints and turnout contacts**, with
propagation to the moving listener, onboard balances and benchmark curve squeal.
The older one-joint mix remains a regression comparison only. Ordinary track's
39 m joint spacing stays visible; point interfaces match their affected running rail.

The scheduler evaluates actual axle positions in both directions. Playback pitch
stays constant as speed changes; contact gaps follow distance divided by speed.
An LHB's 2.56 m axle pair therefore sounds 0.3072 / 0.1536 / 0.0768 seconds apart
at 30 / 60 / 120 km/h. Other stock uses its actual geometry. At a stand, there
are no new impacts and rolling fades to silence. TRACK_ONLY remains enabled.
Comma/period adjust second-axle balance (default neutral); brackets adjust total
track sound. J is optional diagnostics; real gaps stay visible.

`game/train_motion.gd` samples travelled distance along the occupied route between
physics ticks. Bodies, bogies, wheels, camera targets and sound scheduling share
that rendered position, including old tail-edge history until the rendered tail
clears it. The overview camera carries forward the train's movement before easing
its framing, so it does not lag behind at wheel-level zoom. Simulation and
interlocking remain at their fixed tick rate; rendering is one tick behind.
Teleporting or changing cab ends resets interpolation. Godot's physics jitter fix
is disabled for this custom interpolation, as specified in the
[engine documentation](https://docs.godotengine.org/en/stable/classes/class_engine.html#class-engine-property-physics-jitter-fix).

## Trains

The original MEMU now has a background-Blender-built detail kit: open fabricated
bogie frames, coil suspension, dampers, brake blocks/rigging, wheels with separate
treads/flanges/faces, axle boxes, reservoirs, cabinets/louvres, pipework, couplers,
hoses, window bars/gaskets/mullions, handrails, steps, roof seams/vents and cab
wipers/horns. The 16 bogies and 32 wheelsets of an eight-car rake are independently
steered/rotated, using the same geometry as the sound axle positions. Its authored
body length, bogie centres and wheelbase stay unchanged. Door steps clear the
existing platform envelope. The editable master is `art/memu/memu_detailed.blend`.

`fleet_surface.gd` adds non-destructive PBR finishing to the MEMU, existing WAP-7/LHB
and all 25 imported models: enamel sheen, uneven rain/road film, darker roof dirt,
running-gear/brake dust, exposed-metal roughness and darker reflective exterior
glazing. Vande Bharat receives a lighter wear level. Original source meshes/materials,
instrument textures, labels and animated rigs remain intact. Entering a cab or
passenger view clears only that vehicle's glass; leaving restores its finished
exterior material. Interior instruments/doors retain the limitations documented in
the imported-fleet guide.

These are detailed procedural reconstructions, not scanned production vehicles.
The surrounding palms, broadleaf trees, terrain and repeated town props still need
their own realism pass; improved trains/track do not make the whole scene photoreal.

## Verification and playtest

Automated geometry checks cover gauge/datum, upward rail/sleeper surfaces, sleeper
spacing across section boundaries, unbridged joint openings, fishplate/sound position
agreement, forward/reverse hit timing, paired blade motion and crossing guards.
Fleet checks cover all 25 material applications/source preservation and MEMU
wheel/rail/sound alignment and motion. Existing dispatch and fleet integrations
exercise actual gameplay separately.

1. Start the default WAP-7/mixed-LHB working in the cab; A enables AI driving
   and Tab switches between cab and exterior.
   Inspect track texture stability while moving and the close sleeper/clip detail
   from an exterior view. F4 clears the HUD.
   Exterior zoom now reaches 3 m for rail-joint and wheel inspection; pan/orbit to
   frame a bogie and use the mouse wheel to pull back out.
2. Use F9 for WAP-7, WAG-9, WAG-12B, ICF/LHB and Vande Bharat. Check exterior
   glass/paint, then Tab or V inside and back out. Glass should restore correctly.
3. At an unoccupied junction, use D to set a different valid route, or F6 to expose
   point labels and click an unlocked switch. Zoom on the blade toe and motor: one
   tongue opens while the other closes and the stretcher rods move. Locked points
   must remain locked.
4. Follow an LHB bogie past a fishplated joint at roughly 30, 60 and 120 km/h
   where the route permits. The approved cling-clang character should remain,
   with the pair interval halving each time speed doubles. The wheel, bogie and
   camera should move together smoothly. Brake to a stand and verify the track
   sound stops, then repeat after changing ends. Comma/period adjust the balance.
   J can expose the existing sound diagnostic bars; turn it off for normal viewing.
5. Check the MEMU's wheels rotating and bogies steering through a curve, and the
   upper door steps beside a platform. Report clipping, material glare and target-PC
   performance; no target-PC frame-rate guarantee is made.

Rebuild MEMU: background Blender with `--python tools/blender/build_memu.py`.
Run `tools/check_track.gd`, `tools/check_fleet_finish.gd`,
`tools/check_motion_playable.gd`, `tools/check_body_v2_audio.gd` and the normal
headless suite. The audio check exercises actual players at 0/30/71.6/120 km/h;
`-- --capture` saves Train-bus WAVs under `.local/body-v2-ab/` (use a working
audio driver or fixed-120-fps Movie Maker mode for offline mixing). The motion check
also accepts `-- --clock-probe` to stress actual render/physics timing, with
`--render-probe` for a graphical wheel-level capture; only that probe lowers
physics ticks to 10 Hz to expose stepping on a slow test GPU.
`tools/capture_track.gd` saves actual-corridor comparison views under
`.local/track-after/`; `tools/capture_fleet_finish.gd` renders the actual fleet in a
small inspection railway under `.local/fleet-finish/`. Both use the game's materials
and lighting. `tools/build-windows.ps1` includes both geometry checks and this guide.
