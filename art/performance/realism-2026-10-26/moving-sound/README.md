# Moving passenger sound propagation checks

`tools/check_moving_passenger_sound.gd` drives the real sound scheduler,
geographic listener proxy and native PCM mixer with known trajectories. Each
ICF, LHB and 16-car VB case runs an oncoming pass and an overtake, first with a
fixed head direction and then continuous head turns. Both trains move. Each
40-second case includes a 1,024-metre render-origin shift while retaining the
same absolute railway coordinates. Own-train track gain is zero so it cannot
mask an external rail dropout. Headphone propagation is enabled.

All twelve cases pass: 80 half-second bins per case, no paused mixer, no silent
nearby rolling bin, and real wheel/contact impact PCM. Maximum listener-proxy
position error is 0.046875 m at the large absolute coordinates. See the full
per-bin JSON and `summary.json` for proximity, channel RMS/peak/sample count,
contact count and observed frame times. ICF/LHB/VB impact peak-bin RMS ranges
are about 0.024–0.029 / 0.0126–0.0133 / 0.0086–0.0095 respectively.

These are controlled motion/propagation checks using native Dummy audio, not a
listening judgment or rendered-game FPS result. No physical output device was
measured. They do not reproduce the full scenery/rendering workload reported
by the user, and do not establish that every intermittent passenger-view
dropout is fixed. The separately proven late-impact scheduling defect and
coach-end transmission changes are documented in the earlier audio evidence.
The generated sound banks are unchanged.
