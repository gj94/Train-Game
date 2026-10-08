extends RefCounted
## Route alternatives and downstream admission. Topology is cached, occupation isn't.
const Policy := preload("res://sim/priority_dispatch.gd")
const Resources := preload("res://sim/dispatch_resources.gd")
var _section_ends := {}

func candidates(w, t: Train, signal_id: String, platform: String = "") -> Array:
	var result: Array = []
	if t.timetable == null: return result
	var stop: Dictionary = t.timetable.stop_ahead()
	var options: Array = w.route_options(signal_id)
	var preferred: Dictionary = Policy.choose_platform(w, t, options, stop)
	for option in options:
		var last: Dictionary = option.edges[-1]
		var st: Dictionary = Policy.station(w, last.edge)
		var goal := stop.duplicate()
		var changes_stop := false
		var reason := ""
		var cost: float = option.cost * .001
		var hold := {}
		var stopping: bool = not st.is_empty() and last.edge in st.get("platform_tracks", []) and Policy.station(w, stop.block).get("code", "") == st.code
		if stopping:
			if st.get("platform_details", {}).get(last.edge, {}).get("platform_width", 1) <= 0: reason = "No passenger platform on this road"
			if w.graph.edges[last.edge].length < t.length + 20: reason = "Formation is too long for this road"
		if stopping and (t.timetable.index < t.timetable.stops.size()-1 or platform==last.edge):
			goal.block = last.edge
			goal.s = w.graph.edges[last.edge].length * .5 + last.dir * t.length * .5
			changes_stop = true
			if not platform.is_empty() and last.edge != platform: reason = "Operator assigned " + platform
		elif not platform.is_empty() and stopping and last.edge != platform:
			reason = "Operator assigned " + platform
		var distance: float = w._stop_distance(last.edge, last.dir, w.graph.entry_s(last.edge, last.dir), goal, [])
		if option.edges.any(func(r): return r.edge == goal.block and r.dir == goal.direction): distance = 0.0
		if is_inf(distance): reason = "Cannot reach next call: " + stop.name
		var following_index: int=t.timetable.index+(1 if t.timetable.at_stop else 0)+1
		if stopping and following_index<t.timetable.stops.size():
			var following: Dictionary=t.timetable.stops[following_index]
			if is_inf(w._stop_distance(last.edge,last.dir,w.graph.entry_s(last.edge,last.dir),following,[])):
				reason="Road cannot reach following call: "+following.name
		cost += distance * .00001
		if not preferred.is_empty() and preferred.option.destination == option.destination:
			cost -= 1000
			hold = preferred.hold
		var physical: String = w.route_reason(signal_id, option.destination)
		var blockers: Array = []
		if not physical.is_empty() and reason.is_empty():
			reason = physical
			blockers = Resources.blockers(w, signal_id, option)
		var admission := {}
		if reason.is_empty():
			admission = admission_reason(w, t, option)
			if not admission.is_empty():
				reason = admission.reason
				blockers = admission.get("blockers", [])
		result.append({destination=option.destination, option=option, cost=cost,
			stop=goal if changes_stop else {}, hold=hold, reason=reason, blockers=blockers,
			eligible=not is_inf(distance), available=reason.is_empty()})
	result.sort_custom(func(a,b): return a.cost < b.cost if a.cost != b.cost else a.destination < b.destination)
	return result

