extends RefCounted
const Surface:=preload("res://game/platform_navigation.gd")
const EngineSound:=preload("res://game/engine_audio.gd")

func test_only_passenger_platforms_provide_walking_surface():
	var w:=preload("res://sim/layouts/kerala_coast.gd").build_traffic()
	return Surface.new(w,"KUMM_P1").edge.is_empty() and Surface.new(w,"KUMM_P2").edge=="KUMM_P2"

func test_platform_sweeps_stop_at_edges_and_obstacles():
	var w:=preload("res://sim/layouts/kerala_coast.gd").build_traffic()
	var nav=Surface.new(w,"ERS_P1")
	var landing: Dictionary=nav.landing((nav.start+nav.end)*.5)
	if landing.is_empty():return "No accessible mid-platform landing"
	for delta in [Vector2(1000,0),Vector2(-1000,0),Vector2(0,100),Vector2(0,-100)]:
		if not nav.allowed(nav.move(landing.point,delta)):return "Movement left the platform"
	for obstacle in nav.obstacles:
		if nav.allowed(obstacle.get_center()):return "Platform furnishing is permeable"
	return true

func test_all_detailed_models_have_bilateral_source_doors():
	var doors: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/interiors/exterior_doors.json"))
	if doors.size()!=22:return "Expected all 22 detailed masters"
	for model in doors:
		var row: Dictionary=doors[model]
		if row.doors.size()<4 or row.source_sha256.length()!=64:return "Missing model door provenance: "+model
		if not row.doors.any(func(d):return d.point[0]<-1.5) or not row.doors.any(func(d):return d.point[0]>1.5):return "Missing one side: "+model
	return true

func test_tea_kiosk_collision_covers_its_full_authored_body():
	var w:=preload("res://sim/layouts/kerala_coast.gd").build_traffic()
	var nav=Surface.new(w,"ERS_P1")
	var centre:=Vector2((nav.start+nav.end)*.5-110,2.02+nav.width*.6)
	# The source body is 3.7 m wide and 2.4 m deep, not a small post.
	return not nav.allowed(centre+Vector2(1.1,1.6)) and not nav.allowed(centre+Vector2(-.9,-1.6))

func test_stationary_brake_does_not_make_traction_whine():
	var state:=EngineSound.parameters(0,-1,50)
	return state.level.x>0 and state.level.y==0 and state.level.z==0

func test_engine_pitch_follows_speed_and_level_follows_load():
	var slow:=EngineSound.parameters(5,1,50)
	var fast:=EngineSound.parameters(25,1,50)
	var coast:=EngineSound.parameters(25,0,50)
	return fast.pitch>slow.pitch and fast.level.y>coast.level.y*3 and slow.level.z>fast.level.z
