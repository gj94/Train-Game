# R25: camera bounds, railway corridor and GPU costs

Measured in the native source build at **1600×900 on the Radeon 780M development
PC**. These are not results from the target i9-13980HX / RTX 4090 Laptop 16 GB /
64 GB machine. The five-train fixture contains 91 vehicles and 5,580 simulated
passengers; all formations remain resident and move in the final live phase.

## Measured GPU costs

The fixed, paused overview costs **56.14 ms GPU time per frame**. Each row hides
one category or disables one effect, restores it, then tests the next. The
ending baseline is 55.88 ms (0.47% drift). Each capture lasts at least eight
seconds with at least 120 frames and no scenery loading.

| Category removed | GPU time without it | Saving from baseline |
|---|---:|---:|
| Vegetation: trees, palms, grass, crops, shrubs | 36.62 ms | **19.52 ms** |
| All five trains | 45.16 ms | **10.98 ms** |
| Directional shadows | 48.53 ms | **7.61 ms** |
| Stations and building geometry | 50.12 ms | **6.02 ms** |
| Terrain and water | 50.67 ms | **5.47 ms** |
| Screen-space indirect lighting (SSIL) | 53.69 ms | **2.45 ms** |
| Running rails, sleepers and other permanent way | 53.80 ms | **2.34 ms** |
| Other scenery, roads, overhead equipment, signs and props | 54.11 ms | **2.03 ms** |
| Glow | 55.42 ms | **0.72 ms** |
| Screen-space ambient occlusion (SSAO) | 56.21 ms | Within run noise |

These are **marginal savings, not additive component timings**. Geometry
removal also changes its shadows, occlusion and indirect-light contribution.
Contents embedded in station assets belong to the station group. Vegetation
is the clearest next optimization target in this view; individual tree species
have not received GPU timers. The source-geometry inventory identifies nearby
jackfruit/coconut foliage as heavy candidates, but counts source triangles
before exact frustum/mesh-LOD selection and cannot prove their individual cost.

## Effect of the corridor limits

| Matched camera | R24 median frame | R25 median frame | Draw calls before → after |
|---|---:|---:|---:|
| Pilot | 55.61 ms | 51.60 ms | 10,008 → 3,611 |
| Passenger | 57.21 ms | 54.49 ms | 11,101 → 4,397 |
| Platform | 51.93 ms | 49.72 ms | 12,884 → 3,797 |

Camera coordinates and captured pixel sizes match in these three comparisons.
Separate-process timings include ordinary run variation: the observed median
improvement is 4.3–7.2%, despite draw calls dropping 60–71%. Nearby shading and
geometry remain expensive. The new overview is lower (55 m offset instead of
95 m), so its timing and the live phase are **not** directly comparable with
the previous overview. No target-PC FPS prediction is implied.

Pilot/passenger/platform request 11 detailed tiles, 13 landscape-only tiles and
13 coarse background tiles. Detailed objects are confined to approximately
220 m either side of the route. Landscape-only tiles keep mapped water and
continuous terrain without buildings or vegetation. Track/signals continue
out to 1,650 m, stations to 2 km, and the simulation covers the entire route.
The free camera ceiling is 60 m above local ground, orbit zoom is 300 m and
the view clip is 2.2 km. Depth fog reaches full opacity before that clip;
Godot's [depth-fog density is an opacity setting](https://docs.godotengine.org/en/4.6/classes/class_environment.html#class-environment-property-fog-density).

## Validation and evidence

- 447 headless tests passed, zero failed. Coverage includes controller/mouse
  zoom, restored high camera positions, origin rebasing, onboard-camera
  exemption, corridor bends/depots, terrain coverage and retained rail/signals.
- Native five-train audit passed; all trains/passengers remain and every train
  travels over 1 m during the live phase. No script or renderer errors.
- ERS overview, pilot and Kumbalam backwater/landscape captures inspected.
  Kumbalam capture timings are not performance evidence: the test suite ran
  alongside this capped visual check.
- [Full benchmark](../art/performance/corridor-2026-10-10/report.json),
  [audited five-train summary](../art/performance/corridor-2026-10-10/summary.json),
  [GPU costs and matched comparisons](../art/performance/corridor-2026-10-10/comparison.json),
  [ERS overview](../art/performance/corridor-2026-10-10/overview.png).

On the playing PC, run from the updated game folder:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\Benchmark.ps1 -CrowdedOnly -RenderCosts -Resolution 1440p
```

For gameplay checks, use R3 at ERS/Kumbalam, hold RB to reach the height ceiling
and LB to descend; try the largest orbit zoom, then L3 to resume pilot view.
Load an older high external-camera save and confirm its view is bounded while
the service and dispatcher-map zoom still work normally.
