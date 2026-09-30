extends RefCounted

const Clock := preload("res://sim/world_clock.gd")
const Line := preload("res://sim/layouts/first_line.gd")

func _world(departure: String = "08:01", dwell: float = 1.0) -> RailWorld:
	var w := Line.build()
	var t: Train = w.trains.T1
	t.automatic = true
	t.head_s = Line.ORIGIN_HEAD
	var result := w.set_timetable("T1", {
		departure = departure,
		stops = [
			{block = "cpm_p1", minutes_from_origin = 0, direction = 1},
			{block = "mrt_loop", minutes_from_origin = 4, dwell_minutes = dwell, direction = 1},
			{block = "kdp_plat", minutes_from_origin = 9, direction = 1},
		]})
	assert(result.ok, result.reason)
	return w

func _route_to_loop(w: RailWorld) -> void:
	w.set_route("CPM-S1", "MRT-HE")
	w.set_route("MRT-HE", "MRT-SE2")

func test_24_hour_clock_and_day_rollover():
	var w := RailWorld.new()
	w.clock_start = Clock.parse_time("23:59:59")
	w.step(2)
	return w.clock_text() == "00:00:01" and w.clock_day() == 2 and Clock.format_time(25 * 3600) == "01:00:00"

func test_time_parser_rejects_invalid_24_hour_times():
	return Clock.parse_time("24:00") < 0 and Clock.parse_time("12:60") < 0 and Clock.parse_time("night") < 0 and Clock.parse_time("+1:30") < 0 and Clock.parse_time("07:05") == 25500

func test_clear_route_does_not_allow_early_departure():
	var w := _world()
	_route_to_loop(w)
	w.step(59)
	return w.trains.T1.speed == 0 and w.trains.T1.odometer == 0 and w.trains.T1.timetable.actual_departures[0] < 0

func test_due_train_waits_for_route_then_departs_automatically():
	var w := _world()
	w.step(90)
	if w.trains.T1.odometer != 0:
		return "Train moved with no departure route"
	_route_to_loop(w)
	w.step(5)
	var tt = w.trains.T1.timetable
	return w.trains.T1.speed > 0 and tt.index == 1 and tt.actual_departures[0] >= 8 * 3600 + 90

func test_only_origin_route_is_needed_to_start():
	var w := _world()
	w.set_route("CPM-S1", "MRT-HE")
	w.step(90)
	return w.trains.T1.odometer > 0 and not w.signals["MRT-HE"].cleared

func test_stop_is_mandatory_even_with_onward_route_clear():
	var w := _world()
	_route_to_loop(w)
	w.set_route("MRT-SE2", "KDP-H")
	w.set_route("KDP-H", "BUFFER:KDP_B")
	var t: Train = w.trains.T1
	for i in 7000:
		w.step(0.05)
		if t.timetable.at_stop and t.timetable.index == 1:
			break
	if t.timetable.index != 1 or not t.timetable.at_stop or t.speed > 0.05:
		return "Skipped the scheduled station call"
	var position := t.head_s
	w.step(20)
	return is_equal_approx(t.head_s, position) and t.path[0].edge == "mrt_loop"

func test_late_arrival_gets_full_dwell_and_offsets_stay_fixed():
	var w := _world()
	w.step(500)
	_route_to_loop(w)
	w.set_route("MRT-SE2", "KDP-H")
	w.set_route("KDP-H", "BUFFER:KDP_B")
	var t: Train = w.trains.T1
	for i in 8000:
		w.step(0.05)
		if t.timetable.at_stop and t.timetable.index == 1:
			break
	var tt = t.timetable
	if not tt.at_stop:
		return "Did not arrive at intermediate stop"
	var arrival: float = tt.actual_arrivals[1]
	w.step(59)
	if tt.index != 1 or not tt.at_stop:
		return "Late arrival lost its minimum dwell"
	w.step(3)
	if tt.actual_departures[1] < arrival + 60 - 0.0001:
		return "Arrival %.3f, departure %.3f, now %.3f; %s" % [arrival, tt.actual_departures[1], w.clock_seconds(), t.status]
	return tt.planned_arrival(2) == 8 * 3600 + 60 + 9 * 60

func test_timetable_rejects_wrong_platform_route():
	var w := _world()
	w.set_route("CPM-S1", "MRT-HE")
	w.set_route("MRT-HE", "MRT-SE1")
	w.step(500)
	var t: Train = w.trains.T1
	return t.path[0].edge == "main_w" and t.speed < 0.01 and w.next_signal(t).id == "MRT-HE" and t.timetable.actual_arrivals[1] < 0

