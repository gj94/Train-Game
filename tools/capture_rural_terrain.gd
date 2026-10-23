extends SceneTree
## Native, frozen-railway audit of rural banks/cuttings at train and ground height.
var game
var output:="res://.local/map-2026-10-24/rural"
var chainages:=[11498.0,78743.0,135489.0,169733.0,217727.0,253472.0]
var report:=[]
var frozen:=0.0

func _initialize() -> void:
	set_meta("route","kerala_coast");set_meta("traffic_seed",0)
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--output="):output=arg.trim_prefix("--output=")
		if arg.begins_with("--km="):
			chainages=[]
			for value in arg.trim_prefix("--km=").split(","):chainages.append(float(value)*1000)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output))
	call_deferred("run")

func settle() -> bool:
	var began:=Time.get_ticks_msec()
	for i in 12:await process_frame
	while game.wv.loading or game.wv.has_pending_work():
		if Time.get_ticks_msec()-began>180000:return false
		await process_frame
	for i in 35:await process_frame
	return true

func run() -> void:
	root.size=Vector2i(1440,900)
	game=load("res://game/main.tscn").instantiate()
	game.set_physics_process(false);root.add_child(game);current_scene=game
	game._set_paused(true);game.set_physics_process(false);game.hud.hide()
	frozen=game.world.time;game.world.clock_start=15*3600-frozen
	game.journey_tools.save_directory=output+"/fixture-saves"
	if not await settle():printerr("RURAL_CAPTURE initial timeout");quit(2);return
	game._set_cab_visuals(false);game.dispatcher.set_open(false)
	for chain: float in chainages:
		var route: Dictionary=game.world.scenery.route
		var index:=PackedFloat64Array(route.chainage).bsearch(chain)
		index=clampi(index,0,route.alignment.size()-2)
		var a: Array=route.alignment[index];var b: Array=route.alignment[index+1]
		var p:=Vector3(a[0],a[1],a[2]);var forward:=Vector3(b[0]-a[0],0,b[2]-a[2]).normalized()
		var right:=forward.cross(Vector3.UP)
		for view in ["bank","train"]:
			var eye:=p+right*42-forward*24
			eye.y=game.wv.geo.ground_at(eye.x,eye.z)+3.5
			var target:=p+forward*12+Vector3.UP*.6
			if view=="train":
				eye=p+Vector3.UP*3.1;target=p+forward*90+right*25+Vector3.UP*1.4
			game.cam.enter_free(eye-game.wv.coordinate_origin,(target-eye).normalized());game.hud.hide()
			if not await settle():printerr("RURAL_CAPTURE streaming timeout ",chain);quit(2);return
			if game.world.time!=frozen:printerr("RURAL_CAPTURE railway advanced");quit(2);return
			await RenderingServer.frame_post_draw
			var label:="km-%06.1f-%s" % [chain*.001,view]
			root.get_texture().get_image().save_png(output+"/"+label+".png")
			var row:={view=label,eye=[eye.x,eye.y,eye.z],target=[target.x,target.y,target.z],draw_calls=Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),triangles=Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME),railway_time=game.world.time,loaded=game.wv.loaded.size()}
			report.append(row);print("RURAL_CAPTURE ",JSON.stringify(row))
			FileAccess.open(output+"/report.json",FileAccess.WRITE).store_string(JSON.stringify(report,"\t"))
	game._return_to_landing()
	for i in 10:await process_frame
	print("RURAL_CAPTURE_COMPLETE");quit()
