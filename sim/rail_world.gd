class_name RailWorld
extends RefCounted
## The whole simulation: track, switches, signals, trains. Call step(dt).
##
## Signals sit near the exit end of an edge and protect the block beyond it:
## every edge up to and including the next edge that carries a signal in the
## same direction (or up to a buffer stop).
##
## Clearing a signal locks its route: the switches in it can't be thrown and no
## other signal can clear over the same edges. The signal returns to red when a
## train passes it; each route edge is released once the train has run over it
## and left it (sectional release).

enum Aspect { RED, YELLOW, GREEN }

var graph := TrackGraph.new()
var signals := {}        # id -> {id, edge, dir, s, cleared, route: Array of {edge, switch, seen}}
var trains := {}         # id -> Train
var time := 0.0
var protection := true   # auto emergency brake on passing a red signal
var stations: Array = [] # layout data for rendering: {code, name, platforms: [Rect2 in x/z], building}

var events: Array = []   # {seq, t, kind, text, train}
var _event_seq := 0
var _signals_on := {}    # "edge|dir" -> [signal ids]


# --- building ---------------------------------------------------------------

## A signal `offset` metres before the exit end of `edge`, facing trains moving in `dir`.
func add_signal(id: String, edge: String, dir: int, offset: float = 10.0) -> void:
	var s := graph.exit_s(edge, dir) - dir * offset
	signals[id] = {id = id, edge = edge, dir = dir, s = s, cleared = false, route = []}
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
		result.edges.append({edge = nxt.edge, switch = nxt.switch})
		var here: Array = _signals_on.get(_key(nxt.edge, nxt.dir), [])
		if not here.is_empty():
			result.end_signal = here[0]
			return result
		cur = {edge = nxt.edge, dir = nxt.dir}
	return result


func aspect(sig_id: String, _depth: int = 0) -> Aspect:
	var sig: Dictionary = signals[sig_id]
	if not sig.cleared:
		return Aspect.RED
	var blk := block_ahead(sig_id)
	if blk.against != "":
		return Aspect.RED
	var occ := occupancy()
	for e in blk.edges:
		if occ.has(e.edge):
			return Aspect.RED
	if blk.end_signal == "" or _depth > 8:
		return Aspect.YELLOW
	return Aspect.YELLOW if aspect(blk.end_signal, _depth + 1) == Aspect.RED else Aspect.GREEN


## The next signal ahead of a train's head: {id, distance} or {} if none within `max_dist`.
func next_signal(train: Train, max_dist: float = 5000.0) -> Dictionary:
	var travelled := 0.0
	var cur: Dictionary = train.path[0]
	var from_s := train.head_s
	for _i in 64:
		var best := ""
		var best_d := INF
		for sid in _signals_on.get(_key(cur.edge, cur.dir), []):
			var d: float = (signals[sid].s - from_s) * cur.dir
			if d > 0.0 and d < best_d:
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


## Why a switch can't be thrown right now, or "" if it can.
func switch_lock_reason(node_id: String) -> String:
	for sig in signals.values():
		for r in sig.route:
			if r.switch == node_id:
				return "locked by route from signal " + sig.id
	for t in trains.values():
		for i in range(1, t.path.size()):
			if graph.exit_node(t.path[i].edge, t.path[i].dir) == node_id:
				return "train %s is standing over it" % t.id
	return ""


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
	var sig: Dictionary = signals[sig_id]
	if not want:
		sig.cleared = false
		# A route nobody has entered yet is released immediately.
		if sig.route.all(func(r): return not r.seen):
			sig.route = []
		return {ok = true, reason = ""}
	if sig.cleared:
		return {ok = true, reason = ""}
	if not sig.route.is_empty():
		return {ok = false, reason = "Signal %s: previous train still in the block" % sig_id}
	var blk := block_ahead(sig_id)
	if blk.against != "":
		return {ok = false, reason = "Signal %s: switch %s is set against the route" % [sig_id, blk.against]}
	var occ := occupancy()
	var mine := {}
	for e in blk.edges:
		if occ.has(e.edge):
			return {ok = false, reason = "Signal %s: block occupied by %s" % [sig_id, occ[e.edge]]}
		mine[e.edge] = true
	for other in signals.values():
		for r in other.route:
			if mine.has(r.edge):
				return {ok = false, reason = "Signal %s: conflicts with route from %s" % [sig_id, other.id]}
	sig.route = []
	for e in blk.edges:
		sig.route.append({edge = e.edge, switch = e.switch, seen = false})
	sig.cleared = true
	return {ok = true, reason = ""}


## Clear the next signal ahead of a train ("request the road").
func request_signal_ahead(train_id: String) -> Dictionary:
	var ns := next_signal(trains[train_id])
	if ns.is_empty():
		return {ok = false, reason = "No signal ahead"}
	return set_signal(ns.id, true)


## Swap cabs (train must be stopped).
func reverse_train(train_id: String) -> Dictionary:
	var t: Train = trains[train_id]
	if not t.reverse(graph):
		return {ok = false, reason = "Stop the train before changing ends"}
	return {ok = true, reason = ""}


func release_emergency(train_id: String) -> Dictionary:
	var t: Train = trains[train_id]
	if t.speed > 0.01:
		return {ok = false, reason = "Emergency brake releases only at a stand"}
	t.emergency = false
	return {ok = true, reason = ""}


# --- simulation -------------------------------------------------------------

func step(dt: float) -> void:
	time += dt
	for t in trains.values():
		_step_train(t, dt)
	_release_routes()


func _step_train(t: Train, dt: float) -> void:
	t.update_speed(dt)
	var d := t.speed * dt
	if d <= 0.0:
		return
	# Signals are far apart compared with one step's travel, so at most one is passed.
	var probe := next_signal(t, d + 1.0)
	if not probe.is_empty() and probe.distance <= d:
		_on_pass_signal(t, probe.id)
	var hit_speed := t.speed
	var res := t.advance(graph, d)
	for nxt in res.entered:
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


func _release_routes() -> void:
	var occ := occupancy()
	for sig in signals.values():
		if sig.route.is_empty():
			continue
		var keep := []
		for r in sig.route:
			if occ.has(r.edge):
				r.seen = true
				keep.append(r)
			elif not r.seen:
				keep.append(r)
			# seen and now clear: released
		sig.route = keep


func _event(kind: String, text: String, train_id: String = "") -> void:
	_event_seq += 1
	events.append({seq = _event_seq, t = time, kind = kind, text = text, train = train_id})
	if events.size() > 50:
		events.pop_front()


static func _key(edge: String, dir: int) -> String:
	return "%s|%d" % [edge, dir]
