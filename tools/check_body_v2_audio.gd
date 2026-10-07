extends SceneTree
## Real native playback using the approved website's exact benchmark geometry.
const Sound := preload("res://game/body_v2_audio.gd")
const Data := preload("res://game/body_v2_data.gd")
var failures := 0
class Listener extends Node3D:
	var pivot := Vector3.ZERO
	var distance := 5.8

func _initialize() -> void:
	root.content_scale_size=Vector2i(16,16)
	root.size=Vector2i(16,16)
	call_deferred("run_check")

func check(ok: bool,message: String) -> void:
	if not ok:
		failures+=1
		printerr("FAIL: ",message)

func run_check() -> void:
	Engine.max_fps=120
	root.size=Vector2i(16,16)
	var capture := "--capture" in OS.get_cmdline_user_args()
	var fixture: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://tests/fixtures/body_v2_website.json"))
	var axles: Array=[]
	for axle in fixture.consist.axles:
		axles.append({x=axle.offset,cls=int(axle.bogie)*2+int(axle.index)%2,car=int(axle.vehicle)})
	AudioServer.set_bus_volume_db(0,-80)
	var cases: Array=[]
	for kmh in [0.0,30.0,71.6,120.0]: cases.append({speed=kmh,stem=""})
	if "--stems" in OS.get_cmdline_user_args():
		for kmh in [30.0,71.6,120.0]:
			for stem in ["-strikes","-rolling"]: cases.append({speed=kmh,stem=stem})
	for test_case in cases:
		var kmh: float=test_case.speed
		var world:=RailWorld.new()
		world.graph.add_node("a",Vector3(-2000,0,0))
		world.graph.add_node("b",Vector3(2000,0,0))
		world.graph.add_edge("benchmark","a","b")
		var joint_id:=51
		var joint_s: float=Sound.JOINT_OFFSET+joint_id*Sound.JOINT_SPACING
		var joint_world:=Vector3(joint_s-2000,0,0)
		var train:=Train.new("body_probe",fixture.consist.length)
		train.path=[{edge="benchmark",dir=1}]
		train.speed=kmh/3.6
		var first: float=fixture.consist.axles[6].offset
		train.head_s=joint_s+first-train.speed
		var head_start:=train.head_s
		var camera:=Listener.new()
		root.add_child(camera)
		camera.pivot=joint_world
		var sound:=Sound.new()
		root.add_child(sound)
		sound.setup(train,world,camera,axles)
		if test_case.stem=="-strikes": sound._rolling.volume_db=-100
		if test_case.stem=="-rolling": sound._track.volume_db=-100
		sound.set_process(false)
		sound.listener_override={position=joint_world+Vector3(3.8,2.73,5.8),forward=Vector3(-27.8,-.43,-5.8).normalized(),up=Vector3.UP}
		sound.joint_override={edge="benchmark",joint=joint_id,point=joint_world,tangent=Vector3.RIGHT}
		check(sound._kernels.size()==8,"all approved BODY V2 variants load")
		check(sound._bogies.size()==42,"rolling radiates from the exact 42 website bogies")
		var identities:=sound._identities
		for i in axles.size():
			var a: Dictionary=fixture.consist.axles[i]
			check(identities[i].variant==posmod(int(a.vehicle)*3+int(a.bogie)*2+int(a.index),8),"variant agrees with website axle identity")
			check(absf(identities[i].load-a.load)<.000001,"axle load agrees with website")
		var hits: Array=[]
		var callback:=func(edge: String,joint: int,cls: int): hits.append({edge=edge,joint=joint,cls=cls,head=train.head_s})
		sound.joint_hit.connect(callback)
		var bus:=AudioServer.get_bus_index(Sound.BUS)
		check(AudioServer.get_bus_effect_count(bus)==1 and AudioServer.get_bus_effect(bus,0) is AudioEffectCompressor,"approved dynamics without old EQ or reverb")
		var record:=AudioEffectRecord.new()
		record.format=AudioStreamWAV.FORMAT_16_BITS
		AudioServer.add_bus_effect(bus,record)
		sound._track_sound(train.speed,kmh)
		if capture: record.set_recording_active(true)
		var elapsed:=0.0
		var clock_start:=Time.get_ticks_usec()
		var duration:=2.0 if kmh==0 else 8.0
		while elapsed<duration:
			await process_frame
			var next:=minf(duration,elapsed+1.0/120.0 if not Engine.get_write_movie_path().is_empty() else (Time.get_ticks_usec()-clock_start)/1000000.0)
			train.head_s=head_start+train.speed*next
			sound._track_sound(train.speed,kmh,next-elapsed)
			elapsed=next
		if capture:
			record.set_recording_active(false)
			var wav:=record.get_recording()
			check(wav!=null and wav.get_length()>duration-.15,"audio capture has expected duration")
			if wav!=null: wav.save_to_wav("res://.local/body-v2-ab/game-%s%skmh.wav"%[str(kmh),test_case.stem])
		var expected:=0
		if kmh>0:
			for a in axles:
				var start: float=head_start-a.x+train.speed*(Data.KERNEL_LEAD+Data.LOOKAHEAD)
				var end: float=train.head_s-a.x+train.speed*(Data.KERNEL_LEAD+Data.LOOKAHEAD)
				if start<joint_s and end>=joint_s: expected+=1
		check(hits.size()==expected,"exactly one contact per axle at the listening joint; %d vs %d"%[hits.size(),expected])
		print("BODY V2 runtime: ",kmh," km/h; ",hits.size()," contacts; expected ",expected)
		sound.joint_hit.disconnect(callback)
		AudioServer.remove_bus_effect(bus,AudioServer.get_bus_effect_count(bus)-1)
		sound.free(); camera.free()
		await create_timer(.2).timeout
	print("BODY V2 audio: ",failures," failures")
	quit(1 if failures else 0)
