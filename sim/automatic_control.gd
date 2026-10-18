extends RefCounted
## Continuous, predictive driving with a saved, monotone station approach.
## Authority/stop selection belongs to RailWorld; this never clears a signal.
const COMFORT_FRACTION := .45
const RESPONSE_SECONDS := 2.0
const ANTICIPATION_SECONDS := 4.0
const HANDLE_RATE := .35 # full handle units per simulated second
const LIMIT_MARGIN := .4 # m/s below the line/equipment limit

static func horizon(t: Train, line_limit: float) -> float:
	var speed := maxf(t.speed, minf(t.max_speed, line_limit))
	return maxf(1000.0, speed * speed / (2.0 * t.service_decel * COMFORT_FRACTION) + speed * ANTICIPATION_SECONDS + 100.0)

static func curve(t: Train, distance: float, end_speed: float) -> float:
	# Allow time to release traction and build the brake before the restriction.
	var usable := maxf(0.0, distance - t.speed * ANTICIPATION_SECONDS)
	return sqrt(end_speed * end_speed + 2.0 * t.service_decel * COMFORT_FRACTION * usable)

static func urgent(t: Train, distance: float, end_speed: float) -> bool:
	# A newly lost authority/late takeover must not wait for the comfort ramp.
	var required := maxf(0.0, t.speed * t.speed - end_speed * end_speed)
	return required > 2.0 * t.service_decel * .8 * maxf(.01, distance)

## Geometry/speed-only work: safe to evaluate for different trains concurrently
## while the simulation owner holds the railway at a physics-slice barrier.
static func speed_envelope(w, t: Train) -> Dictionary:
	var line_limit: float = w.speed_limit_for(t)
	var target := maxf(0.0, minf(line_limit, t.max_speed) - LIMIT_MARGIN)
	var must_brake := false
	var lookahead := horizon(t, line_limit)
	var cur: Dictionary = t.path[0]
	var distance: float = absf(w.graph.exit_s(cur.edge, cur.dir) - t.head_s)
	var visited := {}
	while distance <= lookahead:
		var nxt: Dictionary = w.graph.next(cur.edge, cur.dir)
		if nxt.is_empty(): break
		var key: String = nxt.edge + "|" + str(nxt.dir)
		if visited.has(key): break
		visited[key] = true
		var posted_limit: float = w.graph.edges[nxt.edge].speed_limit
		var limit := maxf(0.0, posted_limit - LIMIT_MARGIN)
		var before_board := maxf(0.0, distance - 12.0)
		target = minf(target, curve(t, before_board, limit))
		must_brake = must_brake or urgent(t, distance, posted_limit)
		cur = nxt
		distance += w.graph.edges[cur.edge].length
	return {target=target,must_brake=must_brake,horizon=lookahead}

static func station_curve(t: Train, distance: float) -> float:
	# Partial service braking followed by a gentler final walking-speed stop.
	# This is an authored comfort profile, not an emergency braking curve.
	var comfort := t.service_decel * COMFORT_FRACTION
	var final_decel := minf(.18, comfort)
	var final_speed := 2.5
	var final_distance := final_speed * final_speed / (2 * final_decel)
	var usable := maxf(0, distance - .35 - t.speed * 1.6)
	return sqrt(2 * final_decel * usable) if usable < final_distance else sqrt(final_speed * final_speed + 2 * comfort * (usable - final_distance))

static func arrival_target(t: Train, distance: float, zone: float, target: float) -> float:
	if t.timetable == null or t.timetable.at_stop or not is_finite(distance):
		t.station_approach.clear()
		return target
	var stop: Dictionary = t.timetable.stop_ahead()
	var key := "%d:%s:%d" % [t.timetable.index, stop.block, stop.direction]
	if t.station_approach.get("key", "") != key: t.station_approach.clear()
	if distance <= zone and t.station_approach.is_empty() and t.speed>2.5 and (t.controller < -.015 or t.path[0].edge == stop.block):
		t.station_approach = {key=key, ceiling=maxf(2.0,t.speed)}
	if not t.station_approach.is_empty():
		# A complete stand short of the berth ends the uninterrupted arrival.
		# Restart under the same station/signal curves, then latch again when
		# braking resumes. Never crawl hundreds of metres on a stale ceiling.
		if t.speed<.08 and distance>60:
			t.station_approach.restarting=true
			t.station_approach.ceiling=t.max_speed
		if t.station_approach.get("restarting",false):
			if t.speed>2.5 and t.controller<-.015:
				t.station_approach.erase("restarting")
				t.station_approach.ceiling=t.speed
		else:
			t.station_approach.ceiling=minf(t.station_approach.ceiling,maxf(2.0,t.speed))
			target=minf(target,t.station_approach.ceiling)
	return minf(target,station_curve(t,distance))

static func drive(w, t: Train, stop_at: float, dt: float, prepared: Dictionary={}, station_distance: float=INF, station_zone: float=0.0) -> void:
	var envelope:=speed_envelope(w,t) if prepared.is_empty() else prepared
	var station_is_nearest := is_finite(station_distance) and absf(stop_at-station_distance)<.01
	var target:=minf(envelope.target,station_curve(t,stop_at) if station_is_nearest else curve(t,stop_at,0.0))
	target=arrival_target(t,station_distance,station_zone,target)
	var must_brake: bool=envelope.must_brake or urgent(t,stop_at,0.0)
	if must_brake or (stop_at < .7 and t.speed < .08):
		t.controller = -1.0
		return
	if stop_at < .7: target = 0.0
	# Compensate running resistance: a steady speed needs steady low power,
	# rather than alternating traction and coast around a discontinuous threshold.
	var acceleration := (target - t.speed) / RESPONSE_SECONDS
	var effort := acceleration + t.running_resistance()
	var request := 0.0
	if effort >= 0:
		request = clampf(effort / maxf(.001, t.traction_acceleration()), 0.0, 1.0)
	else:
		request = clampf(effort / t.service_decel, -1.0, 0.0)
	# Release the stationary holding brake before ramping traction. Spending
	# seconds traversing negative handle values at a stand delays booked starts.
	if t.speed == 0.0 and t.controller < 0.0 and request > 0.0:
		t.controller = 0.0
	t.controller = move_toward(t.controller, request, HANDLE_RATE * dt)
