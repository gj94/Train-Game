# Fast-forward, home and passenger travel

R44 adds a lightweight home screen with an actual in-game railway backdrop.
Choose a departure, continue the latest save, browse saved journeys, explore
by time, or change graphics/display settings and read the controller guide
before loading the 3D railway. The service browser retains both operating days,
scheduled stops, all three encounter roles, search and average-speed sorting.
It remembers the selected service, search, departure filter and sort order.

## Passenger seat

Sitting remembers the exact coach and seat for that service. Hold **R3** while
seated to remember it again, including the current look direction. Hold **R3**
elsewhere to return there with AI driving. A short R3 press still recentres.
Keyboard: **End** returns; **Shift+End** remembers. The Train & camera pause
section also offers Remember passenger seat and Return to passenger seat.

The bookmark is part of the saved journey. It cannot change your assigned train
or board a stored/departed service. Old saves remain supported. Rendered crowd
occupancy uses the existing player-seat exclusion; this does not change the
passenger simulation or counts.

Skip forward includes **After skip: return to passenger seat if seated**. It is
on by default and saved in the local skip preferences. A clock, stop or event
skip captures the seat at the start, then restores it with AI driving and the
game paused. Cancellation uses the same return path. With the preference off,
the completion screen can still offer Return to passenger seat. If the service
has finished, the existing platform-observer fallback remains in force.

## Streaming

Streaming now predicts a seven-second lead plus a one-tile buffer along the geographic route,
including bends and reverse travel. The look-ahead is bounded to 6 km / 600
speculative jobs on the large-GPU profile (including the target RTX 4090 Laptop),
and 3 km / 260 jobs otherwise. The current camera's visible footprint and far
clip do not increase. Detached/free/platform cameras do not preload a moving
train's route.

Nearby track, signals and stations outrank speculative work; distant background
jobs can follow the forward buffer. A small buffer also fills at x1 while
driving or waiting, before fast-forward is selected. Prepared sections remain
hidden, do not block the loading gate and become visible only when the normal
camera request includes them. Requests refresh after direction, speed-band or
time-scale changes; obsolete work is discarded or becomes ordinary warm cache.
GPU pressure suspends speculative requests, while normal nearby scenery keeps
priority. The existing 2 ms live attachment target remains; no VRAM reservation
is made and no simulation/dispatcher state is changed.

The native scenery replay harness is `tools/benchmark_stream_lookahead.gd`.
It freezes the railway and moves a camera along the same route at 100 km/h ×16
or ×32, pausing camera progress while the actual loading gate is active. Run
with and without `--baseline`; `--target-budget` uses the target's memory/cache
budgets on the development GPU. Results are not 4090 frame-rate measurements.

## Playtest

1. At 720p and your usual resolution, navigate Home with D-pad/LS and A/B. Open
   settings, controller tabs, both operating days, stops and traffic. Exit and
   reopen the browser to check remembered search/filter/sort.
2. Sit in a passenger seat, look toward the window and hold R3. Return to pilot,
   then hold R3: the same seat/view should return with AI driving. Tap R3 to
   recenter. Repeat from the platform and another carriage.
3. From the seat, skip to a time, a future stop and the next event. Try Cancel,
   the passenger-return preference off, Save/Load, and the end of a service.
4. Drive ×16 and ×32 through several stations. Check memory and loading pauses;
   reverse direction or detach the camera, then return. Distant preloaded trees
   and structures must remain hidden until the regular view includes them.
