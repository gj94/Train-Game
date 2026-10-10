extends RefCounted
## Behavioural driving checks: comfort, advance restriction compliance and safety.

func straight(speeds: Array, lengths: Array) -> RailWorld:
	var w := RailWorld.new()
	var x := 0.0
	w.graph.add_node("N0", Vector3.ZERO)
	for i in speeds.size():
		x += lengths[i]
		w.graph.add_node("N" + str(i + 1), Vector3(x, 0, 0))
		w.graph.add_edge("E" + str(i), "N" + str(i), "N" + str(i + 1), [], speeds[i] / 3.6)
	return w

func train_at(w: RailWorld, edge: String, position: float, direction: int, speed: float) -> Train:
	var t := Train.new("AI", 200)
	t.max_speed = 180.0 / 3.6
	t.service_decel = .85
	t.automatic = true
	t.speed = speed / 3.6
	w.place_train(t, edge, position, direction)
	return t

func test_cruise_holds_speed_without_power_coast_chatter():
	var w := straight([90], [100000])
	var t := train_at(w, "E0", 1000, 1, 87)
	var changes := 0
	var previous := 0
	var low := INF
	var high := 0.0
	for i in 2400:
		w.step(.05)
		if i < 600: continue
		var mode := 1 if t.controller > .001 else (-1 if t.controller < -.001 else 0)
		if previous != mode: changes += 1
		previous = mode
		low = minf(low, t.speed)
		high = maxf(high, t.speed)
	if changes > 2: return "Cruise changed handle mode %d times in 90 seconds" % changes
	return high - low < .05 and low * 3.6 > 88 and high * 3.6 < 90

func restriction_run(direction: int, short_edges: bool = false):
	var speeds := []
	var lengths := []
	if short_edges:
		for i in 80:
			speeds.append(160)
			lengths.append(50)
	else:
		speeds.append(160)
		lengths.append(4000)
	var slow_edge := "E" + str(speeds.size())
	speeds.append(40); lengths.append(2000)
	speeds.append(160); lengths.append(4000)
	var w := straight(speeds, lengths)
	var start_edge := "E0" if direction > 0 else "E" + str(speeds.size() - 1)
	if short_edges: start_edge = "E4"
	var start_position := 0.0 if short_edges else (200.0 if direction > 0 else 3800.0)
	var t := train_at(w, start_edge, start_position, direction, 144)
	var first_brake := -1.0
	var strongest := 0.0
	var largest_change := 0.0
	var previous := t.controller
	var brake_releases := 0
	for i in 7000:
		w.step(.05)
		if t.path[0].edge == slow_edge:
			if t.speed > 40.0 / 3.6 + .03: return "Entered 40 km/h restriction at %.3f km/h" % (t.speed * 3.6)
			if first_brake < 1500: return "Advance braking began only %.1f m before restriction" % first_brake
			if strongest >= .85: return "Routine reduction used %.1f%% brake" % (strongest * 100)
			if largest_change > .026: return "Handle jumped %.3f in one physics slice" % largest_change
			if brake_releases > 1: return "Brake/coast cycled during the reduction"
			return true
		var left: float = 3800 - t.odometer
		if t.controller < -.02 and first_brake < 0: first_brake = left
		strongest = maxf(strongest, -t.controller)
		largest_change = maxf(largest_change, absf(t.controller - previous))
		if previous < -.001 and t.controller >= -.001 and t.speed > 40 / 3.6 + 1: brake_releases += 1
		previous = t.controller
	return "Did not reach the speed reduction"

func test_brakes_gradually_well_before_lower_limit():
	return restriction_run(1)

func test_reverse_direction_brakes_before_lower_limit():
	return restriction_run(-1)

func test_lookahead_is_not_cut_off_by_twenty_short_edges():
	return restriction_run(1, true)

func test_red_signal_stop_uses_partial_brake_and_keeps_clearance():
	var w := straight([110,110], [2500,5000])
	w.add_signal("RED", "E0", 1, 30)
	var t := train_at(w, "E0", 700, 1, 100)
	var partial := 0
	var previous := t.controller
	for i in 5000:
		w.step(.05)
		if t.speed > .3:
			if t.controller < -.99: return "Routine signal approach used full brake"
			if absf(t.controller - previous) > .026: return "Signal approach handle jumped"
		if t.controller < -.1 and t.controller > -.8: partial += 1
		previous = t.controller
		if t.speed == 0:
			var gap: float = w.signals.RED.s - t.head_s
			return partial > 100 and gap >= 6 and gap < 7.1 and not t.emergency and w.events.is_empty()
	return "Did not settle at the red signal"