func test_overnight_offsets_are_absolute_not_reset_at_midnight():
	var w := _world("23:59")
	w.clock_start = Clock.parse_time("23:58:30")
	_route_to_loop(w)
	w.step(120)
	var tt = w.trains.T1.timetable
	return tt.actual_departures[0] >= Clock.parse_time("23:59") and Clock.format_time(tt.planned_arrival(1)) == "00:03:00" and w.clock_day() == 2

func test_invalid_timetable_is_rejected_atomically():
	var w := _world()
	var original = w.trains.T1.timetable
	for stops in [
		[{block = "cpm_p1", minutes_from_origin = 0}, {block = "missing", minutes_from_origin = 4}],
		[{block = "cpm_p1", minutes_from_origin = 2}, {block = "mrt_loop", minutes_from_origin = 4}],
		[{block = "cpm_p1", minutes_from_origin = 0}, {block = "mrt_loop", minutes_from_origin = -1}],
	]:
		if w.set_timetable("T1", {departure = "08:00", stops = stops}).ok:
			return "Accepted invalid stops"
	return w.trains.T1.timetable == original

func test_manual_arrival_and_ai_handoff_keep_timetable_progress():
	var w := _world()
	_route_to_loop(w)
	w.step(70)
	var t: Train = w.trains.T1
	t.automatic = false
	t.controller = -1
	t.speed = 0
	var tt = t.timetable
	w.place_train(t, "mrt_loop", tt.stops[1].s, 1)
	w.step(0.05)
	t.automatic = true
	w.step(10)
	return tt.index == 1 and tt.at_stop and tt.actual_arrivals[1] >= 0 and t.speed == 0

func test_station_dwell_at_60hz_does_not_count_residual_braking_as_departure():
	var w := _world()
	_route_to_loop(w)
	w.set_route("MRT-SE2", "KDP-H")
	w.set_route("KDP-H", "BUFFER:KDP_B")
	var t: Train = w.trains.T1
	for i in 25000:
		w.step(1.0 / 60.0)
		if t.timetable.at_stop and t.timetable.index == 1:
			break
	if not t.timetable.at_stop or t.timetable.index != 1:
		return "No intermediate arrival at 60 Hz"
	for i in 3000:
		w.step(1.0 / 60.0)
	return t.timetable.index == 1 and t.timetable.at_stop and t.speed == 0

func test_scenario_loads_block_based_timetables():
	var w := Line.build_dispatch()
	return w.clock_text() == "08:00:00" and w.trains.T1.timetable.departure == 28860 and w.trains.T2.timetable.stops[1].block == "mrt_main" and w.trains.T1.timetable.stops[1].minutes_from_origin == 4

func test_early_arrival_waits_for_booked_departure_then_for_route():
	var w := _world()
	_route_to_loop(w)
	w.step(70)
	var t: Train = w.trains.T1
	t.automatic = false
	t.speed = 0
	t.controller = -1
	w.place_train(t, "mrt_loop", t.timetable.stops[1].s, 1)
	w.step(0.05)
	t.automatic = true
	w.set_route("MRT-SE2", "KDP-H")
	w.step(285) # 08:05:55, more than a minute after arrival but not due out
	if not t.timetable.at_stop or t.speed != 0:
		return "Early arrival departed before 08:06"
	w.set_signal("MRT-SE2", false)
	w.step(10)
	if not t.timetable.at_stop or t.speed != 0:
		return "Departure time overrode a red starter"
	if not t.timetable.row_status(1, w.clock_seconds()).begins_with("Held +"):
		return "Timetable did not report the held departure"
	w.set_route("MRT-SE2", "KDP-H")
	w.step(2)
	return t.timetable.actual_departures[1] >= 8 * 3600 + 365 and t.speed > 0

func test_terminal_arrival_remains_complete_after_midnight():
	var w := _world()
	_route_to_loop(w)
	w.set_route("MRT-SE2", "KDP-H")
	w.set_route("KDP-H", "BUFFER:KDP_B")
	w.step(1000)
	var t: Train = w.trains.T1
	if not t.service_complete:
		return "Train did not finish timetable"
	var distance := t.odometer
	var arrival: float = t.timetable.actual_arrivals[2]
	w.time += Clock.DAY
	w.step(5)
	return t.service_complete and t.odometer == distance and t.timetable.actual_arrivals[2] == arrival and t.speed == 0
