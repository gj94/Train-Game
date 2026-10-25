extends RefCounted
## Physical map limits, never a route grant. Calls at these limits are timing
## points, not passenger stations. A through train leaves only when its tail is
## wholly in the outward portal road beyond the modelled station approaches.

static func portals(w) -> Dictionary:
	return w.scenery.get("network_portals",{})

static func stop_reason(w, stop: Dictionary, index: int, count: int) -> String:
	var kind=stop.get("boundary","")
	if not kind is String or kind not in ["","entry","exit"]:return "Invalid boundary timing point"
	var portal: Dictionary=portals(w).get(stop.get("block",""),{})
	if portal.is_empty():return "Boundary timing point must use a real portal road" if not kind.is_empty() else ""
	if kind!=portal.kind:return "Portal road requires its matching entry/exit timing point"
	if (kind=="entry" and index!=0) or (kind=="exit" and index!=count-1):return "Boundary timing points belong only at the ends of a working"
	if stop.get("direction",0)!=portal.direction:return "Wrong-way boundary timing point"
	if stop.get("dwell_minutes",0)!=0:return "Boundary timing points cannot have passenger dwell"
	return ""

static func journey_reason(data) -> String:
	if not data is Dictionary:return "Journey identity must be an object"
	if data.is_empty():return ""
	for key in ["origin","destination","category"]:
		var value=data.get(key)
		if not value is String or value.strip_edges().is_empty() or value.length()>100 or "\n" in value or "[" in value or "]" in value:return "Invalid full-journey "+key
	if data.category not in ["local","mail","superfast","vb"]:return "Unknown service category"
	return ""

static func has_exit(t: Train) -> bool:
	return t.timetable!=null and not t.timetable.stops.is_empty() and t.timetable.stops[-1].get("boundary","")=="exit"

static func on_exit_road(w, t: Train) -> bool:
	if not has_exit(t) or t.path.is_empty() or t.timetable.index!=t.timetable.stops.size()-1:return false
	var stop: Dictionary=t.timetable.stops[-1]
	var portal: Dictionary=portals(w).get(stop.block,{})
	return portal.get("kind","")=="exit" and t.path[0].edge==stop.block and t.path[0].dir==portal.direction

static func cleared(w, t: Train) -> bool:
	if not has_exit(t) or not t.service_complete or not t.timetable.complete() or t.path.size()!=1:return false
	var stop: Dictionary=t.timetable.stops[-1]
	var portal: Dictionary=portals(w).get(stop.block,{})
	if portal.get("kind","")!="exit" or t.path[0].edge!=stop.block or t.path[0].dir!=portal.direction:return false
	return (t.head_s-stop.s)*portal.direction>=-.001 and preload("res://sim/berth_clearance.gd").fits(w,t,stop.block,t.head_s,portal.direction,false)

static func retire(w, t: Train) -> bool:
	if not cleared(w,t):return false
	t.lifecycle="exited"
	t.speed=0.0;t.controller=0.0;t.cancel_departure_horns()
	t.status="Continues beyond the map to "+str(t.journey.get("destination",t.destination))
	w.dispatch_holds.erase(t.id)
	w.dispatcher().platform_preferences.erase(t.id)
	return true
