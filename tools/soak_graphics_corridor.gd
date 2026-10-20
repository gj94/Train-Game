extends "res://tools/check_streaming_reversal.gd"
## Four regional camera sweeps at 140 km/h, with the railway frozen.
## Exercises streaming, rebasing, daytime wire shadows and lit night scenery.
var missing_near_samples:=0
var frozen_time:=0.0
var regions:=[]
func near_missing() -> int:
	var result:=0
	var at: Vector3=game.cam.global_position+game.wv.coordinate_origin
	for id in game.wv.wanted:
		var job: Dictionary=game.wv.wanted[id]
		if job.kind not in ["track","ohe"]:continue
		if Vector2(at.x-job.point.x,at.z-job.point.z).length_squared()>240*240:continue
		if not game.wv.loaded.has(id) or not game.wv.loaded[id].node.visible:result+=1
	return result
func run() -> void:
	root.size=Vector2i(1280,720);started=Time.get_ticks_msec()
	if not await load_service("B012"):printerr("GRAPHICS_SOAK loading timeout");quit(2);return
	game.journey_tools.save_directory=output+"/fixture-saves"
	game._set_paused(true);game.set_physics_process(false);frozen_time=game.world.time
	game._set_cab_visuals(false);game.dispatcher.set_open(false);game.hud.hide()
	Engine.max_fps=30
	var graph: TrackGraph=game.world.graph
	for region in [{a="ERS",b="TUVR",hour=15.0},{a="QLN",b="VAK",hour=8.5},{a="TVC",b="NYY",hour=20.0},{a="KZT",b="NCJ",hour=16.0}]:
		var a: Dictionary=game.world.stations.filter(func(s):return s.code==region.a)[0]
		var b: Dictionary=game.world.stations.filter(func(s):return s.code==region.b)[0]
		route=route_between(graph.edges[a.platform_tracks[0]].a,graph.edges[b.platform_tracks[0]].b)
		route_length=0
		for step in route:route_length+=float(graph.edges[step.edge].length)
		if route_length<5000:printerr("GRAPHICS_SOAK invalid region ",region.a);quit(2);return
		game.world.clock_start=region.hour*3600.0-game.world.time
		move_camera(0,false)
		var loading_started:=Time.get_ticks_msec()
		for i in 15:await process_frame
		while game.wv.loading or game.wv.has_pending_work():
			await process_frame
			if Time.get_ticks_msec()-loading_started>180000:printerr("GRAPHICS_SOAK region loading timeout ",region.a);quit(2);return
		var length:=minf(14000,route_length);var distance:=0.0;var backward:=false
		var last:=Time.get_ticks_msec();var until:=last+seconds*250
		var origin: Vector3=game.wv.coordinate_origin
		var first_missing:=missing_near_samples;var first_errors:=errors;var first_rebase:=origin_changes
		var captures:=0
		while Time.get_ticks_msec()<until:
			await process_frame
			var now:=Time.get_ticks_msec();var elapsed: float=(now-last)*.001;last=now
			distance+=elapsed*140.0/3.6*(-1 if backward else 1)
			if distance>length:distance=length;backward=true
			elif distance<0:distance=0;backward=false
			move_camera(distance,backward)
			if game.wv.coordinate_origin!=origin:origin_changes+=1;origin=game.wv.coordinate_origin
			if game.world.time!=frozen_time:printerr("GRAPHICS_SOAK railway advanced");quit(2);return
			if now>=next_sample:
				var missing:=near_missing()
				if missing>0:missing_near_samples+=1
				record(region.a+("_reverse" if backward else "_forward"))
				print("GRAPHICS_NEAR missing=",missing," region=",region.a)
				coverage_samples+=1;next_sample=now+10000
			if captures<3 and now>=until-seconds*250+captures*seconds*250/3:
				await RenderingServer.frame_post_draw
				root.get_texture().get_image().save_png(output+"/%s-%d.png"%[region.a,captures])
				captures+=1
		regions.append({region=region.a,hour=region.hour,near_missing_samples=missing_near_samples-first_missing,coverage_errors=errors-first_errors,origin_changes=origin_changes-first_rebase})
	await close_service()
	var result:={complete=true,errors=errors,regions=regions,coverage_samples=coverage_samples,missing_near_samples=missing_near_samples,
		origin_changes=origin_changes,wall_seconds=(Time.get_ticks_msec()-started)*.001,journeys=summaries,
		note="Native source-only 140 km/h camera sweeps; railway frozen; 30 FPS cap; development Radeon 780M. No timetable rehearsal or target-PC FPS claim."}
	FileAccess.open(output+"/result.json",FileAccess.WRITE).store_string(JSON.stringify(result,"\t"))
	log_file.close();print("GRAPHICS_SOAK_COMPLETE ",JSON.stringify(result));quit(1 if errors or missing_near_samples else 0)
