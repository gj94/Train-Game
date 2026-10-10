extends SceneTree
## 60 wall seconds per strategy, sequentially, from the SAME all-AI checkpoint.
## Headless UI-frame scheduling comparison, not a GPU or target-laptop benchmark.
## godot --headless --path . --script res://tools/benchmark_time_skip.gd -- --seconds=60 --output=res://.local/threaded-skip.json
const Snapshot := preload("res://sim/world_snapshot.gd")
const Advance := preload("res://sim/time_skip.gd")
const Worker := preload("res://sim/time_skip_worker.gd")
var seconds:=60.0
var output:="res://.local/threaded-skip.json"

func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--seconds="):seconds=float(arg.trim_prefix("--seconds="))
		if arg.begins_with("--output="):output=arg.trim_prefix("--output=")
	call_deferred("run")

func restore(state: Dictionary) -> RailWorld:
	var result: Dictionary=Snapshot.restore(state)
	assert(result.ok,"Checkpoint restore failed")
	return result.world

func summary(w: RailWorld) -> Dictionary:
	var arrivals:=0
	for t in w.trains.values():
		var tt=t.completed_timetable if t.completed_timetable!=null else t.timetable
		if tt!=null:
			for arrival in tt.actual_arrivals:
				if arrival>=0:arrivals+=1
	return {clock=w.clock_text(),active=w.active_trains().size(),recorded_arrivals=arrivals,events=w.events.duplicate(true)}

func run() -> void:
	OS.low_processor_usage_mode=false
	var world: RailWorld=preload("res://sim/layouts/kerala_coast.gd").build_traffic(true)
	var warm:=Advance.new(world);warm.to_time(world.clock_seconds()+3600)
	# Warm-up is outside all measurements; identical to the prior isolated profile.
	for i in 1800:
		world.step(2)
		if (i+1)%300==0:print("WARM ",world.clock_text())
	var checkpoint: Dictionary=Snapshot.capture(world)
	var results:={engine=Engine.get_version_info().string,cpu=OS.get_processor_name(),logical_processors=OS.get_processor_count(),wall_budget_seconds=seconds,
		method="Same restored all-AI 09:00 100-service state; unchanged 0.2 s skip batches / 0.05 s physics; sequential modes. Headless frame-budget emulation, not rendered UI.",start=summary(world),runs=[]}
	for mode in ["original_60fps","threaded_60fps","original_uncapped"]:
		world=restore(checkpoint)
		var advance:=Advance.new(world);advance.to_time(world.clock_seconds()+86400)
		var start_clock:=world.clock_seconds()
		Engine.max_fps=0 if mode=="original_uncapped" else 60
		await process_frame
		var worker=Worker.new() if mode=="threaded_60fps" else null
		var frames:=0;var max_frame_usec:=0;var frame_times: Array[int]=[]
		var began:=Time.get_ticks_usec();var previous:=began
		var deadline:=began+int(seconds*1000000)
		print("BENCH START ",mode)
		if worker!=null:assert(worker.start(advance)==OK)
		while Time.get_ticks_usec()<deadline:
			if worker==null:
				var budget:=mini(deadline,Time.get_ticks_usec()+12000)
				while Time.get_ticks_usec()<budget and not advance.done:advance.step()
				if advance.done:break
			else:
				var status: Dictionary=worker.progress()
				if status.done:break
			await process_frame
			var now:=Time.get_ticks_usec()
			var frame_usec:=now-previous
			max_frame_usec=maxi(max_frame_usec,frame_usec);frame_times.append(frame_usec)
			previous=now;frames+=1
		var stop_requested:=Time.get_ticks_usec()
		if worker!=null:
			worker.request_cancel()
			while true:
				var result: Dictionary=worker.take()
				if not result.is_empty():advance=result.trial;break
				await process_frame
		else:advance.cancel()
		var finished:=Time.get_ticks_usec()
		var elapsed: float=(finished-began)/1000000.0
		var simulated: float=world.clock_seconds()-start_clock
		frame_times.sort()
		var record: Dictionary=summary(world)
		record.merge({mode=mode,wall_seconds=elapsed,simulated_seconds=simulated,speedup=simulated/elapsed,frames=frames,mean_fps=frames/elapsed,
			p95_frame_ms=frame_times[mini(frame_times.size()-1,int(frame_times.size()*.95))]/1000.0,max_frame_ms=max_frame_usec/1000.0,cancel_ms=(finished-stop_requested)/1000.0})
		results.runs.append(record)
		print("BENCH RESULT ",JSON.stringify(record))
		FileAccess.open(output,FileAccess.WRITE).store_string(JSON.stringify(results,"\t"))
	# Equal-duration replay checks ALL snapshot fields, not just distance or speed.
	Engine.max_fps=0
	var expected:={};var equal:=false
	for mode in ["serial","threaded"]:
		world=restore(checkpoint)
		var advance:=Advance.new(world);advance.to_time(world.clock_seconds()+600)
		if mode=="serial":
			while not advance.done:advance.step()
		else:
			var worker:=Worker.new();assert(worker.start(advance)==OK)
			while worker.take().is_empty():await process_frame
		var state: Dictionary=Snapshot.capture(world)
		if mode=="serial":expected=state
		else:equal=state==expected
		print("EQUIVALENCE ",mode," ",world.clock_text())
	results.equivalence={simulated_seconds=600,all_snapshot_fields_equal=equal,end=summary(world)}
	FileAccess.open(output,FileAccess.WRITE).store_string(JSON.stringify(results,"\t"))
	print("BENCH COMPLETE equal=",equal," output=",output)
	quit(0 if equal else 1)
