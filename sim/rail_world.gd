class_name RailWorld
extends RefCounted
## The whole simulation: track, switches, signals, trains. Call step(dt).
##
## Signals sit near the exit end of an edge and protect the block beyond it:
## every edge up to and including the next edge that carries a signal in the
## same direction (or up to a buffer stop).
##
## set_route chooses the next signal / buffer and aligns and locks its points.
## No other route may reserve the same block or throat. The signal returns to
## red on passage. Points release after tail clearance; occupancy continues to
## protect berths after their entrance route releases. No scene-tree dependencies.

enum Aspect { RED, YELLOW, GREEN }
const Clock := preload("res://sim/world_clock.gd")
const Timetable := preload("res://sim/timetable.gd")

var graph := TrackGraph.new()
var signals := {}        # route sections are immutable paths, independent of later point settings
var trains := {}         # id -> Train
var time := 0.0
var clock_start := 8.0 * 3600.0 # absolute world seconds at scenario start, day 1
var protection := true   # emergency intervention before passing a red signal
var stations: Array = [] # layout data for rendering: {code, name, platforms: [Rect2 in x/z], building}
var automatic_signals: Array[String] = [] # fixed plain-line block signals; never station routes
var scenery: Dictionary = {} # geographic/layout metadata consumed by rendering
var single_line_sections: Dictionary = {} # edge -> direction-locked section between passing places
var dispatch_notices: Dictionary = {} # advisory text; never grants or withholds authority
var dispatch_holds: Dictionary = {}
var dispatch_history: Array = []

var events: Array = []   # {seq, t (elapsed), clock (absolute), kind, text, train}
var _event_seq := 0
var _signals_on := {}    # "edge|dir" -> [signal ids]
var _next_auto_update := 0.0
var _route_distances
var _route_options_cache := {}
var _route_topology_size := ""
var _within_step := false
var _step_route_directions := {}
var _automatic_set := {}
var _automatic_set_size := -1
var _auto_direction_snapshot: Dictionary = {}
var _updating_automatic := false


# --- building ---------------------------------------------------------------

## A signal `offset` metres before the exit end of `edge`, facing trains moving in `dir`.
func add_signal(id: String, edge: String, dir: int, offset: float = 10.0) -> void:
	_route_options_cache.clear()
	var s := graph.exit_s(edge, dir) - dir * offset
	signals[id] = {id = id, edge = edge, dir = dir, s = s, cleared = false, route = [],
		destination = "", owner = "", cancel_pending = false}
	var key := _key(edge, dir)
	if not _signals_on.has(key):
		_signals_on[key] = []
	_signals_on[key].append(id)


## Puts `train` with its head at `s` on `edge`, facing `dir`; the body trails
## back along the track following current switch settings.
func place_train(train: Train, edge: String, s: float, dir: int) -> void:
	train.path = [{edge = edge, dir = dir}]
	train.head_s = s
	var covered := absf(s - graph.entry_s(edge, dir))
	var cur := {edge = edge, dir = dir}
	while covered < train.length:
		var back := graph.next(cur.edge, -cur.dir)
		if back.is_empty():
			break
		cur = {edge = back.edge, dir = -back.dir}
		train.path.append(cur)
		covered += graph.edges[cur.edge].length
	train._trim_tail(graph)
	trains[train.id] = train


# --- queries ----------------------------------------------------------------

func clock_seconds() -> float:
	return clock_start + time

func clock_text() -> String:
	return Clock.format_time(clock_seconds())

func clock_day() -> int:
	return Clock.day(clock_seconds())

## Atomic assignment: invalid data never replaces an existing working.
func set_timetable(train_id: String, definition: Dictionary) -> Dictionary:
	if not trains.has(train_id):
		return {ok = false, reason = "Unknown train " + train_id}
	var train: Train = trains[train_id]
	if train.speed > 0.01:
		return {ok = false, reason = "Stop the train before assigning a timetable"}
	var schedule := Timetable.new()
	var result := schedule.configure(definition, self, train)
	if not result.ok:
		return result
	train.timetable = schedule
	train.destination = schedule.stops[-1].name
	train.service_complete = false
	return result

