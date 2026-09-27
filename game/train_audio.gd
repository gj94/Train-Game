extends Node3D
## Train sound, driven by the sim every frame. Attach under the leading car.
##
## - Rolling: recorded interior loop (CC0, BigSoundBank); volume + pitch follow speed.
## - Synth (AudioStreamGenerator): 3-phase traction inverter whine (pitch follows
##   speed, loudness follows the power/brake handle), transformer hum, flange
##   squeal on curves, air-brake hiss.
## - Rail-joint clacks: modal-synthesis metal impacts (rail_sounds.gd), fired as
##   each nearby axle crosses a joint (every JOINT_SPACING metres).
## - Horn: recorded one-shot.
## Everything goes through the "Train" bus: reverb + a cab low-pass, switched
## between interior (cab) and exterior (overview) with set_interior().

const JOINT_SPACING := 13.0
const MIX_RATE := 22050.0
## Axle positions (metres behind the head) that the listener in the leading cab hears.
const NEAR_AXLES := [1.75, 4.25]
const FAR_AXLES := [17.05, 19.55, 23.65, 26.15]
const RailSounds := preload("res://game/rail_sounds.gd")
const BUS := "Train"

var train: Train
var world: RailWorld

var _rolling: AudioStreamPlayer3D
var _synth: AudioStreamPlayer3D
var _playback: AudioStreamGeneratorPlayback
var _clicks_near: AudioStreamPlayer3D
var _clicks_far: AudioStreamPlayer3D
var _horn: AudioStreamPlayer3D

var _last_odo := 0.0
var _prev_controller := 0.0
var _rng := RandomNumberGenerator.new()
var _reverb: AudioEffectReverb
var _lowpass: AudioEffectLowPassFilter

# Smoothed synth parameters (updated per frame, read per sample).
var _whine_amp := 0.0
var _whine_freq := 100.0
var _carrier_amp := 0.0
var _squeal_amp := 0.0
var _hiss_amp := 0.0
# Oscillator state.
var _ph := [0.0, 0.0, 0.0, 0.0, 0.0, 0.0]
var _t := 0.0
var _lp := 0.0


func setup(t: Train, w: RailWorld) -> void:
	train = t
	world = w
	_last_odo = t.odometer
	_prev_controller = t.controller
	_make_bus()

	var roll: AudioStreamOggVorbis = load("res://assets/sounds/interior_eurostar_car.ogg").duplicate()
	roll.loop = true
	_rolling = _player(roll, 18.0)
	_rolling.volume_db = -80.0
	_rolling.play()

	var gen := AudioStreamGenerator.new()
	gen.mix_rate = MIX_RATE
	gen.buffer_length = 0.12
	_synth = _player(gen, 14.0)
	_synth.play()
	_playback = _synth.get_stream_playback()

	var clacks := RailSounds.joint_impacts(4)
	_clicks_near = _player(clacks, 14.0)
	_clicks_near.max_polyphony = 8
	_clicks_far = _player(clacks, 14.0)
	_clicks_far.max_polyphony = 12
	_horn = _player(load("res://assets/sounds/horn_1.ogg"), 60.0)


func _player(stream: AudioStream, unit_size: float) -> AudioStreamPlayer3D:
	var p := AudioStreamPlayer3D.new()
	p.stream = stream
	p.unit_size = unit_size
	p.max_distance = 3000.0
	p.doppler_tracking = AudioStreamPlayer3D.DOPPLER_TRACKING_DISABLED
	p.bus = BUS
	add_child(p)
	return p


func horn() -> void:
	_horn.play()


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
	_reverb = AudioServer.get_bus_effect(idx, 0)
	_lowpass = AudioServer.get_bus_effect(idx, 1)
	set_interior(false)


## Cab: small, damped steel-box reverb and muffled highs. Outside: open air
## with a longer, thinner tail (ballast, cuttings, trees).
func set_interior(cab: bool) -> void:
	var idx := AudioServer.get_bus_index(BUS)
	if cab:
		_reverb.room_size = 0.32
		_reverb.damping = 0.55
		_reverb.spread = 0.6
		_reverb.wet = 0.28
		_reverb.dry = 0.9
		_reverb.predelay_msec = 12.0
		_lowpass.cutoff_hz = 5200.0
	else:
		_reverb.room_size = 0.7
		_reverb.damping = 0.35
		_reverb.spread = 1.0
		_reverb.wet = 0.2
		_reverb.dry = 1.0
		_reverb.predelay_msec = 45.0
		_lowpass.cutoff_hz = 16000.0
	AudioServer.set_bus_effect_enabled(idx, 1, cab)


