extends RefCounted
## Incremental rehearsal on an isolated simulation. GUI decides its time budget.
var world: RailWorld
var done := false
var ok := false
var report := ""
var deadline := 0.0
var ticks := 0
var _last_progress := 0.0
var _next_stall_check := 0.0

func _init(w: RailWorld) -> void:
	world = w
	_last_progress = w.time
	world.dispatcher().enabled=true
	deadline = w.clock_start
	for train in world.trains.values():
		deadline = maxf(deadline,train.timetable.planned_arrival(train.timetable.stops.size()-1))
	deadline += 7200.0

func step(simulation_seconds: float = 2.0) -> void:
	if done: return
	world.step(simulation_seconds)
	ticks += 1
	if not world.events.is_empty():
		done = true
		report = "Traffic check stopped: " + str(world.events[0].text)
	elif world.trains.values().all(func(t): return preload("res://sim/depot_workings.gd").finished(world,t)):
		done = true
		ok = true
		var late := 0.0
		for train in world.trains.values():
			var schedule = train.completed_timetable if train.completed_timetable!=null else train.timetable
			late = maxf(late,schedule.actual_arrivals[-1]-schedule.planned_arrival(schedule.stops.size()-1))
		report = "All %d services arrived safely and cleared to depot where provided. Latest passenger arrival delay: %.1f min. Manual driving may change the outcome." % [world.trains.size(),late/60]
	elif _stalled():
		done = true
		report = "Traffic did not finish: no train moved for five simulated minutes, and no booked departure, passenger exchange or depot release explains the wait. Check the dispatch blockers."
	elif world.clock_seconds() > deadline:
		done = true
		var held: Array[String] = []
		for train in world.trains.values():
			if not preload("res://sim/depot_workings.gd").finished(world,train): held.append(train.id + " at " + train.path[0].edge)
		report = "Traffic did not finish within two hours of the last booked arrival: " + ", ".join(held) + ". Check occupied destination platforms and conflicting schedules."

func _stalled() -> bool:
	if world.time < _next_stall_check:return false
	_next_stall_check=world.time+2.0
	# A distant booked departure is a legitimate pause, not a deadlock. Manual
	# or operator-held services can resume by user action and are not diagnosed.
	for t: Train in world.trains.values():
		if t.lifecycle=="stored":continue
		if t.lifecycle=="scheduled" and t.timetable.departure>world.clock_seconds():
			_last_progress=world.time;return false
		if t.lifecycle!="active":continue
		if t.speed>.001 or not t.automatic or world.dispatcher().operator_holds.has(t.id):
			_last_progress=world.time;return false
		if t.timetable!=null and not t.service_complete and t.timetable.at_stop and t.timetable.release_time()>world.clock_seconds():
			_last_progress=world.time;return false
		if preload("res://sim/passenger_service.gd").departure_blocked(t) or t.depot.get("release",0)>world.clock_seconds():
			_last_progress=world.time;return false
	return world.time-_last_progress>=300.0