## edge id -> train id, for every occupied edge.
func occupancy() -> Dictionary:
	var occ := {}
	for t in trains.values():
		for seg in t.path:
			occ[seg.edge] = t.id
	return occ


## Edges protected by a signal, following current switch settings.
## Returns {edges: [{edge, switch}], end_signal ("" at a buffer stop), against: switch id or ""}.
func block_ahead(sig_id: String) -> Dictionary:
	var sig: Dictionary = signals[sig_id]
	var result := {edges = [], end_signal = "", against = ""}
	var cur := {edge = sig.edge, dir = sig.dir}
	for _i in 64:
		var nxt := graph.next(cur.edge, cur.dir)
		if nxt.is_empty():
			return result
		if nxt.against and result.against == "":
			result.against = nxt.switch
		result.edges.append({edge = nxt.edge, dir = nxt.dir, switch = nxt.switch})
		var here: Array = _signals_on.get(_key(nxt.edge, nxt.dir), [])
		if not here.is_empty():
			result.end_signal = here[0]
			return result
		cur = {edge = nxt.edge, dir = nxt.dir}
	return result


func aspect(sig_id: String, _depth: int = 0) -> Aspect:
	var sig: Dictionary = signals[sig_id]
	if not sig.cleared or sig.route.is_empty() or sig.owner != "":
		return Aspect.RED
	var occ := occupancy()
	for e in sig.route:
		if occ.has(e.edge):
			return Aspect.RED
		if e.switch != "" and graph.switches[e.switch].reversed != e.reversed:
			return Aspect.RED
	if not signals.has(sig.destination) or _depth > 8:
		return Aspect.YELLOW
	return Aspect.YELLOW if aspect(sig.destination, _depth + 1) == Aspect.RED else Aspect.GREEN


## The next signal ahead of a train's head: {id, distance} or {} if none within `max_dist`.
func next_signal(train: Train, max_dist: float = 5000.0) -> Dictionary:
	if scenery.get("geographic",false) and max_dist==5000.0: max_dist=25000.0
	var travelled := 0.0
	var cur: Dictionary = train.path[0]
	var from_s := train.head_s
	for _i in 64:
		var best := ""
		var best_d := INF
		for sid in _signals_on.get(_key(cur.edge, cur.dir), []):
			var d: float = (signals[sid].s - from_s) * cur.dir
			if d >= 0.0 and d < best_d and travelled + d <= max_dist:
				best = sid
				best_d = d
		if best != "":
			return {id = best, distance = travelled + best_d}
		travelled += absf(graph.exit_s(cur.edge, cur.dir) - from_s)
		if travelled > max_dist:
			return {}
		var nxt := graph.next(cur.edge, cur.dir)
		if nxt.is_empty():
			return {}
		cur = {edge = nxt.edge, dir = nxt.dir}
		from_s = graph.entry_s(cur.edge, cur.dir)
	return {}


## Distance from a train's head to the buffer stop or the end of what it can
## see (max_dist), following current switches.
func distance_to_buffer(train: Train, max_dist: float = 5000.0) -> float:
	var cur: Dictionary = train.path[0]
	var d := absf(graph.exit_s(cur.edge, cur.dir) - train.head_s)
	while d < max_dist:
		var nxt := graph.next(cur.edge, cur.dir)
		if nxt.is_empty():
			return d
		cur = {edge = nxt.edge, dir = nxt.dir}
		d += graph.edges[cur.edge].length
	return INF


## Lowest speed limit over the edges the train occupies (m/s).
func speed_limit_for(train: Train) -> float:
	var lim := INF
	for seg in train.path:
		lim = minf(lim, graph.edges[seg.edge].speed_limit)
	return lim


