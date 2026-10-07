extends SceneTree
## Geometry/material preservation and native visual inspection of the v02 port.
var failures := 0
func _initialize() -> void: call_deferred("run")
func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		printerr("FAIL: "+message)
func run() -> void:
	var spec: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/models/ported/manifest.json")).wap7
	check(spec.source_revision=="de45b4e0e4194af47b1182800b7d103409c69478","pinned detailed source")
	check(spec.triangles==2885744,"all visible evaluated source triangles retained")
	var scene := Node3D.new()
	root.add_child(scene)
	var world := RailWorld.new()
	world.graph.add_node("a",Vector3.ZERO)
	world.graph.add_node("b",Vector3(1500,0,0))
	world.graph.add_edge("main","a","b")
	world.scenery = {x_min=0,x_max=1500}
	var capture := "--capture" in OS.get_cmdline_user_args()
	var wv = preload("res://game/world_view.gd").new()
	if capture: wv.build(world,scene)
	var train := Train.new("WAP",20.4)
	preload("res://sim/stock/ported_stock.gd").configure(train,"wap7")
	world.place_train(train,"main",813,1)
	var view := preload("res://game/ported_train_view.gd").new()
	view.build(train,world.graph,scene,wv)
	var model: Node3D = view.models[0]
	check(model.get_meta("detailed_wap7",false),"authored materials applied")
	var triangles := 0
	var shaders := {}
	for mesh: MeshInstance3D in model.find_children("*","MeshInstance3D",true,false):
		if str(mesh.name).begins_with("Shadow_"):
			check(mesh.cast_shadow==GeometryInstance3D.SHADOW_CASTING_SETTING_SHADOWS_ONLY,"proxy never replaces visible source geometry")
			continue
		for i in mesh.mesh.get_surface_count():
			var arrays := mesh.mesh.surface_get_arrays(i)
			triangles += (arrays[Mesh.ARRAY_INDEX] as PackedInt32Array).size()/3
			check(arrays[Mesh.ARRAY_CUSTOM0]!=null,"32-bit original material coordinates preserved")
			var m := mesh.get_active_material(i) as ShaderMaterial
			check(m!=null,"every detailed surface has its authored graph")
			if m!=null:
				shaders[m.resource_name]=true
				for uniform in m.shader.get_shader_uniform_list():
					if str(uniform.name).begins_with("tex"):
						check(m.get_shader_parameter(uniform.name) is Texture2D,"source texture loaded: "+m.resource_name)
	check(triangles==spec.triangles,"Godot imported every source triangle")
	check(shaders.size()==spec.material_count,"all authored material roles retained")
	check(model.find_child("MACHINERY_INTERIOR",true,false)!=null,"machinery room preserved")
	for i in [1,2]:
		check(model.find_child("CABV02_%d_Rear_door_hinge"%i,true,false)!=null,"cab door hinge retained")
	check(not view.glass[0].is_empty(),"cab glazing has a clear onboard optical variant")
	for pane in view.glass[0]:
		var role: String = pane.exterior.resource_name.to_lower()
		check("laminated_cab_glass" in role or "windscreen" in role,"decals, instruments and lenses retain authored materials")
	var driver_eye := view.cab_transform().origin
	for position in 4:
		check(not view.cycle_cab_position().is_empty(),"cab inspection positions reachable")
		check(view.cab_transform().origin.is_finite(),"valid inspection camera")
	check(view.cab_transform().origin.distance_to(driver_eye)<.001,"inspection cycle returns to driver")
	check(train.reverse(world.graph),"light engine changes driving ends")
	view.update()
	check(view.cab_transform().origin.distance_to(driver_eye)>15,"other cab is a distinct driver position")
	check(train.reverse(world.graph),"restore original driving end")
	view.update()
	if capture:
		var camera := Camera3D.new()
		camera.near=.03
		camera.far=2200
		camera.fov=58
		scene.add_child(camera)
		camera.make_current()
		DirAccess.make_dir_recursive_absolute("res://.local/wap7-detail")
		var car: Node3D=view.cars[0]
		for shot in [
			["exterior",Vector3(-14,5,-20),Vector3(0,2,0)],
			["exterior_other_side",Vector3(12,4,-17),Vector3(0,2,-1)],
			["bogie",Vector3(-3.6,1.0,-6.0),Vector3(0,.7,-6.0)],
			["cab_A",Vector3(-.78,3.05,-7.98),Vector3(-.65,2.72,-9.6)],
			["cab_overview",Vector3(0,3.13,-7.47),Vector3(0,2.68,-8.96)],
			["cab_B",Vector3(.78,3.05,7.98),Vector3(.65,2.72,9.6)],
			["machinery",Vector3(0,3.0,-6.6),Vector3(0,2.5,2.0)],
			["roof",Vector3(-8,8,-12),Vector3(0,4,0)]]:
			view.set_cab_view("cab" in shot[0] or shot[0]=="machinery")
			view.update()
			camera.global_position=car.global_transform*shot[1]
			camera.look_at(car.global_transform*shot[2])
			if shot[0]=="machinery": view._interior_light.global_position=camera.global_position
			for frame in 20: await process_frame
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("res://.local/wap7-detail/"+shot[0]+".png")
			print("CAPTURE ",shot[0])
	scene.free()
	print("Detailed WAP-7: ",triangles," triangles; ",shaders.size()," materials; ",failures," failures")
	quit(1 if failures else 0)
