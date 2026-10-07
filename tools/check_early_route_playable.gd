extends "res://tools/check_kerala_geography.gd"
func _run() -> void:
	game=load("res://game/main.tscn").instantiate()
	root.add_child(game);current_scene=game
	await settle()
	game._set_paused(true);game.hud.show_modal("")
	for chain in [2950.0,4270.0,6600.0]:
		var road:=""
		var distance:=0.0
		for eid in game.world.graph.edges:
			var e: Dictionary=game.world.graph.edges[eid]
			if chain>=e.chainage_start and chain<e.chainage_end:
				road=eid;distance=(chain-e.chainage_start)/(e.chainage_end-e.chainage_start)*e.length;break
		var p: Vector3=game.world.graph.position(road,distance)
		var f: Vector3=game.world.graph.tangent(road,distance,1)
		game.cam.jump_to(p-game.wv.coordinate_origin)
		game.cam._blend=1;game.cam.yaw=atan2(f.x,f.z)+1.2
		game.cam.distance=65;game.cam.pitch=-.30
		await settle()
		await capture("supported-"+str(int(chain)))
	# Exercise the manual-stop recovery using the visible Progress button.
	var t: Train=game.train
	t.timetable.index=1;t.timetable.at_stop=false;t.timetable.missed_stop=true
	game._toggle_progress()
	assert(game.hud.can_skip_stop)
	assert(game.hud._buttons.get_children().any(func(b):return b.text.contains("Skip missed")))
	game._ui_action("skip_missed_stop")
	assert(t.timetable.index==2 and t.timetable.stops[1].skipped)
	assert(game.hud._body.text.contains("Skipped calls: 1"))
	assert(not game.hud.can_skip_stop)
	await capture("missed-call-recovered")
	print("EARLY_ROUTE_AND_RECOVERY_NATIVE_PASS")
	quit()
