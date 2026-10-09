extends SceneTree
## Reproducible source-only visual audit on the actual streamed route.
var game
var codes:=["KUMM","ALLP","VAK","NCJ"]
var report:=[]
var views:=["homes","water","fields","landscape"]
var output:="res://.local/kerala-variety"
func _initialize() -> void:
	set_meta("route","kerala_coast");set_meta("traffic_seed",0)
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--codes="):codes=arg.trim_prefix("--codes=").split(",")
		if arg.begins_with("--output="):output=arg.trim_prefix("--output=")
		if arg.begins_with("--views="):views=arg.trim_prefix("--views=").split(",")
	call_deferred("run")
func settle() -> bool:
	var started:=Time.get_ticks_msec()
	for i in 8:await process_frame
	while game.wv.loading or game.wv.has_pending_work():
		if Time.get_ticks_msec()-started>180000:printerr("SCENERY_CAPTURE loading timeout");return false
		await process_frame
	for i in 35:await process_frame
	return true
func shot(label: String,target: Vector3,front: Vector3,distance: float,height: float) -> void:
	if not label.get_slice("-",1) in views:return
	var eye:=target+front*distance+Vector3.UP*height
	game.cam.enter_free(eye,(target+Vector3.UP*2-eye).normalized());game._set_cab_visuals(false);game.hud.hide()
	if not await settle():quit(1);return
	var frames:=[];var previous:=Time.get_ticks_usec()
	for i in 60:
		await process_frame
		var now:=Time.get_ticks_usec();frames.append((now-previous)*.001);previous=now
	frames.sort()
	if DisplayServer.get_name()!="headless":
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(output+"-"+label+".png")
	var kinds:={};var details:={}
	for node in game.wv.root.find_children("*","MultiMeshInstance3D",true,false):
		var kind: String=node.get_meta("scenery_kind","")
		if kind.is_empty():continue
		kinds[kind]=kinds.get(kind,0)+node.multimesh.instance_count
	for node in game.wv.root.find_children("Geography_*","Node3D",true,false):
		for key in node.get_meta("kerala_details",{}):details[key]=details.get(key,0)+node.get_meta("kerala_details")[key]
	var entry:={view=label,kinds=kinds,details=details,frame_ms_median=frames[30],frame_ms_p95=frames[57],fps_cap=Engine.max_fps,primitives=Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME),draw_calls=Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),pending=game.wv.queue.size()}
	report.append(entry);print("SCENERY_CAPTURE ",JSON.stringify(entry))
	FileAccess.open(output+".json",FileAccess.WRITE).store_string(JSON.stringify(report,"\t"))
func nearest_kind(kinds: Array,p: Vector3) -> Dictionary:
	var best:={};var distance:=INF
	for kind in kinds:
		for node in game.wv.root.find_children("*","MultiMeshInstance3D",true,false):
			if node.get_meta("scenery_kind","")!=kind:continue
			for i in node.multimesh.instance_count:
				var pose: Transform3D=node.global_transform*node.multimesh.get_instance_transform(i)
				var d:=pose.origin.distance_squared_to(p)
				if d<distance:distance=d;best={pose=pose,kind=kind}
	return best
func run() -> void:
	Engine.max_fps=30;root.size=Vector2i(1440,900)
	change_scene_to_file("res://game/main.tscn");await process_frame;await process_frame
	game=current_scene;game.set_physics_process(false);game._set_paused(true);game.hud.hide()
	if not await settle():quit(1);return
	for code: String in codes:
		var station: Dictionary=game.world.stations.filter(func(s):return s.code==code)[0]
		game._visit_station(game.world.stations.find(station))
		if not await settle():quit(1);return
		var road: String=station.platform_tracks[0]
		var p: Vector3=game.world.graph.position_relative(road,game.world.graph.edges[road].length*.5,game.wv.coordinate_origin)
		var target:=nearest_kind(["kerala_veranda","laterite_cottage","balcony_villa"],p)
		if not target.is_empty():
			var pose: Transform3D=target.pose
			await shot(code.to_lower()+"-homes",pose.origin,(-pose.basis.z.normalized()+pose.basis.x.normalized()*.3).normalized(),17,7)
		p=game.world.graph.position_relative(road,game.world.graph.edges[road].length*.5,game.wv.coordinate_origin)
		target=nearest_kind(["country_canoe","fishing_skiff"],p)
		if not target.is_empty():
			var pose: Transform3D=target.pose
			await shot(code.to_lower()+"-water",pose.origin,water_side(pose),19,16)
		p=game.world.graph.position_relative(road,game.world.graph.edges[road].length*.5,game.wv.coordinate_origin)
		target=nearest_kind(["rice_green","rice_ripe"],p)
		if not target.is_empty():await shot(code.to_lower()+"-fields",target.pose.origin,Vector3(.8,0,-.6),45,18)
		# Wider setting shows settlement/cultivation/terrain variety around the stop.
		p=game.world.graph.position_relative(road,game.world.graph.edges[road].length*.5,game.wv.coordinate_origin)
		var f: Vector3=game.world.graph.tangent(road,0,1)
		await shot(code.to_lower()+"-landscape",p,-f+f.cross(Vector3.UP)*.8,160,75)
	print("SCENERY_CAPTURE_COMPLETE");quit()

func water_side(pose: Transform3D) -> Vector3:
	var absolute: Vector3=pose.origin+game.wv.coordinate_origin
	var key:=Vector2i(floori(absolute.x/512),floori(absolute.z/512))
	var tile: Dictionary=game.wv.geo.tile(key)
	var local:=Vector2(absolute.x-key.x*512,absolute.z-key.y*512)
	var c:=preload("res://game/geographic_scenery_chunk.gd").new(null,{},null)
	for side in [pose.basis.x.normalized(),-pose.basis.x.normalized(),pose.basis.z.normalized(),-pose.basis.z.normalized()]:
		for feature in tile.get("features",[]):
			if feature.kind=="water" and c._inside(local+Vector2(side.x,side.z)*19,feature.geometry):return side
	return pose.basis.x.normalized()
