# Journey acoustics, station approaches and recovery

## What changes in play

Booked station approaches now retain a falling speed ceiling after braking begins
near the station. Clearing the tail of an entry restriction cannot produce another
run-up to line speed. Normal braking remains progressive, with a gentler final
walking-speed stop. Signals, occupied sections and emergency braking still override
comfort. If a red signal stops a train short, it can build speed under the remaining braking curve and finish its arrival;
it does not retain a crawl-speed ceiling from that stand. Short station-to-station departures can still accelerate normally.
The policy applies to the AI driver, including when you hand over your service.
Manual driving remains yours.

An AI-driven departure from a booked platform produces two horn calls **while
stationary**, including the player's own service after handing driving to AI.
Booked departure, passenger doors and the starter must permit departure first.
The calls begin 3.5 **simulation seconds** apart and last about 1.15 seconds each;
the holding brake stays applied until the second finishes (about 4.65 seconds).
An already-cleared departure cannot receive a new advisory overtake hold that
would trap another train behind its reserved route. Signal protection still applies.

Manual driving suppresses automatic calls. Taking over cancels the pending pair,
even while paused; a later stationary AI handover starts a fresh complete pair.
Losing the departure route also cancels the ceremony. Your manual horn remains
available. Saving preserves cue/brake-release timing, and loading a distant train
does not replay old events. Fast-forwarding compresses the interval with the clock.

