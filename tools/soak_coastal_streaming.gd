extends SceneTree
## Long native x1 journeys exercise real-time cache retirement and world teardown.
## This is a stability run, not an isolated frame-time benchmark.
var output:="res://.local/overnight-2026-10-14/streaming-soak"
var seconds:=3600
var game
var log_file: FileAccess
var errors:=0
var started:=0
var next_sample:=0
var phase:=-1
var summaries:=[]

func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--output="):output=arg.trim_prefix("--output=")
		if arg.begins_with("--seconds="):seconds=maxi(60,int(arg.trim_prefix("--seconds=")))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output))
	log_file=FileAccess.open(output+"/samples.jsonl",FileAccess.WRITE)
	call_deferred("run")

func record(label: String) -> void:
	var visible_patches:=0;var coverage_errors:=0;var far_chunks:=0
	for chunk in game.wv.loaded.values():
		if not chunk.has("terrain_patches") or not chunk.node.visible:continue
		far_chunks+=1
		for tile in chunk.terrain_patches:
			var id: String=("tile:" if game.wv.corridor_tiles.has(tile) else "landscape:")+str(tile)
			var covered: bool=game.wv.loaded.has(id) and game.wv.loaded[id].node.visible
			if chunk.terrain_patches[tile].visible==covered:coverage_errors+=1
			if chunk.terrain_patches[tile].visible:visible_patches+=1
	errors+=coverage_errors
	var row:={label=label,wall_seconds=(Time.get_ticks_msec()-started)*.001,
		service=game.train.id,clock=game.world.clock_seconds(),edge=game.train.path[0].edge,
		speed_kmh=game.train.speed*3.6,odometer=game.train.odometer,loading=game.wv.loading,
		heap_bytes=OS.get_static_memory_usage(),nodes=Performance.get_monitor(Performance.OBJECT_NODE_COUNT),
		video_bytes=Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED),loaded=game.wv.loaded.size(),
		warm=game.wv._warm.size(),pending=game.wv.queue.size(),activated=game.wv.completed_jobs,
		cache_hits=game.wv.cache_hits,far_chunks=far_chunks,coarse_patches=visible_patches,coverage_errors=coverage_errors,
		origin=str(game.wv.coordinate_origin)}
	log_file.store_line(JSON.stringify(row));log_file.flush();print(JSON.stringify(row))

func load_service(id: String) -> bool:
	var page:=preload("res://game/launch.gd").new();root.add_child(page);current_scene=page
	await process_frame;await process_frame
	var row: Dictionary=page.services.filter(func(r):return r.id==id)[0]
	page._begin("service",row)
	var began:=Time.get_ticks_msec()
	while current_scene==page or current_scene==null:
		await process_frame
		if Time.get_ticks_msec()-began>180000:return false
	game=current_scene
	while game.wv.loading:
		await process_frame
		if Time.get_ticks_msec()-began>180000:return false
	game.train.automatic=true;game.world.dispatcher().manual_service=""
	# Explicitly exercise the release-only bounded logger in this source harness.
	game.journey_diagnostics=preload("res://game/journey_diagnostics.gd").new(output+"/journal")
	game.journey_diagnostics.start({build="Source native soak",service=id})
	game._set_time_scale(1);game._set_paused(false);game.hud.show_modal("")
	return true

func close_service() -> void:
	record("before_menu")
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(output+"/"+game.train.id+"_end.png")
	var old: WeakRef=weakref(game.wv)
	game._ui_action("landing");game._confirm_action()
	var previous=game
	while current_scene==previous or current_scene==null:await process_frame
	game=null;previous=null
	for i in 8:await process_frame
	summaries.append({released_world=old.get_ref()==null,heap_after_menu=OS.get_static_memory_usage()})
	if old.get_ref()!=null:errors+=1
	current_scene.free();current_scene=null

func run() -> void:
	root.size=Vector2i(1280,720)
	started=Time.get_ticks_msec()
	for service in ["B012","B011"]:
		if not await load_service(service):printerr("SOAK loading timeout");quit(2);return
		record("ready")
		var until:=Time.get_ticks_msec()+seconds*500
		var segment_start:=Time.get_ticks_msec();phase=-1
		while Time.get_ticks_msec()<until:
			await process_frame
			var view_phase:=int((Time.get_ticks_msec()-segment_start)/300000)%2
			if view_phase!=phase:
				phase=view_phase
				if phase==0:game._pilot_camera()
				else:game._passenger_preset(0)
			if Time.get_ticks_msec()>=next_sample:
				record("driving");next_sample=Time.get_ticks_msec()+10000
		await close_service()
	var result:={complete=true,errors=errors,journeys=summaries,wall_seconds=(Time.get_ticks_msec()-started)*.001,
		adapter=RenderingServer.get_video_adapter_name(),note="Source-game x1 stability soak; dummy audio; development GPU; not an isolated performance benchmark."}
	FileAccess.open(output+"/result.json",FileAccess.WRITE).store_string(JSON.stringify(result,"\t"))
	log_file.close();print("SOAK_COMPLETE ",JSON.stringify(result));quit(1 if errors else 0)
