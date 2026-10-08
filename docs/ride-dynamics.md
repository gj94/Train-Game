# Sprung-body ride motion (R9)

Cab, head-out, passenger and walking cameras move with their carriage. Wheels
and bogies follow the original track poses. Joint and turnout contacts excite
the body using the same axle positions and physical contact metadata as audio:
front/rear bogies produce opposite pitch, and one-rail point contacts add roll.
Spatial track roughness adds speed-dependent vibration; acceleration/braking
and lateral acceleration through curves load damped springs.

The response runs in simulation seconds, including fast forward. Pausing holds
the pose; changes of cab, teleports and route discontinuities reset the sweep.
Floating-origin rebasing does not change the ride state. Detached exterior
camera remains independent. The pure solver lives in `sim/ride_dynamics.gd`;
`game/vehicle_ride.gd` supplies actual contacts and applies body transforms.

These are restrained, tuned ride cues, not measured WAP/LHB suspension values.
This release does not introduce coupler slack, brake-pipe propagation or change
longitudinal traction/braking performance. There is no random shake at rest.

## Check in game

1. Drive at 30–60 km/h in pilot view; watch the horizon relative to the cab.
   Repeat in a passenger coach. Jolts follow that vehicle's own axle contacts.
2. Change power, coast, then brake. The body should pitch and settle, without
   moving the wheels away from the rails. Turnout contacts produce sharper,
   asymmetric responses than ordinary joints.
3. Stop and wait: vibration settles. Pause freezes it. Try 2x/4x and return to
   1x; motion follows world time. R3/free exterior remains detached.
4. Walk through a coach while moving: the floor, furnishings and viewpoint
   share one body transform. Verify that boarding and sitting still work.

Validation: eight solver regressions cover rest, impulse direction, speed,
traction/braking, frame-rate repeatability, curves, pause/reset and 32x stability.
`tools/check_ride_playable.gd` checks the actual four formations, rail alignment,
body travel, camera roll, rebasing and cab reversal (24 checks).
