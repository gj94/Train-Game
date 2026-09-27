extends Node3D
## Train sound, driven by the sim every frame. Attach under the leading car.
##
## Track sound comes from the user's Railway Sound Lab (E:\ClaudeWS\railway-clang-simulator):
## - Cab: the approved calibrated take, time-stretched by speed (calibrated_bed.gd, WSOLA).
## - Outside: the procedural model with measured resonances (rail_sounds.gd), one
##   impact per axle per rail joint from the sim's odometer, plus synth.js's rolling
##   bed (filtered noise with a sleeper-spacing pulse).
## The two crossfade when the camera switches between cab and overview.
## On top: 3-phase traction whine, PWM whistle, transformer hum, flange squeal,
## air-brake hiss (synthesized), and the horn (CC0 recording).
## Everything runs through the "Train" bus: reverb, plus a low-pass in the cab.

const JOINT_SPACING := 13.0
const SYNTH_RATE := 22050.0
## Axles of the leading car, metres behind the head (lead bogie, trailing bogie).
const NEAR_AXLES := [1.75, 4.25]
const FAR_AXLES := [17.05, 19.55]
const RailSounds := preload("res://game/rail_sounds.gd")
const CalibratedBed := preload("res://game/calibrated_bed.gd")
const CALIBRATED_TAKE := "res://assets/sounds/lab/calibrated_55kmh.wav"
const BUS := "Train"
const RUMBLE := 0.3          # synth.js default "rumble"

var train: Train
var world: RailWorld

var _bed                     # CalibratedBed
var _bed_player: AudioStreamPlayer
var _bed_playback: AudioStreamGeneratorPlayback
var _synth: AudioStreamPlayer3D
var _playback: AudioStreamGeneratorPlayback
var _clacks_near: AudioStreamPlayer3D
var _clacks_far: AudioStreamPlayer3D
var _horn: AudioStreamPlayer3D
var _reverb: AudioEffectReverb
var _lowpass: AudioEffectLowPassFilter

var _cab := false
var _cab_mix := 0.0          # 0 = outside sound, 1 = cab sound (smoothed)
var _last_odo := 0.0
var _prev_controller := 0.0
var _rng := RandomNumberGenerator.new()

# Smoothed synth parameters (updated per frame, read per sample).
var _whine_amp := 0.0
var _whine_freq := 100.0
var _carrier_amp := 0.0
var _squeal_amp := 0.0
var _hiss_amp := 0.0
var _bed_amp := 0.0          # outside rolling bed level
var _odo_now := 0.0
# Oscillator / filter state.
var _ph := [0.0, 0.0, 0.0, 0.0, 0.0, 0.0]
var _t := 0.0
var _lp_hiss := 0.0
var _n_low := 0.0
var _n_deep := 0.0
var _n_mid := 0.0


func setup(t: Train, w: RailWorld) -> void:
	train = t
	world = w
	_last_odo = t.odometer
	_prev_controller = t.controller
	_make_bus()

	# Cab: calibrated take (non-positional — you're sitting on top of it).
	_bed = CalibratedBed.new(load(CALIBRATED_TAKE))
	var bed_gen := AudioStreamGenerator.new()
	bed_gen.mix_rate = _bed.rate
	bed_gen.buffer_length = 0.15
	_bed_player = AudioStreamPlayer.new()
	_bed_player.stream = bed_gen
	_bed_player.bus = BUS
	add_child(_bed_player)
	_bed_player.play()
	_bed_playback = _bed_player.get_stream_playback()

	var gen := AudioStreamGenerator.new()
	gen.mix_rate = SYNTH_RATE
	gen.buffer_length = 0.12
	_synth = _player(gen, 14.0)
	_synth.play()
	_playback = _synth.get_stream_playback()

	_clacks_near = _player(RailSounds.joint_impacts(4, 0), 14.0)
	_clacks_near.max_polyphony = 8
	_clacks_far = _player(RailSounds.joint_impacts(4, 2), 14.0)
	_clacks_far.position = Vector3(0, 0, 15.3)     # trailing bogie of the same car
	_clacks_far.max_polyphony = 8
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