func test_station_stop_is_accurate_with_gradual_braking():
	var w := straight([110,110], [3000,3000])
	var t := train_at(w, "E0", 2600, 1, 0)
	var assigned := w.set_timetable(t.id, {departure="08:00", stops=[
		{block="E0",position_m=2600,minutes_from_origin=0},
		{block="E1",position_m=1500,minutes_from_origin=3}]})
	if not assigned.ok: return assigned.reason
	t.timetable.at_stop = false
	t.timetable.index = 1
	t.speed = 100.0 / 3.6
	var partial := 0
	for i in 5000:
		w.step(.05)
		if t.speed > .3 and t.controller < -.99: return "Routine station approach used full brake"
		if t.controller < -.1 and t.controller > -.8: partial += 1
		if t.timetable.complete():
			return partial > 100 and absf(t.head_s - 1500) < 1.1 and not t.emergency and not t.timetable.missed_stop
	return "Station arrival was not acknowledged"

func test_sudden_close_red_overrides_comfort_rate():
	var w := straight([110,110], [1000,3000])
	w.add_signal("RED", "E0", 1, 30)
	var t := train_at(w, "E0", 820, 1, 54)
	t.controller = 1
	w.step(.05)
	if t.controller > -.99: return "Close danger retained power or gentle braking"
	w.step(35)
	return t.speed == 0 and t.head_s <= w.signals.RED.s - 6 and not t.emergency

func test_emergency_and_occupied_block_protection_remain_immediate():
	var w := straight([110,110], [1000,3000])
	var t := train_at(w, "E0", 980, 1, 80)
	var blocker := Train.new("BLOCKER", 100)
	w.place_train(blocker, "E1", 200, 1)
	w.protection = false
	w.step(2)
	if not t.emergency or t.occupies("E1"): return "Occupied-block protection failed"
	t.controller = 1
	w.step(.05)
	return t.controller == -1 and t.speed == 0

func test_speed_increase_waits_for_tail_to_clear_restriction():
	var w := straight([40,110], [2000,5000])
	var t := train_at(w, "E0", 1990, 1, 38.5)
	var entered := false
	for i in 1000:
		w.step(.05)
		if t.path[0].edge == "E1": entered = true
		if t.occupies("E0"):
			if t.speed > 40 / 3.6: return "Accelerated before the tail cleared"
		elif entered:
			w.step(10)
			return t.speed * 3.6 > 45
	return "Tail did not clear restriction"

func test_stationary_hold_releases_into_gradual_power():
	var w := straight([110], [10000])
	var t := train_at(w, "E0", 1000, 1, 0)
	t.controller = -1
	w.step(.05)
	return t.speed > 0 and t.controller > 0 and t.controller < .03

func test_buffer_stop_and_equipment_cap():
	var w := straight([160], [2500])
	var t := train_at(w, "E0", 500, 1, 80)
	t.max_speed = 90 / 3.6
	for i in 6000:
		w.step(.05)
		if t.speed > t.max_speed: return "AI exceeded equipment speed"
		if t.speed == 0:
			return t.head_s > 2492 and t.head_s <= 2493 and not t.emergency and w.events.is_empty()
	return "Did not stop before buffers"

func test_fast_forward_preserves_braking_curve():
	var a := straight([110,40], [2500,2000])
	var b := straight([110,40], [2500,2000])
	var ta := train_at(a, "E0", 500, 1, 100)
	var tb := train_at(b, "E0", 500, 1, 100)
	for i in 1600: a.step(.05)
	b.step(80)
	return absf(ta.speed - tb.speed) < .00001 and absf(ta.head_s - tb.head_s) < .00001 and absf(ta.controller - tb.controller) < .00001

func test_weak_brakes_look_ahead_beyond_five_kilometres():
	var w := straight([180,40], [12000,2000])
	var t := train_at(w, "E0", 1000, 1, 175)
	t.service_decel = .3
	var first_brake := -1.0
	for i in 10000:
		w.step(.05)
		if first_brake < 0 and t.controller < -.02: first_brake = 11000 - t.odometer
		if t.speed > 12 and t.controller < -.85: return "Weak-braked train ran out of comfortable stopping distance"
		if t.path[0].edge == "E1": return first_brake > 5000 and t.speed <= 40 / 3.6
	return "Weak-braked train did not reach restriction"
