extends RefCounted
## Track-sound logic: the axle-over-joint scheduler and its laws (the sound itself is checked by ear).

const AxleJoint := preload("res://game/axle_joint.gd")
const Data := preload("res://game/joint_video_model_data.gd")


## Drive axles along a straight 1000 m edge (then optionally a second edge) at constant
## speed, 60 fps. Returns hits, each with `wheel_at`: where that wheel really met the joint.
static func run(axles: Array, speed: float, seconds: float, head0: float = 60.0, dir: int = 1,
		split_at: float = INF) -> Array:
	var s = AxleJoint.new()
	s.setup(axles, 13.0, 6.5)
	var head := head0
	var out := []
	var ahead := Data.KERNEL_LEAD * speed
	for f in int(seconds * 60):
		head += dir * speed / 60.0
		var pos := []
		for a in axles:
			var p: float = head - dir * (a.x - ahead)       # look-ahead point, track coordinate
			if p >= split_at:                                # second edge starts at split_at
				pos.append({edge = "b", s = p - split_at, dir = 1, length = 1000.0})
			else:
				pos.append({edge = "a", s = p, dir = dir, length = split_at if split_at < INF else 1000.0})
		for h in s.advance(pos, speed):
			var base := split_at if h.edge == "b" else 0.0
			var joint_track: float = base + 6.5 + h.joint * 13.0
			h.wheel_at = joint_track
			h.head_now = head
			out.append(h)
	return out


func test_joints_are_fixed_on_the_track():
	var hits := run([{x = 2.0, cls = 0, car = 0}], 20.0, 3.0)
	for h in hits:
		# Head position when the wheel hit = joint + axle offset; reconstruct from lateness.
		var head_at_hit: float = h.head_now - h.late * 20.0 + Data.KERNEL_LEAD * 20.0
		if absf(head_at_hit - 2.0 - h.wheel_at) > 0.001:
			return "wheel met joint %d at head %f, expected %f" % [h.joint, head_at_hit, h.wheel_at + 2.0]
	return true if hits.size() >= 3 else "expected hits every 13 m, got %d" % hits.size()


func test_bogie_pair_hits_same_joint_one_wheelbase_apart():
	var hits := run([{x = 1.0, cls = 0, car = 0}, {x = 3.5, cls = 1, car = 0}], 20.0, 2.0)
	var j := func(axle): return hits.filter(func(h): return h.axle == axle and h.joint == 6)
	var a: Array = j.call(0)
	var b: Array = j.call(1)
	if a.is_empty() or b.is_empty():
		return "both axles should hit joint 6"
	var t_a: float = a[0].head_now - a[0].late * 20.0
	var t_b: float = b[0].head_now - b[0].late * 20.0
	return true if absf((t_b - t_a) - 2.5) < 0.01 else "second axle should hit 2.5 m of travel later, got %f" % (t_b - t_a)


func test_hit_count_is_axles_times_joints():
	var axles := AxleJoint.rake_axles(2, 21.9, 21.3, 3.0, 2.5)
	var hits := run(axles, 25.0, 4.0, 60.0)       # 100 m of travel, well inside the edge
	var ahead := Data.KERNEL_LEAD * 25.0
	var expected := 0
	for a in axles:
		var p0: float = 60.0 - (a.x - ahead) + 25.0 / 60.0   # first frame's look-ahead point
		var p1: float = 160.0 - (a.x - ahead)
		expected += floori((p1 - 6.5) / 13.0) - floori((p0 - 6.5) / 13.0)
	return true if hits.size() == expected else "expected %d hits, got %d" % [expected, hits.size()]


func test_crossing_onto_the_next_edge():
	var hits := run([{x = 0.0, cls = 0, car = 0}], 20.0, 2.0, 80.0, 1, 100.0)
	var on_b := hits.filter(func(h): return h.edge == "b")
	var on_a := hits.filter(func(h): return h.edge == "a")
	if on_a.is_empty() or on_b.is_empty():
		return "should hit joints on both edges (a: %d, b: %d)" % [on_a.size(), on_b.size()]
	return true if on_b[0].joint == 0 else "first joint on the new edge should be k=0 (6.5 m in)"


