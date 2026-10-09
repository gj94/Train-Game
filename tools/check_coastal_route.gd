extends SceneTree
var game
var failures:=0
func _initialize() -> void:
	set_meta("route","kerala_coast")
	set_meta("traffic_seed",0)
	call_deferred("_run")
func settle() -> void:
	var started:=Time.get_ticks_msec()
	for i in 10:await process_frame
	while (game.wv.loading or not game.wv.loaded.has("station:"+str(game.world.stations[_index].code))) and Time.get_ticks_msec()-started<90000:
		await process_frame
	for i in 60:await process_frame
var _index:=0
func _run() -> void:
	game=load("res://game/main.tscn").instantiate()
	root.add_child(game);current_scene=game
	await settle()
	game._set_paused(true);game.hud.show_modal("")
	for code in ["KUMM","TUVR","QLN","NYY","VRLR"]:
		var station: Dictionary=game.world.stations.filter(func(s):return s.code==code)[0]
		_index=game.world.stations.find(station)
		game._visit_station(_index)
		var site:=preload("res://game/coastal_station_placement.gd").site(game.world,station,game.wv.coordinate_origin)
		game.cam.pivot=site.position-site.right*18
		game.cam.yaw=atan2(-site.right.x,-site.right.z)
		game.cam.distance=120 if code=="QLN" else 75
		game.cam.pitch=-.36;game.cam._blend=1
		await settle()
		var found: Array=game.wv.root.find_children(code+"_AuthoredStation","Node3D",true,false)
		if found.size()!=1:
			failures+=1;printerr("COASTAL_ROUTE missing/duplicate ",code," count=",found.size())
		if DisplayServer.get_name()!="headless":
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("res://.local/coastal-route-"+code.to_lower()+".png")
		print("COASTAL_ROUTE ",code," assets=",found.size()," loaded=",game.wv.loaded.size()," primitives=",Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME))
	print("COASTAL_ROUTE failures=",failures)
	quit(failures)