func admission_reason(w, t: Train, option: Dictionary) -> Dictionary:
	if not w.scenery.get("geographic", false): return {}
	for entry in option.edges:
		var section: String = w.single_line_sections.get(entry.edge, "")
		if section.is_empty() or t.path.any(func(p): return w.single_line_sections.get(p.edge, "") == section): continue
		var destination := _exit_station(w, section, entry.dir)
		if destination.is_empty(): continue
		var occupancy: Dictionary = w.occupancy()
		var blocked: Array = []
		var available: Array = []
		var approaches := {}
		for sig in w.signals.values():
			for r in sig.route:
				if r.edge in destination.platform_tracks: approaches[r.edge] = sig.id
		for road: String in destination.platform_tracks:
			if not w.graph.allows(road, entry.dir) or w.graph.edges[road].length < t.length + 20: continue
			var goal := {block=road, direction=entry.dir, s=w.graph.edges[road].length*.5+entry.dir*t.length*.5}
			if is_inf(w._stop_distance(entry.edge, entry.dir, w.graph.entry_s(entry.edge, entry.dir), goal, [])): continue
			if occupancy.has(road) and occupancy[road] != t.id:
				blocked.append({train=occupancy[road], kind="receiving_road", resource=road})
			elif not approaches.has(road): available.append(road)
		var own_roads:=_receiving_roads(w,t,destination,entry.edge,entry.dir,available)
		# Capacity means a road this particular service can use. A through main
		# without a passenger face cannot receive a booked station call.
		if own_roads.is_empty():
			return {reason="Expect a wait before %s: no free platform suitable for this service" % destination.name,blockers=blocked}
		# Avoid admitting a train into a single line whose receiving station is
		# full. It would otherwise prevent an opposing occupant from departing.
		if available.is_empty():
			return {reason="Receiving roads at %s are occupied or committed; wait before entering %s" % [destination.code, section], blockers=blocked}
		# Following trains already inside the single section need a berth first.
		var claims: Array=[{id=t.id,roads=own_roads}]
		for other: Train in w.trains.values():
			if other == t: continue
			if destination.platform_tracks.any(func(r): return occupancy.get(r, "") == other.id):continue
			var ns: Dictionary=w.next_signal(other)
			var committed: Array=w.signals[ns.id].route if not ns.is_empty() else []
			# An already committed receiving platform is excluded from available,
			# so its owner must not also consume a second berth in this count.
			if committed.any(func(p):return p.edge in destination.platform_tracks):continue
			# Include BOTH approaches to the receiving station. Opposing trains
			# can enter different single sections while competing for one platform.
			for segment in other.path+committed:
				var other_section: String=w.single_line_sections.get(segment.edge,"")
				if other_section.is_empty(): continue
				if _exit_station(w,other_section,segment.dir).get("code","")!=destination.code: continue
				var roads:=_receiving_roads(w,other,destination,segment.edge,segment.dir,available)
				claims.append({id=other.id,roads=roads})
				blocked.append({train=other.id,kind="receiving_capacity",resource=destination.code})
				break
		if not _can_berth(claims):
			return {reason="Expect a wait before %s: the remaining platforms are reserved for approaching services" % destination.name, blockers=blocked}
	return {}

func _receiving_roads(w,t: Train,st: Dictionary,edge: String,direction: int,free: Array) -> Array:
	return preload("res://sim/receiving_berths.gd").roads(w,t,st,edge,direction,free)

static func _can_berth(claims: Array) -> bool:
	# Bipartite matching: don't count a general-purpose road twice or allocate
	# the only suitable platform to a train with other usable choices.
	var assigned:={}
	for i in claims.size():
		if not _assign_berth(i,claims,assigned,{}): return false
	return true

static func _assign_berth(index: int,claims: Array,assigned: Dictionary,seen: Dictionary) -> bool:
	for road in claims[index].roads:
		if seen.has(road): continue
		seen[road]=true
		if not assigned.has(road) or _assign_berth(assigned[road],claims,assigned,seen):
			assigned[road]=index
			return true
	return false

func _exit_station(w, section: String, direction: int) -> Dictionary:
	var key := section + str(direction)
	if _section_ends.has(key): return _section_ends[key]
	var lo := INF; var hi := -INF
	for id in w.single_line_sections:
		if w.single_line_sections[id] != section: continue
		var e: Dictionary = w.graph.edges[id]
		lo = minf(lo, e.chainage_start); hi = maxf(hi, e.chainage_end)
	var best := {}; var distance := INF
	for st in w.stations:
		if st.get("through_halt", false): continue
		var d: float = st.s-hi if direction == 1 else lo-st.s
		if d >= -10 and d < distance: best = st; distance = d
	_section_ends[key] = best
	return best
