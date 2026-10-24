extends SceneTree
## Live-worker stress on a real crowded railway checkpoint. Operator commands
## run only on its owner; this never edits the saved baseline or certifies it.
const Snapshot:=preload("res://sim/world_snapshot.gd")
const Times:=preload("res://persistence/railway_times.gd")
const InputData:=preload("res://sim/dispatch_forecast_input.gd")
var folder:="res://.local/dispatcher-v2-2026-10-24/rehearsals-v3/predictive-intensive"
var output:="res://.local/dispatcher-v2-2026-10-24/busy-async.json"
var failures:=[]
var commands:=[]

func _initialize() -> void:call_deferred("run")
func check(value: bool,reason: String) -> void:
	if not value:failures.append(reason);printerr(reason)

func run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--folder="):folder=arg.trim_prefix("--folder=")
		elif arg.begins_with("--output="):output=arg.trim_prefix("--output=")
	var catalogue=JSON.parse_string(FileAccess.get_file_as_string(folder+"/starts/catalogue.json"))
	if not catalogue is Dictionary:printerr("Missing frozen rehearsal catalogue");quit(1);return
	for path: String in catalogue.sources:
		var digest:=FileAccess.get_sha256("res://"+path) if path.ends_with(".bin") else FileAccess.get_file_as_string("res://"+path).replace("\r\n","\n").sha256_text()
		check(digest==catalogue.sources[path],"Changed railway input "+path)
	if not failures.is_empty():quit(1);return
	var checkpoint:="T045300"
	var path:=folder+"/times/"+checkpoint+".bin"
	var loaded:=Times.load_state({id=checkpoint,file=checkpoint+".bin",clock=45300.0,sha256=FileAccess.get_sha256(path)},folder+"/times")
	if not loaded.ok:printerr(loaded.reason);quit(1);return
	var w: RailWorld=loaded.world;var e=w.dispatcher()
	e.predictive.execution(true)
	check(w.trains.size()==140,"Expected the real 140-service railway")
	check(e.predictive.enabled,"Checkpoint is not Predictive V2")
	for id in ["K1","D101","D108"]:check(w.trains.has(id) and w.trains[id].lifecycle=="active","Missing active stress participant "+id)
	if not failures.is_empty():quit(1);return
	var began:=w.time;var wall:=Time.get_ticks_msec()
	var initial:={};var observed:={};var newcomers:={};var threads:=[]
	for t: Train in w.active_trains():observed[t.id]=true
	for id in ["K1","D101","D108"]:initial[id]=InputData.chainage(w,w.trains[id])
	var old_priority: int=w.trains.D108.dispatch_priority
	var peak:=w.active_trains().size();var plan_samples:=0;var accepted_jobs:=0
	var last_job:=-1.0;var phase:=0;var restored_pending:=false
	while w.time<began+1800 and w.events.is_empty() and failures.is_empty():
		var elapsed:=w.time-began
		if phase==0 and elapsed>=90:
			w.trains.K1.automatic=false;w.trains.K1.controller=-1;command(w,"Manual K1 brake");phase+=1
		elif phase==1 and elapsed>=210:
			w.trains.K1.automatic=true;command(w,"Return K1 to AI");phase+=1
		elif phase==2 and elapsed>=300:
			check(e.set_service_hold("D101",true).ok,"Could not hold D101");command(w,"Hold D101 at next uncommitted signal");phase+=1
		elif phase==3 and elapsed>=420:
			check(e.set_service_hold("D101",false).ok,"Could not release D101");command(w,"Release D101");phase+=1
		elif phase==4 and elapsed>=600:
			check(e.set_priority("D108",100).ok,"Could not promote D108");command(w,"Promote D108 to priority 100");phase+=1
		elif phase==5 and elapsed>=720:
			check(e.set_priority("D108",old_priority).ok,"Could not restore D108 priority");command(w,"Restore D108 priority");phase+=1
		elif phase==6 and elapsed>=900:
			var routes:=var_to_bytes(w.signals);check(e.set_mode("classic").ok,"Classic switch refused")
			check(routes==var_to_bytes(w.signals),"Mode switch changed movement authorities");command(w,"Switch to Classic without changing routes");phase+=1
		elif phase==7 and elapsed>=930:
			var routes:=var_to_bytes(w.signals);check(e.set_mode("predictive").ok,"V2 switch refused")
			check(routes==var_to_bytes(w.signals),"V2 switch changed movement authorities");command(w,"Restore asynchronous V2");phase+=1
		elif phase==8 and elapsed>=1020 and e.predictive._worker!=null and e.predictive._worker.busy():
			var saved:=Snapshot.capture(w);var restored:=Snapshot.restore(saved)
			check(restored.ok,"Busy-worker save could not restore")
			if not restored.ok:break
			check(var_to_bytes(saved)==var_to_bytes(Snapshot.capture(restored.world)),"Busy-worker checkpoint round trip changed state")
			e.predictive._worker.close();w=restored.world;e=w.dispatcher();restored_pending=true
			check(e.predictive.asynchronous and e.predictive._worker==null,"Restored save retained worker handles")
			command(w,"Save/reload while forecast group is pending");phase+=1
		w.step(.5)
		peak=maxi(peak,w.active_trains().size())
		for t: Train in w.active_trains():
			if not observed.has(t.id):newcomers[t.id]=true;observed[t.id]=true
			if t.timetable!=null:check(not t.timetable.missed_stop,"Missed call for "+t.id)
		var plans: Dictionary=e.predictive.plans
		plan_samples+=plans.size()
		for p: Dictionary in plans.values():
			if p.time!=last_job:accepted_jobs+=1;last_job=p.time
		for id in e.predictive.metrics.get("worker_threads",[]):
			if id not in threads:threads.append(id)
		OS.delay_msec(1) # Yield to real workers; this is not a throughput benchmark.
	check(w.events.is_empty(),"Safety events during crowded asynchronous replay")
	check(phase==9 and restored_pending,"Not all live commands and pending-worker save were exercised")
	check(peak>=25 and not newcomers.is_empty(),"Stress run did not include busy/new traffic")
	check(plan_samples>0 and accepted_jobs>10 and not threads.is_empty(),"No sustained accepted asynchronous forecasts")
	check(OS.get_thread_caller_id() not in threads,"Forecast computation ran on the owner")
	var progress:={}
	for id: String in initial:
		progress[id]=InputData.chainage(w,w.trains[id])-initial[id]
		check(w.trains[id].service_complete or progress[id]>100,"Participant failed to progress: "+id)
	if e.predictive._worker!=null:e.predictive._worker.close();check(not e.predictive._worker.busy(),"Worker did not close")
	var report:={ok=failures.is_empty(),failures=failures,source_folder=folder,checkpoint=checkpoint,checkpoint_sha256=FileAccess.get_sha256(path),
		clock=w.clock_seconds(),services=w.trains.size(),peak_active=peak,new_entries=newcomers.keys(),accepted_jobs=accepted_jobs,plan_samples=plan_samples,
		worker_threads=threads,commands=commands,progress_m=progress,events=w.events,pending_save_restored=restored_pending,
		wall_seconds=(Time.get_ticks_msec()-wall)*.001,limitation="Functional stress under concurrent development jobs, not target-PC performance or full-day certification"}
	FileAccess.open(output,FileAccess.WRITE).store_string(JSON.stringify(report,"\t"))
	print("BUSY_ASYNC ok=%s peak=%d entries=%d jobs=%d" % [report.ok,peak,newcomers.size(),accepted_jobs]);quit(0 if report.ok else 1)

func command(w: RailWorld,label: String) -> void:
	commands.append({clock=w.clock_seconds(),action=label});print(w.clock_text()," ",label)
