# Saved journeys

Open **Esc / controller Menu → Save journey** or **Load journey**. There are
five numbered slots and a separate **Quick save**. **Ctrl+S** quick-saves;
**Ctrl+L** opens the load list. The same actions are reachable entirely by
controller: D-pad/left stick chooses, A activates, B goes back. Overwriting a
manual slot and loading a journey ask for confirmation, with Cancel focused.
Quick save replaces its own slot immediately and keeps the previous backup.

Each entry shows the service, game day/time, completed stops and local save
timestamp. A restored game starts **paused**. Check the power/brake setting,
AI/manual driver and fast-forward multiplier, then select Resume.

## What resumes

- All trains, including deleted services remaining absent: occupied head-to-tail
  paths, speed, odometer, formation, driving handle, emergency brake and AI mode.
- Timetables, actual arrival/departure records, missed calls and passenger
  journeys, including partially completed boarding/alighting and door timers.
- Point positions, cleared/locked signal routes and route owners, dispatch
  priorities, operator holds, waiting ages, overtake commitments, future-platform
  reservations, journal, depot workings and passenger results.
- Your assigned service, authored service definitions, time multiplier,
  protection setting, camera angle, coach/seat, head-out side, detached external
  view, walking position inside a coach or on a platform, and dispatch map view.

Scenery, train presentation and audio voices are rebuilt around that state.
Audio playback tails and visual suspension transients restart; held inputs are
neutralized. Display and controller preferences remain local to the PC. The
game does not save automatically or restore an unsaved session after a crash.

## Files and compatibility

**Open saves folder** in either list opens the storage location. On a standard
Windows installation it is `%APPDATA%\Godot\app_userdata\Train Game\saves`.
Saves survive replacing/extracting a new game build because they live outside
the portable game folder. Copy this folder to the same location on another PC
to transfer saves. Use compatible builds on both machines.

Each slot is `save-1.tgs` through `save-5.tgs`, or `save-quick.tgs`. The `.bak`
file is the previous version, selectable directly in the load list. Writes use
a verified temporary file before replacement; overwriting an unreadable primary
does not replace its good backup. Incomplete files and checksum failures show
an error and leave the current run intact. Do not rename `.tmp` files as saves.

Checkpoints are data only, with object deserialization disabled. The save format
has its own version and a track/platform/signalling signature. Unknown versions or changed
track geometry, passenger faces, depots or signals are rejected rather than applying old reservations to a
different railway. R13 and earlier did not create resumable save files. Changes
to checkpoint semantics or incompatible rolling-stock/interior datums must bump
`WorldSnapshot.VERSION`; no automatic migration is promised yet.

## Verification and playtest

The headless suite checks exact state and continued simulation equivalence,
the Turavur overtake, future-platform commitments, passenger transfers, deleted
services, operator settings, depot workings, backups and corrupted files.
`tools/check_save_playable.gd` reloads the actual main scene through the menu,
tests controller confirmation/cancellation and moving-coach restoration. Add
`-- --kerala` for platform exit/save/load. No extracted distribution is needed.

1. Drive for a while, quick-save, continue, then load Quick save. Compare the
   game clock, speed, handle, next stop and surrounding trains before resuming.
2. Save while waiting for an overtake and during passenger boarding. Check that
   the same trains retain their routes and passenger totals do not restart.
3. Save while walking in a moving coach, and separately on a platform. Restore
   each and continue walking/boarding. Check head-out and free-camera views too.
4. Overwrite a numbered slot, then load its previous backup. Cancel a load and
   check that the current journey is still intact.