## Track curvature (1 / radius, in 1/m) under the leading end of a train,
## measured over the `span` metres behind the head. 0 on straight track.
func curvature_at(train: Train, span: float = 10.0) -> float:
	var a := train.locate_behind(graph, 0.0)
	var b := train.locate_behind(graph, minf(span, train.length))
	var ta := graph.tangent(a.edge, a.s, a.dir)
	var tb := graph.tangent(b.edge, b.s, b.dir)
	var dist := minf(span, train.length)
	return 0.0 if dist <= 0.0 else ta.angle_to(tb) / dist


## Why a switch can't be thrown right now, or "" if it can.
func switch_lock_reason(node_id: String) -> String:
	for sig in signals.values():
		for r in sig.route:
			if r.switch == node_id:
				return "locked by route from signal " + sig.id
	for t in trains.values():
		if _train_near_switch(t, node_id):
			return "train %s occupies the point clearance zone" % t.id
	return ""


## A berth may be occupied while the throat behind its tail is free.
## Station turnouts have long clearance zones; small test points use 12 m.
func _train_near_switch(t: Train, node_id: String) -> bool:
	var remaining := t.length
	for i in t.path.size():
		var seg: Dictionary = t.path[i]
		var edge: Dictionary = graph.edges[seg.edge]
		var start: float = t.head_s if i == 0 else graph.exit_s(seg.edge, seg.dir)
		var covered := minf(remaining, t._available_behind(graph, i))
		var end: float = start - seg.dir * covered
		var zone: float = graph.switches[node_id].clearance
		if (edge.a == node_id and minf(start, end) < zone) or (edge.b == node_id and maxf(start, end) > edge.length - zone):
			return true
		remaining -= covered
	return false


# --- controls ---------------------------------------------------------------

## Returns {ok, reason}.
func throw_switch(node_id: String) -> Dictionary:
	if not graph.switches.has(node_id):
		return {ok = false, reason = "no switch " + node_id}
	var why := switch_lock_reason(node_id)
	if why != "":
		return {ok = false, reason = "Switch %s %s" % [node_id, why]}
	var sw: Dictionary = graph.switches[node_id]
	sw.reversed = not sw.reversed
	return {ok = true, reason = ""}


## Clear (want = true) or put back (want = false) a signal. Returns {ok, reason}.
func set_signal(sig_id: String, want: bool) -> Dictionary:
	if not signals.has(sig_id):
		return {ok = false, reason = "Unknown signal " + sig_id}
	var sig: Dictionary = signals[sig_id]
	if not want:
		sig.cleared = false
		if sig.owner == "" and not _approach_locked(sig_id):
			sig.route = []
		else:
			sig.cancel_pending = true
		return {ok = true, reason = ""}
	if sig.cleared:
		return {ok = true, reason = ""}
	var blk := block_ahead(sig_id)
	if blk.against != "":
		return {ok = false, reason = "Signal %s: switch %s is set against the route" % [sig_id, blk.against]}
	# Compatibility shortcut: an explicit route following the current points.
	for option in route_options(sig_id):
		var aligned := true
		for e in option.edges:
			if e.switch != "" and graph.switches[e.switch].reversed != e.reversed:
				aligned = false
		if aligned:
			return set_route(sig_id, option.destination)
	return {ok = false, reason = "No route available"}


