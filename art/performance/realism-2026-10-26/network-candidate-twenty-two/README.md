# Network candidate22 — southern departure groups, V2 only

Both original candidate21 V2 runs failed naturally: baseline K1 at NEM,
11:52:24,65/208 (b1bbd659); delayed L026 at PASA,12:25:14,68/208 (b80e8990).
Their exact evidence and historical source hashes are preserved. Zero safety
events did not satisfy the wait or full-day gates. Neither was installed.

Candidate22 changes only these fifteen departures from candidate21:

| Service | Before | Candidate22 |
|---|---|---|
| M068 | 10:30 | 10:50 |
| M096 | 10:40 | 11:00 |
| S050 | 10:50 | 11:10 |
| M086 | 11:15 | 11:20 |
| L036 | 10:20 | 11:35 |
| L026 | 10:40 | 11:45 |
| S034 | 11:40 | 12:45 |
| M066 | 11:45 | 12:55 |
| M102 | 11:55 | 13:05 |
| S048 | 12:15 | 13:20 |
| M082 | 12:20 | 13:40 |
| M054 | 12:40 | 14:00 |
| S052 | 12:50 | 14:20 |
| M052 | 13:10 | 14:40 |
| S054 | 13:35 | 15:00 |

## Group hypothesis

Move M068/M096/S050/M086 to 10:50/11:00/11:10/11:20, aiming to leave an
interval after the existing L024/M048 group for K1/L025. Put L036/L026 behind
these faster trains at11:35/11:45. In actual21 baseline M048's sampled NEM
envelope clears11:31:22, M068 occupies11:38:32–11:44:56 and M096 enters11:51:26;
L036 has reached NYY and remains held there. K1 waits from11:06:17.70. In
actual21 delayed, L026 atPASA accumulates overtakes and receiving waits;
M086 approaches NYY while L025 approaches in the opposite direction.

Move the following S034/M066/M102 group to12:45/12:55/13:05, leaving an
intended hour after L026's origin departure before the next faster train.
Spread S048/M082/M054/S052/M052/S054 through13:20–15:00 to avoid refilling that
interval immediately. This includes the later departures that would otherwise
catch the locals. The interval is a departure hypothesis, not a guaranteed
section gap. Opposing southbound traffic, later queues and the delayed K1
may be worsened. Only actual baseline and disturbed results can decide.

`sampled-groups.json` records both actual21 full-rake axis-envelope overlaps
with static bounds, source hashes, sample intervals and right-censoring.
These are planning inputs, not exact interlocking ownership, assigned
receiving roads, guaranteed clearance or full-day capacity proof. No new
isolated-model score or complete-population improvement is claimed.

## Validation before launch

Normal authoring and exact --check reproduce both packs from205 overrides.
All four headless authoring guards pass with empty stderr. Reverting exactly
these15 departures recovers each whole predecessor JSON object. Every other
field is unchanged; common-author service arrays match and K1 stays06:00.
208services:40local,104mail,56superfast,8VB;168boundary journeys,71overnight
origins,3–12starts/hour. Common-author consistency is not Classic readiness.

Runtime/routes/tests/six observers and approved sound banks are unchanged.
The completed1003-test suite remains source evidence; it was not rerun for
data timings. Eleven raw proofs are listed in raw-files.json. Exact originals
remain in local candidate-twenty-two-before.

Next commit/push, then launch exactly one V2 baseline with snapshots and one
600s K1 disturbance at07:30 in isolatedv22 outputs. All service/call/departure,
full-tail portal/depot,safety,both wait populations,overtaking and recovery
gates remain mandatory. Network208V2 is unaccepted/uninstalled. No Classic208
replay,installation or native/category requirement is in scope.
