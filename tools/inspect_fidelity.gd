extends SceneTree
## Close native inspection of platform materials, permanent way and verge cover.
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
	var prefix:="res://.local/fidelity-close"
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--output="): prefix=arg.trim_prefix("--output=")
	var platform: Rect2=game.world.stations[0].platforms[0]
	var middle:=Vector3(platform.position.x+85,2.95,platform.get_center().y)
	var track: Vector3=game.wv.scenery_plan.track_at(6200)
	var shots:=[
		["platform",middle,middle+Vector3(55,-.5,1.0)],
		["roof",middle+Vector3(20,5,17),middle+Vector3(80,3,0)],
		["verge",track+Vector3(-12,1.8,10),track+Vector3(40,1,3)],
		["trackside",track+Vector3(-8,1.0,3.5),track+Vector3(30,.6,0)]]
	for shot in shots:
		game.cam.position=shot[1]
		game.cam.look_at(shot[2])
		game.cam.fov=62
		for i in 35: await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(prefix+"-"+shot[0]+".png")
		print("Fidelity inspected: ",shot[0])
	quit()
