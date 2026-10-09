extends SceneTree
## Source-rendered station comparison; no packaged distribution.
var game
var tag:="before"
var codes:=["KUMM","TUVR","ERS","TVC"]
var views:=["forecourt","ground","platform"]
func _initialize() -> void:
	set_meta("route","kerala_coast");set_meta("traffic_seed",0)
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--tag="):tag=arg.trim_prefix("--tag=")
		if arg.begins_with("--codes="):codes=arg.trim_prefix("--codes=").split(",")
		if arg.begins_with("--views="):views=arg.trim_prefix("--views=").split(",")
	call_deferred("run")
func settle(code: String) -> void:
	var started:=Time.get_ticks_msec()
	for i in 8:await process_frame
	while (game.wv.loading or not game.wv.loaded.has("station:"+code)) and Time.get_ticks_msec()-started<120000:await process_frame
	if not game.wv.loaded.has("station:"+code):
		printerr("STATION_CAPTURE missing loaded station ",code);quit(1);return
	for i in 30:await process_frame
func run() -> void:
	Engine.max_fps=30;root.size=Vector2i(1440,900)
	change_scene_to_file("res://game/main.tscn")
	await process_frame;await process_frame
	game=current_scene;game.set_physics_process(false)
	await settle("ERS")
	game._set_paused(true);game.hud.show_modal("");game.hud.hide()
	for code: String in codes:
		var station: Dictionary=game.world.stations.filter(func(s):return s.code==code)[0]
		game._visit_station(game.world.stations.find(station));await settle(code)
		var road: String=station.platform_tracks[0]
		var s: float=game.world.graph.edges[road].length*.5
		var p: Vector3=game.world.graph.position_relative(road,s,game.wv.coordinate_origin)
		var f: Vector3=game.world.graph.tangent(road,s,1);var r: Vector3=f.cross(Vector3.UP)
		if preload("res://game/coastal_station_placement.gd").available(code):
			var site:=preload("res://game/coastal_station_placement.gd").site(game.world,station,game.wv.coordinate_origin)
			p=site.position;f=site.forward;r=site.right
		else:
			var extent:=0.0
			for detail in station.operating_roads:extent=minf(extent,detail.offset)
			p+=r*(extent-26)
		for view in views:
			var eye: Vector3=p-r*(125 if station.major else 85)+f*28+Vector3.UP*(45 if station.major else 28)
			var target: Vector3=p-r*20+Vector3.UP*3
			if view=="entrance":
				eye=p-r*34+f*20+Vector3.UP*1.7
				target=p-r*12+Vector3.UP*2.8
			elif view=="ground":
				eye=p-r*(85 if station.major else 65)+f*16+Vector3.UP*1.7
				target=p-r*9+Vector3.UP*2.6
			elif view=="platform":
				eye=game.world.graph.position_relative(road,s-65,game.wv.coordinate_origin)+r*(-4.0)+Vector3.UP*2.9
				target=p+Vector3.UP*2.2
			game.cam.enter_free(eye,(target-eye).normalized());game._set_cab_visuals(false);game.hud.hide()
			await settle(code)
			if DisplayServer.get_name()!="headless":
				await RenderingServer.frame_post_draw
				root.get_texture().get_image().save_png("res://.local/station-"+tag+"-"+code.to_lower()+"-"+view+".png")
			print("STATION_CAPTURE ",tag," ",code," ",view," draw_calls=",Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)," triangles=",Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME))
	quit()