## Enumerate routes from one signal to the NEXT signal or buffer, with all
## turnout choices. This is a topology query: it never moves points.
func route_options(sig_id: String) -> Array:
	if not signals.has(sig_id):
		return []
	# Geographic layouts are immutable once assembled. Occupancy and point
	# settings are deliberately absent: this cache stores possible paths only.
	if scenery.get("geographic",false):
		var topology := "%d:%d:%d" % [graph.edges.size(),graph.switches.size(),signals.size()]
		if topology != _route_topology_size:
			_route_options_cache.clear()
			_route_topology_size=topology
		if _route_options_cache.has(sig_id): return _route_options_cache[sig_id]
	var sig: Dictionary = signals[sig_id]
	var options: Array = []
	_walk_routes(sig.edge, sig.dir, [], [sig.edge], options)
	# A crossover ladder can reach the same berth by several paths. Present
	# one stable, shortest route per exit instead of silently choosing the last
	# enumerated zigzag while the UI displays a different route.
	var unique := {}
	for option in options:
		var cost := 0.0
		for r in option.edges:
			cost += graph.edges[r.edge].length + (50.0 if r.reversed else 0.0)
		option.cost = cost
		if not unique.has(option.destination) or cost < unique[option.destination].cost:
			unique[option.destination] = option
	var result: Array=unique.values()
	if scenery.get("geographic",false): _route_options_cache[sig_id]=result
	return result


func _walk_routes(edge_id: String, dir: int, path: Array, visited: Array, options: Array) -> void:
	if visited.size() > 64:
		return
	var node := graph.exit_node(edge_id, dir)
	var exits: Array = []
	if graph.switches.has(node):
		var sw: Dictionary = graph.switches[node]
		exits = [sw.normal, sw.reverse] if edge_id == sw.trunk else [sw.trunk]
	else:
		for e in graph.nodes[node].edges:
			if e != edge_id:
				exits.append(e)
	if exits.is_empty() and not path.is_empty():
		options.append({destination = "BUFFER:" + node, edges = path})
	for e in exits:
		if e in visited:
			continue
		var travel := 1 if graph.edges[e].a == node else -1
		if not graph.allows(e, travel):
			continue
		var switch_id := node if graph.switches.has(node) else ""
		var reversed := false
		if switch_id != "":
			var sw: Dictionary = graph.switches[node]
			reversed = e == sw.reverse or edge_id == sw.reverse
		var extended := path.duplicate(true)
		extended.append({edge = e, dir = travel, switch = switch_id, reversed = reversed, seen = false})
		var here: Array = _signals_on.get(_key(e, travel), [])
		if not here.is_empty():
			options.append({destination = here[0], edges = extended})
		else:
			_walk_routes(e, travel, extended, visited + [e], options)


## Validate every resource before making any change. Point conflicts matter
## even when two routes protect different track blocks.
func route_reason(sig_id: String, destination: String) -> String:
	if not signals.has(sig_id):
		return "Unknown entrance signal"
	var sig: Dictionary = signals[sig_id]
	if not sig.route.is_empty():
		return "Route already set / awaiting tail clearance from " + sig_id
	var candidate := {}
	for option in route_options(sig_id):
		if option.destination == destination:
			candidate = option
	if candidate.is_empty():
		return "No route to " + destination
	var has_single: bool=candidate.edges.any(func(e):return single_line_sections.has(e.edge))
	var direction_locks:=(_auto_direction_snapshot if _updating_automatic else single_line_directions()) if has_single else {}
	for entry in candidate.edges:
		var section: String=single_line_sections.get(entry.edge,"")
		if not section.is_empty() and direction_locks.has(section) and direction_locks[section]!=entry.dir:
			return "Single line "+section+" is locked for opposing traffic"
	var occ := occupancy()
	for e in candidate.edges:
		if occ.has(e.edge):
			return "Block %s occupied by %s" % [e.edge, occ[e.edge]]
		for other in signals.values():
			for r in other.route:
				if r.edge == e.edge or (e.switch != "" and e.switch == r.switch):
					return "Conflicts with route from " + other.id
		if e.switch != "":
			for t in trains.values():
				if not _train_near_switch(t, e.switch):
					continue
				# The train waiting at this entrance may occupy its approach.
				var ns := next_signal(t)
				if ns.is_empty() or ns.id != sig_id or t.path.size() > 1:
					return "Point clearance zone occupied by " + t.id
	return ""


