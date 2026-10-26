# Candidate seventeen: open a gap in the observed northbound wave

| Service | Previous departure | New departure |
| --- | --- | --- |
| M100 | 03:05 | 02:00 |
| M078 | 03:20 | 02:10 |

All four v16 runs failed M045 at NYY04:45:52, before the planned hold. Their
exact audits, traffic, failure snapshots, immutable inspections and hashes are
preserved in candidate-sixteen/failed-runs (4a25536a). M045 reached NYY03:57:01.10
and accumulated2,196s opposing occupation,468s receiving/downstream protection
and38s conflicts. S042, M100, M078 and M044 successively occupied the section.

These two northbound mails are moved ahead of S026/M092/M076 to aim for a gap
between the earlier northbound group and M044/M064/S046 when M045 needs NYY/PASA
and KZT crossing space. M094 remains01:50, M10002:00, M07802:10 and S02602:25.
The earlier group can itself encounter new queues; this is a hypothesis, not a
guaranteed gap, capacity proof or complete-day improvement. No new isolated-model
score is claimed. M045 remains00:00 and S03004:20; every other service is retained.

Restoring these two departures recovers each entire predecessor JSON object.
Both modes have identical services; K1 remains06:00. All calls, dwell, stock,
priorities, speeds, tracks and interlocking are unchanged.208 services comprise
40local,104mail,56superfast,8VB;168 boundary journeys,71 overnight origins and
3–13 starts/hour. Exact predecessor files remain in candidate-seventeen-before.

Normal authoring through205 overrides reproduces both packs exactly with --check.
All four headless authoring tests pass with empty stderr. Runtime/tests are
unchanged from the completed1,003-test suite on candidate ten; that full suite
was not rerun for two departure edits. Ten exact diagnostic files are hashed.

Fresh Classic/V2 baseline and delayed replays must meet every unchanged completion,
full-tail clearance, safety, station-only and all-location wait target. Disturbed
runs must actually reach and recover from the600s K1hold07:30–07:40. Passing
baselines can be finalized independently; category comparisons and actual menu,
midnight and save-load checks remain required. Network208 is not accepted or
installed. Legacy certifications, runtime9ec3530, R47 and unrelated files remain.

## Verified v17 launch

Candidate5ffdb3da is committed/pushed. Four v17 replays launched once at19:08:12:
Classic baseline16000/12508, V2baseline15064/2092, Classicdelayed16736/12232,
V2delayed10492/17808 (wrapper/child). All eight actual commands/options, distinct
single outputs, initial baseline modes,4,837 distinct source hashes and six
observer hashes are verified. Verification waited for initial catalogues;
no jobs restarted. Five exact launch files and hashes are archived. At19:08
baselines are starting,delayed00:20,empty stderr,no final audits. Partial clocks
are not acceptance. Runtime/routes/packs/observers are frozen. Baselines save
real snapshots; delayed runs apply600s K1hold07:30–07:40 and cannot be installed.
No suite,native,search or diagnostic job remains.