func test_running_backwards_hits_the_same_joints():
	var hits := run([{x = 0.0, cls = 0, car = 0}], 20.0, 1.5, 200.0, -1)
	var ks := hits.map(func(h): return h.joint)
	# Moving from 200 m down to ~170 m: joints at 188.5 (k=14) and 175.5 (k=13).
	return true if ks == [14, 13] else "backwards crossings should be [14, 13], got %s" % [ks]


func test_teleport_and_reset_do_not_burst():
	var s = AxleJoint.new()
	s.setup([{x = 0.0, cls = 0, car = 0}], 13.0, 6.5)
	s.advance([{edge = "a", s = 10.0, dir = 1, length = 1000.0}], 20.0)
	if not s.advance([{edge = "a", s = 900.0, dir = 1, length = 1000.0}], 20.0).is_empty():
		return "a 890 m jump produced hits"
	s.reset()
	return s.advance([{edge = "a", s = 910.0, dir = 1, length = 1000.0}], 20.0).is_empty()


func test_joint_character_is_stable():
	return AxleJoint.joint_character("main_w", 5) == AxleJoint.joint_character("main_w", 5)


func test_rake_geometry():
	var ax := AxleJoint.rake_axles(2, 21.9, 21.3, 3.0, 2.5)
	var xs := ax.map(func(a): return a.x)
	var want := [1.75, 4.25, 17.05, 19.55, 23.65, 26.15, 38.95, 41.45]
	for i in want.size():
		if absf(xs[i] - want[i]) > 1e-6:
			return "axle %d at %f, want %f" % [i, xs[i], want[i]]
	return ax.map(func(a): return a.cls) == [0, 1, 2, 3, 0, 1, 2, 3]


func test_laws_are_unity_at_the_takes_speed():
	if absf(AxleJoint.impact_scale(Data.REFERENCE_SPEED) - 1.0) > 1e-6 or absf(AxleJoint.rolling_scale(Data.REFERENCE_SPEED) - 1.0) > 1e-6:
		return "speed laws must be 1.0 at the reference speed"
	if not (AxleJoint.impact_scale(30.0) < 1.0 and AxleJoint.impact_scale(100.0) > 1.0):
		return "impacts should get louder with speed"
	return AxleJoint.rolling_scale(0.0) == 0.0


func test_distance_fade():
	if AxleJoint.distance_gain(1.0) != 1.0:
		return "full level within the near distance"
	return absf(AxleJoint.distance_gain(30.0) - Data.NEAR_DISTANCE / 30.0) < 1e-6


func test_exported_model_matches_the_fit():
	if Data.MODEL_ID != "joint-video-contact-v1" or Data.REFERENCE_SPEED != 60.0:
		return "expected the approved joint-video bank, with a 60 km/h volume anchor"
	if Data.KERNELS != 28 or Data.WHEEL_GAIN.size() != 2:
		return "expected 14 pairs of individually triggered first/second wheel strikes"
	for w in Data.KERNELS:
		var wav: AudioStreamWAV = load(Data.KERNEL_PATH % w)
		if wav == null or not wav.stereo or absf(wav.get_length() - Data.KERNEL_SECONDS) > 0.01:
			return "wheel kernel %d missing or wrong length" % (w + 1)
		if wav.loop_mode != AudioStreamWAV.LOOP_DISABLED:
			return "a wheel strike must never loop"
	return true


func test_every_bogie_is_cling_then_clang():
	# Positions 0/2 are the first wheel of the leading / trailing bogie, 1/3 the second.
	var ax := AxleJoint.rake_axles(1, 21.9, 21.3, 3.0, 2.5)
	var wheel := ax.map(func(a): return a.cls % 2)
	return true if wheel == [0, 1, 0, 1] else "wheel-in-bogie order should be cling, clang, cling, clang: %s" % [wheel]


func test_game_audio_scripts_compile():
	for p in ["res://game/train_audio.gd", "res://game/main.gd", "res://game/world_view.gd"]:
		var sc = load(p)
		if sc == null or not sc.can_instantiate():
			return "%s does not compile" % p
	return true
