# Enhanced sound-lab recovery copy

Working source lives in `D:/ClaudeWS/railway-clang-simulator`, which is not a Git
checkout. These files preserve the work with the game. The approved input snapshot
is `platform-squeal-benchmark-src-md-20261006-221237/platform-experience`.

Restore `public/`, `scripts/`, `Acoustics.md`, `TURNOUT-MODEL.md` and `package.json`
into the lab's `profiles/platform-enhanced/`. Put `export-platform-enhanced.mjs`
in the lab's `tools/`, then run it there with the game directory as argument.
The exporter reads the original BODY V2 bank from `profiles/platform-body-v2/`;
restore that profile using the sibling `../body-v2/README.md` instructions if needed.
It calls the unmodified benchmark synthesis, preserves all 262,144 periodic
frames, derives channel-routed PCM and measures original impact energy bins.

`reference-fixture.mjs` independently evaluates original JavaScript expected
values for the native tests. Run it in this recovery directory, passing the game
directory, to regenerate `tests/fixtures/platform_enhanced.json`.

The supplied source-only package omits the original recordings and generated
calibration JSON/images; they are not fabricated or distributed here. Its
recording-report test requires the absent `squeal-fit.json`. Source synthesis,
mode/band, mathematical and lifecycle tests can run without the recording.
