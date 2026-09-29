extends RefCounted
## One scheduled working. Offsets always reference the PLANNED origin time.
## A stop is acknowledged only at a stand in its block at its stopping marker.
const Clock := preload("res://sim/world_clock.gd")

var departure := 0.0
var stops: Array = []
var index := 0
var at_stop := true
var actual_arrivals: Array[float] = []
var actual_departures: Array[float] = []
var missed_stop := false

func configure(definition: Dictionary, world, train: Train) -> Dictionary:
	var value = definition.get("departure", "")
	if not value is String:
		return _error("Departure must be a 24-hour HH:MM or HH:MM:SS time")
	var parsed := Clock.parse_time(value)
	var day_value = definition.get("day", 1)
	if parsed < 0 or not _number(day_value) or float(day_value) < 1 or float(day_value) != floorf(float(day_value)):
		return _error("Invalid departure time or day (day 1 is the first world day)")
	departure = (int(day_value) - 1) * Clock.DAY + parsed
	var entries = definition.get("stops", [])
	if not entries is Array or entries.size() < 2:
		return _error("A timetable needs an origin and at least one destination stop")
	var previous_departure := -1.0
	for i in entries.size():
		var raw = entries[i]
		if not raw is Dictionary:
			return _error("Each stop must be an object")
		var block = raw.get("block", "")
		var offset = raw.get("minutes_from_origin", -1)
		var dwell = raw.get("dwell_minutes", 1.0 if i > 0 and i < entries.size() - 1 else 0.0)
		var dir = raw.get("direction", train.path[0].dir)
		if not block is String or not world.graph.edges.has(block):
			return _error("Unknown stop block: " + str(block))
		if not _number(offset) or not _number(dwell) or float(offset) < 0 or float(dwell) < 0:
			return _error("Stop and dwell minutes must be finite non-negative numbers")
		if not _number(dir) or float(dir) not in [-1.0, 1.0]:
			return _error("Stop direction must be +1 or -1")
		if (i == 0 and float(offset) != 0) or (i > 0 and float(offset) <= stops[-1].minutes_from_origin) or float(offset) < previous_departure:
			return _error("Origin must be +0 min; later stops must follow prior stops and dwell times")
		if i == 0 and (block != train.path[0].edge or int(dir) != train.path[0].dir):
			return _error("Origin block and direction must match the placed train")
		var position: float = world.graph.exit_s(block, dir) - dir * 7.0
		for sig in world.signals.values():
			if sig.edge == block and sig.dir == dir:
				position = sig.s - dir * 6.0
		if raw.has("position_m"):
			if not _number(raw.position_m):
				return _error("Stopping position must be a finite number")
			position = float(raw.position_m)
		var length: float = world.graph.edges[block].length
		if position < 0 or position > length or absf(position - world.graph.entry_s(block, dir)) < train.length:
			return _error("Stop marker cannot hold the full train in block " + block)
		stops.append({block = block, name = str(raw.get("name", block)), direction = int(dir), s = position,
			minutes_from_origin = float(offset), dwell_minutes = float(dwell) if i > 0 else 0.0})
		previous_departure = float(offset) + stops[-1].dwell_minutes
		actual_arrivals.append(-1.0)
		actual_departures.append(-1.0)
	return {ok = true, reason = ""}

static func _number(value) -> bool:
	return (value is int or value is float) and is_finite(float(value))

func _error(reason: String) -> Dictionary:
	return {ok = false, reason = reason}

func planned_arrival(i: int) -> float:
	return departure + stops[i].minutes_from_origin * 60.0

func planned_departure(i: int) -> float:
	return planned_arrival(i) + stops[i].dwell_minutes * 60.0

func release_time() -> float:
	if index == 0:
		return departure
	return maxf(planned_departure(index), actual_arrivals[index] + stops[index].dwell_minutes * 60.0)

func complete() -> bool:
	return at_stop and index == stops.size() - 1

func stop_ahead() -> Dictionary:
	return stops[mini(index + 1, stops.size() - 1)] if at_stop else stops[index]

func observe(train: Train, now: float, moved: bool) -> void:
	if complete():
		return
	if at_stop and moved:
		actual_departures[index] = now
		index += 1
		at_stop = false
		missed_stop = false
	if at_stop:
		return
	var stop: Dictionary = stops[index]
	if train.path[0].edge != stop.block or train.path[0].dir != stop.direction:
		return
	var ahead: float = (stop.s - train.head_s) * stop.direction
	if absf(ahead) <= 1.1 and train.speed <= 0.001:
		actual_arrivals[index] = now
		at_stop = true
		missed_stop = false
	elif ahead < -1.1:
		missed_stop = true

func row_status(i: int, now: float) -> String:
	if actual_departures[i] >= 0:
		return "Departed " + _deviation(actual_departures[i] - planned_departure(i))
	if actual_arrivals[i] >= 0:
		if i < stops.size() - 1 and now > planned_departure(i) + 1.0:
			return "Held " + _deviation(now - planned_departure(i))
		return ("Arrived " if i == stops.size() - 1 else "At stop ") + _deviation(actual_arrivals[i] - planned_arrival(i))
	if i == index and missed_stop:
		return "MISSED STOP"
	var due := planned_departure(i) if i == 0 else planned_arrival(i)
	return "Overdue " + _deviation(now - due) if now > due + 1.0 else "Scheduled"

func _deviation(seconds: float) -> String:
	if absf(seconds) < 1.0:
		return "on time"
	return "%+.1f min" % (seconds / 60.0)
