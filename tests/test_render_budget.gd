extends RefCounted
const Budget:=preload("res://game/railway_render_budget.gd")
const Camera:=preload("res://game/camera_rig.gd")
const Pad:=preload("res://game/controller_camera.gd")

class Streaming extends "res://game/geographic_world.gd":
	func _refresh_loading() -> void:pass

func camera():
	var c:=Camera.new()
	c.ground_height=func(_x,_z):return 120.0
	Engine.get_main_loop().root.add_child(c);c.set_process(false)
	return c

func test_free_camera_clamps_input_and_saved_altitude_without_accumulating():
	var c=camera()
	c.enter_free(Vector3(10,1000,20),Vector3.FORWARD)
	var ok: bool=c.pivot.y==180 and c.global_position.y==180
	# A restored high position and an in-progress transition both obey the cap.
	c.pivot.y=500;c._from.origin.y=900;c._blend=0
	c._process(.016)
	ok=ok and c.global_position.y<=180 and c.pivot.y==180
	# Descending starts immediately; upward input has no hidden overshoot.
	c.pivot.y-=1;c._process(.016)
	ok=ok and c.pivot.y==179
	c._blend=1;c.pivot.y=-100;c._process(.016)
	ok=ok and is_equal_approx(c.global_position.y,120.35)
	c.free();return ok

func test_mouse_controller_and_old_orbit_distance_share_limits():
	var c=camera();c.pivot=Vector3(0,120,0);c.distance=3000;c.pitch=-1.4
	var pose: Transform3D=c._target()
	var ok: bool=c.distance==300 and pose.origin.y<=180
	var wheel:=InputEventMouseButton.new();wheel.button_index=MOUSE_BUTTON_WHEEL_DOWN;wheel.pressed=true
	c._unhandled_input(wheel)
	Pad.apply(c,Vector2.ZERO,Vector2.ZERO,-1,10)
	c._process(.016)
	ok=ok and c.distance==300 and c.global_position.y<=180 and c.far==2200
	c.free();return ok

func test_height_limit_uses_rebased_terrain_and_leaves_onboard_views_alone():
	var c=camera()
	var reference:={origin=Vector3(200000,0,300000)}
	c.ground_height=func(x,_z):return (x+reference.origin.x)*.001
	c.enter_free(Vector3(50,1000,20),Vector3.FORWARD)
	var before: Vector3=c.global_position+reference.origin
	var delta:=Vector3(1024,0,1024)
	reference.origin+=delta;c.shift_origin(delta);c._process(.016)
	var ok: bool=(c.global_position+reference.origin).distance_to(before)<.001
	var onboard:=Transform3D(Basis.IDENTITY,Vector3(10,700,20))
	c.cab_transform=func():return onboard
	c.passenger_transform=c.cab_transform;c.walking_transform=c.cab_transform
	for mode in [Camera.Mode.CAB,Camera.Mode.PASSENGER,Camera.Mode.WALKING]:
		c.set_mode(mode);c._blend=1;c._process(.016)
		ok=ok and c.global_position==onboard.origin
	c.free();return ok

func test_corridor_tiles_retain_bends_depots_and_negative_coordinates():
	var segments:=[{a=Vector3(-520,0,-20),b=Vector3(20,0,-20)},
		{a=Vector3(20,0,-20),b=Vector3(20,0,620)},
		{a=Vector3(20,0,620),b=Vector3(900,0,620),depot=true}]
	var tiles:=Budget.corridor_tiles(segments)
	for segment in segments:
		for step in 21:
			var p: Vector3=segment.a.lerp(segment.b,step/20.0)
			for shift in [Vector3(219,0,0),Vector3(-219,0,0),Vector3(0,0,219),Vector3(0,0,-219)]:
				var q: Vector3=p+shift
				if not tiles.has(Vector2i(floori(q.x/512),floori(q.z/512))):return "Corridor has an edge/bend hole"
	return not tiles.has(Vector2i(4,4)) and tiles.has(Vector2i(-2,-1))

func test_streaming_retains_rail_signals_outside_detailed_scenery_radius():
	var stream:=Streaming.new();stream.world=RailWorld.new()
	stream.speed_boards={jobs=[{id="board:1",kind="speed_board",point=Vector3(1550,0,0)}]}
	stream.corridor_tiles=Budget.corridor_tiles([{a=Vector3(-2000,0,0),b=Vector3(2000,0,0)}])
	var job:={id="track:test",kind="track",point=Vector3(1550,0,0)}
	stream.track_jobs=[job];stream.track_index[Vector2i(3,0)]=[0]
	stream.world.graph.add_node("a",Vector3.ZERO);stream.world.graph.add_node("b",Vector3(2000,0,0))
	stream.world.graph.add_edge("line","a","b")
	stream.world.signals.S={edge="line",s=1550.0}
	stream.world.stations=[{code="TEST",origin=Vector3(1500,0,0)}]
	stream._request(Vector3.ZERO)
	for id in ["track:test","ohe:track:test","signal:S","board:1","station:TEST"]:
		if not stream.wanted.has(id):return "Lost operational presentation: "+id
	var detail:=0;var landscape:=0;var backgrounds:=[]
	for wanted in stream.wanted.values():
		if wanted.kind=="tile":
			detail+=1
			if not stream.corridor_tiles.has(wanted.key):return "Detailed off-route tile"
		elif wanted.kind=="landscape":landscape+=1
		elif wanted.kind=="far":backgrounds.append(wanted)
	# Every view-frustum ground sample has background coverage, with holes only
	# where a requested detailed or landscape tile supplies the surface.
	for x in range(-2200,2201,200):
		for z in range(-2200,2201,200):
			if Vector2(x,z).length()>2200:continue
			var key:=Vector2i(floori(x/2048.0),floori(z/2048.0))
			if not backgrounds.any(func(b):return b.key==key):return "Background coverage hole"
	for bg in backgrounds:
		for tile in bg.holes:
			if not stream.wanted.has("tile:"+str(tile)) and not stream.wanted.has("landscape:"+str(tile)):return "Unfilled terrain hole"
	return detail>0 and landscape>0 and detail<detail+landscape and backgrounds.size()<20
