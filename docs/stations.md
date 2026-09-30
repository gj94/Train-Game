# Southern Railway station architecture and real metre scale

Implemented 30 September 2026 following the request to replace generic stations.
The user selected **Kumbakonam, Mayiladuthurai Junction and Thanjavur** as references.

## What is reproduced

These are original, photograph-referenced architectural adaptations on the game's
compact fictional line. They retain the playable names **Chennapuram / Maruthur /
Kadalur** and existing signal IDs. They are **not surveyed replicas of the three
real yards**, and the 4.89 km map is not the real distance between those towns.
Reference photographs show earlier station appearances, not a claim to reproduce
the current Amrit Bharat redevelopment works.

| Game station | Reference | Recognisable features |
|---|---|---|
| Chennapuram (CPM) | Kumbakonam | Long blue corrugated platform roofs, open steel trusses, red paving with pale inset tiles, yellow entrance fascia with blue wings, round piers and a maroon crown, auto forecourt |
| Maruthur (MRT) | Mayiladuthurai Junction | Red/white sheet roofing, cream booking block, covered white-railed footbridge, maroon platform retaining faces and blue watering pipe |
| Kadalur (KDP) | Thanjavur Junction | Stepped temple-style entrance tower, coloured portico fascia and dark columns, barred windows/fanlights, open upper gallery and three rooftop name panels |

Each kit includes benches, drinking-water stands with taps and blue/white tiles,
tea/book stalls, bins, lamps, roof drainage, open booking-hall access, platform-end
ramps, stairs connected to the footbridge, and a forecourt with auto-rickshaws.
Runtime additions supply Tamil/Hindi/English yellow boards, platform signs,
passengers, stop markers and overhead electrical portals. The landscape now has
a flat delta profile instead of steep hills immediately beside the stations.

The remaining simplifications include idealised weathering, repeated structural
bays, schematic people, simplified autos and tower ornament, reduced track counts,
and no walkable station interior or station passenger simulation. The side access
platforms and islands are adapted to the existing two-road dispatcher topology.

## Dimensions and evidence

**One Godot unit and one Blender unit are one metre.** Vehicles are not scaled to
fit short platforms. The station tracks, throats, signalling positions and scenery
were lengthened together.

| Item | Implemented value | Basis / limit |
|---|---:|---|
| Usable level platform | 600 m | Deliberate railway-scale design allowance; not a measured length of each reference station. Accommodates the 500.562 m playable rake and a nominal 24-coach LHB + WAP-7 envelope of 596.562 m geometrically. The 24-coach case is not an added service. |
| Platform surface | 0.800 m above rail | Within the 760–840 mm BG high-level range; world rail is Y=0.5, platform Y=1.3. Coping rises another 40 mm. |
| Platform widths | 8.2 m island / 12 m side | Game layout dimensions allowing the photographed shelters, circulation and stair footprint; track centres 12 m apart. |
| Maruthur station roads | 840 m between points, plus the small curve-length addition on the loop | 120 m approaches around a 600 m straight platform section. Starters and clearance zones keep the 20-coach rake clear of both throats. |
| LHB body / coupling pitch | 23.540 / 24.000 m | RDSO LHB maintenance dimensions. |
| WAP-7 over buffers | 20.562 m | Existing metre-scale WAP-7 profile, see `wap7.md`. |
| Playable LHB consist | 20 coaches + WAP-7 = **500.562 m** | EOG1, B1–B16, A1–A2, EOG2. Full-length AC-special composition based on the reported SWR 06523/06524 2025 formation; the game remains a fictional working. |
| Loaded LHB mass | **1,145.70 t** including locomotive | RDSO tabulated gross masses: 16 × 51.36 t (3A), 2 × 48.66 t (2A), 2 × 59.31 t (generator van), plus 108 t locomotive. |
| MEMU body / gap | 21.337 / 0.795 m | RDSO MEMU specification. Eight bodies + seven gaps give a **176.261 m model envelope**; this is explicit body/gap geometry, not an assertion that every MEMU variant has this over-buffer length. |
| MEMU bogie centres / axle spacing | 14.783 / 2.896 m | ICF MEMU geometry. The renderer, model builder and axle sound scheduling use the corrected spacing. |

The LHB formation has **86 wheelsets** including the locomotive. Sound kernels
and generated sound data were not edited. Only axle positions/counts follow the
actual rendered vehicles. Generator vans have distinct louvred grey exteriors;
they are skipped by passenger camera selection and have no modeled interior.
The train still needs a run-round to return; R does not reverse a non-driving van.

Dimensional sources:

