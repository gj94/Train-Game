extends RefCounted
const Camera := preload("res://game/camera_rig.gd")
func test_mouse_look_stays_on_release_and_recenters_explicitly():
	var camera := Camera.new()
	camera.mode = Camera.Mode.CAB
	var button := InputEventMouseButton.new()
	button.button_index = MOUSE_BUTTON_RIGHT
	button.pressed = true
	camera._unhandled_input(button)
	var move := InputEventMouseMotion.new()
	move.relative = Vector2(60,-30)
	camera._unhandled_input(move)
	var look: Vector2 = camera._look
	button.pressed = false
	camera._unhandled_input(button)
	var held: bool = camera._look==look and look.length()>.1
	button.button_index = MOUSE_BUTTON_MIDDLE
	button.pressed = true
	camera._unhandled_input(button)
	var centered: bool = camera._look==Vector2.ZERO
	camera.free()
	return true if held and centered else "Mouse look must stay on release and center only on deliberate middle-click"
