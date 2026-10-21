# Event skip and local dispatcher evidence

Development PC: Ryzen 7 7840HS / Radeon 780M, Godot 4.7.2, 1280×720.
The playing target is i9-13980HX / RTX 4090 Laptop / 64 GB; these are not
measurements from that laptop. No distribution gameplay test was performed.

## Native skip benchmark

`tools/benchmark_skip_map.gd` restores the same 09:00 Standard railway before
each run, advances exactly 600 simulated seconds and caps the UI at 30 FPS.
It runs hidden / map / map / hidden, followed by a forced history/encounter-search
window with interruptions disabled for comparison. That last fixture deliberately
uses a shortened timeout; its `ok=false` is the expected timeout result, not a
safety failure. All five finish with exactly equal complete saved railway states
and zero safety events. The actual native map was drawn throughout visible runs.

| Mode | Wall seconds | Simulation rate |
| --- | ---: | ---: |
| Hidden | 15.669 | 38.29× |
| Map | 16.157 | 37.14× |
| Map repeated | 16.437 | 36.50× |
| Hidden repeated | 15.867 | 37.81× |
| Map + prediction/history | 17.969 | 33.39× |

The map averages about 3.4% more elapsed time / 3.2% lower throughput than the
two hidden controls. Including prediction/history costs about 14.0% more time /
12.3% lower throughput. Peak additional tracked heap in the history case was
82,403,212 bytes (78.6 MiB), compared with 4.0–6.1 MiB in the ordinary runs.
This is one ten-minute busy interval, not a claim about every timetable state.
The benchmark's unavailable audio output fell back to Dummy; 3D and sound are
disabled during skip. Later UI captures use Dummy explicitly. Text labels gained
explicit km/h units after this timing run; the snapshot/drawing algorithm is the same.

## Restore and UI checks

`history-audit.json` records exact restore AND identical 120-second replay from
Standard 09:00, Standard 22:00 and Intensive 09:30. These contain 100/100/140
services, 12/18/20 active trains and real passenger exchange/reservations. Existing
train object identities survive. No safety events occurred.

`native-ui.txt`: 37 actual source-game checks pass. They cover persisted independent
event switches and focus, detached map, clock skip, a completed next-event skip,
Xbox cancellation/disconnection, stale commands, safe quit, scene teardown and
finished-service return. The event run returned K1 997 m before Kumbalam, paused,
with AI driving. The harness disables ordinary scenery updates, so its completion
image is a UI check, not a destination-scenery beauty capture.

`source-refresh.json` records the seven skip-only files added/changed. Every other
railway input matches the prior audited source. Original skip movement and worker
simulation-loop bodies are byte-identical. Prepared checkpoints and original
full-day audits remain unchanged; source-provenance refresh is not a new replay.

See [user controls and behaviour](../../../docs/event-skip.md).

`headless-tests.txt`: 751 passed, zero failed. `corridor-events.json` checks
actual Standard railway crossings and both overtake roles, plus a delayed
overtaker: every warning returns 60 seconds before the observed first overlap
(within 0.1 s on replay), with no safety events. Delaying B001 changes the
encounter prediction; it is not replaying the home-page baseline preview.

The depot-access speed correction and stationary departure-horn ceremony were
stashed at the user's request before publication. Neither is included here;
both need operating-day regeneration/validation in the next release.