func set_route(sig_id: String, destination: String) -> Dictionary:
	var reason := route_reason(sig_id, destination)
	if reason != "":
		return {ok = false, reason = reason}
	var sig: Dictionary = signals[sig_id]
	for option in route_options(sig_id):
		if option.destination == destination:
			sig.route = option.edges.duplicate(true)
	for e in sig.route:
		if e.switch != "":
			graph.switches[e.switch].reversed = e.reversed
	sig.destination = destination
	sig.owner = ""
	sig.cancel_pending = false
	sig.cleared = true
	return {ok = true, reason = ""}


func _approach_locked(sig_id: String) -> bool:
	for t in trains.values():
		var ns := next_signal(t)
		if not ns.is_empty() and ns.id == sig_id and t.speed > 0.1 and ns.distance < t.braking_distance() * 1.3 + 25.0:
			return true
	return false


## Clear the next signal ahead of a train ("request the road").
func request_signal_ahead(train_id: String) -> Dictionary:
	var ns := next_signal(trains[train_id])
	if ns.is_empty():
		return {ok = false, reason = "No signal ahead"}
	return set_signal(ns.id, true)


## Swap cabs (train must be stopped).
func reverse_train(train_id: String) -> Dictionary:
	var t: Train = trains[train_id]
	if not t.can_change_ends:
		return {ok = false, reason = "This LHB rake needs a locomotive run-round. Restart the service for another trip."}
	if t.timetable != null and not t.timetable.complete():
		return {ok = false, reason = "Finish the current timetable before changing ends"}
	for sig in signals.values():
		if sig.owner == train_id and sig.route.any(func(r): return not r.seen):
			return {ok = false, reason = "Complete the movement into the reserved block before changing ends"}
	if not t.reverse(graph):
		return {ok = false, reason = "Stop the train before changing ends"}
	t.service_complete = false
	t.timetable = null # completed working stays complete; return movement is unscheduled
	return {ok = true, reason = ""}


func release_emergency(train_id: String) -> Dictionary:
	var t: Train = trains[train_id]
	if t.speed > 0.01:
		return {ok = false, reason = "Emergency brake releases only at a stand"}
	t.emergency = false
	return {ok = true, reason = ""}


# --- simulation -------------------------------------------------------------

func step(dt: float) -> void:
	# Bound movement even at accelerated time / long frames. Each train sees
	# the preceding train's updated occupancy before it is allowed to move.
	var remaining := maxf(dt, 0.0)
	while remaining > 0.000001:
		var slice := minf(remaining, 0.05)
		time += slice
		_update_automatic_blocks()
		_step_route_directions=_reservation_directions()
		_within_step=true
		for t in trains.values():
			if t.automatic:
				_drive_automatic(t)
			var previous_distance: float = t.odometer
			_step_train(t, slice)
			if t.timetable != null:
				t.timetable.observe(t, clock_seconds(), t.odometer > previous_distance + 0.000001, _arrival_tolerance(t))
				t.service_complete = t.timetable.complete()
				if t.service_complete:
					t.status = "Arrived at " + t.destination
			elif t.destination != "" and t.speed < 0.01 and distance_to_buffer(t, 15.0) < 12.0:
				t.service_complete = true
				t.status = "Arrived at " + t.destination
		_release_routes()
		_within_step=false
		_step_route_directions.clear()
		remaining -= slice


func _arrival_tolerance(t: Train) -> float:
	if t.automatic or not scenery.get("geographic",false) or t.timetable==null:return 1.1
	var stop: Dictionary=t.timetable.stops[t.timetable.index]
	# The full formation must fit the platform, but a human need not hit a
	# one-metre AI target. Leave five metres at each usable platform end.
	for st in stations:
		if stop.block not in st.platform_tracks:continue
		var length: float=graph.edges[stop.block].length
		var half:=minf(320,length*.5-200)
		return maxf(1.1,half-t.length*.5-5)
	return 1.1

