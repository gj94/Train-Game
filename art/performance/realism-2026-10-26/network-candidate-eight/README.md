# Eighth Network candidate: disturbance runs rejected

These are incomplete failed runs, not certified timetable data. Both used
runtime `9ec3530` and the identical Classic/V2 authored definitions in `ac69057`.
Each audit matches 4,836 current source hashes. Both finish after the configured
07:30–07:40 manual K1 hold interval, with zero recorded safety events.

| Mode | Failure clock | Completed | Continuous wait | Longest station wait |
| --- | --- | ---: | ---: | ---: |
| Classic | 07:46:04 | 29 / 208 | M043 at NEM, 2,702 s | 2,524 s |
| V2 | 07:51:52 | 31 / 208 | L006 at AMPA, 2,702 s | 2,702 s |

The two original baseline jobs remain running at the time of this archive.
No baseline result is inferred from these disturbance failures. `finished` in
the run summaries means an audit file exists; `audit.ok=false` is authoritative.
Raw audits, traffic, failed worlds, exact packs and read-only inspections are
preserved with SHA-256 hashes in provenance.json. No source signatures are
changed and none of these files may be installed as baseline prepared data.

Classic M043's signal wait includes 1,044 seconds protecting V005's approach,
454 seconds of opposing M078 single-line occupancy and 334 seconds for S046,
alongside receiving-platform restrictions. At failure M078 is arriving at TVC,
S046 is moving at 24.6 m/s toward NEM, and L002 has reached Kazhakuttam. There
is no active future-crossing transaction in the saved world.

V2 L006's Ambalappuzha wait includes 1,336 seconds waiting for M010 to overtake,
702 seconds for opposing L005 and further receiving-capacity constraints.
At failure M010 is moving north from AMPA at 8.46 m/s, M008 is north of ALLP
at 24.6 m/s, M011 is approaching HAD and M101 is arriving at AMPA. There is
no active future-crossing transaction in this saved world either. Inspection
leaves both world snapshots byte-for-byte unchanged. These observations show
moving traffic; they do not establish a full recovery or excuse excessive waits.

The two departure adjustments have not made the 208-service day acceptable.
No further runtime or authored changes are made from this late partial result.
The remaining work is full-day acceptance, category running-time comparisons,
geographically distributed actual overtakes, and real installed native menu,
midnight and save/load validation. Preserve all failures and the user's fixed
10:00 checkpoint. The source suite remains at 1,003 passes, with four passing
authoring tests for the current unchanged packs. R47 remains published.


## Final baseline results at the deadline checkpoint

Both original baselines have also finished and failed. Classic fails at
07:46:04 with 29/208 complete, M043 continuous wait 2,702 s and longest
station wait 2,524 s. V2 fails at 07:59:52 with 32/208 complete, S046
continuous wait 2,702 s and longest station wait 2,570 s. Both record zero
safety events and match their 4,836 current source hashes. Their exact raw
audits, traffic, failure snapshots and incomplete catalogues are now archived
with provenance. All four v8 runs are rejected; none is installed. The V2
baseline fails on a different service than its disturbance run, so those
results must not be treated as interchangeable. No late retiming was attempted.
