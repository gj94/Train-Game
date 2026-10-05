extends Node
## Train sound, driven by the sim every frame.
##
## Track sound: the approved joint-video reconstruction, separated in the Sound Lab
## into 14 pairs of individual synthetic strikes plus a fitted rolling layer.
## tools/export-joint-video-godot.js owns all generated WAVs and constants.
## Actual axle crossings trigger strikes at unchanged pitch; speed changes the spacing
## and loudness, never a fixed-rate clip loop. Rolling noise is the take's
## calibrated background, radiated by every wheel by distance. The listener is the driver
## (cab view) or, in the overview, a spot beside the track where the camera is looking
## (as if standing OVERVIEW_SIDE metres from the rails), turned down gently as you zoom
## out; the two blend while the camera flies between them.
## On top: 3-phase traction whine, PWM whistle, transformer hum, flange squeal, air-brake
## hiss (synthesized), and the horn (CC0 recording).
## Everything runs through the "Train" bus: reverb, plus a low-pass in the cab.

const AxleJoint := preload("res://game/axle_joint.gd")
const JointLayout := preload("res://game/rail_joint_layout.gd")
const Data := preload("res://game/joint_video_model_data.gd")
## One bogie model: wheel 1 = the bogie's first wheel over the joint ("cling", brighter),
## wheel 2 = the second, right after it ("clang", heavier). Every bogie of every car uses it,
## so a car over a joint gives cling-clang ....... cling-clang.
const KERNELS := Data.KERNEL_PATH
const DEFAULT_CLANG_BALANCE_DB := Data.DEFAULT_CLANG_BALANCE_DB # sound-lab voicing; , / . adjust
const ROLLING := Data.ROLLING_PATH
signal joint_hit(edge: String, joint: int, cls: int)   # every axle-over-joint hit (for the joint markers)

const JOINT_SPACING := JointLayout.SPACING
const JOINT_OFFSET := JointLayout.OFFSET
const DEFAULT_TRACK_LEVEL := 1.2     # overall track-sound level (1.0 = the take's level); [ / ] adjust
const OVERVIEW_SIDE := 6.0           # overview listener: metres from the track, at the camera's focus
const DRIVER := Vector2(2.0, 1.5)    # driver's ear: metres behind the head, metres to the side
const SYNTH_RATE := 22050.0
## Listening test: only the track sound (axle hits + rolling noise). Turns off the synthesized
## traction whine / PWM whistle / hum / squeal / brake hiss and the horn.
const TRACK_ONLY := true
const BUS := "Train"

var train: Train
var motion
var world: RailWorld
var camera: Node3D                   # listener in overview

var _sched                           # AxleJoint scheduler
var _kernels: Array = []             # 14 approved [first-wheel, second-wheel] pairs
var clang_balance_db := DEFAULT_CLANG_BALANCE_DB
var _track: AudioStreamPlayer
var _track_pb: AudioStreamPlaybackPolyphonic
var _rolling: AudioStreamPlayer
var _synth: AudioStreamPlayer
var _playback: AudioStreamGeneratorPlayback
var _horn: AudioStreamPlayer
var _reverb: AudioEffectReverb
var _lowpass: AudioEffectLowPassFilter

var track_level := DEFAULT_TRACK_LEVEL
var _cab := false
var interior_listener := DRIVER     # passenger views supply their actual position in the rake
var _cab_mix := 0.0                  # 0 = camera is the listener, 1 = driver is (smoothed)
var _prev_controller := 0.0
var _rng := RandomNumberGenerator.new()

# Smoothed synth parameters (updated per frame, read per sample).
var _whine_amp := 0.0
var _whine_freq := 100.0
var _carrier_amp := 0.0
var _squeal_amp := 0.0
var _hiss_amp := 0.0
var _ph := [0.0, 0.0, 0.0, 0.0, 0.0, 0.0]
var _t := 0.0
var _lp_hiss := 0.0