func _update_automatic_blocks() -> void:
	if time < _next_auto_update:
		return
	_next_auto_update = time + .5
	var directions:=single_line_directions()
	_auto_direction_snapshot=directions
	_updating_automatic=true
	# Unoccupied automatic routes must not hold a single-line direction forever.
	for sid in automatic_signals:
		var sig: Dictionary=signals[sid]
		var section: String=single_line_sections.get(sig.edge,"")
		if not section.is_empty() and not directions.has(section) and sig.owner.is_empty():
			sig.route=[];sig.cleared=false
	for sid in automatic_signals:
		var section: String=single_line_sections.get(signals[sid].edge,"")
		if not section.is_empty() and directions.get(section,0)!=signals[sid].dir:continue
		if not signals[sid].route.is_empty():
			continue
		var options := route_options(sid)
		if options.size() != 1 or options[0].edges.any(func(r): return r.switch != ""):
			continue # automatic block control is never allowed to move a point
		set_route(sid, options[0].destination)
	_updating_automatic=false
	_auto_direction_snapshot={}

func single_line_directions() -> Dictionary:
	var result:={}
	if single_line_sections.is_empty():return result
	if _automatic_set_size!=automatic_signals.size():
		_automatic_set={}
		for sid in automatic_signals:_automatic_set[sid]=true
		_automatic_set_size=automatic_signals.size()
	for t in trains.values():
		for seg in t.path:
			if single_line_sections.has(seg.edge):result[single_line_sections[seg.edge]]=seg.dir
	for sig in signals.values():
		if _automatic_set.has(sig.id):continue
		for entry in sig.route:
			if single_line_sections.has(entry.edge):result[single_line_sections[entry.edge]]=entry.dir
	return result


## Braking curves include signals, buffers, occupied blocks and lower speed
## limits ahead. AI never requests or changes a route by itself.
func _drive_automatic(t: Train) -> void:
	if t.emergency:
		t.status = "Emergency — release at stand"
		t.controller = -1.0
		return
	var scheduled_stop := {}
	if t.timetable != null:
		var tt = t.timetable
		if tt.complete():
			t.status = "Timetable complete"
			t.controller = -1.0
			return
		if tt.at_stop:
			if clock_seconds() + 0.000001 < tt.release_time():
				t.status = ("Departs " if tt.index == 0 else "Dwell until ") + Clock.format_time(tt.release_time())
				t.controller = -1.0
				return
			var scenario_hold: String=preload("res://sim/priority_dispatch.gd").hold_reason(self,t)
			if not scenario_hold.is_empty():
				t.status=scenario_hold
				t.controller=-1.0
				return
			var starter := next_signal(t)
			var inside_reserved_section:=false
			if _signals_on.get(_key(t.path[0].edge,t.path[0].dir),[]).is_empty():
				for signal_data in signals.values():
					if signal_data.owner==t.id and signal_data.route.any(func(r): return r.edge==t.path[0].edge and r.dir==t.path[0].dir):
						inside_reserved_section=true
			if not inside_reserved_section and (starter.is_empty() or aspect(starter.id) == Aspect.RED):
				t.status = "Awaiting route" if starter.is_empty() else "Waiting for " + starter.id
				t.controller = -1.0
				return
		scheduled_stop = tt.stop_ahead()
		if tt.missed_stop:
			t.status = "Missed stop: " + scheduled_stop.block
			t.controller = -1.0
			return
	var buffer := distance_to_buffer(t)
	var stop_at := buffer - 7.0
	var ns := next_signal(t)
	t.status = "Running to " + t.destination
	stop_at = minf(stop_at, _distance_to_red(t) - 6.0)
	if not ns.is_empty() and aspect(ns.id) == Aspect.RED:
		stop_at = minf(stop_at, ns.distance - 6.0)
		if t.speed < 0.1:
			t.status = "Waiting for " + ns.id
	stop_at = minf(stop_at, _distance_to_obstruction(t) - 3.0)
	if not scheduled_stop.is_empty():
		var to_stop := _stop_distance(t.path[0].edge, t.path[0].dir, t.head_s, scheduled_stop, [])
		if is_inf(to_stop):
			t.controller = -1.0
			t.status = "Cannot reach stop: " + scheduled_stop.block
			return
		stop_at = minf(stop_at, to_stop)
		# A cleared route to the wrong platform is still wrong for this
		# working. Stop at its entrance; never move points on the AI's behalf.
		if not ns.is_empty() and signals[ns.id].cleared:
			var route: Array = signals[ns.id].route
			if not route.is_empty():
				var last: Dictionary = route[-1]
				var contains_stop := route.any(func(r): return r.edge == scheduled_stop.block and r.dir == scheduled_stop.direction)
				if not contains_stop and is_inf(_stop_distance(last.edge, last.dir, graph.entry_s(last.edge, last.dir), scheduled_stop, [])):
					stop_at = minf(stop_at, ns.distance - 6.0)
					t.status = "Route must serve " + scheduled_stop.block
	var target := minf(speed_limit_for(t) - 0.4, sqrt(maxf(0.0, 2.0 * t.service_decel * 0.65 * stop_at)))
	var cur: Dictionary = t.path[0]
	var distance := absf(graph.exit_s(cur.edge, cur.dir) - t.head_s)
	for i in 20:
		var nxt := graph.next(cur.edge, cur.dir)
		if nxt.is_empty() or distance > 1000.0:
			break
		var limit: float = graph.edges[nxt.edge].speed_limit - 0.4
		target = minf(target, sqrt(maxf(0.0, limit * limit + 2.0 * t.service_decel * 0.65 * maxf(0.0, distance - 12.0))))
		cur = nxt
		distance += graph.edges[cur.edge].length
	if stop_at < 0.7 or t.speed > target + 0.15:
		t.controller = -1.0
	elif t.speed < target - 0.5:
		t.controller = clampf((target - t.speed) * 0.7, 0.0, 1.0)
	else:
		t.controller = 0.0
	if t.service_complete:
		t.controller = -1.0


