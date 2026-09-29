extends RefCounted
## Verify exported Blender pivots and in-cab state, including emergency override.

const Cab := preload("res://game/cab_view.gd")


func test_exported_speedometer_points_at_marked_values():
	var train := Train.new("cab_test", 175.0)
	var cab := Cab.new()
	cab.setup(train)
	# Dial layout: zero at bottom-left, 60 at twelve o'clock, 120 at bottom-right.
	var samples := [[0.0, Vector3(-0.707107, 0, 0.707107)],
		[60.0, Vector3(0, 0, -1)], [120.0, Vector3(0.707107, 0, 0.707107)]]
	for sample in samples:
		train.speed = sample[0] / 3.6
		cab.update_instruments()
		var tip: Vector3 = cab._speed.basis * Vector3.RIGHT
		if tip.distance_to(sample[1]) > 0.001:
			cab.free()
			return "Exported speedometer does not point to the %s km/h mark" % sample[0]
	cab.free()
	return true


func test_cab_emergency_overrides_traction_indication():
	var train := Train.new("cab_test", 175.0)
	var cab := Cab.new()
	cab.setup(train)
	train.controller = 0.8
	cab.update_instruments()
	if cab._lamps.PowerLamp.material_override != cab._lit.PowerLamp:
		cab.free()
		return "Positive controller must illuminate POWER"
	var powered_angle: float = cab._controller.rotation.y
	train.emergency = true
	cab.update_instruments()
	if cab._lamps.PowerLamp.material_override != cab._dark or cab._lamps.EmergencyLamp.material_override != cab._lit.EmergencyLamp:
		cab.free()
		return "Emergency must extinguish POWER and illuminate EMERGENCY"
	if (cab._brake.basis * Vector3.RIGHT).distance_to(Vector3(0.707107, 0, 0.707107)) > .001:
		cab.free()
		return "Emergency must indicate full brake demand"
	if not is_equal_approx(cab._controller.rotation.y, powered_angle):
		cab.free()
		return "Emergency indication must not move the physical power handle"
	train.emergency = false
	train.controller = -0.5
	cab.update_instruments()
	if cab._lamps.BrakeLamp.material_override != cab._lit.BrakeLamp or cab._lamps.EmergencyLamp.material_override != cab._dark:
		cab.free()
		return "Service braking must light BRAKE without EMERGENCY"
	train.controller = 0.0
	cab.update_instruments()
	if cab._lamps.CoastLamp.material_override != cab._lit.CoastLamp:
		cab.free()
		return "Returning to neutral must illuminate COAST"
	cab.free()
	return true
