# Enhanced platform acoustics and passenger views

Active player: `game/platform_audio.gd`. The reference is the user's newer
`platform-squeal-benchmark-src-md-20261006-221237/platform-experience/Acoustics.md`,
superseding the earlier curve-squeal snapshot from 21:56. The original nine BODY V2
WAVs are unchanged. The old `body_v2_audio.gd` remains a regression reference.

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
Existing ordinary track remains **13 m jointed rail**; the website's optional
39 m SWR setting is not silently substituted for visible game gaps. The active
player now hears multiple physical joints. Inside point assemblies, ordinary
periodic gaps are replaced by rail-specific interfaces. Toe, heel and crossing
positions derive from the existing game geometry, rather than assuming every
game turnout is the website's 39.975 m assembly. Each complete modeled point has
11 contacts per axle: seven interfaces, two quiet welds, one switch transfer and
one stronger nose transfer. Check rails do not generate invented gap impacts.

The scheduler sweeps actual axle route positions and interpolates crossing time.
A short prediction preserves the 21.333 ms pre-contact attack; invalidated future
contacts are canceled on motion/route changes. Native silent padding places
starts between display frames. More distant arrivals wait in a queue before
native scheduling. Debug records retain physical and heard times and identify
virtualized events. The scene's joint marker flashes at heard arrival.

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

Native voice budgets are 24 filtered impact locations and 12 squeal voices
(including fading tails) per train. Impact locations are prioritized by received
level; all physical contacts remain in the diagnostic trace. Squeal uses the
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
- **Esc → Passenger views** offers the same three choices.
- **PgUp/PgDn** visit other coaches; **left/right** change position; **Home**
  switches aisle/seat; right-drag looks around. **V** returns to the cab.

Generator and luggage vans without passenger interiors are skipped. First/last
refer to the current direction of travel. The default seven-coach mixed LHB rake
selects vehicle indices 1, 4 and 7. The 20-coach LHB and other passenger fleets
use their actual eligible coach list. Entering these views preserves AI/manual
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

Playtest a freshly extracted build at normal simulation time. Use A for AI and
Alt+1/2/3 to compare coach positions at 30/60/120 km/h where allowed. Confirm
wheel-pair gaps shorten with speed while impact pitch stays fixed; brake to a
stand and restart. Traverse a curved turnout slowly and compare with straight
running, then pause/resume and change coach repeatedly. The new passenger balance
is an airborne listening model, not a separately calibrated carbody vibration path.
