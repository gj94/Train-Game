# Journey controls and cross-day layout audit — 22 October 2026

- Native Home/controller guide: 32 checks using real joypad events.
- Headless in-journey controller contexts: 99 checks, including all five guide tabs.
- Native timeline layout: 24 checks at 720p, 182 active-service inspections over
  six existing snapshot times (08:00, 09:30, 11:00, 14:00, 20:00, 23:00) in each
  Standard and Intensive day. No overflowing footer/version; every complete
  railway snapshot is byte-identical before and after inspection.
- The 797-test suite passed immediately before this reference-text/test-fixture
  change; it was not repeated for a help-page addition. No simulation changes.

Development Radeon 780M, Godot 4.7.2 Forward+, Dummy audio. Guide screenshot
inspected at 1280×720. These are source UI checks, not distribution gameplay,
full timetable rehearsal or target-PC performance measurements.

```powershell
& $g --path . --audio-driver Dummy --script tools/check_home_preferences.gd -- --event-pipeline
& $g --headless --path . --script tools/check_controller_qol.gd
& $g --path . --audio-driver Dummy --script tools/check_timeline_layout.gd
```

Playtest: open Controller layout from Home or Pause, use LB/RB to reach
Journeys, scroll with RS, then B to return to the originating menu.


## Preview lifetime and rapid input

24 varied Intensive snapshots: 51 native checks pass. Six repeat loads of the
same two times: 17 native checks pass. Replaced worlds and the final closed
world are released (WeakRef checks), rapid changes commit only the final
requested time, and the scene stays at 58 nodes. Engine-tracked static allocations
vary with snapshot contents; the same-time spread is at most 4,800 bytes.
This is not process RAM, VRAM or a long-running gameplay memory benchmark.

```powershell
& $g --path . --audio-driver Dummy --script tools/check_timeline_retention.gd
& $g --path . --audio-driver Dummy --script tools/check_timeline_retention.gd -- --same-times
```

An initial fixture inference error was corrected by explicitly typing WeakRef;
the retained native logs are the passing runs. No runtime changes were needed.
