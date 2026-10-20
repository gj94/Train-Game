# KZT reported departure regression

`B012.bin` is the original R36 prepared NCJ–ERS Vande Bharat departure, saved
at 09:08:02 before its booked 09:10 start. It includes the complete 100-service
railway so B014 and B088 retain the traffic history from the reported build.
The reduced catalogue keeps the original service row and its SHA-256.
Provenance records the source release and full original catalogue checksum.

Do not regenerate this fixture when rebuilding the game's prepared departures:
that would change the starting conditions of the regression. Production
departures remain in `data/service_starts/`. `tests/*` is excluded from exports.

Run from the project root:

```powershell
& .local/godot/Godot_v4.7.2-stable_win64_console.exe --headless --path . `
  --script res://tools/check_kzt_dispatch.gd -- --require-forward
```

Add `--delay=600` to pause the incoming driver after the receiving platform
has been promised. Both runs must complete the KZT crossing without releasing
the opposing train before the full VB is received.
