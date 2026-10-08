# Imported Indian Rail fleet

The user's assets from [gj94/transport-fever-3-mods](https://github.com/gj94/transport-fever-3-mods)
are available through **F9**, or **Escape → Traffic / solo fleet**. Choose a working
and confirm to start at Chennapuram. F2/F3 now use the detailed WAP-7 as well.
See [the v0.2 port notes](wap7-detail.md) for interior viewpoints and preserved detail.

A fresh launch starts **K1, the slow passenger on Kerala Coast**, among 32
services with AI traffic and automatic routing. F1 explains your assignment and
expected waits; PROGRESS/F12 shows stop counts and the next arrival estimate.
Restart keeps the assignment; F9 offers a new random
assignment or a solo working. WAP trains use full-length homogeneous coach
families: 20 seated coaches for K1 and 22 for express workings. Explicit fleet choices and F2/F3 take precedence;
the older low-detail WAP and MEMU are no longer playable or shipped. F7 switches
between Kerala Coast and the shorter Southern corridor.

## Vehicles

| Working | Imported assets | Visible train length |
|---|---|---:|
| ICF express / stopping passenger | WAP-7 + 22 / 20 blue ICF coaches | 511.094 / 466.500 m |
| LHB express / seated passenger | WAP-7 + 22 / 20 red-grey LHB coaches | 548.560 / 500.560 m |
| Vande Bharat 8 | Full-size v02, DTC–MC–TC_EC–MC2 + mirrored half | 191.560 m (192 m coupling pitch) |
| Vande Bharat 16 | Full-size v02, CC trailers and two central EC cars | 383.560 m (384 m coupling pitch) |

Only these four stock families are selectable, with two WAP rake profiles in the Service Designer. The detailed WAP-7 retains both cabs
and its machinery room. Historical WAG masters remain in source history/catalogue
for integrity comparison, but are excluded from the playable package.
See [rakes and research](rakes.md) for class grouping, physical lengths and the
missing utility-car limitation. These are representative fictional formations.

The enhanced Vande Bharat is pinned to published source revision
`91bcc2899eeedccb7497374227d1c81562279640` on `main`, including the newer three
EC masters. Its full-size 24 m car pitch replaces the
older compact interpretation. Bogie centres are 14.9 m apart, axle spacing 2.7 m,
wheel diameter .952 m. The eight/sixteen-car formations have 530/1,128 modelled seats.

All 14,820,268 triangles from the seven current source masters survive in the closest
LOD, including seats, luggage racks, equipment, cab and underframe details.
Meshes are merged only within rigid articulated parts. Pantographs, wheels and
bogies retain separate pivots. Source procedural material graphs are translated
to Godot, preserving source coordinates in full-float custom vertex channels.
Rendering/lighting differs between engines; a Cycles render is not pixel-identical
to the game's real-time lighting. Distant LODs, 100 m interior visibility and
separate reduced shadow meshes reduce runtime work without simplifying the master.

## Controls and route

- **W/S/X/Space**: power, brake, coast, emergency brake. **A**: AI/manual.
- **Tab**: cab/exterior. **F**: frame train; wheel/right-drag: zoom/orbit.
- **V**: passenger/cab in ICF, LHB and Vande Bharat. **PgUp/PgDn** cycles coaches;
  **←/→** changes position; **Home** switches aisle/seat.
- **R**: change ends at rest in Vande Bharat. Coach showcases
  refuse reversal because a locomotive run-round is not implemented.
- **C/D**: route desk. Initial routes lead to Maruthur P1. To continue, set
  **MRT-E1 → E-AE1**, then **KDP-H → BUFFER:KDP_B1**.
- **F9**: another imported working. Cancel preserves the run; confirmation
  discards progress. There is no save/load.

Bogies steer through curves, wheels roll with distance, and active pantograph
heads meet the 5.6 m wire above rail. VB cars articulate
independently. Reversal preserves physical car orientation and reverses the
axle audio map. Existing route protection and approved sound kernels are reused.

Source analog gauges, switches, coach doors and berths remain decorative/static;
use the live HUD for driving information. TF3 economy, purchase browser,
boarding, private horn and track-speed mod scripts are not ported. There are no
animated passengers or dynamic coupler compression/yaw. Power/mass/braking are
playable approximations, not certified traction models. Camera comfort and
frame rate still need a human playtest.

