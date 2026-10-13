extends SceneTree
## Native silhouette equivalence and draw-count comparison of exact same trees.
var output:="res://.local/overnight-2026-10-14/tree-shadows"
var report:={checks=0,failures=0,cases=[]}
var context
var library
var originals:={}

func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--output="):output=arg.trim_prefix("--output=")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output));call_deferred("run")

func check(ok: bool,message: String) -> void:
	report.checks+=1
	if not ok:report.failures+=1;printerr("FAIL: "+message)

func capture(label: String) -> void:
	for i in 80:await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(output+"/"+label+".png")
	report.cases.append({name=label,draws=Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),
		primitives=Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME)})

func run() -> void:
	root.size=Vector2i(1600,900);DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	var scene:=Node3D.new();root.add_child(scene);current_scene=scene
	context=preload("res://game/world_view.gd").new();context.root=scene;context._build_environment();context.day_night.update(16.5*3600,true)
	var floor_node:=MeshInstance3D.new();var mesh:=BoxMesh.new();mesh.size=Vector3(250,.15,250);floor_node.mesh=mesh;floor_node.position.y=-.1
	var mat:=StandardMaterial3D.new();mat.albedo_color=Color(.5,.5,.5);mat.roughness=.9;floor_node.material_override=mat;scene.add_child(floor_node)
	library=preload("res://game/scenery_library.gd").new(context);preload("res://game/trackside_assets.gd").prepare(library)
	var names: Array=preload("res://game/trackside_assets.gd").TREES
	for i in names.size():
		var kind: String="tf3_"+names[i]
		library.place(kind,Vector3(i*15-22.5,0,0),i*.9,Vector3(1,.95,1.1))
		check(library.meshes["shadow:"+kind][0].mesh.get_surface_count()==1,"one shadow surface: "+kind)
	library.flush()
	for node in scene.get_children():
		if not node.has_meta("scenery_shadow"):continue
		var kind: String=node.get_meta("scenery_kind")
		var parts: Array=library.asset(kind+"_LOD2")
		check(parts.size()==1 and parts[0].transform==Transform3D.IDENTITY,"reference has identity source pose")
		originals[node]={merged=node.multimesh.mesh,source=parts[0].mesh}
	var camera:=Camera3D.new();scene.add_child(camera);camera.current=true;camera.far=800
	for distance in [60.0,120.0,220.0]:
		camera.position=Vector3(0,30,distance);camera.fov=45 if distance<100 else 22;camera.look_at(Vector3(0,2,0))
		for node in originals:node.multimesh.mesh=originals[node].merged
		await capture("merged_%d"%distance)
		for node in originals:node.multimesh.mesh=originals[node].source
		await capture("source_%d"%distance)
		check(report.cases[-2].draws<report.cases[-1].draws,"fewer shadow draws at %dm"%distance)
		# One shared surface culls less finely than each material's own bounds,
		# and retains the authored LOD2 instead of per-material automatic LODs.
		check(report.cases[-2].primitives<=report.cases[-1].primitives*1.08,"bounded shadow triangle tradeoff")
	report.note="Same authored LOD2 positions; one draw per shadow batch. Automatic per-material simplification/culling can make original primitive counts slightly lower. Compare native silhouette images as well as draws."
	report.complete=true;report.adapter=RenderingServer.get_video_adapter_name()
	FileAccess.open(output+"/report.json",FileAccess.WRITE).store_string(JSON.stringify(report,"\t"))
	print("SHADOW_CHECK ",JSON.stringify(report));quit(1 if report.failures else 0)
