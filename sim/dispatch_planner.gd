extends RefCounted
## Route alternatives and downstream admission. Topology is cached, occupation isn't.
const Policy := preload("res://sim/priority_dispatch.gd")
const Resources := preload("res://sim/dispatch_resources.gd")
var _section_ends := {}
var _outbound_sections := {}
var _evaluating := false
var _claim_cache := {}

func candidates(w, t: Train, signal_id: String, platform: String = "") -> Array:
	var result: Array = []
	if t.timetable == null: return result
	_evaluating=true;_claim_cache.clear()
	var stop: Dictionary = t.timetable.stop_ahead()
	var booked_station: Dictionary=Policy.station(w,stop.block)
	var flexible_terminal: bool=w.scenery.get("geographic",false) and booked_station.get("platform_details",{}).get(stop.block,{}).get("platform_width",0)>0
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
		var future = w.dispatcher().future_clearances
		var promised: String=future.assigned(t,st.get("code",""))
		var stopping: bool = not st.is_empty() and last.edge in st.get("platform_tracks", []) and Policy.station(w, stop.block).get("code", "") == st.code
		if not st.is_empty() and preload("res://sim/berth_clearance.gd").capacity(w,last.edge,stopping)<t.length:
			reason="Formation is too long to wait clear of signals and points on this road"
		if stopping:
			if st.get("platform_details", {}).get(last.edge, {}).get("platform_width", 1) <= 0: reason = "No passenger platform on this road"
			if preload("res://sim/berth_clearance.gd").capacity(w,last.edge) < t.length: reason = "Formation is too long for this road's clear platform length"
		if stopping and (flexible_terminal or t.timetable.index < t.timetable.stops.size()-1 or platform==last.edge):
			goal.block = last.edge
			goal.s = preload("res://sim/berth_clearance.gd").marker(w,t,last.edge,last.dir)
			changes_stop = true
			if not platform.is_empty() and last.edge != platform: reason = "Operator assigned " + platform
		elif not platform.is_empty() and stopping and last.edge != platform:
			reason = "Operator assigned " + platform
		if stopping and reason.is_empty():reason=preload("res://sim/berth_clearance.gd").reason(w,t,last.edge,goal.s,last.dir)
		var distance: float = w._stop_distance(last.edge, last.dir, w.graph.entry_s(last.edge, last.dir), goal, [])
		if option.edges.any(func(r): return r.edge == goal.block and r.dir == goal.direction): distance = 0.0
		if is_inf(distance): reason = "Cannot reach next call: " + stop.name
		var following_index: int=t.timetable.index+(1 if t.timetable.at_stop else 0)+1
		if stopping and following_index>=t.timetable.stops.size() and not preload("res://sim/depot_workings.gd").terminal_road_compatible(w,st,last.edge,last.dir):
			reason="Terminal platform must preserve the outgoing running line for depot clearance"
		if stopping and following_index<t.timetable.stops.size():
			var following: Dictionary=t.timetable.stops[following_index]
			if is_inf(w._stop_distance(last.edge,last.dir,w.graph.entry_s(last.edge,last.dir),following,[])):
				reason="Road cannot reach following call: "+following.name
		cost += distance * .00001
		if not preferred.is_empty() and preferred.option.destination == option.destination:
			cost -= 1000
			hold = preferred.hold
		var physical: String = w.route_reason(signal_id, option.destination)
		if not promised.is_empty() and last.edge!=promised: reason="Planned crossing platform: "+promised
		var protected: String=future.section_reason(w,t,option)
		if not protected.is_empty():reason=protected
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
	_evaluating=false;_claim_cache.clear()
	result.sort_custom(func(a,b): return a.cost < b.cost if a.cost != b.cost else a.destination < b.destination)
	return result

