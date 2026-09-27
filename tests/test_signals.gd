extends RefCounted
## Signal aspects, route locking and signal passing.

const A := RailWorld.Aspect

## A --e0-- S --e1-- M --e3-- B        signals: s0 (e0 east), s1 (e1 east),
##           \--e2-- C                          sb (e1 west), sw (e3 west), sc (e2 west)
static func small_world() -> RailWorld:
	var w := RailWorld.new()
	var g := w.graph
	g.add_node("A", Vector3(0, 0, 0))
	g.add_node("S", Vector3(100, 0, 0))
	g.add_node("M", Vector3(300, 0, 0))
	g.add_node("B", Vector3(500, 0, 0))
	g.add_node("C", Vector3(300, 0, 20))
	g.add_edge("e0", "A", "S")
	g.add_edge("e1", "S", "M")
	g.add_edge("e3", "M", "B")
	g.add_edge("e2", "S", "C", [Vector3(150, 0, 20)])
	g.add_switch("S", "e0", "e1", "e2")
	w.add_signal("s0", "e0", 1)
	w.add_signal("s1", "e1", 1)
	w.add_signal("sb", "e1", -1)
	w.add_signal("sw", "e3", -1)
	w.add_signal("sc", "e2", -1)
	return w


## Runs the world with the train held at a constant speed.
static func run(w: RailWorld, t: Train, seconds: float, speed: float) -> void:
	for i in int(seconds * 60):
		if not t.emergency:
			t.speed = speed
		w.step(1.0 / 60.0)


func test_uncleared_signal_is_red():
	return small_world().aspect("s0") == A.RED


func test_three_aspects_follow_next_signal():
	var w := small_world()
	w.set_signal("s0", true)
	if w.aspect("s0") != A.YELLOW:
		return "next signal red -> expected YELLOW, got %d" % w.aspect("s0")
	w.set_signal("s1", true)
	if w.aspect("s1") != A.YELLOW:
		return "s1 leads to a buffer stop -> expected YELLOW"
	if w.aspect("s0") != A.GREEN:
		return "next signal yellow -> expected GREEN, got %d" % w.aspect("s0")
	return true


func test_cannot_clear_into_occupied_block():
	var w := small_world()
	w.place_train(Train.new("T", 40.0), "e1", 150.0, 1)
	var r := w.set_signal("s0", true)
	if r.ok:
		return "cleared into an occupied block"
	return w.aspect("s0") == A.RED


func test_occupied_block_turns_cleared_signal_red():
	var w := small_world()
	w.set_signal("s0", true)
	w.place_train(Train.new("T", 40.0), "e1", 150.0, 1)
	return w.aspect("s0") == A.RED


func test_route_locks_switch_until_signal_put_back():
	var w := small_world()
	w.set_signal("s0", true)
	if w.throw_switch("S").ok:
		return "switch moved under a cleared route"
	w.set_signal("s0", false)
	if not w.throw_switch("S").ok:
		return "unused route should release on putting the signal back"
	return true


func test_conflicting_route_refused():
	var w := small_world()
	w.set_signal("s0", true)          # locks e1 eastbound
	var r := w.set_signal("sw", true) # westbound onto e1
	return "opposing route was allowed" if r.ok else true


func test_cannot_clear_through_trailing_switch_set_against():
	var w := small_world()
	if w.set_signal("sc", true).ok:
		return "cleared sc with switch S normal (against)"
	w.throw_switch("S")
	if not w.set_signal("sc", true).ok:
		return "should clear once switch is reversed"
	return true


func test_passing_clear_signal_puts_it_back_and_releases_route():
	var w := small_world()
	var t := Train.new("T", 40.0)
	w.place_train(t, "e0", 80.0, 1)
	w.set_signal("s0", true)
	w.set_signal("s1", true)
	run(w, t, 3.0, 10.0)              # head now ~110 m on (on e1)
	if w.signals.s0.cleared or w.aspect("s0") != A.RED:
		return "s0 should return to red behind the train"
	if w.throw_switch("S").ok:
		return "switch moved under the train / its route"
	run(w, t, 30.0, 10.0)             # well onto e3, tail clear of e1
	if not w.signals.s0.route.is_empty():
		return "route should be released: %s" % [w.signals.s0.route]
	if not w.throw_switch("S").ok:
		return "switch should be free after the train cleared it"
	for e in w.events:
		if e.kind == "spad":
			return "unexpected SPAD: " + e.text
	return true


func test_spad_applies_emergency_brake():
	var w := small_world()
	var t := Train.new("T", 40.0)
	w.place_train(t, "e0", 80.0, 1)
	run(w, t, 2.0, 10.0)
	if not t.emergency:
		return "protection should apply emergency brake"
	var spads := w.events.filter(func(e): return e.kind == "spad")
	if spads.size() != 1:
		return "expected one SPAD event, got %d" % spads.size()
	return true


func test_emergency_release_only_at_stand():
	var w := small_world()
	var t := Train.new("T", 40.0)
	w.place_train(t, "e0", 50.0, 1)
	t.emergency = true
	t.speed = 3.0
	if w.release_emergency("T").ok:
		return "released while moving"
	t.speed = 0.0
	return w.release_emergency("T").ok and not t.emergency


func test_next_signal_distance():
	var w := small_world()
	var t := Train.new("T", 40.0)
	w.place_train(t, "e0", 50.0, 1)
	var ns := w.next_signal(t)
	if ns.id != "s0" or not is_equal_approx(ns.distance, 40.0):
		return "expected s0 at 40 m, got %s" % ns
	t.head_s = 95.0                   # past s0
	ns = w.next_signal(t)
	if ns.id != "s1" or not is_equal_approx(ns.distance, 5.0 + 190.0):
		return "expected s1 at 195 m, got %s" % ns
	return true
