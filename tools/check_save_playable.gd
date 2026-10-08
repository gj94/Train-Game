extends SceneTree
## Real scene reload and controller menu tests; never launches an exported build.
const Snapshot:=preload("res://sim/world_snapshot.gd")
var game
var failures:=0
var checks:=0
const DEVICE:=16

func _initialize() -> void:
	set_meta("imported_fleet","icf");set_meta("traffic_drive",false)
	if "--traffic" in OS.get_cmdline_user_args():
		set_meta("imported_fleet","");set_meta("traffic_drive",true);set_meta("traffic_seed",0);set_meta("route","southern_corridor")
	if "--kerala" in OS.get_cmdline_user_args():set_meta("route","kerala_coast")
	call_deferred("run")

func check(value: bool, label: String) -> void:
	checks+=1
	if not value:failures+=1;printerr("SAVE_FAIL ",label)

func freeze() -> void:
	game=current_scene
	game.set_physics_process(false);game.set_process(false);game.cam.set_process(false)
	game.controller.set_process(false);game.dispatcher.set_process(false)
	for sound in game.train_audio.values():sound.set_process(false)
	game.save_load.store.directory="res://.local/save-playable/"+("kerala" if game.geographic_drive else "solo")
	game.controller.settings_path="res://.local/save-controller.cfg"
	game.controller.window_focus(true);game.controller._adopt(DEVICE);game.controller._set_mode(true)

func frames() -> void:
	await process_frame;await process_frame
	game.controller._process(.016)

func tap(button: int) -> void:
	for pressed in [true,false]:
		var event:=InputEventJoypadButton.new();event.device=DEVICE;event.button_index=button;event.pressed=pressed
		Input.parse_input_event(event);Input.flush_buffered_events();await frames()

func choose(action: String) -> void:
	for child in game.hud._buttons.get_children():
		if child.get_meta("action","")==action:
			child.grab_focus();await tap(JOY_BUTTON_A);return
	check(false,"Missing action "+action)

func screenshot() -> void:
	if DisplayServer.get_name()=="headless":return
	await process_frame;await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://.local/save-load-menu.png")

func run() -> void:
	change_scene_to_file("res://game/main.tscn");await process_frame;await process_frame
	freeze()
	if "--traffic" in OS.get_cmdline_user_args():
		var original: String=game.train.id
		var other: String=game.world.trains.keys().filter(func(id):return id!=original)[0]
		game._select_train(other)
		game.dispatcher.set_open(true);game.dispatcher.inspect_train(original)
		game.dispatcher._prompt_delete();game.dispatcher.confirm_handover();game.dispatcher.set_open(false)
		check(not game.world.trains.has(original),"Delete original assignment after handover")
	game._set_paused(false)
	game.train.controller=.42;game.train.automatic=true;game.train.speed=12.0
	game._passenger_preset(1);game.cam._look=Vector2(.6,-.12);game._set_time_scale(4)
	check(game.walker.stand(),"Stand inside the moving coach")
	game.walker.crouched=true;game.walker.eye_height=.94;game.walker.lamp_enabled=true
	game.cam._look=Vector2(.9,-.16)
	var pose: Vector2=game.walker.position;var car: int=game.walker.car
	var before:=Snapshot.capture(game.world)
	check(game.save_load.save("1").ok,"Write moving-train checkpoint")
	check(not game.paused,"Quick/direct save preserves running state")
	game._ui_action("pause");await frames()
	await choose("save:menu:save")
	check(game.hud.modal=="saved_games" and game.paused,"Controller opens save slots and pauses")
	await choose("save:save:1")
	check(game.save_load.pending.get("kind")=="save","Overwrite requires confirmation")
	check(root.gui_get_focus_owner().get_meta("action","")=="save:back","Overwrite defaults to Cancel")
	await tap(JOY_BUTTON_B)
	check(game.save_load.pending.is_empty() and game.hud.modal=="saved_games","Controller B cancels overwrite")
	await tap(JOY_BUTTON_B);await choose("save:menu:load")
	await screenshot()
	game.world.time+=100;game.train.controller=-.9
	await choose("save:load:1")
	check(game.save_load.pending.get("kind")=="load","Valid save prepared before replacement")
	check(root.gui_get_focus_owner().get_meta("action","")=="save:back","Load defaults to Cancel")
	# Invoke the same button signal without waiting on a freed controller instance.
	game._ui_action("save:confirm")
	await process_frame;await process_frame;await process_frame
	freeze()
	check(game.paused and game.hud.modal=="pause","Loaded scene is paused")
	check(var_to_bytes(before)==var_to_bytes(Snapshot.capture(game.world)),"Scene initialization preserves every railway field")
	check(game.train.automatic and game.train.controller==.42 and game.train.speed==12,"Driver, speed and handle restored")
	check(game.walker.active and game.walker.car==car and game.walker.position==pose and game.walker.crouched,"Moving coach walking position restored")
	check(game.cam._look==Vector2(.9,-.16) and game.cam.mode==4 and game.time_scale==4,"View angle and time scale restored")
	check(game.audio._cab and game.audio._paused,"Walking interior audio restored paused")
	check(not game.controller._armed and not game.walker.armed,"Held inputs neutralized after load")
	game.save_load.open("load");game.save_load.action("save:load:1");game.save_load.back()
	check(game.save_load.pending.is_empty() and game.train.controller==.42,"Cancel loading leaves current session intact")
	if game.geographic_drive:await platform_roundtrip()
	view_checks()
	print("SAVE_PLAYABLE ",checks," checks / ",failures," failed")
	quit(0 if failures==0 else 1)

