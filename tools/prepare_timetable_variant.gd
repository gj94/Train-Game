extends SceneTree
## Serial operating-day rehearsal: starts, timeline and traffic share one replay.
## Outputs stay in the requested staging folder until all validation passes.
const Pack:=preload("res://sim/service_pack.gd")
const Starts:=preload("res://persistence/service_starts.gd")
const Snapshot:=preload("res://sim/world_snapshot.gd")
const Times:=preload("res://persistence/railway_times.gd")
const Depot:=preload("res://sim/depot_workings.gd")
const Observer:=preload("res://tools/record_service_traffic.gd")
var pack_path:="res://art/timetables/kerala-coast-intensive.json"
var output:="res://.local/intensive-candidate"
var snapshots:=false
var delay:=0.0
var delay_service:="K1"
var delay_at:=0.0
var standard:=false

func _initialize() -> void:call_deferred("run")

func json_file(path: String, value) -> void:
	FileAccess.open(path,FileAccess.WRITE).store_string(JSON.stringify(value,"\t"))

func run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--pack="):pack_path=arg.trim_prefix("--pack=")
		elif arg.begins_with("--output="):output=arg.trim_prefix("--output=")
		elif arg=="--snapshots":snapshots=true
		elif arg=="--standard":standard=true
		elif arg.begins_with("--delay="):delay=float(arg.trim_prefix("--delay="))
		elif arg.begins_with("--delay-at="):delay_at=float(arg.trim_prefix("--delay-at="))
		elif arg.begins_with("--delay-service="):delay_service=arg.trim_prefix("--delay-service=")
	var decoded: Dictionary={ok=true,world=preload("res://sim/layouts/kerala_coast.gd").build_traffic(true)} if standard else Pack.decode(FileAccess.get_file_as_string(pack_path))
	if not decoded.ok:printerr(decoded.reason);quit(1);return
	var w: RailWorld=decoded.world
	for t: Train in w.trains.values():t.automatic=true
	w.dispatcher().manual_service=""
	if not w.trains.has(delay_service):printerr("Unknown delayed train");quit(1);return
	if snapshots and delay>0:printerr("Disturbed runs are audits, never baseline starts");quit(1);return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output))
	for sub in ["starts","times"]:DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output.path_join(sub)))
	var began:=Time.get_ticks_msec()
	var sources:=preload("res://persistence/prepared_sources.gd").collect()
	if not standard:sources[pack_path.trim_prefix("res://")]=FileAccess.get_file_as_string(pack_path).replace("\r\n","\n").sha256_text()
	var catalogue:={version=1,engine=Engine.get_version_info().string,complete=false,services=[],sources=sources,layout_signature=Snapshot.signature(w)}
	var timeline:={version=1,engine=Engine.get_version_info().string,complete=false,states=[],sources=sources,layout_signature=catalogue.layout_signature}
	var pending:={};var metrics:={};var maximum_wait:=0.0;var peak:=0
	for t: Train in w.trains.values():
		var tt=t.timetable
		pending[t.id]=true
		metrics[t.id]={name=t.service_name,priority=t.dispatch_priority,departure=tt.departure,booked_stops=tt.stops.duplicate(true),wait_seconds=0.0,max_wait_seconds=0.0,current_wait=0.0}
	var raw:=FileAccess.open(output+"/traffic.jsonl",FileAccess.WRITE)
	var trial:=preload("res://sim/service_trial.gd").new(w)
	var next_snapshot:=w.clock_seconds()
	var stations:=w.stations.map(func(s):return {code=s.code,name=s.name,s=s.s,half=s.yard_half})
	while not trial.done:
		if snapshots:
			for id in pending.keys():
				var t: Train=w.trains[id]
				if t.lifecycle!="active":continue
				if t.speed>.01 or not t.timetable.at_stop or t.timetable.index!=0:printerr("Missed origin "+id);quit(1);return
				var row:=preload("res://persistence/service_briefing.gd").describe(w,t)
				var formation:=preload("res://sim/stock/ported_stock.gd").formation(t.stock_kind.trim_prefix("ported:"),t.rake_profile)
				row.merge({id=id,name=t.service_name,origin=t.timetable.stops[0].name,destination=t.timetable.stops[-1].name,stock=t.stock_kind.trim_prefix("ported:"),
					departure=t.timetable.departure,start_clock=w.clock_seconds(),duration=t.timetable.planned_arrival(t.timetable.stops.size()-1)-t.timetable.departure,
					stops=t.timetable.stops.size(),cars=formation.size(),file=id+".bin"})
				var state:=Snapshot.capture(w)
				row.sha256=write_state(output+"/starts/"+row.file,state)
				var restored:=Starts.load_start(row,output+"/starts")
				if not restored.ok or var_to_bytes(Snapshot.capture(restored.world))!=var_to_bytes(state):printerr("Departure restore mismatch "+id);quit(1);return
				catalogue.services.append(row);pending.erase(id)
				json_file(output+"/starts/catalogue.json",catalogue)
			if w.clock_seconds()>=next_snapshot-.001:
				if not write_time(w,timeline):quit(1);return
				next_snapshot+=300
		raw.store_line(JSON.stringify([w.clock_seconds(),Observer.positions(w)]))
		var held: bool=delay>0 and w.time>=delay_at and w.time<delay_at+delay
		w.trains[delay_service].automatic=not held
		if held:w.trains[delay_service].controller=-1
		trial.step()
		peak=maxi(peak,w.active_trains().size())
		for t: Train in w.active_trains():
			var m: Dictionary=metrics[t.id]
			var waiting: bool=not t.service_complete and t.speed<.1 and w.clock_seconds()>t.timetable.release_time()+2 and not (held and t.id==delay_service)
			m.current_wait=m.current_wait+2 if waiting else 0.0
			if waiting:m.wait_seconds+=2
			m.max_wait_seconds=maxf(m.max_wait_seconds,m.current_wait);maximum_wait=maxf(maximum_wait,m.current_wait)
			if m.current_wait>2700:trial.done=true;trial.ok=false;trial.report="Wait exceeded 45 minutes: "+t.id
		if trial.ticks%300==0:
			raw.flush()
			print("%s complete=%d/%d peak=%d max_wait=%.1fm wall=%.1fs" % [w.clock_text(),w.trains.values().filter(func(t):return Depot.finished(w,t)).size(),w.trains.size(),peak,maximum_wait/60,(Time.get_ticks_msec()-began)*.001])
			var waiting:=w.active_trains().filter(func(t):return metrics[t.id].current_wait>180).map(func(t):return {id=t.id,road=t.path[0].edge,wait=metrics[t.id].current_wait,reason=w.dispatcher().states.get(t.id,{}).get("reason",t.status)})
			if not waiting.is_empty():print("WAITS "+JSON.stringify(waiting))
	var finished: int=w.trains.values().filter(func(t):return Depot.finished(w,t)).size()
	if trial.ok:
		var final_clock:=ceili(w.clock_seconds()/300)*300
		while w.clock_seconds()<final_clock-.001:
			raw.store_line(JSON.stringify([w.clock_seconds(),Observer.positions(w)]))
			w.step(minf(2,final_clock-w.clock_seconds()))
		if snapshots and not write_time(w,timeline):quit(1);return
	raw.store_line(JSON.stringify([w.clock_seconds(),Observer.positions(w)]));raw.close()
	for t: Train in w.trains.values():
		var tt=t.completed_timetable if t.completed_timetable!=null else t.timetable
		metrics[t.id].actual_arrivals=tt.actual_arrivals
		metrics[t.id].actual_departures=tt.actual_departures
		metrics[t.id].stabled=Depot.finished(w,t)
		metrics[t.id].arrival_delay=maxf(0,tt.actual_arrivals[-1]-tt.planned_arrival(tt.stops.size()-1)) if t.service_complete else -1
	var audit:={ok=trial.ok and maximum_wait<=1800 and w.events.is_empty(),report=trial.report,maximum_wait=maximum_wait,
		wall_seconds=(Time.get_ticks_msec()-began)*.001,clock=w.clock_seconds(),events=w.events,finished=finished,total=w.trains.size(),peak_active=peak,
		pack_sha256="" if standard else FileAccess.get_sha256(pack_path),operating_day="standard" if standard else "intensive",
		delay=delay,delay_service=delay_service,delay_at=delay_at}
	json_file(output+"/audit.json",{audit=audit,services=metrics,stations=stations,history=w.dispatch_history,sources=sources})
	if snapshots:
		catalogue.services.sort_custom(func(a,b):return a.departure<b.departure if a.departure!=b.departure else a.id<b.id)
		catalogue.audit=audit;catalogue.complete=audit.ok and pending.is_empty()
		json_file(output+"/starts/catalogue.json",catalogue)
		timeline.departure_catalogue_sha256=FileAccess.get_sha256(output+"/starts/catalogue.json")
		timeline.complete=catalogue.complete
		timeline.audit={ok=timeline.complete,states=timeline.states.size(),round_trips=timeline.states.size(),events=w.events}
		json_file(output+"/times/catalogue.json",timeline)
	if not audit.ok:
		FileAccess.open(output+"/failure.bin",FileAccess.WRITE).store_var(Snapshot.capture(w))
	print("AUDIT "+JSON.stringify(audit));quit(0 if audit.ok else 1)

func write_state(path: String, state: Dictionary) -> String:
	var f:=FileAccess.open_compressed(path,FileAccess.WRITE,FileAccess.COMPRESSION_ZSTD)
	f.store_var(state);f.close()
	return FileAccess.get_sha256(path)

func write_time(w: RailWorld, timeline: Dictionary) -> bool:
	var id:="T%06d" % roundi(w.clock_seconds())
	var row:={id=id,file=id+".bin",clock=float(roundi(w.clock_seconds())),active=Times.available(w).size()}
	var state:=Snapshot.capture(w)
	row.sha256=write_state(output+"/times/"+row.file,state)
	var restored:=Times.load_state(row,output+"/times")
	if not restored.ok or var_to_bytes(Snapshot.capture(restored.world))!=var_to_bytes(state):printerr("Timeline restore mismatch "+id+": "+restored.get("reason","state differs"));return false
	timeline.states.append(row)
	return true
