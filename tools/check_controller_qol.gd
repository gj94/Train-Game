extends "res://tools/check_walking_playable.gd"
## Source-scene integration for the current tap/hold/context scheme.
func _initialize() -> void:
	family="lhb"
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--fleet="):family=arg.trim_prefix("--fleet=")
	set_meta("route","southern_corridor");set_meta("imported_fleet",family);set_meta("traffic_drive",false)
	call_deferred("run")
func hold_button(id: int) -> void:
	button(id,true);pad._process(.30);await frames()
	pad._process(.40);button(id,false);await frames()
func choose(action: String) -> void:
	game.hud.focus_action(action);await frames()
	for child in game.hud._buttons.get_children():
		if child.get_meta("action","")==action:
			check(not child.disabled,"enabled "+action);child.grab_focus();await tap(JOY_BUTTON_A);return
	check(false,"missing "+action)
func capture(name: String) -> void:
	if DisplayServer.get_name()=="headless":return
	await process_frame;await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://.local/controller-"+name+".png")
func run() -> void:
	root.size=Vector2i(1280,720)
	change_scene_to_file("res://game/main.tscn");await process_frame;await process_frame
	game=current_scene;pad=game.controller;walk=game.walker
	game.set_process(false);game.set_physics_process(false);game.cam.set_process(false)
	pad.set_process(false);game.dispatcher.set_process(false);game.journey_tools.set_process(false)
	for sound in game.train_audio.values():sound.set_process(false)
	pad.settings_path="res://.local/controller-context-test.cfg"
	pad.window_focus(true);pad._adopt(DEVICE);pad._set_mode(true);game._pilot_camera();await frames()
	game.train.automatic=false;game.train.controller=.35
	button(JOY_BUTTON_DPAD_RIGHT,true);await frames()
	check(game.cam.mode==1,"D-pad press waits for tap/hold decision")
	button(JOY_BUTTON_DPAD_RIGHT,false);await frames()
	check(game.cam.mode==3 and game.cam.head_out_side==1,"right from pilot is right head-out")
	check(not game.train.automatic and game.train.controller==.35,"head-out preserves manual handle")
	for view in ["follow_close","follow_far","follow_tail","head_left","head_right"]:
		await tap(JOY_BUTTON_DPAD_RIGHT)
		check(preload("res://game/controller_camera.gd").current(game)==view,"external cycle "+view)
		check(not game.train.automatic,"external cycle retains manual driving")
	await hold_button(JOY_BUTTON_DPAD_LEFT)
	check(game.cam.mode==1 and not game.train.automatic,"horizontal hold returns pilot without AI handover")
	await tap(JOY_BUTTON_DPAD_LEFT)
	check(game.cam.mode==3 and game.cam.head_out_side==-1,"left from pilot is left head-out")
	await hold_button(JOY_BUTTON_DPAD_RIGHT)
	axis(JOY_AXIS_TRIGGER_LEFT,1);await frames()
	check(pad.drive_handle(.1,.5)==0,"trigger pauses at coast")
	check(pad.drive_handle(0,.5)==0,"held trigger stays in coast detent")
	pad._process(.26);check(pad.drive_handle(0,.5)<0,"continued trigger crosses coast after pause")
	axis(JOY_AXIS_TRIGGER_LEFT,0);axis(JOY_AXIS_TRIGGER_RIGHT,1);await frames()
	check(pad.drive_handle(0,.5)>0,"re-pull immediately crosses coast")
	axis(JOY_AXIS_TRIGGER_RIGHT,0);await frames()
	await tap(JOY_BUTTON_X)
	check(game.train.automatic and game.hud.modal=="","tap X enables AI without opening menu")
	axis(JOY_AXIS_TRIGGER_RIGHT,1);await frames();check(pad.drive_input()==0,"triggers cannot steal AI control")
	axis(JOY_AXIS_TRIGGER_RIGHT,0);await frames()
	button(JOY_BUTTON_X,true);pad._process(.3)
	check(game.train.automatic and pad._assist.visible,"hold X pending feedback")
	pad._process(.4);axis(JOY_AXIS_TRIGGER_RIGHT,1);button(JOY_BUTTON_X,false);await frames()
	check(not game.train.automatic and game.train.controller==0 and pad.drive_input()==0,"hold X takes over at coast and gates held trigger")
	axis(JOY_AXIS_TRIGGER_RIGHT,0);await frames()
	var light: int=game.tv.headlight_mode
	await tap(JOY_BUTTON_RIGHT_SHOULDER)
	check(game.tv.headlight_mode==light and game.train.controller==0,"RB does not change headlights or leave coast")
	game.train.controller=.6;button(JOY_BUTTON_RIGHT_SHOULDER,true);await frames()
	check(is_equal_approx(pad.drive_handle(.6,.2),.4) and pad.drive_handle(.1,.5)==0,"RB reduces power and clamps at coast")
	button(JOY_BUTTON_RIGHT_SHOULDER,false);await frames()
	game.train.controller=-.6;button(JOY_BUTTON_LEFT_SHOULDER,true);await frames()
	check(is_equal_approx(pad.drive_handle(-.6,.2),-.4) and pad.drive_handle(-.1,.5)==0,"LB releases brake and clamps at coast")
	button(JOY_BUTTON_LEFT_SHOULDER,false);await frames()
	game.train.automatic=true;button(JOY_BUTTON_LEFT_SHOULDER,true);await frames()
	check(pad.drive_handle(-.6,.2)==-.6 and game.train.automatic,"bumper cannot steal AI control")
	button(JOY_BUTTON_LEFT_SHOULDER,false);game.train.automatic=false;game.train.controller=0;await frames()
	await tap(JOY_BUTTON_B);check(not game.train.emergency,"B is not emergency brake")
	await tap(JOY_BUTTON_LEFT_SHOULDER);check(not game.train.emergency,"LB is not emergency brake")
	await tap(JOY_BUTTON_Y)
	check(walk.active and game.train.automatic,"Y stands and gives AI control")
	var pos: Vector2=walk.position
	axis(JOY_AXIS_LEFT_Y,-1);await frames();walk.update(.35)
	check(walk.position.distance_to(pos)>.01,"LS moves inside cab")
	await tap(JOY_BUTTON_LEFT_STICK);check(pad._running,"L3 toggles running")
	axis(JOY_AXIS_LEFT_Y,0);await frames()
	await tap(JOY_BUTTON_RIGHT_SHOULDER);check(walk.lamp_enabled,"RB torch on foot")
	await hold_button(JOY_BUTTON_X);check(game.train.automatic,"on-foot hold X cannot take over")
	await hold_button(JOY_BUTTON_DPAD_DOWN)
	check(walk.active and walk.car==(game.tv.cars.size()-1 if game.train.cab_end==2 else 0),"vertical hold returns standing loco without first visiting coach")
	await tap(JOY_BUTTON_Y)
	check(not walk.active and game.cam.mode==1 and game.train.automatic,"Y driver seat preserves AI")
	await tap(JOY_BUTTON_DPAD_DOWN)
	var first: int=game.tv.passenger_coaches()[0]
	check(walk.active and walk.car==first and game.train.automatic,"down enters first passenger coach standing")
	var first_pos: Vector2=walk.position
	axis(JOY_AXIS_LEFT_Y,1);await frames();walk.update(.35);axis(JOY_AXIS_LEFT_Y,0);await frames()
	check(walk.position.distance_to(first_pos)>.01,"LS freely walks passenger carriage")
	await tap(JOY_BUTTON_DPAD_DOWN);check(walk.car==game.tv.passenger_coaches()[1],"next tap advances exactly one coach")
	await tap(JOY_BUTTON_DPAD_UP);check(walk.car==first,"up moves exactly one coach forward")
	# Place the walker beside an available seat, then interact using the real pad.
	var seats: Array=game.tv.specs[walk.car].passengers
	var seat_ready:=false
	for i in seats.size():
		if not game.train.passengers.is_empty() and game.train.passengers.cars[walk.car].seats[i]>=0:continue
		var seat: Array=seats[i].position
		var near: Dictionary=walk.nav.nearest(Vector2(seat[0],seat[2]),false,2.5,40)
		if near.is_empty():continue
		walk.position=near.point
		var toward: Vector2=Vector2(seat[0],seat[2])-walk.position
		game.cam._look=Vector2(atan2(-toward.x,-toward.y),0);walk.update(.01)
		if walk.target.get("kind","")=="seat":seat_ready=true;break
	check(seat_ready,"available seat has an interaction position")
	await tap(JOY_BUTTON_A)
	check(game._passenger_seated() and game.train.automatic,"A sits at a passenger row")
	var seat_index: int=game.tv.passenger_seat_index
	await tap(JOY_BUTTON_DPAD_LEFT)
	check(game._passenger_head_out() and game.cam.head_out_side==-1 and game.tv.passenger_seat_index==seat_index,"left row head-out preserves seat")
	await tap(JOY_BUTTON_DPAD_RIGHT);check(game.cam.mode==2 and game._passenger_seated(),"opposite returns to row interior")
	await tap(JOY_BUTTON_DPAD_RIGHT);check(game._passenger_head_out() and game.cam.head_out_side==1,"right row head-out")
	await hold_button(JOY_BUTTON_X);check(game.train.automatic,"seated hold X is guarded")
	await tap(JOY_BUTTON_Y);check(walk.active and game.train.automatic,"Y stands from row head-out")
	await hold_button(JOY_BUTTON_DPAD_UP);await tap(JOY_BUTTON_Y)
	await hold_button(JOY_BUTTON_X);check(not game.train.automatic,"explicit takeover after returning to driver seat")
	await tap(JOY_BUTTON_DPAD_RIGHT);await tap(JOY_BUTTON_DPAD_RIGHT)
	var distance: float=game.cam.distance
	axis(JOY_AXIS_LEFT_Y,-1);axis(JOY_AXIS_LEFT_X,1);await frames();pad._process(.4)
	check(game.cam.follow and game.cam.distance<distance and not game.train.automatic,"LS adjusts follow camera without detaching or handing over")
	axis(JOY_AXIS_LEFT_Y,0);axis(JOY_AXIS_LEFT_X,0);await frames()
	game.cam._look=Vector2(1,.4);await tap(JOY_BUTTON_RIGHT_STICK)
	check(game.cam.mode==0 and game.cam.follow and game.cam._look==Vector2.ZERO,"R3 recenters instead of entering free camera")
	await tap(JOY_BUTTON_DPAD_RIGHT);await tap(JOY_BUTTON_DPAD_RIGHT)
	var session: Dictionary=game.save_load.capture_session()
	check(session.camera.follow_preset=="follow_tail" and session.view.headlight_mode==game.tv.headlight_mode,"save captures tail view and lights")
	game.save_load.restore_view(session);await frames()
	check(game.cam.follow_point.call().distance_to(game.tv.cars[-1].global_position+Vector3.UP*2)<.01,"restore anchors rear camera to rear car")
	await tap(JOY_BUTTON_B)
	button(JOY_BUTTON_BACK,true);pad._process(.3);check(pad._assist.visible,"View hold feedback")
	pad._process(.4);button(JOY_BUTTON_BACK,false);await frames()
	check(game.hud.modal=="progress" and not game.dispatcher._root.visible,"held View opens only progress")
	await tap(JOY_BUTTON_B)
	await tap(JOY_BUTTON_START)
	for i in 5:
		check(game.hud.pause_menu.page==i,"pause section via RB "+str(i))
		check(game.hud.pause_menu.actions.is_ancestor_of(root.gui_get_focus_owner()),"section owns focus")
		await tap(JOY_BUTTON_RIGHT_SHOULDER)
	check(game.hud.pause_menu.page==0,"RB wraps pause sections")
	await tap(JOY_BUTTON_LEFT_SHOULDER);check(game.hud.pause_menu.page==4,"LB wraps pause sections")
	await choose("game_speed");await choose("time:4")
	check(game.time_scale==4 and root.gui_get_focus_owner().text.begins_with("✓"),"Time speed selection marks current rate")
	await choose("time:1");await tap(JOY_BUTTON_B)
	check(game.hud.modal=="pause" and game.hud.pause_menu.page==0,"Time speed back returns to Journey")
	await choose("controller_guide")
	check(game.hud.modal=="controller_guide" and game.paused,"Pause opens dedicated control guide")
	for i in 4:
		check(game.hud.control_guide.page==i,"guide tab "+str(i))
		check(root.get_visible_rect().encloses(game.hud.control_guide.get_global_rect()),"guide fits viewport")
		await capture("guide-"+str(i))
		await tap(JOY_BUTTON_RIGHT_SHOULDER)
	await tap(JOY_BUTTON_B);check(game.hud.modal=="pause","B from guide returns to Pause")
	await choose("controllers");await choose("controller_guide");await tap(JOY_BUTTON_B)
	check(game.hud.modal=="controllers","guide opened from preferences returns to preferences")
	await tap(JOY_BUTTON_B);await choose("journey:open")
	var old: bool=game.journey_tools.show_signal_aspect
	await choose("journey:toggle:show_signal_aspect")
	check(game.journey_tools.show_signal_aspect!=old,"HUD aspect option toggles")
	# Restore the user's preference after this fixture.
	await choose("journey:toggle:show_signal_aspect")
	await capture("signal-settings")
	await tap(JOY_BUTTON_B);await tap(JOY_BUTTON_B)
	game.dispatcher.set_open(true);await frames()
	await tap(JOY_BUTTON_X)
	check(game.dispatcher.inspected_train==game.train.id and game.dispatcher._map.has_focus(),"X locates own service on map")
	await tap(JOY_BUTTON_Y);check(game.dispatcher._map.follow_train,"Y follows inspected service")
	await tap(JOY_BUTTON_Y);check(not game.dispatcher._map.follow_train,"Y unpins follow")
	for i in 4:
		await tap(JOY_BUTTON_RIGHT_SHOULDER)
		check(game.dispatcher._zone(root.gui_get_focus_owner())==posmod(i+1,4),"RB dispatcher area "+str(i))
	await tap(JOY_BUTTON_B)
	button(JOY_BUTTON_DPAD_DOWN,true);pad._process(.25);pad.window_focus(false);button(JOY_BUTTON_DPAD_DOWN,false)
	check(not walk.active and not pad._armed and not pad._assist.visible,"focus loss cancels pending D-pad tap")
	print("Controller context (%s): %d checks, %d failures" % [family,checks,failures])
	game.queue_free();current_scene=null;await process_frame;await process_frame
	quit(1 if failures else 0)
