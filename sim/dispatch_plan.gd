extends RefCounted
## Optional dispatch assistant used by the live desk and traffic tests.
## It requests the same interlocked routes as manual dispatch; no safety bypass.

static func update(w: RailWorld, hold_maruthur: bool = false, manual_service: String = "") -> void:
	var priority=preload("res://sim/priority_dispatch.gd")
	priority.update(w)
	var services: Array=w.trains.values()
	services.sort_custom(func(a,b):return a.dispatch_priority>b.dispatch_priority if a.dispatch_priority!=b.dispatch_priority else a.id<b.id)
	for t in services:
		if (not t.automatic and t.id != manual_service) or t.service_complete or t.timetable == null:
			continue
		var ns := w.next_signal(t)
		if ns.is_empty() or ns.id in w.automatic_signals or not w.signals[ns.id].route.is_empty():
			continue
		if not priority.hold_reason(w,t).is_empty():continue
		if hold_maruthur and ns.id.begins_with("MRT-") and not ns.id in ["MRT-HE","MRT-HW"]:
			continue
		if t.timetable.at_stop and w.clock_seconds() < t.timetable.release_time():
			continue
		var stop: Dictionary = t.timetable.stop_ahead()
		var platforms: Dictionary=priority.choose_platform(w,t,w.route_options(ns.id),stop)
		if not platforms.is_empty():
			if w.set_route(ns.id,platforms.option.destination).ok:
				if not platforms.stop.is_empty():
					stop.block=platforms.stop.block
					stop.s=platforms.stop.s
				if not platforms.hold.is_empty():w.dispatch_holds[t.id]=platforms.hold
			continue
		var best := ""
		var distance := INF
		for option in w.route_options(ns.id):
			var last: Dictionary = option.edges[-1]
			var d := w._stop_distance(last.edge,last.dir,w.graph.entry_s(last.edge,last.dir),stop,[])
			# An unsignalled halt can lie INSIDE a reserved section. The train
			# stops there while retaining its road to the next station signal.
			if option.edges.any(func(r): return r.edge==stop.block and r.dir==stop.direction): d=0.0
			if d < distance and w.route_reason(ns.id,option.destination) == "":
				distance = d
				best = option.destination
		if best != "":
			w.set_route(ns.id,best)
	priority.refresh_notices(w)
