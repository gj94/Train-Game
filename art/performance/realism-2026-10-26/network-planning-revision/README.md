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

A broader strict search and an independent proposal with express-spacing
penalties are still under evaluation. Neither is accepted traffic. Preserve
the source timetable until a proposal has been reviewed and validated.
