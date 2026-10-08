extends "res://tools/check_platform_walking.gd"
## Walk using collision sweeps from the actual pilot standing point, then along
## the platform. Never teleport to an interior entry point to prove reachability.
const Stock:=preload("res://sim/stock/ported_stock.gd")

func interior_path(goal: Vector2) -> Array:
	var nav=walk.nav
	var first: Vector2i=nav.cell(walk.position)
	var last: Vector2i=nav.cell(goal)
	var queue: Array=[first]
	var previous: Dictionary={first:first}
	var cursor:=0
	while cursor<queue.size() and not previous.has(last):
		var at: Vector2i=queue[cursor];cursor+=1
		for d in [Vector2i.LEFT,Vector2i.RIGHT,Vector2i.UP,Vector2i.DOWN]:
			var next: Vector2i=at+d
			if previous.has(next) or not nav.valid(next):continue
			if not nav.reachable_step(nav.center(at),nav.center(next),false):continue
			previous[next]=at;queue.append(next)
	if not previous.has(last):return []
	var result: Array=[nav.center(last)]
	var at:=last
	while at!=first:
		at=previous[at];result.push_front(nav.center(at))
	return result

func platform_path(goal: Vector2) -> Array:
	var surface=walk.platform.surface
	var offset:=Vector2(minf(goal.x,walk.platform.position.x)-3,2.22)
	var extent:=Vector2(absf(goal.x-walk.platform.position.x)+6,surface.width-.4)
	var step:=.16
	var first:=Vector2i(((walk.platform.position-offset)/step).round())
	var last:=Vector2i(((goal-offset)/step).round())
	var queue: Array=[first]
	var previous: Dictionary={first:first}
	var cursor:=0
	while cursor<queue.size() and not previous.has(last):
		var at: Vector2i=queue[cursor];cursor+=1
		for d in [Vector2i.LEFT,Vector2i.RIGHT,Vector2i.UP,Vector2i.DOWN]:
			var next: Vector2i=at+d
			var relative:=Vector2(next)*step
			if previous.has(next) or relative.x<0 or relative.y<0 or relative.x>extent.x or relative.y>extent.y:continue
			var p:=offset+relative
			if not surface.allowed(p):continue
			if surface.move(offset+Vector2(at)*step,Vector2(d)*step).distance_to(p)>.001:continue
			previous[next]=at;queue.append(next)
	if not previous.has(last):return []
	var result: Array=[offset+Vector2(last)*step,goal]
	var at:=last
	while at!=first:
		at=previous[at];result.push_front(offset+Vector2(at)*step)
	return result

