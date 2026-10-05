extends RefCounted
## Adapter for the user's Blender fleet. Simulation owns motion and occupancy.
const Stock := preload("res://sim/stock/ported_stock.gd")
const RAIL_TOP := .5
const CONTACT_HEIGHT := 5.6
var train: Train
var graph: TrackGraph
var choice := ""
var cars: Array[Node3D] = []
var models: Array[Node3D] = []
var specs: Array = []
var formation: Array = []
var bogies: Array = []
var axles: Array = []
var pantographs: Array = []
var glass: Array = []
var lamps: Array = []
var passenger_coach := 0
var passenger_bay := 0
var passenger_seat := false
var passenger_on := false
var cab_on := false
var _last_odometer := 0.0
var _wheel_angles: Array[float] = []
var _interior_light: OmniLight3D


func build(t: Train, g: TrackGraph, parent: Node3D, _world_view) -> void:
	train = t
	graph = g
	choice = t.stock_kind.trim_prefix("ported:")
	formation = Stock.formation(choice)
	var catalog: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/models/ported/manifest.json"))
	for entry in formation:
		var spec: Dictionary = catalog[entry.model]
		specs.append(spec)
		var car := Node3D.new()
		car.name = "%s_%s_%d" % [t.id, entry.model, cars.size()]
		parent.add_child(car)
		cars.append(car)
		var model: Node3D = (load("res://assets/models/ported/%s.glb" % entry.model) as PackedScene).instantiate()
		car.add_child(model)
		models.append(model)
		var car_bogies := []
		for pivot in spec.bogies:
			car_bogies.append(model.find_child(pivot.node, true, false))
		bogies.append(car_bogies)
		var car_axles := []
		for pivot in spec.axles:
			car_axles.append(model.find_child(pivot.node, true, false))
		axles.append(car_axles)
		_wheel_angles.append(0.0)
		var car_pantos := []
		for mechanism in spec.pantographs:
			var pivots := []
			for node_name in mechanism.nodes:
				pivots.append(model.find_child(node_name, true, false))
			car_pantos.append(pivots)
		pantographs.append(car_pantos)
		var car_glass := []
		for mesh in model.find_children("*", "MeshInstance3D", true, false):
			# Engine-generated mesh LODs handle distant views. Interior-only groups
			# disappear beyond 100 m, keeping full detail for onboard cameras.
			if "INTERIOR" in str(mesh.name):
				mesh.visibility_range_end = 100.0
				mesh.visibility_range_end_margin = 15.0
			for surface in mesh.mesh.get_surface_count():
				var material: Material = mesh.mesh.surface_get_material(surface)
				if material is StandardMaterial3D and material.transparency != BaseMaterial3D.TRANSPARENCY_DISABLED:
					var clear := material.duplicate() as StandardMaterial3D
					clear.albedo_color.a = 0
					car_glass.append({node = mesh, surface = surface, clear = clear})
		glass.append(car_glass)
		var front := SpotLight3D.new()
		front.position = Vector3(0, 2.25, -entry.pitch * .5 + .30)
		front.spot_range = 100
		front.spot_angle = 25
		front.light_color = Color("fff1d7")
		front.light_energy = 2.5
		car.add_child(front)
		var rear := SpotLight3D.new()
		rear.position = Vector3(0, 2.25, entry.pitch * .5 - .30)
		rear.rotation.y = PI
		rear.spot_range = 100
		rear.spot_angle = 25
		rear.light_color = front.light_color
		rear.light_energy = 2.5
		car.add_child(rear)
		lamps.append([front, rear])
	_interior_setup(parent)
	passenger_coach = 1 if choice in ["icf", "lhb"] else 0
	update()


func _interior_setup(parent: Node3D) -> void:
	_interior_light = OmniLight3D.new()
	_interior_light.name = "ImportedInteriorLight"
	_interior_light.light_color = Color("e4eef5")
	_interior_light.light_energy = .55
	_interior_light.omni_range = 8
	_interior_light.shadow_enabled = false
	_interior_light.visible = false
	parent.add_child(_interior_light)


func _point(back: float) -> Vector3:
	var loc := train.locate_behind(graph, clampf(back, 0.0, train.length))
	return graph.position(loc.edge, loc.s)


func _center(index: int) -> float:
	return train.length - formation[index].center if train.cab_end == 2 else formation[index].center


func _direction(index: int) -> float:
	return -1.0 if bool(formation[index].reverse) != (train.cab_end == 2) else 1.0