func _process(delta: float) -> void:
	if train == null:
		return
	var v := train.speed
	var kmh := v * 3.6
	var r := clampf(v / train.max_speed, 0.0, 1.0)
	var k := 1.0 - exp(-8.0 * delta)   # parameter smoothing factor

	# Rolling loop.
	var roll_gain := smoothstep(0.0, 7.0, v) * lerpf(0.55, 1.0, r)
	_rolling.volume_db = linear_to_db(maxf(roll_gain, 0.0001))
	_rolling.pitch_scale = lerpf(0.72, 1.3, r)

	# Traction: louder with handle deflection (power, or regenerative braking).
	var traction := absf(train.controller) if not train.emergency else 0.0
	var moving := smoothstep(0.0, 1.5, v)
	var target_whine := (0.02 + 0.13 * traction) * lerpf(1.0, 0.55, r) * maxf(moving, 0.35 * traction)
	_whine_amp = lerpf(_whine_amp, target_whine, k)
	_whine_freq = lerpf(_whine_freq, 70.0 + kmh * 8.5, k)
	_carrier_amp = lerpf(_carrier_amp, 0.05 * traction * (1.0 - smoothstep(12.0, 35.0, kmh)), k)

	# Flange squeal on sharp curves (radius under ~400 m) at speed.
	var curv := world.curvature_at(train)
	_squeal_amp = lerpf(_squeal_amp, 0.06 * smoothstep(0.0025, 0.012, curv) * smoothstep(4.0, 14.0, v), k)

	# Air brake: hiss when the brake is applied further; big dump on emergency.
	if train.controller < _prev_controller and train.controller < 0.0:
		_hiss_amp = maxf(_hiss_amp, 0.08)
	if train.emergency and _hiss_amp < 0.2 and v > 0.1:
		_hiss_amp = 0.25
	_hiss_amp *= exp(-1.6 * delta)
	_prev_controller = train.controller

	_fill_synth()
	_rail_joints(r)


func _fill_synth() -> void:
	var frames := _playback.get_frames_available()
	var dt := 1.0 / MIX_RATE
	for i in frames:
		_t += dt
		var s := 0.0
		# Transformer / converter hum (always on while powered up).
		_ph[0] = fmod(_ph[0] + 100.0 * dt, 1.0)
		s += 0.025 * sin(TAU * _ph[0])
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
		_lp = lerpf(_lp, _rng.randf_range(-1.0, 1.0), 0.35)
		s += _hiss_amp * _lp
		_playback.push_frame(Vector2(s, s))


## Fire a click for every axle that crossed a rail joint since last frame.
func _rail_joints(r: float) -> void:
	var odo := train.odometer
	var moved := odo - _last_odo
	if moved <= 0.0:
		_last_odo = odo
		return
	if moved > JOINT_SPACING * 2.0:   # time skip / big jump: don't machine-gun
		_last_odo = odo
		return
	var near_hits := 0
	var far_hits := 0
	for a in NEAR_AXLES:
		near_hits += _joints_crossed(_last_odo - a, odo - a)
	for a in FAR_AXLES:
		far_hits += _joints_crossed(_last_odo - a, odo - a)
	var gain := lerpf(0.35, 1.0, smoothstep(0.0, 0.5, r))
	if near_hits > 0:
		_clicks_near.volume_db = linear_to_db(gain)
		_clicks_near.pitch_scale = _rng.randf_range(0.92, 1.08) * lerpf(0.9, 1.15, r)
		_clicks_near.play()
	if far_hits > 0:
		_clicks_far.volume_db = linear_to_db(gain * 0.3)
		_clicks_far.pitch_scale = _rng.randf_range(0.9, 1.05)
		_clicks_far.play()
	_last_odo = odo


static func _joints_crossed(from: float, to: float) -> int:
	return maxi(0, floori(to / JOINT_SPACING) - floori(from / JOINT_SPACING))
