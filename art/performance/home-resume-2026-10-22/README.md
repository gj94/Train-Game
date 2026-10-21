# Home resume feedback — 22 October 2026

Full source suite: 797 pass. Native Forward+ on development Radeon 780M,
Dummy audio, 720p/900p. Home resume 15 checks; journey library 23 checks with
real joypad press/release input injection. No target-PC performance claims.

The resume fixture uses an isolated empty save folder and fixture metadata.
It checks that unreadable newer entries are skipped, backup and passenger role
are visible, long service names fit, failed Continue returns Home, cancellation
restores the initiating menu/focus, and no save file is written by these paths.
An intentional missing-slot failure is visible in the screenshot. Actual
save/recovery round trips were checked in the earlier recovery QoL evidence.

```powershell
& $g --headless --path . --script tests/run_tests.gd
& $g --path . --audio-driver Dummy --script tools/check_home_resume_ui.gd
& $g --path . --audio-driver Dummy --script tools/check_journey_library_ui.gd -- --event-pipeline
```

Simulation, persistence and prepared timetable files unchanged from R44.
No full timetable rehearsal or extracted-distribution gameplay run.
See [playtest steps](../../../docs/journey-library.md).
