# Enhanced platform acoustics and passenger views

Active player: `game/platform_audio.gd`. The reference is the user's newer
`platform-squeal-benchmark-src-md-20261006-221237/platform-experience/Acoustics.md`,
superseding the earlier curve-squeal snapshot from 21:56. The original nine BODY V2
WAVs are unchanged. The old `body_v2_audio.gd` remains a regression reference.

## Free-camera receiver — R17

Gameplay track sound now listens at the actual camera eye and orientation, as
native traction and horns already do. Previously exterior track audio inherited
the website preview's virtual spectator beside the orbit pivot. A detached free
camera could approach the wheels while that receiver stayed hundreds of metres
away, making rolling, joint impacts and squeal much too quiet.

The geographic listener retains absolute route coordinates across origin shifts.
Only explicit reference mode keeps the website's projected single-joint receiver;
gameplay no longer searches the entire track graph for that unused projection.
On-foot platform cameras always use exterior acoustics. The approved sound banks,
gain law, speed response and joint timing are unchanged.

`tools/check_free_camera_audio.gd` captures native PCM at 200 m and 5 m, with a
remote fixed pivot. It checks rolling and traction distance response, a real
nearby joint voice, pivot independence, origin rebasing and pause silence.
Receiver unit tests also cover orientation, overrides and reference mode.
Run the native probe headlessly with `--audio-driver Dummy`.

Playtest: right-stick click selects free exterior. Approach the bogies of a
moving train, then move away; rolling and impacts should rise and fall with your
distance. Try an AI train while keeping your current driving assignment. Return
to pilot with left-stick click and cycle to a passenger view for the existing
interior mix. A stationary coach has no rolling/joint sounds; the WAP auxiliary
hum comes from its locomotive.

## Coach-body rattles — R10

`coach_rattle_audio.gd` adds intermittent short latch/panel resonances, strongest
in ICF coaches and quieter/less frequent in LHB. Each coach has its own seeded
distance intervals; speed changes cadence, and sprung-body jolts can trigger
extra knocks. These are secondary metallic body cues, independent of axle-joint
timing. They settle to silence when stopped, freeze on pause/loading, and remain
excluded from the track-reference comparison mode. Pitch does not rise with speed.

Eight short, uncompressed mono WAVs come from the canonical sibling sound-lab
`src/coach-rattle.mjs`, exported by `tools/export-coach-rattle.mjs`. Rebuild with
`node D:/ClaudeWS/railway-clang-simulator/tools/export-coach-rattle.mjs D:/ClaudeWS/train-game`.
Source snapshots are committed under `tools/audio-source/`, with source/output
hashes in `assets/sounds/coach_rattle/provenance.json`. These are synthesized
approximations, not new recordings or a measured ICF reference match. The approved
joint, rolling and squeal banks have not been regenerated or retuned.

Each resident train uses at most four native positional voices; distant events
are culled and stale fast-forward events never accumulate into a burst. The
separate CoachBody bus, local source positions and reduced cab leakage keep the
sounds associated with coaches rather than the locomotive. Validation includes
native PCM capture, clipping, pause, stationary silence and bounded voice count.

## Electric engine layer restored, 8 October

The track-only comparison mode had also disabled the game engine sounds and horn.
`engine_audio.gd` now adds a separate **Traction** bus: electric auxiliary hum,
load/speed-dependent motor whine and low-speed inverter tone. Cached one-second
periodic PCM loops play in Godot's native 3D mixer; there is no per-frame sample
generation and no change to the sound-lab files. These are synthesized engine
sounds, not new recordings or a calibrated WAP/VB acoustic measurement.

WAP sound comes from the locomotive; VB traction comes from its four/eight motor
cars. Level responds to power or moving regenerative braking; stationary applied
brakes produce no motor whine. Distance, cab attenuation, pause, scenery loading
and streamed train cleanup apply. The existing recorded horn is enabled again.
Clack/squeal pitch, contacts, approved bank and filter buses remain unchanged.
On a platform the track receiver uses the walker's actual position and orientation.

## Sound and physical contacts

The enhanced adapter preserves the full 341.333 ms impact kernels, native pitch,
natural axle loads, master balance, inverse-distance/equal-power spatialization,
and per-bogie rolling. It adds the supplied joint-specific variant selection,
moving receiver propagation, distance filters, passenger +3 dB doorway balance,
preceding-bogie body cap and locomotive rear-wheelset compensation. Balance uses
32 measured energy bins from the unchanged impacts, including receiver motion
through their decay. It follows the actual camera on the rigid coach body.

Rolling follows `(speed / 71.6 km/h)^1.25`, capped at 1.4, with the supplied
900 Hz high shelf. It becomes much quieter at low speeds without transposing
impacts. Onboard rolling/squeal has no artificial relative Doppler.

