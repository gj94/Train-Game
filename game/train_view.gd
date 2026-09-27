extends RefCounted
## Low-poly 8-car MEMU that follows a sim Train along the track.
## Car 0 is always the car at the train's head; both end cars have cabs, so
## changing ends just re-assigns which physical end is "car 0".

const CAR_LENGTH := 21.3
const CAR_GAP := 0.6
const BOGIE_INSET := 3.0
const RAIL_TOP := 0.5

var train: Train
var graph: TrackGraph
var cars: Array = []            # Node3D per car
var _head_lights: Array = []    # [MeshInstance3D x2] at the front of car 0
var _tail_lights: Array = []    # at the back of the last car
var _front_end: Array = []      # lead cab's outer face, hidden in cab view so the driver can see out
var _cab_interior: Node3D       # dashboard + window frame, shown only in cab view
var _wv                         # world_view, for materials


func build(t: Train, g: TrackGraph, parent: Node3D, world_view) -> void:
	train = t
	graph = g
	_wv = world_view
	var n := int(round((t.length + CAR_GAP) / (CAR_LENGTH + CAR_GAP)))
	for i in n:
		var car := Node3D.new()
		car.name = "%s_car%d" % [t.id, i]
		parent.add_child(car)
		_build_car(car, i == 0, i == n - 1, i == 2 or i == n - 3)
		cars.append(car)
	update()


func _build_car(car: Node3D, front_cab: bool, rear_cab: bool, pantograph: bool) -> void:
	var L := CAR_LENGTH
	var white := Color(0.94, 0.94, 0.92)
	var blue := Color(0.12, 0.3, 0.62)
	var glass := Color(0.12, 0.16, 0.2)
	var grey := Color(0.5, 0.5, 0.52)
	var dark := Color(0.16, 0.16, 0.17)
	var y0 := RAIL_TOP
	_wv.box(Vector3(2.9, 0.7, L - 1.0), Vector3(0, y0 + 0.85, 0), dark, car)            # underframe
	for z in [-(L * 0.5 - BOGIE_INSET), L * 0.5 - BOGIE_INSET]:
		_wv.box(Vector3(2.5, 0.65, 3.2), Vector3(0, y0 + 0.45, z), dark, car)          # bogies
	_wv.box(Vector3(3.25, 0.9, L), Vector3(0, y0 + 1.65, 0), blue, car)               # lower body
	_wv.box(Vector3(3.2, 0.95, L - 0.4), Vector3(0, y0 + 2.55, 0), glass, car)        # window band
	for z in [-L * 0.5 + 4.5, L * 0.5 - 4.5]:                                         # doors (both sides)
		_wv.box(Vector3(3.27, 2.1, 1.5), Vector3(0, y0 + 2.2, z), Color(0.85, 0.85, 0.85), car)
	_wv.box(Vector3(3.25, 0.55, L), Vector3(0, y0 + 3.3, 0), white, car)              # upper body
	_wv.box(Vector3(2.9, 0.35, L - 0.3), Vector3(0, y0 + 3.75, 0), grey, car)         # roof
	_wv.box(Vector3(3.27, 0.18, L + 0.02), Vector3(0, y0 + 2.05, 0), Color(0.95, 0.55, 0.1), car)  # orange stripe
	if pantograph:
		_wv.box(Vector3(1.6, 0.2, 1.6), Vector3(0, y0 + 4.0, 0), dark, car)
		var arm: MeshInstance3D = _wv.box(Vector3(0.08, 1.4, 0.08), Vector3(0, y0 + 4.6, 0), dark, car)
		arm.rotation.x = 0.6
		_wv.box(Vector3(1.8, 0.08, 0.2), Vector3(0, y0 + 5.2, 0.35), dark, car)
	if front_cab:
		_head_lights = _build_cab_end(car, -1)
	if rear_cab:
		_tail_lights = _build_cab_end(car, 1)


## Cab face at the -Z (side = -1) or +Z (side = 1) end. Returns its two lamps.
func _build_cab_end(car: Node3D, side: int) -> Array:
	var z := side * (CAR_LENGTH * 0.5 + 0.05)
	var y0 := RAIL_TOP
	var parts := []
	parts.append(_wv.box(Vector3(3.25, 1.9, 0.12), Vector3(0, y0 + 2.0, z), Color(0.98, 0.78, 0.1), car))   # yellow nose
	parts.append(_wv.box(Vector3(2.6, 0.9, 0.14), Vector3(0, y0 + 2.75, z), Color(0.1, 0.12, 0.15), car))  # windscreen
	var lamps := []
	for x in [-1.1, 1.1]:
		lamps.append(_wv.box(Vector3(0.35, 0.25, 0.16), Vector3(x, y0 + 1.5, z), Color.WHITE, car))
	if side < 0:
		_front_end = parts + lamps
		_build_cab_interior(car, z)
	return lamps


func _build_cab_interior(car: Node3D, z_front: float) -> void:
	_cab_interior = Node3D.new()
	car.add_child(_cab_interior)
	var y0 := RAIL_TOP
	var frame := Color(0.2, 0.2, 0.22)
	_wv.box(Vector3(3.1, 0.55, 0.9), Vector3(0, y0 + 2.2, z_front + 0.55), Color(0.28, 0.3, 0.33), _cab_interior)  # desk
	_wv.box(Vector3(0.9, 0.12, 0.5), Vector3(-0.75, y0 + 2.5, z_front + 0.7), Color(0.12, 0.12, 0.12), _cab_interior)  # instrument panel
	_wv.box(Vector3(3.1, 0.35, 0.12), Vector3(0, y0 + 3.2, z_front + 0.1), frame, _cab_interior)                    # top frame
	for x in [-1.55, 0.0, 1.55]:
		_wv.box(Vector3(0.14 if x == 0.0 else 0.2, 1.0, 0.12), Vector3(x, y0 + 2.9, z_front + 0.1), frame, _cab_interior)  # pillars
	_cab_interior.visible = false


## World position and forward direction `back` metres behind the head.
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
	for l in _head_lights:
		l.material_override = _wv.mat(Color(1.0, 0.97, 0.85), true)
	for l in _tail_lights:
		l.material_override = _wv.mat(Color(0.9, 0.05, 0.05), true)


## Driver's eye point in the leading cab (left-hand seat) and look direction.
func cab_transform() -> Transform3D:
	var car: Node3D = cars[0]
	var b := car.global_transform.basis
	var eye := car.global_transform * Vector3(-0.75, RAIL_TOP + 2.75, -CAR_LENGTH * 0.5 + 1.7)
	var ahead := eye - b.z * 40.0 - b.y * 1.2
	return Transform3D(Basis.looking_at(ahead - eye, Vector3.UP), eye)


func set_cab_view(on: bool) -> void:
	for part in _front_end:
		part.visible = not on
	_cab_interior.visible = on


func head_position() -> Vector3:
	return _point(0.0)
