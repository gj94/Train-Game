extends SceneTree
## Native closest-detail/material review through the actual playable adapter.
const Stock = preload("res://sim/stock/ported_stock.gd")
var failures := 0
var checks := 0
var scene: Node3D
var camera: Camera3D

func _initialize() -> void: call_deferred("run")
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		printerr("FAIL: "+message)

func run() -> void:
	root.size = Vector2i(1200,720)
	scene = Node3D.new()
	root.add_child(scene)
	var environment = preload("res://game/world_view.gd").new()
	environment.root = scene
	environment._build_environment()
	var floor_mesh := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(1600,100)
	floor_mesh.mesh = plane
	floor_mesh.position = Vector3(800,0,0)
	var ground := StandardMaterial3D.new()
	ground.albedo_color = Color(.23,.22,.19)
	ground.roughness = 1
	floor_mesh.material_override = ground
	scene.add_child(floor_mesh)
	for side in [-1,1]:
		var rail := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = Vector3(1400,.16,.075)
		rail.mesh = box
		rail.position = Vector3(800,.42,side*.838)
		scene.add_child(rail)
	camera = Camera3D.new()
	camera.near = .035
	camera.far = 2000
	camera.fov = 64
	scene.add_child(camera)
	camera.make_current()
	DirAccess.make_dir_recursive_absolute("res://.local/coach-detail")
	var world := RailWorld.new()
	world.graph.add_node("a",Vector3.ZERO)
	world.graph.add_node("b",Vector3(1600,0,0))
	world.graph.add_edge("main","a","b")
	var vb_ec := "--vb-ec" in OS.get_cmdline_user_args()
	for family in (["vb8","vb16"] if vb_ec else ["icf","lhb"]):
		var train := Train.new("REVIEW",200)
		Stock.configure(train,family)
		world.place_train(train,"main",1000,1)
		var holder := Node3D.new()
		scene.add_child(holder)
		var view = preload("res://game/ported_train_view.gd").new()
		view.build(train,world.graph,holder,null)
		for i in view.models.size():
			if view.formation[i].model=="wap7": continue
			if vb_ec and view.formation[i].model not in ["vb_tc_ec","vb_ndtc_ec","vb_ndtc_ec2"]: continue
			var previous_failures := failures
			var model: Node3D = view.models[i]
			var spec: Dictionary = view.specs[i]
			var key: String = view.formation[i].model
			check(model.get_meta("detailed_authored_vehicle",false),key+" authored materials active")
			var triangles := 0
			var materials := {}
			var interiors := 0
			for mesh: MeshInstance3D in model.find_children("*","MeshInstance3D",true,false):
				if str(mesh.name).begins_with("Shadow_"):
					check(mesh.cast_shadow==GeometryInstance3D.SHADOW_CASTING_SETTING_SHADOWS_ONLY,key+" shadow proxy stays invisible")
					continue
				if "INTERIOR" in str(mesh.name):
					interiors += 1
					check(mesh.visibility_range_end>60 and mesh.visibility_range_end<=120,key+" interior distance culling")
				for surface in mesh.mesh.get_surface_count():
					var arrays: Array = mesh.mesh.surface_get_arrays(surface)
					triangles += (arrays[Mesh.ARRAY_INDEX] as PackedInt32Array).size()/3
					check(arrays[Mesh.ARRAY_CUSTOM0]!=null,key+" source material coordinates")
					var material := mesh.get_active_material(surface) as ShaderMaterial
					check(material!=null,key+" authored surface")
					if material == null: continue
					materials[material.resource_name] = true
					for uniform in material.shader.get_shader_uniform_list():
						if str(uniform.name).begins_with("tex"):
							check(material.get_shader_parameter(uniform.name) is Texture2D,key+" original marking image bound")
			check(triangles==spec.triangles,key+" all source triangles imported")
			check(materials.size()==spec.material_count,key+" every authored material role")
			check(interiors>0,key+" separate interior batch")
			check(not view.glass[i].is_empty(),key+" onboard optical glazing")
			view.set_passenger_view(false)
			var car: Node3D = view.cars[i]
			camera.global_position = car.global_transform*Vector3(-10,4.3,-17)
			camera.look_at(car.global_transform*Vector3(0,1.8,0))
			await capture(key+"-exterior")
			view.passenger_coach = i
			view.passenger_bay = 0
			view.passenger_seat = false
			view.set_passenger_view(true)
			view.update()
			camera.global_transform = view.passenger_transform()
			await capture(key+"-aisle")
			view.passenger_seat = true
			view.update()
			camera.global_transform = view.passenger_transform()
			await capture(key+"-seat")
			print("COACH_NATIVE_", "PASS " if failures==previous_failures else "FAIL ",key," triangles=",triangles," materials=",materials.size())
		holder.free()
		world.trains.clear()
		await process_frame
	print("Detailed coach native checks: ",checks," checks, ",failures," failures")
	quit(1 if failures else 0)

func capture(label: String) -> void:
	for frame in 12: await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://.local/coach-detail/"+label+".png")
	print("COACH_CAPTURE ",label," draw_calls=",Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)," primitives=",Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME))
