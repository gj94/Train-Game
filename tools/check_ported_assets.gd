extends SceneTree
const Stock := preload("res://sim/stock/ported_stock.gd")
const Fleet := preload("res://sim/layouts/ported_fleet.gd")
const View := preload("res://game/ported_train_view.gd")
var failures := 0

func _initialize() -> void:
	call_deferred("_check")

func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		printerr("FAIL: " + message)

func _check() -> void:
	var catalog: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/models/ported/manifest.json"))
	check(catalog.size() == 25, "25 source masters")
	for id in catalog:
		var spec: Dictionary = catalog[id]
		var scene := load("res://assets/models/ported/%s.glb" % id) as PackedScene
		check(scene != null, id + " imported")
		if scene == null: continue
		var model := scene.instantiate() as Node3D
		root.add_child(model)
		var bounds := AABB()
		var first := true
		var inward_ceiling := false
		var textures := 0
		for mesh in model.find_children("*", "MeshInstance3D", true, false):
			var box: AABB = mesh.global_transform * mesh.get_aabb()
			bounds = box if first else bounds.merge(box)
			first = false
			for i in mesh.mesh.get_surface_count():
				var material: Material = mesh.mesh.surface_get_material(i)
				check(material != null, id + " has materials")
				if material is StandardMaterial3D and material.albedo_texture != null: textures += 1
				if str(id).begins_with("vb_"):
					var arrays: Array = mesh.mesh.surface_get_arrays(i)
					var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
					var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
					for index in vertices.size():
						var point: Vector3 = mesh.global_transform * vertices[index]
						var normal: Vector3 = mesh.global_basis * normals[index]
						if point.y > 3.69 and point.y < 3.74 and absf(point.x) < .9 and normal.y < -.8:
							inward_ceiling = true
		if str(id).begins_with("vb_"): check(inward_ceiling, id + " ceiling faces passengers")
		if id == "wap7": check(textures >= 2, "WAP-7 packed instruments have textures")
		check(not first and bounds.size.y > 3.5 and bounds.size.x > 3.0, id + " standing upright at metre scale")
		# Rotated AABBs are conservative, so permit a small bevel-bound margin.
		check(bounds.position.distance_to(v(spec.bounds[0])) < .05 and bounds.end.distance_to(v(spec.bounds[1])) < .05, id + " complete source bounds")
		for kind in ["bogies", "axles"]:
			for pivot in spec[kind]:
				var node := model.find_child(pivot.node, true, false) as Node3D
				check(node != null, id + " preserved " + pivot.node)
				if node != null: check(node.global_position.distance_to(v(pivot.position)) < .001, id + " axis conversion " + pivot.node)
		var geometry := Stock.geometry(id)
		check(absf(geometry.pitch - spec.pitch) < .001, id + " sim/import pitch matches")
		check(spec.mesh_groups < 35, id + " consolidated mesh count")
		model.free()
	for choice in Stock.CHOICES:
		var world := Fleet.build(choice)
		var train: Train = world.trains.T1
		var parent := Node3D.new()
		root.add_child(parent)
		var view := View.new()
		view.build(train, world.graph, parent, null)
		check_view(view, train, world)
		if train.can_change_ends:
			var poses: Array = view.cars.map(func(car): return car.global_transform)
			check(train.reverse(world.graph), choice + " reverse")
			view.update()
			for i in poses.size():
				check(view.cars[i].global_position.distance_to(poses[i].origin) < .002, choice + " body stays put when reversing")
				check(view.cars[i].global_basis.z.distance_to(poses[i].basis.z) < .002, choice + " body keeps orientation")
			check_view(view, train, world)
		# A 600 m radius arc exercises each vehicle and bogie independently.
		var curved := RailWorld.new()
		var points := []
		for k in range(1, 800):
			var angle := float(k) / 600.0
			points.append(Vector3(600 * sin(angle), 0, 600 * (1 - cos(angle))))
		curved.graph.add_node("a", Vector3.ZERO)
		curved.graph.add_node("b", Vector3(600 * sin(800.0 / 600), 0, 600 * (1 - cos(800.0 / 600))))
		curved.graph.add_edge("curve", "a", "b", points)
		curved.place_train(train, "curve", 700, 1)
		view.graph = curved.graph
		view.update()
		check_view(view, train, curved, .02)
		parent.free()
	print("Imported assets: 25 models, 7 formations; %d failures" % failures)
	quit(1 if failures else 0)

func check_view(view, train: Train, world: RailWorld, tolerance: float = .003) -> void:
	var choice: String = view.choice
	var axles: Array = view.sound_axles()
	for axle in axles:
		var loc := train.locate_behind(world.graph, axle.x)
		var expected: Vector3 = world.graph.position(loc.edge, loc.s) + Vector3.UP * (.5 + Stock.geometry(view.formation[axle.car].model).radius)
		var found := false
		for wheel in view.axles[axle.car]:
			if wheel.global_position.distance_to(expected) < tolerance: found = true
		check(found, choice + " axle sound/mesh alignment at " + str(axle.x))
	for i in view.cars.size():
		for j in view.pantographs[i].size():
			var head: Node3D = view.pantographs[i][j][2]
			check(head.global_basis.y.dot(Vector3.UP) > .999, choice + " level pantograph head")
			check(head.global_position.y < 6.101 and head.global_position.y > 4.0, choice + " pantograph range")
	check(view.cab_transform().origin.is_finite(), choice + " cab camera")
	if choice in ["icf", "lhb", "vb8", "vb16"]:
		for i in view.cars.size():
			if view.specs[i].passengers.is_empty(): continue
			view.passenger_coach = i
			check(view.passenger_transform().origin.is_finite(), choice + " aisle camera")
			view.passenger_seat = true
			check(view.passenger_transform().origin.is_finite(), choice + " seat camera")
			view.passenger_seat = false

func v(array: Array) -> Vector3:
	return Vector3(array[0], array[1], array[2])
