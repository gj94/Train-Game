extends RefCounted
const Motion := preload("res://game/train_motion.gd")

func fixture() -> Dictionary:
	var g := TrackGraph.new()
	for i in 5: g.add_node(str(i), Vector3(i * 100, 0, 0))
	for i in 4: g.add_edge(str(i), str(i), str(i + 1))
	var t := Train.new("T", 20)
	t.path = [{edge="1", dir=1}]
	t.head_s = 50
	return {g=g, t=t, m=Motion.new(t,g)}

func test_uniform_render_motion_at_mismatched_frame_rates():
	for fps in [30, 60, 90, 144, 240]:
		var f := fixture()
		var next_tick := 0.0
		var previous := -1.0
		for frame in range(1, fps + 1):
			var now := frame / float(fps)
			while next_tick <= now + .0000001:
				f.m.begin_tick()
				f.t.advance(f.g, 20.0 / 60.0)
				f.m.end_tick()
				next_tick += 1.0 / 60.0
			f.m.sample((now - next_tick + 1.0 / 60.0) * 60.0)
			var x: float = f.m.point(5).x
			if previous >= 0 and absf((x - previous) - 20.0 / fps) > .0001:
				return "uneven frame displacement at %d FPS: %f" % [fps, x-previous]
			previous = x
	return true

func test_render_keeps_tail_history_across_edge_boundary():
	var f := fixture()
	f.t.path = [{edge="1",dir=1},{edge="0",dir=1}]
	f.t.head_s = 19.8
	f.m.reset()
	f.m.begin_tick()
	f.t.advance(f.g, .6) # Simulation drops edge 0 after the tail leaves it.
	f.m.end_tick()
	f.m.sample(.1)
	if f.t.path.size() != 1 or f.m.locate(20).edge != "0": return "old tail edge discarded before rendered tail cleared it"
	if absf(f.m.point(20).x - 99.86) > .0001: return "tail interpolation jumped at boundary"
	f.m.sample(.8)
	if f.m.locate(20).edge != "1": return "rendered tail failed to enter new edge"
	return true

func test_render_crossing_in_reverse_direction():
	var f := fixture()
	f.t.path = [{edge="2",dir=-1}]
	f.t.head_s = .2
	f.m.reset()
	f.m.begin_tick()
	f.t.advance(f.g, .6)
	f.m.end_tick()
	f.m.sample(.25)
	if absf(f.m.point(0).x - 200.05) > .0001: return "reverse boundary interpolation"
	f.m.sample(.75)
	if absf(f.m.point(0).x - 199.75) > .0001: return "reverse boundary transition"
	return true

func test_render_teleport_and_cab_reversal_snap():
	var f := fixture()
	f.m.begin_tick()
	f.t.advance(f.g, 1)
	f.m.end_tick()
	f.m.sample(.1)
	f.t.head_s = 80
	if absf(f.m.point(0).x - 180) > .0001: return "teleport swept from old position"
	f.t.reverse(f.g)
	if f.m.locate(0).dir != -1 or absf(f.m.point(0).x - 160) > .0001: return "cab reversal retained old interpolation"
	return true

func test_render_curve_stays_on_track_and_leaves_simulation_untouched():
	var f := fixture()
	f.g.edges["1"].points = PackedVector3Array([Vector3(100,0,0),Vector3(150,0,5),Vector3(200,0,0)])
	f.g.edges["1"].cum = PackedFloat32Array([0,sqrt(2525.0),2*sqrt(2525.0)])
	f.g.edges["1"].length = 2*sqrt(2525.0)
	f.m.reset()
	f.m.begin_tick()
	f.t.advance(f.g, 2)
	f.m.end_tick()
	var head: float = f.t.head_s
	var odometer: float = f.t.odometer
	for alpha in [.1,.4,.9]:
		f.m.sample(alpha)
		var expected: Vector3 = f.g.position("1",50+2*alpha-5)
		if f.m.point(5).distance_to(expected) > .0001: return "render cut across curved track"
		if f.t.head_s != head or f.t.odometer != odometer: return "render modified simulation"
		if absf(f.m.odometer()-2*alpha) > .0001: return "wheel rotation and rendered distance disagree"
	return true

