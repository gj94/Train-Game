extends SceneTree
## Focused player-assigned pause, continued from this build's fresh 12:55 state.
## Diagnostic only: these disturbed states never become selectable baselines.
const Snapshot:=preload("res://sim/world_snapshot.gd")
const Policy:=preload("res://sim/priority_dispatch.gd")
func _initialize() -> void:call_deferred("run")
func run() -> void:
	var folder:="res://.local/intensive-v10"
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--baseline="):folder=arg.trim_prefix("--baseline=")
	var catalogue: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(folder+"/starts/catalogue.json"))
	var sources:=preload("res://persistence/prepared_sources.gd").collect()
	var pack:="art/timetables/kerala-coast-intensive.json"
	sources[pack]=FileAccess.get_file_as_string("res://"+pack).replace("\r\n","\n").sha256_text()
	if catalogue.sources!=sources:printerr("Stale manual-delay fixture");quit(1);return
	var path:=folder+"/times/T046500.bin"
	var file:=FileAccess.open_compressed(path,FileAccess.READ,FileAccess.COMPRESSION_ZSTD)
	if file==null:printerr("Missing fresh 12:55 state");quit(1);return
	var loaded:=Snapshot.restore(file.get_var(false));file.close()
	if not loaded.ok:printerr(loaded.reason);quit(1);return
	var w: RailWorld=loaded.world
	if w.trains.size()!=140 or absf(w.clock_seconds()-46500)>.01:printerr("Wrong railway/time");quit(1);return
	var driver: Train=w.trains.K1
	w.dispatcher().manual_service="K1"
	var began:=Time.get_ticks_msec();var start_distance:=driver.odometer
	var waits:={};var peaks:={};var maximum:=0.0;var manual_samples:=0;var route_samples:=0;var ticks:=0
	while w.clock_seconds()<61200 and w.events.is_empty() and maximum<2700:
		var held: bool=w.clock_seconds()>=46800 and w.clock_seconds()<47400
		driver.automatic=not held
		if held:driver.controller=-1;manual_samples+=1
		w.step(2);ticks+=1
		if held and w.signals.values().any(func(s):return s.owner=="K1" and not s.route.is_empty()):route_samples+=1
		for t: Train in w.active_trains():
			var waiting: bool=not t.service_complete and t.speed<.1 and (not t.timetable.at_stop or w.clock_seconds()>t.timetable.release_time()+2) and not (held and t.id=="K1")
			waits[t.id]=waits.get(t.id,0.0)+2 if waiting else 0.0
			peaks[t.id]=maxf(peaks.get(t.id,0),waits[t.id]);maximum=maxf(maximum,waits[t.id])
		if ticks%300==0:print("%s K1=%s max_wait=%.1fm" % [w.clock_text(),driver.path[0].edge,maximum/60])
	var ok: bool=w.events.is_empty() and maximum<2700 and manual_samples==300 and route_samples>0 and driver.odometer-start_distance>10000 and w.clock_seconds()>=61200
	var report:={ok=ok,method="Player-assigned K1 from fresh 12:55 baseline; manually braked 13:00–13:10 while dispatcher retains player route preparation; resume AI through 17:00. Focused diagnostic, not a baseline or full-day wait-distribution audit.",
		clock=w.clock_seconds(),source_sha256=FileAccess.get_sha256(path),sources=sources,events=w.events,manual_seconds=manual_samples*2,manual_route_seconds=route_samples*2,
		maximum_wait=maximum,wait_peaks=peaks,k1_road=driver.path[0].edge,k1_distance_advanced=driver.odometer-start_distance,wall_seconds=(Time.get_ticks_msec()-began)*.001}
	FileAccess.open("res://.local/intensive-manual-delay.json",FileAccess.WRITE).store_string(JSON.stringify(report,"\t"))
	print(JSON.stringify(report));quit(0 if ok else 1)
