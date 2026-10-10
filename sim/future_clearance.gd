extends RefCounted
## A bounded three-train crossing transaction. Forecasts select opportunities;
## physical occupation and ordinary interlocking advance the transaction.
const Planner := preload("res://sim/dispatch_planner.gd")
const Berths := preload("res://sim/receiving_berths.gd")
const Prediction := preload("res://sim/dispatch_prediction.gd")
const HORIZON := 1200.0
var enabled := true
var plans: Array = []
var _next_search := 0.0
var _planner := Planner.new()

func update(w, engine, discover: bool) -> void:
	for p in plans.duplicate():
		if [p.incoming,p.opponent,p.vacater].any(func(id):return not w.trains.has(id)):
			# Service replacement builds a new world; never transfer promises to IDs.
			plans.erase(p)
			continue
		p.received = p.received or _contained(w.trains[p.incoming],p.future_road)
		p.opponent_received = p.opponent_received or _contained(w.trains[p.opponent],p.opponent_road)
		p.escaped = p.escaped or _contained(w.trains[p.vacater],p.escape_road)
		if p.received and p.escaped and not w.trains[p.opponent].path.any(func(seg):return seg.edge==p.opponent_road):
			engine._record(w,"crossing_complete",p.incoming,"Planned platform succession completed at "+p.station)
			plans.erase(p)
	if not enabled or not discover or w.time < _next_search: return
	_next_search = w.time + 10.0
	var trains: Array = w.active_trains().duplicate()
	trains.sort_custom(func(a,b):return a.id<b.id)
	for t: Train in trains:
		if t.service_complete or t.timetable==null or (not t.automatic and engine.manual_service!=t.id):continue
		if t.timetable.at_stop and t.timetable.release_time()>w.clock_seconds():continue
		var proposed := propose(w,engine,t)
		if proposed.is_empty():continue
		plans.append(proposed)
		engine._record(w,"crossing_plan",t.id,"Approach "+proposed.station+"; receive into "+proposed.future_road+" after "+proposed.vacater+" clears; hold "+proposed.opponent+" until arrival")

func propose(w, engine, t: Train) -> Dictionary:
	if not w.scenery.get("geographic",false) or _participant(t.id) or _unavailable(engine,t):return {}
	var ns: Dictionary=w.next_signal(t)
	if ns.is_empty() or ns.id in w.automatic_signals or engine.inhibited_signals.has(ns.id):return {}
	var approach := _approach(w,t)
	if approach.is_empty():return {}
	var st: Dictionary=approach.station
	if st.through_halt:return {}
	if _arrival_fixed(w,t,st):return {}
	var occ: Dictionary=w.occupancy()
	var free: Array=st.platform_tracks.filter(func(road):return not occ.has(road) and not _reserved(w,road))
	var own_free:=Berths.roads(w,t,st,approach.edge,t.path[0].dir,free)
	# The stopping train may have no free passenger face yet (one-platform yard).
	# The opponent still needs a separate usable road and a free escape berth.
	# More complicated yards keep the ordinary conservative admission policy.
	if own_free.size()>1:return {}
	for road: String in st.platform_tracks:
		if not occ.has(road) or _reserved(w,road):continue
		var v: Train=w.trains[occ[road]]
		if v==t or _participant(v.id) or not v.automatic or _unavailable(engine,v):continue
		if engine.inhibited_signals.has(w.next_signal(v).get("id","")):continue
		if v.path[0].dir!=t.path[0].dir or not _contained(v,road) or v.speed>.01:continue
		if v.timetable==null or not v.timetable.at_stop or v.timetable.complete():continue
		var release: float=v.timetable.release_time()-w.clock_seconds()
		if release<0 or release>HORIZON:continue
		if Berths.roads(w,t,st,approach.edge,t.path[0].dir,[road]).is_empty():continue
		var escape:=_approach(w,v)
		if escape.is_empty() or escape.section==approach.section or escape.station.code==st.code:continue
		if _arrival_fixed(w,v,escape.station):continue
		# The vacater must leave AWAY from the incoming train's single line.
		var escape_free: Array=escape.station.platform_tracks.filter(func(r):return not occ.has(r) and not _reserved(w,r))
		var escape_roads:=Berths.roads(w,v,escape.station,escape.edge,v.path[0].dir,escape_free)
		if escape_roads.is_empty():continue
		for o: Train in w.active_trains():
			if o==t or o==v or _participant(o.id) or not o.automatic or _unavailable(engine,o):continue
			if engine.inhibited_signals.has(w.next_signal(o).get("id","")):continue
			if o.timetable==null or o.service_complete or o.path[0].dir==t.path[0].dir:continue
			var other:=_approach(w,o)
			if other.is_empty() or other.station.code!=st.code or other.section!=escape.section:continue
			if _arrival_fixed(w,o,st):continue
			var other_roads:=Berths.roads(w,o,st,other.edge,o.path[0].dir,free)
			if other_roads.is_empty():continue
			if Planner._can_berth([{id=t.id,roads=own_free},{id=o.id,roads=other_roads}]):continue
			# No optimistic chain of future vacancies: the escape berth is free NOW.
			var actors: Array=[t.id,o.id,v.id]
			if actors.any(func(id):return engine.platform_preferences.has(id)):continue
			var sections: Array=[approach.section,escape.section]
			if not _exclusive(w,sections,actors):continue
			if plans.any(func(p):return p.station==st.code or p.escape_station==st.code or p.station==escape.station.code or p.escape_station==escape.station.code or p.approach_section in sections or p.escape_section in sections):continue
			if _departure_committed(w,o,approach.section):continue
			if Prediction.arrival_seconds(w,o,st.s)>HORIZON or Prediction.arrival_seconds(w,t,st.s)>release+300:continue
			return {station=st.code,escape_station=escape.station.code,incoming=t.id,opponent=o.id,vacater=v.id,
				future_road=road,opponent_road=other_roads[0],escape_road=escape_roads[0],
				approach_section=approach.section,escape_section=escape.section,direction=t.path[0].dir,
				received=false,opponent_received=false,escaped=false,created=w.time}
	return {}

