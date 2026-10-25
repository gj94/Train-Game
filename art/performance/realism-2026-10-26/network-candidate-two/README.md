# Second Network candidate: rejected before the manual disturbance

These are exact rejected or stopped outputs from the 04:00:37 v2 generation,
using corrected simulation source `66ab453`. None is installable prepared data.
The four Standard/Intensive v2 baselines remain running with unchanged inputs.

| Run | Result | Simulated end | Finished | Safety events |
| --- | --- | --- | ---: | ---: |
| Classic Network baseline | L005 continuous wait 2,702s | 05:40:04 | 18/208 | 0 |
| Classic Network delayed | Same L005 failure | 05:40:04 | 18/208 | 0 |
| Predictive Network delayed | L022 continuous wait 2,702s | 07:00:24 | 26/208 | 0 |
| Predictive Network baseline | Intentionally stopped, no final audit | about 05:55 | Incomplete | No final claim |

Both configured disturbances would start at 07:30, so neither failed delayed
run tested the manual hold. The stopped predictive baseline matches all 10,677
complete traffic samples of the delayed run through its observed prefix.
Its interrupted trailing line is retained byte-for-byte in the raw gzip and
excluded from that comparison. This does not establish completed-day equivalence.

L005's Classic origin wait contains successive M009/M045 receiving-road holds,
716 seconds explicitly giving way to M045, and 558 seconds of opposing S004/S026
single-line holds. The actual failure checkpoint has M004 moving north toward
Kumbalam and M009 departing Cherthala. This northern railway is progressing;
the original local departure falls into a congested opposing/express sequence.

The separate predictive failure has L002/M078 occupying both Kulitturai roads,
L033/S045 occupying both Neyyattinkara roads and M061 awaiting Kulitturai from
Parassala. Conservative onward-crossing checks hold the opposing approaches;
L022 accumulates its failed wait behind Kulitturai at Eraniel. Read-only
inspection records the actual routes, calls, candidates and blockers and verifies
that restoring/inspecting the checkpoint did not mutate the captured simulation.

The next authored candidate changes only two departures in **both** modes:

- L005 Ernakulam–Kollam local: 04:55 → 05:20, separating its initial movement
  from the northern opposing arrivals and successive express departures.
- L033 TVC–Nagercoil local: 05:40 → 06:35, following the 06:25 VB origin
  departure and separating the southern opposing morning clusters.

Every call, running-time offset, dwell, stock, priority and other field is
unchanged. The modes still use identical 208 service arrays. The new distribution
has 66 departures from 22:00 through 05:59, with 4–14 in every hour. This is an
unproven timetable candidate, not a claim that retiming resolves the full day.
Both new baselines and both real 600-second manual-delay runs are required.

`retiming-verification.json` compares the exact old packs here with the new
authored packs. `provenance.json` records raw byte counts/hashes and process
outcomes. Gzip files decompress to the unchanged raw evidence. Original local
folders, including all incomplete start/time states, remain preserved. Waiting
targets, physical interlocking, source simulation and prepared-data validators
are unchanged. The authoring overrides are separate from simulation sources;
all 4,835/4,836 hashes of the four ongoing legacy baselines still match.
