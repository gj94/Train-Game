extends RefCounted
## GDScript port of the Railway Sound Lab's CalibratedSynth
## (E:\ClaudeWS\railway-clang-simulator\src\calibrated.js).
##
## Pitch-preserving, stereo-linked WSOLA of the user's approved 5-second synthetic
## take (assets/sounds/lab/calibrated_55kmh.wav), calibrated to 55 km/h: grains
## are read at their original rate while their source position advances at
## speed / 55, so the rhythm follows speed and the metal's pitch does not.
## Search stays near the nominal position, so alignment can't drift the tempo.
##
## Differences from the JS: runs at half the source rate (22.05 kHz, the cab view
## low-passes at ~5 kHz anyway) to keep GDScript cost down; output is pulled in
## blocks by the game instead of an AudioWorklet.

const REFERENCE_SPEED := 55.0

var rate: int
var target_speed := 0.0      # km/h, set by the game
var target_volume := 0.0     # 0..1, set by the game
var speed := 0.0
var volume := 0.0

var _l: PackedFloat32Array
var _r: PackedFloat32Array
var _mono: PackedFloat32Array
var _len: int
var _size: int
var _hop: int
var _search: int
var _overlap: int
var _window: PackedFloat32Array
var _qsize: int
var _sum_l: PackedFloat32Array
var _sum_r: PackedFloat32Array
var _weight: PackedFloat32Array
var _reference: PackedFloat32Array
var _head := 0
var _until_grain := 0
var _source_pos := 0.0
var _grains := 0
var _frame := 0
var _motion_gain := 0.0
var _speed_slew: float
var _gain_slew: float


func _init(wav: AudioStreamWAV) -> void:
	_decode_half_rate(wav)
	_len = _l.size()
	_mono = PackedFloat32Array()
	_mono.resize(_len)
	for i in _len:
		_mono[i] = (_l[i] + _r[i]) * 0.5
	_size = roundi(rate * 0.024)
	_hop = roundi(_size / 4.0)
	_search = roundi(rate * 0.004)
	_overlap = _size - _hop
	_window = PackedFloat32Array()
	_window.resize(_size)
	for i in _size:
		_window[i] = pow(sin(PI * (i + 0.5) / _size), 2.0)
	_qsize = _size * 2
	_sum_l = PackedFloat32Array()
	_sum_l.resize(_qsize)
	_sum_r = PackedFloat32Array()
	_sum_r.resize(_qsize)
	_weight = PackedFloat32Array()
	_weight.resize(_qsize)
	_reference = PackedFloat32Array()
	_reference.resize(_overlap)
	_speed_slew = 1.0 - exp(-1.0 / (rate * 0.22))
	_gain_slew = 1.0 - exp(-1.0 / (rate * 0.02))


## PCM16 (stereo or mono) -> float, decimated by 2 with a small [1 2 1]/4 filter.
func _decode_half_rate(wav: AudioStreamWAV) -> void:
	assert(wav.format == AudioStreamWAV.FORMAT_16_BITS, "calibrated take must be uncompressed 16-bit PCM")
	var data := wav.data
	var ch := 2 if wav.stereo else 1
	var frames := data.size() / (2 * ch)
	var half := frames / 2
	rate = wav.mix_rate / 2
	_l = PackedFloat32Array()
	_l.resize(half)
	_r = PackedFloat32Array()
	_r.resize(half)
	for i in half:
		var a := posmod(2 * i - 1, frames)
		var b := 2 * i
		var c := mini(2 * i + 1, frames - 1)
		for side in ch:
			var v := 0.25 * data.decode_s16((a * ch + side) * 2) + 0.5 * data.decode_s16((b * ch + side) * 2) \
				+ 0.25 * data.decode_s16((c * ch + side) * 2)
			v /= 32768.0
			if side == 0:
				_l[i] = v
				if ch == 1:
					_r[i] = v
			else:
				_r[i] = v


func _wrap(i: int) -> int:
	return posmod(i, _len)


func _grain() -> void:
	var nominal := roundi(_source_pos)
	var start := nominal
	# Unity rate is sample-exact; otherwise align waveform phase without changing pitch.
	if _grains > 0 and absf(speed / REFERENCE_SPEED - 1.0) > 1e-8:
		var ref_power := 0.0
		var i := 0
		while i < _overlap:
			var q := (_head + i) % _qsize
			var w := _weight[q]
			var value := (_sum_l[q] + _sum_r[q]) / (2.0 * w) if w > 1e-7 else 0.0
			_reference[i] = value
			ref_power += value * value
			i += 4
		if ref_power > 1e-10:
			var best := -INF
			var best_off := 0
			var d := -_search
			while d <= _search:
				var sc := _score(nominal + d, ref_power)
				if sc > best:
					best = sc
					best_off = d
				d += 4
			var coarse := best_off
			for dd in range(maxi(-_search, coarse - 3), mini(_search, coarse + 3) + 1):
				var sc := _score(nominal + dd, ref_power)
				if sc > best:
					best = sc
					best_off = dd
			start += best_off
	var at := _wrap(start)
	for i in _size:
		var q := (_head + i) % _qsize
		var w := _window[i]
		_sum_l[q] += _l[at] * w
		_sum_r[q] += _r[at] * w
		_weight[q] += w
		at += 1
		if at == _len:
			at = 0
	_grains += 1


## Normalised correlation of the queued overlap with the source at `pos` (every 4th sample).
func _score(pos: int, ref_power: float) -> float:
	var dot := 0.0
	var power := 0.0
	var at := _wrap(pos)
	var i := 0
	while i < _overlap:
		var s := _mono[at]
		dot += _reference[i] * s
		power += s * s
		at += 4
		if at >= _len:
			at -= _len
		i += 4
	return dot / sqrt(maxf(1e-20, ref_power * power))


## Produce `frames` stereo samples.
func process(frames: int) -> PackedVector2Array:
	var out := PackedVector2Array()
	out.resize(frames)
	var moving_target := 0.0 if target_speed <= 0.0 else 1.0
	for i in frames:
		speed += (target_speed - speed) * _speed_slew
		if target_speed <= 0.0 and speed < 0.005:
			speed = 0.0
		volume += (target_volume - volume) * _gain_slew
		_motion_gain += (moving_target - _motion_gain) * _gain_slew
		if _until_grain == 0:
			_grain()
			_until_grain = _hop
		var w := _weight[_head]
		var fade := minf(1.0, _frame / (rate * 0.008))
		var g := volume * _motion_gain * fade
		if w > 1e-10:
			out[i] = Vector2(_sum_l[_head] / w * g, _sum_r[_head] / w * g)
		_sum_l[_head] = 0.0
		_sum_r[_head] = 0.0
		_weight[_head] = 0.0
		_head = (_head + 1) % _qsize
		_until_grain -= 1
		_source_pos += speed / REFERENCE_SPEED
		_frame += 1
	return out
