extends SceneTree
var game
func _init() -> void:
	set_meta("route","kerala_coast")
	set_meta("traffic_seed",0)
	call_deferred("_run")
func _run() -> void:
	game=load("res://game/main.tscn").instantiate()
	root.add_child(game)
	current_scene=game
	var started:=Time.get_ticks_msec()
	while game.wv.loading and Time.get_ticks_msec()-started<120000:
		await process_frame
	game.paused=true
	print("KERALA_INITIAL loaded=",game.wv.loaded.size()," pending=",game.wv.queue.size()," loading=",game.wv.loading," seconds=",(Time.get_ticks_msec()-started)*.001)
	while not game.wv.queue.is_empty() and Time.get_ticks_msec()-started<150000:
		await process_frame
	for i in 90: await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://.local/kerala-cab.png")
	game.cam.set_head_out(-1)
	for i in 45: await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://.local/kerala-headout.png")
	game.cam.set_mode(0)
	game.cam.distance=160
	game.cam.pitch=-.65
	for i in 75: await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://.local/kerala-station.png")
	print("KERALA_SCREENSHOTS_DONE")
	quit()