func update() -> void:
	var travelled := train.odometer - _last_odometer
	_last_odometer = train.odometer
	for i in cars.size():
		var back := _center(i)
		var sign_dir := _direction(i)
		var half: float = Stock.geometry(formation[i].model).bogie
		var front := _point(back - half)
		var rear := _point(back + half)
		if front.distance_squared_to(rear) < .0001: continue
		cars[i].global_transform = Transform3D(Basis.looking_at((front - rear) * sign_dir, Vector3.UP), (front + rear) * .5 + Vector3.UP * RAIL_TOP)
		for j in bogies[i].size():
			var position := _v(specs[i].bogies[j].position)
			var bogie_back := back + sign_dir * position.z
			var a := _point(bogie_back - 1.0)
			var b := _point(bogie_back + 1.0)
			if a.distance_squared_to(b) > .0001:
				bogies[i][j].global_transform = Transform3D(Basis.looking_at((a - b) * sign_dir, Vector3.UP), _point(bogie_back) + Vector3.UP * (RAIL_TOP + position.y))
		_wheel_angles[i] -= travelled * sign_dir / float(specs[i].axles[0].radius)
		for axle in axles[i]: axle.rotation.x = _wheel_angles[i]
		_update_pantographs(i)
		var leading := i == (cars.size() - 1 if train.cab_end == 2 else 0)
		lamps[i][0].visible = leading and sign_dir > 0
		lamps[i][1].visible = leading and sign_dir < 0
	if _interior_light != null and (cab_on or passenger_on):
		var camera := passenger_transform() if passenger_on else cab_transform()
		_interior_light.global_position = camera.origin + Vector3.UP * .5


func _update_pantographs(index: int) -> void:
	for j in pantographs[index].size():
		var mechanism: Dictionary = specs[index].pantographs[j]
		var raised := true
		if pantographs[index].size() == 2:
			raised = ("REAR" in mechanism.nodes[0]) == (train.cab_end == 1)
		elif choice == "wag12":
			raised = index == (1 if train.cab_end == 1 else 0)
		var angle: float = asin((CONTACT_HEIGHT - mechanism.base) / mechanism.arms) if raised else mechanism.lower_angle
		for k in 3:
			# Source Y axis maps to Godot -X. The centre joint counter-rotates.
			pantographs[index][j][k].rotation.x = -mechanism.sign * angle * (-2.0 if k == 1 else 1.0)


func cab_transform() -> Transform3D:
	var i := cars.size() - 1 if train.cab_end == 2 else 0
	var eyes: Array = specs[i].eyes
	var opposite := cars.size() == 1 and train.cab_end == 2
	var eye := _v(eyes[1 if opposite else 0].position)
	var look := Vector3(0, -.06, 1 if opposite else -1)
	var transform := cars[i].global_transform
	return Transform3D(Basis.looking_at(transform.basis * look, Vector3.UP), transform * eye)


func set_cab_view(on: bool) -> void:
	cab_on = on
	_apply_glass()


func set_passenger_view(on: bool) -> void:
	passenger_on = on
	_apply_glass()


func _apply_glass() -> void:
	var active := passenger_coach if passenger_on else (cars.size() - 1 if train.cab_end == 2 else 0)
	for i in glass.size():
		for pane in glass[i]:
			pane.node.set_surface_override_material(pane.surface, pane.clear if i == active and (cab_on or passenger_on) else null)
	_interior_light.visible = cab_on or passenger_on


func change_passenger_coach(delta: int) -> void:
	passenger_coach = posmod(passenger_coach + delta, cars.size())
	while specs[passenger_coach].passengers.is_empty():
		passenger_coach = posmod(passenger_coach + delta, cars.size())
	passenger_bay = 0
	_apply_glass()


func change_passenger_bay(delta: int) -> void:
	passenger_bay = posmod(passenger_bay + delta, 9)


func passenger_transform() -> Transform3D:
	var model: String = formation[passenger_coach].model
	var aisle := 0.0
	if model.ends_with("_1a"): aisle = -1.05
	elif model.right(2) in ["2a", "3a", "sl"]: aisle = -.60
	var eye := Vector3(aisle, 2.65, 6.5 - passenger_bay * 1.6)
	var look := Vector3(0, -.02, -1)
	if passenger_seat:
		var seats: Array = specs[passenger_coach].passengers
		var seat: Dictionary = seats[mini(passenger_bay * maxi(1, seats.size() / 9), seats.size() - 1)]
		eye = _v(seat.position) + Vector3.UP * 1.12
		look = _v(seat.forward) + Vector3.DOWN * .04
	var transform := cars[passenger_coach].global_transform
	return Transform3D(Basis.looking_at(transform.basis * look, Vector3.UP), transform * eye)


func passenger_name() -> String:
	return "%s · CAR %d · %s %d" % [str(formation[passenger_coach].model).to_upper().replace("_", " "), passenger_coach + 1, "SEAT" if passenger_seat else "AISLE", passenger_bay + 1]


func interior_audio_position() -> Vector2:
	var i := passenger_coach if passenger_on else (cars.size() - 1 if train.cab_end == 2 else 0)
	var camera := passenger_transform() if passenger_on else cab_transform()
	var eye := cars[i].to_local(camera.origin)
	return Vector2(_center(i) + _direction(i) * eye.z, maxf(.8, eye.y - .5))


func passenger_audio_position() -> Vector2:
	return interior_audio_position()


func head_position() -> Vector3:
	return _point(0)


func overview_position() -> Vector3:
	return _point(train.length * .5)


func sound_axles() -> Array:
	return Stock.sound_axles(choice, train.cab_end == 2)


func _v(value: Array) -> Vector3:
	return Vector3(value[0], value[1], value[2])
