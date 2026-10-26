# Candidate ten: receiving-compatible departure planning

This is an authored candidate for full-day simulation, **not accepted traffic**.
It changes 202 departures from candidate nine, preserving every other pack field
and identical Classic/V2 service definitions. K1 remains 06:00. The 208 services
include 168 journeys crossing a map boundary, 69 overnight origins, and 3–12
departures in every hour. The category mix remains 40 locals, 104 mails, 56
superfast and eight Vande Bharat services. This is the previously researched
representative adaptation, not a verified real-day Indian railway timetable.

The v5 search uses the 44 measured isolated stock/call profiles and the runtime's
static receiving-road compatibility exported in `network-planning-revision`.
It accounts for following separation, repeated express approaches, opposing
single-line occupation and compatible receiving-road subsets. No forced passing
sites, runtime holds, stock, speed, priority, call or dwell changes were made.

Two small final changes to the v5 proposal move L031 from 18:30 to 18:31 and L023
from 05:50 to 05:47. They reduce unmatched conservative yard-minute estimates
from three to one. A strict zero-target repair within five, then fifteen minutes
could not remove the final TVC clash without worsening another modeled constraint;
those diagnostic scripts are preserved. The remaining cell is at minute 1,310,
with M069 and S019 both requiring TVC P1. It is an explicit planning limitation,
not an observed one-minute wait or a waiver of any actual wait gate.

The model has a significant tradeoff: opposing overlaps increase compared with
candidate nine. Nominal berth assignment and following order improve, but neither
this improvement nor the lower objective certifies real performance. The true
dispatcher can change passing plans, delay approaches and create opposing queues.
All actual continuous/cumulative wait, calls, completion, safety and overtake gates
remain unchanged. Real baselines and 600-second K1 disturbances must decide whether
this candidate works. There is no Network installation or acceptance claim.

`candidate-ten-field-proof.json` verifies that restoring old departures makes each
entire pack identical to its predecessor. The exact predecessors match the files
in `network-candidate-nine`. The normal authoring tool produced both new packs,
then reproduced them exactly in `--check` mode. All four authoring tests pass with
empty stderr. The full source suite also finished: **1,003 passed, zero failed**,
empty stderr. The three authored file hashes remain unchanged from suite launch.

`planning-and-authoring-hashes.json` preserves 23 exact completed diagnostic and
authoring files. `full-suite-hashes.json` preserves the final source-suite log,
stderr and job record. Actual replay evidence remains pending.

The staged-file check confirms all 26 raw evidence files and both authored packs
are byte-identical to their recorded hashes. Git normalizes the override file
from CRLF to LF; its JSON is identical, and both worktree and staged hashes are
recorded explicitly. No prepared-data source fingerprint was altered or relabeled.

The tested candidate was committed as `a5e93191`. Four genuine v10 replays launched
once at 12:46 on that commit: Classic/V2 baselines with snapshots and both modes'
600-second manual K1 disturbance at 07:30. All eight wrapper/child commands,
distinct output arguments, initial modes, 4,837 distinct current source hashes
and six frozen observer hashes are verified. `launch-evidence-hashes.json` records
five exact launch/provenance files. The launch status is an initial snapshot;
all four had empty stderr and no final audits. No full-day acceptance is implied.
