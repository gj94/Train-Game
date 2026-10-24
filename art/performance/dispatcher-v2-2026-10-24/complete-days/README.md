# Complete-day V2 validation

## First Intensive candidate, ten-minute manual disturbance

The 140-service railway was replayed from the operating-day beginning to 03:20
on the following day. K1 was manually braked for 600 seconds at simulation time
11000 (11:03:20), then returned to AI. This is the initial departure candidate,
not the final requested ten-pass baseline. Its base run later failed the ten-distinct-overtaker gate; see
`candidate-one`. Revised disturbed evidence is in `candidate-two`. Never publish this disturbed audit as departure/time data.

All 140 services completed every booked call and departure and cleared to depot.
No safety events occurred. All 4,834 recorded source hashes matched independently
at completion. Independent Node checks recomputed the wait distribution and
validated every call, completed service and wait-reason total from the raw audit.
The compressed JSON is an exact copy of that original audit; its uncompressed
SHA-256 appears in the small summary.

| Measured extra wait | All locations | Booked station calls |
| --- | ---: | ---: |
| Episodes of at least 30 seconds | 288 | 175 |
| Under 10 minutes | 86.81% | 82.29% |
| Under 20 minutes | 98.26% | 97.71% |
| Under 30 minutes | 100% | 100% |

Maximum continuous wait was 27m 32s. K1 arrived 26m 56s late after the injected
pause and had nine distinct overtakers across seven stations, maximum three at
Kadakavur. A disturbed run is expected to change encounters; it is not required
to reproduce the baseline count or passing stations. The injected pause and
booked dwell are excluded from extra-wait quality. These results validate this
specific disturbance, not every possible manual-driving pattern.

Reproduce with the corresponding frozen source and first-candidate pack:

```powershell
.local/godot/Godot_v4.7.2-stable_win64_console.exe --headless --path . --script res://tools/prepare_timetable_variant.gd -- --pack=res://art/timetables/kerala-coast-intensive-v2.json --delay=600 --delay-at=11000 --output=res://.local/dispatcher-v2-delayed-check
```

The audit contains its exact source/pack hashes. A later authored candidate will
need a new baseline and disturbed run; do not compare it as a planner-only change.
This headless replay is a correctness check, not target-PC performance evidence.

Authoring guard: `python tools/test_author_predictive_timetable.py -v` checks
Classic inputs and Standard timings, permits only declared Intensive departure/
name edits, preserves the entire K1 working, and matches generated packs to their
source. All four tests pass before any next-candidate edit.


## Comparison coverage

`tools/compare-timetable-runs.mjs` now reports intermediate arrival and departure
lateness by priority, alongside destination results. This prevents a recovered
late express from appearing unaffected merely because it eventually reaches its
terminus on time. Every booked event is one observation; services with more calls
therefore contribute more events. These are grouped by priority and are not
presented as a service-weighted network punctuality score.

The comparison retains absolute day times, counts early arrivals as zero lateness,
ignores the unrecorded origin arrival and terminal departure, and matches station
identity across alternative platform assignments. Changed calling patterns are
explicitly excluded; missing actual calls fail. Changed booked event times are
reported so timing edits cannot be mistaken for a dispatcher-only improvement.

Validation: 21 call-level assertions, 18 existing comparison assertions and all
3,452 recorded arrival/departure events in a self-comparison of this completed
140-service audit pass. Real Classic/V2 comparison must await both complete days.
