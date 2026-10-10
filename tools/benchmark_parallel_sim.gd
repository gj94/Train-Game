extends SceneTree
## Compare the SAME railway on one thread and 2/4/8 simulation pool threads.
## All modes are uncapped and rendering-free. Preparation time is included.
const Snapshot := preload("res://sim/world_snapshot.gd")
const Advance := preload("res://sim/time_skip.gd")
var wall_seconds:=60.0
var sim_seconds:=0.0
var modes:=[0,1,2,4,8]
var output:="res://.local/parallel-sim.json"
const CHECKPOINT:="res://.local/parallel-sim-checkpoint.bin"

func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--seconds="):wall_seconds=float(arg.trim_prefix("--seconds="))
		if arg.begins_with("--sim-seconds="):sim_seconds=float(arg.trim_prefix("--sim-seconds="))
		if arg.begins_with("--output="):output=arg.trim_prefix("--output=")
		if arg.begins_with("--workers="):
			modes.clear()
			for n in arg.trim_prefix("--workers=").split(","):modes.append(int(n))
	call_deferred("run")

func run() -> void:
	var checkpoint: Dictionary
	if FileAccess.file_exists(CHECKPOINT):
		checkpoint=FileAccess.open(CHECKPOINT,FileAccess.READ).get_var()
	else:
		var w: RailWorld=preload("res://sim/layouts/kerala_coast.gd").build_traffic(true)
		w.simulation_workers=0
		var ai:=Advance.new(w);ai.to_time(w.clock_seconds()+3600)
		for i in 1800:
			w.step(2)
			if (i+1)%300==0:print("WARM ",w.clock_text())
		checkpoint=Snapshot.capture(w)
		FileAccess.open(CHECKPOINT,FileAccess.WRITE).store_var(checkpoint)
	var report:={cpu=OS.get_processor_name(),logical_processors=OS.get_processor_count(),engine=Engine.get_version_info().string,
		wall_budget=wall_seconds,sim_budget=sim_seconds,checkpoint_sha256=FileAccess.get_sha256(CHECKPOINT),runs=[]}
	var expected:={};var reference_workers: int=modes[0]
	for count: int in modes:
		var restored: Dictionary=Snapshot.restore(checkpoint)
		assert(restored.ok,"Checkpoint restore failed")
		var w: RailWorld=restored.world
		w.simulation_workers=count
		# Sample worker identities only during a common unmeasured 0.2 s prefix.
		w.trace_parallel=true
		var advance:=Advance.new(w)
		var request:=advance.to_time(w.clock_seconds()+minf(86400,(sim_seconds if sim_seconds>0 else 86399)+.2))
		if not request.ok:push_error(request.reason);quit(1);return
		advance.step();w.trace_parallel=false
		var start_clock:=w.clock_seconds()
		var began:=Time.get_ticks_usec()
		print("BENCH START workers=",count)
		while not advance.done and (sim_seconds>0 or Time.get_ticks_usec()-began<int(wall_seconds*1000000)):
			advance.step()
		var elapsed: float=(Time.get_ticks_usec()-began)/1000000.0
		var progressed:=w.clock_seconds()-start_clock
		var same:=true
		if sim_seconds>0:
			var state: Dictionary=Snapshot.capture(w)
			if count==reference_workers:expected=state
			else:same=state==expected
		var result:={workers=count,wall_seconds=elapsed,simulated_seconds=progressed,speedup=progressed/elapsed,
			clock=w.clock_text(),active=w.active_trains().size(),events=w.events,same_state=same if sim_seconds>0 else null,
			pool_thread_ids=w.parallel_threads.keys(),parallel_batches=w.parallel_batches}
		report.runs.append(result)
		print("BENCH RESULT ",JSON.stringify(result))
		FileAccess.open(output,FileAccess.WRITE).store_string(JSON.stringify(report,"\t"))
		if not same or not w.events.is_empty() or progressed<=0:quit(1);return
	quit()
