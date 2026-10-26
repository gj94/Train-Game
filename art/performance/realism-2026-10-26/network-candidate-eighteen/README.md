# Network candidate eighteen

This departure-only candidate follows the completed v17 failures preserved in
8c9a56c1 (V2) and c56f9221 (Classic). All four original v17 jobs ended naturally
before the planned hold; none passed or was installed.

| Service | Previous | Candidate | Traffic hypothesis |
| --- | --- | --- | --- |
| S030 | 04:20 | 04:50 | Follow L034, leaving a gap after L002 for M045 to obtain KZT receiving space and clear PASA. |
| L006 | 04:40 | 04:05 | Leave QLN before the observed M100 hold and reach ALLP before the M063/L013/S029/M009 crossing queue fills the receiving and onward roads. |

V2 M045 reached PASA04:20:11.70 but waited2,702s:1,690s opposing occupation,
976s KZT receiving reservations and36s route conflicts. L002 left KZT04:48:25.80,
S030 arrived04:53:31.30 and left05:00:50.80; L034 approached from PYD.
The later S030 aims to separate these claims, not force a crossing.
Classic L006 was held at QLN for M100 and left04:46:37.80; it reached the ALLP
approach after06:18 and waited2,436s while M063 waited2,702s inside ALLP.
An earlier L006 aims to clear this chain before the observed southbound wave.
Earlier or later conflicts may still occur. These timings are hypotheses,
not acceptance, a capacity certificate or a guaranteed improvement.

Restoring those two departures recovers each entire predecessor JSON object.
All other pack fields are unchanged, both modes have identical services and
K1 remains06:00. Candidate seventeen's other provisional timings remain.
There are208 services:40 local,104 mail,56 superfast and8 VB;168 boundary
journeys,71 overnight origins and3–13 starts/hour. The hourly totals are unchanged.

All205 overrides reproduce both packs through normal author_network_timetable.gd;
exact --check and all four headless authoring tests pass with empty stderr.
The runtime/tests are unchanged from the completed1,003-test source suite on
candidate ten. That full suite was not repeated for these two data timings.
Ten exact raw proof files and their hashes are included here. Exact predecessor
files remain in .local/realism-2026-10-26/candidate-eighteen-before.

Full-day completion of every service/call/departure/full-tail portal or depot,
zero safety events, both wait populations' cumulative70/90/98/100% targets under
10/20/30/45 minutes and actual overtakes at multiple locations are still required.
Both600-second K1 disturbance runs need actual recovery. No partial or disturbed
data may be installed. No new isolated planning-model score is claimed.
Runtime9ec3530, routes, six observers, calls, dwell, stock, speeds and priorities
remain unchanged. Legacy certifications, R47, approved sound banks and pending
Network UI/category work are preserved. Network208 is unaccepted and uninstalled.

## Verified launch

Candidate9559f4f7 is committed/pushed. Four v18 replays launched once at19:51:50:
Classic baseline3816/13752, V2 baseline22532/11016, Classic delayed13112/460,
V2 delayed10336/9808 (wrapper/child). All eight actual commands/options,
exactly one distinct isolated output each, initial baseline modes,4,837 distinct
source fingerprints and six observer hashes are verified. Verification waited
for initial catalogues; no jobs restarted. Five exact launch files and hashes
are archived. Both baselines save genuine snapshots; delayed runs apply600s
manual K1hold at07:30 and can never be installed. Runtime, routes, packs and
six observers are frozen. No suite/native/search/diagnostic/Git job remains.
Partial clocks are not acceptance. Await these original outcomes before edits.
