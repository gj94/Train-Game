# Graphics settings

Open **Menu / Esc → Graphics settings**. On Xbox controllers, press **Menu**, use
the D-pad or left stick to navigate, **A** to select and **B** to go back one level.
Keyboard arrows/Enter and mouse also work. Pick a group, then a setting and value.
Changes apply immediately and save locally. Use **Resume and compare** and **F10**
to compare the same camera position; opening the menu pauses the simulation.

The initial **High** preset preserves the R25 appearance. **Balanced** changes
8× MSAA to 4×, 8192-pixel shadows to 4096, soft shadow filtering to Low and automatic
mesh detail to Balanced. **Performance** additionally uses 85% render scale, 2×
MSAA, 2048-pixel/100 m shadows, disables SSIL, reduces view distance to 1.8 km and
reduces vegetation, building, exterior train detail and rendered crowd budgets.
Changing any individual value makes the preset **Custom**. Applying a preset
resets all 18 options, including the frame limit and V-sync.

| Group | Individual controls |
| --- | --- |
| Display & image | 3D resolution scale (50–100%), MSAA (Off/2×/4×/8×), FXAA, V-sync, FPS limit |
| Light & shadow | Shadow resolution (Off/2048/4096/8192), distance (100/200/300 m), filtering, SSAO, SSIL, bloom |
| Scenery | View distance (1.5/1.8/2.2 km), vegetation density, vegetation detail distance, building detail distance, automatic mesh detail |
| Trains & passengers | Other train detail distance, visible passenger budget |

Below native resolution, FSR spatial upscaling scales the 3D scene; the UI keeps its
full resolution. Mesh detail adjusts automatic imported LOD selection rather than
modifying the source assets. Vegetation density keeps the same subset of plants
across mesh LODs and image silhouettes. Detail-distance changes keep transitions
aligned, while distant silhouettes retain their reach. Newly streamed chunks and
cached scenery receive the current preferences too. No scene reload is needed.

Train detail changes exterior interior/shadow distances. The occupied cab or coach
keeps its interior, and pilot view still hides seated passengers. The passenger
setting caps animated journey actors across all trains at 35/70/140 seated plus
20/40/80 moving; decorative station figures are separate.
Passenger journeys, boarding, train loads, dwell, physics and dispatch remain fully
simulated. Track and signal geometry is not removed by vegetation/building options.
The view-distance control also adjusts the far haze; the 60 m camera ceiling remains.

Preferences live in Godot's `user://graphics.cfg` (normally
`%APPDATA%/Godot/app_userdata/Train Game/graphics.cfg`). They belong to this PC,
remain separate from journey saves and survive incremental updates. If saving fails,
the menu reports that the change applies only for this run.

## Tuning on the target laptop

The target is an i9-13980HX / RTX 4090 Laptop GPU (16 GB VRAM) / 64 GB RAM. Try
Balanced first at your normal display resolution. For additional GPU savings, try
Medium vegetation detail, SSIL Off, or 85% render scale individually. These are
tuning starting points, not measured frame-rate promises on that laptop.

To benchmark your saved preferences, close the game and run from the build folder:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\Benchmark.ps1 -CrowdedOnly -SavedGraphics -Resolution 1440p
```

Without `-SavedGraphics`, benchmarks use High for reproducibility. Both modes turn
off V-sync and the FPS limit during measurement. Reports include the chosen preset
and all effective graphics preferences. The diagnostic `*_full` crowded cases force
full interior/building/grass detail; use `*_culled` cases for the normal quality policy.

## Playtest

1. Open Graphics settings using the controller. Select vegetation density, change it,
   and confirm focus returns to that setting; B backs out one level at a time.
2. Compare High and Balanced from the same pilot/platform position using F10.
3. Select Performance, go to a passenger coach and then back to pilot. The coach
   should still contain passengers; hidden seated passengers should stay culled in pilot.
4. Set High again and visit another station. Trees, houses and shadows should restore;
   check that no gap opens where vegetation changes from meshes to distant images.
5. Choose a custom frame cap and SSIL setting, quit and reopen: both should persist.
