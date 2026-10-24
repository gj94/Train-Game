# Saved ETA coverage and the imminent-call dwell correction

The read-only audit visited all 233 five-minute states of the completed,
pre-correction V2 Intensive day. It verified 4,834 source fingerprints and each
state hash, then compared fresh saved passing advice with completed arrivals
only when the actual road and stopping marker matched. It does not step a railway.

34 predictions cover 16 actual arrivals by 14 services, both directions, ICF
passenger and LHB express formations. Six observations exceed the model's own
arrival uncertainty, but they describe only three arrivals. Upper-middle signed error
is +3.48s, p90 +149.08s, range -14.85s to +679.58s (positive is optimistic).
Four different-road forecasts are excluded explicitly. The K1-only mode matches
exactly the six K1 rows selected from all-service output. A Classic timeline is
rejected without writing output. No VB slow-train samples occur in this selection;
this is not a calibration certificate for every stock type or dispatch scenario.
Repeated observations of one arrival are not independent samples.

## Three outlier arrivals

- B042 / Cherthala: three forecasts are 648-680s optimistic. Actual Turavur extra
  waiting totals 788s: opposing B039, B002 overtaking and clearance. The completed
  history records the actual B002 pass at Turavur, not the saved Cherthala idea.
- D129 / Varkala: two forecasts are 136-146s optimistic. The recorded journey
  includes following B013, automatic-block delays and a later B012 pass at
  Paravur rather than the forecast Varkala pass. These observations mix running
  and intervening traffic effects; they do not isolate a numerical model error.
- K1 / Sasthankotta: the 11:34:55.05 forecast is 149.08s optimistic. K1 arrives at
  Karunagapalli at 11:34:55.55 and has a 150-second booked dwell there. Its head
  moves only 0.169m between the 11:34:54 and 11:34:56 traffic samples. The old
  forecast discarded intermediate calls within one metre while the arrival
  controller had not yet acknowledged the stop. That loses the full dwell.

The raw plan, actual calls, grouped waits, actual pass history and approach trace
are retained. No exact forecast-origin frame was stored, so the traffic trace
bounds the position rather than providing a fabricated exact frame. Two focused
regressions reproduce the code defect: 0.25m and exactly-at-marker pending calls
in both directions must retain 150s of dwell, and a pending call must respect a
later booked departure. Before correction: 14 focused passes, two failures.
After correction: 16 passes. The code now retains pending calls down to the existing 1cm route tolerance.
A further manual-overshoot test failed before the final guard, then passed:
remaining unacknowledged calls behind the train now decline onward advice
instead of being silently skipped. Both directions are covered. Acknowledged
stops retain the existing release-time path and are not counted twice.
The first dwell correction passed 963 full source tests; the final overshoot
guard passes 17 focused tests. The final full suite passes 964 tests with
zero failures and empty stderr; full logs are retained here.

## Compatibility and reproduction

These reports describe the accepted pre-correction day with the forecast source
from commit36298eb, preserved as forecast-before.gd.txt. The correction changes a
prepared source hash, so all four mode/day catalogues must be regenerated, plus
corresponding Intensive manual-delay audits. No signatures are relabelled and no
authored departures, priorities, stock, dwell or track geometry change. R46 stays
published. The old complete-day results are historical evidence, not compatible
prepared data for the corrected runtime.

After fresh prepared data passes, run:

```powershell
.local/godot/Godot_v4.7.2-stable_win64_console.exe --headless --path . --script res://tools/audit_saved_forecast_arrivals.gd -- --folder=res://data/timetables/intensive_v2 --all-trains --output=res://.local/eta-after.json
```

Keep the exclusions and external-traffic limitations when interpreting errors.
The interlocking, not these estimates, continues to grant movement authority.
