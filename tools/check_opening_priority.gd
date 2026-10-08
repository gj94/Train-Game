extends SceneTree
## A/B experiment only: keep the published timetable unchanged, swap K1/K2
## before any authority is issued, and use identical AI driving in both worlds.
const Kerala := preload("res://sim/layouts/kerala_coast.gd")
const Policy := preload("res://sim/priority_dispatch.gd")
const Clock := preload("res://sim/world_clock.gd")
const WATCH := ["K1", "K2", "K3"]

func _init() -> void:
	if "--vacancy" in OS.get_cmdline_user_args():
		_vacancy_probe()
		return
	var results: Array = []
	for swap in [false, true]:
		results.append(_rehearse(swap))
	var output := "res://.local/opening-priority-results.json"
	var file := FileAccess.open(output, FileAccess.WRITE)
	file.store_string(JSON.stringify(results, "\t"))
	print("PRIORITY_RESULTS ", JSON.stringify(results))
	quit(0 if results.all(func(r): return r.cleared_opening and r.safety_events.is_empty() and r.circular_seconds == 0) else 1)

func _rehearse(swap: bool) -> Dictionary:
	var w := Kerala.build_traffic()
	if swap:
		var old: int = w.trains.K1.dispatch_priority
		w.trains.K1.dispatch_priority = w.trains.K2.dispatch_priority
		w.trains.K2.dispatch_priority = old
	var engine = w.dispatcher()
	engine.enabled = true
	engine.run_cycle(true)
	var result := {variant="swapped" if swap else "baseline", priorities={}, initial={}, first_clear={}, origin_exit={}, calls={}, circular_seconds=0.0, first_cycle={}, safety_events=[], cleared_opening=false}
	var origins := {}
	var starts := {}
	for id in WATCH:
		var t: Train = w.trains[id]
		result.priorities[id] = t.dispatch_priority
		origins[id] = t.path[0].edge
		starts[id] = w.next_signal(t).id
		var state: Dictionary = engine.states[id]
		result.initial[id] = {status=state.status, reason=state.reason}
		if w.aspect(starts[id]) != RailWorld.Aspect.RED: result.first_clear[id] = w.clock_text()
	print("PRIORITY_START ", JSON.stringify({variant=result.variant, priorities=result.priorities, decisions=result.initial}))
	var tuvr := 0.0
	for station in w.stations:
		if station.code == "TUVR": tuvr = station.s
	var next_log := 600.0
	while w.time < 7200 and w.events.is_empty():
		w.step(2.0)
		for id in WATCH:
			if not result.first_clear.has(id) and w.aspect(starts[id]) != RailWorld.Aspect.RED:
				result.first_clear[id] = w.clock_text()
			if not result.origin_exit.has(id) and w.trains[id].path[0].edge != origins[id]:
				result.origin_exit[id] = w.clock_text()
		if engine.alerts.any(func(a): return a.get("kind", "") == "conflict"):
			result.circular_seconds += 2.0
			if result.first_cycle.is_empty():
				result.first_cycle = {time=w.clock_text(), alerts=engine.alerts.duplicate(true)}
		if w.time >= next_log:
			print("PRIORITY_PROGRESS ", JSON.stringify({variant=result.variant, time=w.clock_text(), trains=WATCH.map(func(id): return [id,w.trains[id].path[0].edge,w.trains[id].status])}))
			next_log += 600.0
		if w.trains.K2.service_complete and Policy.chainage(w,w.trains.K1) > tuvr+1000 and Policy.chainage(w,w.trains.K3) > tuvr+1000:
			result.cleared_opening = true
			break
	result.end_time = w.clock_text()
	result.safety_events = w.events.duplicate(true)
	for id in WATCH:
		var tt = w.trains[id].timetable
		var calls: Array = []
		for i in tt.stops.size():
			if tt.actual_arrivals[i] < 0 and tt.actual_departures[i] < 0: continue
			calls.append({station=tt.stops[i].name, road=tt.stops[i].block,
				arrival=Clock.format_time(tt.actual_arrivals[i]) if tt.actual_arrivals[i]>=0 else "",
				departure=Clock.format_time(tt.actual_departures[i]) if tt.actual_departures[i]>=0 else ""})
		result.calls[id] = calls
	print("PRIORITY_FINISHED ", JSON.stringify({variant=result.variant, time=result.end_time, cleared=result.cleared_opening, circular_seconds=result.circular_seconds, events=result.safety_events}))
	return result

func _vacancy_probe() -> void:
	var w := Kerala.build_traffic()
	w.dispatcher().enabled = true
	w.dispatcher().run_cycle(true)
	var result := {sampling_seconds=2, events={}}
	while w.time < 1500 and w.events.is_empty():
		w.step(2.0)
		var vb: Train = w.trains.K3
		if not result.events.has("vb_head_left_platform") and vb.path[0].edge != "KUMM_P3":
			result.events.vb_head_left_platform = w.clock_text()
		if not result.events.has("vb_tail_left_platform") and not vb.path.any(func(p): return p.edge == "KUMM_P3"):
			result.events.vb_tail_left_platform = w.clock_text()
			result.k2_at_vacancy = {edge=w.trains.K2.path[0].edge, status=w.trains.K2.status}
			result.k1_at_vacancy = w.dispatcher().states.K1.reason
		if not result.events.has("ers_signal_cleared") and w.aspect("ERS-S1") != RailWorld.Aspect.RED:
			result.events.ers_signal_cleared = w.clock_text()
		if result.events.size() == 3: break
	result.safety_events = w.events.duplicate(true)
	FileAccess.open("res://.local/opening-vacancy-results.json",FileAccess.WRITE).store_string(JSON.stringify(result,"\t"))
	print("VACANCY_RESULT ", JSON.stringify(result))
	quit(0 if result.events.size() == 3 and w.events.is_empty() else 1)
