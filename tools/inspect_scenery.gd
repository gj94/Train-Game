extends SceneTree
## Fixed scenery viewpoints for before/after visual and rendering checks.
func _initialize() -> void: call_deferred("capture")
func capture() -> void:
	set_meta("traffic_seed",0)
	change_scene_to_file("res://game/main.tscn")
	await process_frame
	await process_frame
	var game=current_scene
	game._set_paused(true)
	game.hud.hide()
	game.controller.set_process(false)
	game.cam.set_process(false)
	game._set_cab_visuals(false)
	var prefix:="res://.local/scenery-before"
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--output="): prefix=arg.trim_prefix("--output=")
	var village_x: float=game.world.scenery.villages[0]
	var village_z: float=game.wv.scenery_plan.track_at(village_x).z-66.0
	var shots:=[
		["station_street",Vector3(440,6,-165),Vector3(505,4,-100)],
		["market",Vector3(210,2.3,-81),Vector3(380,2.8,-84)],
		["village_lane",Vector3(village_x-170,2.3,village_z+1),Vector3(village_x+40,2.0,village_z)],
		["station_overview",Vector3(290,66,-245),Vector3(570,0,-10)],
		["station_opposite",Vector3(760,8,82),Vector3(475,4,68)],
		["village",Vector3(3180,7,-200),Vector3(3330,3,-170)],
		["rural",Vector3(6100,4,-195),Vector3(6250,2,-100)],
		["canal",Vector3(7830,8,-125),Vector3(7960,-1,-160)],
		["maruthur",Vector3(10870,25,-155),Vector3(11080,4,-80)],
		["kadalur",Vector3(21390,15,175),Vector3(21520,4,85)],
		["bus_bay",Vector3(619,2.5,-80),Vector3(650,1.5,-66)],
		["temple",Vector3(665,3,-211),Vector3(665,6,-239)]]
	for field in game.wv.scenery_plan.fields:
		if field.stage==2 and field.rect.position.x>5800:
			var p:=Vector3(field.rect.position.x-2,1.2,field.rect.get_center().y)
			shots.append(["rice_close",p,p+Vector3(38,-.2,4)])
			break
	for shot in shots:
		game.cam.position=shot[1]
		game.cam.look_at(shot[2])
		game.cam.fov=65
		for i in 30: await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(prefix+"-"+shot[0]+".png")
		print("Scenery captured: ",shot[0],"; draws ",Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),"; primitives ",Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME))
	quit()
