# Imported Indian Rail fleet

The user's assets from [gj94/transport-fever-3-mods](https://github.com/gj94/transport-fever-3-mods)
are available through **F9**, or **Escape → Traffic / solo fleet**. Choose a working
and confirm to start at Chennapuram. Original scenarios remain on F2/F3.

A fresh launch assigns a random cab among **six mixed passenger services**, with
AI traffic and automatic routing. See [dispatching.md](dispatching.md). F1 explains
your assignment and expected waits. Restart keeps it; F9 offers a new random
assignment or a solo working. The LHB working still hauls all seven classes:
1A, 2A, 3A, 2S, CC, SL and GS. Explicit fleet choices and F2/F3 take precedence;
`-- --memu` starts the original six-MEMU dispatcher directly.

## Vehicles

| Working | Imported assets | Visible train length |
|---|---|---:|
| WAP-7 | Pantograph v0.4 master, both furnished cabs | 20.560 m |
| WAG-9 | Green/yellow master, both furnished cabs | 20.642 m |
| WAG-12B | Articulated A/B sections with outward cabs | 38.580 m |
| ICF showcase | WAP-7 + 1A, 2A, 3A, 2S, CC, SL, GS | 176.639 m |
| LHB showcase | WAP-7 + 1A, 2A, 3A, 2S, CC, SL, GS | 188.560 m |
| Vande Bharat 8 | DTC, MC, TC_EC, MC2, MC2, TC_CC, MC, DTC | 155.738 m |
| Vande Bharat 16 | Source formation with all six required car types | 310.738 m |

Twenty-five distinct current masters are imported. Older prototypes, review
fixtures and duplicate FBX/baked files are superseded by these masters.
Coach showcases are inspection consists, not claimed real services. Freight
locomotives run light; the source contains no freight wagons. Vande Bharat retains
the author's **compact interpretation**, with 19.375 m car pitch.

## Controls and route

- **W/S/X/Space**: power, brake, coast, emergency brake. **A**: AI/manual.
- **Tab**: cab/exterior. **F**: frame train; wheel/right-drag: zoom/orbit.
- **V**: passenger/cab in ICF, LHB and Vande Bharat. **PgUp/PgDn** cycles coaches;
  **←/→** changes position; **Home** switches aisle/seat.
- **R**: change ends at rest in light engines and Vande Bharat. Coach showcases
  refuse reversal because a locomotive run-round is not implemented.
- **C/D**: route desk. Initial routes lead to Maruthur P1. To continue, set
  **MRT-E1 → E-AE1**, then **KDP-H → BUFFER:KDP_B1**.
- **F9**: another imported working. Cancel preserves the run; confirmation
  discards progress. There is no save/load.

Bogies steer through curves, wheels roll with distance, and active pantograph
heads meet the 5.6 m wire above rail. WAG-12 sections and VB cars articulate
independently. Reversal preserves physical car orientation and reverses the
axle audio map. Existing route protection and approved sound kernels are reused.

Source analog gauges, switches, coach doors and berths remain decorative/static;
use the live HUD for driving information. TF3 economy, purchase browser,
boarding, private horn and track-speed mod scripts are not ported. There are no
animated passengers or dynamic coupler compression/yaw. Power/mass/braking are
playable approximations, not certified traction models. Camera comfort and
frame rate still need a human playtest.

## Rebuild

Source revision: `4c4f0be85edbf4468bca22f2d1285fec72343bd5`.
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
47,587 source objects become 387 rigid mesh groups across the 25 models.
VB ceiling lining winding is corrected for Godot's backface culling.
Glass gets an alpha material. WAP-7's two packed original instrument textures
are embedded in GLB and extracted by Godot. Godot generates mesh LODs; groups
named INTERIOR have a 100 m draw range. Other interior geometry remains visible
with its parent body.

`assets/models/ported/manifest.json` records source/output SHA-256 hashes,
bounds, pivots, cameras, passenger markers and mesh counts. The adapter is
`game/ported_train_view.gd`. Physical formation data in
`sim/stock/ported_stock.gd` has no rendering or asset-loading dependency.

## Verification and playtest

```powershell
& .\.local\godot\Godot_v4.7.2-stable_win64_console.exe --headless --path . --log-file .local/fleet-tests.log --script res://tests/run_tests.gd
& .\.local\godot\Godot_v4.7.2-stable_win64_console.exe --headless --path . --log-file .local/fleet-assets.log --script res://tools/check_ported_assets.gd
& .\.local\godot\Godot_v4.7.2-stable_win64_console.exe --headless --path . --log-file .local/fleet-playable.log --script res://tools/check_ported_playable.gd
```

For captures, run the last script without `--headless`, adding `-- --capture`;
outputs go to `.local/ported-preview/`. Direct launch accepts `-- --fleet=wap7`,
`wag9`, `wag12`, `icf`, `lhb`, `vb8` or `vb16`.

1. F9 → WAG-9, then WAG-12B: inspect wheel/rail contact and pantographs. Stop,
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
