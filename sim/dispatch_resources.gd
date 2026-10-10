extends RefCounted
## Structured resource diagnostics for the desk and wait-for graph.
## RailWorld.route_reason/set_route remains the authoritative interlocking.

static func blockers(w, signal_id: String, option: Dictionary) -> Array:
	var result: Array = []
	var occupancy: Dictionary = w.occupancy()
	var seen := {}
	for entry in option.edges:
		if occupancy.has(entry.edge):
			_add(result, seen, occupancy[entry.edge], "occupied", entry.edge)
		var section: String = w.single_line_sections.get(entry.edge, "")
		for t: Train in w.active_trains():
			if not section.is_empty() and t.path.any(func(p): return w.single_line_sections.get(p.edge, "") == section and p.dir != entry.dir):
				_add(result, seen, t.id, "single_line", section)
			if entry.switch != "" and w._train_near_switch(t, entry.switch):
				if not w._train_waiting_before_point(t,entry.switch,signal_id):
					_add(result, seen, t.id, "point_clearance", entry.switch)
		for sig in w.conflicting_signals(entry,signal_id):
			var owner: String = sig.owner
			if owner.is_empty():
				var distance := INF
				for t: Train in w.active_trains():
					var ns: Dictionary = w.next_signal(t)
					if not ns.is_empty() and ns.id == sig.id and ns.distance < distance:
						owner = t.id; distance = ns.distance
			_add(result, seen, owner, "reserved", sig.id)
	return result

static func _add(rows: Array, seen: Dictionary, train: String, kind: String, resource: String) -> void:
	var key := train + ":" + kind + ":" + resource
	if seen.has(key): return
	seen[key] = true
	rows.append({train=train, kind=kind, resource=resource})

static func cycles(dependencies: Dictionary) -> Array:
	# Small service graph: deterministic reachability components, including only
	# services whose every possible road is blocked (not merely one busy road).
	var result: Array = []
	var consumed := {}
	var ids: Array = dependencies.keys().map(func(id):return str(id)); ids.sort()
	for id in ids:
		if consumed.has(id): continue
		var reachable := _reachable(dependencies, id)
		var group: Array = []
		for other in ids:
			if reachable.has(other) and _reachable(dependencies, other).has(id): group.append(other)
		if group.size() < 2: continue
		for other in group: consumed[other] = true
		result.append(group)
	return result

static func _reachable(edges: Dictionary, start: String) -> Dictionary:
	var seen := {}
	var pending: Array = edges.get(start, []).duplicate()
	while not pending.is_empty():
		var id: String = pending.pop_back()
		if seen.has(id): continue
		seen[id] = true
		pending.append_array(edges.get(id, []))
	return seen