## `axles`: AxleJoint.rake_axles(...) for this train; `listener`: the overview camera.
func setup(t: Train, w: RailWorld, listener: Node3D, axles: Array) -> void:
	train = t
	world = w
	camera = listener
	_prev_controller = t.controller
	_make_bus()

	_sched = AxleJoint.new()
	_sched.setup(axles, JOINT_SPACING, JOINT_OFFSET)
	for wheel in Data.KERNELS:
		_kernels.append(load(KERNELS % wheel))
	var poly := AudioStreamPolyphonic.new()
	poly.polyphony = 96
	_track = _player(poly)
	_track.play()
	_track_pb = _track.get_stream_playback()

	var roll: AudioStreamWAV = load(ROLLING).duplicate()
	roll.loop_mode = AudioStreamWAV.LOOP_FORWARD
	roll.loop_begin = 0
	roll.loop_end = int(roll.get_length() * roll.mix_rate)
	_rolling = _player(roll)
	_rolling.volume_db = -80.0
	_rolling.play()

	var gen := AudioStreamGenerator.new()
	gen.mix_rate = SYNTH_RATE
	gen.buffer_length = 0.12
	_synth = _player(gen)
	if not TRACK_ONLY:
		_synth.play()
		_playback = _synth.get_stream_playback()
	_horn = _player(load("res://assets/sounds/horn_1.ogg"))


func _player(stream: AudioStream) -> AudioStreamPlayer:
	var p := AudioStreamPlayer.new()
	p.stream = stream
	p.bus = BUS
	add_child(p)
	return p


func horn() -> void:
	if TRACK_ONLY:
		return
	_horn.volume_db = linear_to_db(maxf(0.0001, lerpf(minf(1.0, _overview_gain(0.0) * 2.0), 1.0, _cab_mix)))
	_horn.play()


## After changing ends every axle is a different wheel: start tracking afresh.
func reset_positions() -> void:
	_sched.reset()


## Update geometry after an asymmetric imported formation changes ends.
func set_axles(axles: Array) -> void:
	_sched.setup(axles, JOINT_SPACING, JOINT_OFFSET)


## Shift the clang (2nd wheel) against the cling (1st wheel) by `db`; returns the new balance.
func adjust_clang_balance(db: float) -> float:
	clang_balance_db = clampf(clang_balance_db + db, -12.0, 12.0)
	return clang_balance_db


## Change the track-sound level by `db` decibels; returns the new level in dB (0 = the take's level).
func adjust_track_level(db: float) -> float:
	track_level = clampf(track_level * db_to_linear(db), 0.1, 8.0)
	return linear_to_db(track_level)


## Bus "Train": reverb (+ low-pass in the cab), created once.
func _make_bus() -> void:
	var idx := AudioServer.get_bus_index(BUS)
	if idx == -1:
		AudioServer.add_bus()
		idx = AudioServer.bus_count - 1
		AudioServer.set_bus_name(idx, BUS)
		AudioServer.set_bus_send(idx, "Master")
		AudioServer.add_bus_effect(idx, AudioEffectReverb.new())
		AudioServer.add_bus_effect(idx, AudioEffectLowPassFilter.new())
		var limiter := AudioEffectHardLimiter.new()   # overlapping hits must not clip
		limiter.ceiling_db = -0.5
		AudioServer.add_bus_effect(idx, limiter)
	_reverb = AudioServer.get_bus_effect(idx, 0)
	_lowpass = AudioServer.get_bus_effect(idx, 1)
	set_interior(false)


## Cab: small, damped steel-box reverb and muffled highs. Outside: open air.
func set_interior(cab: bool) -> void:
	_cab = cab
	var idx := AudioServer.get_bus_index(BUS)
	if cab:
		_reverb.room_size = 0.32
		_reverb.damping = 0.55
		_reverb.spread = 0.6
		_reverb.wet = 0.10
		_reverb.dry = 0.95
		_reverb.predelay_msec = 12.0
		_lowpass.cutoff_hz = 5200.0
	else:
		_reverb.room_size = 0.7
		_reverb.damping = 0.35
		_reverb.spread = 1.0
		_reverb.wet = 0.03
		_reverb.dry = 1.0
		_reverb.predelay_msec = 45.0
		_lowpass.cutoff_hz = 16000.0
	AudioServer.set_bus_effect_enabled(idx, 1, cab)


