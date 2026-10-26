# Seventh Network attempt: morning queues remain unacceptable

These are rejected partial runs on corrected runtime `9ec3530`, not prepared
timetable data. Each failed audit has 4,836 verified source hashes and zero
recorded safety events. The two incomplete Network baselines were stopped by
verified process identity before changing their authored packs. Original local
snapshot folders remain intact. Four Standard/Intensive v7 baselines continue.

| Run | Failure clock | Completed | Failure |
| --- | --- | ---: | --- |
| Classic delayed | 07:50:40 | 32 / 208 | L002 at NYY: 2,702 s station/continuous wait |
| V2 delayed | 07:12:16 | 27 / 208 | M045 at ALLP: 2,702 s station/continuous wait |

Classic passed the configured 07:30–07:40 K1 hold interval; V2 failed before it.
Neither is an accepted disturbance day. In run-summary.json, `finished` means
the final audit file exists; `audit.ok=false` and incomplete counts govern
acceptance. Exact raw audits, traffic, failed worlds, old packs and logs are
preserved with hashes in provenance.json. Do not install or relabel them.

The V2 service records and raw traffic hash exactly equal the previous v6
failed prefix. That is an observed prefix comparison, not a claim of full-day
or universal equivalence after the crossing correction.

## Two departure changes for the next candidate

At Alappuzha, M045 arrives at 06:25:13.65 and remains waiting at failure.
M101, originating there at 06:10, occupies downstream capacity alongside L013
and opposing through traffic. In this run M101 arrives Ambalappuzha at
07:01:37.15. Moving its departure out of that group is a scheduling hypothesis.

Classic L002 arrives Neyyattinkara at 07:04:28.70. Its station wait includes
600 seconds of opposing L033 single-line occupancy, 438 seconds for M043 and
122 seconds for S027, plus receiving-capacity and route conflicts. The saved
world shows M043, L033 and S027 still moving; no additional immovable cycle is
established. The read-only inspection leaves world bytes unchanged and shows
no stale completed NYY transaction. The 45-minute limit still fails.

| Service | Previous departure | Next candidate |
| --- | --- | --- |
| M101 Alappuzha–Kanniyakumari mail | 06:10 | 07:25 |
| L033 Thiruvananthapuram–Nagercoil passenger | 06:35 | 07:55 |

M101 now precedes the 07:40 Alappuzha local; L033 moves beyond the earlier
V005/M043/S027 southbound group and the 07:15 originating mail. Both engines
retain identical service definitions. An independent semantic comparison
confirms these are the only two changed fields in each 208-service pack.
All calls, dwell, rolling stock, priorities, speed limits and other departures
remain unchanged. These are authored representative departures, not verified
real railway timings, and do not force a passing site.

Four Network authoring tests pass. The unchanged runtime has 1,003 passing
full-suite tests. All inputs to the four continuing legacy baselines are
independently rechecked after the pack edits. Only the four affected Network
runs need fresh preparation, after this increment is committed.

Full-day calls, full-tail completion, safety, both wait distributions and
actual geographically distributed overtakes remain mandatory. Category
comparisons and actual installed native midnight/save-load checks are pending.
No threshold is weakened and no new timetable is installed. At the fixed
10:00 deadline, checkpoint incomplete validation honestly; preserve R47.
