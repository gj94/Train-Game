extends RefCounted
const Platform:=preload("res://game/platform_camera.gd")
const Rig:=preload("res://game/camera_rig.gd")
const PadCamera:=preload("res://game/controller_camera.gd")
func world() -> RailWorld:
	var w:=RailWorld.new()
	var origin:=Vector3(200000,7,300000)
	w.graph.add_node("a",origin);w.graph.add_node("b",origin+Vector3(1000,0,0))
	w.graph.add_edge("TEST_P1","a","b")
	w.stations.append({name="Test",code="TEST",origin=origin+Vector3(500,0,0),passenger_open=true,through_halt=true,major=false,
		platform_tracks=["TEST_P1"],platform_details={TEST_P1={platform_side=1,platform_sides=[1],platform_width=4.0}}})
	return w
func test_spectator_uses_real_platform_height_and_clearance():
	var w:=world()
	var spot:=Platform.nearest(w,Vector3(200480,10,300000))
	if spot.is_empty():return "No platform found"
	var surface:=preload("res://game/platform_navigation.gd").new(w,"TEST_P1")
	return surface.allowed(spot.point) and absf(spot.eye.y-(7+1.26+1.65))<.01 and spot.forward.dot(Vector3.FORWARD)>.2 and is_equal_approx(spot.forward.length(),1.0)
func test_closed_station_is_skipped_and_no_station_is_safe():
	var w:=world();w.stations[0].passenger_open=false
	if not Platform.nearest(w,Vector3.ZERO).is_empty():return "Closed station selected"
	w.stations.clear()
	return Platform.nearest(w,Vector3.ZERO).is_empty()
func test_flat_platform_fallback_stays_within_rectangle():
	var w:=RailWorld.new()
	var rect:=Rect2(0,10,100,6)
	w.stations.append({name="Flat",origin=Vector3(50,0,0),platforms=[rect]})
	var spot:=Platform.nearest(w,Vector3(8,2,0))
	return rect.has_point(Vector2(spot.eye.x,spot.eye.z)) and is_equal_approx(spot.eye.y,2.85)
func test_free_optical_zoom_preserves_eye_and_origin_rebase():
	var camera:=Rig.new();Engine.get_main_loop().root.add_child(camera);camera.set_process(false)
	camera.enter_free(Vector3(50,2.85,12),Vector3.FORWARD)
	var before: Vector3=camera._target().origin
	PadCamera.apply(camera,Vector2.ZERO,Vector2.ZERO,1,.25)
	var ok: bool=camera.free_fov<65 and camera._target().origin==before
	camera.shift_origin(Vector3(1024,0,0))
	ok=ok and camera._target().origin+Vector3(1024,0,0)==before
	camera.free();return ok
func test_free_look_rotates_without_orbiting_and_follow_resets_it():
	var camera:=Rig.new();Engine.get_main_loop().root.add_child(camera);camera.set_process(false)
	camera.enter_free(Vector3(50,2.85,12),Vector3.FORWARD)
	var before: Vector3=camera._target().origin
	PadCamera.apply(camera,Vector2(1,.2),Vector2.ZERO,0,.5)
	var ok: bool=camera._target().origin==before and absf(camera.yaw)>.5
	camera.set_mode(0)
	ok=ok and not camera.free_flight
	camera.free();return ok
