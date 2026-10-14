extends SceneTree
## Repeatable native review using the playable adapter, with fixed cameras/light.
var scene: Node3D
var camera: Camera3D
var output := "res://.local/train-fidelity/review"
var report := []
var full_shadows := false
var failures := 0
var night := false
var full_geometry := false

func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--output="): output=arg.trim_prefix("--output=")
		if arg=="--full-shadows": full_shadows=true
		if arg=="--night":night=true
		if arg=="--full-geometry":full_geometry=true
	call_deferred("run")

func run() -> void:
	root.size=Vector2i(1600,900)
	if full_geometry:root.mesh_lod_threshold=0
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	RenderingServer.viewport_set_measure_render_time(root.get_viewport_rid(),true)
	DirAccess.make_dir_recursive_absolute(output)
	scene=Node3D.new();root.add_child(scene)
	var environment=preload("res://game/world_view.gd").new()
	environment.root=scene;environment._build_environment()
	if night:environment.day_night.update(22*3600,true)
	var floor_mesh:=MeshInstance3D.new()
	var plane:=PlaneMesh.new();plane.size=Vector2(400,200)
	floor_mesh.mesh=plane;floor_mesh.position=Vector3(200,0,0)
	var ground:=StandardMaterial3D.new();ground.albedo_color=Color(.23,.22,.19);ground.roughness=1
	floor_mesh.material_override=ground;scene.add_child(floor_mesh)
	var world:=RailWorld.new()
	world.graph.add_node("a",Vector3.ZERO);world.graph.add_node("b",Vector3(500,0,0))
	world.graph.add_edge("main","a","b")
	var train:=Train.new("REVIEW",200)
	preload("res://sim/stock/ported_stock.gd").configure(train,"lhb")
	world.place_train(train,"main",300,1)
	var view=preload("res://game/ported_train_view.gd").new()
	view.begin_build(train,world.graph,scene)
	view.formation=[]
	var distance:=0.0
	for key in ["wap7","lhb_cc","icf_gs","vb_dtc","vb_tc_ec"]:
		var pitch: float=preload("res://sim/stock/ported_stock.gd").geometry(key).pitch
		view.formation.append({model=key,reverse=false,center=distance+pitch*.5,pitch=pitch})
		distance+=pitch
	while not view.build_next_car():pass
	view.finish_build()
	if full_shadows:
		for model in view.models:
			for mesh in model.find_children("*","MeshInstance3D",true,false):
				if str(mesh.name).begins_with("Shadow_"):mesh.visible=false
				else:mesh.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	camera=Camera3D.new();camera.near=.035;camera.far=1000;camera.fov=58
	scene.add_child(camera);camera.make_current()
	for i in view.cars.size():
		var key: String=view.formation[i].model
		view.set_cab_view(false);view.set_passenger_view(false)
		await shot(key+"-exterior",view.cars[i],Vector3(13,4.3,-18),Vector3(0,2,-1))
		camera.fov=40
		await shot(key+"-hero",view.cars[i],Vector3(15,3.2,-14),Vector3(0,2,-1))
		camera.fov=58
		await shot(key+"-gear",view.cars[i],Vector3(3.6,1.1,-6.1),Vector3(0,.85,-6.1))
		if key=="wap7":
			view.set_cab_view(true);view.update()
			await shot(key+"-cab",view.cars[i],Vector3(0,3.13,-7.47),Vector3(0,2.68,-8.96))
		else:
			view.passenger_coach=i;view.passenger_bay=0;view.passenger_seat=false
			view.set_passenger_view(true);view.update()
			camera.global_transform=view.passenger_transform()
			await capture(key+"-aisle")
	FileAccess.open(output+"/report.json",FileAccess.WRITE).store_string(JSON.stringify(report,"\t"))
	await shadow_regression(view)
	scene.free();quit(1 if failures else 0)

func shadow_regression(view) -> void:
	# With dynamic shadows disabled, changing the shadow budget must not alter
	# visible geometry. The old OFF transition exposed collapsed shadow meshes.
	view.set_cab_view(false);view.set_passenger_view(false)
	for light in scene.find_children("*","DirectionalLight3D",true,false):light.shadow_enabled=false
	root.mesh_lod_threshold=0
	var results:=[]
	for i in view.cars.size():
		var car: Node3D=view.cars[i]
		camera.global_position=car.global_transform*Vector3(5,2.7,-10)
		camera.look_at(car.global_transform*Vector3(0,1.9,-5))
		var images:=[]
		for detailed in [true,false,true]:
			for parts in view.shadow_parts:preload("res://game/train_visibility.gd").set_shadow_detail(parts,detailed)
			for frame in 20:await process_frame
			await RenderingServer.frame_post_draw
			var img:=root.get_texture().get_image()
			img.resize(160,90,Image.INTERPOLATE_BILINEAR)
			images.append(img)
		var error:=0.0
		for variant in [1,2]:
			for y in 90:
				for x in 160:
					var a: Color=images[0].get_pixel(x,y)
					var b: Color=images[variant].get_pixel(x,y)
					error=maxf(error,maxf(absf(a.r-b.r),maxf(absf(a.g-b.g),absf(a.b-b.b))))
		if error>2.0/255.0:failures+=1;printerr("Shadow budget changed visible train: ",view.formation[i].model," error=",error)
		results.append({model=view.formation[i].model,max_channel_error=error})
	FileAccess.open(output+"/shadow-regression.json",FileAccess.WRITE).store_string(JSON.stringify(results,"\t"))
	print("SHADOW_VISIBILITY ",JSON.stringify(results))

func shot(label: String,car: Node3D,eye: Vector3,target: Vector3) -> void:
	camera.global_position=car.global_transform*eye
	camera.look_at(car.global_transform*target)
	await capture(label)

func capture(label: String) -> void:
	for frame in 35:await process_frame
	var samples:=[]
	for frame in 60:
		await process_frame
		samples.append(RenderingServer.viewport_get_measured_render_time_gpu(root.get_viewport_rid()))
	samples.sort()
	await RenderingServer.frame_post_draw
	var captured:=root.get_texture().get_image()
	captured.save_png(output+"/"+label+".png")
	if night and label=="vb_tc_ec-aisle":
		# Fixed-camera aisle floor. A second backface-normal flip made this
		# grey vinyl black despite the ceiling lamps. Sample away from seats.
		var floor_light:=0.0
		for y in range(780,821,10):
			for x in range(790,811,5):floor_light+=captured.get_pixel(x,y).get_luminance()/25.0
		if floor_light<.10:failures+=1;printerr("VB aisle floor is unlit: ",floor_light)
		FileAccess.open(output+"/interior-regression.json",FileAccess.WRITE).store_string(JSON.stringify({floor_luminance=floor_light,minimum=.10,passed=floor_light>=.10}))
	report.append({view=label,gpu_median_ms=samples[30],draws=Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),triangles=Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME)})
	print("FIDELITY ",JSON.stringify(report[-1]))
