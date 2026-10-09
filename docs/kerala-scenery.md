# Kerala coastal scenery

## References and visual direction

Research checked 9 October 2026. This route follows the coastal lowlands from
Ernakulam through Alappuzha, Kollam and Thiruvananthapuram, then enters Tamil Nadu
on the approach to Nagercoil. A generic tropical forest, or Munnar's tea hills,
would not describe that journey.

| Reference | Detail carried into the scenery |
| --- | --- |
| [Kerala Tourism: Kumarakom's traditional homes](https://www.keralatourism.org/kumarakom/nalukettus-kumarakom.php) | Deep tiled eaves, timber veranda posts, shaded sitting ledges, courtyard wells and domestic compounds. The new house is a veranda house, not a claim to reconstruct a complete nalukettu courtyard plan. |
| [Kerala Tourism: modern houses](https://www.keralatourism.org/kumarakom/modern-houses-kumarakom.php) | Mix traditional tiled silhouettes with contemporary concrete homes, balconies and rooftop services. |
| [Kerala Tourism: Kuttanad](https://www.keralatourism.org/destination/kuttanad-alappuzha/59/) | Open cultivation divided by bunds, coconut planting and waterways. Fields should read as fields rather than scattered trees on the same lawn. |
| [Kerala Tourism: Munroe Island](https://www.keralatourism.org/video-gallery/munroe-island-kollam/1879//) | Small craft, fishing activity and planted canal banks. Used as a regional reference, not an assertion that the railway passes through those photographed locations. |
| [Kerala Tourism: Varkala topography](https://www.keralatourism.org/varkala/varkala-topography.php) | Laterite and local terrain variation. Retain the route's mapped elevation rather than inventing coastal cliffs beside the tracks. |
| [Kanniyakumari district: agriculture](https://kanniyakumari.nic.in/agri/) | Paddy, coconut and banana in the southern landscape; increase the banana mix approaching Nagercoil. |

Reference photographs informed shape and composition only. No downloaded
reference pixels or third-party models were added. The new geometry is original
project work; existing registered CC0 textures retain their provenance.

## Implementation

- Eleven new editable Blender masters and portable GLBs: veranda house, laterite
  cottage, balcony villa, tiled roadside shop, banana clump, country canoe,
  fishing skiff, courtyard well, net rack, green rice and ripe rice.
- Buildings include recessed openings, grills, chajjas, steps, hip and ridge
  tiles, gutters, porch columns, balcony railings and rooftop equipment.
  Candidate fitting tries both footprint axes and faces the closest mapped road.
  Entire measured bounds, including verandas, remain inside the mapped footprint;
  storey height is never stretched. Explicit industrial/tall/irregular envelopes
  still use the mapped reconstruction. A sparse shop mix is inferred only for
  otherwise unclassified low buildings beside a road.
- Dry compound walls and wells require clear land outside mapped buildings,
  roads, water, tracks and station sites. Long walls are rejected on steep ground.
- Boats require their complete rectangular hull envelope to fit inside a water
  polygon, including subtraction of islands/holes, plus obstacle clearance.
  A nearby dry bank must be close to the water level. Planting and net racks give
  these isolated working banks context; at most three boats are added per tile.
- Mapped agricultural land receives green, ripe, wet/seedling and harvested
  parcel treatments. Bund coordinates and crop stage use absolute route metres
  so tile streaming/rebasing cannot move them. Rice geometry appears close to the
  railway; palms and shrubs stay on bunds. These parcel boundaries and stages
  are artistic reconstruction, not cadastral or seasonal survey data.
- Precise water geometry overrides coarse dry land-cover samples. Mixed shoreline
  terrain cells refine from 8 m to 2 m locally, reducing angular bank clipping.
  A spatially indexed 10 m grading band connects the dry bank to the water datum;
  tile clipping edges and protected railway/station ground are excluded.
- New meshes/materials preload before worker threads. Plants use spatial
  MultiMeshes: rice fades at 145 m, banana at 300 m, small working-bank props at
  500 m. Existing distant tree impostors remain in use.

Native asset and route captures are kept under
[`art/scenery/kerala-variety`](../art/scenery/kerala-variety/). Whole-scene
primitive counts depend heavily on nearby detailed trains/station buildings and
camera direction. Nagercoil rice views measured about 16.9–24.1 million primitives
with different camera positions and crop coverage. This is not a frame-rate guarantee for the other PC; use F10
there to check the final build in the same passenger/exterior views.

## Rebuild and check

Use the machine paths in [pc-setup.md](pc-setup.md). Background Blender:

```powershell
& .local/blender/blender-5.2.1-windows-x64/blender.exe --background --python tools/blender/build_scenery.py -- --only=kerala_veranda,laterite_cottage,balcony_villa,coastal_shop,banana_clump,country_canoe,fishing_skiff,courtyard_well,fishing_net_rack,rice_green,rice_ripe
& .local/godot/Godot_v4.7.2-stable_win64_console.exe --headless --path . --editor --import
& .local/godot/Godot_v4.7.2-stable_win64_console.exe --headless --path . --script res://tests/run_tests.gd
& .local/blender/blender-5.2.1-windows-x64/5.2/python/bin/python.exe tools/check_scenery_assets.py
```

`tools/capture_kerala_scenery.gd` renders the real main scene, pauses the simulation,
waits for streaming, visits requested stations and captures homes, nearby working
banks, rice fields when present, and the wider landscape. Run with
`-- --codes=KUMM,TUVR,NCJ --output=res://.local/kerala-check`.
`tools/inspect_scenery_assets.gd -- --only=banana_clump,kerala_veranda,coastal_shop`
is the isolated geometry/material check. Neither tool modifies a saved run.

## Playtest

1. Start the Kerala Coast route. Open **D**, select **KUMM / Kumbalam** in the
   station picker and choose **VISIT YARD**. Inspect water banks from the
   free camera, then try a passenger window: check the small boats, net racks,
   coconut planting, varied tiled homes and narrow clear rail corridor.
2. Visit **TUVR / Thuravur** for roadside shops, verandas and compounds. Look from
   both street and track sides; entrances should face nearby roads and neither
   walls nor plants should cross a mapped road or platform.
3. Visit **NCJ / Nagercoil Junction** and inspect the cultivated approaches north
   of the station. Check the green/gold/wet field patches, rice rows, open bunds
   and increased banana planting. Do not expect all mapped farmland at Thuravur
   to be beside the track: much of it is around a kilometre away.
4. Move away and return, and visit a distant station before returning again.
   The same buildings, plots and boats should reappear without shifting across
   tile boundaries. Use **F4** to hide the HUD and **F10** to compare rendering
   performance in passenger and exterior views on the target PC.