func _arrival_fixed(w,t: Train,st: Dictionary) -> bool:
	# A home route may still traverse a single-line depot access, but its
	# platform is already committed. Never promise a different arrival road.
	# Include prepared homes beyond the next automatic signal as well.
	return (t.path+_planner._committed_routes(w,t)).any(func(seg):return seg.edge in st.platform_tracks)

func _approach(w,t: Train) -> Dictionary:
	var ns: Dictionary=w.next_signal(t)
	if ns.is_empty():return {}
	for option in w.route_options(ns.id):
		for entry in option.edges:
			var section: String=w.single_line_sections.get(entry.edge,"")
			if section.is_empty():continue
			var destination: Dictionary=_planner._exit_station(w,section,entry.dir)
			if destination.is_empty():continue
			return {section=section,station=destination,edge=entry.edge}
	return {}

func _unavailable(engine,t: Train) -> bool:
	return t.service_complete or t.emergency or engine.operator_holds.has(t.id) or (t.timetable!=null and t.timetable.missed_stop)

func _reserved(w,road: String) -> bool:
	if not owner(road).is_empty():return true
	return w.signals.values().any(func(sig):return sig.route.any(func(e):return e.edge==road))

func _exclusive(w,sections: Array,actors: Array) -> bool:
	for t: Train in w.active_trains():
		if t.id not in actors and t.path.any(func(seg):return w.single_line_sections.get(seg.edge,"") in sections):return false
	for sig in w.signals.values():
		if sig.id in w.automatic_signals or not sig.route.any(func(seg):return w.single_line_sections.get(seg.edge,"") in sections):continue
		var found:=false
		for id in actors:
			if sig.owner==id or w.next_signal(w.trains[id]).get("id","")==sig.id:found=true
		if not found:return false
	return true

func _departure_committed(w,t: Train,section: String) -> bool:
	var ns: Dictionary=w.next_signal(t)
	return not ns.is_empty() and w.signals[ns.id].route.any(func(seg):return w.single_line_sections.get(seg.edge,"")==section)

func _participant(id: String) -> bool:
	return plans.any(func(p):return id in [p.incoming,p.opponent,p.vacater])

func controls_order(id: String) -> bool:
	# These three movements already have an interdependent departure order.
	# A separate priority overtake must not hold the promised platform vacater.
	return _participant(id)

static func _contained(t: Train,road: String) -> bool:
	return t.path.size()==1 and t.path[0].edge==road

func owner(road: String) -> String:
	for p in plans:
		if road==p.future_road:return p.incoming
		if road==p.opponent_road:return p.opponent
		if road==p.escape_road:return p.vacater
	return ""

func assigned(t: Train,station_code: String) -> String:
	for p in plans:
		if t.id==p.incoming and station_code==p.station and not p.received:return p.future_road
		if t.id==p.opponent and station_code==p.station and not p.opponent_received:return p.opponent_road
		if t.id==p.vacater and station_code==p.escape_station and not p.escaped:return p.escape_road
	return ""

func admission(t: Train,section: String) -> bool:
	for p in plans:
		if t.id==p.incoming and section==p.approach_section and not p.received:return true
		if t.id==p.opponent and section==p.escape_section and not p.opponent_received:return true
		if t.id==p.vacater and section==p.escape_section and not p.escaped:return true
	return false

func route_reason(t: Train,option: Dictionary) -> String:
	for entry in option.edges:
		var owner_id:=owner(entry.edge)
		if not owner_id.is_empty() and owner_id!=t.id:return "Platform "+entry.edge+" reserved for planned crossing service "+owner_id
	return ""

func advice(w,t: Train) -> String:
	for p in plans:
		if t.id==p.incoming and not p.received:
			return "Planned crossing at "+p.station+": enter "+p.future_road+" after "+w.trains[p.vacater].service_name+" ("+p.vacater+") clears; "+p.opponent+" will wait for your arrival"
	return ""

func section_reason(w,t: Train,option: Dictionary) -> String:
	for p in plans:
		for entry in option.edges:
			var section: String=w.single_line_sections.get(entry.edge,"")
			if section==p.approach_section:
				if t.id==p.incoming or (t.id==p.opponent and p.received):continue
				return "Approach reserved for "+p.incoming+" to enter "+p.future_road
			if section==p.escape_section:
				if t.id==p.opponent or t.id==p.vacater or (t.id==p.incoming and p.received):continue
				return "Escape section protected for "+p.vacater+" at "+p.station
	return route_reason(t,option)

func hold(w,t: Train) -> String:
	for p in plans:
		if t.id==p.opponent and _contained(t,p.opponent_road) and not p.received:
			return "Expect a wait at "+p.station+" until "+w.trains[p.incoming].service_name+" ("+p.incoming+") enters "+p.future_road+" after "+p.vacater+" leaves"
		if t.id==p.vacater and _contained(t,p.future_road) and not p.opponent_received:
			return "Expect a wait at "+p.station+" until "+w.trains[p.opponent].service_name+" ("+p.opponent+") clears the escape approach"
	return ""
