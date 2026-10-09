extends "res://tools/check_walking_playable.gd"
## Regression for D-pad-selected interiors: stick translation, not seated zoom.
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
	pad.settings_path="res://.local/coach-movement-test.cfg"
	pad.window_focus(true);pad._adopt(DEVICE);pad._set_mode(true);await frames()
	for layout in [true,false]:
		pad.tsw_layout=layout;game._pilot_camera();await frames()
		game.train.automatic=false;game.train.controller=.35
		var coaches: Array=game.tv.passenger_coaches()
		for index in coaches.size():
			await tap(JOY_BUTTON_DPAD_DOWN)
			var coach: int=coaches[index]
			check(game.cam.mode==2 and game.tv.passenger_coach==coach,"D-pad selects exact coach "+str(index))
			var lens: float=game.cam.cab_fov
			# Look down first: starting translation must retain that direction.
			axis(JOY_AXIS_RIGHT_Y,.4);pad._process(.15);axis(JOY_AXIS_RIGHT_Y,0)
			var before: Transform3D=game.cam._target()
			axis(JOY_AXIS_LEFT_Y,-1);pad._process(.016)
			check(walk.active and walk.car==coach and game.cam.mode==4,"LS immediately enables movement in coach "+str(index))
			if not walk.active:quit(1);return
			var forward: Vector3=-game.cam._target().basis.z
			check(forward.dot(-before.basis.z)>.9999,"movement preserves look direction")
			var start: Vector2=walk.position
			var bay: int=game.tv.passenger_bay
			for i in 30:
				pad._process(.016);walk.update(.016);game.cam._process(.016)
			check(walk.position.distance_to(start)>.15,"held LS translates continuously, no release or Y needed")
			check(walk.nav.allowed(walk.position) and game.cam.cab_fov==lens and game.tv.passenger_bay==bay,"no zoom, bay jump or wall crossing")
			axis(JOY_AXIS_LEFT_Y,0);await frames()
			var look: Vector2=game.cam._look
			var still: Vector2=walk.position
			axis(JOY_AXIS_RIGHT_X,.7);pad._process(.1);walk.update(.1);axis(JOY_AXIS_RIGHT_X,0)
			check(game.cam._look.x!=look.x and walk.position==still,"RS looks without translating")
			# The actual Camera3D must follow an articulated moving/turning coach.
			var original: Transform3D=game.tv.cars[coach].global_transform
			game.tv.cars[coach].global_transform=Transform3D(Basis(Vector3.UP,.37),Vector3(130,4,-75))*original
			game.cam._process(.016)
			var expected: Vector3=game.tv.cars[coach].global_transform*Vector3(walk.position.x,walk.nav.floor_height(walk.position)+walk.eye_height,walk.position.y)
			check(game.cam.global_position.distance_to(expected)<.001 and walk.position==still,"viewpoint stays fixed inside moving and rotating coach")
			game.tv.cars[coach].global_transform=original;game.cam._process(.016)
			check(not game.train.automatic and game.train.controller==.35 and pad.drive_input()==0,"interior movement keeps assigned driver and handle")
			if index in [0,coaches.size()/2,coaches.size()-1]:
				reach_room_end()
				var session: Dictionary=game.save_load.capture_session()
				check(session.camera.mode==4 and game.save_load.validate_session({world=game.world,session=session}).is_empty(),"moving interior save validates")
			# Next D-pad Down must advance from this walking car, not reset to car 1.
		await tap(JOY_BUTTON_LEFT_STICK);check(game.cam.mode==1 and not walk.active,"L3 returns to pilot")
		# AI assignment is also preserved through automatic movement entry.
		game.train.automatic=true
		await tap(JOY_BUTTON_DPAD_DOWN);axis(JOY_AXIS_LEFT_Y,-1);pad._process(.016);walk.update(.016)
		check(game.train.automatic and walk.active,"automatic service continues while moving inside coach")
		axis(JOY_AXIS_LEFT_Y,0);await frames()
		await tap(JOY_BUTTON_LEFT_STICK)
	print("Coach camera movement ",family,": ",checks," checks; ",failures," failures")
	quit(1 if failures else 0)

func reach_room_end() -> void:
	# Walk via real stick input to the farther end of the current connected aisle.
	# Use its clearance grid only to plan a route around furniture.
	var start: Vector2=walk.position
	var cells: Array=walk.nav.component(start,false)
	var first: Vector2i=walk.nav.cell(start)
	var goal: Vector2i=first
	for cell: Vector2i in cells:
		if absf(walk.nav.center(cell).y-start.y)>absf(walk.nav.center(goal).y-start.y):goal=cell
	var queue: Array[Vector2i]=[first]
	var parent: Dictionary={first:first}
	var cursor:=0
	while cursor<queue.size() and not parent.has(goal):
		var at:=queue[cursor];cursor+=1
		for offset: Vector2i in [Vector2i.LEFT,Vector2i.RIGHT,Vector2i.UP,Vector2i.DOWN]:
			var next:=at+offset
			if parent.has(next) or not walk.nav.reachable_step(walk.nav.center(at),walk.nav.center(next),false):continue
			parent[next]=at;queue.append(next)
	check(parent.has(goal),"far aisle end has a continuous path")
	if not parent.has(goal):return
	var path: Array[Vector2i]=[goal]
	while path[-1]!=first:path.append(parent[path[-1]])
	path.reverse();game.cam._look=Vector2.ZERO
	for cell: Vector2i in path:
		var point: Vector2=walk.nav.center(cell)
		for attempt in 30:
			var direction: Vector2=point-walk.position
			if direction.length()<.025:break
			direction=direction.normalized()
			axis(JOY_AXIS_LEFT_X,direction.x);axis(JOY_AXIS_LEFT_Y,direction.y)
			pad._process(.016);walk.update(.016);game.cam._process(.016)
	axis(JOY_AXIS_LEFT_X,0);axis(JOY_AXIS_LEFT_Y,0)
	check(walk.position.distance_to(walk.nav.center(goal))<.04,"sticks reach the far end of the aisle")
	check(walk.position.distance_to(start)>3.0,"translation spans metres within the carriage, not a zoom")