func admission_reason(w, t: Train, option: Dictionary) -> Dictionary:
	if not w.scenery.get("geographic", false): return {}
	# A local depot entrance leaves the corridor before its next receiving
	# station. Ordinary interlocking still protects the shared throat/approach.
	if w.depots.has(option.edges[-1].edge):
		if preload("res://sim/depot_workings.gd").active(t) and option.edges[-1].edge==t.depot.road:return {}
		return {reason="Depot road reserved for an assigned empty-stock working",blockers=[]}
	# Recheck the actual platform at the home signal. A choice made here must
	# not consume the escape road protected when entering the approach.
	var last: Dictionary=option.edges[-1]
	var arrival: Dictionary=Policy.station(w,last.edge)
	if not arrival.is_empty() and not arrival.get("through_halt",false):
		var exit_check:=_escape_capacity(w,t,arrival,last.dir,[last.edge])
		if not exit_check.is_empty():return exit_check
	for entry in option.edges:
		var section: String = w.single_line_sections.get(entry.edge, "")
		if section.is_empty() or t.path.any(func(p): return w.single_line_sections.get(p.edge, "") == section): continue
		var destination := _exit_station(w, section, entry.dir)
		if destination.is_empty(): continue
		var future = w.dispatcher().future_clearances
		if future.admission(t,section):continue
		var occupancy: Dictionary = w.occupancy()
		var blocked: Array = []
		var available: Array = []
		var approaches := {}
		for sig in w.routed_signals():
			for r in sig.route:
				if r.edge in destination.platform_tracks: approaches[r.edge] = sig.id
		for road: String in destination.platform_tracks:
			if not future.owner(road).is_empty() and future.owner(road)!=t.id:continue
			if not w.graph.allows(road, entry.dir) or preload("res://sim/berth_clearance.gd").capacity(w,road,false)<t.length: continue
			var goal := {block=road, direction=entry.dir, s=preload("res://sim/berth_clearance.gd").marker(w,t,road,entry.dir,false)}
			if is_inf(w._stop_distance(entry.edge, entry.dir, w.graph.entry_s(entry.edge, entry.dir), goal, [])): continue
			if occupancy.has(road) and occupancy[road] != t.id:
				blocked.append({train=occupancy[road], kind="receiving_road", resource=road})
			elif not approaches.has(road): available.append(road)
		var own_roads:=_receiving_roads(w,t,destination,entry.edge,entry.dir,available)
		var exit_check:=_escape_capacity(w,t,destination,entry.dir,own_roads)
		if not exit_check.is_empty():return exit_check
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
		for other: Train in w.active_trains():
			if other == t: continue
			if not future.assigned(other,destination.code).is_empty():continue # its exclusive berth is already removed from available
			if destination.platform_tracks.any(func(r): return occupancy.get(r, "") == other.id):continue
			var committed: Array=_committed_routes(w,other)
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

func _outbound_single(w,st: Dictionary,direction: int) -> String:
	var key: String=st.code+str(direction)
	if _outbound_sections.has(key):return _outbound_sections[key]
	var seen:={}
	for section: String in w.single_line_sections.values():
		if seen.has(section):continue
		seen[section]=true
		if _exit_station(w,section,-direction).get("code","")==st.code:
			_outbound_sections[key]=section
			return section
	_outbound_sections[key]=""
	return ""

func _road_owners(w,st: Dictionary) -> Dictionary:
	var result:={}
	var occupancy: Dictionary=w.occupancy()
	var future=w.dispatcher().future_clearances
	for road in st.platform_tracks:
		if occupancy.has(road):result[road]=occupancy[road]
		elif not future.owner(road).is_empty():result[road]=future.owner(road)
	for sig in w.routed_signals():
		for part in sig.route:
			if part.edge not in st.platform_tracks or result.has(part.edge):continue
			var owner: String=sig.owner
			if owner.is_empty():
				for other: Train in w.active_trains():
					var next: Dictionary=w.next_signal(other)
					if next.is_empty():continue
					var ahead: Dictionary=w.signals[next.id]
					if ahead.owner not in ["",other.id]:continue
					if next.id==sig.id or (ahead.cleared and ahead.destination==sig.id):
						owner=other.id;break
			result[part.edge]=owner
	return result

