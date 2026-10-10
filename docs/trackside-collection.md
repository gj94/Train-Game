# Kerala trackside collection port

Source: [the user's collection at revision 16c06aee](https://github.com/gj94/transport-fever-3-mods/tree/16c06aee07c70eea5ed74e8420116998c27a4895/kerala_trackside_collection).
The runtime manifest records the original SHA-256 and metric bounds for every
entry. Archive parts, complete archives, ZIP integrity and all 52 GLBs were
verified before conversion. There are 44 distinct assets and eight supplied
tree LOD alternatives, rather than 52 distinct building types.

## Fidelity and placement

The port retains original UVs, textures, material groups and nearby geometry.
Static meshes are joined to reduce scene-node overhead; identical image payloads
share external textures. Building fronts are turned to the game's existing
front convention. The source collection remains unchanged. Original gate
mechanism hierarchies are flattened for static scenery; these are not functional
level crossings. Source/font notices accompany the download.

The collection supplies homes, a tea shop, workshops, a coir shed, a well,
compound pieces, coconut palms, jackfruit, banana and wetland plants, crop tufts,
a canoe, permanent-way equipment and utility props. Existing mapped-footprint
placement now uses the detailed houses, shop and workshop with measured bounds.
Planting and paddy placement use the new vegetation. Canoes use their source
waterline and longitudinal axis. Small utility and maintenance groups require
dry, flat ground outside railway/station clearance and mapped obstacles.

All 52 entries are available to the scenery library. Oversized bank/bund modules,
route-number signs and crossing gates are not scattered indiscriminately into
mapped geography. Their presence in the library does not claim a surveyed
real-world installation. The existing station operating layouts are unchanged.

## Distance rendering

- Nearby trees retain the original mesh; supplied LOD1 and LOD2 take over at
  45 and 95 m, with an eight-view impostor beyond 190 m.
- Six buildings retain full geometry to 180 m, then use images baked from the
  actual textured model. Small baked plants transition at 85 m and end at 420 m.
- Fourteen assets have shared albedo and normal atlases. A distant instance is
  two triangles, lit using its baked normals. This is a distant approximation:
  it has no interior or true parallax and should not be used near the observer.
- Spatially bounded MultiMeshes share materials and resources. Distance bands
  use consistent grid sizes and fade margins. Tiny foliage and distant tree
  geometry do not cast expensive detailed shadows.

These distances describe batch origins and include fade margins, rather than
an exact per-leaf transition distance. Source details remain available when the
camera approaches. AA, texture resolution and global lighting quality are not
reduced by this port.

Nine existing building families also have native Godot material bakes: eight
views with all six facade palettes. Beyond 220 m, they use these impostors and
simple shadow hulls; nearby geometry stays unchanged. The billboard shader
accounts for the nonuniform scale used to fit mapped footprints. Rebuild them
with `tools/bake_building_impostors.gd` using the native renderer.

Grass retains 384 bent blades per nearby patch. At 50 and 90 m, it changes to
96 and 24 wider blades with the same seeded positions and spatial batches.
This avoids drawing thousands of subpixel blades farther away while keeping
3D grass nearby and the original ground material underneath.

## Passenger and train visibility

Pilot view retains the occupied locomotive/cab interior and omits seated
passenger meshes. Nearby exterior views restore coach interiors and passengers;
passenger/walking views preserve the occupied coach and adjacent gangway area.
Platform actors and boarding/alighting continue independently. All passenger
counts, destinations and simulation state remain in RailWorld.

Nearby and occupied vehicles retain detailed shadows. Farther vehicles use a
simple shadow hull. Visibility changes are cached per vehicle instead of
reassigning thousands of mesh properties each frame.

Distant unoccupied vehicles select coarser engine-generated mesh LODs. Track
fastenings transition to small silhouettes at 48 m; sleepers retain full detail
to 125 m and simpler solid geometry to their existing 650 m range. Running
rails, points, sleeper spacing and sound-aligned expansion gaps are unchanged.
Nearby AI formations now load scene resources in the background and assemble
one vehicle per frame. Partial formations stay hidden until every carriage,
axle, doorway and sound attachment is ready. Direct player handover can still
finish a pending formation synchronously; one indivisible coach can exceed a
frame budget. This is not a promise of completely stall-free loading.
The route-wide, immutable contact table is shared by the presentation manager;
playback voices, contact sweeps and acoustic histories remain per train. This
avoids rebuilding identical rail-joint geometry for every arriving service.

## Rebuilding

Run `tools/fetch_trackside_collection.py` using Python, then run Blender in
background mode with `tools/blender/port_trackside_collection.py` and
`tools/blender/bake_trackside_impostors.py`. Defaults use the verified files
under `.local/trackside-source/`; outputs go to `assets/models/trackside/`.
Do not run these scripts in an open user Blender scene.
After either atlas bake, run `tools/configure_impostor_imports.py`, then Godot
import. All 46 new atlas images use high-quality GPU compression and mipmaps;
their normal images keep all three RGB channels rather than tangent-normal
packing. This is necessary for both distant filtering and texture bandwidth.

For source visual checks, use `tools/inspect_scenery_assets.gd` with
`--only=tf3_BLD_Home_Verandah_01,tf3_KL_LS_Coconut_Tall_A` and repeat with
`--impostor`. The latter forces the far representation near the camera so its
limitations are visible. Normal gameplay selects it only at distance.

## Playtest

1. Drive out of ERS, then visit Kumbalam and Turavur. Check house grounding,
   road-facing fronts, railway clearance, dense planting and waterline contact.
2. Approach a palm or house slowly in free camera and check both LOD transitions.
3. Start in pilot view, step down into a passenger coach, move along its aisle,
   then look into another train from the platform. Visible interiors/passengers
   should return without changing the actual onboard population.
4. Run the crowded benchmark described in `performance.md`, preferably on the
   RTX 4090 Laptop PC. Development-PC frame times are not target-PC predictions.
