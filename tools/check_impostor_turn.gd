extends SceneTree
## Compare angle-boundary continuity, including wraparound, on the real atlas.
var output:="res://.local/overnight-2026-10-14/impostor-turn"
var report:={complete=false,cases=[]}
var material: ShaderMaterial
var camera: Camera3D
var scene: Node3D
var context
var timing:=preload("res://game/render_telemetry.gd").new()

func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--output="):output=arg.trim_prefix("--output=")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output));call_deferred("run")

func capture(label: String,angle: float) -> void:
	camera.position=Vector3(sin(deg_to_rad(angle))*200,10,cos(deg_to_rad(angle))*200)
	camera.look_at(Vector3(0,10,0))
	for i in 20:await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(output+"/"+label+".png")

func measure(label: String) -> void:
	for i in 120:await process_frame
	var values:=[];var gpu:=[];var last:=Time.get_ticks_usec()
	var began:=Time.get_ticks_msec()
	while Time.get_ticks_msec()-began<4000:
		await process_frame
		var now:=Time.get_ticks_usec();values.append((now-last)*.001);last=now
		gpu.append(timing.sample(root.get_viewport_rid()).x)
	values.sort();gpu.sort()
	report.cases.append({name=label,frame_median_ms=values[values.size()/2],gpu_median_ms=gpu[gpu.size()/2],frames=values.size()})

func run() -> void:
	root.size=Vector2i(1280,720);DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	root.msaa_3d=Viewport.MSAA_8X
	scene=Node3D.new();root.add_child(scene);current_scene=scene
	context=preload("res://game/world_view.gd").new();context.root=scene;context._build_environment();context.day_night.update(14*3600,true)
	# Fixed background isolates silhouette changes from moving photographic clouds.
	context.day_night.environment.background_mode=Environment.BG_COLOR
	context.day_night.environment.background_color=Color(.035,.045,.06)
	camera=Camera3D.new();scene.add_child(camera);camera.current=true;camera.fov=12;camera.far=1000
	RenderingServer.viewport_set_measure_render_time(root.get_viewport_rid(),true)
	var name:="KL_LS_Coconut_Leaning_B"
	var catalogue: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://assets/models/trackside/impostors/catalog.json"))
	var entry: Dictionary=catalogue["tf3_"+name]
	var quad:=QuadMesh.new();quad.size=Vector2.ONE*entry.width;quad.center_offset=Vector3(0,entry.centre[1],0)
	material=ShaderMaterial.new();material.shader=load("res://game/shaders/scenery_impostor.gdshader")
	material.set_shader_parameter("centre_y",0.0)
	material.set_shader_parameter("view_count",float(entry.get("views",8)))
	material.set_shader_parameter("atlas_columns",float(entry.get("columns",4)))
	material.set_shader_parameter("colour_atlas",load("res://assets/models/trackside/impostors/"+name+"_albedo.png"))
	material.set_shader_parameter("normal_atlas",load("res://assets/models/trackside/impostors/"+name+"_normal.png"))
	quad.material=material
	var tree:=MeshInstance3D.new();tree.mesh=quad;tree.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	tree.custom_aabb=AABB(Vector3(-20,-1,-20),Vector3(40,40,40));scene.add_child(tree)
	for enabled in [false,true]:
		material.set_shader_parameter("blend_views",enabled)
		var prefix:="blend" if enabled else "nearest"
		for angle in [2.3125,2.5625,2.8125,3.0625,3.3125,21.5,22.0,22.5,23.0,23.5,356.6875,357.1875,357.6875]:
			await capture(prefix+"_"+str(angle).replace(".","p"),angle)
	camera.fov=65
	await capture("natural_fov_blend",2.8125)
	# Fill the same screen with an overlapping distant grove to expose the extra
	# atlas samples. Relative microbenchmark only, not a whole-game claim.
	camera.fov=60;camera.position=Vector3(0,10,200);camera.look_at(Vector3(0,10,0))
	for i in 96:
		var node:=MeshInstance3D.new();node.mesh=quad
		node.position=Vector3((i%16-8)*9,0,-float(i/16)*8);node.rotation.y=i*.7
		node.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF;node.custom_aabb=tree.custom_aabb;scene.add_child(node)
	for enabled in [false,true,false]:
		material.set_shader_parameter("blend_views",enabled);await measure("blend" if enabled else "nearest")
	timing.close();report.complete=true;report.adapter=RenderingServer.get_video_adapter_name();report.msaa="8x"
	report.views=entry.get("views",8);report.video_bytes=Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED)
	FileAccess.open(output+"/report.json",FileAccess.WRITE).store_string(JSON.stringify(report,"\t"))
	print("IMPOSTOR_TURN ",JSON.stringify(report));quit()
