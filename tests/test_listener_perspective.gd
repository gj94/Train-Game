extends RefCounted
const Sound := preload("res://game/platform_audio.gd")
class Listener extends Node3D:
	var mode:=1
	var pivot:=Vector3.ZERO

func test_head_out_does_not_use_enclosed_cab_filter():
	var camera:=Listener.new(); var sound:=Sound.new(); sound.camera=camera
	camera.mode=3; sound._cab=true
	var ok:=sound._onboard() and not sound._enclosed_cab() and not sound._passenger()
	sound.free();camera.free()
	return true if ok else "head out still muffled as enclosed cab"

func test_walking_uses_the_actual_carriage_acoustic_profile():
	var camera:=Listener.new(); var sound:=Sound.new(); sound.camera=camera
	camera.mode=4; camera.set_meta("passenger_interior",true)
	var ok:=sound._passenger() and not sound._enclosed_cab()
	camera.set_meta("passenger_interior",false)
	ok=ok and sound._enclosed_cab() and not sound._passenger()
	camera.mode=0;sound._cab=false
	ok=ok and not sound._onboard()
	sound.free();camera.free()
	return true if ok else "walking/boarding profile is incorrect"

func test_seated_reference_profiles_remain_unchanged():
	var camera:=Listener.new(); var sound:=Sound.new(); sound.camera=camera
	var ok:=sound._enclosed_cab() and not sound._passenger()
	camera.mode=2
	ok=ok and not sound._enclosed_cab() and sound._passenger()
	sound.free();camera.free()
	return ok
