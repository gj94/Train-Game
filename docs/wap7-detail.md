# WAP-7 detailed v0.2

The imported WAP-7 uses the user's detailed 39002 master from
[`transport-fever-3-mods`](https://github.com/gj94/transport-fever-3-mods/tree/de45b4e0e4194af47b1182800b7d103409c69478/wap7_photoreal_v02),
pinned to `de45b4e0e4194af47b1182800b7d103409c69478`.
Master SHA-256: `25aa1f264f7dbab9f25e9e2fe27ff2f2e9d6b8ab513133d374717fcff0e24930`.

## Preserved detail

- All **2,885,744** evaluated, visible source triangles: both furnished cabs,
  machinery aisle, instruments, text, seats/stitching, roof equipment, grilles,
  brake rigging and couplers. Hidden older furnishings stay excluded.
- 109 material roles and original image pixels/resolutions, including 6144 × 1536
  side wear maps, 2048 × 2048 nose/buffer masks and instrument artwork.
- Independent bogies, six rolling axles, both pantographs and rear cab-door
  hinges. Dimensions and simulation/axle sound positions remain unchanged.
- Original object/generated material coordinates in full float UV/custom
  attributes, keeping procedural finish attached to the moving parts.

The converter batches 12,331 visible nonempty source objects into 24 rigid groups.
It does not decimate visible geometry. Godot generates distance LODs; near geometry
remains in the imported mesh. Interiors cull beyond 100 metres. Separate simplified
shadow geometry reduces shadow-map work without replacing the visible model.
Structurally identical material graphs share 21 compiled shaders and textures.
The shadow model has 107,006 triangles; it only casts shadows and is never drawn
in place of the detailed visible model.

Godot and Cycles are different renderers. Authored PBR values, ramps, service maps,
roughness and bounded bump are translated. Filtered real-time noise replaces Cycles
Perlin noise; mixed BSDF lobes become PBR parameter blends. Glazing uses restrained
Fresnel transparency instead of Cycles' refractive ray tracing. These are rendering
approximations. Source instruments remain static artwork; the HUD supplies live
speed and brake information. The occupied cab reduces window reflection and tint
so the sky environment does not wash out the forward view; exterior glazing,
instrument cover glass, labels and lenses retain their authored materials.

## Playtest

1. F2 starts the detailed light engine; F3 starts its mixed LHB rake. F9 also offers
   these. In random traffic, select an ICF/LHB service in the dispatch roster.
2. In its cab, **Home** cycles driver, assistant, cab overview and machinery aisle.
   Controller: Menu → Train & view actions → Camera & passengers → Cab position.
3. Right-drag looks around and retains the direction on release. Middle-click
   recenters; right-stick click also recenters. Wheel/LB/RB zoom. Passenger Home
   retains its existing aisle/seat action.
4. Tab goes outside. Inspect grilles, wheels, brake gear and roof close up; move off
   slowly and check axle rotation and pantograph contact.
5. Stop the light engine and press R to inspect the other cab. Alt+1/2/3 still enters
   passenger views; the approved speed-dependent sound is unchanged.
6. F10 shows frame time and memory. Spend several minutes inside, then change views.

## Measured rendering cost

Native Forward+, Radeon 780M, 1280 × 720, six-service scene with simulation frozen,
identical camera/settings, 45 warm-up frames and 120 measured frames per view.
The previous model was loaded as a local A/B fixture in the current scene. This is
an integrated-GPU comparison, not a measurement on the user's 4090 laptop.

| View | Previous model frame / GPU ms | Detailed model frame / GPU ms |
| --- | ---: | ---: |
| Cab | 21.25 / 20.47 | 26.69 / 25.90 |
| Exterior | 34.56 / 33.70 | 35.27 / 34.43 |
| Passenger | 19.37 / 18.64 | 21.15 / 20.38 |

The preserved cab detail has a measurable cost. Shared shader programs and the
separate shadow mesh reduce it without cutting the visible model. A six-minute
moving cab run had constant node/audio-bus counts and a bounded impact queue.
Local evidence: `.local/wap7-legacy-same-camera.json`,
`.local/wap7-detail-final-profile.json`, `.local/wap7-detail-soak.json`.

## Rebuild procedure

Use `pc-setup.md` for this PC's paths. Downloaded source scripts are not executed.

1. Fetch `tools/wap7_v02_sources.json` with `tools/fetch_port_sources.mjs` into
   `.local/wap7-v02-source/`; the fetcher verifies pinned Git blob hashes.
2. Run background Blender with `--background --factory-startup --disable-autoexec
   --python-exit-code 1 --python tools/blender/port_tf3_assets.py -- wap7`.
3. Install unique shaders from `.local/wap7-materials.json` through Godot MCP's
   `create_shader`, using each `shader` filename and `code`. The converter writes
   the material index, source textures and shadow resource alongside the model.
4. The shared `microfinish.res` is rebuilt with native Godot (not `--headless`)
   using `--script res://tools/build_wap7_noise.gd`. Its small original 3D noise
   volume replaces repeated shader hash arithmetic; source maps are untouched.
5. Rescan/import; run `tools/check_wap7_port.py` and `tools/check_wap7_detail.gd`, then run the latter natively with
   `-- --capture` to inspect both cabs, exterior, running gear and machinery.
6. Run the headless suite and release checks before committing/exporting.

`wap7.glb` uses URI-backed binary buffers below GitHub's file-size limit. Each buffer
view is preserved byte-for-byte; keep `wap7_detail/` dependencies with it. Their
SHA-256 digests are recorded in the model manifest.
