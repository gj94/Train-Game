extends RefCounted
## Physical timing of the approved strike bank, independent of frame rate and pitch.
const Scheduler := preload("res://game/axle_joint.gd")
const Audio := preload("res://game/train_audio.gd")
const Data := preload("res://game/joint_video_model_data.gd")
const Layout := preload("res://game/rail_joint_layout.gd")


func _timed_hits(kmh: float, fps: float, direction: int = 1) -> Array:
	var speed := kmh / 3.6
	var s := Scheduler.new()
	s.setup([{x=10.0, cls=0, car=1}, {x=12.56, cls=1, car=1}], Layout.SPACING, Layout.OFFSET)
	var head := 100.0 if direction > 0 else 500.0
	var out := []
	var time := 0.0
	while time < maxf(80.0,Layout.SPACING*5.0) / speed:
		var pos := []
		for axle in s.axles:
			pos.append({edge="plain", s=head-direction*(axle.x-Data.KERNEL_LEAD*speed), dir=direction, length=1000.0})
		for h in s.advance(pos, speed):
			h.time = time - h.late + Data.KERNEL_LEAD
			out.append(h)
		time += 1.0/fps
		head += direction*speed/fps
	return out


func test_lhb_pair_intervals_follow_speed_in_both_directions():
	for direction in [1, -1]:
		for kmh in [15.0, 30.0, 60.0, 90.0, 120.0, 160.0]:
			for fps in [30.0, 60.0, 144.0]:
				var hits := _timed_hits(kmh, fps, direction)
				var compared := 0
				for first in hits.filter(func(h): return h.axle == 0):
					var second := hits.filter(func(h): return h.axle == 1 and h.joint == first.joint)
					if second.is_empty(): continue
					var interval: float = second[0].time - first.time
					if absf(interval-2.56/(kmh/3.6)) > .0001:
						return "LHB pair %.6fs at %s km/h/%s fps, expected %.6fs" % [interval,kmh,fps,2.56/(kmh/3.6)]
					compared += 1
				if compared < 4: return "too few pairs checked"
	return true


func test_same_axle_hits_visible_joint_spacing():
	for kmh in [30.0, 60.0, 120.0]:
		var hits := _timed_hits(kmh, 144.0).filter(func(h): return h.axle == 0)
		for i in range(1,hits.size()):
			if absf((hits[i].time-hits[i-1].time)*kmh/3.6-Layout.SPACING) > .0001:
				return "sound contacts differ from the visible rail spacing"
	return true


func test_stationary_axles_produce_no_impacts():
	var s := Scheduler.new()
	s.setup([{x=0.0, cls=0, car=0}],Layout.SPACING,Layout.OFFSET)
	var p := [{edge="plain",s=Layout.OFFSET,dir=1,length=1000.0}]
	for i in 300:
		if not s.advance(p,0.0).is_empty(): return "stationary wheel replayed an impact"
	return true


func test_variant_pair_stays_together_and_has_no_speed_parameter():
	var variants := {}
	for joint in 100:
		for cls in [0,2]:
			var a := Audio.strike_index(cls,1,"plain",joint)
			var b := Audio.strike_index(cls+1,1,"plain",joint)
			if a < 0 or b >= Data.KERNELS or a%2 != 0 or b != a+1:
				return "first/second wheels selected different approved pairs"
			variants[a/2] = true
	if variants.size() != Data.VARIANT_COUNT: return "not all approved variants are used"
	return true


func test_reference_rhythm_is_not_embedded_in_a_strike():
	# All visible reference wheel pairs were at least 134.966 ms apart.
	# Each strike finishes before the following reference contact, and is not looped.
	if Data.KERNEL_SECONDS-Data.KERNEL_LEAD >= .1349:
		return "a strike could include a second recorded wheel crossing"
	if Data.CLANG_SEMITONES != 0 or Data.DEFAULT_CLANG_BALANCE_DB != 0:
		return "approved video timbre should not be retuned on export"
	return true


func test_acceleration_braking_and_stop_do_not_duplicate_contacts():
	var s := Scheduler.new()
	s.setup([{x=0.0,cls=0,car=0}],Layout.SPACING,Layout.OFFSET)
	var seen := {}
	for frame in range(50*120):
		var t := frame/120.0
		var speed := 0.0
		var head := 484.0
		if t < 20:
			speed = .8*t
			head = 100+.4*t*t
		elif t < 26:
			speed = 16
			head = 260+16*(t-20)
		elif t < 42:
			var u := t-26
			speed = 16-u
			head = 356+16*u-.5*u*u
		var p := [{edge="plain",s=head+Data.KERNEL_LEAD*speed,dir=1,length=1000.0}]
		for hit in s.advance(p,speed):
			if seen.has(hit.joint): return "acceleration or braking replayed a joint"
			if t >= 42: return "impact continued after stopping"
			seen[hit.joint] = true
	var expected := Scheduler.joints_on_edge(1000,Layout.SPACING,Layout.OFFSET)
	var count := 0
	for joint in expected:
		if joint>100 and joint<=484: count += 1
	return true if seen.size()==count else "changing speed skipped contacts: %d vs %d" % [seen.size(),count]
