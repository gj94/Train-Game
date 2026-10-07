extends RefCounted
## Indian Railways MEMU (car count from the train length) (model: assets/models/memu.glb, built by
## tools/blender/build_memu.py) following a sim Train along the track.
## Car 0 is always the car at the train's head; both end cars are cab cars, so
## changing ends just re-assigns which physical end is "car 0".

const MODEL := "res://assets/models/memu.glb"
const CabView := preload("res://game/cab_view.gd")
const Profile := preload("res://sim/stock/memu_consist.gd")
const CAR_LENGTH := Profile.BODY_LENGTH
const CAR_GAP := Profile.INTER_CAR_GAP
const BOGIE_INSET := Profile.BOGIE_INSET
const AXLE_SPACING := Profile.AXLE_SPACING
const RAIL_TOP := 0.5
const EYE := Vector3(-0.75, 2.80, -9.05)   # seated eye, left-hand driving position

var train: Train
var motion
var graph: TrackGraph
var cars: Array = []            # Node3D per car (positioned on the track)
var _front_lamps: Array = []    # lamps at the head of the train
var _rear_lamps: Array = []     # lamps at the tail
var _cab_interior: Node3D       # shown only in cab view
var _destinations: Array = []
var _wv                         # world_view, for materials
var _bogie_views := []
var _wheel_views := []
var _last_odometer := 0.0
var _wheel_angle := 0.0
var _cab_exterior_occluders := []


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
		preload("res://game/fleet_surface.gd").apply(body)
		_add_identity(body, i, n)
		_register_running_gear(body, kind, i)
		if i==0:
			_cab_exterior_occluders = body.find_children("*ExteriorDetails_Frame","MeshInstance3D",true,false)
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


## Crisp destination boards and running numbers on the existing MEMU model.
func _register_running_gear(body: Node3D, kind: String, car_index: int) -> void:
	var facing := -1.0 if absf(body.rotation.y)>1 else 1.0
	for j in 2:
		var bogie: Node3D = body.find_child(kind+"_Bogie"+str(j),true,false)
		if bogie==null: continue
		var rest := body.transform*bogie.position
		_bogie_views.append({node=bogie,back=car_index*(CAR_LENGTH+CAR_GAP)+CAR_LENGTH*.5+rest.z,facing=facing})
		for k in 2:
			var axle: Node3D = body.find_child(kind+"_Axle"+str(j)+str(k),true,false)
			if axle!=null: _wheel_views.append({node=axle,facing=facing})

func _update_running_gear() -> void:
	var distance: float = motion.odometer() if motion != null else train.odometer
	_wheel_angle -= (distance - _last_odometer) / .46
	_last_odometer = distance
	for bogie in _bogie_views:
		var direction := _point(bogie.back-1)-_point(bogie.back+1)
		if direction.length_squared()<.00001: continue
		bogie.node.global_transform = Transform3D(Basis.looking_at(direction*bogie.facing,Vector3.UP),_point(bogie.back)+Vector3.UP*RAIL_TOP)
	for axle in _wheel_views: axle.node.rotation.x = _wheel_angle*axle.facing


func _add_identity(body: Node3D, index: int, count: int) -> void:
	for side in [-1, 1]:
		var number := Label3D.new()
		number.text = "SR  %s%02d   •   MEMU" % ["6600" if train.id == "T1" else "6601", index + 1]
		number.font_size = 64
		number.pixel_size = 0.0045
		number.modulate = Color("eddbb4")
		number.outline_size = 0
		number.position = Vector3(side * 1.845, 1.85, 0)
		number.rotation.y = side * PI / 2
		body.add_child(number)
	if index != 0 and index != count - 1:
		return
	var destination := Label3D.new()
	destination.text = train.destination.to_upper() if train.destination != "" else "MEMU LOCAL"
	destination.font_size = 64
	destination.pixel_size = 0.0028
	destination.modulate = Color("ffcf74")
	destination.outline_size = 0
	destination.position = Vector3(0, 3.50, -10.327)
	destination.rotation.y = PI
	body.add_child(destination)
	_destinations.append(destination)
	if index == 0:
		var headlight := SpotLight3D.new()
		headlight.position = Vector3(0, 1.8, -10.75)
		headlight.light_color = Color("fff1cd")
		headlight.light_energy = 2.5
		headlight.spot_range = 90
		headlight.spot_angle = 24
		headlight.shadow_enabled = true
		body.add_child(headlight)


## Original Blender-built cab; instruments are a rendering of the simulation state.
func _build_cab_interior(car: Node3D) -> void:
	_cab_interior = CabView.new()
	_cab_interior.name = "DrivingCab"
	car.add_child(_cab_interior)
	_cab_interior.position.y = RAIL_TOP
	_cab_interior.setup(train)
	_cab_interior.visible = false


## World position `back` metres behind the head.
func _point(back: float) -> Vector3:
	if motion != null: return motion.point(back)
	var loc: Dictionary = train.locate_behind(graph, back)
	return graph.position(loc.edge, loc.s)


func update() -> void:
	for label in _destinations:
		label.text = train.destination.to_upper() if train.destination != "" else "MEMU LOCAL"
	var step := CAR_LENGTH + CAR_GAP
	for i in cars.size():
		var front := _point(i * step + BOGIE_INSET)
		var rear := _point(i * step + CAR_LENGTH - BOGIE_INSET)
		var fwd := front - rear
		if fwd.length_squared() < 0.0001:
			continue
		cars[i].global_transform = Transform3D(Basis.looking_at(fwd, Vector3.UP), (front + rear) * 0.5)
	_update_running_gear()
	for l in _front_lamps:
		l.material_override = _wv.mat(Color(1.0, 0.97, 0.85), true)
	for l in _rear_lamps:
		l.material_override = _wv.mat(Color(0.9, 0.05, 0.05), true)
	_cab_interior.update_instruments()


## Driver's eye point in the leading cab and look direction.
func cab_transform() -> Transform3D:
	var car: Node3D = cars[0]
	var b := car.global_transform.basis
	var eye := car.global_transform * (EYE + Vector3(0, RAIL_TOP, 0))
	var ahead := eye - b.z * 40.0 - b.y * 6.0
	return Transform3D(Basis.looking_at(ahead - eye, Vector3.UP), eye)


func head_out_transform(side: int) -> Transform3D:
	var transform: Transform3D = cars[0].global_transform
	var eye := Vector3(side * 1.90, EYE.y + RAIL_TOP, EYE.z)
	return Transform3D(Basis.looking_at(-transform.basis.z, Vector3.UP), transform * eye)


func set_cab_view(on: bool) -> void:
	_cab_interior.visible = on
	# The dedicated cab supplies its own correctly seated wipers.
	for mesh in _cab_exterior_occluders: mesh.visible = not on


func head_position() -> Vector3:
	return _point(0.0)


func overview_position() -> Vector3:
	return _point(train.length * 0.45)
