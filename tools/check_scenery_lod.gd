extends SceneTree
## Native Forward+ checks: real imported transforms, shared bounds and transitions.
var context
var library
var output:="res://.local/overnight-2026-10-14/lod"
var report:={checks=0,failures=0,cases=[]}

func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--output="):output=arg.trim_prefix("--output=")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output))
	call_deferred("run")

func check(ok: bool,message: String) -> void:
	report.checks+=1
	if not ok:report.failures+=1;printerr("FAIL: "+message)

func run() -> void:
	root.size=Vector2i(1600,900)
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	var scene:=Node3D.new();root.add_child(scene);current_scene=scene
	context=preload("res://game/world_view.gd").new();context.root=scene
	context._build_environment();context.day_night.update(12*3600,true)
	var floor_node:=MeshInstance3D.new();var floor_mesh:=BoxMesh.new()
	floor_mesh.size=Vector3(500,.15,700);floor_node.mesh=floor_mesh;floor_node.position.y=-.15
	var floor_material:=StandardMaterial3D.new();floor_material.albedo_color=Color(.3,.34,.24);floor_material.roughness=.9
	floor_node.material_override=floor_material;scene.add_child(floor_node)
	library=preload("res://game/scenery_library.gd").new(context)
	preload("res://game/trackside_assets.gd").prepare(library)
	for name in ["tf3_KL_LS_Coconut_Tall_A","tf3_KL_LS_Jackfruit_Tree","tf3_BLD_Home_Verandah_01"]:
		for i in 4:
			var x: float=-30.0+i*20.0
			var z: float=-35.0 if "Jackfruit" in name else (45.0 if "BLD" in name else 0.0)
			library.place(name,Vector3(x,0,z),i*.65,Vector3(1,.85+i*.1,1))
	library.flush()
	var groups:={}
	for node in scene.get_children():
		if not node is MultiMeshInstance3D or not node.has_meta("scenery_kind"):continue
		var key: String=str(node.get_meta("scenery_kind"))+str(node.position)
		if groups.has(key):
			check(node.custom_aabb==groups[key].custom_aabb,"matched native bounds "+key)
			check(node.multimesh.instance_count==groups[key].multimesh.instance_count,"matched placement count "+key)
		else:groups[key]=node
		check(node.custom_aabb.size.length()>1,"nonempty native bounds")
		for i in node.multimesh.instance_count:
			check(node.custom_aabb.encloses(node.multimesh.get_instance_transform(i)*node.multimesh.mesh.get_aabb()),"native transform inside bounds")
	var camera:=Camera3D.new();scene.add_child(camera);camera.current=true;camera.far=1000
	for distance in [35.0,45.0,55.0,85.0,95.0,105.0,180.0,190.0,200.0]:
		camera.position=Vector3(0,4,distance+60);camera.look_at(Vector3(0,5,-10))
		for i in 40:await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(output+"/distance_%03d.png" % distance)
		report.cases.append({distance=distance,draws=Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),
			objects=Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME),primitives=Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME)})
	# Change preference and origin after construction: density and LOD groups
	# must still agree, without rebuilding geometry or losing native transforms.
	var graphics:=preload("res://game/graphics_options.gd").new();graphics.preset("Performance")
	graphics.apply_tree(scene);scene.position=Vector3(-1024,0,-2048)
	camera.position=Vector3(0,4,155);camera.look_at(scene.position+Vector3(0,5,-10))
	for i in 40:await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(output+"/rebased_performance.png")
	report.complete=true;report.adapter=RenderingServer.get_video_adapter_name()
	FileAccess.open(output+"/report.json",FileAccess.WRITE).store_string(JSON.stringify(report,"\t"))
	print("LOD_CHECK ",JSON.stringify(report));quit(1 if report.failures else 0)
