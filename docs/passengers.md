# Passengers and fullscreen — R12

Start a fresh Kerala Coast scenario. Every scheduled ICF, LHB and Vande Bharat
service carries passengers with seats and destination calls. Nearby people are
visible through the windows and inside the coaches; their positions follow the
same interpolated coach bodies as the passenger camera.
Free-drive formations carry seated riders too; exchanges require a timetable.

At a booked platform stop, doors open on the platform side. People walk through
the coach aisle and vestibule, step onto the platform, then walk away. Waiting
passengers board after the alighters and take their allocated seats. Two end-door
queues operate per coach. The driver and AI cannot apply traction until the
exchange finishes and the doors close. The journey strip and F12/PROGRESS show
the exchange countdown and passenger totals. A red signal without a booked stop
does not trigger boarding; the full rake must fit the platform.

At the terminus everyone alights. Empty-stock depot dispatch waits for unloading
and closed doors. Passenger timing follows simulation time, including pause and
fast forward. The dispatcher sees the physical passenger release time as well
as the timetable dwell, so it does not plan an exit before boarding finishes.

## Fullscreen

- **F11** or **Alt+Enter** toggles borderless fullscreen on the current monitor,
  including while a menu or the dispatcher is open.
- **Esc / controller Menu → Fullscreen / Windowed** provides the same action.
- The choice is saved in `user://display.cfg`. New exported builds default to
  fullscreen; switching back restores the previous window mode and dimensions.
  Development/editor runs default to windowed. Export detection uses Godot's
  [template feature tag](https://docs.godotengine.org/en/stable/tutorials/export/feature_tags.html).

## Implementation and scope

`sim/passenger_service.gd` owns journeys, queues, capacity, conservation and door
interlocking without a scene tree. Capacity matches the authored passenger-seat
anchors in all 21 coach models. Demand is a deterministic scenario model, not
measured ridership: 34% initial occupancy, local trips plus through passengers,
more demand at major stations, and no boarding beyond available seats. Each
transfer takes 22 world seconds, with 1.2-second door slots and three seconds
each for opening and closing. These are gameplay timings rather than a railway
operating standard. The older fictional layouts without platform metadata do
not yet offer boarding exchanges; Kerala is the supported operating route.

`game/passenger_crowd.gd` renders at most 140 seated and 80 moving people within
100 m of the camera using eight shared GPU instance batches. Everyone's journey
continues in simulation outside that visual budget. Seat poses and boarding
paths are cached. Departed passengers use railway coordinates so origin rebases
and train departures do not drag them along with the train. Dynamic people do
not have physical collision with the player; occupied seats cannot be selected
for sitting. The existing static platform furniture remains solid.

People are original procedural characters with male/female clothing variants,
seated poses, breathing and a shader-driven walking cycle. They are not scanned
or motion-captured humans. Source-model coach walk grids provide the aisle paths;
platform navigation avoids the existing furniture. Queues and departures are
local platform activity, not a complete town/station pedestrian network. Crowd
speech and announcements are not included; existing train audio is unchanged.

Door openings adapt the original closed geometry with a platform-side shader
aperture and animated replacement leaves (hinged ICF/LHB, sliding VB). Only the
two passenger end doors are used; VB driving-cab doors and the LHB GS middle
door are excluded. This is runtime animation, not an authored source rig.

Rebuild seated characters in background Blender with
`tools/blender/build_seated_passengers.py`. Rebuild all seat-to-door paths with
`tools/bake_passenger_paths.gd` after changing coach walking grids. The generated
JSON records the input hashes and must report zero unreachable seat/door paths.

## Playtest

1. Start K1 at ERS. Press V or use Menu → Go to passenger coach. Look at occupied
   seats, then use an exterior view to watch the platform-side boarding doors.
2. Try applying power during the exchange: the train should remain stopped until
   the HUD countdown ends and the doors close. Resume power afterwards.
3. Enable AI and watch a subsequent scheduled stop. People should alight first,
   then new people board; F12 should record both totals. Repeat in LHB and VB.
4. Pause and fast-forward during boarding; people and the countdown should follow
   world time. At the terminus, verify zero aboard before the depot movement.
5. Toggle F11/Alt+Enter, then try Menu → Fullscreen using the controller. Restart
   and check that the selected display mode is remembered.
