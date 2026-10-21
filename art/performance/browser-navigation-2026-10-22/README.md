# Browser/controller QoL — 22 October 2026

Source Godot 4.7.2, development Radeon 780M. Native Forward+ at 1280×720 and
1600×900, Dummy audio. No extracted-distribution gameplay or full-day rehearsal.

- Full source suite: 797 passed; controller contexts: 97.
- Native browser: 36 checks, including actual joypad press/release events through
  Input.parse_input_event, native popup Viewports, Home settings/guide, station
  paging/cancel, nearby roster, inaccessible platform, empty day, corrupt hash,
  retry and invalid-catalogue recovery. Full railway bytes remain unchanged.
- Native Home preferences: 30 checks using the same real event pipeline.
- Existing native timeline passenger boarding: 23 checks passed during this batch.
- Inspected screenshots include a stopped train's waiting advice at 720p,
  900p and a recoverable preview error. All nearby-service detail panels fit.

An earlier direct-method fixture missed native popup input and duplicate engine
ui_* joypad bindings. Real input injection exposed both; native popup events now
route explicitly and only native joypad UI bindings are removed. Keyboard and
mouse bindings remain. Final passing logs are stored here.

Reproduce from the project root with the configured Godot executable:

```powershell
& $g --headless --path . --script tests/run_tests.gd
& $g --headless --path . --script tools/check_controller_qol.gd
& $g --path . --audio-driver Dummy --script tools/check_browser_navigation.gd -- --event-pipeline
& $g --path . --audio-driver Dummy --script tools/check_home_preferences.gd -- --event-pipeline
```

No changes to sim/, persistence/ or prepared timetable data. See
[playtest guide](../../../docs/journey-library.md).
