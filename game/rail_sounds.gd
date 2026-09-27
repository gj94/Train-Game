extends RefCounted
## Rail-joint impact sounds — the procedural model from the user's Railway Sound Lab
## (E:\ClaudeWS\railway-clang-simulator, src/synth.js + profiles/reference.json).
##
## Resonances were measured from 168 impacts in an Indian Railways onboard recording
## (WAP-7/LHB, WAP-4/ICF). Each impact excites a 68 Hz body mode plus 24 measured
## modes with randomized contact pressure; a quieter second strike 4–7 ms later
## gives the double edge, and a short band-passed noise burst is the contact.
## synth.js runs resonators live; since they are linear, the same sound is
## pre-rendered here as a few variants and played per axle crossing.

const MIX_RATE := 44100
const RING := 0.55        # synth.js default "ring"  -> decay scale 0.4 + RING * 1.5
const ROUGHNESS := 0.4    # synth.js default "roughness"
const BODY_MODE := [68.0, 0.9, 0.035]            # [Hz, amplitude, decay s] (preset weight 1)

## [frequency Hz, amplitude, decay s] from profiles/reference.json ("reference-derived resonance").
const MODES := [
	[139.97, 0.8660, 0.1465], [193.80, 0.8103, 0.1330], [236.87, 1.0000, 0.1257],
	[285.31, 0.8277, 0.1196], [317.61, 0.8505, 0.1163], [479.11, 0.5154, 0.1052],
	[522.18, 0.5684, 0.1032], [640.61, 0.5990, 0.0986], [785.96, 0.7055, 0.0946],
	[925.93, 0.6502, 0.0916], [1162.79, 0.6618, 0.0878], [1383.51, 0.3612, 0.0852],
	[1523.47, 0.4157, 0.0839], [1808.79, 0.4042, 0.0817], [2121.02, 0.4596, 0.0797],
	[2352.50, 0.4427, 0.0786], [2659.35, 0.3512, 0.0773], [3046.95, 0.3568, 0.0759],
	[3423.78, 0.2458, 0.0748], [3671.41, 0.2261, 0.0742], [3983.64, 0.2177, 0.0735],
	[4349.71, 0.2105, 0.0728], [5593.25, 0.3720, 0.0709], [6190.80, 0.2026, 0.0702],
]


## An AudioStreamRandomizer of `variants` impacts for one resonator bank (axle 0..3).
static func joint_impacts(variants: int = 6, bank: int = 0, seed_base: int = 7319) -> AudioStreamRandomizer:
	var rnd := AudioStreamRandomizer.new()
	rnd.random_pitch = 1.0            # synth.js never pitches the metal; variation comes from the modes
	rnd.random_volume_offset_db = 0.0 # per-hit loudness is set by the caller (speed, joint irregularity)
	for v in variants:
		rnd.add_stream(v, _to_wav(impact_samples(seed_base + v * 7919 + bank * 104729, bank)))
	return rnd


## Mono float samples of one impact (primary strike + flam), peak about 0.7.
static func impact_samples(seed_value: int, bank: int = 0, length: float = 0.9) -> PackedFloat32Array:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var n := int(MIX_RATE * length)
	var out := PackedFloat32Array()
	out.resize(n)
	var modes := [BODY_MODE] + MODES
	var flam_delay := 0.004 + 0.003 * rng.randf()
	var strikes := [[0, 1.0, 0.33], [int(flam_delay * MIX_RATE), 0.27 + ROUGHNESS * 0.18, 0.18]]
	for st in strikes:
		var start: int = st[0]
		var force: float = st[1]
		for j in modes.size():
			var m: Array = modes[j]
			var f: float = m[0] * (1.0 + (bank - 1.5) * 0.004)
			var tau: float = m[2] * (0.4 + RING * 1.5)
			# Excitation as in synth.js (amplitude * 0.9 or 1.25 * 0.077), randomized contact pressure.
			var amp: float = force * m[1] * (1.25 if j > 6 else 0.9) * 0.077 * (1.0 + rng.randf_range(-1.0, 1.0) * 0.38)
			var w := TAU * f / MIX_RATE
			var decay := exp(-1.0 / (tau * MIX_RATE))
			var env := amp
			for i in range(start, n):
				out[i] += env * sin(w * (i - start + 1))
				env *= decay
				if env < 0.00002:
					break
		# Contact noise: high-passed noise burst, 8 ms decay.
		var cenv: float = force * st[2]
		var lp := 0.0
		var mid_a := 1.0 - exp(-TAU * 1800.0 / MIX_RATE)
		var cdecay := exp(-1.0 / (MIX_RATE * 0.008))
		for i in range(start, mini(n, start + int(0.06 * MIX_RATE))):
			var noise := rng.randf_range(-1.0, 1.0)
			lp += mid_a * (noise - lp)
			out[i] += (noise - lp * 0.7) * cenv
			cenv *= cdecay
	# Fade the last 60 ms and normalise.
	var fade := int(0.06 * MIX_RATE)
	for i in fade:
		out[n - 1 - i] *= float(i) / fade
	var peak := 0.0001
	for x in out:
		peak = maxf(peak, absf(x))
	for i in n:
		out[i] *= 0.7 / peak
	return out


## Per-hit loudness like synth.js: speed gain and a fixed irregularity per rail joint.
static func hit_gain(kmh: float, joint_index: int, seed_value: int = 7319) -> float:
	var speed_gain := minf(1.45, 0.3 + sqrt(maxf(0.0, kmh) / 90.0))
	var irregularity := 1.0 + ROUGHNESS * (_hash(joint_index + seed_value) - 0.5) * 0.7
	return speed_gain * irregularity


## Deterministic 0..1 hash of an integer (same idea as synth.js hash()).
static func _hash(v: int) -> float:
	var x := (v ^ 0x5bd1e995) * 0x45d9f3b & 0xFFFFFFFF
	x = ((x ^ (x >> 16)) * 0x45d9f3b) & 0xFFFFFFFF
	x = x ^ (x >> 16)
	return float(x) / 4294967296.0


static func _to_wav(samples: PackedFloat32Array) -> AudioStreamWAV:
	var data := PackedByteArray()
	data.resize(samples.size() * 2)
	for i in samples.size():
		data.encode_s16(i * 2, int(clampf(samples[i], -1.0, 1.0) * 32000.0))
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = MIX_RATE
	wav.stereo = false
	wav.data = data
	return wav
