# MEMU driving cab

The cab is an original Indian MEMU-inspired interior, built in background Blender.
It is an interpretation for this fictional railway, not a measured replica of a particular unit.
Browser reference research was blocked in this chat; no third-party photos or models were incorporated.

## What changed

- Formed olive-green desk with separate instrument plate, engraved legends, screws, switches and controller.
- Analogue speedometer reads train speed. POWER and BRAKE dials read demand percentages, not electrical current or air pressure.
- Animated master controller and illuminated power, coast, service-brake and emergency indicators.
- Driver and assistant seats, stitched cushions, armrests, a footwell, ribbed mat and pedal.
- Cream lining, curved headliner, cage fans, ceiling light, sun visors, rubber window seals, sliding-window latches and parked wipers.
- Radio and handset, timetable clipboard, electrical cabinet, rear door and fire extinguisher.
- Revised seated eye position, a wider default cab view, mouse-wheel zoom and more head-turn range.
- The large floating speed readout hides in the cab so it does not cover the desk; numeric speed remains in the top-left HUD.
- F now correctly hides the cab and restores outside audio/labels when returning to the overview.

The radio, toggle switches, fans, wipers, doors and pedal are visual props. The existing keyboard driving controls operate the animated controller and instruments. There is no new pneumatic, electrical or passenger simulation.

## Build and inspect

```powershell
& .\.local\blender\blender-5.2.1-windows-x64\blender.exe --background --factory-startup --python tools/blender/build_cab.py
& .\.local\blender\blender-5.2.1-windows-x64\blender.exe --background --factory-startup --python tools/blender/render_cab.py -- .local/train-art/cab-final
```

The build exports `assets/models/memu_cab.glb` with its original roughness texture embedded. Godot extracts that texture beside the GLB during import. Static meshes are joined by material; animated pivots retain their names. The final asset has 30 mesh objects and about 50,100 triangles before Godot import.

`game/cab_view.gd` owns display state and reads the existing `Train`. Blender +Y is forward and +Z is up; exported instrument pivots rotate around local Godot Y. Keep the `NeedleSpeed`, `NeedlePower`, `NeedleBrake`, `ControllerPivot` and four `*Lamp` names stable. `tests/test_cab.gd` loads the actual exported asset and checks speedometer direction and emergency overrides.

## Verification, 30 September 2026

- 43 headless tests passed; no errors in the standalone playtest stderr.
- Inspected Blender renders of the exported GLB from the driver's seat, desk, rear and assistant side.
- Compared the old and new cabins in Godot from the same seated camera with the same world lighting. Captures: `.local/train-art/cab-before-matched.png` and `cab-after-final.png`.
- Fixed the upper window gaps, wiper joints, buried panel legends and driver's legroom during visual review.
- Live input playtest: C cleared starter, W produced 53% power and departure (observed 12 km/h), speedometer and power dial tracked it, Space stopped the train and lit both brake indicators, X returned the handle to neutral.
- Released emergency and changed ends with R; F hid the interior; cab zoom changed 70 to 66 degrees for one wheel-up event.
- Simulation, sound data, exterior train model and global graphics settings are unchanged.

## Playtest

1. Tab enters the cab; F1 hides the help panel. Right-drag to inspect the desk, fans, seats and rear wall. Release to face forward.
2. Mouse wheel zooms in/out in the cab. Check signal visibility and instrument readability at your TV viewing distance.
3. C clears the starter; W increases power. Check the handle, green POWER light, percentage dial and speedometer together.
4. X coasts; S applies service brake. Space applies emergency: BRAKE and EMERGENCY should light, POWER should extinguish. Release emergency at a stand with Space.
5. Tab or F returns to overview; R changes ends at a stand. Return to the cab and verify the view is usable from the opposite end.
