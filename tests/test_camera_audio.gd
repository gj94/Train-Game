extends RefCounted
const Sound:=preload("res://game/platform_audio.gd")
const Rig:=preload("res://game/camera_rig.gd")
const Proxy:=preload("res://game/geographic_audio_listener.gd")
# A private World3D is unnecessary: these tests inspect the receiver transform.
func fixture() -> Dictionary:
	var tree: SceneTree=Engine.get_main_loop()
	var camera:=Rig.new()
	tree.root.add_child(camera);camera.set_process(false)
	camera.mode=0;camera.follow=false
	camera.pivot=Vector3(900,0,700)
	camera.position=Vector3(20,3,5)
	var proxy:=Proxy.new()
	tree.root.add_child(proxy);proxy.set_process(false)
	proxy.sync(camera,Vector3(200000,0,300000))
	var sound:=Sound.new();sound.camera=proxy
	return {camera=camera,proxy=proxy,sound=sound}
func release(f: Dictionary) -> void:
	f.sound.free();f.proxy.free();f.camera.free()
func test_free_camera_receiver_uses_eye_instead_of_orbit_pivot():
	var f:=fixture()
	var expected: Vector3=f.camera.position+Vector3(200000,0,300000)
	var ok: bool=f.sound._listener().position.distance_to(expected)<.01
	release(f)
	return true if ok else "Free-camera track listener is detached from camera"
func test_receiver_orientation_follows_free_camera():
	var f:=fixture()
	f.camera.rotation=Vector3(.2,1.2,.15)
	f.proxy.sync(f.camera,Vector3(200000,0,300000))
	var actual: Dictionary=f.sound._listener()
	var ok: bool=actual.forward.is_equal_approx(-f.camera.global_basis.z) and actual.up.is_equal_approx(f.camera.global_basis.y)
	release(f)
	return ok
func test_free_camera_receiver_survives_origin_rebase():
	var f:=fixture();var origin:=Vector3(200000,0,300000)
	var before: Vector3=f.sound._listener().position
	var shift:=Vector3(1024,0,-2048)
	f.camera.shift_origin(shift);f.proxy.sync(f.camera,origin+shift)
	var after: Vector3=f.sound._listener().position
	var ok:=before.distance_to(after)<.01 and after.distance_to(Vector3(200020,3,300005))<.01
	release(f)
	return ok
func test_actual_listener_keeps_explicit_reference_override():
	var f:=fixture()
	f.sound.listener_override={position=Vector3(11,2,9),forward=Vector3.RIGHT,up=Vector3.UP}
	var ok: bool=f.sound._listener()==f.sound.listener_override
	release(f)
	return ok
func test_reference_mode_preserves_website_platform_receiver():
	var f:=fixture()
	f.sound.reference_mode=true
	f.sound._selection={tangent=Vector3.RIGHT,point=Vector3(0,0,0)}
	var expected: Vector3=f.proxy.pivot+Vector3(3.8,2.73,5.8)
	var ok: bool=f.sound._listener().position.distance_to(expected)<.02
	release(f)
	return ok
func test_platform_walk_is_exterior_even_with_walking_camera_mode():
	var f:=fixture()
	f.sound.camera=f.camera;f.camera.mode=4;f.camera.set_meta("on_platform",true)
	var ok: bool=not f.sound._onboard() and f.sound._listener().position==f.camera.global_position
	release(f)
	return ok
