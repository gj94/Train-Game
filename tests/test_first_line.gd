extends RefCounted
## End-to-end run on the first layout with a simple autopilot:
## drive from Chennapuram through the Maruthur loop and stop at its red starter.

const FirstLine := preload("res://sim/layouts/first_line.gd")
const DT := 1.0 / 60.0


## Power up to near the limit; brake for a red signal or the buffers ahead.
static func autopilot(w: RailWorld, t: Train) -> void:
	# Exercise the production driver, including advance turnout speed checks.
	w._drive_automatic(t)


static func drive_until_stopped(w: RailWorld, t: Train, max_seconds: float) -> void:
	var moved := false
	for i in int(max_seconds / DT):
		autopilot(w, t)
		w.step(DT)
		if t.speed > 0.5:
			moved = true
		if moved and t.speed == 0.0:
			return


func test_layout_builds_and_train_is_placed():
	var w := FirstLine.build()
	var t: Train = w.trains.T1
	var tail := t.locate_behind(w.graph, t.length)
	if tail.edge != "cpm_p1" or tail.s < 100.0:
		return "tail should be on platform 1, got %s" % tail
	if w.next_signal(t).id != "CPM-S1":
		return "first signal should be CPM-S1"
	return true


func test_every_signal_block_ends_somewhere_sensible():
	var w := FirstLine.build()
	for sid in w.signals:
		var blk := w.block_ahead(sid)
		if blk.edges.is_empty():
			return "signal %s protects nothing" % sid
	return true


func test_drive_into_loop_and_stop_at_red():
	var w := FirstLine.build()
	var t: Train = w.trains.T1
	w.throw_switch("MRT_1")                       # route into the loop
	for sid in ["CPM-S1", "MRT-HE"]:
		var r := w.set_signal(sid, true)
		if not r.ok:
			return r.reason
	drive_until_stopped(w, t, 600.0)
	if t.path[0].edge != "mrt_loop":
		return "should stop in the loop, head on %s" % t.path[0].edge
	var ns := w.next_signal(t)
	if ns.id != "MRT-SE2" or ns.distance > 40.0:
		return "should stop just before MRT-SE2, got %s" % ns
	for e in w.events:
		if e.kind == "spad":
			return "SPAD: " + e.text
	# Routes behind the train are released; the loop exit switch is free.
	if w.signals["CPM-S1"].route.size() != 0:
		return "CPM-S1 route not released"
	# Onward to Kadalur.
	w.throw_switch("MRT_2")
	for sid in ["MRT-SE2", "KDP-H"]:
		var r := w.set_signal(sid, true)
		if not r.ok:
			return r.reason
	drive_until_stopped(w, t, 600.0)
	if t.path[0].edge != "kdp_plat" or w.distance_to_buffer(t) > 30.0:
		return "should stop at Kadalur buffers, head on %s, %f m to go" % [t.path[0].edge, w.distance_to_buffer(t)]
	for e in w.events:
		if e.kind in ["spad", "warning"]:
			return "%s: %s" % [e.kind, e.text]
	return true


func test_reverse_and_return_westbound():
	var w := FirstLine.build()
	var t: Train = w.trains.T1
	w.place_train(t, "kdp_plat", 200.0, 1)
	if not w.reverse_train("T1").ok:
		return "reverse failed"
	if w.next_signal(t).id != "KDP-S":
		return "after reversing, next signal should be KDP-S, got %s" % w.next_signal(t)
	return true
