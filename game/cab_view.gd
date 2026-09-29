extends Node3D
## Rendering only: mechanical instruments read the existing train state.
## Power/brake dials show handle demand, not simulated current or air pressure.

const MODEL := preload("res://assets/models/memu_cab.glb")

var train: Train
var _speed: Node3D
var _power: Node3D
var _brake: Node3D
var _controller: Node3D
var _lamps: Dictionary = {}
var _lit: Dictionary = {}
var _dark: StandardMaterial3D


func setup(t: Train) -> void:
	train = t
	var model := MODEL.instantiate()
	add_child(model)
	_speed = model.find_child("NeedleSpeed", true, false)
	_power = model.find_child("NeedlePower", true, false)
	_brake = model.find_child("NeedleBrake", true, false)
	_controller = model.find_child("ControllerPivot", true, false)
	_dark = StandardMaterial3D.new()
	_dark.albedo_color = Color(0.035, 0.045, 0.04)
	_dark.roughness = 0.35
	var colors := {"PowerLamp": Color(0.12, 0.8, 0.28), "CoastLamp": Color(1.0, 0.6, 0.12),
		"BrakeLamp": Color(1.0, 0.6, 0.12), "EmergencyLamp": Color(1.0, 0.08, 0.03)}
	for lamp_name in colors:
		_lamps[lamp_name] = model.find_child(lamp_name, true, false)
		var m := StandardMaterial3D.new()
		m.albedo_color = colors[lamp_name]
		m.emission_enabled = true
		m.emission = colors[lamp_name]
		m.emission_energy_multiplier = 0.75
		m.roughness = 0.3
		_lit[lamp_name] = m
	# Soft cabin bounce makes the enclosed panels readable in the existing daylight.
	var fill := OmniLight3D.new()
	fill.name = "CabLight"
	fill.position = Vector3(0, 3.35, -8.8)
	fill.light_color = Color(1.0, 0.90, 0.73)
	fill.light_energy = 0.45
	fill.omni_range = 3.1
	fill.shadow_enabled = false
	add_child(fill)
	update_instruments()


func update_instruments() -> void:
	if not is_instance_valid(_speed):
		return
	var power := maxf(train.controller, 0.0) if not train.emergency else 0.0
	var brake := 1.0 if train.emergency else maxf(-train.controller, 0.0)
	# Blender Z axes become Godot Y axes in the exported local pivot transforms.
	_speed.rotation.y = deg_to_rad(225.0 - clampf(train.speed * 3.6 / 120.0, 0.0, 1.0) * 270.0)
	_power.rotation.y = deg_to_rad(225.0 - power * 270.0)
	_brake.rotation.y = deg_to_rad(225.0 - brake * 270.0)
	_controller.rotation.y = deg_to_rad(90.0 - train.controller * 70.0)
	_set_lamp("PowerLamp", power > 0.001)
	_set_lamp("CoastLamp", absf(train.controller) <= 0.001 and not train.emergency)
	_set_lamp("BrakeLamp", brake > 0.001)
	_set_lamp("EmergencyLamp", train.emergency)


func _set_lamp(lamp_name: String, on: bool) -> void:
	var lamp: MeshInstance3D = _lamps[lamp_name]
	lamp.material_override = _lit[lamp_name] if on else _dark
