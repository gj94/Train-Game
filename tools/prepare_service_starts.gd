extends SceneTree
## Run once before release: baseline replay, complete snapshots, full-day audit.
const Starts:=preload("res://persistence/service_starts.gd")
const Snapshot:=preload("res://sim/world_snapshot.gd")
const Depot:=preload("res://sim/depot_workings.gd")
var output:=Starts.DIRECTORY

func _initialize() -> void:
	call_deferred("run")

func write_catalogue(data: Dictionary) -> void:
	FileAccess.open(output.path_join("catalogue.json"),FileAccess.WRITE).store_string(JSON.stringify(data,"\t"))

func run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--output="):output=arg.trim_prefix("--output=")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output))
	var began:=Time.get_ticks_msec()
	var w:=preload("res://sim/layouts/kerala_coast.gd").build_traffic(true)
	for t: Train in w.trains.values():t.automatic=true
	w.dispatcher().manual_service="";w.dispatcher().enabled=true
	var data:={version=Starts.VERSION,engine=Engine.get_version_info().string,complete=false,services=[],sources={},layout_signature=Snapshot.signature(w)}
	data.sources=preload("res://persistence/prepared_sources.gd").collect()
	var pending:={};var waits:={};var maximum_wait:=0.0
	for t: Train in w.trains.values():
		var tt=t.timetable
		var formation:=preload("res://sim/stock/ported_stock.gd").formation(t.stock_kind.trim_prefix("ported:"),t.rake_profile)
		pending[t.id]={id=t.id,name=t.service_name,origin=tt.stops[0].name,destination=tt.stops[-1].name,stock=t.stock_kind.trim_prefix("ported:"),
			departure=tt.departure,start_clock=0.0,duration=tt.planned_arrival(tt.stops.size()-1)-tt.departure,stops=tt.stops.size(),cars=formation.size(),file=t.id+".bin",sha256=""}
		waits[t.id]=0.0
	var trial:=preload("res://sim/service_trial.gd").new(w)
	while not trial.done:
		for id in pending.keys():
			var t: Train=w.trains[id]
			if t.lifecycle!="active":continue
			if t.speed>.01 or not t.timetable.at_stop or t.timetable.index!=0:
				printerr("Missed origin state for "+id);quit(1);return
			var state:=Snapshot.capture(w)
			var path:=output.path_join(id+".bin")
			var file:=FileAccess.open_compressed(path,FileAccess.WRITE,FileAccess.COMPRESSION_ZSTD)
			if file==null:printerr("Cannot write "+path);quit(1);return
			file.store_var(state);file.close()
			var row: Dictionary=pending[id];row.start_clock=w.clock_seconds();row.sha256=FileAccess.get_sha256(path)
			var info:=preload("res://persistence/service_briefing.gd").describe(w,t)
			if info.is_empty():printerr("Unreachable schedule: "+id);quit(1);return
			row.merge(info)
			var restored:=Starts.load_start(row,output)
			if not restored.ok or var_to_bytes(Snapshot.capture(restored.world))!=var_to_bytes(state):
				printerr("Snapshot restore mismatch "+id+": "+restored.get("reason",""));quit(1);return
			data.services.append(row);pending.erase(id)
			print("START %s %s (%d/100)" % [id,w.clock_text(),data.services.size()])
			write_catalogue(data)
		trial.step()
		for t: Train in w.active_trains():
			var waiting: bool=not t.service_complete and t.speed<.1 and w.clock_seconds()>t.timetable.release_time()+2
			waits[t.id]=waits[t.id]+2.0 if waiting else 0.0
			maximum_wait=maxf(maximum_wait,waits[t.id])
			if waits[t.id]>2700:trial.done=true;trial.report="Excessive wait: "+t.id
		if trial.ticks%300==0:
			print("REPLAY %s prepared=%d active=%d finished=%d wall=%.1fs" % [w.clock_text(),data.services.size(),w.active_trains().size(),w.trains.values().filter(func(t):return Depot.finished(w,t)).size(),(Time.get_ticks_msec()-began)*.001])
	data.services.sort_custom(func(a,b):return a.departure<b.departure if a.departure!=b.departure else a.id.naturalnocasecmp_to(b.id)<0)
	data.audit={ok=trial.ok and pending.is_empty() and maximum_wait<=1800,report=trial.report,maximum_wait=maximum_wait,
		wall_seconds=(Time.get_ticks_msec()-began)*.001,clock=w.clock_seconds(),events=w.events,finished=w.trains.values().filter(func(t):return Depot.finished(w,t)).size()}
	data.complete=data.audit.ok
	write_catalogue(data)
	print("PREPARED ",JSON.stringify(data.audit))
	quit(0 if data.complete else 1)
