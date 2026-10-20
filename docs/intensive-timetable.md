# Alternate intensive operating day

The home screen's **Operating day** selector keeps **Standard · 100 services**
separate from **Intensive · 140 services**. Each has its own prepared departures,
five-minute states and measured traffic preview. Switching menus never replaces
the railway inside a saved journey. Save/Continue and prepared-journey Restart
retain the selected operating day.

The intensive timetable adds forty limited-stop relief services around
Kayamkulam–Kollam–Thiruvananthapuram, concentrating density on the double line.
The original two full-route Vande Bharats remain. K1 is an all-stations passenger
with 2½-minute ordinary passenger stops; equipment limits remain unchanged.
This is an authored game operating day, not a real Indian Railways timetable.

The acceptance target is ten **distinct** trains overtaking K1 in a complete
AI-run baseline. Repeated passes by one train do not satisfy that target.
Interlocking, receiving capacity, full-rake clearance, passenger exchange and
normal dynamic priorities remain active. Manual driving can change encounters.
The player's comfort target is a distribution of extra waits, not a ten-minute
hard cutoff: at least **70% under 10 minutes, 90% under 20, 98% under 30 and all
under 45**. These are cumulative minima; better outcomes pass without inventing
long waits. A slow passenger may accumulate an hour of lateness through many
short holds. Destination lateness is reported, not used as a rejection gate or
hidden by padding the schedule.

A booked call shares its ready-to-depart age across successive overtakers,
starting after booked departure, minimum dwell and passenger exchange. Ten
minutes remains a soft target. The dispatcher avoids extending optional passes
beyond a shared thirty-minute starvation budget. An express already alongside
retains its committed pass until its full tail clears. Crossing locks and occupied
routes always retain protection; neither ten nor forty-five minutes forces an
unsafe signal clearance.

The audit groups standstill samples by booked call or signal, including changes
of blocker and short creeps. It excludes normal booked dwell, passenger exchange,
and explicitly injected manual pauses. Episodes below 30 seconds are separately
reported and excluded from percentile calculations, so tiny startup pauses cannot
hide a long hold. Both the combined population and booked-station population
must meet the cumulative percentages. The continuous-standstill guard also stays
below 45 minutes. Every longer-than-ten-minute station call has its reason totals
listed in the audit.

Release preparation rejects incomplete traffic, safety events, a B042 reverse
pass of B002, missed wait-distribution targets, and fewer than ten distinct K1
overtakers. Fresh full-day and delayed-driver results are still pending.

## Why B042 passed B002 back in the standard day

R37's full-day replay records:

| Movement | Time |
|---|---|
| B002 overtakes B042 at Turavur | about 10:19 |
| B002 reaches Cherthala | 10:27:27 |
| B002's booked Cherthala departure | 10:35:30 |
| B042 reaches Cherthala | 10:32:37 |
| B042 leaves after its passenger stop | 10:33:41 |
| B002 finally departs | 10:36:23 |
| B002 passes B042 again at Mararikulam | about 10:48 |

This is a real change in order, not duplicate traffic-preview cards. The express
arrives early against generous running allowances and must not depart before its
public time. The already-late passenger is ready first. The original dispatcher
allows it out, creating another catch and pass later.

In the alternate day, B002's running allowances are reduced to 83% of the
original segment allowances, retaining its actual stop dwell. This changes booked
times, not train physics. The original day's booked schedule is unchanged.
Both days use the corrected dispatcher and newly simulated traffic. The complete replay,
not just the planned times, must confirm the unwanted reverse pass has gone.

## Reproduce

`tools/author_intensive_timetable.py` authors the independent importable JSON in
`art/timetables/kerala-coast-intensive.json`. It never modifies the standard pack.

Run `tools/prepare_timetable_variant.gd` headlessly with
`--output=res://.local/intensive-candidate --snapshots`. The same serial railway
produces its origin checkpoints, five-minute snapshots, full-day audit and
two-second train-extents recording in one pass. Each checkpoint is restored and
compared before acceptance. `--delay=600` (optionally `--delay-at=...` and
`--delay-service=...`) runs a separate disturbed audit without baseline snapshots.

`tools/inspect_variant_traffic.mjs` reads progress without modifying the railway.
`tools/finalize_timetable_variant.mjs` checks the full audit, distinct overtakers
and B042/B002 outcome before copying prepared data to
`data/timetables/intensive/`. The release gate
`tools/verify-timetable-variants.mjs` verifies source fingerprints, snapshot
hashes, the continuous time series and traffic catalogue.

The same preparer with `--standard` regenerates the original hundred-service
day after simulation changes. Finalize it with destination `data --standard`.
Neither day reuses snapshots made by an older dispatcher.

## Dispatcher corrections found during validation

- Future crossing reservations must end at the train's actual destination.
  A terminating TVC relief previously promised an arrival at Nemom after its
  service ended; the unfulfilled promise survived depot storage. Completed
  participants now withdraw unfulfilled planning reservations. Ordinary occupied
  routes, points and signals retain their protection.
- Preparing a home route beyond automatic signals must evaluate availability
  from that home signal. Checking from the train's immediate automatic signal
  incorrectly rejected the preferred main and chose a geometrically shorter
  35 km/h loop at Trivandrum North. Both directions now prefer their clear
  main road (currently 90 km/h), while occupied mains and priority overtakes
  can still require a loop.
- Assigning the actual road must preserve compatible capacity for all trains
  already admitted to either approach. A through VB can use Turavur's
  non-platform main instead of taking the last passenger face needed by an
  opposing stopping train. Exclusive future-succession plans retain their
  ordered vacancy proof.
- New arrivals and individual road assignments also preserve the onward escape
  of services already admitted. A same-direction occupant cannot be assumed to
  vacate its road while an opposing train occupies its exit section. Both checks
  address a four-service Turavur/Kumbalam cycle found in the standard-day replay.
  `tools/check_turavur_capacity.gd` resumes its unmodified pre-jam snapshot.

Playtest: select each operating day, inspect K1's Stops and Traffic tabs, and
sort by slowest scheduled average speed. Compare B042's traffic preview in both
days. Start an intensive service, save, return, Continue, and Restart. Explore by
time should show that day's full roster. Drive K1 late and confirm that actual
signals and priorities take precedence over its baseline preview.
