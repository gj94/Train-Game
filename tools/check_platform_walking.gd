extends "res://tools/check_walking_playable.gd"
## Source integration for model doors, platform collision, audio and camera shortcuts.
func _initialize() -> void:
	set_meta("route","kerala_coast");set_meta("traffic_seed",0)
	family="platform"
	call_deferred("run")

func valid_berth(car: int) -> Dictionary:
	for door in walk.platform.doors(car):
		var berth: Dictionary=walk.platform.dock(car,door)
		if not berth.is_empty() and not walk.platform.entry_point(car,door).is_empty():return berth
	return {}

func face(direction: Vector3) -> void:
	game.cam._look=Vector2(atan2(-direction.x,-direction.z),0)
	game.cam.global_transform=game.cam._target()

func left_head_out() -> void:
	await tap(JOY_BUTTON_LEFT_STICK)
	await tap(JOY_BUTTON_DPAD_RIGHT)

func rms(capture: AudioEffectCapture) -> float:
	var buffer:=capture.get_buffer(capture.get_frames_available())
	var power:=0.0
	for sample in buffer:power+=sample.length_squared()*.5
	return sqrt(power/maxi(1,buffer.size()))

func run() -> void:
	Engine.max_fps=120
	root.size=Vector2i(1280,720)
	change_scene_to_file("res://game/main.tscn")
	await process_frame;await process_frame
	game=current_scene;pad=game.controller;walk=game.walker
	game.set_physics_process(false)
	var start:=Time.get_ticks_msec()
	while game.wv.loading and Time.get_ticks_msec()-start<120000:await process_frame
	game.set_process(false);game.cam.set_process(false);pad.set_process(false)
	for sound in game.train_audio.values():sound.set_process(false);sound.set_paused(true)
	game.audio.set_paused(false)
	pad.settings_path="res://.local/platform-controller-test.cfg"
	pad.tsw_layout=true;pad.window_focus(true);pad._adopt(DEVICE);pad._set_mode(true)
	await frames()
	game.train.automatic=false;game.train.controller=-1
	for layout in [true,false]:
		pad.tsw_layout=layout
		game._pilot_camera();await frames()
		for i in 2:
			await left_head_out()
			check(game.cam.mode==3 and game.cam.head_out_side==-1,"pilot then cycle selects left head-out in either layout")
		game._head_out_camera(1,false);await frames();await left_head_out()
		check(game.cam.head_out_side==-1,"camera shortcuts work from right head-out")
		check(game.train.controller==-1 and not game.train.automatic,"camera shortcuts preserve driving handle and assignment")
	pad.tsw_layout=true
	game._pilot_camera();await frames()
	check(walk.stand(),"stand in WAP cab")
	await frames()
	var berth:=valid_berth(0)
	check(not berth.is_empty(),"source WAP door connects to a valid platform landing and interior")
	if berth.is_empty():game.queue_free();await process_frame;quit(1);return
	walk.position=walk.platform.entry_point(0,berth.door).point
	face(Vector3(berth.door.point[0]-walk.position.x,0,berth.door.point[1]-walk.position.y))
	walk.update(.016)
	check(walk.target.get("kind")=="alight","looking at actual exterior doorway offers platform interaction")
	game.train.speed=1
	check(not walk.platform.alight(berth),"cannot alight after train starts moving")
	game.train.speed=0
	walk.update(.016);walk.interact();await frames()
	check(walk.platform.outside and walk.active,"A/interaction leaves train on its platform")
	check(not game.audio._cab and game.tv.walk_car==-1 and not game.tv._interior_light.visible,"platform switches to exterior sound and glass")
	check(game.train.controller==-1 and not game.train.automatic,"alighting preserves manual assignment")
	game.cam.global_transform=game.cam._target()
	game.geographic_listener.sync(game.cam,game.wv.coordinate_origin)
	var listener: Dictionary=game.audio._listener()
	check(listener.position.distance_to(game.cam.global_position+game.wv.coordinate_origin)<.001,"track sound listener is the actual platform walker")
	var fixed: Vector3=walk.camera_transform().origin
	game.tv.cars[0].position+=Vector3(10,0,0)
	check(walk.camera_transform().origin.distance_to(fixed)<.001,"platform camera stays behind when train moves")
	game.tv.cars[0].position-=Vector3(10,0,0)
	var old_origin: Vector3=game.wv.coordinate_origin
	game.wv.coordinate_origin+=Vector3(1024,0,1024)
	check((walk.camera_transform().origin+game.wv.coordinate_origin-fixed-old_origin).length()<.001,"platform camera survives floating-origin rebase")
	game.wv.coordinate_origin=old_origin
	var surface=walk.platform.surface
	var moved: Vector2=surface.move(walk.platform.position,Vector2(0,-100))
	check(surface.allowed(moved) and moved.y>=2.22,"platform edge prevents walking into track")
	var other:=valid_berth(1)
	check(not other.is_empty(),"first coach door has an accessible landing")
	if not other.is_empty():
		walk.platform.position=other.point
		var local:=Vector3(other.door.point[0],1.3,other.door.point[1])
		face(game.tv.cars[1].to_global(local)-surface.point(other.point,old_origin))
		walk.platform._refresh=0;walk.update(.016)
		check(walk.target.get("kind")=="board" and walk.target.car==1,"platform prompt identifies the other carriage")
		game.cam.global_transform=game.cam._target();walk._fade_time=0;walk.update(.016)
		await shot("doorway")
		walk.interact();await frames()
		check(not walk.platform.outside and walk.car==1 and walk.nav.allowed(walk.position),"boarding lands inside another carriage on supported floor")
		check(game.train.controller==-1 and not game.train.automatic,"boarding does not hand over service")
		await left_head_out()
		check(not walk.active and game.cam.mode==3 and game.cam.head_out_side==-1,"camera shortcuts also work from on-foot state")
	# Native mixer output: all approved track sounds use a separate bus.
	game._pilot_camera();game.cam.global_transform=game.cam._target()
	var engine=game.traffic_presentation.roots.K1.get_node("EngineAudio")
	check(engine.sources.size()==1,"WAP motor source is local to the locomotive")
	var capture:=AudioEffectCapture.new()
	AudioServer.add_bus_effect(AudioServer.get_bus_index("Traction"),capture)
	AudioServer.set_bus_volume_db(0,-80)
	game.train.speed=0;game.train.controller=-1
	await create_timer(.6).timeout;capture.clear_buffer();await create_timer(.4).timeout
	var idle:=rms(capture)
	game.train.speed=15;game.train.controller=1
	await create_timer(.8).timeout;capture.clear_buffer();await create_timer(.4).timeout
	var powered:=rms(capture)
	check(idle>.00001 and powered>idle*1.2,"native engine PCM audible at idle and responds to power/speed")
	game.audio.set_paused(true)
	await create_timer(.2).timeout;capture.clear_buffer();await create_timer(.3).timeout
	check(rms(capture)<.00001,"pause silences engine loops")
	print("ENGINE_PCM idle=",idle," powered=",powered)
	game.train.speed=0
	for service in ["K2","K3","K5"]:
		game._select_train(service);game._render_trains(1)
		for sound in game.train_audio.values():sound.set_process(false);sound.set_paused(true)
		var reachable:=0
		for car in game.tv.cars.size():
			if valid_berth(car).is_empty():continue
			reachable+=1
		check(reachable==game.tv.cars.size(),"every car has a platform doorway in "+game.train.stock_kind+" including reversed cars")
		var motors=game.traffic_presentation.roots[service].get_node("EngineAudio")
		check(motors.sources.size()==(8 if service=="K5" else (4 if service=="K3" else 1)),"engine sources follow actual powered vehicles in "+service)
	print("Platform / controller / engine: %d checks, %d failures" % [checks,failures])
	game.queue_free();await process_frame;await process_frame
	quit(1 if failures else 0)