The braking design is informed by RDSO's trainset specification: service braking is
controllable and normal changes in acceleration are limited, while emergency braking
must retain its full capability ([RDSO/CG/P-20001, §§2.6–2.7](https://rdso.indianrailways.gov.in/uploads/files/20201118_RDSO_CG_P_20001.pdf)).
Its full-service performance requirement is not a normal station-stop target and is
not a measured WAP-7/ICF/LHB comfort profile. Our partial-service fraction, final
0.18 m/s² envelope and response margins are authored simulator tuning. The existing
power/brake handle ramp is retained; this is not a complete pneumatic brake-pipe model.

## Sound

The 26 October development changes make rail sound stronger and less muffled
near coach ends and gangways, where the neighboring bogies are close. Closed
coach interiors reduce passing-air noise more than external rail clacks. A rail
contact processed late now plays its remaining decay instead of discarding an
otherwise audible strike. The approved sound banks are unchanged.

Controlled ICF/LHB/VB checks and two actual rendered passenger cases retain
nearby rolling sound throughout head turns. The rendered cases cover a
stationary passenger being overtaken and crossed, plus two trains meeting at
about 99 km/h. These are native mixer measurements, not a physical listening
verdict or proof that every intermittent report is resolved. See the
[rendered sound evidence](../art/performance/realism-2026-10-26/rendered-sound/README.md).
Playtest turning toward and away from a passing train, then walk from the saloon
through a gangway and compare the bogie/clack balance.

- Listener location distinguishes pilot areas, WAP machinery aisle, coach centres,
  open ICF windows and vestibules with open passenger doors. Sealed VB interiors
  attenuate external sources more strongly. Transmission changes smoothly.
- Passing trains use source/listener-relative Doppler for rolling, squeal, engines
  and horns. A stationary joint's airborne ring accounts for listener motion.
  Own-coach structure response remains at its natural pitch. Floating-origin changes
  do not become fictitious velocities.
- Each nearby train has three bounded air sources: nose, nearest body and wake.
  Air continues to build above 100 km/h; body/gap exposure and distance shape a pass.
  The body rush follows the closest point along a car, avoiding a car-length jump
  when the nearest coach changes.
  Open head-out viewpoints expose the listener to own-train air.
- The occupied car has a separate low-frequency joint/body response scheduled at
  physical wheel contact, alongside the airborne rail sound. It does not remain
  attached to the rail joint behind the train.
- WAP and VB fan layers differ; VB traction has its own pitch profile. Compressor,
  ventilation, floor/platform footsteps, door/latch and brake-release air add context.
  These are authored approximations, **not new field recordings**. The canonical
  generator is in sibling `railway-clang-simulator`, mirrored under `tools/audio-source`.
  Generated WAVs include SHA-256 provenance. Existing approved impact/rolling/squeal
  PCM has not been changed.
- Short compartment/canopy response and optional headphone front/back coloration
  improve positioning. This is a lightweight acoustic model, not measured HRTFs,
  acoustic ray tracing, or a survey of each real carriage's insulation.

Open **Pause → Audio settings**. Choose Speakers, Headphones, Quiet/night, or
Approved track reference. Open **Rail & wheels**, **Wind & passing trains**,
**Motors & equipment**, **Interior & movement**, or **All sound layers** to adjust
individual channels. Master has its own control. Reference disables
new body/air/foley overlays and retains the approved track routing/compression.
Wide-range gameplay separates layers and uses a final limiter; quiet mode adds
compression before that limiter. The reference remains a comparison tool, not a
claim of matching a recorded cabin spectrum.

### Detailed mixer

The sound menu now groups fifteen independent channels, plus Master:

- **Rail & wheels:** continuous rolling rumble/hiss; airborne joint clacks;
  curve/flange squeal; own-car floor thumps; intermittent metallic rattles.
- **Wind & passing trains:** own-train exposed/head-out wind; other trains'
  nose/body/wake air. Taking over a different service updates which train uses
  each air channel.
- **Motors & equipment:** traction motors; cooling fans; horns; compressor.
- **Interior & movement:** ventilation; walking footsteps; doors/latches;
  brake-release air.

Every channel has an explanation, independent 2 dB adjustment, true Mute/Unmute
and Restore standard level. Mute remembers the chosen level. Presets explicitly
reset the mix. Existing saved shared settings are inherited once by their newly
separated channels, so an update does not unexpectedly restore muted machinery.
Settings belong to the PC and apply to nearby trains as well as your own.

The approved reference preset retains its existing routing and bypasses these
gameplay channels; the menu states this. Select Speakers/Headphones before
tuning the full mix. The original `[ / ]` shortcuts remain a current-train
track-group boost; Rail & wheels displays it and offers a reset. The second-axle
balance is also available there. Neither control changes wheel spacing, the
speed-dependent timing or the recorded waveform. A shared output limiter still
protects the total mix from clipping.

## Journey tools

Open **Pause → Journey tools & recovery** (also reachable with controller focus).

- Three rotating recovery slots are saved every five minutes of active play and before
  time skips, loading another journey, scenario changes and confirmed quit. Five
  manual slots and Quick save remain independent. Recover from **Load journey** or
  the landing page's saved journeys. Snapshot capture occurs on the railway owner;
  a sleeping worker writes/verifies the detached data. Each slot keeps its previous
  good backup. This cannot recover progress since the last completed save.
- A proceed-signal notification appears after a sustained red-signal hold clears,
  with the earlier dispatch reason. Returning to ×1 is independently selectable.
  The notification does not clear a route or authorize passing a red signal.
- Route-ahead information adds current geometric gradient, the next posted speed
  change and booked platform side to the existing signal and next-stop guidance.
  The platform indication is provisional if the dispatcher changes the assignment.
- Save three service-specific camera viewpoints or return to the previous viewpoint.
  Restoring one does not rewind the railway. A passenger seat still hands driving
  to AI. Restores pause the game; resume when ready.
- **Create local diagnostic ZIP** captures the railway, build/settings and bounded
  recent logs. **Open diagnostics folder** locates it. Nothing is uploaded. Logs can
  contain local file paths; share the ZIP only when you choose to.

## Validation and playtest

The original 18 October source suite passed 614 tests, including station-entry restriction
regressions in both directions, a short leg, red-signal recovery, departure horn
spacing, acoustic transmission/Doppler, save compatibility and recovery rotation.
The full operating-day audit completed all 100 services, including depot clearance,
with no safety events. Longest stationary wait was 29 min 14 s; maximum passenger
arrival delay was 33.9 min. All 100 departures and 233 five-minute baseline states
were regenerated and exactly round-tripped. Manual driving can change the outcome.
Native source checks cover the menus, bookmark return, detached asynchronous save,
local diagnostic ZIP, free-camera sound, reference routing and five nearby rakes.
The five-rake fixture checks output headroom, sealed-cab attenuation, paired horns
and pause. It measures audio work only, with no scenery/passenger rendering; it is
not an end-to-end performance benchmark of the target i9/RTX 4090 Laptop.

1. Start a stopping service and tap controller X for AI. Observe entry-restriction clearance:
   the train should continue its approach without a second acceleration burst.
   Watch the final few metres and listen for two horn calls on the next departure.
2. Repeat with manual driving: there should be no automatic departure horns;
   B must still sound your horn. Take over between the AI's first and second calls:
   the second must be cancelled. Stop at a red approach and verify AI can finish
   the arrival once a valid route becomes available.
3. At 60 and 100 km/h, walk between the WAP pilot area and machinery aisle; compare
   coach centre, ICF window, vestibule and head-out. Listen to opposing traffic from
   a sealed coach and then from the platform. Compare Speakers and Reference.
4. Save a viewpoint, move to a passenger coach, then restore it. Test recovery/load
   and create a local diagnostic ZIP. A time skip should leave a pre-skip recovery.
5. On the i9-13980HX/4090 Laptop, run the crowded benchmark and a normal journey.
   Report the audio preset/output device, service/time, camera and any new stutter.
