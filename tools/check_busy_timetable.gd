extends SceneTree
const Trial := preload("res://sim/service_trial.gd")
const Depot := preload("res://sim/depot_workings.gd")
func _init() -> void:
	var source_revision := source_digest("res://sim")
	var began := Time.get_ticks_msec()
	var w := preload("res://sim/layouts/kerala_coast.gd").build_traffic(true)
	var trial := Trial.new(w)
	var metrics := {}
	var peak := 0
	var consecutive := {}
	var offset := 0.0
	var output := ".local/busy-timetable.json"
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--delay="): offset=float(arg.trim_prefix("--delay="))
		if arg.begins_with("--output="): output=arg.trim_prefix("--output=")
	for t: Train in w.trains.values():
		metrics[t.id]={id=t.id,name=t.service_name,wait_seconds=0.0,max_wait_seconds=0.0,calls=t.timetable.stops.size()}
		consecutive[t.id]=0.0
	while not trial.done:
		if offset>0 and w.time<offset: w.trains.K1.automatic=false;w.trains.K1.controller=-1.0
		else: w.trains.K1.automatic=true
		trial.step()
		peak=maxi(peak,w.active_trains().filter(func(t):return not t.service_complete).size())
		for t: Train in w.active_trains():
			var waiting: bool=not t.service_complete and t.speed<.1 and w.clock_seconds()>t.timetable.release_time()+2 and w.time>=offset
			if waiting:
				metrics[t.id].wait_seconds+=2.0;consecutive[t.id]+=2.0
				metrics[t.id].max_wait_seconds=maxf(metrics[t.id].max_wait_seconds,consecutive[t.id])
			else: consecutive[t.id]=0.0
		if trial.ticks%300==0:
			print("%s active=%d scheduled=%d complete=%d wall=%.1fs" % [w.clock_text(),w.active_trains().size(),w.trains.values().filter(func(t):return t.lifecycle=="scheduled").size(),w.trains.values().filter(func(t):return Depot.finished(w,t)).size(),(Time.get_ticks_msec()-began)/1000.0])
			var pending:=[]
			for t: Train in w.active_trains():
				if consecutive[t.id]>180: pending.append({id=t.id,road=t.path[0].edge,wait=consecutive[t.id],reason=w.dispatcher().states.get(t.id,{}).get("reason",t.status)})
			if not pending.is_empty(): print("WAITS "+JSON.stringify(pending))
		if trial.ticks%1800==0:
			FileAccess.open(output+".checkpoint.json",FileAccess.WRITE).store_string(JSON.stringify(preload("res://sim/world_snapshot.gd").capture(w)))
		# Stop promptly on a genuinely stalled working; don't burn hours waiting
		# for the end of the operating day just to rediscover the same deadlock.
		if consecutive.values().any(func(v):return v>1800):
			trial.done=true;trial.report="A service remained blocked for over 30 minutes"
	var finished := 0
	for t: Train in w.trains.values():
		var tt=t.completed_timetable if t.completed_timetable!=null else t.timetable
		metrics[t.id].arrived=t.service_complete
		metrics[t.id].stabled=Depot.finished(w,t)
		metrics[t.id].completed_calls=tt.actual_arrivals.filter(func(a):return a>=0).size()
		metrics[t.id].arrival_delay_seconds=maxf(0,tt.actual_arrivals[-1]-tt.planned_arrival(tt.stops.size()-1)) if t.service_complete else -1
		metrics[t.id].road=t.path[0].edge;metrics[t.id].status=t.status
		if Depot.finished(w,t):finished+=1
	var result:={source_digest=source_revision,ok=trial.ok,report=trial.report,finished=finished,total=w.trains.size(),peak_active_services=peak,clock=w.clock_text(),simulation_seconds=w.time,wall_seconds=(Time.get_ticks_msec()-began)/1000.0,player_delay=offset,services=metrics,events=w.events,alerts=w.dispatcher().alerts,history=w.dispatch_history,states=w.dispatcher().states}
	FileAccess.open(output,FileAccess.WRITE).store_string(JSON.stringify(result,"\t"))
	if not trial.ok:FileAccess.open(output+".failure.json",FileAccess.WRITE).store_string(JSON.stringify(preload("res://sim/world_snapshot.gd").capture(w)))
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
