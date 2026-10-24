# Completed Standard 100 operating days

Both unchanged-departure Standard days finished at 03:20 on the following day.
Every service completed every call and cleared to depot; zero safety events.
Independent finalizers and verification tools checked all 4,833 railway inputs,
100 departures and 233 exact five-minute restored states for each mode. The
corresponding source data are installed separately; R46 is unchanged.

| Extra wait, at least 30 seconds | Classic | Predictive V2 |
| --- | ---: | ---: |
| All-location episodes | 176 | 181 |
| Under 10 minutes | 77.27% | 85.08% |
| Under 20 minutes | 96.02% | 97.24% |
| Under 30 minutes | 100% | 100% |
| Station-only under 10 minutes | 73.50% | 82.05% |
| Maximum continuous wait | 28m16s | 29m34s |

All wait targets pass, including station-only distributions. The Standard day
has three distinct K1 overtakers in each mode; the ten-pass requirement applies
to Intensive. Classic has 470 observed crossings and 47 overtakes. Both directions
of each encounter are represented in the service browser.

## Punctuality trade-offs

`comparison.json` includes all destination and intermediate-call results. Same
service IDs, departures and booked calls are retained, on the same layout and
simulation sources. V2 is not uniformly better. Priority-85 mean destination
delay falls from 653.21 to 372.50 seconds, while priority-100 rises from 393.10 to
688.85 seconds. B001 improves by 99.65 seconds, but B012 worsens by 691.15 seconds.
K1's arrival delay rises by 78 seconds, to 7m04s.

B012 reaches Kollam 256.6 seconds sooner, then loses that advantage in the
northern single-line section: its Alappuzha departure is 49 seconds later, and it
subsequently waits 592 seconds at TUVR-N2 for an opposing B004 crossing. B031 also
has a larger AMPA-N3 crossing wait; B020 encounters a different ALLP crossing and
then gives way to higher-priority B021 at SRTL. `regression-waits.json` preserves
the actual hold reasons. These are observed differences, not proof that one
isolated planning decision caused every downstream delay. Local passing forecasts
do not optimize all future opposing movements globally; retain this limitation
when judging the optional planner. Do not claim every express is improved.

## Saved forecast calibration

`tools/audit_saved_forecast_arrivals.gd` checks immutable replay input and state
hashes and reads saved fresh K1 advice without advancing the railway. It compares
only the same actual road and stopping marker, using the completed working as
reference. Seven forecasts cover only **two distinct arrivals** (SRTL and STKT),
with 6.2 to 21.4 minute leads. Actual minus predicted arrival ranges from -7.27 to
+0.95 seconds. This sparse selected sample is useful calibration, not seven
independent journeys or a general safety guarantee; external holds and later
replaced advice can affect other samples.

```powershell
.local/godot/Godot_v4.7.2-stable_win64_console.exe --headless --path . --script res://tools/audit_saved_forecast_arrivals.gd -- --folder=res://.local/dispatcher-v2-2026-10-24/rehearsals-v3/predictive-standard --output=res://.local/dispatcher-v2-2026-10-24/saved-eta-standard.json
node tools/compare-timetable-runs.mjs .local/dispatcher-v2-2026-10-24/rehearsals-v3/classic-standard .local/dispatcher-v2-2026-10-24/rehearsals-v3/predictive-standard
```

## Native preparation checks

36 native checks pass on the actual Classic/V2 Standard catalogues at 1280x720:
service counts and calls, reciprocal traffic roles, real departure restoration,
mode identity, and asynchronous noon-checkpoint restoration. All four captured
screens were reviewed. This machine could not initialize WASAPI, so Godot used
its dummy audio driver; this menu check makes no audio claim. The checker remains
local until the two Intensive choices are validated too. All 961 full source tests pass, zero failures and empty stderr; the log is
included. No runtime/test scripts were edited during that suite.

Playtest in the source build: choose each Standard mode, select K1 and inspect
Stops and Traffic. Open Explore by time at noon, select K1, confirm the labelled
mode and differing actual positions, then join the service. B012's later outcome
must remain visible in its own measured traffic/arrival data rather than hidden
by an aggregate improvement claim. No executable release was prepared.
