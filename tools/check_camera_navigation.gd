extends "res://tools/check_walking_playable.gd"
## Real controller events: carriage progression, platform free view and trigger handoff.
func _initialize() -> void:
	family="lhb"
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--fleet="):family=arg.trim_prefix("--fleet=")
	set_meta("imported_fleet",family);set_meta("traffic_drive",false)
	call_deferred("run")
func run() -> void:
	Engine.max_fps=120
	change_scene_to_file("res://game/main.tscn")
	await process_frame;await process_frame
	game=current_scene;pad=game.controller;walk=game.walker
	game.set_process(false);game.set_physics_process(false);game.cam.set_process(false)
	pad.set_process(false);game.dispatcher.set_process(false)
	for sound in game.train_audio.values():sound.set_process(false)
	pad.settings_path="res://.local/camera-navigation-test.cfg"
	pad.window_focus(true);pad._adopt(DEVICE);pad._set_mode(true);await frames()
	check(game.cam.mode==1,"fresh scenario begins in pilot")
	for layout in [true,false]:
		pad.tsw_layout=layout;game._pilot_camera();await frames()
		game.train.automatic=true;game.train.controller=.35
		var coaches: Array=game.tv.passenger_coaches()
		await tap(JOY_BUTTON_DPAD_RIGHT);check(game.cam.mode==3 and game.cam.head_out_side==1,"pilot right enters right head-out")
		await tap(JOY_BUTTON_LEFT_STICK)
		await tap(JOY_BUTTON_DPAD_LEFT);check(game.cam.mode==3 and game.cam.head_out_side==-1,"pilot left enters left head-out")
		await tap(JOY_BUTTON_LEFT_STICK)
		await tap(JOY_BUTTON_DPAD_UP);check(game.cam.mode==1,"up at loco stays at loco")
		for coach in coaches:
			await tap(JOY_BUTTON_DPAD_DOWN)
			check(game.cam.mode==2 and game.tv.passenger_coach==coach,"down advances exactly one coach")
		await tap(JOY_BUTTON_DPAD_DOWN);check(game.tv.passenger_coach==coaches[-1],"tail does not wrap")
		for i in range(coaches.size()-2,-1,-1):
			await tap(JOY_BUTTON_DPAD_UP)
			check(game.tv.passenger_coach==coaches[i],"up advances exactly one coach toward loco")
		await tap(JOY_BUTTON_DPAD_UP);check(game.cam.mode==1,"up from coach one reaches pilot")
		check(game.train.automatic and game.train.controller==.35,"camera changes preserve service controls")
		var initial_fov: float=game.cam.cab_fov
		axis(JOY_AXIS_LEFT_X,1);pad._process(.2);walk.update(.2)
		check(walk.active and game.cam.mode==4,"left stick enters cabin movement")
		var p: Vector2=walk.position
		var movement:=Vector2.ZERO
		for direction: Vector2 in [Vector2.LEFT,Vector2.RIGHT,Vector2.UP,Vector2.DOWN]:
			var v:=Basis(Vector3.UP,game.cam._look.x)*Vector3(direction.x,0,direction.y)
			if walk.nav.move(p,Vector2(v.x,v.z)*.3).distance_to(p)>.08:movement=direction;break
		axis(JOY_AXIS_LEFT_X,movement.x);axis(JOY_AXIS_LEFT_Y,movement.y)
		for i in 10:pad._process(.016);walk.update(.016)
		check(walk.position.distance_to(p)>.03,"left stick translates the cabin viewpoint")
		check(walk.nav.allowed(walk.position) and game.cam.cab_fov==initial_fov,"cab movement respects walls without zoom")
		axis(JOY_AXIS_LEFT_X,0);axis(JOY_AXIS_LEFT_Y,0);await frames()
		await tap(JOY_BUTTON_LEFT_STICK);check(game.cam.mode==1 and not walk.active,"L3 returns seated pilot")
		var origin: Vector3=game.wv.coordinate_origin if game.geographic_drive else Vector3.ZERO
		var spot:=preload("res://game/platform_camera.gd").nearest(game.world,game.cam._target().origin+origin)
		await tap(JOY_BUTTON_RIGHT_STICK)
		check(game.cam.free_flight and not game.cam.follow and game.cam.pivot.distance_to(spot.eye-origin)<.02,"free view starts on nearest platform at passenger eye height")
		var eye: Vector3=game.cam.pivot;var fov: float=game.cam.free_fov
		axis(JOY_AXIS_TRIGGER_RIGHT,1);pad._process(.25)
		check(game.cam.free_fov<fov and game.cam.pivot==eye and pad.drive_input()==0,"RT zooms optically without moving or driving")
		var zoomed: float=game.cam.free_fov
		button(JOY_BUTTON_RIGHT_STICK,true);pad._process(.7)
		check(pad._free_train_controls and pad.drive_input()==0,"long RS selects drive but held trigger stays blocked")
		pad._process(1);check(pad._free_train_controls,"long hold toggles only once")
		button(JOY_BUTTON_RIGHT_STICK,false);axis(JOY_AXIS_TRIGGER_RIGHT,0);await frames()
		axis(JOY_AXIS_TRIGGER_RIGHT,.7);pad._process(.2)
		check(pad.drive_input()>0 and game.cam.free_fov==zoomed,"fresh RT drives without zoom in drive mode")
		button(JOY_BUTTON_RIGHT_STICK,true);pad._process(.7);button(JOY_BUTTON_RIGHT_STICK,false)
		axis(JOY_AXIS_TRIGGER_RIGHT,0);await frames()
		check(not pad._free_train_controls,"second long hold restores zoom")
		axis(JOY_AXIS_TRIGGER_LEFT,1);pad._process(.2)
		check(game.cam.free_fov>zoomed and pad.drive_input()==0,"LT zooms out without braking")
		await tap(JOY_BUTTON_LEFT_STICK)
		check(game.cam.mode==1 and pad.drive_input()==0,"returning pilot cannot apply a held zoom trigger")
		axis(JOY_AXIS_TRIGGER_LEFT,0);await frames()
		await tap(JOY_BUTTON_RIGHT_STICK)
		var session: Dictionary=game.save_load.capture_session()
		check(session.camera.free_flight and session.camera.free_fov==game.cam.free_fov,"save captures free camera and lens")
		check(game.save_load.validate_session({world=game.world,session=session}).is_empty(),"new free camera save validates")
	var saved: Dictionary=game.save_load.capture_session()
	var saved_eye: Vector3=game.cam.pivot
	game._pilot_camera();game.save_load.restore_view(saved)
	check(game.cam.free_flight and game.cam.pivot==saved_eye and game.paused,"free camera restores at the same platform eye, paused")
	saved.camera.erase("free_flight");saved.camera.erase("free_fov")
	check(game.save_load.validate_session({world=game.world,session=saved}).is_empty(),"old camera save remains accepted")
	game.save_load.restore_view(saved)
	check(not game.cam.free_flight and game.cam.free_fov==65,"old saves use legacy orbit camera defaults")
	print("Camera navigation ",family,": ",checks," checks; ",failures," failures")
	quit(1 if failures else 0)
