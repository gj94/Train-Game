extends RefCounted
## Incremental rehearsal on an isolated simulation. GUI decides its time budget.
var world: RailWorld
var done := false
var ok := false
var report := ""
var deadline := 0.0
var ticks := 0

func _init(w: RailWorld) -> void:
	world = w
	world.dispatcher().enabled=true
	deadline = w.clock_start
	for train in world.trains.values():
		deadline = maxf(deadline,train.timetable.planned_arrival(train.timetable.stops.size()-1))
	deadline += 7200.0

func step() -> void:
	if done: return
	world.step(2.0)
	ticks += 1
	if not world.events.is_empty():
		done = true
		report = "Traffic check stopped: " + str(world.events[0].text)
	elif world.trains.values().all(func(t): return t.service_complete):
		done = true
		ok = true
		var late := 0.0
		for train in world.trains.values():
			var schedule = train.timetable
			late = maxf(late,schedule.actual_arrivals[-1]-schedule.planned_arrival(schedule.stops.size()-1))
		report = "All %d services arrived safely. Latest arrival delay: %.1f min. Manual driving may change the outcome." % [world.trains.size(),late/60]
	elif world.clock_seconds() > deadline:
		done = true
		var held: Array[String] = []
		for train in world.trains.values():
			if not train.service_complete: held.append(train.id + " at " + train.path[0].edge)
		report = "Traffic did not finish within two hours of the last booked arrival: " + ", ".join(held) + ". Check occupied destination platforms and conflicting schedules."
