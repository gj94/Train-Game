extends SceneTree
## Geographic source-game visual check. Never launches an extracted distribution.
var failed:=false
func _initialize() -> void:
	set_meta("route","kerala_coast");set_meta("traffic_seed",0)
	call_deferred("run")
func run() -> void:
	Engine.max_fps=30
	root.size=Vector2i(1280,720)
	change_scene_to_file("res://game/main.tscn")
	await process_frame;await process_frame
	var game=current_scene
	game.set_physics_process(false)
	preload("res://game/controller_camera.gd").select(game,"free")
	var start:=Time.get_ticks_msec()
	for i in 4:await process_frame
	while game.wv.loading and Time.get_ticks_msec()-start<90000:await process_frame
	for i in 40:await process_frame
	failed=game.wv.loading or not game.cam.free_flight
	if DisplayServer.get_name()!="headless":
		game.hud.hide()
		await process_frame;await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://.local/r18-platform-camera.png")
		game.hud.show()
	print("GEOGRAPHIC_FREE_CAMERA eye=",game.cam.global_position+game.wv.coordinate_origin," zoom=",game.cam.fov," loaded=",not game.wv.loading)
	quit(1 if failed else 0)
