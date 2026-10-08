extends SceneTree
var game
var service:=0
var coach:=1
const Pax:=preload("res://sim/passenger_service.gd")
func _init() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--service="):service=int(arg.trim_prefix("--service="))
		if arg.begins_with("--car="):coach=int(arg.trim_prefix("--car="))
	set_meta("route","kerala_coast");set_meta("traffic_seed",service);call_deferred("run")
func shot(name: String, eye: Vector3, target: Vector3, car: int) -> void:
	var pose: Transform3D=game.tv.cars[car].global_transform
	game.cam.global_transform=Transform3D(Basis.looking_at((pose*target-pose*eye).normalized()),pose*eye)
	for i in 45:await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://.local/r12-"+str(service)+"-"+name+".png")
	print("PAX_SHOT ",name," visible=",game.passenger_crowd.visible_count)
func run() -> void:
	game=load("res://game/main.tscn").instantiate();root.add_child(game);current_scene=game;game.paused=true
	var start:=Time.get_ticks_msec()
	while game.wv.loading and Time.get_ticks_msec()-start<120000:await process_frame
	game.cam.set_process(false);game.cam.fov=75
	var t: Train=game.train;Pax.update(game.world,t,0)
	if t.passengers.phase=="riding":Pax._begin(t,0,t.timetable.stops.size(),Pax.platform_at(game.world,t.path[0].edge))
	Pax.update(game.world,t,11);game.world.time+=11
	var car:=coach;var side: int=t.passengers.side*t.path[0].dir*int(game.tv._direction(car))
	var portal=game.tv.passenger_portals[car]
	var door_z: float=portal.positions[portal.indices(side)[0]].point[1]
	await shot("boarding",Vector3(side*5,2.7,door_z+4),Vector3(side*1.4,1.9,door_z),car)
	Pax.update(game.world,t,150);game.world.time+=150
	game.tv.passenger_on=true;game.tv.passenger_coach=car;game.tv._apply_glass()
	await shot("seated",Vector3(0,2.7,6),Vector3(0,2.5,-5),car)
	for seat in t.passengers.cars[car].seats.size():
		if t.passengers.cars[car].seats[seat]>=0:t.passengers.cars[car].seats[seat]=1
	Pax._begin(t,1,3,Pax.platform_at(game.world,t.path[0].edge));Pax.update(game.world,t,13);game.world.time+=13
	game.tv.passenger_on=false;game.tv._apply_glass()
	await shot("alighting",Vector3(side*5,2.7,door_z+4),Vector3(side*1.4,1.9,door_z),car)
	var elapsed:=0
	for i in 100:
		var tick:=Time.get_ticks_usec();game.passenger_crowd.update();elapsed+=Time.get_ticks_usec()-tick
	print("PAX_CPU_UPDATE_MS ",elapsed/100000.0," visible=",game.passenger_crowd.visible_count)
	assert(game.passenger_crowd.visible_count>0 and game.passenger_crowd.visible_count<=220)
	for openings in game.tv.passenger_portals:
		for direction in [-1,1]:
			openings.update(direction,1)
			for leaf in openings.leaves:assert(leaf.node.visible==(leaf.side==direction))
		openings.update(0,0)
	var before: int=DisplayServer.window_get_mode()
	game.display_options.settings_path="res://.local/r12-display-check.cfg"
	game.hud.show_modal("pause")
	var key:=InputEventKey.new();key.physical_keycode=KEY_F11;key.pressed=true
	Input.parse_input_event(key);Input.flush_buffered_events()
	for i in 12:await process_frame
	assert(game.display_options.is_fullscreen())
	var saved:=ConfigFile.new();assert(saved.load(game.display_options.settings_path)==OK and saved.get_value("display","fullscreen")==true)
	key=InputEventKey.new();key.physical_keycode=KEY_ENTER;key.alt_pressed=true;key.pressed=true
	Input.parse_input_event(key);Input.flush_buffered_events()
	for i in 12:await process_frame
	assert(not game.display_options.is_fullscreen() and DisplayServer.window_get_mode()==before)
	print("PASSENGERS_PLAYABLE PASS / fullscreen round trip PASS");quit()
