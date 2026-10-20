extends "res://tools/soak_graphics_corridor.gd"
## Final-source native station tour. Holds each scene after streaming settles;
## the railway stays frozen. No timetable replay or distribution gameplay run.
func run() -> void:
	root.size=Vector2i(1440,900);started=Time.get_ticks_msec()
	if not await load_service("B012"):printerr("STATION_TOUR loading timeout");quit(2);return
	game.journey_tools.save_directory=output+"/fixture-saves"
	game._set_paused(true);game.set_physics_process(false);frozen_time=game.world.time
	game._set_cab_visuals(false);game.dispatcher.set_open(false);game.hud.hide()
	Engine.max_fps=30
	var results:=[];var index:=0
	for station in game.world.stations:
		var sites: Array=preload("res://game/station_precinct_plan.gd").entries(game.wv.geo.station_sites,station)
		if sites.is_empty():continue
		var site: Dictionary=sites[0]
		var hour: float=[9.0,16.0,20.0][index%3]
		if station.code=="TVC":hour=20
		elif station.code=="QLN":hour=16
		var now:=Time.get_ticks_msec()
		game.world.clock_start=hour*3600-frozen_time
		var target: Vector3=site.centre+Vector3.UP*3
		var eye: Vector3=site.centre-site.basis.z*85+site.basis.x*45+Vector3.UP*28
		game.cam.enter_free(eye-game.wv.coordinate_origin,(target-eye).normalized())
		for i in 15:await process_frame
		while game.wv.loading or game.wv.has_pending_work():
			await process_frame
			if Time.get_ticks_msec()-now>180000:printerr("STATION_TOUR streaming timeout ",station.code);quit(2);return
		var load_ms:=Time.get_ticks_msec()-now
		var until:=Time.get_ticks_msec()+maxi(20000,seconds*1000/game.world.stations.size())
		var first_errors:=errors;var first_missing:=missing_near_samples
		var captured:=false
		while Time.get_ticks_msec()<until:
			await process_frame
			if game.world.time!=frozen_time:printerr("STATION_TOUR railway advanced");quit(2);return
			if Time.get_ticks_msec()>=next_sample:
				var missing:=near_missing()
				if missing>0:missing_near_samples+=1
				record(station.code);coverage_samples+=1;next_sample=Time.get_ticks_msec()+10000
				print("STATION_TOUR_NEAR ",station.code," missing=",missing)
			if not captured and Time.get_ticks_msec()>until-10000:
				await RenderingServer.frame_post_draw
				root.get_texture().get_image().save_png(output+"/"+station.code+".png")
				captured=true
		results.append({station=station.code,hour=hour,load_ms=load_ms,coverage_errors=errors-first_errors,near_missing_samples=missing_near_samples-first_missing,access_links=site.access.size()})
		index+=1
	await close_service()
	var result:={complete=true,stations=results,errors=errors,missing_near_samples=missing_near_samples,
		coverage_samples=coverage_samples,wall_seconds=(Time.get_ticks_msec()-started)*.001,journeys=summaries,
		note="Native source station tour, frozen railway, 30 FPS cap; development Radeon 780M. No timetable rehearsal."}
	FileAccess.open(output+"/result.json",FileAccess.WRITE).store_string(JSON.stringify(result,"\t"))
	log_file.close();print("STATION_TOUR_COMPLETE ",JSON.stringify(result));quit(1 if errors or missing_near_samples else 0)
