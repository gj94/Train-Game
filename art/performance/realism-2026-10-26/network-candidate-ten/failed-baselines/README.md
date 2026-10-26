# Both candidate-ten baselines rejected

Both genuine undisturbed v10 baselines finish at 08:00:10, rejected for L005's
2,702-second extra wait at Alappuzha. Each finishes only 32/208 services, with
zero safety events and empty stderr. No prepared data is installed. All four
v10 jobs have ended naturally; none should be relaunched unchanged.

The two read-only failure inspections preserve the restored world byte-for-byte.
Unlike the disturbed failures, no future-clearance plan remains at rejection.
The preceding approach reservation for M044 consumed 992 seconds (Classic) or
988 seconds (V2) of L005's wait. The later queue includes M064, L014 and K1 near
Ambalappuzha. Several trains still move; this is not an immovable-deadlock claim.

L013 and L015, both southbound Alappuzha-origin locals, actually leave at 07:04
and about 07:25 despite booked 06:20 and 06:55. They share the constrained AMPA
southbound receiving road with incoming L005, while northbound V002/M044 and
then M064/L014 approach. L005 is already waiting at ALLP from 07:13. The static
isolated profiles did not predict this accumulated queue.

Separately, L002 has accumulated 2,622 extra seconds at Parassala, after an
Eraniel wait of 1,188 seconds. The PARASSALA/NYY queue includes opposing L021,
V005, M095 and M075; the earlier L022 northbound local cleared the same corridor
without a station wait over ten minutes in this prefix. These observations
motivate testing two local-origin departure changes, not changing track,
interlocking, calls, dwell, stock, priority or runtime hold rules.

The delayed and baseline service records differ, but all four fail the same
L005 gate at the same time. The manual K1 hold is therefore not necessary for
this timetable failure. failed-prefix-comparison.json records the selected
arrival/departure differences without claiming complete-day performance.

All 4,837 distinct current source hashes and exact packs were independently
verified. provenance.json records 22 exact raw files. Audits, traffic and failure
snapshots are losslessly compressed; the original snapshot catalogues and starts
remain in the local v10 folders as failed historical outputs. All 1,003 source
tests and four authoring tests remain current because runtime and inputs have
not changed during these four runs.