## Cab: small, damped steel-box reverb and muffled highs; calibrated take.
## Outside: open-air reverb; procedural clacks + rolling bed.
func set_interior(cab: bool) -> void:
	_cab = cab
	var idx := AudioServer.get_bus_index(BUS)
	if cab:
		_reverb.room_size = 0.32
		_reverb.damping = 0.55
		_reverb.spread = 0.6
		_reverb.wet = 0.22
		_reverb.dry = 0.95
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
	_cab_mix = move_toward(_cab_mix, 1.0 if _cab else 0.0, delta / 0.6)
	var outside := 1.0 - _cab_mix

	# Cab: calibrated take follows speed; silent at a stand (its own fade).
	_bed.target_speed = kmh
	_bed.target_volume = 0.8 * _cab_mix
	var frames := _bed_playback.get_frames_available()
	if frames > 0:
		_bed_playback.push_buffer(_bed.process(frames))

	# Outside rolling bed (synth.js): rumble * min(1.5, (v/100)^0.8).
	_bed_amp = lerpf(_bed_amp, outside * RUMBLE * minf(1.5, pow(kmh / 100.0, 0.8)), k)

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

	_odo_now = train.odometer
	_fill_synth()
	_rail_joints(kmh, outside)


func _fill_synth() -> void:
	var frames := _playback.get_frames_available()
	var dt := 1.0 / SYNTH_RATE
	var low_a := 1.0 - exp(-TAU * 180.0 / SYNTH_RATE)
	var deep_a := 1.0 - exp(-TAU * 32.0 / SYNTH_RATE)
	var mid_a := 1.0 - exp(-TAU * 1800.0 / SYNTH_RATE)
	# Sleeper pulse (0.65 m spacing) and a slower undulation, from synth.js.
	var sleeper := 0.8 + 0.12 * sin(TAU * _odo_now / 0.65) + 0.08 * sin(TAU * _odo_now / 2.8)
	var bed := _bed_amp * sleeper
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
		# Rolling bed (outside): low + deep noise with a little mid roughness.
		var noise := _rng.randf_range(-1.0, 1.0)
		_n_low += low_a * (noise - _n_low)
		_n_deep += deep_a * (noise - _n_deep)
		_n_mid += mid_a * (noise - _n_mid)
		s += (_n_low * 1.7 + _n_deep * 1.5 + (_n_mid - _n_low) * 0.152) * bed
		# Air hiss: low-passed white noise.
		_lp_hiss = lerpf(_lp_hiss, _rng.randf_range(-1.0, 1.0), 0.35)
		s += _hiss_amp * _lp_hiss
		_playback.push_frame(Vector2(s, s))


## Outside: one impact per axle per rail joint crossed since last frame.
func _rail_joints(kmh: float, outside: float) -> void:
	var odo := train.odometer
	var moved := odo - _last_odo
	if moved <= 0.0 or moved > JOINT_SPACING * 2.0 or outside < 0.01:   # stopped, time skip, or in the cab
		_last_odo = odo
		return
	for a in NEAR_AXLES:
		if _joints_crossed(_last_odo - a, odo - a) > 0:
			_clacks_near.volume_db = linear_to_db(outside * RailSounds.hit_gain(kmh, floori((odo - a) / JOINT_SPACING)))
			_clacks_near.play()
	for a in FAR_AXLES:
		if _joints_crossed(_last_odo - a, odo - a) > 0:
			# synth.js: the far bogie is heard through the body at 0.64.
			_clacks_far.volume_db = linear_to_db(outside * 0.64 * RailSounds.hit_gain(kmh, floori((odo - a) / JOINT_SPACING)))
			_clacks_far.play()
	_last_odo = odo


static func _joints_crossed(from: float, to: float) -> int:
	return maxi(0, floori(to / JOINT_SPACING) - floori(from / JOINT_SPACING))
