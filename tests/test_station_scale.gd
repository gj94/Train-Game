extends RefCounted

const Line := preload("res://sim/layouts/first_line.gd")
const Lhb := preload("res://sim/stock/lhb_consist.gd")
const Memu := preload("res://sim/stock/memu_consist.gd")


func test_published_vehicle_dimensions_and_formation():
	return Lhb.FORMATION.size() == Lhb.COACH_COUNT and is_equal_approx(Lhb.LENGTH, 500.562) and \
		Lhb.coach_kind(0) == "eog" and Lhb.coach_kind(19) == "eog" and \
		Lhb.coach_kind(16) == "3a" and Lhb.coach_kind(17) == "2a" and \
		is_equal_approx(Memu.LENGTH, 176.261) and is_equal_approx(Memu.BOGIE_CENTRES, 14.783)


func test_every_platform_keeps_full_vehicle_envelope_clear():
	var w := Line.build()
	for station in w.stations:
		for platform: Rect2 in station.platforms:
			if platform.size.x < 600.0 or platform.size.y < 8.0:
				return "Undersized platform at " + station.code
			for eid in w.graph.edges:
				for s in range(0, int(w.graph.edges[eid].length), 2):
					var p := w.graph.position(eid, s)
					if platform.grow(1.83).has_point(Vector2(p.x, p.z)):
						return "Train envelope intersects " + station.code + " on " + eid
	return true


func test_long_rake_stops_on_both_loop_roads_and_releases_entrance_points():
	for use_loop in [false, true]:
		var w := Line.build_lhb()
		if use_loop:
			w.set_signal("MRT-HE", false)
			if not w.set_route("MRT-HE", "MRT-SE2").ok:
				return "Could not select loop"
		var t: Train = w.trains.T1
		t.automatic = true
		w.step(650)
		var head := w.graph.position(t.path[0].edge, t.head_s)
		var tail := t.locate_behind(w.graph, t.length)
		var rear := w.graph.position(tail.edge, tail.s)
		if t.speed > .01 or head.x > 2840 or rear.x < 2240:
			return "Full-length rake does not berth between platform ends"
		if w.switch_lock_reason("MRT_1") != "" or not w.events.is_empty():
			return "Arrival did not clear entrance points safely"
	return true


func test_origin_and_terminal_keep_whole_rake_at_platform():
	var w := Line.build_lhb()
	var t: Train = w.trains.T1
	if t.head_s - t.length < 8 or t.head_s > 608:
		return "Origin overhang"
	w.set_route("MRT-SE1", "KDP-H")
	w.set_route("KDP-H", "BUFFER:KDP_B")
	t.automatic = true
	w.step(900)
	var rear := t.locate_behind(w.graph, t.length)
	# Leading locomotive may stop beyond the coping; all passenger doors must berth.
	return t.service_complete and rear.edge == "kdp_plat" and rear.s >= 10 and \
		t.head_s - Lhb.LOCO_LENGTH <= 610 and w.events.is_empty()
