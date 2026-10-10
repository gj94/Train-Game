extends RefCounted
## Timed depot supply. Future services do not occupy, reserve or render track.
## Entry is a scenario boundary at a free origin berth, not authority to move.
const PREPARATION := 120.0
const STORAGE_SECONDS := 600.0

static func can_enter(w, t: Train) -> bool:
	var road: String = t.path[0].edge
	if w.occupancy().has(road): return false
	if not preload("res://sim/berth_clearance.gd").fits(w,t,road,t.head_s,t.path[0].dir): return false
	for sig in w.signals.values():
		if sig.route.any(func(r): return r.edge == road): return false
		# A route departing this berth also needs the origin clear.
		if sig.edge == road and not sig.route.is_empty(): return false
	if not w.dispatcher().future_clearances.owner(road).is_empty(): return false
	var station: Dictionary=preload("res://sim/priority_dispatch.gd").station(w,road)
	if station.is_empty():return true
	var occupied: Dictionary=w.occupancy()
	var reserved:={}
	for sig in w.routed_signals():
		for r in sig.route:reserved[r.edge]=true
	var free: Array=station.platform_tracks.filter(func(r):return r!=road and not occupied.has(r) and not reserved.has(r))
	var claims:=[]
	var planner=w.dispatcher()._planner
	for other: Train in w.active_trains():
		if other.path[0].edge in station.platform_tracks:continue
		var ns: Dictionary=w.next_signal(other)
		var route: Array=w.signals[ns.id].route if not ns.is_empty() else []
		if route.any(func(r):return r.edge in station.platform_tracks):continue
		for seg in other.path+route:
			var section: String=w.single_line_sections.get(seg.edge,"")
			if section.is_empty() or planner._exit_station(w,section,seg.dir).get("code","")!=station.code:continue
			claims.append({id=other.id,roads=planner._receiving_roads(w,other,station,seg.edge,seg.dir,free)})
			break
	return planner._can_berth(claims)

static func update(w) -> void:
	var scheduled := []
	for t: Train in w.trains.values():
		if t.lifecycle == "scheduled": scheduled.append(t)
		elif t.lifecycle == "active" and t.depot.get("phase", "") == "stabled":
			if w.clock_seconds() < t.depot.stabled_at + STORAGE_SECONDS: continue
			if t.id == w.dispatcher().manual_service or not t.automatic: continue
			if w.signals.values().any(func(s): return s.owner == t.id): continue
			# Only a full train inside a dedicated depot can enter offstage storage.
			if t.path.size() != 1 or not w.depots.has(t.path[0].edge): continue
			t.lifecycle = "stored"
			t.status = "Service complete · in depot storage"
			w.depot_reservations.erase(t.path[0].edge)
	scheduled.sort_custom(func(a,b): return a.timetable.departure < b.timetable.departure if a.timetable.departure != b.timetable.departure else a.id.naturalnocasecmp_to(b.id) < 0)
	for t: Train in scheduled:
		if w.clock_seconds() < t.timetable.departure - PREPARATION: break
		if not can_enter(w,t):
			t.status = "Awaiting a clear origin berth · " + t.path[0].edge
			continue
		t.lifecycle = "active"
		t.status = "Preparing for booked departure"
