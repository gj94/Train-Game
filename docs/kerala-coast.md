# Kerala Coast: Ernakulam–Alappuzha–TVC–Nagercoil

Fresh launches start **K1, the slow all-stop WAP-7 + ICF passenger** on this route.
**F7** switches to/from the short corridor. The route follows the user's chosen coastal line via
Alappuzha, then Kayamkulam, Kollam, Thiruvananthapuram Central and Nagercoil.
The full alignment is 278.048 km including terminal approaches; station centres
are 276.585 km apart. It is not compressed. There are 56 mapped station locations.

## Driving and exploring

The route is **mixed single and double line**, not single throughout. Current
game station-centre sections are:

| Section | Running lines | Approximate game distance |
| --- | ---: | ---: |
| Ernakulam–Ambalappuzha | 1 | 69.1 km |
| Ambalappuzha–TVC | 2 | 136.4 km |
| TVC–Eraniel | 1 | 52.6 km |
| Eraniel–Nagercoil | 2 | 18.4 km |

Station loops and platform roads are additional. This totals about 155 km of
double-track running. The Ministry's [13 February 2026 section breakdown](https://sansad.in/getFile/annex/270/AU1705_QP2ZtK.pdf?source=pqars)
confirms Ambalappuzha–Kayamkulam already doubled and northern coastal works in
different stages. The [8 June Mararikulam–Alappuzha sanction](https://www.pib.gov.in/newsite/erelcontent.aspx?lang=2&reg=48&relid=289762)
groups other works as commissioned **or under implementation**; it does not
establish that the whole northern coastal line is in double-line operation.
The game snapshot is not certification of every commissioning change after
those sources; see the station audit for unresolved infrastructure details.

- The default is K1 among **32 scheduled passenger workings**. The others use AI;
  automatic dispatch also requests routes for your manually driven train.
- The top-right HUD shows the next scheduled station, distance in **metres**
  and approximate **in-game minutes**, replacing the camera label. Estimates
  include acceleration, braking and remaining dwell; signal waits are additional
  and marked explicitly. Fast forward changes real elapsed time, not this estimate.
- **PROGRESS / F12** shows completed/total calls, calls left, the next stop,
  distance, approximate in-game time and booked arrival. The origin counts as
  the first of 56 calls. Signal waits are identified separately because their
  duration can change. The progress panel pauses play; Back restores the prior
  pause/running state. **D** inspects any service; **F9** can assign randomly.
- **F1** explains your working, priorities and booked stops. The live HUD names
  a service you should expect to wait for: crossing, overtaking or clearing the
  section. This advisory changes with the actual dispatch decision; signals
  remain the authority to move. **W/S** drive; **A** hands driving
  to AI. Wait for a proceed signal. Single-line sections must clear before an
  opposing working can enter, and halts can lie inside a reserved section.
- **4** pilot, **Q / Shift+E** head out, **Alt+1/2/3** first/middle/last passenger coach.
- **D** opens the desk. Choose a station in the yard picker for its schematic;
  **VISIT YARD** moves the exterior camera there. **F** follows the selected train
  again. Select a different service to inspect it, then choose **View train** or
  **Take control…**. Handover requires confirmation; viewing preserves your service.
  See [the new control desk guide](dispatcher-overhaul.md) for mouse/Xbox zoom,
  map targets, route actions, platform requests and the decision log.
- **F5** creates/imports/exports services for this route. The file is bound to
  this exact track/signalling graph. Use the route's platform identifiers and
  allow several hours for a full journey. Rehearsal is independent of the live
  run; it can take time on this full-scale route. Exported stop markers retain
  their exact positions. Up to 64 services and 64 stops per service are supported.
  Set priority from 1–100 (higher first) and a service speed cap.
  Begin at a station with a departure signal; unsignalled halts can be
  intermediate or final stops, not service origins.
- **F7** returns to the fictional corridor. Solo fleet showcases (F2/F3/F9)
  also use that corridor. Restart retains the current route and assignment.
- **T** cycles ×1/2/4/8/16/32; **Shift+T** restores ×1. The entire simulation,
  timetable clock, traffic, dispatch and audio advance together. Train speeds
  remain ordinary in-world km/h and physics still runs in bounded substeps.
  The pause menu has direct rate buttons. Streaming can pause advancement when
  scenery is not ready; high rates are subject to the PC's simulation capacity.

These are designed game services, **not published Indian Railways timetables**:

| ID | Working | Departure | Priority |
|---|---|---|---:|
| K1 | WAP-7 + ICF all-stop passenger, Ernakulam–Nagercoil, 65 km/h cap | 08:00 | 20 |
| K2 | Northbound LHB, Turavur–Ernakulam | 08:00 | 70 |
| K3 | Vande Bharat 8, Kumbalam–Nagercoil | 08:18 | 95 |
| K4 | Northbound ICF, Ambalappuzha–Ernakulam | 08:45 | 40 |
| K5 | Vande Bharat 16, Cherthala–Nagercoil | 09:08 | 100 |
| K6 | Priority LHB, Kayamkulam–Kollam | 10:58 | 80 |
| K7 | Northbound LHB, Eraniel–TVC | 13:30 | 65 |

K8–K32 add 25 regional workings: southbound intercity, passenger and VB trains
between Ernakulam and Kadakavur, and northbound services between Nagercoil Town
and Ernakulam. Departures span 08:10–14:30, with priorities 30–100. Their exact
origins, calls, departures and priorities are in `sim/timetables/kerala_regional.json`
and visible in F1, the dispatcher roster and F5. Each starts in a separate road;
destinations use separately allocated roads so completed services do not stack
on the same terminal block. All 32 exist from the start and remain simulated.
Nearby models/audio load within 3.2 km and unload beyond 4.5 km; your assigned
train and a train being viewed stay loaded. This does not remove distant trains
from the dispatcher or signalling.

Select K1 on the desk to drive the slow passenger. Meets and overtakes are
chosen from current positions, expected arrivals, booked release times,
reachable roads and priorities. They are not fixed events. If you run late,
expresses proceed when they have a safe route; they do not wait for a scripted
overtake. At a single-line crossing the first approaching train is assigned an
available loop. A booked origin, occupied road or already committed route can
constrain that choice. Final trains remain at their destination roads.

Single and double main-line sections have automatic blocks roughly 1 km apart.
On single line, a direction lock covers the whole interval between passing
places, including intervening halts. Several trains may follow in that direction;
opposing entry waits for all trains and committed entry routes to clear. Idle
automatic routes do not keep the section locked indefinitely. These signal
locations and block lengths are a game operating design, not a surveyed signal plan.

## Geography and visual detail

- Dated OpenStreetMap main-line geometry, station names/positions, water polygons,
  road alignments and building footprints. The source corridor contains about
  337,000 mapped buildings. Buildings load around the camera rather than all at once.
- NASA/USGS SRTM terrain, with a smoothed, grade-limited railway elevation profile.
  Track cuttings and embankments blend into the source terrain locally.
- Actual mapped backwater shapes, islands, river channels and coastline;
  bridge spans follow tagged railway locations. Detailed railheads, sleepers,
  fastenings, points and approved 39 m joint spacing remain in use.
- Original Blender frontages for Ernakulam Junction, TVC's stone-and-arch
  heritage building, Nagercoil Junction and a coastal station family. Platforms,
  shelters, footbridges, bilingual boards, passengers, kiosks and forecourt vehicles.
- Mapped building footprints get deterministic roofs, windows, awnings and
  tanks. Tropical vegetation is placed using mapped land classes; it is not a
  survey of individual trees. Additional mapped yard rails are scenic geometry.

This is a playable geographic reconstruction, **not yet an exquisite surveyed
replica of every kilometre**. Operating road counts and sides in `operations.json`
use individual OSM running rails/sidings, excluding construction and identified
dead-end/yard roads. TNU, AROR, EZP, VAY, TRVZ, KAVR, TMPY, PUPR, BRAM, AMVA,
DAVM, KZTW, PYD, VRLR and NJT have one mapped through road, without invented loops.
Other stops may have two through roads without a passing loop. Large yards have
their own road counts; game P1/P2 identifiers are not official platform numbers.
Closely spaced tracks do not get platforms placed between them. Station road
interpretation, yard throats, signals,
platforms, bridge construction, speeds and grades are interpreted for the game.
OSM-inferred single/double-track sections are not a verified current doubling
status. Station architecture follows reference photographs, with interpreted
dimensions and unseen sides; current redevelopment is not represented. Most
surrounding facades/heights are procedural where tags do not supply them. No
photogrammetry, satellite-image textures or LiDAR survey is claimed.

Further fidelity work should prioritize surveyed ERS/ALLP/QLN/TVC/NCJ yards,
distinctive bridges and embankments, accurate current platform plans, local
landmarks, better building height coverage and individual roadside details.

## Performance and precision

The simulation retains the complete railway. Two background workers build
detached nearby chunks; only the main thread attaches or removes scene nodes.
Detailed terrain/buildings cover roughly 1.9 km around the camera, track about
1.65 km, and coarse relief about 9.5 km. Distant trains remain simulated but do
not animate/render their full models outside the local scene. A loading overlay
pauses simulation during initial loading or a long camera transfer.

Position interpolation uses small edge-local coordinates and a floating render
origin, avoiding large-coordinate close-up jitter. Audio uses a stable absolute
listener proxy so shifting the render origin does not move the sound field.
Approved audio samples, pitch, joint spacing and propagation rules are preserved.

## Source and rebuild

Map attribution and licence: `data/routes/kerala_coast/README.md` (ODbL 1.0).
Source downloads remain in `.local/kerala-route/`; no login or proprietary map
service is needed. Install `tools/maps/requirements.txt` into that folder's
`python` subdirectory. Place the dated Geofabrik PBF and its `.md5` alongside
the four SRTM GeoTIFFs, then run in order:

```
python tools/maps/kerala_route.py extract
python tools/maps/kerala_route.py plan
python tools/maps/kerala_route.py terrain
python tools/maps/kerala_route.py sections
python tools/maps/kerala_route.py features
python tools/maps/kerala_route.py tiles
python tools/maps/station_operations.py
```

Geofabrik: `https://download.geofabrik.de/asia/india/southern-zone-261006.osm.pbf`.
SRTM: `https://opentopography.s3.sdsc.edu/raster/SRTM_GL1/SRTM_GL1_srtm/N08E076.tif`
(substitute the four tile names in the data README). The feature extraction is
the slowest step. Do not run `terrain` after `sections`/`tiles` without regenerating
those later steps, because it rebuilds the route manifest.

Blender: background `tools/blender/build_kerala_stations.py`; editable source
models are in `art/scenery/`. Never run this in an open user Blender session.
Native inspection: `tools/check_kerala_geography.gd`; long AI rehearsal:
`tools/check_kerala_traffic.gd`. Neither requires launching an exported package.

## Playtest

1. Start K1, read F1 and drive or enable AI. Open PROGRESS/F12 at the origin and
   after a stop. Check red-signal waits, departure times,
   and the cadence of joints from pilot and passenger views.
2. In D, select TVC then VISIT YARD. Inspect its frontage and platforms; repeat
   ERS and NCJ. F returns to your service. Switch directly between K1 and K7 to
   exercise a transfer across the whole map.
3. Ride K1 south of Kumbalam across the long Aroor backwater bridge. Check shore
   alignment, deck clearance, OHE and distant water as the train moves.
4. Inspect smaller halts and single-line meets. They should not all have invented
   passing loops. Let AI complete a service or design a shorter one in F5.
5. Use F10 on the 4090 PC, compare cab/exterior and revisit a distant station
   after several minutes. Report any sustained slowdown, missing chunk or pop-in.
6. Drive K1 late and watch expresses receive routes according to their actual
   position. Read the named wait advice; try T/Shift+T during a wait and a long
   clear stretch. Return to normal time before close manual braking.
