extends "res://tools/check_walking_playable.gd"
## Native input/GUI regression against the source scene, not an exported build.
func _initialize() -> void:
	set_meta("route","southern_corridor");set_meta("imported_fleet","lhb");set_meta("traffic_drive",false)
	call_deferred("run")

func choose(action: String) -> void:
	for child in game.hud._buttons.get_children():
		if child.get_meta("action","")==action:
			check(not child.disabled,"enabled action "+action)
			child.grab_focus();await tap(JOY_BUTTON_A);return
	check(false,"missing action "+action)

func capture(name: String) -> void:
	if DisplayServer.get_name()=="headless":return
	await process_frame;await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://.local/controller-qol-"+name+".png")

func run() -> void:
	root.size=Vector2i(1280,720)
	change_scene_to_file("res://game/main.tscn");await process_frame;await process_frame
	game=current_scene;pad=game.controller;walk=game.walker
	game.set_process(false);game.set_physics_process(false);game.cam.set_process(false)
	pad.set_process(false);game.dispatcher.set_process(false)
	for sound in game.train_audio.values():sound.set_process(false)
	pad.settings_path="res://.local/controller-qol-test.cfg"
	pad.tsw_layout=true;pad.window_focus(true);pad._adopt(DEVICE);pad._set_mode(true);await frames()
	game._pilot_camera();await frames()
	game.train.automatic=false;game.train.controller=.35
	await tap(JOY_BUTTON_X)
	check(game.paused and game.hud.modal=="controller_actions","tap X opens paused quick actions")
	check(game.hud._buttons.get_child(0).get_meta("action")=="pad_back","safe resume is initially selected")
	check(root.get_visible_rect().encloses(game.hud._dialog.get_global_rect()),"menu fits the logical canvas at 720p output")
	await capture("actions")
	await choose("view_controls");await choose("passengers");await choose("coaches")
	await tap(JOY_BUTTON_B);check(game.hud.modal=="passengers","coach list Back returns to passenger menu")
	check(root.gui_get_focus_owner().get_meta("action","")=="coaches","parent remembers focused coach-list row")
	await tap(JOY_BUTTON_B);check(game.hud.modal=="view_controls","passenger Back returns to camera menu")
	await tap(JOY_BUTTON_B);check(game.hud.modal=="controller_actions","camera Back returns to quick actions")
	check(root.gui_get_focus_owner().get_meta("action","")=="view_controls","quick actions remembers camera row")
	await choose("sound_controls");await choose("audio:open");await choose("audio:levels");await choose("audio:layer:rolling")
	await tap(JOY_BUTTON_B);check(game.hud._heading.text=="AUDIO LAYERS","audio layer Back returns to layer list")
	await tap(JOY_BUTTON_B);check(game.hud._heading.text=="AUDIO","audio levels Back returns to root")
	await tap(JOY_BUTTON_B);check(game.hud.modal=="sound_controls","audio root Back returns to its caller")
	await tap(JOY_BUTTON_B);await choose("view_controls");await choose("journey:open")
	await tap(JOY_BUTTON_B);check(game.hud.modal=="view_controls","journey tools Back returns to cameras")
	await tap(JOY_BUTTON_B)
	await tap(JOY_BUTTON_B);check(not game.paused and game.hud.modal=="","Back from gameplay X menu resumes directly")
	await tap(JOY_BUTTON_X);await choose("padcmd:ai")
	check(game.train.automatic and not game.paused and "AI driving" in game.hud._toast.text,"visible quick action hands driving to AI with feedback")
	button(JOY_BUTTON_X,true);pad._process(.25)
	check(pad._assist.visible and "Take over driving" in pad._assist.detail.text,"held X shows current-state shortcut legend")
	var look: Vector2=game.cam._look
	axis(JOY_AXIS_LEFT_Y,-1);axis(JOY_AXIS_RIGHT_X,1);pad._process(.2);walk.update(.2)
	check(not walk.active and game.cam._look==look,"held X absorbs both sticks without walking or looking")
	axis(JOY_AXIS_LEFT_Y,0);axis(JOY_AXIS_RIGHT_X,0)
	await capture("shortcuts")
	button(JOY_BUTTON_A,true);button(JOY_BUTTON_A,false)
	check(not game.train.automatic,"X+A takes over through guarded path")
	axis(JOY_AXIS_TRIGGER_RIGHT,1);button(JOY_BUTTON_X,false);pad._process(.1)
	check(not pad._armed and pad.drive_input()==0 and not pad._assist.visible,"chord release blocks held trigger and hides assist")
	axis(JOY_AXIS_TRIGGER_RIGHT,0);await frames()
	button(JOY_BUTTON_BACK,true);pad._process(.25)
	check(pad._assist.visible and pad._assist.progress.visible,"View hold shows progress before opening journey")
	pad._process(.35);button(JOY_BUTTON_BACK,false);await frames()
	check(game.hud.modal=="progress" and not game.dispatcher._root.visible,"held View opens progress without dispatch tap")
	await tap(JOY_BUTTON_B)
	await tap(JOY_BUTTON_DPAD_DOWN)
	game.tv.passenger_seat=true;game.tv.passenger_seat_index=0;game._passenger_seating_changed();await frames()
	check(game._passenger_seated() and game.train.automatic,"passenger fixture holds AI lock")
	button(JOY_BUTTON_X,true);pad._process(.25);button(JOY_BUTTON_A,true);button(JOY_BUTTON_A,false)
	check(game.train.automatic and game._passenger_seated(),"X+A cannot switch seated passenger to manual")
	button(JOY_BUTTON_X,false);await frames()
	await tap(JOY_BUTTON_X)
	for child in game.hud._buttons.get_children():
		if child.get_meta("action","") in ["padcmd:ai","padcmd:coast","padcmd:horn","padcmd:emergency"]:check(child.disabled,"seated quick driving action is disabled")
	await capture("passenger-actions")
	await tap(JOY_BUTTON_B)
	var coach: int=game.tv.passenger_coach
	await tap(JOY_BUTTON_DPAD_LEFT);check(game._passenger_head_out() and game.tv.passenger_coach==coach,"seated left head-out stays at passenger row")
	await tap(JOY_BUTTON_DPAD_RIGHT);check(game.cam.mode==2 and game._passenger_seated(),"seated right returns to same seat")
	await tap(JOY_BUTTON_LEFT_STICK)
	button(JOY_BUTTON_RIGHT_STICK,true);axis(JOY_AXIS_TRIGGER_RIGHT,1)
	pad._process(.3);check(pad._assist.visible and pad._assist.progress.value>0,"first RS hold displays gesture progress")
	var eye: Vector3=game.cam.pivot;var fov: float=game.cam.free_fov
	pad._process(.4)
	check(pad._free_train_controls and game.cam.pivot==eye and game.cam.free_fov==fov,"first RS hold switches mode without moving or zooming")
	check(pad.drive_input()==0,"mode switch blocks held zoom trigger")
	await capture("hold-complete")
	button(JOY_BUTTON_RIGHT_STICK,false);axis(JOY_AXIS_TRIGGER_RIGHT,0);await frames()
	axis(JOY_AXIS_TRIGGER_RIGHT,.8);check(pad.drive_input()>0,"fresh trigger works after full release")
	axis(JOY_AXIS_TRIGGER_RIGHT,0);await frames()
	button(JOY_BUTTON_X,true);pad._process(.25)
	axis(JOY_AXIS_LEFT_X,1);axis(JOY_AXIS_RIGHT_X,1);pad._process(.2)
	check(game.cam.pivot==eye,"held X blocks free-camera movement too")
	pad.window_focus(false);button(JOY_BUTTON_X,false)
	check(not pad._assist.visible and not pad._armed and game.hud.modal=="","focus loss cancels pending shortcut without opening menu")
	axis(JOY_AXIS_LEFT_X,0);axis(JOY_AXIS_RIGHT_X,0);pad.window_focus(true);await frames()
	await tap(JOY_BUTTON_START);await choose("controller_actions");await choose("controllers")
	await tap(JOY_BUTTON_B);check(game.hud.modal=="controller_actions","settings Back uses actual quick-menu parent")
	await tap(JOY_BUTTON_B);check(game.paused and game.hud.modal=="pause","quick actions entered from Pause return paused")
	print("Controller QoL: %d checks, %d failures" % [checks,failures])
	game.queue_free();current_scene=null;await process_frame;await process_frame
	quit(1 if failures else 0)
