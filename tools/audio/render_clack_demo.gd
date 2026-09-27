extends SceneTree
## Renders an audition WAV of rail-joint clacks at a steady speed (no bus reverb).
## Usage: godot --headless --path . --script res://tools/audio/render_clack_demo.gd -- <out.wav> [kmh] [seconds]

const RailSounds := preload("res://game/rail_sounds.gd")
const TrainAudio := preload("res://game/train_audio.gd")


func _init() -> void:
	var args := OS.get_cmdline_user_args()
	var out_path: String = args[0] if args.size() > 0 else "user://clack_demo.wav"
	var kmh: float = float(args[1]) if args.size() > 1 else 70.0
	var seconds: float = float(args[2]) if args.size() > 2 else 8.0
	var rate := RailSounds.MIX_RATE
	var n := int(seconds * rate)
	var mix := PackedFloat32Array()
	mix.resize(n)
	var variants := []
	for v in 4:
		variants.append(RailSounds.impact_samples(1000 + v))
	var v := kmh / 3.6
	var axles := []
	for a in TrainAudio.NEAR_AXLES:
		axles.append([a, 1.0])
	for a in TrainAudio.FAR_AXLES:
		axles.append([a, 0.3])
	var rng := RandomNumberGenerator.new()
	for ax in axles:
		var offset: float = ax[0]
		var gain: float = ax[1]
		var k := 1
		while true:
			var t := (k * TrainAudio.JOINT_SPACING + offset) / v    # when this axle reaches joint k
			if t >= seconds:
				break
			var smp: PackedFloat32Array = variants[rng.randi() % variants.size()]
			var start := int(t * rate)
			var g := gain * rng.randf_range(0.8, 1.1)
			for i in smp.size():
				if start + i >= n:
					break
				mix[start + i] += smp[i] * g
			k += 1
	var peak := 0.0001
	for x in mix:
		peak = maxf(peak, absf(x))
	var data := PackedByteArray()
	data.resize(n * 2)
	for i in n:
		data.encode_s16(i * 2, int(mix[i] / peak * 0.8 * 32000.0))
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = rate
	wav.data = data
	var err := wav.save_to_wav(out_path)
	print("wrote ", out_path, " err=", err, " at ", kmh, " km/h")
	quit(0 if err == OK else 1)