func _committed_routes(w,t: Train) -> Array:
	var next: Dictionary=w.next_signal(t)
	if next.is_empty():return []
	var signal_data: Dictionary=w.signals[next.id]
	if signal_data.owner not in ["",t.id]:return []
	var committed: Array=signal_data.route
	# Approach preparation may reserve the home while the next signal is still
	# automatic. Count its platform once for its train, never as an anonymous
	# reservation plus a second unallocated approach claim.
	if signal_data.cleared and w.signals.has(signal_data.destination):
		var prepared: Dictionary=w.signals[signal_data.destination]
		if prepared.owner in ["",t.id]:committed=committed+prepared.route
	return committed

func _station_claims(w,st: Dictionary) -> Array:
	# Alternatives are read-only. Never retain occupation across candidate calls
	# because the dispatcher may grant a route to another service between them.
	if _evaluating and _claim_cache.has(st.code):return _claim_cache[st.code]
	var owners:=_road_owners(w,st)
	var claims:=[]
	var known:={}
	for road in owners:
		var id: String=owners[road] if not str(owners[road]).is_empty() else "reserved:"+road
		if known.has(id):continue
		known[id]=true
		claims.append({id=id,roads=[road]})
	for other: Train in w.active_trains():
		if known.has(other.id):continue
		var committed: Array=_committed_routes(w,other)
		# A train already admitted into either approach owns capacity even before
		# a particular platform has been selected at its home signal.
		for segment in other.path+committed:
			var section: String=w.single_line_sections.get(segment.edge,"")
			if section.is_empty() or _exit_station(w,section,segment.dir).get("code","")!=st.code:continue
			claims.append({id=other.id,roads=_receiving_roads(w,other,st,segment.edge,segment.dir,st.platform_tracks)})
			known[other.id]=true
			break
	if _evaluating:_claim_cache[st.code]=claims
	return claims

func _escape_capacity(w,t: Train,st: Dictionary,direction: int,own_roads: Array) -> Dictionary:
	if own_roads.is_empty() or preload("res://sim/depot_workings.gd").active(t):return {}
	var future=w.dispatcher().future_clearances
	if not future.assigned(t,st.code).is_empty():return {} # exclusive, checked escape transaction
	# A terminating service clears to its local depot, not the next station.
	if t.timetable==null or str(t.timetable.stops[-1].block).get_slice("_P",0)==st.code:return {}
	var section:=_outbound_single(w,st,direction)
	if section.is_empty():return {}
	var next:=_exit_station(w,section,direction)
	if next.is_empty():return {}
	var claims:=_station_claims(w,next).filter(func(c):return c.id!=t.id)
	if claims.is_empty():return {}
	var next_roads:=_receiving_roads(w,t,next,own_roads[0],direction,next.platform_tracks)
	if next_roads.is_empty():return {} # route compatibility is handled by candidates
	var onward:={id=t.id,roads=next_roads}
	if _can_berth(claims+[onward]):return {}
	# Same-direction traffic can leave away from our receiving station. It does
	# not establish a circular dependency, even when more than one berth is busy.
	var opposing:=claims.filter(func(c):return not w.trains.has(c.id) or w.trains[c.id].path[0].dir!=direction)
	if _can_berth(opposing+[onward]):return {}
	var here:=_station_claims(w,st).filter(func(c):return c.id!=t.id)
	here.append({id=t.id,roads=own_roads})
	var blockers: Array=[]
	for claim in opposing:
		var other: Train=w.trains.get(claim.id)
		if other==null:continue
		var remaining:=opposing.filter(func(c):return c.id!=other.id)
		if not _can_berth(remaining+[onward]):continue
		var escape:=_receiving_roads(w,other,st,other.path[0].edge,-direction,st.platform_tracks)
		if _can_berth(here+[{id=other.id,roads=escape}]):return {}
		blockers.append({train=other.id,kind="exit_capacity",resource=next.code})
	if blockers.is_empty():return {} # no proved two-station opposing cycle
	return {reason="Expect a wait before %s: preserve a crossing platform for opposing services at %s" % [st.name,next.name],blockers=blockers}
