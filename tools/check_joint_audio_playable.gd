extends SceneTree
## Exercise the real TrainAudio players and scheduler on a straight test track.
## Runs at real elapsed time; -- --capture additionally saves the Train bus output.
const Sound := preload("res://game/train_audio.gd")
const Data := preload("res://game/joint_video_model_data.gd")
const Layout := preload("res://game/rail_joint_layout.gd")
var failures := 0

class Listener extends Node3D:
	var pivot := Vector3.ZERO
	var distance := 3.0


func _initialize() -> void:
	call_deferred("run_check")


func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		printerr("FAIL: ",message)


func run_check() -> void:
	var capture := "--capture" in OS.get_cmdline_user_args()
	var world := RailWorld.new()
	world.graph.add_node("a",Vector3.ZERO)
	world.graph.add_node("b",Vector3(5000,0,0))
	world.graph.add_edge("audio_probe","a","b")
	var train := Train.new("audio_probe",24.0)
	train.path = [{edge="audio_probe",dir=1}]
	train.head_s = 400.0
	var camera := Listener.new()
	root.add_child(camera)
	var audio := Sound.new()
	root.add_child(audio)
	var axles := [{x=4.0,cls=0,car=1},{x=6.56,cls=1,car=1},{x=18.9,cls=2,car=1},{x=21.46,cls=3,car=1}]
	audio.setup(train,world,camera,axles)
	audio.set_process(false)
	audio.set_interior(false)
	check(audio._kernels.size()==28,"all approved strikes loaded")
	check(audio._rolling.stream.loop_mode==AudioStreamWAV.LOOP_FORWARD,"only the rolling layer loops")
	check(audio._rolling.pitch_scale==1 and audio._track.pitch_scale==1,"players keep the original sound pitch")
	var record := AudioEffectRecord.new()
	record.format = AudioStreamWAV.FORMAT_16_BITS
	var bus := AudioServer.get_bus_index("Train")
	AudioServer.add_bus_effect(bus,record)
	AudioServer.set_bus_volume_db(0,-80) # Silent validation; record before Master volume.
	var reports := []
	for kmh in [0.0,30.0,60.0,120.0]:
		train.head_s = 400.0
		train.speed = kmh/3.6
		audio.reset_positions()
		audio._track.stop()
		audio._track.play()
		audio._track_pb = audio._track.get_stream_playback()
		camera.pivot = Vector3(train.head_s-12.73,0,0)
		audio._track_sound(train.speed,kmh)
		var hits := []
		var callback := func(edge: String,joint: int,cls: int):
			hits.append({edge=edge,joint=joint,cls=cls,head_s=train.head_s})
		audio.joint_hit.connect(callback)
		var seconds := 2.0 if kmh==0 else 4.0
		var elapsed := 0.0
		var clock_start := Time.get_ticks_usec()
		if capture: record.set_recording_active(true)
		while elapsed < seconds:
			await process_frame
			var next := (Time.get_ticks_usec()-clock_start)/1000000.0
			var dt := minf(next-elapsed,seconds-elapsed)
			elapsed += dt
			train.advance(world.graph,train.speed*dt)
			camera.pivot = Vector3(train.head_s-12.73,0,0)
			audio._track_sound(train.speed,kmh)
		if capture:
			record.set_recording_active(false)
			var wav := record.get_recording()
			check(wav != null and wav.get_length() > seconds-.15,"Train bus produces an audio recording")
			if wav != null:
				var path := "res://.local/audio-preview/game-joints-%dkmh.wav" % int(kmh)
				check(wav.save_to_wav(path)==OK,"saved runtime audio preview")
		audio.joint_hit.disconnect(callback)
		if kmh==0:
			check(hits.is_empty(),"stopped wheels produce no impacts")
			check(audio._rolling.volume_db < -79,"rolling fades at standstill")
		else:
			check(hits.size()>=4,"moving coach generates physical joint contacts")
			for h in hits:
				var at: float = Layout.OFFSET+h.joint*Layout.SPACING
				var wheel: float = h.head_s-axles[h.cls].x
				check(absf(wheel-at) <= train.speed*(Data.KERNEL_LEAD+.035),"strike is at the axle's visible joint, within frame/lead compensation")
		reports.append({kmh=kmh,hits=hits.size(),pair_interval_seconds=2.56/(kmh/3.6) if kmh>0 else 0.0})
	print("Joint audio runtime: ",JSON.stringify({failures=failures,capture=capture,cases=reports}))
	AudioServer.remove_bus_effect(bus,AudioServer.get_bus_effect_count(bus)-1)
	audio._track.stop()
	audio._rolling.stop()
	audio._track_pb = null
	await create_timer(.2).timeout
	audio.free()
	camera.free()
	await process_frame
	quit(1 if failures else 0)
