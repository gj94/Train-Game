extends "res://game/wap7_train_view.gd"
## Rendering only. Train owns the whole rake's movement and track occupancy.

const Profile := preload("res://sim/stock/lhb_consist.gd")
const THREE_TIER := preload("res://assets/models/lhb_3a.glb")
const TWO_TIER := preload("res://assets/models/lhb_2a.glb")
const GENERATOR := preload("res://assets/models/lhb_eog.glb")

var coaches: Array[Node3D] = []
var coach_bogies: Array = []
var coach_axles: Array = []
var coach_glass: Array = []
var middle_berths: Array = []
var berth_folded_angles: Array = []
var passenger_coach := 1
var passenger_bay := 0
var passenger_seat := false
var passenger_on := false
var berths_deployed := false
var _passenger_lights: Array[OmniLight3D] = []


func build(t: Train, g: TrackGraph, parent: Node3D, world_view) -> void:
	super.build(t, g, parent, world_view)
	for i in Profile.FORMATION.size():
		var car := Node3D.new()
		car.name = t.id + "_LHB_" + Profile.FORMATION[i]
		parent.add_child(car)
		cars.append(car)
		var kind := Profile.coach_kind(i)
		var model: Node3D = (GENERATOR if kind == "eog" else (THREE_TIER if kind == "3a" else TWO_TIER)).instantiate()
		model.position.y = RAIL_TOP
		car.add_child(model)
		preload("res://game/fleet_surface.gd").apply(model)
		coaches.append(model)
		var bogies := []
		var axles := []
		for j in [1, 2]:
			bogies.append(model.find_child("Bogie_%d" % j, true, false))
			for k in [1, 2]:
				axles.append(model.find_child("Axle_%d_%d" % [j, k], true, false))
		coach_bogies.append(bogies)
		coach_axles.append(axles)
		var glass := []
		for mesh in model.find_children("*", "MeshInstance3D", true, false):
			for s in mesh.mesh.get_surface_count():
				var material: Material = mesh.get_active_material(s)
				if material != null and material.resource_name.begins_with("LHB_Glass"):
					var clear := material.duplicate() as StandardMaterial3D
					clear.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
					clear.albedo_color.a = 0
					glass.append({node = mesh, surface = s, clear = clear, exterior = material})
		coach_glass.append(glass)
		var middles := model.find_children("MiddleBerth_*", "Node3D", true, false)
		middle_berths.append(middles)
		var angles := []
		for berth in middles:
			angles.append(berth.rotation.x)
		berth_folded_angles.append(angles)
		for e in [-1, 1]:
			model.find_child("TailMarker_%s" % e, true, false).visible = i == Profile.FORMATION.size() - 1 and e == -1
		model.find_child("LastVehicleBoard", true, false).visible = i == Profile.FORMATION.size() - 1
		model.find_child("LastVehicleLetters", true, false).visible = i == Profile.FORMATION.size() - 1
		for side in [-1, 1]:
			var label := Label3D.new()
			label.text = Profile.FORMATION[i]
			label.position = Vector3(side * 1.66, 3.36, 3.5)
			label.rotation.y = side * PI / 2
			label.font_size = 72
			label.pixel_size = .0035
			label.modulate = Color("ffdc58")
			label.outline_size = 6
			model.add_child(label)
		# Warm coach lights, separate from world graphics settings.
		for bay in range(0, 9, 2):
			var light := OmniLight3D.new()
			light.position = Vector3(.25, 3.65, 7.92 - bay * 1.98)
			light.light_color = Color("e7f5ee")
			light.light_energy = .65
			light.omni_range = 3.6
			light.omni_attenuation = 1.2
			light.visible = false
			model.add_child(light)
			_passenger_lights.append(light)
	update()


func update() -> void:
	super.update()
	for i in coaches.size():
		var back := Profile.coach_center(i)
		var front := _point(back - Profile.BOGIE_HALF_SPACING)
		var rear := _point(back + Profile.BOGIE_HALF_SPACING)
		var fwd := front - rear
		if fwd.length_squared() < .0001:
			continue
		cars[i + 1].global_transform = Transform3D(Basis.looking_at(fwd, Vector3.UP), (front + rear) * .5)
		for j in 2:
			var bogie_back := back + (j * 2 - 1) * Profile.BOGIE_HALF_SPACING
			var a := _point(bogie_back - Profile.AXLE_HALF_SPACING)
			var b := _point(bogie_back + Profile.AXLE_HALF_SPACING)
			coach_bogies[i][j].global_transform = Transform3D(Basis.looking_at(a - b, Vector3.UP), (a + b) * .5 + Vector3.UP * RAIL_TOP)
		var distance: float = motion.odometer() if motion != null else train.odometer
		for axle in coach_axles[i]:
			axle.rotation.x = -distance / Profile.WHEEL_RADIUS


func overview_position() -> Vector3:
	return _point(train.length * .5)


func set_passenger_view(on: bool) -> void:
	passenger_on = on
	for i in coaches.size():
		for glass in coach_glass[i]:
			glass.node.set_surface_override_material(glass.surface, glass.clear if on and i == passenger_coach else glass.exterior)
		for j in 5:
			_passenger_lights[i * 5 + j].visible = on and i == passenger_coach


func passenger_coaches() -> Array:
	var result := []
	for i in coaches.size():
		if Profile.coach_kind(i) != "eog": result.append(i)
	if train.cab_end == 2: result.reverse()
	return result


func change_passenger_coach(delta: int) -> void:
	passenger_coach = posmod(passenger_coach + delta, coaches.size())
	while Profile.coach_kind(passenger_coach) == "eog":
		passenger_coach = posmod(passenger_coach + (1 if delta >= 0 else -1), coaches.size())
	set_passenger_view(passenger_on)


func change_passenger_bay(delta: int) -> void:
	# Include both vestibules in the inspection path, outside the nine bays.
	passenger_bay = posmod(passenger_bay + delta + 1, 11) - 1


func passenger_transform() -> Transform3D:
	var y := -7.92 + passenger_bay * 1.98
	var eye := Vector3(.60, 2.92, -y + .70)
	var look := Vector3(0, -.025, -1)
	if passenger_seat:
		eye = Vector3(.67, 2.73, -y)
		look = Vector3(-1, -.14, 0)
	if passenger_bay < 0 or passenger_bay > 8:
		var end := -1.0 if passenger_bay < 0 else 1.0
		eye = Vector3(.10, 2.92, -end * 9.48)
		look = Vector3(-.23, -.12, -end)
	var coach: Transform3D = coaches[passenger_coach].global_transform
	return Transform3D(Basis.looking_at(coach.basis * look, Vector3.UP), coach * eye)


func passenger_name() -> String:
	var location := "BAY %d" % (passenger_bay + 1)
	if passenger_bay < 0 or passenger_bay > 8:
		location = "REAR VESTIBULE" if passenger_bay < 0 else "FRONT VESTIBULE"
	return "%s · AC %s TIER · %s" % [Profile.FORMATION[passenger_coach], "3" if Profile.coach_kind(passenger_coach) == "3a" else "2", location]


func passenger_audio_position() -> Vector2:
	var local_eye: Vector3 = coaches[passenger_coach].to_local(passenger_transform().origin)
	return Vector2(Profile.coach_center(passenger_coach) + local_eye.z, 1.5)


func toggle_berths() -> void:
	berths_deployed = not berths_deployed
	for i in middle_berths.size():
		for j in middle_berths[i].size():
			middle_berths[i][j].rotation.x = 0.0 if berths_deployed else berth_folded_angles[i][j]


static func sound_axles() -> Array:
	return Profile.sound_axles()
