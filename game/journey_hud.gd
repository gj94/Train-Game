extends RefCounted
## Presentation only: journey estimates remain in simulation time.
static func text(progress: Dictionary) -> String:
	if not progress.get("scheduled",false): return "No scheduled stops"
	if progress.get("complete",false): return progress.get("depot_status","All scheduled stops completed")
	var station: String=progress.get("next_name","Next stop")
	if progress.get("missed",false): return station+" · Stop missed · F12 for options"
	var distance: float=progress.get("distance_m",INF)
	var seconds: float=progress.get("estimated_seconds",INF)
	if not is_finite(distance) or not is_finite(seconds): return station+" · Awaiting route"
	var metres: String=str(maxi(0,roundi(distance)))
	# Readable metre grouping, including long express legs.
	var grouped:=""
	for i in metres.length():
		if i>0 and (metres.length()-i)%3==0: grouped+=","
		grouped+=metres[i]
	var estimate:="<1 min" if seconds<60 else "~%d min" % ceili(seconds/60)
	if not progress.get("waiting","").is_empty(): estimate+=" + signal wait"
	return "%s · %s m · %s" % [station,grouped,estimate]
