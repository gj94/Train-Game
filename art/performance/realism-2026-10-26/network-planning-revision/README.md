# Further departure planning after candidate nine

The first strict isolated-profile search returned **UNKNOWN** after 180 seconds.
It produced no departure proposal. This does not prove that 208 services are
infeasible, nor does it justify changing the railway or its acceptance gates.

The model has 208 origin times and 15,816 shared-section pair constraints.
Opposing occupation cannot overlap in its isolated profiles; followers must
retain entrance/exit separation and cannot catch inside a section lacking a
passing road. It also constrains hourly starts and estimated recurring fleet.
Runtime delays, receiving-road decisions and successive passing holds are not
fully modeled. Even a feasible result would need genuine full-day verification.

The selected actual/solo call comparison helps explain the failed v9 result:
M003 reaches Alappuzha at 02:04:41 in both, but actually leaves at 02:56:19 after
successive higher-priority holds and receiving constraints. M041 has already
been delayed at Ernakulam by successive faster services. These sampled records
explain why isolated profile spacing alone is insufficient; they are not a
global ETA accuracy claim.

The local authoring tool uses OR-Tools in an ignored dependency directory. It
does not change shared Python, gameplay dependencies, packs or simulation.
Package versions and download hashes are recorded. API and installation sources:
[Google installation guide](https://developers.google.com/optimization/install)
and [official Python model source](https://github.com/google/or-tools/blob/stable/ortools/sat/python/cp_model.py).

The broader strict search also finished **UNKNOWN**, after 901.128 seconds,
with empty stderr. Mail/superfast origins could move across the full day while
local/VB shifts stayed within 90 minutes and K1 remained fixed. No solution or
infeasibility proof was produced. Its exact script, logs and result are preserved.

The express-spacing heuristic produced 110 proposed origin changes. Independent
arithmetic review confirms the intended tradeoff: shared-section SF/VB gaps
below the 35-minute planning target fall from 240 to seven, and the minimum
modeled gap rises from 20 seconds to 31.8 minutes. However, opposing overlap
instances rise from 329 to 382, and summed pair overlap rises from 988.80 to
1,099.93 minutes. These are periodic isolated-profile pair measurements, not
observed waits, unique blocked minutes or capacity acceptance.

The physical-yard inventory and conservative nominal visit estimates flag
simultaneous demand beyond total roads at ten passing yards in the proposal.
Alappuzha and Ambalappuzha still reach four estimated trains against three roads.
Total road counts are only upper bounds: passenger faces, directional connectivity,
full-rake fit, protected routes and escape roads further restrict real admission.
The visit estimates cannot predict interaction-induced queues or passing holds.
The proposal is therefore **not applied**. The authored timetable remains candidate
nine, and no new replay or Network installation has been started from this proposal.

`completed-search-review-hashes.json` records the exact 16 copied source/results/
log files. The review verifies all proposal input hashes before doing independent
pair and yard arithmetic. No runtime, pack, observer or accepted legacy data changed.

The subsequent v4 search proposes 198 changes and removes nominal total-road
overflows. It reduces opposing overlap to 253 pair instances / 786.50 summed
minutes, but introduces eleven modeled following order reversals inside shared
single-line groups and still exceeds passenger-face counts at seven yards.
The estimated peak isolated fleet is 35, not the earlier target of 34. This
proposal is also **not applied**. Its exact output and independent review are
recorded in `completed-yard-search-hashes.json`.

Static receiving compatibility now comes from the runtime's `receiving_berths`
rule on an empty world, including legal approach/onward paths, full train length,
passenger faces and terminal compatibility. All 44 profiles / 208 service IDs
were exported with 4,835 verified current source hashes and the exact pack hash.
For example, both directions of stopping trains at Kumbalam share only P3;
southbound Ambalappuzha traffic can use only P1; and Kollam passenger roads stay
split three per direction. These facts cannot be inferred from total road count.

The first local exporter attempt rejected an approach because its platform-edge
name filter also matched ordinary section names; it exited without a usable
inventory. The next version succeeded but treated an entry portal's station prefix
as an origin yard. The final v2 export uses exact platform-edge membership and
includes portal-fed arrivals. Only that final export is used by the next search.
The earlier scripts/logs are retained for provenance; no game source changed.

Direct bipartite matching agrees with the new compatible-road subset constraints
in all 83,520 checked yard-minute cells across the original and v4 plans. V4 still
has 746 nominal yard-minute cells without a matching assignment across 20 yards,
versus 897 across 26 before. These are conservative isolated-profile planning
cells, not actual occupied roads or measured waits. There are 110 origin visits
with documented passenger-road upper bounds because depot supply is not an
incoming receiving movement. Live routes, escape claims and interaction-induced
delays still require full simulation.

The new v5 diagnostic uses these 108 compatible-road resource subsets and stronger
following-order penalties. Twenty incremental-cost checks match direct calculation.
It is currently a proposal search, not a new authored candidate or replay. Its
source and static verification evidence are in `compatible-berth-review-hashes.json`;
the running log/result remains local until complete.
