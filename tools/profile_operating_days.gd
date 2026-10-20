extends SceneTree
## Sequential CPU-only sampling from the two prepared midday railways.
## No renderer: never interpret these results as frame rates on the playing PC.
const Days:=preload("res://persistence/operating_days.gd")
const Times:=preload("res://persistence/railway_times.gd")
func _initialize() -> void:call_deferred("run")
func percentile(samples: Array, p: float) -> float:
	return samples[clampi(ceili(p*samples.size())-1,0,samples.size()-1)]*.001
func run() -> void:
	var results:={cpu=OS.get_processor_name(),engine=Engine.get_version_info().string,
		method="Two all-AI 12:05 prepared railways, sequential, 120 simulated seconds at 60 simulation calls/second after one-second warm-up. Pure CPU, no rendering.",runs=[]}
	for day in Days.DAYS:
		var catalogue:=Times.catalogue(day.times)
		if not catalogue.ok:printerr(catalogue.reason);quit(1);return
		var rows: Array=catalogue.data.states.filter(func(r):return int(r.clock)==43500)
		if rows.size()!=1:printerr("Missing 12:05 state");quit(1);return
		var loaded:=Times.load_state(rows[0],day.times)
		if not loaded.ok:printerr(loaded.reason);quit(1);return
		var w: RailWorld=loaded.world
		for t: Train in w.trains.values():t.automatic=true
		w.dispatcher().manual_service=""
		for _i in 60:w.step(1.0/60)
		var active:=w.active_trains().size()
		var samples: Array=[]
		w.profile_enabled=true
		var began:=Time.get_ticks_usec()
		for _i in 7200:
			var tick:=Time.get_ticks_usec()
			w.step(1.0/60)
			samples.append(Time.get_ticks_usec()-tick)
		var elapsed:=(Time.get_ticks_usec()-began)*.000001
		samples.sort()
		results.runs.append({day=day.id,services=w.trains.size(),initial_active=active,source_sha256=rows[0].sha256,
			simulation_seconds=120,wall_seconds=elapsed,step_median_ms=percentile(samples,.5),step_p95_ms=percentile(samples,.95),
			step_p99_ms=percentile(samples,.99),step_max_ms=percentile(samples,1),phases_usec=w.profile_usec,events=w.events})
	FileAccess.open("res://.local/operating-days-profile.json",FileAccess.WRITE).store_string(JSON.stringify(results,"\t"))
	print(JSON.stringify(results))
	quit(0 if results.runs.all(func(r):return r.events.is_empty()) else 1)
