# Skip to the next event

Open **Pause > Skip to next event / time / stop > Skip to next event**.
The actual railway advances with all trains on AI, including your service.
The earliest enabled interruption wins:

- Your next scheduled stop is 1 km away, or farther away if comfortable braking
  needs more room at the current speed.
- About 60 simulated seconds before the first side-by-side contact with an
  oncoming train, a train you overtake, or a train overtaking you. This is the
  start of the pass, not the midpoint or the last coach clearing. It need not
  become a completed timetable overtake if the trains subsequently stop.
- A red signal holding your stationary train permits movement: yellow or green.
  A signal already clear when you start, a distant red, and a red during booked
  dwell do not interrupt immediately.

**Pause > Time-skip event settings** enables each category independently. The
three encounter roles have separate switches. Preferences persist on this PC.
Safety interventions, your service ending, and the 24-hour search boundary
always end an event search. Clock and future-stop skips retain their explicit
targets; they do not silently become event searches.

The read-only dispatcher follows your train at a 10 km span. Train bars show
physical footprints, mint tracks show reserved authority, and signal lamps show
the local railway. The clock, progress and stop button remain available to
keyboard, mouse and Xbox. **B / Esc** stops advancing. The map can be disabled
in time-skip settings. It does not render scenery, train models or passengers.

An encounter search simulates one minute ahead and retains a bounded history.
The displayed railway is the committed position, behind that look-ahead. There
can be a short initial pause in displayed progress while this minute is checked.
Cancelling returns to the committed position, not to unseen future activity.
An encounter closer than a minute at the start returns immediately with the
shorter warning. Choosing Next event again dismisses that same warning for this
session; it does not alter railway authority or force trains to pass.

Completion returns paused, normally to your pilot seat, with AI still driving.
Choose **Take control of this train**, continue with AI, inspect Dispatch or skip
again. If your service is no longer available, the existing station-observer
return applies. Manual driving after return can change a forecast encounter.

## Implementation and checks

Simulation and UI remain separate. The worker sends detached local map data at
at most 10 real-time updates per second; the progress view is capped at 30 FPS.
It never waits for a particular map frame. The original 0.2 s batches and 50 ms
physics slices are unchanged. The map never reads worker-owned railway objects.

Event searches keep checkpoints five simulated seconds apart over the recent
minute, then restore the existing world/train objects and replay only the short
remainder to the selected trigger. Detached passenger records are shared across
history entries while unchanged, rather than copying every seat repeatedly.
Signals, switches, passengers, AI state and dispatcher commitments are restored
together. Full save files are not written for these history entries.

The feature does not change ordinary train physics, dispatch rules or operating
days. Prepared-state provenance is refreshed only after verifying every original
railway input and the unchanged old skip movement loop. Original full-day audits
and checkpoint bytes are retained; a provenance refresh is not a new day replay.

Relevant checks: `tests/test_skip_events.gd`, `tools/check_skip_history.gd`,
`tools/check_time_skip.gd` and `tools/benchmark_skip_map.gd`. Compare map hidden /
visible with identical restored railway states. Report the prediction-history
cost separately from drawing the map. Development-PC measurements do not claim
performance on the i9-13980HX / RTX 4090 Laptop / 64 GB target.

Playtest: leave only signal clearance enabled at an actual red wait; then enable
stop approaches and skip toward the next call. Try each passing category around
busy traffic, cancel with B, and check that AI remains in control until requested.
Toggle a category, restart the game and confirm the preference is retained.
