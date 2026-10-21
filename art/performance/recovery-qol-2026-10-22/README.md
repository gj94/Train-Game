# Save/recovery QoL validation

22 October 2026; source project, Godot 4.7.2, development Radeon 780M. These are
UI and state checks, not target-PC performance claims.

- 789 headless units pass; 97 current controller checks pass.
- 23 journey-library checks pass after saved-page navigation changes.
- 21 moving-coach save/load checks pass, including exact railway restoration.
- 25 native recovery checks: failed write keeps current journey; retry/cancel;
  protected load; manual saves retained; repaired path saves before Home.
- 25 native explicit-discard checks: load the chosen passenger save despite a
  failed recovery only on explicit discard, and explicitly leave without saving.
- Damaged primary is visible, not launchable; backup is selectable; Continue
  skips unreadable entries. New optional role/progress metadata is shown.
- Screenshots visually inspected at 720p. No extracted-distribution gameplay,
  full timetable rehearsal/regeneration, simulation or prepared-data edits.

The `Could not create directory` errors in native logs are intentional: a file
blocks this fixture's `.local` save directory to test write failure. Other
runtime errors are absent in the final native logs. All files are isolated
under `.local`; no user save slots are modified by these fixtures.

Fixture repairs: reload needs an instantiated PackedScene, not a bare script
node; solo formations have no scheduled stop count, so use prepared K1; freeze
source rendering for state checks and hide its now-inactive loading overlay.
An initial Southern native fixture reached the existing shader-instance buffer
limit because that legacy world builds all scenery at once. That unrelated
renderer limit is recorded for follow-up; this commit does not alter it.

R44 remains published during this additional QoL work window.
