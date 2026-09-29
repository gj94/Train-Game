extends Node3D
## WAP-7 instruments render actual sim state. Auxiliary switches are decorative.
## Power and brake indications are demand percentages, not invented air/current physics.

const MODEL := preload("res://assets/models/wap7_cab.glb")
var train: Train
var cab_number := 1
var _speed: Node3D
var _power: Node3D
var _brake: Node3D
var _controller: Node3D
var _brake_handle: Node3D
var _lamps := {}
var _lit := {}
var _dark: StandardMaterial3D
var _display: Label3D
var _digital: Label3D
var _fill: OmniLight3D


func setup(t: Train, end_number: int = 1) -> void:
	train = t
	cab_number = end_number
	var model := MODEL.instantiate()
	add_child(model)
	_speed = model.find_child("NeedleSpeed", true, false)
	_power = model.find_child("NeedlePower", true, false)
	_brake = model.find_child("NeedleBrake", true, false)
	_controller = model.find_child("ControllerPivot", true, false)
	_brake_handle = model.find_child("BrakeHandle", true, false)
	_dark = StandardMaterial3D.new()
	_dark.albedo_color = Color("172321")
	var colors := {"PowerLamp": Color("50e185"), "CoastLamp": Color("ffc354"),
		"BrakeLamp": Color("ffc354"), "EmergencyLamp": Color("ff291d")}
	for lamp_name in colors:
		_lamps[lamp_name] = model.find_child(lamp_name, true, false)
		var m := StandardMaterial3D.new()
		m.albedo_color = colors[lamp_name]
		m.emission_enabled = true
		m.emission = colors[lamp_name]
		m.emission_energy_multiplier = .6
		_lit[lamp_name] = m
	_display = _screen(model.find_child("DDUScreen", true, false), 0.0011, 30)
	_digital = _screen(model.find_child("DigitalSpeed", true, false), 0.0010, 28)
	_fill = OmniLight3D.new()
	_fill.name = "CabCeilingLight"
	_fill.position = Vector3(0, 3.46, -7.70)
	_fill.light_color = Color("ffe6b8")
	_fill.light_energy = .60
	_fill.omni_range = 3.0
	add_child(_fill)
	update_instruments()


func _screen(anchor: Node3D, pixel: float, font: int) -> Label3D:
	var label := Label3D.new()
	label.font_size = font
	label.pixel_size = pixel
	label.outline_size = 0
	label.modulate = Color("a3ffca")
	label.no_depth_test = false
	# Blender local text plane XY becomes Godot XZ. Label3D faces local +Y.
	label.rotation.x = -PI / 2
	label.position.y = .002
	anchor.add_child(label)
	return label


func update_instruments() -> void:
	var power := maxf(train.controller, 0.0) if not train.emergency else 0.0
	var brake := 1.0 if train.emergency else maxf(-train.controller, 0.0)
	_speed.rotation.y = deg_to_rad(225.0 - clampf(train.speed * 3.6 / 160.0, 0, 1) * 270)
	_power.rotation.y = deg_to_rad(225.0 - power * 270)
	_brake.rotation.y = deg_to_rad(225.0 - brake * 270)
	_controller.rotation.y = -train.controller * .85
	_brake_handle.rotation.y = -brake * .9
	for pair in [["PowerLamp", power > .001], ["CoastLamp", absf(train.controller) <= .001 and not train.emergency],
		["BrakeLamp", brake > .001], ["EmergencyLamp", train.emergency]]:
		_lamps[pair[0]].material_override = _lit[pair[0]] if pair[1] else _dark
	_display.text = "WAP-7  30306   CAB %d\n%03d km/h\nPOWER %3d%%   BRAKE %3d%%\n%s" % [cab_number,
		roundi(train.speed * 3.6), roundi(power * 100), roundi(brake * 100),
		"EMERGENCY" if train.emergency else ("AUTO DRIVER" if train.automatic else "MANUAL CONTROL")]
	_digital.text = "%03d" % roundi(train.speed * 3.6)
	_fill.visible = visible
