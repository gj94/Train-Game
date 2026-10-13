extends SceneTree
## Compare shipping material batches with unchanged source geometry.
var output:="res://.local/overnight-2026-10-14/tree-palette"
var report:={checks=0,failures=0,cases=[]}
var models:=[]
var scene: Node3D
var camera: Camera3D
var context

func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--output="):output=arg.trim_prefix("--output=")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output));call_deferred("run")

func check(ok: bool,message: String) -> void:
	report.checks+=1
	if not ok:report.failures+=1;printerr("FAIL: "+message)

func capture(label: String) -> void:
	for i in 70:await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(output+"/"+label+".png")
	report.cases.append({name=label,draws=Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),
		primitives=Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME)})

func run() -> void:
	root.size=Vector2i(1600,900);DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	scene=Node3D.new();root.add_child(scene);current_scene=scene
	context=preload("res://game/world_view.gd").new();context.root=scene;context._build_environment();context.day_night.update(14.0*3600,true)
	var floor_node:=MeshInstance3D.new();var floor_mesh:=BoxMesh.new();floor_mesh.size=Vector3(300,.15,300);floor_node.mesh=floor_mesh;floor_node.position.y=-.1
	var mat:=StandardMaterial3D.new();mat.albedo_color=Color(.3,.34,.24);mat.roughness=.9;floor_node.material_override=mat;scene.add_child(floor_node)
	camera=Camera3D.new();scene.add_child(camera);camera.current=true;camera.far=1000
	var names: Array=preload("res://game/trackside_assets.gd").TREES
	for i in names.size():
		var kind: String=names[i]
		for level in ["","_LOD1","_LOD2"]:
			var packed: PackedScene=load("res://assets/models/trackside/"+kind+level+".gltf")
			var imported:=packed.instantiate()
			var source: ArrayMesh=imported.find_children("*","MeshInstance3D",true,false)[0].mesh
			var began:=Time.get_ticks_usec()
			var merged: ArrayMesh=load("res://assets/models/trackside/batched/"+kind+level+".res")
			var stats:={asset=kind+level,bake_ms=(Time.get_ticks_usec()-began)*.001,source_surfaces=source.get_surface_count(),merged_surfaces=merged.get_surface_count()}
			print("PALETTE ",JSON.stringify(stats))
			check(merged.get_surface_count()<source.get_surface_count(),"reduced surfaces: "+kind+level)
			var node:=MeshInstance3D.new();node.mesh=source;node.position=Vector3(i*15-22.5,0,0);node.rotation.y=i*.6;scene.add_child(node)
			models.append({node=node,source=source,merged=merged,level=level,stats=stats})
			imported.free()
	for level in ["","_LOD1","_LOD2"]:
		for model in models:model.node.visible=model.level==level
		for distance in [40.0,120.0]:
			camera.position=Vector3(0,8,distance);camera.fov=60 if distance<100 else 22;camera.look_at(Vector3(0,8,0))
			for model in models:model.node.mesh=model.source
			await capture("source_%s_%d"%["near" if level=="" else level,distance])
			for model in models:model.node.mesh=model.merged
			await capture("merged_%s_%d"%["near" if level=="" else level,distance])
	report.assets=models.map(func(m):return m.stats);report.complete=true
	FileAccess.open(output+"/report.json",FileAccess.WRITE).store_string(JSON.stringify(report,"\t"))
	print("PALETTE_CHECK ",JSON.stringify(report));quit(1 if report.failures else 0)
