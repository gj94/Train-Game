# R44 streaming and passenger QoL

Full suite: 779 pass. Controller: 97 pass. Passenger skip/recall/save:
20 checks each for LHB and VB8. Home/menu native fixture: 27 pass at 720p/900p.
Operating-day UI: 16 pass. Traffic browser: 3,396 Standard / 5,556 Intensive.
Final stream-focused contracts: 16 pass. No full timetable reruns.

## Native scenery replay

Development Ryzen 7840HS / Radeon 780M, 1280×720, actual geographic scenery.
One 60-second run per variant, same 100 km/h camera, frozen railway, selected
RTX 4090 Laptop cache budget. This does **not** measure target-PC frame rate,
train simulation or live traffic. The weak GPU is the dominant constraint;
small throughput differences are single-run observations, not universal gains.
Loading blocks camera travel exactly as in the live scenery gate. Cold start,
no idle prefetch warm-up. GPU/render timing is asynchronously read.

| Variant | Travel km | Loading s | Interruptions | Hidden cache hits | Stream mean ms | GPU mean ms |
|---|---:|---:|---:|---:|---:|---:|
| Baseline ×16 | 14.87 | 26.48 | 34 | 0 | 3.33 | 44.02 |
| Prefetch ×16 | 15.39 | 25.32 | 28 | 86 | 3.79 | 46.28 |
| Baseline ×32 | 17.06 | 40.75 | 35 | 0 | 3.49 | 44.75 |
| Prefetch ×32 | 18.11 | 39.61 | 39 | 56 | 3.91 | 45.99 |

Hidden future chunks promote only into the normal visible footprint. The unit
contract checks priority, the loading gate, reverse/curved routes, cancellation,
static spatial indexing and pressure. See the raw results for memory and p95.
Forward preparation does not remove the need for loading at all high speeds.
No simulation, timetable, prepared-departure or traffic data changed.

See [playtest](../../../docs/streaming-and-passenger-qol.md).
