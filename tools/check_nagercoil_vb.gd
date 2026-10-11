extends SceneTree
## B012 crash investigation: native rendering/audio, exact prepared departure.
## AI drives the observed service to make the route repeatable; not a manual-input replay.
var folder := "res://.local/nagercoil-vb-crash"
var report: FileAccess

func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(folder))
	report=FileAccess.open(folder+"/route.jsonl",FileAccess.WRITE)
	call_deferred("run")

func record(g, phase: String) -> void:
	var row:={phase=phase,wall_ms=Time.get_ticks_msec()}
	if g!=null:
		row.merge({clock=g.world.clock_seconds(),edge=g.train.path[0].edge,s=g.train.head_s,
			odometer=g.train.odometer,speed_kmh=g.train.speed*3.6,
			loading=g.wv.loading,heap_bytes=OS.get_static_memory_usage(),
			origin=str(g.wv.coordinate_origin),camera=str(g.cam.global_position),
			jobs=g.wv.completed_jobs})
	report.store_line(JSON.stringify(row));report.flush();print(JSON.stringify(row))

func run() -> void:
	root.size=Vector2i(1280,720)
	var page:=preload("res://game/launch.gd").new()
	root.add_child(page);current_scene=page
	await process_frame;await process_frame
	var row: Dictionary=page.services.filter(func(r):return r.id=="B012")[0]
	page._begin("service",row)
	while current_scene==page or current_scene==null:await process_frame
	var g=current_scene
	var began:=Time.get_ticks_msec()
	while g.wv.loading:
		await process_frame
		if Time.get_ticks_msec()-began>180000:record(g,"loading_timeout");quit(2);return
	record(g,"ready")
	var start: float=g.train.odometer
	g.train.automatic=true;g.world.dispatcher().manual_service=""
	g._set_time_scale(8);g._set_paused(false);g.hud.show_modal("")
	var next:=0
	while g.train.odometer-start<12000:
		await process_frame
		if Time.get_ticks_msec()>next:
			record(g,"driving");next=Time.get_ticks_msec()+10000
		if Time.get_ticks_msec()-began>900000:record(g,"driving_timeout");quit(2);return
	record(g,"passed_12km")
	g._set_paused(true)
	if DisplayServer.get_name()!="headless":
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(folder+"/passed.png")
	g._ui_action("landing");g._confirm_action()
	while current_scene==g or current_scene==null:await process_frame
	record(null,"clean_exit");report.close();quit(0)
