extends SceneTree
## Native fixed-position passenger audio: head rotations, independent rail/air PCM.
const Sound := preload("res://game/platform_audio.gd")
const Stock := preload("res://sim/stock/ported_stock.gd")
const Space := preload("res://game/listening_space.gd")
var game: Dictionary
var sounds := []
var airs := []
var cars := []
var captures := {}
var report := {cases=[],failures=[]}
var output := "res://.local/realism-2026-10-26/passenger-sound.json"
var sound_script=Sound
var late_only:=false

func _initialize() -> void: call_deferred("run")

func check(ok: bool, message: String) -> void:
	if not ok: report.failures.append(message); printerr("FAIL ",message)

func tick(delta: float) -> void:
	for sound in sounds: sound._track_sound(sound.train.speed,sound.train.speed*3.6,delta)
	for air in airs: air._process(delta)

func measure() -> Dictionary:
	var sums := {}
	for name in captures:
		captures[name].clear_buffer(); sums[name]={energy=0.0,left=0.0,right=0.0,peak=0.0,samples=0}
	for frame in 150:
		tick(1.0/120)
		if frame%30==0:
			var sound = sounds[1]
			var contact: Dictionary=sound.layout.contacts["line1"][69].duplicate()
			contact.key="probe-"+str(Time.get_ticks_usec())
			sound._schedule(0,contact,.06)
		await create_timer(1.0/120).timeout
		for name in captures:
			var pcm: PackedVector2Array=captures[name].get_buffer(captures[name].get_frames_available())
			var row: Dictionary=sums[name]
			for sample in pcm:
				row.energy+=sample.length_squared()*.5; row.left+=sample.x*sample.x; row.right+=sample.y*sample.y
				row.peak=maxf(row.peak,maxf(absf(sample.x),absf(sample.y)));row.samples+=1
	for row in sums.values():
		row.rms=sqrt(row.energy/maxi(1,row.samples)); row.left=sqrt(row.left/maxi(1,row.samples));row.right=sqrt(row.right/maxi(1,row.samples))
		row.erase("energy")
	return sums

func run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--output="): output=arg.trim_prefix("--output=")
		elif arg.begins_with("--sound-script="): sound_script=load(arg.trim_prefix("--sound-script="))
		elif arg=="--late-only":late_only=true
	root.size=Vector2i(640,360);Engine.max_fps=120
	var prefs:=preload("res://game/audio_preferences.gd").new("res://.local/realism-2026-10-26/no-audio-preferences.cfg")
	for key in prefs.levels:prefs.levels[key]=0.0;prefs.muted[key]=false
	prefs.quiet=false;prefs.reference=false;prefs.headphones=false;prefs.apply();AudioServer.set_bus_volume_db(0,-80)
	var camera:=preload("res://game/camera_rig.gd").new();root.add_child(camera);camera.set_process(false);camera.mode=2;camera.make_current()
	camera.position=Vector3(2700,2,1.1)
	var world:=RailWorld.new()
	game={cam=camera,world=world,audio_options=prefs,audio_space=Space.compartment("icf_sl",Vector3(1.1,2,0),22.297,0)}
	game.audio_space.velocity=Vector3.ZERO;game.audio_space.car=4
	for i in 2:
		var edge:="line"+str(i)
		world.graph.add_node(edge+"a",Vector3(0,0,i*5));world.graph.add_node(edge+"b",Vector3(6000,0,i*5));world.graph.add_edge(edge,edge+"a",edge+"b")
		var train:=Train.new(str(i),Stock.length_of("icf"));train.stock_kind="ported:icf";train.path=[{edge=edge,dir=1}];train.head_s=2800;train.speed=0 if i==0 else 30.0
		world.trains[train.id]=train
		if i==0:game.train=train
		var motion:=preload("res://game/train_motion.gd").new(train,world.graph)
		var formation:=Stock.formation("icf");var rake:=[]
		for spec in formation:
			var car:=Node3D.new();root.add_child(car);car.position=motion.point(spec.center);car.rotation.y=-PI/2;rake.append(car);cars.append(car)
		var view:={train=train,motion=motion,cars=rake,formation=formation}
		var sound=sound_script.new();sound.game=game;root.add_child(sound);sound.motion=motion;sound.setup(train,world,camera,Stock.sound_axles("icf"));sound.set_process(false);sounds.append(sound)
		var air:=preload("res://game/train_air_audio.gd").new();root.add_child(air);air.setup(game,view,sound);air.set_process(false);airs.append(air)
	for sound in sounds:sound.listener_owner=sounds[0]
	for name in ["RailRolling","RailImpacts","PassingAir","TrainOutput"]:
		var capture:=AudioEffectCapture.new();capture.buffer_length=.5;AudioServer.add_bus_effect(AudioServer.get_bus_index(name),capture);captures[name]=capture
	for yaw in ([] if late_only else [0,45,90,135,180,225,270,315,360]):
		camera.rotation=Vector3(0,deg_to_rad(yaw),0)
		for frame in 45:tick(1.0/120);await create_timer(1.0/120).timeout
		var result:=await measure()
		report.cases.append({yaw=yaw,pcm=result,paused=sounds[1]._paused,events=sounds[1].debug_events.size()})
		check(result.RailRolling.samples>20000 and result.RailRolling.rms>.00001,"audible rail PCM at yaw "+str(yaw))
		print("PASSENGER_SOUND yaw=",yaw," ",JSON.stringify(result))
	var min_rail:=INF;var max_rail:=0.0
	for row in report.cases:min_rail=minf(min_rail,row.pcm.RailRolling.rms);max_rail=maxf(max_rail,row.pcm.RailRolling.rms)
	if not late_only:
		report.rotation_rail_min_max_ratio=min_rail/maxf(.000001,max_rail)
		check(report.rotation_rail_min_max_ratio>.75,"head rotation preserves rolling energy")
	# A late physical contact must seek into its remaining 341ms kernel, even
	# when a slow rendering frame missed the old 40ms acceptance window.
	tick(.01)
	for sound in sounds:sound._cancel_events(true)
	await create_timer(.5).timeout
	var capture: AudioEffectCapture=captures.RailImpacts;capture.clear_buffer()
	var late_sound=sounds[1]
	var contact: Dictionary=late_sound.layout.contacts.line1[69].duplicate()
	contact.key="late-decay";contact.source=camera.global_position+Vector3(0,-1,3)
	late_sound._schedule(0,contact,-.12)
	var event: Dictionary=late_sound._events.back()
	var late:={virtual=event.virtual,offset=event.get("offset",-1),channels=event.ids.size()}
	await create_timer(.3).timeout
	var energy:=0.0;var peak:=0.0;var pcm: PackedVector2Array=capture.get_buffer(capture.get_frames_available())
	for sample in pcm:energy+=sample.length_squared()*.5;peak=maxf(peak,maxf(absf(sample.x),absf(sample.y)))
	late.rms=sqrt(energy/maxi(1,pcm.size()));late.peak=peak;late.samples=pcm.size();report.late_decay=late
	check(not late.virtual and late.channels==2 and late.rms>.00001,"120ms late contact retains audible native decay")
	print("LATE_DECAY ",JSON.stringify(late))
	FileAccess.open(output,FileAccess.WRITE).store_string(JSON.stringify(report,"  "))
	for air in airs:air.free()
	for sound in sounds:sound.free()
	for car in cars:car.free()
	camera.free();sounds.clear();airs.clear();cars.clear();game.clear();captures.clear()
	await create_timer(.3).timeout
	quit(report.failures.size())
