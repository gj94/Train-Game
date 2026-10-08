extends Node3D
## Audio retains stable route coordinates while graphics use a floating origin.
## This avoids discontinuities in propagation histories and ongoing impact tails.
var mode := 0
var source_camera: Camera3D
var coordinate_origin := Vector3.ZERO
func _process(_delta: float) -> void:
	if is_instance_valid(source_camera): sync(source_camera,coordinate_origin)
var pivot := Vector3.ZERO
func sync(camera: Camera3D, origin: Vector3) -> void:
	set_meta("on_platform",camera.get_meta("on_platform",false))
	set_meta("passenger_interior",camera.get_meta("passenger_interior",false))
	mode = 0 if camera.get_meta("on_platform",false) else camera.mode
	pivot = camera.pivot+origin
	global_transform = camera.global_transform
	global_position += origin
