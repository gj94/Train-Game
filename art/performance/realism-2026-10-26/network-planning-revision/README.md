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