## Distance from the driver's ear to a point `x` metres behind the head, on the track.
static func driver_distance(x: float, listener: Vector2 = DRIVER) -> float:
	return Vector2(x - listener.x, listener.y).length()


## Distance from the overview listener (beside the track at the camera's focus) to a point
## `x` metres behind the head.
func _overview_distance(x: float) -> float:
	if camera == null:
		return 1e6
	var loc: Dictionary = motion.locate(x) if motion != null else train.locate_behind(world.graph, x)
	var p := world.graph.position(loc.edge, loc.s)
	var focus: Vector3 = camera.pivot
	return Vector2(Vector2(p.x - focus.x, p.z - focus.z).length(), OVERVIEW_SIDE).length()


## Overview gain of a point `x` metres behind the head: distance fade + a gentle zoom fade.
func _overview_gain(x: float) -> float:
	return AxleJoint.distance_gain(_overview_distance(x)) * _zoom_gain()


func _zoom_gain() -> float:
	return clampf(80.0 / maxf(1.0, camera.distance), 0.35, 1.0) if camera != null else 1.0


func _process(delta: float) -> void:
	if train == null:
		return
	var v := train.speed
	var kmh := v * 3.6
	var r := clampf(v / train.max_speed, 0.0, 1.0)
	var k := 1.0 - exp(-8.0 * delta)
	_cab_mix = move_toward(_cab_mix, 1.0 if _cab else 0.0, delta / 1.1)   # follows the camera blend

	_track_sound(v, kmh)
	if TRACK_ONLY:
		return

	# Traction: louder with handle deflection (power, or regenerative braking).
	var traction := absf(train.controller) if not train.emergency else 0.0
	var moving := smoothstep(0.0, 1.5, v)
	var target_whine := (0.02 + 0.13 * traction) * lerpf(1.0, 0.55, r) * maxf(moving, 0.35 * traction)
	var near := lerpf(clampf(_overview_gain(4.0) * 2.0, 0.0, 1.0), 1.0, _cab_mix)   # motor is under the lead car
	_whine_amp = lerpf(_whine_amp, target_whine * near, k)
	_whine_freq = lerpf(_whine_freq, 70.0 + kmh * 8.5, k)
	_carrier_amp = lerpf(_carrier_amp, 0.05 * traction * (1.0 - smoothstep(12.0, 35.0, kmh)) * near, k)

	# Flange squeal on sharp curves (radius under ~400 m) at speed.
	var curv := world.curvature_at(train)
	_squeal_amp = lerpf(_squeal_amp, 0.06 * smoothstep(0.0025, 0.012, curv) * smoothstep(4.0, 14.0, v) * near, k)

	# Air brake: hiss when the brake is applied further; big dump on emergency.
	if train.controller < _prev_controller and train.controller < 0.0:
		_hiss_amp = maxf(_hiss_amp, 0.08 * near)
	if train.emergency and _hiss_amp < 0.2 and v > 0.1:
		_hiss_amp = 0.25 * near
	_hiss_amp *= exp(-1.6 * delta)
	_prev_controller = train.controller
	_fill_synth()


## Both wheels of a bogie use the same approved variant pair at each joint.
static func strike_index(cls: int, car: int, edge: String, joint: int) -> int:
	var variant := posmod(AxleJoint.joint_character(edge, joint) + car * 2 + floori(cls / 2.0), Data.VARIANT_COUNT)
	return variant * 2 + cls % 2


