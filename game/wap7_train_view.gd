extends RefCounted
## Physical WAP-7 remains oriented when changing driving ends. Sim owns movement.

const MODEL := preload("res://assets/models/wap7.glb")
const Cab := preload("res://game/wap7_cab_view.gd")
const RAIL_TOP := 0.5
const EYE := Vector3(-.68, 2.98, -7.62)
const HALF_LENGTH := 10.281

var train: Train
var motion
var graph: TrackGraph
var cars: Array = []
var _body: Node3D
var _cabs: Array[Node3D] = []
var _cab_interior: Node3D
var _bogies: Array[Node3D] = []
var _wheels: Array[Node3D] = []
var _glass: Array = []
var _side_panels: Array[Node3D] = []
var _cab_on := false
var _lights: Array[SpotLight3D] = []
var _last_odometer := 0.0
var _wheel_angle := 0.0


func build(t: Train, g: TrackGraph, parent: Node3D, _world_view) -> void:
	train = t
	graph = g
	var car := Node3D.new()
	car.name = t.id + "_WAP7"
	parent.add_child(car)
	cars.append(car)
	_body = MODEL.instantiate()
	_body.position.y = RAIL_TOP
	car.add_child(_body)
	preload("res://game/fleet_surface.gd").apply(_body)
	for i in 2:
		var cab := Cab.new()
		cab.name = "DrivingCab%d" % (i + 1)
		_body.add_child(cab)
		cab.rotation.y = i * PI
		cab.setup(t, i + 1)
		cab.visible = false
		_cabs.append(cab)
		var light := SpotLight3D.new()
		light.position = Vector3(0, 2.35, -9.5 if i == 0 else 9.5)
		light.rotation.y = i * PI
		light.light_color = Color("fff0cc")
		light.light_energy = 2.5
		light.spot_range = 90
		light.spot_angle = 25
		light.shadow_enabled = true
		_body.add_child(light)
		_lights.append(light)
	for i in [1, 2]:
		_bogies.append(_body.find_child("Bogie_%d" % i, true, false))
	_wheels.assign(_body.find_children("Wheelset_*", "MeshInstance3D", true, false))
	_side_panels.assign(_body.find_children("03_Side_*", "MeshInstance3D", true, false))
	# Side-window boxes have inner faces; remove only their glass surfaces in cab mode.
	for node in _body.find_children("*", "MeshInstance3D", true, false):
		for s in node.mesh.get_surface_count():
			var material: Material = node.get_active_material(s)
			if material != null and material.resource_name == "WAP7_Glass":
				var clear := material.duplicate() as StandardMaterial3D
				clear.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
				clear.albedo_color.a = 0.0
				_glass.append({node = node, surface = s, clear = clear, exterior = material})
	_cab_interior = _cabs[0]
	update()


func _point(back: float) -> Vector3:
	var loc: Dictionary = motion.locate(back) if motion != null else train.locate_behind(graph, back)
	return graph.position(loc.edge, loc.s)


func update() -> void:
	var front := _point(HALF_LENGTH - 6.0)
	var rear := _point(HALF_LENGTH + 6.0)
	var fwd := front - rear
	if fwd.length_squared() < .0001:
		return
	cars[0].global_transform = Transform3D(Basis.looking_at(fwd, Vector3.UP), (front + rear) * .5)
	_body.rotation.y = 0.0 if train.cab_end == 1 else PI
	_cab_interior = _cabs[train.cab_end - 1]
	for i in 2:
		_cabs[i].visible = _cab_on and i == train.cab_end - 1
		_cabs[i].update_instruments()
		_lights[i].visible = i == train.cab_end - 1
		var back := HALF_LENGTH + (-6.0 if i == train.cab_end - 1 else 6.0)
		var direction := _point(back - 1.85) - _point(back + 1.85)
		if train.cab_end == 2:
			direction = -direction
		if direction.length_squared() > .0001:
			_bogies[i].global_basis = Basis.looking_at(direction, Vector3.UP)
	var distance: float = motion.odometer() if motion != null else train.odometer
	_wheel_angle -= (distance - _last_odometer) / .546 * (1.0 if train.cab_end == 1 else -1.0)
	_last_odometer = distance
	for wheel in _wheels:
		wheel.rotation.x = _wheel_angle


func cab_transform() -> Transform3D:
	var eye: Vector3 = _cab_interior.global_transform * EYE
	var basis: Basis = _cab_interior.global_basis
	return Transform3D(Basis.looking_at(-basis.z * 40.0 - basis.y * 6.0, Vector3.UP), eye)


func set_cab_view(on: bool) -> void:
	_cab_on = on
	# Exterior doors/window seals contain solid backing plates. The dedicated
	# cab lining replaces those assemblies from inside, keeping apertures clear.
	for panel in _side_panels:
		panel.visible = not on
	for entry in _glass:
		entry.node.set_surface_override_material(entry.surface, entry.clear if on else entry.exterior)
	update()


func head_position() -> Vector3:
	return _point(0.0)


func overview_position() -> Vector3:
	return _point(HALF_LENGTH)


## Correct Co-Co geometry with the approved existing two impact kernels.
## Kernel classes alternate within each bogie; sound data itself is unchanged.
static func sound_axles() -> Array:
	var axles := []
	for i in 2:
		for j in 3:
			axles.append({x = HALF_LENGTH - 6.0 + i * 12.0 + (j - 1) * 1.85,
				cls = i * 2 + j % 2, car = 0})
	return axles
