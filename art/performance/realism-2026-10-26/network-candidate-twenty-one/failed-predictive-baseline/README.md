# Candidate21: original V2 baseline failure

The original baseline 26756/20168 finished naturally at **11:52:24**, with
**65/208 services complete**, failing K1 at NEM after **2,702 seconds** of
extra station wait. Maximum all-location and station-only waits are both
2,702 seconds. Zero safety events, empty run/inspection stderr, no manual hold.
Both original candidate21 runs have now finished and failed. Neither is
accepted or installed; there is no full-day or recovery certificate.

Source candidate `74637eef`, launch proof `021c442a`. The delayed failure is
preserved separately in `../failed-predictive-delayed` (commit `b80e8990`).
Its statement that the baseline remained live is historical.

## Wait gates in this failed prefix

| Population | Under 10 min | Under 20 min | Under 30 min | Under 45 min |
|---|---:|---:|---:|---:|
| All locations | 182/251 pass | 225/251 fail | 243/251 fail | 250/251 fail |
| Station only | 102/150 fail | 133/150 fail | 147/150 pass | 149/150 fail |

225/251 is below 90%; it must not be rounded up. Passing fractions cover only
this failed prefix. Every service, call, departure and full-tail completion
has not been established. No complete-population comparison was performed.
The identical K1 failure clock and completion count to candidate20 do not
make these whole failed populations equal or demonstrate improvement.

## Actual queue

K1 reaches NEM at 11:06:17.70 and has no departure by failure. The failed wait
comprises 1,638 seconds of opposing section occupation by M084/L024/M048/
M068/M096, 994 seconds protecting NYY receiving or onward crossing capacity,
22 seconds awaiting M084 crossing and 48 seconds of route conflicts.

Read-only inspection restores the actual failure snapshot without stepping;
before/after captures are byte-identical and there are no future clearance
plans. NYY claims L036 on P2 and incoming S050 with P1/P2 alternatives, not
two simultaneous reservations. K1 waits for opposing M096 in NEM_single;
L036 waits for M096's occupied block. L025 waits at TVC to preserve NYY
crossing capacity; L026 at PASA awaits S050's overtake. M096, S050, L024,
S034 and L008 move; M048, M068 and M086 exchange passengers. M084 is in
depot storage. This is neither a permanent-deadlock nor a runtime-defect proof.

## Preserved evidence

`provenance.json` records 13 exact raw files and hashes: losslessly compressed
audit, traffic, failure snapshot and immutable inspection; original logs;
actual summary; exact V2 pack; inspection tool and job identities/options.
All 4,836 report source hashes were verified against current-at-run sources.
Original outputs remain intact. Hashes become historical after future edits.

Next coordinate departures using both actual southern queues, with full-rake
clearance and compatible receiving roads. Preserve K1 at 06:00, every
non-departure field and every gate. Classic Network208 remains outside scope.
