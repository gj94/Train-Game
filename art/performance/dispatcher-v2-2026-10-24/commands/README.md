# V2 service deletion and save restoration

The old command path removed a service while automatic dispatch was disabled
but retained accepted predictive advice referring to that service. Saving
immediately then failed to restore: `Missing predictive dispatcher participant`.
A pending result could also survive deletion/reintroduction of an identical ID.

A successful deletion now advances the forecast membership generation and
clears advice before removal. Pending worker results are rejected when received,
without synchronously waiting for them. Refused deletion preserves valid advice.
Classic routing and the existing occupancy/authority cleanup are unchanged.

Validation:

- Three new owner regressions; 18 owner tests and five existing deletion tests pass.
- Direct before/after reproduction covers both enabled and disabled dispatch.
- Native Forward+ source UI: 11 checks pass; stderr empty. Reviewed 720p confirmation
  and post-deletion views. Cancellation leaves the railway byte-for-byte unchanged;
  confirmation preserves K1 and returns controller focus to its roster entry.
- Immediate snapshot restoration after confirmed paused deletion is exact.
- Full source suite: **956 passed, zero failures**, stderr empty (`source-tests.log`).

Reproduce native UI with the bundled Godot and
`--path D:/ClaudeWS/train-game --audio-driver Dummy --script res://tools/check_predictive_commands.gd`.
The diagnostic uses the small K1/B002 predictive fixture, not a prepared full day.
It does not advance time or modify installed timetables. Outputs go to
`.local/dispatcher-v2-2026-10-24/deletion-ui`.

Manual check after the compatible days are prepared: select Predictive V2, pause,
open Operations, disable automatic dispatch, inspect another service and choose
Dispatch tools > Delete service. Verify Keep service cancels, then confirm deletion.
Save and reload immediately. Your assigned service and dispatch mode should remain;
the deleted service must stay absent. Restart restores the authored service.