func platform_roundtrip() -> void:
	game.train.speed=0;game.hud.show_modal("");game._set_paused(false);game.walker.stop();game._pilot_camera()
	check(game.walker.stand(),"Stand in cab for platform exit")
	var berth:={}
	for door in game.walker.platform.doors(0):
		berth=game.walker.platform.dock(0,door)
		if not berth.is_empty():break
	check(not berth.is_empty(),"Platform doorway available")
	if berth.is_empty():return
	check(game.walker.platform.alight(berth),"Step onto platform")
	var road: String=game.walker.platform.surface.edge;var at: Vector2=game.walker.platform.position
	check(game.save_load.save("2").ok,"Save on platform")
	game.save_load.open("load");game.save_load.action("save:load:2");game.save_load.action("save:confirm")
	await process_frame;await process_frame;await process_frame;freeze()
	check(game.walker.active and game.walker.platform.outside and game.walker.platform.surface.edge==road and game.walker.platform.position==at,"Restore platform and position")
	check(not game.audio._cab and game.cam.get_meta("on_platform",false),"Platform acoustics restored")

func view_checks() -> void:
	game.hud.show_modal("");game.walker.stop();game._head_out_camera(-1,false)
	game.cam._look=Vector2(.42,.15)
	game.walker.car=99 # stale inactive walking state after handing over to shorter stock
	var session: Dictionary=game.save_load.capture_session()
	check(game.save_load.validate_session({world=game.world,session=session}).is_empty(),"Inactive former coach does not invalidate a save")
	game._pilot_camera();game.save_load.restore_view(session)
	check(game.cam.mode==3 and game.cam.head_out_side==-1 and game.cam._look==Vector2(.42,.15),"Head-out angle and side restored")
	game.cam.set_mode(0);game._set_cab_visuals(false);game.cam.follow=false;game.cam.pivot+=Vector3(10,5,20)
	session=game.save_load.capture_session();var before: Vector3=game.cam.pivot
	game.cam.pivot=Vector3.ZERO;game.save_load.restore_view(session)
	check(game.cam.mode==0 and not game.cam.follow and game.cam.pivot.is_equal_approx(before),"Detached exterior camera position restored")
	var bad:=session.duplicate(true);bad.camera.erase("yaw")
	check(not game.save_load.validate_session({world=game.world,session=bad}).is_empty(),"Incomplete view rejected before reload")
