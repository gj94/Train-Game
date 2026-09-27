extends RefCounted
## Indian Railways MEMU (car count from the train length) (model: assets/models/memu.glb, built by
## tools/blender/build_memu.py) following a sim Train along the track.
## Car 0 is always the car at the train's head; both end cars are cab cars, so
## changing ends just re-assigns which physical end is "car 0".

const MODEL := "res://assets/models/memu.glb"
const CAR_LENGTH := 21.3
const CAR_GAP := 0.6
const BOGIE_INSET := 3.0
const RAIL_TOP := 0.5
const EYE := Vector3(-0.75, 2.78, -CAR_LENGTH * 0.5 + 1.25)   # driver's eye, car-local (left-hand seat)

var train: Train
var graph: TrackGraph
var cars: Array = []            # Node3D per car (positioned on the track)
var _front_lamps: Array = []    # lamps at the head of the train
var _rear_lamps: Array = []     # lamps at the tail
var _cab_interior: Node3D       # shown only in cab view
var _wv                         # world_view, for materials


func build(t: Train, g: TrackGraph, parent: Node3D, world_view) -> void:
	train = t
	graph = g
	_wv = world_view
	var template: Node3D = (load(MODEL) as PackedScene).instantiate()
	var n := int(round((t.length + CAR_GAP) / (CAR_LENGTH + CAR_GAP)))
	for i in n:
		var car := Node3D.new()
		car.name = "%s_car%d" % [t.id, i]
		parent.add_child(car)
		var kind := "TrailerCar"
		if i == 0 or i == n - 1:
			kind = "CabCar"
		elif i == 2 or i == n - 3:
			kind = "MotorCar"
		var body: Node3D = template.get_node(kind).duplicate()
		body.position = Vector3(0, RAIL_TOP, 0)
		if i == n - 1 and n > 1:
			body.rotation.y = PI     # rear cab car faces backwards
		car.add_child(body)
		if kind == "CabCar":
			var lamps := body.find_children("Lamp_*", "", true, false)
			if i == 0:
				_front_lamps = lamps
			else:
				_rear_lamps = lamps
		cars.append(car)
	template.free()
	_build_cab_interior(cars[0])
	update()


## Simple driving cab around the camera: desk, windscreen frame, walls, ceiling.
## (The body shell is single-sided, so from inside it is invisible.)
func _build_cab_interior(car: Node3D) -> void:
	_cab_interior = Node3D.new()
	car.add_child(_cab_interior)
	var y0 := RAIL_TOP
	var front := -CAR_LENGTH * 0.5
	var trim: Material = _wv.mat(Color(0.55, 0.58, 0.6))
	var dark: Material = _wv.mat(Color(0.12, 0.13, 0.14))
	var desk: Material = _wv.mat(Color(0.3, 0.33, 0.36))
	_wv.box_m(Vector3(3.5, 0.4, 0.75), Vector3(0, y0 + 2.2, front + 0.5), desk, _cab_interior)            # desk
	var panel: MeshInstance3D = _wv.box_m(Vector3(1.0, 0.06, 0.45), Vector3(-0.75, y0 + 2.43, front + 0.62), dark, _cab_interior)
	panel.rotation.x = 0.35                                                                                # instrument panel
	_wv.box_m(Vector3(0.12, 0.16, 0.12), Vector3(-0.2, y0 + 2.5, front + 0.75), dark, _cab_interior)      # master controller
	_wv.box_m(Vector3(3.5, 0.06, 2.4), Vector3(0, y0 + 3.36, front + 1.2), trim, _cab_interior)           # ceiling
	_wv.box_m(Vector3(3.5, 0.3, 0.1), Vector3(0, y0 + 3.3, front + 0.35), dark, _cab_interior)            # windscreen top frame
	for x in [-1.65, 0.0, 1.65]:
		_wv.box_m(Vector3(0.12 if x == 0.0 else 0.2, 0.95, 0.1), Vector3(x, y0 + 2.85, front + 0.3), dark, _cab_interior)
	for side in [-1, 1]:
		_wv.box_m(Vector3(0.06, 1.25, 2.4), Vector3(side * 1.76, y0 + 1.75, front + 1.2), trim, _cab_interior)   # lower side walls
		_wv.box_m(Vector3(0.06, 0.25, 2.4), Vector3(side * 1.76, y0 + 3.22, front + 1.2), trim, _cab_interior)   # above side windows
	_wv.box_m(Vector3(3.5, 2.3, 0.06), Vector3(0, y0 + 2.3, front + 2.4), trim, _cab_interior)             # back wall
	_wv.box_m(Vector3(3.5, 0.06, 2.4), Vector3(0, y0 + 1.18, front + 1.2), dark, _cab_interior)            # floor
	_cab_interior.visible = false


## World position `back` metres behind the head.
func _point(back: float) -> Vector3:
	var loc := train.locate_behind(graph, back)
	return graph.position(loc.edge, loc.s)


func update() -> void:
	var step := CAR_LENGTH + CAR_GAP
	for i in cars.size():
		var front := _point(i * step + BOGIE_INSET)
		var rear := _point(i * step + CAR_LENGTH - BOGIE_INSET)
		var fwd := front - rear
		if fwd.length_squared() < 0.0001:
			continue
		cars[i].global_transform = Transform3D(Basis.looking_at(fwd, Vector3.UP), (front + rear) * 0.5)
	for l in _front_lamps:
		l.material_override = _wv.mat(Color(1.0, 0.97, 0.85), true)
	for l in _rear_lamps:
		l.material_override = _wv.mat(Color(0.9, 0.05, 0.05), true)


## Driver's eye point in the leading cab and look direction.
func cab_transform() -> Transform3D:
	var car: Node3D = cars[0]
	var b := car.global_transform.basis
	var eye := car.global_transform * (EYE + Vector3(0, RAIL_TOP, 0))
	var ahead := eye - b.z * 40.0 - b.y * 1.0
	return Transform3D(Basis.looking_at(ahead - eye, Vector3.UP), eye)


func set_cab_view(on: bool) -> void:
	_cab_interior.visible = on


func head_position() -> Vector3:
	return _point(0.0)
