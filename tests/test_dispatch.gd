extends RefCounted
## Safety regressions and an actual two-train meet, independent of rendering.

const Line := preload("res://sim/layouts/first_line.gd")
const Small := preload("res://tests/test_signals.gd")

func test_route_selection_aligns_points_and_locks_exit():
	var w := Line.build()
	var result := w.set_route("MRT-HE", "MRT-SE2")
	if not result.ok:
		return result.reason
	return w.graph.switches.MRT_1.reversed and w.aspect("MRT-HE") == RailWorld.Aspect.YELLOW and not w.throw_switch("MRT_1").ok

func test_failed_route_has_no_partial_point_changes():
	var w := Line.build()
	w.place_train(Train.new("blocker", 40), "mrt_loop", 230, 1)
	var result := w.set_route("MRT-HE", "MRT-SE2")
	return not result.ok and not w.graph.switches.MRT_1.reversed and w.signals["MRT-HE"].route.is_empty()

func test_shared_throat_conflicts_even_when_blocks_differ():
	var w := Small.small_world()
	if not w.set_route("s0", "s1").ok:
		return "initial route failed"
	return not w.set_route("sc", "BUFFER:A").ok

func test_independent_arrivals_into_different_loop_roads():
	var w := Line.build()
	return w.set_route("MRT-HE", "MRT-SE2").ok and w.set_route("MRT-HW", "MRT-SW1").ok

func test_same_berth_opposing_arrivals_are_refused():
	var w := Line.build()
	w.set_route("MRT-HE", "MRT-SE1")
	return not w.set_route("MRT-HW", "MRT-SW1").ok

func test_passed_signal_cannot_cancel_before_first_route_edge():
	var w := Small.small_world()
	var t := Train.new("T", 40)
	w.place_train(t, "e0", 89, 1)
	w.set_route("s0", "s1")
	t.speed = 5
	w.step(0.5)
	w.set_signal("s0", false)
	return not w.signals.s0.route.is_empty() and not w.throw_switch("S").ok

func test_approach_cancellation_keeps_points_locked_until_stopped():
	var w := Small.small_world()
	var t := Train.new("T", 40)
	w.place_train(t, "e0", 75, 1)
	t.speed = 10
	w.set_route("s0", "s1")
	w.set_signal("s0", false)
	if w.aspect("s0") != RailWorld.Aspect.RED or w.throw_switch("S").ok:
		return "cancellation failed to hold approach lock"
	t.speed = 0
	w.step(0.02)
	return w.throw_switch("S").ok

func test_no_route_means_red_even_with_empty_track():
	var w := Line.build()
	for sid in w.signals:
		if w.aspect(sid) != RailWorld.Aspect.RED:
			return sid + " cleared without a route"
	return true

func test_ai_brakes_for_red_beyond_yellow():
	var w := Small.small_world()
	var t := Train.new("AI", 40)
	w.place_train(t, "e0", 60, 1)
	w.set_route("s0", "s1")
	t.automatic = true
	t.speed = 19.0
	w.step(90)
	if t.path[0].edge != "e1" or t.speed > 0.01:
		return "AI did not stop in the next block"
	if w.events.any(func(e): return e.kind == "spad"):
		return "AI passed the downstream red"
	return w.next_signal(t).id == "s1" and w.next_signal(t).distance >= 5

func test_route_cannot_be_changed_while_reserved():
	var w := Line.build()
	w.set_route("MRT-HE", "MRT-SE2")
	var result := w.set_route("MRT-HE", "MRT-SE1")
	return not result.ok and w.graph.switches.MRT_1.reversed and w.signals["MRT-HE"].destination == "MRT-SE2"

func test_tail_keeps_block_occupied_after_head_leaves():
	var w := Small.small_world()
	var t := Train.new("long", 140)
	w.place_train(t, "e3", 20, 1)
	return not w.set_route("s0", "s1").ok and w.occupancy().has("e1")

func test_signal_query_honours_search_distance():
	var w := Small.small_world()
	var t := Train.new("T", 40)
	w.place_train(t, "e0", 50, 1)
	return w.next_signal(t, 20).is_empty() and w.next_signal(t, 40).id == "s0"

func test_manually_driven_service_can_complete():
	var w := Line.build()
	var t: Train = w.trains.T1
	t.destination = "Kadalur"
	w.place_train(t, "kdp_plat", w.graph.edges.kdp_plat.length - 8, 1)
	w.step(0.05)
	return t.service_complete and not t.automatic

func test_terminal_platform_does_not_intersect_converging_track():
	var w := Line.build()
	var platform: Rect2 = w.stations[0].platforms[0]
	for edge in ["cpm_p1", "cpm_p2"]:
		for i in int(w.graph.edges[edge].length):
			var p := w.graph.position(edge, i)
			if platform.grow(1.83).has_point(Vector2(p.x, p.z)):
				return "Full-width MEMU envelope intersects the platform on " + edge
	return true

func test_large_step_cannot_enter_occupied_block():
	var w := Small.small_world()
	var lead := Train.new("lead", 40)
	var follow := Train.new("follow", 40)
	w.place_train(lead, "e1", 80, 1)
	w.place_train(follow, "e0", 80, 1)
	w.protection = false
	follow.speed = 25
	w.step(5)
	return not follow.occupies("e1") and follow.emergency

func test_complete_opposing_meet_and_tail_release():
	var w := Line.build_dispatch()
	for sid in ["T1", "T2"]:
		w.trains[sid].automatic = true
	for pair in [["CPM-S1", "MRT-HE"], ["KDP-S", "MRT-HW"], ["MRT-HE", "MRT-SE2"], ["MRT-HW", "MRT-SW1"]]:
		var result := w.set_route(pair[0], pair[1])
		if not result.ok:
			return result.reason
	for i in 15000:
		w.step(0.05)
		if w.trains.T1.path[0].edge == "mrt_loop" and w.trains.T2.path[0].edge == "mrt_main" and w.trains.T1.speed < 0.01 and w.trains.T2.speed < 0.01:
			break
	if w.trains.T1.path[0].edge != "mrt_loop" or w.trains.T2.path[0].edge != "mrt_main":
		return "Trains did not reach their separate platforms"
	for pair in [["MRT-SE2", "KDP-H"], ["MRT-SW1", "CPM-H"], ["KDP-H", "BUFFER:KDP_B"], ["CPM-H", "BUFFER:CPM_B1"]]:
		var result := w.set_route(pair[0], pair[1])
		if not result.ok:
			return "Tail-clear departure refused: " + result.reason
	for i in 18000:
		w.step(0.05)
		if w.trains.T1.service_complete and w.trains.T2.service_complete:
			break
	if not w.trains.T1.service_complete or not w.trains.T2.service_complete:
		return "Services did not finish"
	for e in w.events:
		if e.kind in ["spad", "warning", "safety"]:
			return e.text
	return true
