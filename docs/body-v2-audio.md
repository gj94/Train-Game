# Approved BODY V2 audio

**Superseded runtime:** see [enhanced-audio.md](enhanced-audio.md) for the current
benchmark squeal, multiple contacts and passenger views. This document preserves
the earlier one-joint reference and its regression checks.

The reference `game/body_v2_audio.gd` ports the complete website the user approved,
not just its WAV files. Source snapshot:
`D:/ClaudeWS/platform-body-v2-approved-20261006-022055/platform-experience`.
The snapshot is unchanged. The sibling Railway Sound Lab owns
`profiles/platform-body-v2/` and `tools/export-body-v2-godot.mjs`; run that exporter
against this checkout to regenerate `assets/sounds/body_v2/` and `body_v2_data.gd`.
It checks SHA-256 hashes before exporting. Original source/provenance copies live
in that lab profile; no raw reference video is packaged.

## Preserved rules

- Eight original mono 48 kHz / 16-bit kernels, 16,384 samples each; full 341.333 ms
  decay, 21.3333 ms attack lead, playback pitch 1 at every speed.
- Axle variant `(vehicle*3 + bogie*2 + axleIndex) % 8` and approved natural loads.
  WAP-7's six axles use the loco load; coach axles retain their varied strengths.
- Master 0.65, impact and rolling strength unity after website normalization,
  neutral body/brightness filters, no reverb or additional oscillators.
- One fixed joint at a stationary observer; each bogie emits the unchanged
  eight-second rolling bed, staggered by `(bogieIndex * 0.731) % 8` seconds.
- Equal-power stereo panning; inverse-distance attenuation, 4 m reference,
  1.2 rolloff, 600 m cap. Rolling normalization is the maximum distance weight
  divided by the square root of the sum of squared weights.
- Mild rolling-only Doppler `343/(343 + 0.3 * radialSpeed)`, smoothed over 40 ms;
  rolling normalization and listener position use the website's 35 ms smoothing.
- Train-bus compressor: threshold -4 dB, ratio 4, attack 2 ms, release 150 ms.
  A 1.255 dB makeup gain reproduces the browser's implicit output gain, measured
  against its bypassed mix at all three comparison speeds.

The native Godot compressor does not expose Web Audio's 3 dB soft knee. Its
resampling, buffer timing and dynamics backend also differ. This is a faithful
asset/scheduling/mix port, not a claim of sample-identical browser output.

## Game adaptations

`body_v2_model.gd` contains pure acoustic calculations and axle mapping. It does
not advance physics or depend on scene state. The existing physical joint
scheduler uses the rendered route position so sound contacts agree with visible
wheels through acceleration, braking, reverse travel and route transitions.
Impact starts use silent padding and a native sample offset, preserving the full
attack between render frames. Padding and stereo channel routing do not alter PCM.
All WAV imports explicitly disable lossy QOA compression. The project mixes at
48 kHz, matching the approved source.

The nearest existing visible gap supplies impacts. Overview uses a platform ear
near camera focus, 5.8 m to the side and 2.73 m high; onboard views use actual
camera position. A moving observer can change the listening joint. This extends
the website's fixed trackside demonstration, without inventing additional
simultaneous joints or claiming the reference proves track-joint spacing.

Above 0.5 m/s there is no extra speed gain. Below walking speed, rolling fades
to silence; a stopped train emits no new contacts. Pausing freezes the players.
Stock changes and teleports reset contact scheduling. Comma/period and brackets
remain optional user adjustments; a fresh game starts with the approved balance.

## Checks and listening

`tests/test_body_v2.gd` checks approved file hashes, every routed impact PCM sample,
axle identity/load mapping against an original website fixture, panning,
normalization, visible-joint selection, and spacing at 25–160 km/h in both
directions at 30/60/120 render fps. Existing scheduler tests cover acceleration,
braking, stopping and transitions. The actual native-player check is
`tools/check_body_v2_audio.gd`, included in Windows packaging.

For matching geometry, that check uses the website's Co-Co plus 20-coach fixture,
42 rolling emitters, one joint, default listener/orientation and first-coach
contact at one second. Eight-second passes produce 11/29/46 contacts at
30/71.6/120 km/h; the stopped case produces zero. `-- --capture --stems` also saves
isolated strikes and rolling for diagnosis. Offline capture requires the graphical
renderer with Movie Maker at 120 fps and 48 kHz; headless rendering has no movie
texture. Local comparison scaffolding imports the original website audio/model
code unchanged into a browser OfflineAudioContext.

To playtest, download the new portable ZIP and extract into a fresh folder.
Use the default WAP-7/mixed LHB formation, A for AI, Tab for exterior, and inspect
a visible joint beside an LHB bogie. Compare 30/60/120 km/h where the route allows:
pair gaps should halve when speed doubles, while the impact tone stays the same.
Brake to a stand, resume, then change ends and repeat. Use V to check the adapted
passenger perspective. The closest reference comparison is a stationary trackside
view; onboard audio is not a newly fitted interior recording.
