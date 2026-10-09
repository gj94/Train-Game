# Coastal graphics — R16, 9 October 2026

The coastal route previously used simple footprint extrusions for almost every
mapped house. Suitable rectangular footprints now receive the detailed scenery
kit: window recesses, verandas, balconies, tiled roofs, tanks and service fittings.
A new original 5,824-triangle bungalow adds a shaded entrance and steps. Its
editable Blender master is included in the source repository. Horizontal fitting
is bounded; doors/storeys retain their vertical scale. Skewed, irregular, very
small/large and incompatible-height buildings keep their mapped geometry.
Raised foundations are filled beneath exposed verandas. Remaining simple houses
have restrained window frames and elongated hip roofs instead of pyramid roofs.

Terrain blends registered grass and laterite photographs at multiple scales,
with broad, irregular variation and separate soil normals. Roads have dusty
edges and laterite shoulders. Mature/young palms, scanned small trees, shrubs and
weed patches give the scenery more height variation. A worker-local spatial index
keeps planting clear of mapped buildings and roads; existing railway and station
clearance checks remain. Planting follows the rendered terrain triangles.

Platforms and forecourts now have worn paving, canopies have sheet/runoff/rust
detail, and forecourts have planters, kerbs, bollards and marked parking bays within
their reserved footprint. Daylight is more neutral and artificial bloom is removed.
The full station/train models, railway graph, dispatcher, sounds and save format
are unchanged. R14/R15 saves remain compatible.

## Native comparison and performance

Open `art/scenery/coastal-fidelity/index.html` for the before/after slider and close
station/neighbourhood views. These are unaltered source-game captures, not Blender
beauty renders. `tools/profile_coastal_graphics.gd` reproduces the camera sequence.
Baseline and final measurements are preserved alongside the images as JSON.

Same seed 0, paused clock, settled streaming, 45 warmup + 120 sample frames,
Forward+, 1280 × 720, VSync off, unchanged 8× MSAA + FXAA, 8K shadows and SSAO/SSIL.
This PC has a Radeon 780M; these are not measurements of the user's RTX 4090 laptop.

| View | Before mean frame time | R16 | Change |
|---|---:|---:|---:|
| WAP-7 pilot | 42.54 ms | 43.92 ms | +3.2% |
| Passenger | 44.14 ms | 44.63 ms | +1.1% |
| Kumbalam exterior | 33.88 ms | 35.96 ms | +6.1% |

The initial heavier tree mix was reduced after profiling. Full near geometry,
distance LODs and existing tree impostors remain. These short samples do not
establish route-wide or long-duration FPS. One early close-camera sample had a
stale coordinate origin after streaming and is excluded from the comparison;
the corrected station and neighbourhood views are additional visual checks.

The asset audit passes for 51 original scenery GLBs and registered source hashes.
All 372 headless tests pass. Regressions cover rotated footprint containment, unsuitable shapes and
heights, deterministic placement and road/building planting clearances.
Native pilot, passenger, Kumbalam, station-close and neighbourhood captures compile
the actual shaders without rendering/script errors. No extracted build is tested.

## Playtest R16

1. Load your existing save or start the coastal stopping service. Compare the cab
   and passenger views with R15 at the same resolution; use F10 for frame timing.
2. In Dispatch, visit Kumbalam without taking over another service. Use external
   free camera (right-stick click) to inspect the station paving, parking and planters.
3. Look at nearby houses: verandas, inset windows, roof ridges/tanks and filled bases.
   Follow the train out to compare young palms, ground cover and road shoulders.
4. Check for vegetation through roads/platforms and for excessive foliage popping.

The route still uses modular reconstructed properties and procedural vegetation.
This is a substantial scenery/material pass, not full photorealism or a surveyed
model of every real house. Open ground, terrain detail and vegetation silhouettes
remain the largest visual limitations.

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
