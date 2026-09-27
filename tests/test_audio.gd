extends RefCounted
## Track-sound logic: the axle-over-joint scheduler and its laws (the sound itself is checked by ear).

const AxleJoint := preload("res://game/axle_joint.gd")
const Data := preload("res://game/physical_model_data.gd")


## Drive a scheduler at constant speed with 60 fps frames; returns all hits with the
## odometer at which each wheel actually reached its joint.
static func run(axles: Array, spacing: float, speed: float, seconds: float) -> Array:
	var s = AxleJoint.new()
	s.setup(axles, spacing, 0.0)
	var odo := 0.0
	var all := []
	for f in int(seconds * 60):
		odo += speed / 60.0
		for h in s.advance(odo, speed):
			h.hit_at = odo - h.late * speed + Data.KERNEL_LEAD * speed   # wheel-on-joint odometer
			all.append(h)
	return all


func test_bogie_pair_hits_one_wheelbase_apart():
	var axles := [{x = 1.0, cls = 0, car = 0}, {x = 3.5, cls = 1, car = 0}]
	var hits := run(axles, 13.0, 20.0, 2.0)
	var first: Array = hits.filter(func(h): return h.axle == 0 and h.joint == 1)
	var second: Array = hits.filter(func(h): return h.axle == 1 and h.joint == 1)
	if first.is_empty() or second.is_empty():
		return "both axles should hit joint 1"
	var gap: float = second[0].hit_at - first[0].hit_at
	return true if absf(gap - 2.5) < 0.01 else "hits should be one wheelbase (2.5 m) of travel apart, got %f" % gap


func test_hit_count_is_axles_times_joints():
	var axles := AxleJoint.rake_axles(2, 21.9, 21.3, 3.0, 2.5)   # 8 axles, all within 45 m
	var hits := run(axles, 13.0, 25.0, 4.0)                       # 100 m of travel
	var expected := 0
	for a in axles:
		expected += floori((100.0 - a.x + Data.KERNEL_LEAD * 25.0) / 13.0) - floori(-a.x / 13.0)
	return true if absf(hits.size() - expected) <= 1 else "expected %d hits, got %d" % [expected, hits.size()]


func test_late_hits_land_on_time():
	# Every hit's recovered wheel-on-joint point must be the exact joint crossing.
	var axles := [{x = 2.0, cls = 0, car = 0}]
	for h in run(axles, 13.0, 30.0, 3.0):
		var ideal: float = h.joint * 13.0 + 2.0
		if absf(h.hit_at - ideal) > 0.001:
			return "hit on joint %d landed at %f, should be %f" % [h.joint, h.hit_at, ideal]
		if h.late < 0.0:
			return "a hit was reported before its kernel start"
	return true


func test_teleport_does_not_burst():
	var s = AxleJoint.new()
	s.setup(AxleJoint.rake_axles(8, 21.9, 21.3, 3.0, 2.5), 13.0, 0.0)
	var hits: Array = s.advance(5000.0, 25.0)
	return true if hits.is_empty() else "a 5 km jump produced %d hits" % hits.size()


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
	if absf(Data.REFERENCE_SPEED - 66.0) > 0.5:
		return "reference speed should be the fitted ~66 km/h, got %f" % Data.REFERENCE_SPEED
	for c in 4:
		var wav: AudioStreamWAV = load("res://assets/sounds/lab/physical_icf_axle%d.wav" % c)
		if wav == null or not wav.stereo or absf(wav.get_length() - Data.KERNEL_SECONDS) > 0.01:
			return "kernel %d missing or wrong length" % c
	return true
