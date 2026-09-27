extends RefCounted
## Track graph navigation and train movement/physics.

## A (buffer) --e0-- S (switch) --e1 (normal)-- B (buffer)
##                               \--e2 (reverse)-- C (buffer)
static func small_graph() -> TrackGraph:
	var g := TrackGraph.new()
	g.add_node("A", Vector3(0, 0, 0))
	g.add_node("S", Vector3(100, 0, 0))
	g.add_node("B", Vector3(300, 0, 0))
	g.add_node("C", Vector3(300, 0, 20))
	g.add_edge("e0", "A", "S")
	g.add_edge("e1", "S", "B")
	g.add_edge("e2", "S", "C", [Vector3(150, 0, 20)])
	g.add_switch("S", "e0", "e1", "e2")
	return g


func test_edge_length_and_position():
	var g := small_graph()
	if not is_equal_approx(g.edges.e0.length, 100.0):
		return "e0 length %f" % g.edges.e0.length
	var p := g.position("e0", 25.0)
	if not p.is_equal_approx(Vector3(25, 0, 0)):
		return "position %s" % p
	var t := g.tangent("e0", 25.0, -1)
	if not t.is_equal_approx(Vector3(-1, 0, 0)):
		return "tangent %s" % t
	return true


func test_switch_facing_follows_setting():
	var g := small_graph()
	if g.next("e0", 1).edge != "e1":
		return "normal should lead to e1"
	g.switches.S.reversed = true
	var n := g.next("e0", 1)
	if n.edge != "e2" or n.dir != 1 or n.switch != "S":
		return "reverse should lead to e2, got %s" % n
	return true


func test_switch_trailing_detects_against():
	var g := small_graph()
	var n := g.next("e2", -1)   # coming back from C while switch is normal
	if n.edge != "e0" or n.dir != -1 or not n.against:
		return "trailing from e2 with switch normal should be 'against': %s" % n
	if g.next("e1", -1).against:
		return "trailing from e1 with switch normal is fine"
	return true


func test_buffer_stop_has_no_next():
	var g := small_graph()
	return g.next("e0", -1).is_empty() and g.next("e1", 1).is_empty()


func test_train_accelerates_and_brakes():
	var t := Train.new("T", 50.0)
	t.controller = 1.0
	for i in 600:   # 10 s
		t.update_speed(1.0 / 60.0)
	if t.speed < 3.0 or t.speed > 6.0:
		return "after 10 s full power expected ~5 m/s, got %f" % t.speed
	t.controller = -1.0
	for i in 600:
		t.update_speed(1.0 / 60.0)
	if t.speed != 0.0:
		return "should be stopped after braking, speed %f" % t.speed
	return true


func test_train_top_speed_is_capped():
	var t := Train.new("T", 50.0)
	t.controller = 1.0
	for i in 60 * 600:
		t.update_speed(1.0 / 60.0)
	if t.speed > t.max_speed + 0.5:
		return "speed %f above max %f" % [t.speed, t.max_speed]
	return true


func test_advance_through_switch_and_trim_tail():
	var w := RailWorld.new()
	w.graph = small_graph()
	w.graph.switches.S.reversed = true
	var t := Train.new("T", 40.0)
	w.place_train(t, "e0", 90.0, 1)
	t.advance(w.graph, 20.0)          # head crosses S onto e2
	if t.path[0].edge != "e2" or t.path.size() != 2:
		return "path after crossing: %s" % [t.path]
	t.advance(w.graph, 50.0)          # tail now fully on e2 too
	if t.path.size() != 1:
		return "tail should have left e0: %s" % [t.path]
	return true


func test_locate_behind_and_reverse():
	var w := RailWorld.new()
	w.graph = small_graph()
	var t := Train.new("T", 40.0)
	w.place_train(t, "e1", 20.0, 1)   # head 20 m past S, tail 20 m before S on e0
	var tail := t.locate_behind(w.graph, 40.0)
	if tail.edge != "e0" or not is_equal_approx(tail.s, 80.0):
		return "tail at %s" % tail
	t.reverse(w.graph)
	if t.path[0].edge != "e0" or t.path[0].dir != -1 or not is_equal_approx(t.head_s, 80.0):
		return "after reverse head at %s s=%f" % [t.path[0], t.head_s]
	var new_tail := t.locate_behind(w.graph, 40.0)
	if new_tail.edge != "e1" or not is_equal_approx(new_tail.s, 20.0):
		return "after reverse tail at %s" % new_tail
	return true


func test_reverse_refused_while_moving():
	var w := RailWorld.new()
	w.graph = small_graph()
	var t := Train.new("T", 40.0)
	w.place_train(t, "e1", 60.0, 1)
	t.speed = 5.0
	return not w.reverse_train("T").ok


func test_train_stops_at_buffer():
	var w := RailWorld.new()
	w.graph = small_graph()
	var t := Train.new("T", 40.0)
	w.place_train(t, "e1", 150.0, 1)
	t.speed = 10.0
	var res := t.advance(w.graph, 100.0)
	if not res.get("buffer", false) or t.speed != 0.0 or not is_equal_approx(t.head_s, 200.0):
		return "expected stop at buffer (s=200), got s=%f speed=%f" % [t.head_s, t.speed]
	return true


func test_odometer_counts_travel_but_not_past_buffers():
	var w := RailWorld.new()
	w.graph = small_graph()
	var t := Train.new("T", 40.0)
	w.place_train(t, "e1", 150.0, 1)
	t.advance(w.graph, 30.0)
	if not is_equal_approx(t.odometer, 30.0):
		return "after 30 m odometer %f" % t.odometer
	t.advance(w.graph, 100.0)          # only 20 m left before the buffer
	if not is_equal_approx(t.odometer, 50.0):
		return "should stop counting at the buffer, odometer %f" % t.odometer
	return true


func test_curvature_zero_on_straight_and_positive_on_curve():
	var w := RailWorld.new()
	w.graph = small_graph()
	var t := Train.new("T", 40.0)
	w.place_train(t, "e1", 100.0, 1)
	if w.curvature_at(t) > 0.0001:
		return "straight track curvature %f" % w.curvature_at(t)
	w.graph.switches.S.reversed = true
	w.place_train(t, "e2", 5.0, 1)     # head 5 m past the switch: the 10 m span crosses the kink
	if w.curvature_at(t) <= 0.001:
		return "curve should have curvature, got %f" % w.curvature_at(t)
	return true