Contacts come from `track_contacts.gd`, shared with the permanent-way renderer.
Ordinary track uses **39 m SWR joint spacing**, matching the website default and
the user's explicit 7 October selection. Visible gaps and fishplates moved with
their sound contacts; the gap itself remains 10 mm wide. The active
player now hears multiple physical joints. Inside point assemblies, ordinary
periodic gaps are replaced by rail-specific interfaces. Toe, heel and crossing
positions derive from the existing game geometry, rather than assuming every
game turnout is the website's 39.975 m assembly. Each complete modeled point has
11 contacts per axle: seven interfaces, two quiet welds, one switch transfer and
one stronger nose transfer. Check rails do not generate invented gap impacts.

The scheduler sweeps actual axle route positions and interpolates crossing time.
A prediction includes the reported output-device latency, mixer block and next
display frame, preserving the 21.333 ms pre-contact attack; invalidated future
contacts are canceled on motion/route changes. Native silent padding places
starts between display frames. More distant arrivals wait in a queue before
native scheduling. Debug records retain physical and heard times and identify
virtualized events. The scene's joint marker flashes at heard arrival.

`audio_output_timing.gd` caches the driver's latency estimate once per second and
samples time-to-next-mix when submitting an impact. The padding offset removes
that buffering delay without altering waveform samples, pitch or real acoustic
propagation. Offline captures/Dummy have no physical device compensation. F10
shows the audio driver and output-buffer estimate. This estimate cannot measure
unreported Bluetooth/receiver or display latency; a hardware listening test is
still needed for those paths.

Desktop `AudioStreamPlaybackPolyphonic.play_stream(..., bus)` does not route an
ordinary streamed voice independently of its owning player. The corrected
adapter therefore uses one pooled player per joint filter, the rolling player's
actual shelf bus and one player per squeal filter chain. Previously these filter
buses were configured but bypassed by the native stream mixer. The native PCM
regression now captures their outputs rather than checking properties alone.

## New benchmark squeal

The current four banks use the supplied `squeal-profile.js` and original seeded
inverse-FFT synthesis. This is the newer rough spectral texture, not the earlier
three-tone oscillator bank. Each 48 kHz bank is **262,144 frames / 5.461333 s**;
the complete periodic buffer loops. Exports only quantize to lossless 16-bit PCM,
without normalization, pitch detuning or copying recording samples/phases.

Signed curvature is evaluated under each physical axle. The new weighted
curvature, sustained 0.7-floor envelope and 4.8 kHz curve-color shelf match the
new JavaScript model. A bogie's rear axle can sustain the sound after its leading
axle leaves a curve. Curvature is derived from the game's tessellated alignment,
not from abrupt heading impulses at individual vertices. Straight track and
standstill produce no new squeal. Five seconds of pose history support retarded
source positions, and the source follows the modeled inner wheel.
Each history query interpolates only the relevant bogie's wheels. Retarded-time
iteration stops after convergence (at most eight iterations), and sources beyond
any reachable audible position in retained history are culled early.

Native voice budgets are 128 impact channels, 24 filtered impact locations and 12 squeal voices
(including fading tails) per train. Impact locations are prioritized by received
level; retained contacts keep their physical identity in the diagnostic trace.
Impacts beyond a conservative 2.6 km prefetch radius are discarded before
retarded-arrival calculations (native impact voices already stop at 1.6 km).
This prevents inaudible trains at the far end of the 22 km corridor from building
thousands of pending events. Nearby timing, voicing and decay are unchanged.
Onboard receivers no longer search the entire corridor for an exterior listening
joint. Exterior sources share a matching receiver's nearest-joint result.
Curved-arrival iteration stops when converged to 0.1 ns, retaining its twelve-step
maximum. Squeal uses the
reference threshold, normalization, gain/filter smoothing and 300 ms release.
Pause, coach jumps, consist replacement and exit clean up pending events/tails.

The fitted squeal spectrum is a benchmark match, not absolute SPL calibration or
an estimate of the recording's curve radius. The supplied source-only archive
omits `squeal-fit.json` and the recording; its held-out recording statistics
cannot be independently rerun from that archive. Source synthesis/model tests,
generated-bank checks and game integration are verified independently.
Godot's native compressor still lacks the browser's soft knee; native buffering,
resampling and moving-filter updates prevent a sample-identical output claim.

## Passenger views

- **Alt+1 / Alt+2 / Alt+3:** enter first / middle / last passenger coach directly.
- In passenger view, **1 / 2 / 3** select those same coaches.
- **Esc → Go to passenger coach** offers the same three choices and a numbered
  list for any coach, including while moving behind a WAP-7.
