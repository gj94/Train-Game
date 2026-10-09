extends SceneTree
## Isolated native material/geometry inspection, using the game's actual daylight.
func _initialize() -> void: call_deferred("capture")
func capture() -> void:
	var stage:=Node3D.new()
	root.add_child(stage)
	var view=load("res://game/world_view.gd").new()
	view.root=stage
	view._build_environment()
	var lib=load("res://game/scenery_library.gd").new(view)
	var names:=["tiled_house","courtyard_house","shop_house","corner_shop","apartments_3","warehouse","water_tower"]
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--only="): names=Array(arg.trim_prefix("--only=").split(","))
	var camera:=Camera3D.new()
	camera.fov=52
	stage.add_child(camera)
	var ground:=PlaneMesh.new()
	ground.size=Vector2(2400,150)
	var floor_mesh:=MeshInstance3D.new()
	floor_mesh.mesh=ground
	floor_mesh.position=Vector3(1000,-.035,0)
	floor_mesh.material_override=view.pbr("red_laterite_soil_stones",3.0,Color(.8,.77,.64))
	stage.add_child(floor_mesh)
	if "--no-lod" in OS.get_cmdline_user_args(): root.mesh_lod_threshold=0.0
	for kind in names:
		for part in lib.asset(kind):
			for surface in part.mesh.get_surface_count():
				var mat: Material=part.mesh.surface_get_material(surface)
				if mat is StandardMaterial3D:
					if "--no-alpha-aa" in OS.get_cmdline_user_args(): mat.alpha_antialiasing_mode=BaseMaterial3D.ALPHA_ANTIALIASING_OFF
					if "--unlit" in OS.get_cmdline_user_args(): mat.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
					if "--opaque" in OS.get_cmdline_user_args():
						mat.transparency=BaseMaterial3D.TRANSPARENCY_DISABLED
						mat.alpha_antialiasing_mode=BaseMaterial3D.ALPHA_ANTIALIASING_OFF
						mat.normal_enabled=false
					print("MATERIAL ",mat.resource_name," tint ",mat.albedo_color," UV ",mat.uv1_scale,"/",mat.uv1_offset," tex ",mat.albedo_texture.resource_path)
	for i in names.size(): lib.place(names[i],Vector3(i*100,0,0))
	lib.flush()
	if "--impostor" in OS.get_cmdline_user_args():
		for node in stage.get_children():
			if node is MultiMeshInstance3D:
				if node.name.begins_with("Canopy_"):
					node.visibility_range_begin=0
					node.visibility_range_end=0
					node.visibility_range_fade_mode=GeometryInstance3D.VISIBILITY_RANGE_FADE_DISABLED
				else: node.hide()
	if "--raw" in OS.get_cmdline_user_args():
		for node in stage.get_children():
			if node is MultiMeshInstance3D: node.queue_free()
		for i in names.size():
			var raw: Node3D=load(lib.ROOT+names[i]+".glb").instantiate()
			raw.position.x=i*100
			stage.add_child(raw)
	if "--no-lod" in OS.get_cmdline_user_args():
		for node in stage.get_children():
			if node is GeometryInstance3D: node.lod_bias=1000.0
	var prefix:="res://.local/scenery-asset"
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--output="): prefix=arg.trim_prefix("--output=")
	for i in names.size():
		var centre:=Vector3(i*100,0,0)
		camera.position=centre+Vector3(-22,10,-28)
		camera.look_at(centre+Vector3(0,3.5,0))
		if names[i].begins_with("passenger_") or names[i] in ["hatchback","auto_rickshaw","motorcycle","tea_kiosk","transformer","shrub","grass_tuft","reeds","banana_clump","country_canoe","fishing_skiff","courtyard_well","fishing_net_rack","rice_green","rice_ripe"]:
			camera.position=centre+Vector3(-5,2.5,-7)
			camera.look_at(centre+Vector3(0,1,0))
		if names[i].begins_with("passenger_"):
			camera.position=centre+Vector3(-1.9,1.3,-3.5)
			camera.look_at(centre+Vector3(0,.85,0))
		if names[i]=="tree_small_02":
			camera.position=centre+Vector3(-5.8,3.2,-8.5)
			camera.look_at(centre+Vector3(0,2.5,0))
		if names[i] in ["warehouse","rice_mill"]:
			camera.position=centre+Vector3(-34,16,-44)
			camera.look_at(centre+Vector3(0,3.5,0))
		if "--front" in OS.get_cmdline_user_args():
			camera.position=centre+Vector3(0,2.279673,-10)
			camera.look_at(centre+Vector3(0,2.279673,0))
		for frame in 24: await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(prefix+"-"+names[i]+".png")
		print("Asset inspected: ",names[i])
	quit()
