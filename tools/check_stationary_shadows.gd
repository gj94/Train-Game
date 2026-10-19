extends SceneTree
## Fixed train and external casters: isolate sunlight stepping from streaming,
## vehicle movement, camera motion and animated vegetation.
var output:="res://.local/r35-fixes/shadows-current"
var sun_angle:=-1.0
var cycle_script:="res://game/day_night.gd"
func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--output="):output=arg.trim_prefix("--output=")
		if arg.begins_with("--sun-angle="):sun_angle=arg.trim_prefix("--sun-angle=").to_float()
		if arg.begins_with("--cycle="):cycle_script=arg.trim_prefix("--cycle=")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output));call_deferred("run")
func box(parent: Node3D,point: Vector3,size: Vector3) -> void:
	var node:=MeshInstance3D.new();var mesh:=BoxMesh.new();mesh.size=size;node.mesh=mesh;node.position=point
	var mat:=StandardMaterial3D.new();mat.albedo_color=Color(.4,.4,.4);mat.roughness=.9;node.material_override=mat;parent.add_child(node)
func run() -> void:
	root.size=Vector2i(960,540);Engine.max_fps=60
	var scene:=Node3D.new();root.add_child(scene)
	var context=preload("res://game/world_view.gd").new();context.root=scene;context._build_environment()
	var original=context.day_night
	var cycle=load(cycle_script).new(original.environment,original.sun,scene)
	original.moon.queue_free();context.day_night=cycle
	cycle.update(16*3600,true)
	if sun_angle>=0:cycle.sun.light_angular_distance=sun_angle
	var world:=RailWorld.new();world.graph.add_node("a",Vector3.ZERO);world.graph.add_node("b",Vector3(500,0,0));world.graph.add_edge("main","a","b")
	var train:=Train.new("STATIONARY",40);preload("res://sim/stock/ported_stock.gd").configure(train,"lhb");world.place_train(train,"main",300,1)
	var view=preload("res://game/ported_train_view.gd").new();view.begin_build(train,world.graph,scene)
	view.formation=[{model="wap7",reverse=false,center=10.0,pitch=20.0}]
	while not view.build_next_car():pass
	view.finish_build();view.update()
	var p: Vector3=view.cars[0].global_position
	box(scene,p+Vector3(0,-.5,0),Vector3(140,1,100))
	for i in 9:box(scene,p+Vector3(-14+i*3,7.5,0),Vector3(.35,.4,18))
	var camera:=Camera3D.new();camera.position=p+Vector3(10,5.2,19);camera.fov=58;scene.add_child(camera);camera.look_at(p+Vector3(0,2,0));camera.make_current()
	for i in 80:await process_frame
	var samples:=[];var previous: Basis=cycle.sun.basis
	for i in 81:
		var clock:=16*3600+i*.25
		# Equivalent clock-driven samples independent of disk/capture wall time.
		cycle._wall=-1000000;cycle.update(clock)
		var change: float=(cycle.sun.basis.z-previous.z).length();previous=cycle.sun.basis
		for f in 3:await process_frame
		await RenderingServer.frame_post_draw
		var image:=root.get_texture().get_image()
		if i in [0,20,80]:image.save_png(output+"/full-%03d.png"%i)
		image.resize(240,135,Image.INTERPOLATE_LANCZOS);image.save_png(output+"/%03d.png"%i)
		samples.append({clock=clock,light_vector_step=change})
	# A paused clock must not move either the train, camera or direct light.
	var before: Basis=cycle.sun.basis
	for i in 30:cycle.update(16*3600+20);await process_frame
	var report:={samples=samples,paused_light_fixed=cycle.sun.basis==before,train_speed=train.speed,adapter=RenderingServer.get_video_adapter_name(),cycle=cycle_script}
	FileAccess.open(output+"/report.json",FileAccess.WRITE).store_string(JSON.stringify(report,"\t"));print("STATIONARY_SHADOWS ",report.paused_light_fixed)
	scene.queue_free();await process_frame;quit(0 if report.paused_light_fixed else 1)
