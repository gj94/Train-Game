# Candidate-eleven V2 baseline rejected

The original V2 baseline finished naturally at 07:56:50, with L002 exceeding
45 minutes of extra waiting at Neyyattinkara. It completed 32/208 services,
recorded a 2,702-second wait, zero safety events and empty stderr. This baseline
has no manual K1 hold. The Classic baseline remains independently pending.

The first three cumulative wait targets pass only within this failed prefix.
Under45 counts are 141/142 at all locations and 84/85 at stations, below 100%.
No incomplete population was passed to the completed-day comparison tool.

The failure time, complete L002 service record and all its station-wait rows
match the V2 disturbed run exactly. Whole service records and traffic hashes
differ, so no wider equality is claimed. The local failure does not require
the manual K1 hold. `baseline-vs-delayed.json` records the exact comparison.

L002 remains at Neyyattinkara after arrival at 07:10:39.10, with successive
opposing movements and constrained receiving space at Thiruvananthapuram South.
Read-only inspection preserves the snapshot bytes and finds no future-clearance
plan. Other trains are moving; this is not an immovable-deadlock diagnosis or
proof of a runtime defect. Existing dispatch and interlocking remain unchanged.

All 4,836 source hashes and the exact V2 authored pack hash verify against this
run. `provenance.json` records 14 exact raw files, including losslessly compressed
audit, traffic and failure snapshot, the original pack, immutable inspection,
logs and scoped comparison. Original local output is preserved. Summary
`finished` means a final audit exists; this audit explicitly failed with only
32 services completed. No Network installation or new executable follows.
