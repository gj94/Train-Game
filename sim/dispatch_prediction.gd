extends RefCounted
## Bounded running-time estimates, in simulation seconds. No rendering or wall clock.

static func travel_seconds(distance: float, speed: float, limit: float, accel: float) -> float:
	if not is_finite(distance): return INF
	if distance <= 0: return 0.0
	var v := maxf(1.0, limit)
	var initial := clampf(speed, 0.0, v)
	var a := maxf(.08, accel * .65)
	var ramp := (v * v - initial * initial) / (2 * a)
	if distance <= ramp: return (sqrt(initial * initial + 2 * a * distance) - initial) / a
	return (v - initial) / a + (distance - ramp) / v

static func chainage(w, t: Train) -> float:
	var e: Dictionary = w.graph.edges[t.path[0].edge]
	if e.has("chainage_start"):
		return lerpf(e.chainage_start, e.chainage_end, t.head_s / e.length)
	return w.graph.position(t.path[0].edge, t.head_s).x

static func arrival_seconds(w, t: Train, target: float) -> float:
	var at := chainage(w, t)
	var direction: int = t.path[0].dir
	var distance := (target - at) * direction
	if distance < -t.length - 500: return INF
	if absf(target - at) < 500: return 0.0
	var limit := minf(90.0 / 3.6, t.max_speed)
	var seconds := travel_seconds(maxf(0, distance), t.speed, limit, t.max_accel)
	var tt = t.timetable
	if tt == null: return seconds
	if tt.at_stop: seconds += maxf(0, tt.release_time() - w.clock_seconds())
	# Include intervening passenger calls; a distant fast train which is still
	# serving several stops must not be treated as a non-stop express.
	for i in range(tt.index + (1 if tt.at_stop else 0), tt.stops.size()):
		var stop: Dictionary = tt.stops[i]
		var e: Dictionary = w.graph.edges[stop.block]
		var s: float = lerpf(e.get("chainage_start", 0), e.get("chainage_end", 0), stop.s / e.length)
		if (target - s) * direction <= 500: break
		if (s - at) * direction <= 100: continue
		seconds += stop.dwell_minutes * 60 + limit / maxf(.1, t.max_accel) * .5 + limit / maxf(.1, t.service_decel) * .5
	return seconds

static func next_call(w, t: Train) -> Dictionary:
	if t.timetable == null or t.timetable.complete(): return {}
	var tt = t.timetable
	var index: int = mini(tt.index + (1 if tt.at_stop else 0), tt.stops.size() - 1)
	var stop: Dictionary = tt.stops[index]
	var distance: float = w._stop_distance(t.path[0].edge, t.path[0].dir, t.head_s, stop, [])
	var seconds := travel_seconds(distance, t.speed, minf(t.max_speed, 90.0 / 3.6), t.max_accel)
	if tt.at_stop: seconds += maxf(0, tt.release_time() - w.clock_seconds())
	return {name=stop.name, block=stop.block, index=index, distance=distance,
		arrival=w.clock_seconds()+seconds, booked=tt.planned_arrival(index),
		delay=maxf(0, w.clock_seconds()+seconds-tt.planned_arrival(index)),
		qualified=true, missed=tt.missed_stop}
