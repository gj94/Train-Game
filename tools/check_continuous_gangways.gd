extends SceneTree
## Native source models and the real walker: no prompted transfer or fade.
const View:=preload("res://game/ported_train_view.gd")
const Walk:=preload("res://game/train_walk.gd")
const Stock:=preload("res://sim/stock/ported_stock.gd")
const Link:=preload("res://game/gangway_connection.gd")
var report:={cases=[],failures=[]}
var folder:="res://.local/realism-2026-10-26/gangway-native"

func _initialize() -> void:call_deferred("run")

func shot(name: String) -> void:
	await process_frame;await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(folder+"/"+name+".png")

func aisle_route(nav, start: Vector2, destination: Vector2) -> Array:
	var from: Vector2i=nav.cell(start);var goal: Vector2i=nav.cell(destination)
	var queue: Array=[from];var parents: Dictionary={from:from};var cursor:=0
	while cursor<queue.size() and not parents.has(goal):
		var at: Vector2i=queue[cursor];cursor+=1
		for direction in [Vector2i.LEFT,Vector2i.RIGHT,Vector2i.UP,Vector2i.DOWN]:
			var next: Vector2i=at+direction
			if parents.has(next) or not nav.valid(next):continue
			if not nav.reachable_step(nav.center(at),nav.center(next),false):continue
			parents[next]=at;queue.append(next)
	if not parents.has(goal):return []
	var route: Array=[destination];var at:=goal
	while at!=from:route.push_front(nav.center(at));at=parents[at]
	return route

func saloon_point(nav, start: Vector2) -> Vector2:
	var point:=start;var best:=INF
	for cell in nav.component(start):
		var p: Vector2=nav.center(cell);var score:=absf(p.y)+absf(p.x)*.1
		if score<best:best=score;point=p
	return point

func follow_aisle(walk, cam, destination: Vector2, label: String) -> bool:
	var route:=aisle_route(walk.nav,walk.position,destination)
	if route.is_empty():return false
	for point in route:
		var delta: Vector2=point-walk.position
		cam._look=Vector2(atan2(-delta.x,-delta.y),0)
		walk.move_inside(delta)
		if walk.position.distance_to(point)>.003:return false
		cam.global_transform=walk.camera_transform();cam.basis*=Basis(Vector3.UP,cam._look.x)
		await process_frame
	await shot(label)
	return true

func run() -> void:
	DirAccess.make_dir_recursive_absolute(folder);root.size=Vector2i(1280,720);Engine.max_fps=60
	for model in ["icf_sl","lhb_3a","vb_tc_cc","vb_dtc","lhb_gs"]:
		var scene:=Node3D.new();root.add_child(scene)
		var environment:=WorldEnvironment.new();scene.add_child(environment);environment.environment=Environment.new()
		environment.environment.background_mode=Environment.BG_COLOR;environment.environment.background_color=Color("9eb8cc")
		environment.environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
		environment.environment.ambient_light_color=Color.WHITE;environment.environment.ambient_light_energy=.75
		var sun:=DirectionalLight3D.new();scene.add_child(sun);sun.rotation_degrees=Vector3(-35,30,0);sun.light_energy=1.1
		var graph:=TrackGraph.new();graph.add_node("a",Vector3(0,0,-3000));graph.add_node("b",Vector3(0,0,3000));graph.add_edge("line","a","b")
		var family:="vb8" if model.begins_with("vb") else ("icf" if model.begins_with("icf") else "lhb")
		var train:=Train.new("walk",Stock.length_of(family));Stock.configure(train,family);train.path=[{edge="line",dir=1}];train.head_s=3200
		var view:=View.new();view.begin_build(train,graph,scene)
		var pitch: float=Stock.geometry(model).pitch
		var reversed: bool=model.begins_with("vb")
		view.formation=[{model=model,reverse=false,center=pitch*.5,pitch=pitch},{model=model,reverse=reversed,center=pitch*1.5,pitch=pitch}]
		train.length=2*pitch
		while not view.build_next_car():pass
		view.finish_build();view.ride=null
		var cam:=preload("res://game/camera_rig.gd").new();scene.add_child(cam);cam.set_process(false);cam.make_current();cam.near=.035;cam.fov=75
		var walk:=Walk.new();walk.game={tv=view,cam=cam,train=train};scene.add_child(walk)
		walk.active=true;walk.car=0;walk.nav=walk.navigation(0);walk.eye_height=1.58;cam._look=Vector2(PI,0)
		var approach:=Vector2(0,Link.load_profiles()[model].gangway_join-.25)
		walk.position=saloon_point(walk.nav,approach)
		var approach_passed: bool=await follow_aisle(walk,cam,approach,model+"-full-aisle-approach")
		cam._look=Vector2(PI,0)
		var maximum:=0.0;var previous:=walk.camera_transform().origin;var captured:=false
		for frame in 180:
			var old_car_origin: Vector3=view.cars[0].global_position
			train.head_s+=.2;view.update()
			previous+=view.cars[0].global_position-old_car_origin
			var direction:=Basis(Vector3.UP,cam._look.x)*Vector3(0,0,-.015)
			walk.move_inside(Vector2(direction.x,direction.z))
			cam.global_transform=walk.camera_transform();cam.basis*=Basis.from_euler(Vector3(cam._look.y,cam._look.x,0))
			maximum=maxf(maximum,cam.global_position.distance_to(previous));previous=cam.global_position
			if frame==0:await shot(model+"-approach")
			if not walk.bridge.is_empty() and walk.bridge.u>.42 and not captured:
				await shot(model+"-bridge");captured=true
			await process_frame
		await shot(model+"-arrival")
		var arrival_passed: bool=await follow_aisle(walk,cam,saloon_point(walk.nav,walk.position),model+"-full-aisle-arrival")
		var result:={model=model,reversed=reversed,car=walk.car,bridge_empty=walk.bridge.is_empty(),max_step_m=maximum,fade=walk._fade_time,bridge_screenshot=captured,full_aisle_approach=approach_passed,full_aisle_arrival=arrival_passed,train_movement_m=36.0}
		var passed: bool=walk.car==1 and walk.bridge.is_empty() and maximum<.065 and walk._fade_time==0 and captured and approach_passed and arrival_passed
		result.passed=passed;report.cases.append(result);print("GANGWAY ",JSON.stringify(result))
		if not passed:report.failures.append(model)
		if model in ["vb_dtc","lhb_gs"]:
			walk.bridge.clear();walk.car=0;walk.nav=walk.navigation(0);walk.position=Vector2(0,7.6 if model=="vb_dtc" else 8.0)
			cam._look=Vector2(PI,0);cam.global_transform=walk.camera_transform();cam.basis*=Basis(Vector3.UP,PI)
			await shot(model+"-interior-pinch")
		scene.queue_free();await process_frame;await process_frame
	var out:=FileAccess.open(folder+"/report.json",FileAccess.WRITE);out.store_string(JSON.stringify(report,"  "));out.close()
	quit(0 if report.failures.is_empty() else 1)
