extends RefCounted
## Sound logic: rail-joint timing, the ported Railway Sound Lab engines.
## (How it sounds is checked by ear.)

const TrainAudio := preload("res://game/train_audio.gd")
const RailSounds := preload("res://game/rail_sounds.gd")
const CalibratedBed := preload("res://game/calibrated_bed.gd")


func test_joint_crossings_follow_distance():
	var j: float = TrainAudio.JOINT_SPACING
	if TrainAudio._joints_crossed(0.0, j * 0.5) != 0:
		return "no joint within the first half rail"
	if TrainAudio._joints_crossed(j * 0.9, j * 1.1) != 1:
		return "one joint when passing a rail end"
	if TrainAudio._joints_crossed(-1.0, j * 3.0 + 1.0) != 4:
		return "four joints over three rails starting just before a joint"
	return TrainAudio._joints_crossed(5.0, 4.0) == 0   # never negative


func test_impact_rings_then_decays():
	var s := RailSounds.impact_samples(7319)
	var early := _rms(s, 0, 2000)
	var late := _rms(s, s.size() - 4000, s.size())
	if early < 0.05:
		return "impact too quiet: %f" % early
	return true if late < early * 0.01 else "impact still ringing at the end (%f vs %f)" % [late, early]


func test_hit_gain_grows_with_speed():
	return RailSounds.hit_gain(20.0, 5) < RailSounds.hit_gain(60.0, 5) and RailSounds.hit_gain(60.0, 5) < RailSounds.hit_gain(120.0, 5)


func test_calibrated_take_is_pcm16():
	var wav: AudioStreamWAV = load(TrainAudio.CALIBRATED_TAKE)
	if wav.format != AudioStreamWAV.FORMAT_16_BITS:
		return "import must be uncompressed 16-bit (compress/mode=0), got format %d" % wav.format
	return true


func test_calibrated_silent_at_stand_audible_when_moving():
	var bed = CalibratedBed.new(load(TrainAudio.CALIBRATED_TAKE))
	bed.target_volume = 0.8
	bed.target_speed = 0.0
	var still := _rms_v2(bed.process(bed.rate))
	bed.target_speed = 55.0
	bed.process(bed.rate)                 # let speed and gain settle
	var moving := _rms_v2(bed.process(bed.rate))
	if still > 0.001:
		return "should be silent at 0 km/h, rms %f" % still
	return true if moving > 0.01 else "should be audible at 55 km/h, rms %f" % moving


func test_calibrated_rhythm_scales_with_speed():
	var a = CalibratedBed.new(load(TrainAudio.CALIBRATED_TAKE))
	var b = CalibratedBed.new(load(TrainAudio.CALIBRATED_TAKE))
	for bed in [a, b]:
		bed.target_volume = 0.8
	a.target_speed = 55.0
	b.target_speed = 110.0
	a.speed = 55.0                        # skip the slew so the comparison is exact
	b.speed = 110.0
	a.process(a.rate * 2)
	b.process(b.rate * 2)
	var ratio: float = b._source_pos / a._source_pos
	return true if absf(ratio - 2.0) < 0.01 else "110 km/h should advance the pattern 2x as fast, got %f" % ratio


static func _rms(s: PackedFloat32Array, from: int, to: int) -> float:
	var acc := 0.0
	for i in range(from, to):
		acc += s[i] * s[i]
	return sqrt(acc / maxf(1.0, to - from))


static func _rms_v2(s: PackedVector2Array) -> float:
	var acc := 0.0
	for v in s:
		acc += v.x * v.x + v.y * v.y
	return sqrt(acc / maxf(1.0, s.size() * 2.0))