## Rebuild

ICF/LHB now use all fourteen v02 masters from checkpoint
`e209ff54ff5cd00bb0761761bdbe124cac6bf7cd`. Fetch
`tools/coach_v02_sources.json` to `.local/coach-v02-source/`; see
[detailed coach notes](coach-detail.md) for source status, material conversion
and preservation checks. R10 changes formation counts and exterior LHB paint
consistency; the source geometry and physical axle datums remain unchanged.
Fetch `tools/vb_v02_sources.json` into `.local/vb-v02-source/` for the seven
enhanced Vande Bharat masters. Run the converter for their `vb_*` IDs, then
install the emitted material shader code through Godot MCP (create the per-car
`*_detail/shaders` directories first). The exported shader definitions are saved
in `.local/<car>-materials.json`. Keep mesh compression disabled on these imports:
the extra full-float coordinates carry the procedural material inputs.
WAP-7 is now the detailed v0.2 source: fetch `tools/wap7_v02_sources.json` into
`.local/wap7-v02-source/` before running the converter. Follow [wap7-detail.md](wap7-detail.md)
for its shader installation and source-specific checks.
`tools/port_sources.json` pins download paths and Git blob hashes. Sources remain
in ignored `.local/transport-fever-3-mods/`; the converter never saves over them
or executes downloaded scripts. Run only in background Blender:

```powershell
& 'C:\Users\Gokul\Documents\Node_v24\node.exe' tools/fetch_port_sources.mjs tools/port_sources.json .local/transport-fever-3-mods
& .\.local\blender\blender-5.2.1-windows-x64\blender.exe --background --factory-startup --python tools/blender/port_tf3_assets.py
```

Append `-- wap7 wag9` to rebuild selected IDs. Rescan through Godot MCP with the
editor open; otherwise use `tools/godot.ps1 import`. Avoid concurrent imports.

The converter maps source `(X,Y,Z)` to Godot `(-Y,Z,-X)`, preserves metres,
UVs/split normals and mechanical hierarchies, and merges meshes per rigid parent:
The original fleet conversion used 387 rigid groups across 25 models; the detailed
WAP-7 replacement has its own 24-group audit in `wap7-detail.md`.
The v02 VB ceiling uses its authored inward lining; the old compact ceiling fix
does not apply. Legacy coach glass gets an alpha material. WAP-7 and enhanced VB
use authored material graphs instead of generic fleet finishing. Godot generates mesh LODs; groups
named INTERIOR have a 100 m draw range. Other interior geometry remains visible
with its parent body.

`assets/models/ported/manifest.json` records source/output SHA-256 hashes,
bounds, pivots, cameras, passenger markers and mesh counts. The adapter is
`game/ported_train_view.gd`. Physical formation data in
`sim/stock/ported_stock.gd` has no rendering or asset-loading dependency.

## Verification and playtest

```powershell
& .\.local\godot\Godot_v4.7.2-stable_win64_console.exe --headless --path . --log-file .local/fleet-tests.log --script res://tests/run_tests.gd
& .\.local\godot\Godot_v4.7.2-stable_win64_console.exe --path . --audio-driver Dummy --log-file .local/fleet-assets.log --script res://tools/check_ported_assets.gd
python tools/check_wap7_port.py
python tools/check_vb_port.py
```

`tools/check_kerala_geography.gd` captures the detailed VB pilot, CC/EC passenger
views and exterior on the geographic route. Native rendering is required for
transform/visual checks. Direct launch accepts `-- --fleet=icf`, `lhb`, `vb8` or `vb16`.

1. F9 → Vande Bharat 8, then 16: inspect wheel/rail contact and pantographs. Stop,
   press R and inspect the other cab.
2. Choose each coach showcase. V then PgDn through all seven classes; check
   glazing, interior visibility and Home/arrow-key viewpoints.
3. Try both VB lengths: outward end cabs, intermediate cars, couplings and
   passenger views.
4. A runs to Maruthur's red starter. Set the onward routes above and check the
   complete arrival without a safety event.
5. Report clipping, uncomfortable viewpoints, frame rate or audio balance.

## Ownership

The user explicitly requested reuse of their original procedural meshes and
materials. The source grants no open-source licence; this port does not relicense
them. Reference photos/manuals and private horn recordings are not bundled.
Existing personal-use sound restrictions continue to apply to game builds.
