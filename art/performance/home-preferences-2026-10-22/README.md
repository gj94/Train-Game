# Home preferences / time-browser boarding validation

22 October 2026, development PC Radeon 780M, Godot 4.7.2. This is UI/state
validation, not a performance result for the target RTX 4090 laptop.

- Full source suite: 787 pass, 0 fail. No full timetable rerun/regeneration.
- Current context controller: 97 pass. Existing Home regression: 27 pass.
- Home preferences: 30 native Forward+ checks at 720p/900p. Sound and hardware
  persistence, focus/back hierarchy, guide tabs, mute/reset and failed writes.
- Time browser: 23 native and 23 headless boarding checks; 20 native preview
  checks including finished-day disabled boarding. Complete railway snapshots
  are byte-equal before and after entering the moving service as a passenger.
- Native screenshots visually inspected. No extracted-distribution game run.
- Godot MCP rescan and error check: no editor errors.

Fixture corrections: sound category lookup is case-insensitive (Godot title
case); timeline source scene is frozen before its first update for state-only
headless checks. The initial unfrozen Dummy-renderer attempt generated RID
errors during GPU mesh streaming; final headless and native logs are clean.
The legacy `check_controller_playable.gd` still refers to obsolete menus and
fails 35 assertions; `check_controller_qol.gd` covers the current 97-check scheme.

Source/UI changes preserve simulation and prepared railway files. R44 remains
the live release while the additional QoL work continues.