## Distance via track topology, allowing points beyond a red signal to be
## set later. Actual movement still follows only dispatcher-set points.
func _stop_distance(edge: String, dir: int, from_s: float, stop: Dictionary, visited: Array) -> float:
	if _route_distances == null: _route_distances = preload("res://sim/route_distances.gd").new(graph)
	return _route_distances.distance(edge,dir,from_s,stop)


func _distance_to_red(t: Train) -> float:
	var cur: Dictionary = t.path[0]
	var from_s := t.head_s
	var distance := 0.0
	for i in 64:
		for sid in _signals_on.get(_key(cur.edge, cur.dir), []):
			var ahead: float = (signals[sid].s - from_s) * cur.dir
			if ahead >= 0 and aspect(sid) == Aspect.RED:
				return distance + ahead
		distance += absf(graph.exit_s(cur.edge, cur.dir) - from_s)
		var nxt := graph.next(cur.edge, cur.dir)
		if nxt.is_empty() or distance > 5000:
			return INF
		cur = nxt
		from_s = graph.entry_s(cur.edge, cur.dir)
	return INF


## A hard block boundary prevents collisions even with driver protection off.
## This also protects against routes revoked after a signal was passed.
func _reservation_directions() -> Dictionary:
	var directions := {}
	for signal_data in signals.values():
		for road in signal_data.route:
			directions[road.edge]=int(directions.get(road.edge,0)) | (1 if road.dir>0 else 2)
	return directions


func _distance_to_obstruction(t: Train) -> float:
	# Route paths are constant within a physics slice; occupancy is not. Keep
	# each earlier train's movement visible to the trains updated after it.
	var occupied := occupancy()
	var directions: Dictionary=_step_route_directions if _within_step else _reservation_directions()
	var cur: Dictionary = t.path[0]
	var distance := absf(graph.exit_s(cur.edge, cur.dir) - t.head_s)
	for i in 64:
		var nxt := graph.next(cur.edge, cur.dir)
		if nxt.is_empty():
			return INF
		if occupied.has(nxt.edge) and occupied[nxt.edge]!=t.id:
			return distance
		if nxt.against:
			return distance
		if int(directions.get(nxt.edge,0)) & (2 if nxt.dir>0 else 1):
			return distance
		cur = nxt
		distance += graph.edges[cur.edge].length
	return INF