- **PgUp/PgDn** visit other coaches; **left/right** change position; **Home**
  switches aisle/seat; right-drag looks around. **V** returns to the cab.

Generator and luggage vans without passenger interiors are skipped. First/last
refer to the current direction of travel. R10's 20/22-coach WAP rakes and the
Vande Bharat formations use their actual eligible coach lists, excluding the
WAP locomotive. Entering these views preserves AI/manual
driving controls. Outside passenger view, unmodified 1/2/3 remain station views.

## Source and validation

Regenerate through the sibling `railway-clang-simulator`, never by editing WAVs:

```
node tools/export-platform-enhanced.mjs D:/ClaudeWS/train-game
```

The lab owns `profiles/platform-enhanced/`. Source, exporter, calibration scripts
and restoration instructions are committed in `tools/sound-lab/enhanced/`.
`assets/sounds/platform_enhanced/provenance.json` records input/output hashes.
The original BODY V2 exporter remains responsible for the impact/rolling bank.

`tests/test_platform_acoustics.gd` compares original-JavaScript fixtures for 56
onboard cases, rolling/demand laws and curved-source states, plus route contacts,
reverse identities, frame-independent timing, history reset and all routed PCM.
`tools/check_platform_audio.gd` exercises native reference playback at rest and
30/71.6/120 km/h. Heard events in eight seconds are 0/12/29/45: these include
propagation and differ from the old check's look-ahead/contact-boundary counts.
`tools/check_platform_integration.gd` checks native curve voices, release/re-entry,
pause, bus cleanup, and the three real scene cameras/listeners.

7 October performance follow-up: queued onboard impacts first pass a conservative
wavefront-distance check. The sound can travel at 343 m/s; the receiver's bound
includes its speed and the full possible rotation of its offset from the bogie
midpoint. Impacts that cannot arrive within 180 ms skip repeated curved-route
queries for that frame. The original exact solver still sets arrival time before
the 160 ms native scheduling window. Virtual impacts without a native voice also
skip unnecessary stereo-volume calculations. The sample bank, pitch, envelope,
contact positions and audible-distance limit are unchanged. The headless suite
checks that the guard never excludes an imminent arrival on moving curved paths.

Playtest a freshly extracted build at normal simulation time. Use A for AI and
Alt+1/2/3 to compare coach positions at 30/60/120 km/h where allowed. Confirm
wheel-pair gaps shorten with speed while impact pitch stays fixed; brake to a
stand and restart. Traverse a curved turnout slowly and compare with straight
running, then pause/resume and change coach repeatedly. The new passenger balance
is an airborne listening model, not a separately calibrated carbody vibration path.
# R9 onboard comparison and perspective fixes

The new comparison uses a moving pilot and first-coach doorway on straight
track with 39 m joints at 30, 71.6 and 120 km/h. It uses the website's exact
WAP + 20 LHB geometry, rather than R9's imported seven-coach formation. R10's
20/22-coach service profiles are a subsequent change; these measurements describe
the fixed comparison fixture, not a new measurement of each long service rake.
Native and Web Audio captures use the same approved PCM and receiver positions.

Across six eight-second captures, game/reference RMS difference was -0.015 to
+0.142 dB and mean absolute third-octave band difference was 0.064–0.167 dB.
No impacts were virtualized. This validates overall track-layer level/timbre,
not identical waveforms or subjective equality: 10 ms envelope correlation was
0.57–0.86; loop phase, native mixer automation and compressor behavior differ.
The reference excludes electric traction, other trains and station turnouts.
The game's detailed stock also has different locomotive geometry and listening
positions. Do not treat the comparison as proof that the entire game sounds
like the user's videos.

Fixed two actual perspective errors: head-out no longer uses the enclosed-cab
impact/squeal filter; walking in a passenger coach retains passenger balance
and filtering instead of reverting to pilot acoustics. Walking in a DTC driving
compartment remains a cab (local z below -6 m). Geographic audio copies this
listener context across origin rebases. Approved sound banks are unchanged.

Reproduce: run `node tools/audio-comparison/serve.mjs`, open its localhost URL
and render the six references. Run `tools/check_onboard_audio.gd` with the real
renderer, `--audio-driver Dummy --fixed-fps 120 --write-movie .local/onboard-ab/native.avi`
and user argument `--capture`. Do not use the headless dummy renderer for movie
capture. `tools/audio-comparison/compare.py` requires NumPy and reports spectra,
RMS, peaks and envelope correlation from `.local/onboard-ab`. Optional isolated
impacts use the page checkbox and native `--strikes`; preserve full-mix captures
before overwriting. The tool server serves only approved reference assets and
binds to localhost. No user recordings or sound banks are modified.
