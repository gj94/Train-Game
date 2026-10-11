# Native day/night validation — 11 October 2026

See [the feature and reproduction guide](../../../docs/day-night.md).

- `report.json`: eight paused native source-game cases, High, actual 1600×900,
  safe/default renderer, uncapped frame rate, V-sync off, Dummy audio.
- `stdout.log`, `stderr.log`: 23 checks passed; native stderr is empty.
- PNG files: unedited viewport captures. The synthetic fixture retains five
  trains, 91 vehicles and 5,580 passengers while setting its clock for each
  view. Screenshot timetable advice is not a result of advancing the railway
  to those times.
- `source-sha256.json`: source-file byte hashes from the validated checkout.
  Git line-ending normalization may change raw byte hashes on another checkout.
- `tests.stdout.log`, `tests.stderr.log`, `test-timings.json`: full headless suite,
  558 passed, zero failed; eight new day/night tests.
- `skip.stdout.log`, `skip.stderr.log`: native source-game time-skip validation
  with `--simulation-workers=4`, 33 checks passed, empty stderr. Dummy audio
  validates mute/restoration state without an audible playback assessment.
- `import.log`: final headless editor import, exit 0, no errors or warnings.

This runs on the development Ryzen 7 7840HS / Radeon 780M, not the target
i9-13980HX / RTX 4090 Laptop. Window-focus state was not recorded. Treat the
timings as short visual-check observations, not a release performance claim.
The overview camera is outside the platform light pool; the platform cases
exercise all 24 lights. All cases pause train movement and dispatch.
