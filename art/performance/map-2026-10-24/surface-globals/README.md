# Busy-station surface shader allocation repair

The fresh QLN reproduction previously exhausted Godot's 65,536-entry global
shader buffer: 4,090 geometry instances carried an identical Epic flag, alongside
420 independent passenger-door parameters. Both High and Epic allocated copies.
The nine surface shaders now read one project-declared global float. Graphics
changes update it on the main thread; scene activation uses a cached CPU value,
without renderer readback or per-surface material/mesh mutation. Passenger doors
retain their instance parameters. The buffer limit has not been increased.

API verified with the running Godot 4.7.2 ClassDB and official documentation:
https://docs.godotengine.org/en/4.7/tutorials/shaders/shader_reference/shading_language.html#global-uniforms
An initial diagnostic tried server readback, which this engine rejects outside
the editor. The final diagnostic instead renders an independent 8x8 GPU probe.
It reads black/white/black for High/Epic/High, with no renderer errors. Production
code never calls the getter. Earlier failed diagnostic logs remain in .local.

## Validation

- 861 full source tests pass; clean stderr. Three scripts validate in the
  live headless editor; zero editor errors.

- Same fresh QLN source case, railway frozen at time zero, 1440x900: 23,524
  geometry nodes, zero surface instance parameters, all 420 door parameters
  retained. High/Epic/High GPU values 0/1/0. Clean final stderr.
- 51-frame source-material fixture: daylight/dusk/night, three presets and
  six far-route origin-rebase captures. 14 of 15 restored-High images are pixel
  identical. Daylight overview mean RGB difference is 0.003/255; the fixture's
  sky/screen-space history prevents an exact match there. No missing surfaces
  or material change observed in selected native views. Full PNGs remain in
  .local/map-2026-10-24/global-visual-fixture; manifest and representative images
  are retained here. Rebase differences are measured, not claimed zero.
- All 4,893 protected railway, simulation and prepared-data hashes unchanged.
  Existing route/road geometry audits remain applicable: this changes shading
  storage only. No full timetable or extracted-distribution run.
- Development Radeon 780M. This is renderer correctness evidence, not an RTX
  4090 Laptop FPS claim. Remaining QLN bridge-edge ground slit is separate.

Reproduce with the source project and a native GPU:
`--script res://art/performance/map-2026-10-24/surface-globals/reproduce.gd -- --cases=res://art/performance/map-2026-10-24/surface-globals/case.json --output=res://.local/qln-surface-check`
Use `--audio-driver Dummy` for the silent fixture. Do not run extracted gameplay.

After release: visit Kollam, toggle High/Epic/High and travel to another station;
check track/ground detail returns to High and passenger doors still open only
on their platform side. R45 remains available during the overnight work.
