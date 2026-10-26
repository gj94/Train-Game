# Candidate eighteen: V2 baseline failure

The original baseline22532/11016 finished naturally at08:46:28 with M013
waiting at SRTL,37/208 complete,2,702s maximum extra wait in both populations,
zero safety events and empty stderr. This run had no manual intervention.
All four original candidate18 runs have now finished and failed. No Network
prepared data is accepted or installed; no failed job was restarted.

## Failed-prefix gates

| Population | Under10m | Under20m | Under30m | Under45m |
|---|---:|---:|---:|---:|
| All locations |119/169 pass|154/169 pass|162/169 FAIL|168/169 FAIL|
| Station only |66/103 FAIL|93/103 pass|100/103 FAIL|102/103 FAIL|

Targets are cumulative70/90/98/100%. These are failed prefixes, not complete
operating days. No whole-population comparison or recovery claim is made.

## Actual queue

M013 arrives SRTL07:59:29.75 and never departs before failure. Its2,702s
extra wait is2,634s opposing M044/M064 section occupation,66s MAKM receiving
reservations and2s awaiting V001's overtake. The immutable inspection has
SRTL claims M013P1 and incoming M044,M064,V001 each compatible with P1/P2/P3.
M044 is stopped on the approach while protecting compatible receiving roads;
M064 waits behind it for automatic block clearance. V001 waits on the other
approach for compatible receiving roads. M006/M008 wait at MAKM protecting
M013's onward crossing, and S009 waits at TUVR for SRTL availability.
K1,L002,L007 and S030 move. V002 has left the map. No future-clearance plans
remain. This snapshot alone is not proof of permanent deadlock or a runtime
bug. The baseline's outcome must not be attributed to the delayed run's hold.

## Preservation

provenance.json identifies13 exact raw files and verifies4,836 current-at-run
source fingerprints. The exact V2 pack matches the launch job and audit.
Lossless fixed-mtime gzip preserves audit,traffic,failure and inspection;
original outputs remain intact. Inspection is byte-immutable with empty
stderr. The actual summarize-timetable-run.mjs summary is preserved; finished
means an audit exists, not208 services completed. Runtime9ec3530 and six
observers are unchanged from candidate9559f4f7. No source test rerun was
needed for this evidence-only increment; the existing1,003-pass source suite
and four authoring checks remain historical results, not new runs.

Next planning must coordinate opposing departure groups across connected
single-line sections using actual queues, compatible receiving roads and
full-tail clearance. Preserve every non-departure field, identical services
across modes, K1 at06:00 and every acceptance gate.
