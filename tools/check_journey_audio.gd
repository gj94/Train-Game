extends SceneTree
## Bounded five-rake acoustic integration: no scenery or passengers consume this budget.
const Sound:=preload("res://game/platform_audio.gd")
const Motion:=preload("res://game/train_motion.gd")
const Space:=preload("res://game/listening_space.gd")
const Stock:=preload("res://sim/stock/ported_stock.gd")
var game: Dictionary
var items:=[]
var capture: AudioEffectCapture
var failures:=0
var timings:=[]
var metrics:={}
var extra_timings:=[]
func _initialize() -> void:call_deferred("run")
func check(ok: bool,message: String) -> void:
	if not ok:failures+=1;printerr("FAIL ",message)
func measure() -> Dictionary:
	for item in items:item.engine._process(.01);item.air._process(.01)
	await create_timer(.3).timeout
	capture.clear_buffer();var energy:=0.0;var peak:=0.0;var samples:=0;var tail_energy:=0.0;var tail_samples:=0
	for frame in 120:
		var start:=Time.get_ticks_usec()
		var extra:=0.0
		for item in items:
			item.sound._track_sound(item.train.speed,item.train.speed*3.6,1.0/120)
			if frame%30==0 and not item.sound._paused:
				# Deliberately aligned nearby rail contacts stress simultaneous peaks.
				var contact: Dictionary=item.sound.layout.contacts[item.train.path[0].edge][69].duplicate()
				contact.key="mix-"+str(Time.get_ticks_usec());item.sound._schedule(0,contact,.06)
			var before:=Time.get_ticks_usec()
			item.engine._process(1.0/120);item.air._process(1.0/120)
			extra+=(Time.get_ticks_usec()-before)*.001
		timings.append((Time.get_ticks_usec()-start)*.001);extra_timings.append(extra)
		await create_timer(1.0/120).timeout
		var pcm:=capture.get_buffer(capture.get_frames_available())
		for sample in pcm:
			energy+=sample.length_squared()*.5;peak=maxf(peak,maxf(absf(sample.x),absf(sample.y)));samples+=1
			if frame>90:tail_energy+=sample.length_squared()*.5;tail_samples+=1
	return {rms=sqrt(energy/maxi(1,samples)),peak=peak,samples=samples,tail_rms=sqrt(tail_energy/maxi(1,tail_samples))}