- [RDSO revised LHB maintenance manual, introduction](https://rdso.indianrailways.gov.in/uploads/files/Revised_LHB_Manual_Vol_II_Chapter_I_Introduction_Draft.pdf): body/coupler lengths, bogie and axle geometry.
- [RDSO 2013/CG/B/01 Rev 01, Appendix C](https://rdso.indianrailways.gov.in/works/uploads/File/Al_coach_spec_RDSO_CG_B_01_rev01_changes_jan16_upload15days_PRINT.pdf): coach gross masses and capacities.
- [RDSO MEMU specification, December 2014, §4.1](https://rdso.indianrailways.gov.in/works/uploads/File/draft%20MEMU%2005.01.2015%20%281%29.pdf): 21,337 mm body and 795 mm inter-car distance.
- [RDSO EMU/MEMU leading particulars](https://rdso.indianrailways.gov.in/uploads/1-ii-%20spec%20for%20EMU-MEMU-163.pdf): 14,783 mm MEMU bogie centres.
- [Indian Railways passenger amenities handbook](https://indianrailways.gov.in/railwayboard/uploads/directorate/eff_res/camtech/Civil%20Engineering/YearWise/Handbook%20on%20Passenger%20amenities%20in%20station%282%29.pdf): size platforms to accommodate the longest passenger train.
- [Railway Board platform-height audit](https://indianrailways.gov.in/railwayboard/uploads/directorate/Environment_Management/2025/pp.pdf): 760–840 mm high-level platform range.
- [SWR statement reported by PTI, 30 July 2025](https://www.deccanherald.com/india/south-western-railway-to-run-special-trains-between-bengaluru-thiruvananthapuram-for-festive-season-3656545): 20 LHB coaches, including 16 AC3, two AC2 and two generator/luggage vans. This is a reported formation, not the game's timetable or route.

## Visual references and ownership

Viewed the actual photographs at full size, not just search descriptions:

- [Kumbakonam southern platforms](https://commons.wikimedia.org/wiki/File:KumbakonamRailwayStation_SouthernSide.jpg): roof profiles, trusses, paving and station proportions.
- [Kumbakonam entrance](https://tamil.abplive.com/news/thanjavur/battery-car-service-started-at-kumbakonam-railway-station-15462): yellow fascia, blue wings, round piers, curved maroon brackets, trapezoidal crown and auto queue.
- [Mayiladuthurai footbridge photograph](https://indiarailinfo.com/blog/post/533264): covered stair flights, pale rails, red roof sections, watering pipes and platform faces.
- [Thanjavur entrance photograph](https://st.indiarailinfo.com/kjfdsuiemjvcya22/0/6/6/1/3456661/0/dsc0208.jpg): tower, portico, gallery, barred windows and rooftop signs.
- [LHB generator-car photograph](https://st.indiarailinfo.com/kjfdsuiemjvcya22/0/4/4/1/4984441/2/img20210613103203932444.jpg): louvres, equipment doors, grey/red/blue treatment and luggage/brake markings.

All geometry and the mineral-surface shader are original project work. No reference
photograph pixels or downloaded third-party meshes are embedded or committed.
Read-only reference downloads are in ignored `.local/station-references/`.
Signs use Windows **Nirmala UI** via Godot SystemFont for Tamil/Devanagari shaping;
the font file is not redistributed. Other operating systems need a suitable
system fallback before export (the project target remains Windows).

## Build and inspect

Run only background Blender using the machine paths in `pc-setup.md`:

```powershell
& ./.local/blender/blender-5.2.1-windows-x64/blender.exe --background --factory-startup --python tools/blender/build_stations.py
& ./.local/blender/blender-5.2.1-windows-x64/blender.exe --background --factory-startup --python tools/blender/build_lhb_eog.py
& ./.local/blender/blender-5.2.1-windows-x64/blender.exe --background --factory-startup --python tools/blender/assemble_lhb_rake.py
```

Editable station masters: `art/stations/{kumbakonam,mayiladuthurai,thanjavur}.blend`.
Runtime exports: `assets/models/stations/*.glb`. The native art folder is excluded
from Godot import using `.gdignore`. Roof sheets have separate top/bottom vertices
and physical thickness; coincident reverse faces disappeared during Godot import
in the first export and were corrected after viewing the actual game.

Tests: `tests/run_tests.gd`, `tools/check_stations.gd`, `tools/check_lhb_playable.gd`,
`tools/check_wap7_playable.gd`, `tools/check_dispatch_ui.gd`.

## Playtest

1. Start the main game. Press **1**, **2**, **3** to inspect the three station
   buildings; right-drag to orbit, left-drag to pan, wheel to inspect close details.
   **D** hides the dispatcher for a clearer view. Compare the blue Kumbakonam-type
   roofs, Mayiladuthurai-type bridge/striped roofing, and Thanjavur-type entrance.
2. Press **F3**, then **Tab** for the full 20-coach rake. Zoom out if necessary;
   the locomotive and tail van must both stand alongside Chennapuram's platform.
3. Press **A** to depart under AI. Stop at Maruthur's red starter and inspect both
   ends; all passenger vehicles must berth and the entrance points must release.
4. Set **MRT-SE1 → KDP-H** and **KDP-H → BUFFER:KDP_B**. At Kadalur, inspect the
   rear generator van, LV board, and the train's length relative to the platform.
5. Use **V**, **PgUp/PgDn**, **Home**, **B** to check B1–B16 and A1–A2. Coach cycling
   must skip both generator vans. R at the terminus must explain the run-round.
6. Press F3 to return to the MEMU meet and follow `dispatching.md`'s route sequence.
   Both eight-car services must stop on their separate roads and complete safely.
