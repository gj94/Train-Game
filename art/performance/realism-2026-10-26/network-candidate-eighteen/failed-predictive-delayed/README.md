# Candidate eighteen: V2 disturbed failure

The original predictive delayed rehearsal (wrapper10336/child9808) finished
naturally at09:30:08 with V001 waiting at MAKM-S3,47/208 services complete,
2,702s maximum extra wait,2,454s maximum station wait,zero safety events and
empty stderr. It used candidate9559f4f7 with runtime9ec3530 and the unchanged
600s manual K1 intervention at07:30. It is not accepted or installed and has
no full-day or disturbance-recovery certificate. The original V2 baseline
remains pending; both original Classic runs have already failed before the hold.

## Exact failed-prefix wait gates

| Population | Under10m | Under20m | Under30m | Under45m |
|---|---:|---:|---:|---:|
| All locations |137/197 FAIL|178/197 pass|190/197 FAIL|196/197 FAIL|
| Station only |75/119 FAIL|105/119 FAIL|114/119 FAIL|119/119 pass|

Targets are cumulative70/90/98/100%.137/197 is below70%; it must not be
rounded up. These populations cover only the failed prefix. A pass in a
column does not certify the whole day or waive the other population.

## Actual queue

V001's failed MAKM-S3 wait totals1,254s of opposing single-line occupation
(S030618s,M008588s,S00648s),1,150s of ALLP receiving-road availability or
reservations,184s of occupied blocks and114s of route conflicts. These
categories sum exactly to2,702s. Earlier V001 waits remain in the raw report.

The byte-immutable inspection restores the actual failure snapshot without
advancing simulation. ALLP claims are S006P1,S009P2,L002P3. V001 waits at
MAKM-S3 for S006; S030 waits at SRTL for M011. S006 and L002 approach ALLP,
S009 exchanges passengers. K1,L007,M008,M013 and M006 also move; V002 has
left the railway. No future-clearance plans remain. This instant does not
prove permanent deadlock or a runtime defect.

K1's minute samples during the configured07:30-07:40 intervention show
27.4545764399m of braking movement by07:31, then unchanged recorded extents
through07:40. These are samples, not exact controller-frame timestamps.
They differ from earlier generations' braking distances and are preserved
without relabelling. No recovery certificate is inferred from the later clock.

## Preservation and verification

provenance.json lists13 exact raw files and verifies4,836 current-at-run
source fingerprints, including the frozen observers. The exact pack hash
matches the job and final audit. Gzip containers are lossless with fixed
mtime0; original audit,traffic,failure and logs remain in the isolated output.
The real summarize-timetable-run.mjs summary is preserved: finished means
an audit exists, not208 completed services. No complete-population comparator
or installation was run. Inspector stderr is empty and snapshot_unchanged=true.

Runtime/routes/packs/observers remain frozen while the original V2 baseline
continues. No failed job was restarted. Source tests remain the prior1,003-pass
suite; no unchanged suite was rerun for this evidence-only increment.
