# Controller and signal validation — 19 October 2026

Source checkout, Godot 4.7.2, development PC Radeon 780M. These are not target
RTX 4090 Laptop performance measurements or tests of an exported download.

Full headless regression: **625 passed, 0 failed** after the walking interaction fix.

## Controls and interface

- `tools/check_controller_qol.gd`: 70 checks with LHB, 70 with VB8 and 70 with VB16.
  ICF passed the preceding 69-check revision (before adding the seat-fixture
  availability assertion; the control behavior was unchanged).
- Native standard-layout events exercise the actual source scene and GUI:
  tap/hold disambiguation, ownership, coast detent, following views, coach movement,
  passenger seating/head-outs, input release gates, guide tabs, menu parents,
  saved rear camera/headlights, and the HUD setting.
- `tools/check_walking_playable.gd --fleet=lhb`: 181 checks pass after fixing
  blocked exterior-door notices masking aligned interior passages.
- Controller screenshots are 1280×720 output using Compatibility and dummy audio.
  The recorded renderer warnings concern unsupported SSA/SSIL in that UI fixture.
  All four guide tabs fit; smaller viewports can scroll.
- Physical-controller comfort, wireless behavior and haptic feel remain playtests.

## Signal optics

`tools/check_signal_visibility.gd` uses Forward+, 4× MSAA, the game's AgX tone
mapping, glow and route depth-fog distances. All 22 checks pass:

- Each of red, yellow and green is detectable at 20, 200 and 600 m, day and night.
- The rear face shows no lit aspect.
- An intervening wall occludes the light.
- At 600 m, the day red/yellow/green differences cover 8/3/5 pixels above the
  test threshold; night differences cover 11/16/12 pixels.

The scene provides a clear, straight sightline. It does not imply visibility
around bends, through trains/buildings, in every weather or at arbitrary distance.
The shader's small optical footprint is depth-tested and bounded; it is not a
HUD marker. Both geographic and small-layout signals use the same shared asset.

Full-resolution captures and the renderer's output/error logs are alongside
this file. Source references and provenance are recorded in `docs/assets.md`.
R33 remains the published build; this is a source update for the next release.
