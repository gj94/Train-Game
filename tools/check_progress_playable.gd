extends SceneTree
var game
func _init() -> void:call_deferred("run")
func run() -> void:
	game=load("res://game/main.tscn").instantiate();root.add_child(game);current_scene=game
	assert(game.geographic_drive and game.train.id=="K1","Default must be the slow Kerala passenger")
	var start:=Time.get_ticks_msec()
	while game.wv.loading and Time.get_ticks_msec()-start<90000:await process_frame
	game.hud.show_modal("");game._set_paused(false)
	var button: Button=game.hud._toolbar.get_children().filter(func(b):return b.text.begins_with("PROGRESS"))[0]
	button.pressed.emit()
	assert(game.paused and game.hud.modal=="progress")
	assert(game.hud._body.text.contains("1 / 56") and game.hud._body.text.contains("Stops left: 55"))
	assert(game.hud._body.text.contains("Next stop: Tripunithura") or game.hud._body.text.contains("Next stop: Tirunettur"))
	assert(game.hud._body.text.contains("in-game min") and game.hud._body.text.contains("Booked arrival"))
	for i in 3:await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://.local/journey-progress.png")
	game._close_progress();assert(not game.paused and game.hud.modal.is_empty())
	game._set_paused(true);game._toggle_progress();game._close_progress()
	assert(game.paused and game.hud.modal=="pause")
	print("DEFAULT_PASSENGER_PROGRESS_UI_PASS")
	quit()