func run() -> void:
	Engine.max_fps=60
	root.size=Vector2i(1280,720)
	change_scene_to_file("res://game/main.tscn")
	await process_frame;await process_frame
	game=current_scene;pad=game.controller;walk=game.walker
	game.set_physics_process(false)
	var start:=Time.get_ticks_msec()
	while game.wv.loading and Time.get_ticks_msec()-start<120000:await process_frame
	game.set_process(false);game.cam.set_process(false);pad.set_process(false)
	for sound in game.train_audio.values():sound.set_process(false);sound.set_paused(true)
	pad.settings_path="res://.local/r10-walking-controller.cfg"
	pad.tsw_layout=true;pad.window_focus(true);pad._adopt(DEVICE);pad._set_mode(true)
	for service in ["K1","K2"]:
		game._select_train(service);game._render_trains(1)
		game.cam.global_transform=game.cam._target()
		game._geographic_frame();game._render_trains(1)
		await scenery_ready()
		game.train.automatic=false;game.train.controller=-1;game.train.speed=0
		for sound in game.train_audio.values():sound.set_process(false);sound.set_paused(true)
		var family: String=game.tv.choice
		var count:=20 if service=="K1" else 22
		check(game.tv.cars.size()==count+1,"rendered "+service+" includes every long-rake coach")
		check(game.tv.sound_axles().size()==6+4*count,"audio follows actual coach count")
		check(game.tv.formation==Stock.formation(family,game.train.rake_profile),"rendering shares simulation rake profile")
		# A viewpoint transfer remains available at speed, independent of the
		# physical WAP/platform walking route and without giving up the service.
		game.train.speed=16.667;game.train.controller=-.4
		game._ui_action("coaches");await frames()
		var coach_buttons: Array=game.hud._buttons.get_children()
		check(coach_buttons.size()==count+1,"all numbered coaches and Back are selectable")
		coach_buttons[count-1].grab_focus();await tap(JOY_BUTTON_A)
		check(game.cam.mode==2 and game.tv.passenger_coach==count,"controller selects last coach while moving")
		check(game.train.id==service and not game.train.automatic and game.train.controller==-.4,"coach transfer preserves assigned service and driving handle")
		await tap(JOY_BUTTON_Y)
		check(walk.active and walk.car==count,"stand and walk inside selected moving coach")
		await tap(JOY_BUTTON_LEFT_STICK)
		check(game.cam.mode==1 and not walk.active,"L3 returns directly to WAP pilot from moving coach")
		game.train.speed=0;game.train.controller=-1
		for car in range(1,game.tv.cars.size()):
			check(game.tv.formation[car].model.begins_with(family+"_"),"homogeneous family at coach "+str(car))
			check(not valid_berth(car).is_empty(),"long rake coach has a usable platform doorway "+str(car))
		game._pilot_camera();await frames()
		await tap(JOY_BUTTON_Y)
		check(walk.active,"controller Y stands in "+service+" cab")
		var found:={}
		var route: Array=[]
		for door in walk.platform.doors(0):
			var dock: Dictionary=walk.platform.dock(0,door)
			var entry: Dictionary=walk.platform.entry_point(0,door)
			if dock.is_empty() or entry.is_empty():continue
			route=interior_path(entry.point)
			if not route.is_empty():found=dock;break
		check(not found.is_empty(),"pilot can physically reach a platform-side cab door")
		if found.is_empty():continue
		for point in route:walk.position=walk.nav.move(walk.position,point-walk.position)
		check(walk.position.distance_to(route[-1])<.03,"cab route uses supported walking surface")
		face(Vector3(found.door.point[0]-walk.position.x,0,found.door.point[1]-walk.position.y))
		walk.update(.016)
		check(walk.target.get("kind")=="alight","cab side door offers platform action")
		game.train.speed=1;walk.update(.016)
		check(walk.target.get("kind")=="platform_blocked" and not walk.platform.alight(found),"cannot leave moving locomotive")
		game.train.speed=0;walk.update(.016)
		await tap(JOY_BUTTON_A)
		check(walk.platform.outside,"controller A leaves cab")
		if not walk.platform.outside:continue
		var coach:=valid_berth(1)
		check(not coach.is_empty(),"first coach is docked")
		if coach.is_empty():continue
		var path:=platform_path(coach.point)
		check(not path.is_empty(),"platform route from locomotive to first coach clears furniture")
		for point in path:walk.platform.position=walk.platform.surface.move(walk.platform.position,point-walk.platform.position)
		check(walk.platform.position.distance_to(coach.point)<.03,"walk reaches first coach without teleporting")
		var doorway: Vector3=game.tv.cars[1].to_global(Vector3(coach.door.point[0],1.3,coach.door.point[1]))
		face(doorway-walk.platform.surface.point(walk.platform.position,walk.platform.origin()))
		walk.platform._refresh=0;walk.update(.016)
		check(walk.target.get("kind")=="board" and walk.target.get("car")==1,"first passenger coach boarding prompt")
		check("coach 1" in walk.target.get("label",""),"coach number excludes locomotive")
		await tap(JOY_BUTTON_A)
		check(not walk.platform.outside and walk.car==1 and walk.nav.allowed(walk.position),"controller A boards first passenger coach")
		check(game.train.controller==-1 and not game.train.automatic,"walking preserves manual service and brake")
		game.cam.global_transform=game.cam._target();walk._fade_time=0;walk.update(.016)
		await shot(service+"-first-coach")
		game._pilot_camera();await frames()
		if DisplayServer.get_name()!="headless":
			var camera:=Camera3D.new();game.add_child(camera)
			var centre: Vector3=(game.tv.cars.front().global_position+game.tv.cars.back().global_position)*.5
			var along: Vector3=(game.tv.cars.front().global_position-game.tv.cars.back().global_position).normalized()
			camera.global_position=centre+along.cross(Vector3.UP)*game.train.length*.7+Vector3.UP*game.train.length*.3
			camera.look_at(centre);camera.far=3000;camera.current=true
			await scenery_ready()
			await shot(service+"-full-rake")
			centre=game.tv.cars[3].global_position+Vector3.UP*2
			camera.global_position=centre+along.cross(Vector3.UP)*55+Vector3.UP*9
			camera.look_at(centre);await scenery_ready()
			await shot(service+"-coach-paint")
			camera.queue_free();game.cam.current=true
	print("Long-rake walking: %d checks; %d failures" % [checks,failures])
	game.queue_free();await process_frame;await process_frame
	quit(1 if failures else 0)

func scenery_ready() -> void:
	game.wv.update()
	var start:=Time.get_ticks_msec()
	while game.wv.loading and Time.get_ticks_msec()-start<120000:
		await process_frame;game.wv.update()
	check(not game.wv.loading,"scenery streamed at capture/walking position")
