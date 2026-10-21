# R43 menus and dispatcher

The pause hub groups actions into five sections, remembers the selection in each,
and uses the same colour, focus and spacing rules as the service browser,
settings, controller reference, service designer and dispatcher.

| Pause section | Contents |
| --- | --- |
| Journey | Resume, progress, skip, time speed, quick save, save and load |
| Train & camera | Driving actions, camera/walking, coaches, dispatch, HUD and labels |
| Settings | Graphics, sound mixer, HUD/recovery, controller, skip events, display |
| Reference | Controller layout, scenario/keyboard help, driving and sound tools |
| Session | Service selection, service designer, fleet, route, restart and quit |

LB/RB changes sections. D-pad/LS navigates, A selects and B returns; B from the
hub resumes. Keyboard Q/E changes sections, arrows/Enter navigate and Esc goes
back. Submenus return to their caller. Destructive actions still ask separately,
with Cancel selected first. Graphics rows explain the highlighted setting and its
cost before opening the value selector. Time speed marks the selected rate.

## Dispatcher

X or L3 centres **your assigned train** at a local zoom even after you inspect
someone else. It clears search/waiting filters that could hide your service.
Your full occupied length is blue, with a YOU label. Other trains are amber;
labels are separated when space allows. Select a train's occupied footprint to
inspect it, including where the train overlaps a signal marker.

Y toggles following the inspected train; manual pan stops following. The Follow
button shows its state. LB/RB rotates map/timetable, services, inspector and
activity; focus is remembered while its control remains visible. LS/D-pad
navigates controls outside the map. On the map LS pans, triggers zoom and D-pad
selects targets. RS scrolls the focused panel. View switches map/timetable.

Active / Waiting / All filters reduce service-list clutter. The inspector keeps
View train and Take control separate. Dispatch tools expands platform, hold,
priority and deletion controls. Existing confirmations and interlocking remain.
The top bar shows the assigned service, driver, clock and live/paused status.

## Loading

Loading is partly threaded. Railway-state restoration runs on a worker, resource
requests can load asynchronously, station assets have a preparation worker, and
scenery generation uses 2–8 workers based on logical CPU count. Attaching nodes
to the live scene and some initial resource/model setup still run on the main
thread. Large station assembly and rendering preparation can dominate the tail.

The scenery screen shows completed nearby sections, queued/building/attaching
counts, the station being prepared and elapsed time. The progress bar measures
section completion, not elapsed time: one station is much more work than one
small track section. Version remains visible. Only nearby required work gates
entry; distant scenery continues afterward.

During the loading overlay, scene attachment has an 8 ms / 96 top-level-child
target per frame; driving retains 2 ms / 24. A single child hierarchy can exceed
a time target. Ready station jobs return to proximity order and nearby pending
attachments take priority. Scene-tree ownership remains on the main thread.
No asset fidelity, simulation, signalling, timetable or prepared data changes.

## Checks and playtest

The UI fixture checks all pause actions, remembered focus, 720p/900p layouts,
dispatch assignment safety, local zoom/follow, all four focus areas and loading.
Source controller integration covers the actual button routing. Stationary native
startup verifies scenery completion with an unchanged railway clock. Full
headless unit tests remain required; full-day timetable simulations and prepared
state regeneration are intentionally excluded for this presentation release.

1. Pause with Menu. Cycle all five sections using LB/RB; open a submenu and B
   back. Revisit a section and check the previous action stays selected.
2. Open Settings > Graphics; highlight rows to read their effect. Set time speed
   under Journey and verify the selected mark. Check save/load, mixer and guide.
3. Open Dispatch, inspect a different train, then X. It must locate your own
   service without changing the driver. Y follows; LS pans and cancels follow.
4. Use LB/RB through every dispatcher area, RS to scroll, View for timetable,
   and B back. Expand Dispatch tools and cancel a handover/deletion prompt.
5. Start a service and watch the loading phases/version; the clock stays still
   until the nearby railway is ready. Try both a gamepad and mouse/keyboard.

Synthetic controller events do not replace a physical Xbox feel test. Local
startup timings are development-PC observations, not RTX 4090 Laptop results.
