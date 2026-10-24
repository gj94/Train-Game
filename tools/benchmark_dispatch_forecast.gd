extends SceneTree
## Pure planning benchmark; does not step or alter the prepared railway.
const InputData:=preload("res://sim/dispatch_forecast_input.gd")
const Worker:=preload("res://sim/dispatch_forecast_worker.gd")
func _initialize() -> void:call_deferred("run")
func run() -> void:
	var file:=FileAccess.open_compressed("res://data/timetables/intensive/times/T042000.bin",FileAccess.READ,FileAccess.COMPRESSION_ZSTD)
	var restored:=preload("res://sim/world_snapshot.gd").restore(file.get_var(false));file.close();assert(restored.ok)
	var w: RailWorld=restored.world;var began:=Time.get_ticks_usec()
	var network:=InputData.topology(w);var topology_us:=Time.get_ticks_usec()-began;began=Time.get_ticks_usec()
	var frame:=InputData.frame(w);var capture_us:=Time.get_ticks_usec()-began
	var worker:=Worker.new(network);var baseline:=worker.synchronous(frame)
	var rows:=[];var consistent:=true
	for threads in [0,1,2,4]:
		for repeat in 10:
			began=Time.get_ticks_usec();var result:={};var submit_us:=0
			if threads==0:result=worker.synchronous(frame)
			else:
				worker.submit(frame,threads);submit_us=Time.get_ticks_usec()-began
				while result.is_empty():
					result=worker.take()
					if result.is_empty():OS.delay_usec(100)
			consistent=consistent and result.plans==baseline.plans
			rows.append({threads=threads,iteration=repeat,elapsed_us=Time.get_ticks_usec()-began,submit_us=submit_us,compute_cpu_us=result.cpu_usec,worker_threads=result.worker_threads})
	worker.close()
	var report:={ok=consistent,clock=frame.clock,trains=frame.trains.size(),edges=network.edges.size(),topology_us=topology_us,capture_us=capture_us,caller=OS.get_thread_caller_id(),samples=rows,plans=baseline.plans}
	DirAccess.make_dir_recursive_absolute("res://.local/dispatcher-v2-2026-10-24")
	FileAccess.open("res://.local/dispatcher-v2-2026-10-24/worker-benchmark.json",FileAccess.WRITE).store_string(JSON.stringify(report,"\t"))
	print("FORECAST BENCHMARK ",consistent," frames=",rows.size()," capture_us=",capture_us);quit(0 if consistent else 1)
