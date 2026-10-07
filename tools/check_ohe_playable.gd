extends "res://tools/check_kerala_geography.gd"
func _run() -> void:
	game=load("res://game/main.tscn").instantiate()
	root.add_child(game);current_scene=game
	await settle()
	game._set_paused(true)
	game.hud.show_modal("")
	for code in ["ERS","QLN"]:
		var st: Dictionary=game.world.stations.filter(func(s):return s.code==code)[0]
		game._visit_station(game.world.stations.find(st))
		var road: String=st.platform_tracks[0]
		var f: Vector3=game.world.graph.tangent(road,500,1)
		var side:=f.cross(Vector3.UP)
		game.cam.pivot-=side*20
		game.cam.yaw=atan2(-side.x,-side.z)+.45
		game.cam.distance=100;game.cam.pitch=-.28
		await settle()
		await capture("ohe-"+code.to_lower())
	var edge: String="AMPA_TZH_D1"
	var p: Vector3=game.world.graph.position(edge,300)
	var f: Vector3=game.world.graph.tangent(edge,300,1)
	game.cam.jump_to(p-game.wv.coordinate_origin)
	game.cam._blend=1;game.cam.yaw=atan2(f.x,f.z)+.3
	game.cam.distance=40;game.cam.pitch=-.12
	await settle()
	await capture("ohe-double")
	print("OHE_NATIVE_PASS")
	quit()
