extends SceneTree
## Moving cab/doorway receivers, 39 m joints, approved 20-coach reference geometry.
## Use the real renderer with --write-movie and --audio-driver Dummy for offline PCM.
const Sound := preload("res://game/platform_audio.gd")
const Data := preload("res://game/body_v2_data.gd")
var failures := 0
class Listener extends Node3D:
	var pivot := Vector3.ZERO
	var distance := 5.8
	var mode := 1

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
	var output := "res://.local/onboard-ab"
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--output="): output=arg.trim_prefix("--output=")
	if capture: DirAccess.make_dir_recursive_absolute(output)
	var fixture: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://tests/fixtures/body_v2_website.json"))
	var axles: Array=[]
	for axle in fixture.consist.axles:
		axles.append({x=axle.offset,cls=int(axle.bogie)*2+int(axle.index)%2,car=int(axle.vehicle)})
	AudioServer.set_bus_volume_db(0,-80)
	var cases: Array=[]
	for kmh in [30.0,71.6,120.0]:
		for position in ["pilot","passenger"]: cases.append({speed=kmh,stem="-"+position,position=position})
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
		sound.reference_mode=false
		camera.mode=1 if test_case.position=="pilot" else 2
		sound.set_interior(true)
		sound.listener_owner=sound
		var offset: float=1.8 if camera.mode==1 else 21.99
		var height: float=3.15 if camera.mode==1 else 3.18
		var side: float=.68 if camera.mode==1 else .4
		for contact in sound.layout.contacts.benchmark:
			contact.id-=joint_id
			contact.key="benchmark:"+str(contact.id)
		if "--strikes" in OS.get_cmdline_user_args(): sound._rolling.volume_db=-100
		sound.set_process(false)
		sound.listener_override={position=Vector3(head_start-2000-offset,height,side),forward=Vector3.RIGHT,up=Vector3.UP}
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
		sound._track_sound(train.speed,kmh,0.0)
		if capture: record.set_recording_active(true)
		var elapsed:=0.0
		var clock_start:=Time.get_ticks_usec()
		var duration:=2.0 if kmh==0 else 8.0
		while elapsed<duration:
			await process_frame
			var next:=minf(duration,elapsed+1.0/120.0 if not Engine.get_write_movie_path().is_empty() else (Time.get_ticks_usec()-clock_start)/1000000.0)
			train.head_s=head_start+train.speed*next
			sound.listener_override.position=Vector3(train.head_s-2000-offset,height,side)
			sound._track_sound(train.speed,kmh,next-elapsed)
			elapsed=next
		if capture:
			record.set_recording_active(false)
			var wav:=record.get_recording()
			check(wav!=null and wav.get_length()>duration-.15,"audio capture has expected duration")
			if wav!=null: wav.save_to_wav(output+"/game-%s%skmh.wav"%[str(kmh),test_case.stem])
		var virtual:=sound.debug_events.filter(func(e): return e.virtual).size()
		check(virtual==0,"all audible contacts fit the native voice budget")
		var timing_error:=0.0
		for event in sound.debug_events:
			var joint:=int(event.contact.get_slice(":",1))
			var physical: float=(joint_s+joint*Sound.JOINT_SPACING-head_start+axles[event.axle].x)/train.speed
			timing_error=maxf(timing_error,absf(event.physical-physical))
		check(timing_error<.001,"contact rhythm follows exact axle and joint geometry")
		print("Onboard capture ", test_case, " heard ",sound.debug_events.size(), " virtual ",virtual," timing error ",timing_error)
		sound.joint_hit.disconnect(callback)
		AudioServer.remove_bus_effect(bus,AudioServer.get_bus_effect_count(bus)-1)
		sound.free(); camera.free()
		await create_timer(.2).timeout
	print("Enhanced reference audio: ",failures," failures")
	quit(1 if failures else 0)
