extends RefCounted
## Procedural rail-joint impact sounds ("clack"), modal synthesis.
##
## Each impact: the wheel drops into the joint gap and strikes the next rail
## head (two transients a few ms apart). That excites a low car-body thud and a
## set of inharmonic wheel / rail resonances with different decay times — the
## metallic ring. A short baked "space" (early reflections off ballast and the
## underframe + a diffuse tail) makes it sit in the world before bus reverb.

const MIX_RATE := 44100

# Metallic modes: [frequency Hz, decay time s (to ~-60 dB), relative amplitude].
# Roughly: rail vertical bending (low hundreds), wheel radial / axial modes (kHz).
const MODES := [
	[410.0, 0.22, 0.30],
	[1180.0, 0.55, 0.34],
	[1690.0, 0.40, 0.22],
	[2470.0, 0.65, 0.26],
	[3290.0, 0.35, 0.14],
	[4380.0, 0.28, 0.10],
	[5960.0, 0.18, 0.06],
]


## Returns an AudioStreamRandomizer holding `variants` detuned impact samples.
static func joint_impacts(variants: int = 6, seed_base: int = 1000) -> AudioStreamRandomizer:
	var rnd := AudioStreamRandomizer.new()
	rnd.random_pitch = 1.04
	rnd.random_volume_offset_db = 2.0
	for v in variants:
		rnd.add_stream(v, make_impact(seed_base + v))
	return rnd


static func make_impact(seed_value: int, length: float = 0.75) -> AudioStreamWAV:
	var samples := impact_samples(seed_value, length)
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


## Mono float samples of one impact, normalised to about -3 dBFS peak.
static func impact_samples(seed_value: int, length: float = 0.75) -> PackedFloat32Array:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var n := int(MIX_RATE * length)
	var dry := PackedFloat32Array()
	dry.resize(n)

	# Two strikes: drop into the gap, then the far rail head (louder, sharper).
	var strikes := [[0.0, 0.45], [rng.randf_range(0.004, 0.009), 1.0]]
	var detune := rng.randf_range(0.96, 1.04)
	for st in strikes:
		var t0: float = st[0]
		var force: float = st[1]
		var start := int(t0 * MIX_RATE)
		# Metallic ring: each mode is an exponentially decaying sinusoid.
		for m in MODES:
			var f: float = m[0] * detune * rng.randf_range(0.985, 1.015)
			var tau: float = m[1] / 6.9                    # -60 dB decay time -> time constant
			var amp: float = m[2] * force * rng.randf_range(0.7, 1.2)
			var ph := rng.randf() * TAU
			var w := TAU * f / MIX_RATE
			var decay := exp(-1.0 / (tau * MIX_RATE))
			var env := amp
			for i in range(start, n):
				dry[i] += env * sin(ph + w * (i - start))
				env *= decay
				if env < 0.0005:
					break
		# Body thud (bogie / car body), low and short.
		var thud_f := rng.randf_range(55.0, 80.0)
		for i in range(start, mini(n, start + int(0.18 * MIX_RATE))):
			var t := float(i - start) / MIX_RATE
			dry[i] += 0.9 * force * sin(TAU * thud_f * t) * exp(-t * 26.0)
			dry[i] += 0.35 * force * sin(TAU * thud_f * 2.1 * t) * exp(-t * 40.0)
		# Contact transient: a very short click of noise.
		for i in range(start, mini(n, start + int(0.004 * MIX_RATE))):
			var t := float(i - start) / MIX_RATE
			dry[i] += 0.6 * force * rng.randf_range(-1.0, 1.0) * exp(-t * 1400.0)

	# Baked space: early reflections (ballast, sleepers, underframe) + diffuse tail.
	var out := dry.duplicate()
	for refl in [[0.0061, 0.42], [0.0113, 0.30], [0.0187, 0.22], [0.0269, 0.15], [0.0371, 0.10]]:
		var d := int(refl[0] * MIX_RATE)
		var g: float = refl[1]
		var lp := 0.0
		for i in range(n - d):
			lp += (dry[i] - lp) * 0.45                       # reflections lose top end
			out[i + d] += g * lp
	var tail_lp := 0.0
	var energy := 0.0
	for i in n:
		energy = energy * 0.9993 + absf(dry[i]) * 0.0007      # follows the dry level, ~35 ms memory
		tail_lp += (rng.randf_range(-1.0, 1.0) - tail_lp) * 0.25
		out[i] += tail_lp * energy * 0.9
	# Gentle fade to zero at the end, then normalise.
	var fade := int(0.08 * MIX_RATE)
	for i in fade:
		out[n - 1 - i] *= float(i) / fade
	var peak := 0.0001
	for x in out:
		peak = maxf(peak, absf(x))
	for i in n:
		out[i] *= 0.7 / peak
	return out
