extends SceneTree
const Trial := preload("res://sim/service_trial.gd")
const Depot := preload("res://sim/depot_workings.gd")
func _init() -> void:
	var source_revision := source_digest("res://sim")
	var began := Time.get_ticks_msec()
	var metrics := {}
	var peak := 0
	var consecutive := {}
	var resumed_wait := {}
	var history := []
	var seen_history := {}
	var offset := 0.0
	var output := ".local/busy-timetable.json"
	var resume := ""
	var prior_wall := 0.0
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--delay="): offset=float(arg.trim_prefix("--delay="))
		if arg.begins_with("--output="): output=arg.trim_prefix("--output=")
		if arg.begins_with("--resume="): resume=arg.trim_prefix("--resume=")
	var w: RailWorld
	if resume.is_empty():w=preload("res://sim/layouts/kerala_coast.gd").build_traffic(true)
	else:
		# Diagnostic continuation of a failed audit, explicitly labelled in output.
		# It keeps the old schedule/state; it does not validate newly authored slots.
		var previous: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(resume))
		var checkpoint:=FileAccess.open(resume+".failure.bin",FileAccess.READ)
		if checkpoint==null:printerr("Resume needs the typed .failure.bin checkpoint");quit(1);return
		var restored: Dictionary=preload("res://sim/world_snapshot.gd").restore(checkpoint.get_var(false))
		if not restored.ok:printerr(restored.reason);quit(1);return
		w=restored.world
		metrics=previous.services;peak=previous.peak_active_services;history=previous.history
		offset=previous.player_delay;prior_wall=previous.wall_seconds;source_revision=previous.source_digest
		for event in history:seen_history[JSON.stringify(event)]=true
	var trial := Trial.new(w)
	for t: Train in w.trains.values():
		if not metrics.has(t.id):metrics[t.id]={id=t.id,name=t.service_name,priority=t.dispatch_priority,wait_seconds=0.0,max_wait_seconds=0.0,calls=t.timetable.stops.size(),booked_stops=t.timetable.stops.duplicate(true),departure=t.timetable.departure}
		consecutive[t.id]=metrics[t.id].get("current_wait_seconds",0.0)
		resumed_wait[t.id]=consecutive[t.id] if not resume.is_empty() else 0.0
	while not trial.done:
		if offset>0 and w.time<offset: w.trains.K1.automatic=false;w.trains.K1.controller=-1.0
		else: w.trains.K1.automatic=true
		trial.step()
		for event in w.dispatch_history:
			var key: String=JSON.stringify(event)
			if not seen_history.has(key):history.append(event.duplicate());seen_history[key]=true
		peak=maxi(peak,w.active_trains().filter(func(t):return not t.service_complete).size())
		for t: Train in w.active_trains():
			var waiting: bool=not t.service_complete and t.speed<.1 and w.clock_seconds()>t.timetable.release_time()+2 and w.time>=offset
			if waiting:
				metrics[t.id].wait_seconds+=2.0;consecutive[t.id]+=2.0
				metrics[t.id].max_wait_seconds=maxf(metrics[t.id].max_wait_seconds,consecutive[t.id])
			else: consecutive[t.id]=0.0;resumed_wait[t.id]=0.0
		if trial.ticks%300==0:
			print("%s active=%d scheduled=%d complete=%d wall=%.1fs" % [w.clock_text(),w.active_trains().size(),w.trains.values().filter(func(t):return t.lifecycle=="scheduled").size(),w.trains.values().filter(func(t):return Depot.finished(w,t)).size(),(Time.get_ticks_msec()-began)/1000.0])
			var pending:=[]
			for t: Train in w.active_trains():
				if consecutive[t.id]>180: pending.append({id=t.id,road=t.path[0].edge,wait=consecutive[t.id],reason=w.dispatcher().states.get(t.id,{}).get("reason",t.status)})
			if not pending.is_empty(): print("WAITS "+JSON.stringify(pending))
		if trial.ticks%1800==0:
			var state: Dictionary=preload("res://sim/world_snapshot.gd").capture(w)
			FileAccess.open(output+".checkpoint.json",FileAccess.WRITE).store_string(JSON.stringify(state))
			FileAccess.open(output+".checkpoint.bin",FileAccess.WRITE).store_var(state)
		# Collect all excessive waits in one day instead of discovering only the
		# first bad slot per run. Thirty minutes still FAILS the quality check;
		# forty-five minutes aborts promptly as a likely stalled working.
		# A diagnostic continuation gets another watchdog interval to expose
		# downstream conflicts; its full accumulated wait still fails quality.
		if consecutive.keys().any(func(id):return consecutive[id]-resumed_wait[id]>2700):
			trial.done=true;trial.report="A service remained blocked for over 45 minutes"
	var finished := 0
	for t: Train in w.trains.values():
		var tt=t.completed_timetable if t.completed_timetable!=null else t.timetable
		metrics[t.id].arrived=t.service_complete
		metrics[t.id].stabled=Depot.finished(w,t)
		metrics[t.id].completed_calls=tt.actual_arrivals.filter(func(a):return a>=0).size()
		metrics[t.id].actual_arrivals=tt.actual_arrivals.duplicate()
		metrics[t.id].actual_departures=tt.actual_departures.duplicate()
		metrics[t.id].arrival_delay_seconds=maxf(0,tt.actual_arrivals[-1]-tt.planned_arrival(tt.stops.size()-1)) if t.service_complete else -1
		metrics[t.id].road=t.path[0].edge;metrics[t.id].status=t.status
		metrics[t.id].current_wait_seconds=consecutive[t.id]
		if Depot.finished(w,t):finished+=1
	var excessive: Array=metrics.values().filter(func(m):return m.max_wait_seconds>1800).map(func(m):return m.id)
	if trial.ok and not excessive.is_empty():trial.ok=false;trial.report="All services finished, but waits over 30 minutes need timetable review: "+str(excessive)
	var result:={source_digest=source_revision,resumed_from=resume,excessive_wait_services=excessive,ok=trial.ok,report=trial.report,finished=finished,total=w.trains.size(),peak_active_services=peak,clock=w.clock_text(),simulation_seconds=w.time,wall_seconds=prior_wall+(Time.get_ticks_msec()-began)/1000.0,player_delay=offset,services=metrics,events=w.events,alerts=w.dispatcher().alerts,history=history,states=w.dispatcher().states}
	FileAccess.open(output,FileAccess.WRITE).store_string(JSON.stringify(result,"\t"))
	if not trial.ok:
		var state: Dictionary=preload("res://sim/world_snapshot.gd").capture(w)
		FileAccess.open(output+".failure.json",FileAccess.WRITE).store_string(JSON.stringify(state))
		FileAccess.open(output+".failure.bin",FileAccess.WRITE).store_var(state)
	print("AUDIT "+trial.report+"; complete=%d/%d; peak=%d; wall=%.1fs; report=%s" % [finished,w.trains.size(),peak,result.wall_seconds,output])
	quit(0 if trial.ok else 1)

func source_digest(root_path: String) -> String:
	var entries: Array[String]=[]
	var dir:=DirAccess.open(root_path)
	for path in dir.get_files():
		if path.ends_with(".gd") or path.ends_with(".json"):entries.append(path+":"+FileAccess.get_sha256(root_path+"/"+path))
	for path in dir.get_directories():entries.append(path+":"+source_digest(root_path+"/"+path))
	entries.sort()
	return "\n".join(entries).sha256_text()
