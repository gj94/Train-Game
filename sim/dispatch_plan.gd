extends RefCounted
## Optional dispatch assistant used by the live desk and traffic tests.
## It requests the same interlocked routes as manual dispatch; no safety bypass.

static func update(w: RailWorld, hold_maruthur: bool = false) -> void:
	for t in w.trains.values():
		if not t.automatic or t.service_complete or t.timetable == null:
			continue
		var ns := w.next_signal(t)
		if ns.is_empty() or ns.id in w.automatic_signals or not w.signals[ns.id].route.is_empty():
			continue
		if hold_maruthur and ns.id.begins_with("MRT-") and not ns.id in ["MRT-HE","MRT-HW"]:
			continue
		if t.timetable.at_stop and w.clock_seconds() < t.timetable.release_time():
			continue
		var stop: Dictionary = t.timetable.stop_ahead()
		var best := ""
		var distance := INF
		for option in w.route_options(ns.id):
			var last: Dictionary = option.edges[-1]
			var d := w._stop_distance(last.edge,last.dir,w.graph.entry_s(last.edge,last.dir),stop,[])
			if d < distance and w.route_reason(ns.id,option.destination) == "":
				distance = d
				best = option.destination
		if best != "":
			w.set_route(ns.id,best)
