# Visual fidelity pass — 7 October 2026

The detailed WAP-7 stays intact. This pass improves the surrounding scenery and
permanent-way materials using the modest performance increase the user approved.

## Assets and materials

- Rebuilt 14 building types with 12 mm rounded masonry edges. Small fittings keep
  their original geometry; each building still has one batched draw surface.
  Plaster wear exposes brick patches, windows have darker backing and uneven
  blinds, and projected normal maps follow the actual surface orientation.
- Rebuilt two broadleaf crowns with denser, bent leaf cards carrying registered
  CC0 leaf photographs. Coconut palms have 23 fronds, including dry lower fronds,
  and bark shading. All four trees have freshly baked eight-view distant atlases.
  The broadleaf names are legacy asset identifiers; the mixed leaf/branch forms
  are ornamental approximations, not botanically exact species.
- Added 8,471 spatially batched, irregular grass/weed patches along the corridor.
  Each patch contains 3,024 triangles, is visible only nearby, and fades out at
  150 m. Placement keeps whole patches clear of tracks, maintenance paths,
  cable troughs, open drains, field plots and building footprints.
- Rice blades are narrower, denser and have varied height, lean and base shading.
  Terrain retains more fine texture at distance. Roads show smaller-scale cracks.
- Station concrete, plaster, paving and metal now use the registered photographic
  PBR maps instead of colour noise alone. Roof sheets have varied weathering,
  overlap seams and runoff; paving has small joints and varied wear.
- Five platform passengers have integrated nose/cheek/jaw geometry, smaller eyes
  and brows, revised hairlines, collars and pockets. They remain static scenery
  figures with simple skin/clothing materials, not scanned photoreal characters.
- Ballast and sleepers have a darker, weathered finish. Rail/joint geometry,
  39 m audio spacing, simulation, controls and sound data are unchanged.

Native comparison pictures are in `art/scenery/fidelity-preview/`.
`index.html` contains a same-camera before/after slider; these are actual game
captures, not Blender beauty renders or generated concept pictures.

## Validation and performance

The headless suite passes 155 tests. The native scenery audit passes 99 checks,
including all 8,471 patch positions and release of scene resources on reload.
The Dummy renderer cannot read back MultiMesh transforms; the headless variant
explicitly skips that one check. Asset audits validate all 42 original geometry
GLBs, registered source hashes and 43 self-contained editable Blender masters.
The focused permanent-way check passes. Native captures compile the actual
shaders and show the three stations, town/village/rural views and close trackwork.

Performance uses `tools/profile_rendering.gd`: six trains, deterministic seed 0,
paused identical camera positions, 45 warmup frames and 120 samples per view,
Forward+, unchanged quality settings, 1280 × 720, VSync off. This host uses a
Radeon 780M integrated GPU; results are not measurements of the user's RTX 4090.

| View | Before mean frame time | After mean frame time | Before / after GPU time |
|---|---:|---:|---:|
| Cab | 27.09 ms | 27.33 ms | 26.27 / 26.32 ms |
| Exterior | 35.98 ms | 38.57 ms | 35.03 / 37.73 ms |
| Passenger | 21.24 ms | 22.66 ms | 20.31 / 21.75 ms |

The measured increase is about 1% cab, 7% exterior and 7% passenger frame time.
These are short controlled samples, not a route-wide or long-duration FPS claim.
Raw measurements are `.local/fidelity-before.json` and `.local/fidelity-final.json`.

No extracted-package or repeated distribution tests are run, per user preference.

## Playtest

1. Start a traffic scenario. Press Tab and inspect the platform roofs, paving,
   nearby buildings and passengers. Zoom close enough to see surface detail.
2. Press A to let AI drive out of the station. Use Alt+1/2/3 and look sideways at
   tree canopies, rice plots and the irregular vegetation beside the railway.
3. Use F10 at your normal resolution to compare cab, passenger and exterior frame
   times with the previous WAP-7 build. Keep the same scenario/camera for an A/B.
4. Check that grass does not cross the maintenance path or obscure the running
   rails, and watch tree/grass transitions as the train moves.

The route still uses repeated modular buildings and fictional, planned settlement
layouts. This improves their surfaces, silhouettes and nearby detail; it does not
turn the entire route or its static people into a photogrammetry environment.