func _step_train(t: Train, dt: float) -> void:
	t.update_speed(dt)
	var d := t.speed * dt
	if d <= 0.0:
		return
	var obstruction := _distance_to_obstruction(t)
	if d >= obstruction - 0.1:
		d = maxf(0.0, obstruction - 0.1)
		if not t.emergency:
			_event("safety", "Train %s stopped at occupied or conflicting block boundary" % t.id, t.id)
		t.emergency = true
		t.speed = 0.0
	var probe := next_signal(t, d + 1.0)
	if not probe.is_empty() and probe.distance <= d:
		if aspect(probe.id) == Aspect.RED and protection:
			if not t.emergency:
				_event("spad", "Train %s attempted signal %s at danger — protection stop" % [t.id, probe.id], t.id)
			t.emergency = true
			t.speed = 0.0
			d = maxf(0.0, probe.distance - 0.05)
		else:
			_on_pass_signal(t, probe.id)
	var hit_speed := t.speed
	var res := t.advance(graph, d)
	for nxt in res.entered:
		for sig in signals.values():
			if sig.owner == t.id:
				for r in sig.route:
					if r.edge == nxt.edge:
						r.seen = true
		if nxt.against:
			graph.switches[nxt.switch].reversed = not graph.switches[nxt.switch].reversed
			_event("warning", "Train %s ran through switch %s set against it" % [t.id, nxt.switch], t.id)
	if res.get("buffer", false) and hit_speed > 1.5:
		_event("warning", "Train %s hit the buffer stop at %d km/h" % [t.id, roundi(hit_speed * 3.6)], t.id)


func _on_pass_signal(t: Train, sig_id: String) -> void:
	var sig: Dictionary = signals[sig_id]
	if aspect(sig_id) == Aspect.RED:
		_event("spad", "Train %s passed signal %s at danger" % [t.id, sig_id], t.id)
		if protection:
			t.emergency = true
	sig.cleared = false  # the route stays locked until the train has cleared it
	if not sig.route.is_empty():
		sig.owner = t.id


func _release_routes() -> void:
	var occ := occupancy()
	for sig in signals.values():
		if sig.route.is_empty():
			continue
		if sig.cancel_pending and sig.owner == "" and not _approach_locked(sig.id):
			sig.route = []
			sig.cancel_pending = false
			continue
		var keep := []
		for r in sig.route:
			if sig.owner != "" and occ.get(r.edge, "") == sig.owner:
				r.seen = true
			# Release points only after the owning train's tail clears the
			# turnout, while keeping the occupied berth reserved.
			if r.seen and r.switch != "" and not _train_near_switch(trains[sig.owner], r.switch):
				r.switch = ""
			if occ.has(r.edge) or not r.seen:
				keep.append(r)
			# seen and now clear: released
		# Once every section has been traversed and the entrance/points are
		# clear, this entrance may admit another train to a DIFFERENT berth.
		# Occupancy continues to protect the first train's entire body. Keeping
		# the entrance attached to that berth prevented multi-platform arrivals.
		if sig.owner != "" and occ.get(sig.edge, "") != sig.owner and keep.all(func(r): return r.seen and r.switch == ""):
			keep.clear()
		sig.route = keep
		if keep.is_empty():
			sig.owner = ""
			sig.destination = ""
			sig.cancel_pending = false


func _event(kind: String, text: String, train_id: String = "") -> void:
	_event_seq += 1
	events.append({seq = _event_seq, t = time, clock = clock_seconds(), kind = kind, text = text, train = train_id})
	if events.size() > 50:
		events.pop_front()


static func _key(edge: String, dir: int) -> String:
	return "%s|%d" % [edge, dir]