func run() -> void:
	root.size=Vector2i(640,360);Engine.max_fps=120
	var prefs:=preload("res://game/audio_preferences.gd").new()
	for key in prefs.levels:prefs.levels[key]=0.0
	prefs.quiet=false;prefs.reference=false;prefs.apply();AudioServer.set_bus_volume_db(0,-80)
	var camera:=preload("res://game/camera_rig.gd").new();root.add_child(camera);camera.set_process(false);camera.mode=0;camera.make_current();camera.position=Vector3(2700,2,2.5);camera.rotation.y=PI/2
	var world:=RailWorld.new()
	game={cam=camera,world=world,audio_options=prefs,audio_space={inside=false,exposure=1.0,room=0.0,velocity=Vector3.ZERO}}
	for i in 5:
		var edge:="line"+str(i)
		world.graph.add_node(edge+"a",Vector3(0,0,i*5));world.graph.add_node(edge+"b",Vector3(6000,0,i*5));world.graph.add_edge(edge,edge+"a",edge+"b")
		var choice: String=["icf","lhb","vb8","vb16","lhb"][i]
		var train:=Train.new(str(i),Stock.length_of(choice));train.stock_kind="ported:"+choice;train.path=[{edge=edge,dir=1}];train.head_s=2800;train.speed=0 if i==0 else (20+i*5)
		world.trains[train.id]=train
		if i==0:game.train=train
		var motion:=Motion.new(train,world.graph);var cars:=[];var formation:=Stock.formation(choice);var axles:=Stock.sound_axles(choice)
		for car in formation.size():
			var node:=Node3D.new();root.add_child(node);node.position=motion.point(formation[car].center);cars.append(node)
		var view:={train=train,motion=motion,cars=cars,formation=formation}
		var sound:=Sound.new();sound.game=game;root.add_child(sound);sound.motion=motion;sound.setup(train,world,camera,axles);sound.set_process(false)
		var engine:=preload("res://game/engine_audio.gd").new();root.add_child(engine);engine.setup(game,view,sound);engine.set_process(false)
		var air:=preload("res://game/train_air_audio.gd").new();root.add_child(air);air.setup(game,view,sound);air.set_process(false)
		items.append({train=train,sound=sound,engine=engine,air=air,cars=cars})
	capture=AudioEffectCapture.new();capture.buffer_length=.5;AudioServer.add_bus_effect(AudioServer.get_bus_index("TrainOutput"),capture)
	metrics.vehicles=items.reduce(func(total,item):return total+item.cars.size(),0)
	metrics.traction_emitters=items.reduce(func(total,item):return total+item.engine.sources.size(),0)
	metrics.outside=await measure()
	game.audio_space=Space.compartment("vb_dtc",Vector3(0,2,8),24,0);game.audio_space.velocity=Vector3.ZERO;game.audio_space.car=0
	camera.mode=1
	metrics.sealed=await measure()
	check(metrics.outside.rms>metrics.sealed.rms*1.7,"closed cab attenuates four passing sources")
	check(metrics.outside.peak<1 and metrics.sealed.peak<1,"five trains do not clip output")
	check(metrics.outside.samples>20000 and metrics.outside.rms>.001,"native mixer produced audible signal")
	var train: Train=game.train;var engine=items[0].engine;var track=items[0].sound
	train.automatic=true
	train.horn_sequence+=1;train.horn_emitted_at=world.clock_seconds();engine._process(.01)
	check(engine.horn_player.playing,"first departure horn plays")
	world.time+=1.2;engine._process(.01);check(not engine.horn_player.playing,"first departure horn releases")
	world.time+=2.3;train.horn_sequence+=1;train.horn_emitted_at=world.clock_seconds();engine._process(.01)
	check(engine.horn_player.playing,"second departure horn plays after gap")
	train.automatic=false;engine._process(.01)
	check(not engine.horn_player.playing,"manual takeover stops automatic horn")
	world.time+=3.5;train.horn_sequence+=1;train.horn_emitted_at=world.clock_seconds()
	train.horn_pending_at=world.clock_seconds()+3.5;engine._process(.01)
	check(not engine.horn_player.playing,"manual departure does not sound automatic horn")
	train.automatic=true;world.time+=3.5;train.horn_sequence+=1
	train.horn_pending_at=-1;train.horn_emitted_at=world.clock_seconds();engine._process(.01)
	check(not engine.horn_player.playing,"takeover cancels pending second call after handback")
	train.automatic=false;engine.horn();engine._process(.01)
	check(engine.horn_player.playing,"manual horn button still works under manual control")
	engine.horn_player.stop()
	for item in items:item.sound.set_paused(true)
	metrics.paused=await measure()
	check(metrics.paused.tail_rms<.00001,"pause silences all train layers")
	extra_timings.sort();metrics.new_layers_ms={median=extra_timings[extra_timings.size()/2],p99=extra_timings[int(extra_timings.size()*.99)]}
	timings.sort();metrics.cpu_ms={median=timings[timings.size()/2],p99=timings[int(timings.size()*.99)],max=timings[-1]};metrics.failures=failures
	FileAccess.open("res://.local/r33/five-train-audio.json",FileAccess.WRITE).store_string(JSON.stringify(metrics,"  "));print("FIVE_TRAIN_AUDIO ",JSON.stringify(metrics))
	for item in items:
		item.engine.free();item.air.free();item.sound.free()
		for car in item.cars:car.free()
	camera.free();items.clear();game.clear();capture=null;call_deferred("finish")
func finish() -> void:
	# Let native audio consume the queued stop/free commands before exiting.
	await create_timer(.3).timeout
	quit(failures)
