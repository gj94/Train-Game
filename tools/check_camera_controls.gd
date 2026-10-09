extends "res://tools/check_walking_playable.gd"
## Real viewport gamepad events against both layouts, including walking and UI isolation.
func _initialize() -> void:
	family="lhb"
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--fleet="):family=arg.trim_prefix("--fleet=")
	set_meta("imported_fleet",family);set_meta("traffic_drive",false)
	call_deferred("run")

func pose() -> Array:
	match game.cam.mode:
		0:return [0,game.cam.follow]
		1:return [1,game.tv.cab_position]
		2:return [2,game.tv.passenger_coach]
		3:return [3,game.cam.head_out_side]
	return [game.cam.mode]

func run() -> void:
	Engine.max_fps=120
	change_scene_to_file("res://game/main.tscn")
	await process_frame;await process_frame
	game=current_scene;pad=game.controller;walk=game.walker
	game.set_process(false);game.set_physics_process(false);game.cam.set_process(false)
	pad.set_process(false);game.dispatcher.set_process(false)
	for sound in game.train_audio.values():sound.set_process(false)
	pad.settings_path="res://.local/camera-controller-test.cfg"
	pad.window_focus(true);pad._adopt(DEVICE);pad._set_mode(true)
	game.train.automatic=true;game.train.controller=.35
	var coaches: Array=game.tv.passenger_coaches()
	var expected: Array=[[1,0],[3,1]]
	if family=="lhb":expected.append_array([[1,1],[1,2],[1,3]])
	expected.append_array([[2,coaches[0]],[2,coaches[(coaches.size()-1)/2]],[2,coaches[-1]],[0,true],[0,false],[3,-1]])
	for layout in [true,false]:
		pad.tsw_layout=layout;game._pilot_camera();await frames()
		for direction in [1,-1]:
			for step in range(1,expected.size()+1):
				await tap(JOY_BUTTON_DPAD_RIGHT if direction==1 else JOY_BUTTON_DPAD_LEFT)
				check(pose()==expected[posmod(step*direction,expected.size())],"both-direction camera cycle: "+str(pose()))
		for index in expected.size():
			game._pilot_camera();await frames()
			for step in index:await tap(JOY_BUTTON_DPAD_RIGHT)
			await tap(JOY_BUTTON_LEFT_STICK)
			check(pose()==[1,0],"L3 always returns to pilot")
			for step in index:await tap(JOY_BUTTON_DPAD_RIGHT)
			await tap(JOY_BUTTON_RIGHT_STICK);await tap(JOY_BUTTON_RIGHT_STICK)
			check(pose()==[0,false],"R3 is immediate and idempotent free camera")
		check(game.train.automatic and game.train.controller==.35,"camera changes preserve AI and traction")
		var pivot: Vector3=game.cam.pivot
		game.cam.follow_point=func():return pivot+Vector3(100,0,0)
		game.cam._process(1)
		check(game.cam.pivot==pivot,"free camera does not follow a moving train")
		game.cam.follow_point=game.tv.overview_position
		await tap(JOY_BUTTON_LEFT_STICK)
		check(walk.stand(),"stand for on-foot camera shortcuts");await frames()
		await tap(JOY_BUTTON_B);check(walk.active and walk.crouched,"B crouches without leaving walking")
		var lamp_before: bool=walk.lamp_enabled
		button(JOY_BUTTON_X,true);await tap(JOY_BUTTON_DPAD_UP);button(JOY_BUTTON_X,false);await frames()
		check(walk.active and walk.lamp_enabled!=lamp_before,"X plus D-pad up operates walking lamp")
		axis(JOY_AXIS_TRIGGER_RIGHT,1);axis(JOY_AXIS_LEFT_Y,-1)
		await tap(JOY_BUTTON_LEFT_STICK)
		check(not walk.active and pose()==[1,0] and pad.drive_input()==0,"pilot return blocks held walking/run input")
		axis(JOY_AXIS_TRIGGER_RIGHT,0);axis(JOY_AXIS_LEFT_Y,0);await frames()
		check(walk.stand(),"stand for free-camera shortcut");await frames()
		await tap(JOY_BUTTON_RIGHT_STICK)
		check(not walk.active and pose()==[0,false] and not game.audio._cab,"free camera exits walking with exterior sound")
		await tap(JOY_BUTTON_LEFT_STICK)
		check(walk.stand(),"stand for on-foot cycling");await frames()
		await tap(JOY_BUTTON_DPAD_RIGHT)
		check(not walk.active and pose()==[3,1],"D-pad cycles on foot without lamp conflict")
		await tap(JOY_BUTTON_START)
		var before:=pose()
		await tap(JOY_BUTTON_DPAD_RIGHT);await tap(JOY_BUTTON_RIGHT_STICK)
		check(game.hud.modal=="pause" and pose()==before,"menu navigation does not change camera")
		await tap(JOY_BUTTON_B)
		pad.shortcut("dispatch");await frames()
		before=pose()
		await tap(JOY_BUTTON_DPAD_LEFT);await tap(JOY_BUTTON_RIGHT_STICK)
		check(game.dispatcher._root.visible and pose()==before,"dispatch navigation does not change camera")
		await tap(JOY_BUTTON_B)
	print("Camera controls: %d checks, %d failures" % [checks,failures])
	quit(1 if failures else 0)
