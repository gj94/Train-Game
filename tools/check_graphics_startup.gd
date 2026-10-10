extends SceneTree
## Catch startup ordering regressions without touching the user's preferences.
func _initialize() -> void:
	set_meta("imported_fleet","vb8");set_meta("traffic_drive",false)
	call_deferred("run")

func run() -> void:
	var scene: PackedScene=load("res://game/main.tscn")
	var game=scene.instantiate()
	game.graphics_options.preset("Performance")
	root.add_child(game);current_scene=game
	await process_frame
	var ok: bool=game.passenger_crowd.render_budget==.5 and game.cam.far==1800 and root.msaa_3d==1 and is_equal_approx(root.scaling_3d_scale,.85)
	print("PASS startup applies all preferences after crowd creation" if ok else "FAIL startup lost a graphics preference")
	game.graphics_options.preset("High");game.graphics_options.apply()
	quit(0 if ok else 1)