## Axle-over-joint hits + wheel-radiated rolling noise.
func _track_sound(v: float, kmh: float) -> void:
	var impact := AxleJoint.impact_scale(kmh)
	# Where each axle's look-ahead point is on the track (kernels start KERNEL_LEAD early).
	var ahead := Data.KERNEL_LEAD * v
	var positions := []
	for a in _sched.axles:
		var back: float = maxf(0.0, a.x - ahead)
		var loc: Dictionary = motion.locate(back) if motion != null else train.locate_behind(world.graph, back)
		positions.append({edge = loc.edge, s = loc.s, dir = loc.dir, length = world.graph.edges[loc.edge].length})
	for h in _sched.advance(positions, v):
		joint_hit.emit(h.edge, h.joint, h.cls)
		var wheel: int = h.cls % 2          # 0 = first wheel of its bogie (cling), 1 = second (clang)
		var g: float = h.gain * impact * track_level * Data.KERNEL_GAIN * Data.WHEEL_GAIN[wheel]
		if wheel == 1:
			g *= db_to_linear(clang_balance_db)
		g *= lerpf(_overview_gain(h.x), AxleJoint.distance_gain(driver_distance(h.x, interior_listener)), _cab_mix)
		if g < 0.001:
			continue
		var bank_index := strike_index(h.cls, _sched.axles[h.axle].car, h.edge, h.joint)
		_track_pb.play_stream(_kernels[bank_index], minf(h.late, Data.KERNEL_SECONDS - 0.02), linear_to_db(g), 1.0)
	# Rolling noise from every wheel: driver (fixed distances) or camera.
	var cab_d := PackedFloat32Array()
	var cam_d := PackedFloat32Array()
	for a in _sched.axles:
		cab_d.append(driver_distance(a.x, interior_listener))
		if _cab_mix < 0.999:
			cam_d.append(_overview_distance(a.x))
	var level := AxleJoint.rolling_level(cab_d) if _cab_mix >= 0.999 else \
		lerpf(AxleJoint.rolling_level(cam_d) * _zoom_gain(), AxleJoint.rolling_level(cab_d), _cab_mix)
	var roll := level * AxleJoint.rolling_scale(kmh) * track_level * Data.ROLLING_GAIN
	_rolling.volume_db = linear_to_db(maxf(roll, 0.00001))


func _fill_synth() -> void:
	var frames := _playback.get_frames_available()
	var dt := 1.0 / SYNTH_RATE
	for i in frames:
		_t += dt
		var s := 0.0
		# Transformer / converter hum (always on while powered up).
		_ph[0] = fmod(_ph[0] + 100.0 * dt, 1.0)
		s += 0.025 * lerpf(0.2, 1.0, _cab_mix) * sin(TAU * _ph[0])
		# Inverter whine: fundamental + harmonics.
		_ph[1] = fmod(_ph[1] + _whine_freq * dt, 1.0)
		_ph[2] = fmod(_ph[2] + _whine_freq * 2.0 * dt, 1.0)
		_ph[3] = fmod(_ph[3] + _whine_freq * 3.0 * dt, 1.0)
		s += _whine_amp * (sin(TAU * _ph[1]) + 0.45 * sin(TAU * _ph[2]) + 0.2 * sin(TAU * _ph[3]))
		# Low-speed PWM carrier whistle.
		_ph[4] = fmod(_ph[4] + (820.0 + 40.0 * sin(_t * 9.0)) * dt, 1.0)
		s += _carrier_amp * sin(TAU * _ph[4])
		# Flange squeal: wavering high tone.
		_ph[5] = fmod(_ph[5] + (3100.0 + 180.0 * sin(_t * 6.3)) * dt, 1.0)
		s += _squeal_amp * sin(TAU * _ph[5]) * (0.7 + 0.3 * sin(_t * 23.0))
		# Air hiss: low-passed white noise.
		_lp_hiss = lerpf(_lp_hiss, _rng.randf_range(-1.0, 1.0), 0.35)
		s += _hiss_amp * _lp_hiss
		_playback.push_frame(Vector2(s, s))
