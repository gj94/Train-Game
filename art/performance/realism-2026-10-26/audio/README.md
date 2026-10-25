# Passenger audio correction — 26 October 2026

The native fixed-position probe uses two ICF rakes, a stationary passenger eye,
a 30 m/s neighboring source and repeatable axle impacts. It measures actual Godot
PCM at nine yaw angles; it does not replay an entire moving railway or use the
hardware audio device. Dummy audio and compatibility rendering are intentional.

- Head rotation retains rail energy: minimum/maximum RMS is 0.9837 before and
  0.9750 after, with ordinary rolling phase variation. Impact RMS remains
  0.01123156 at every angle. No directional mute was reproduced.
- A separate 120 ms-late impact was completely discarded before the correction.
  The native old-source probe records zero channels and zero PCM, with an expected
  failure. The corrected scheduler submits both channels at offset 2.1321 s into
  the padded bank: RMS 0.01552 and peak 0.08402. It seeks into the remaining decay,
  rather than replaying the attack. Expired 600 ms contacts remain discarded.
- At the tested partly exposed ICF window, passing-air RMS falls from about
  0.00660 to 0.00409 while impact RMS stays unchanged. Closed spaces shelter air
  more than rail sound; exterior response is unchanged. Coach ends transmit more
  nearby rail sound without pretending the side door is open.
- Five focused tests and the full **969-test suite** pass, with empty test stderr.
  Native full probes have empty failures arrays. The native renderer reports its
  known screen-space antialiasing availability warning; no audio-device or FPS
  claim is made.

Generated sound banks are unchanged. The mix is an authored approximation, not a
measured acoustic calibration. The user's intermittent moving/head-turn silence
is not fully reproduced or certified fixed by this bounded probe.

Run `tools/check_passenger_sound.gd` natively with `--audio-driver Dummy` and an
explicit `--output=res://...`. `--late-only` isolates the scheduler regression;
`--sound-script=res://...` allows an exact old-source copy without editing runtime.

Playtest: ride beside a passing/oncoming train and turn through 360 degrees; listen
for continuous rolling/clacks, reduced air masking and stronger bogie sound near
coach ends. Check open-window versus sealed VB saloons. Report any remaining
silence with train, coach, camera position and time.
