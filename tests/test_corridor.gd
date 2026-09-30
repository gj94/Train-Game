extends RefCounted

const Line := preload("res://sim/layouts/southern_corridor.gd")
const Dispatch := preload("res://sim/dispatch_plan.gd")

func test_double_track_and_four_platforms():
	var w := Line.build()
	if w.graph.nodes["KDP_B4"].pos.x < 21000:
		return "Route was not expanded"
	for st in w.stations:
		if st.platform_tracks.size() != 4 or st.platforms.size() != 2:
			return "Each station needs four distinct faces on two islands"
		for road in st.platform_tracks:
			if not w.graph.edges.has(road):
				return "Missing platform road"
	for section in ["W", "E"]:
		for i in 4:
			var east: Dictionary = w.graph.edges["%s_E%d" % [section, i]]
			var west: Dictionary = w.graph.edges["%s_W%d" % [section, i]]
			if east.allowed_dir != 1 or west.allowed_dir != -1:
				return "Directional running lines missing"
			if not is_equal_approx(east.points[0].distance_to(west.points[0]), 6.0):
				return "Main tracks must maintain six metre centres"
	return true

func test_independent_arrivals_and_conflicting_departures():
	var w := Line.build()
	if not w.set_route("MRT-HE", "MRT-E1").ok or not w.set_route("MRT-HW", "MRT-W3").ok:
		return "Independent opposite-direction arrivals should coexist"
	if w.set_route("MRT-HE", "MRT-E2").ok:
		return "One entrance cannot simultaneously feed two platforms"
	w = Line.build()
	if not w.set_route("MRT-E1", "E-AE1").ok:
		return "First departure not available"
	return not w.set_route("MRT-E2", "E-AE1").ok

func test_terminal_crossovers_reach_all_four_platforms():
	var w := Line.build()
	for code in ["CPM", "KDP"]:
		var options := w.route_options(code + "-H")
		for p in range(1, 5):
			if not options.any(func(r): return r.destination == "BUFFER:%s_B%d" % [code, p]):
				return "Terminal arrival cannot reach " + code + " P" + str(p)
	return true

func test_route_paths_have_no_reversals_or_duplicate_exits():
	var w := Line.build()
	for sid in w.signals:
		var exits := []
		for option in w.route_options(sid):
			if option.destination in exits:
				return "Duplicate destination in route desk: " + sid
			exits.append(option.destination)
			var edge: String = w.signals[sid].edge
			var dir: int = w.signals[sid].dir
			for r in option.edges:
				var a := w.graph.tangent(edge,w.graph.exit_s(edge,dir),dir)
				var b := w.graph.tangent(r.edge,w.graph.entry_s(r.edge,r.dir),r.dir)
				if a.dot(b) < .97:
					return "Route reverses at a turnout: " + sid + " into " + r.edge
				edge = r.edge
				dir = r.dir
	return true

func test_lhb_berths_on_extended_corridor():
	var w := Line.build_lhb()
	var t: Train = w.trains.T1
	t.automatic = true
	w.step(1200)
	var rear := t.locate_behind(w.graph,t.length)
	if t.path[0].edge != "MRT_P1" or rear.edge != "MRT_P1" or t.speed > .01:
		return "Full LHB rake did not berth at Maruthur"
	if w.graph.position(rear.edge,rear.s).x < 10700 or w.switch_lock_reason("MRT_LE") != "":
		return "Tail overhang or entrance points still fouled"
	w.set_route("MRT-E1","E-AE1")
	w.set_route("KDP-H","BUFFER:KDP_B1")
	w.step(1400)
	rear = t.locate_behind(w.graph,t.length)
	return t.service_complete and rear.edge == "KDP_P1" and w.graph.position(rear.edge,rear.s).x > 21200 and w.events.is_empty()

func test_six_train_station_saturation_and_recovery():
	var w := Line.build_dispatch()
	var arrived := {}
	var maximum := 0
	var held_following := false
	# Dispatcher deliberately holds all four station starters at red.
	for tick in 420:
		Dispatch.update(w, true)
		w.step(5)
		var count := 0
		for t in w.trains.values():
			if t.path[0].edge.begins_with("MRT_P") and t.speed < .01:
				arrived[t.id] = true
				count += 1
		maximum = maxi(maximum, count)
		if count == 4:
			for id in ["T5", "T6"]:
				var t: Train = w.trains[id]
				if t.speed < .01 and not t.path[0].edge.begins_with("MRT_P"):
					held_following = true
		if maximum == 4 and held_following:
			break
	if maximum != 4 or not held_following:
		return "Expected four berthed trains and following traffic held safely: " + str(maximum)
	# Normal routing then empties the station and completes all six services.
	for tick in 600:
		Dispatch.update(w)
		w.step(5)
		if w.trains.values().all(func(t): return t.service_complete):
			break
	if not w.events.is_empty():
		return "Safety intervention during dispatched movements: " + str(w.events)
	return w.trains.values().all(func(t): return t.service_complete)

func test_wap7_round_trip_uses_both_running_lines():
	var w := Line.build_wap7()
	w.trains.T1.automatic = true
	w.set_route("MRT-E1","E-AE1")
	w.set_route("KDP-H","BUFFER:KDP_B1")
	w.step(2200)
	if not w.trains.T1.service_complete or not w.reverse_train("T1").ok:
		return "Light engine did not complete/reverse at Kadalur"
	for r in [["KDP-W1","E-AW1"],["MRT-HW","MRT-W3"],["MRT-W3","W-AW1"],["CPM-H","BUFFER:CPM_B3"]]:
		if not w.set_route(r[0],r[1]).ok:
			return "Return route refused: " + r[0]
	w.trains.T1.automatic = true
	w.step(2200)
	return w.trains.T1.service_complete and w.trains.T1.path[0].edge == "CPM_P3" and w.events.is_empty()
