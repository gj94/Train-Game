extends RefCounted
## Compact fictional South Indian line, about 4.8 km; every unit is one metre.
## Station architecture references and dimensional evidence: docs/stations.md.
##
##   Chennapuram (CPM) ── main_w ── Maruthur (MRT) ── main_e ── Kadalur (KDP)
##   2-platform terminus             passing loop               1-platform terminus
##
## x runs east, z south. Eastbound trains travel in +x.

const Memu := preload("res://sim/stock/memu_consist.gd")
const CAR_LENGTH := Memu.BODY_LENGTH
const CAR_GAP := Memu.INTER_CAR_GAP
const CARS := Memu.CARS
const TRACK_SPACING := 12.0
const ORIGIN_HEAD := 604.0
const PLATFORM_LENGTH := 600.0
const PLATFORM_HEIGHT_ABOVE_RAIL := 0.8
const Clock := preload("res://sim/world_clock.gd")
const TIMETABLE_FILE := "res://sim/timetables/first_line.json"


static func train_length() -> float:
	return CARS * CAR_LENGTH + (CARS - 1) * CAR_GAP


static func build() -> RailWorld:
	var w := RailWorld.new()
	var g := w.graph
	var kmh := func(v: float) -> float: return v / 3.6

	g.add_node("CPM_B1", Vector3(0, 0, 0))
	g.add_node("CPM_B2", Vector3(0, 0, -TRACK_SPACING))
	g.add_node("CPM_1", Vector3(760, 0, 0))
	g.add_node("MRT_1", Vector3(2120, 0, 0))
	g.add_node("MRT_2", Vector3(2960, 0, 0))
	g.add_node("KDP_H", Vector3(4260, 0, 0))
	g.add_node("KDP_B", Vector3(4890, 0, 0))

	g.add_edge("cpm_p1", "CPM_B1", "CPM_1", straight(0, 760, 0), kmh.call(50))
	g.add_edge("cpm_p2", "CPM_B2", "CPM_1",
		straight(0, 620, -TRACK_SPACING) + ease_between(620, 760, -TRACK_SPACING, 0), kmh.call(30))
	g.add_edge("main_w", "CPM_1", "MRT_1", bow(760, 2120, -160), kmh.call(100))
	g.add_edge("mrt_main", "MRT_1", "MRT_2", straight(2120, 2960, 0), kmh.call(80))
	g.add_edge("mrt_loop", "MRT_1", "MRT_2",
		ease_between(2120, 2240, 0, TRACK_SPACING) + straight(2240, 2840, TRACK_SPACING)
		+ ease_between(2840, 2960, TRACK_SPACING, 0), kmh.call(30))
	g.add_edge("main_e", "MRT_2", "KDP_H", bow(2960, 4260, 120), kmh.call(100))
	g.add_edge("kdp_plat", "KDP_H", "KDP_B", straight(4260, 4890, 0), kmh.call(50))

	g.add_switch("CPM_1", "main_w", "cpm_p1", "cpm_p2", 115.0)
	g.add_switch("MRT_1", "main_w", "mrt_main", "mrt_loop", 105.0)
	g.add_switch("MRT_2", "main_e", "mrt_main", "mrt_loop", 105.0)

	# Eastbound (+1)
	w.add_signal("CPM-S1", "cpm_p1", 1, 150) # starters before the turnout clearance
	w.add_signal("CPM-S2", "cpm_p2", 1, g.edges.cpm_p2.length - 610.0)
	w.add_signal("MRT-HE", "main_w", 1)    # home, eastbound
	w.add_signal("MRT-SE1", "mrt_main", 1, 122) # hold a 20-coach rake clear of the throat
	w.add_signal("MRT-SE2", "mrt_loop", 1, 122)
	w.add_signal("KDP-H", "main_e", 1)     # home
	# Westbound (-1)
	w.add_signal("KDP-S", "kdp_plat", -1)  # starter
	w.add_signal("MRT-HW", "main_e", -1)
	w.add_signal("MRT-SW1", "mrt_main", -1, 122)
	w.add_signal("MRT-SW2", "mrt_loop", -1, 122)
	w.add_signal("CPM-H", "main_w", -1)

	w.stations = [
		{code = "CPM", name = "Chennapuram", tamil = "சென்னபுரம்", hindi = "चेन्नपुरम", reference = "Kumbakonam", kit = "kumbakonam", origin = Vector3(308, 0, 0), platforms = [Rect2(8, -10.1, PLATFORM_LENGTH, 8.2), Rect2(8, -25.9, PLATFORM_LENGTH, 12)], building = Vector3(308, 0, -34)},
		{code = "MRT", name = "Maruthur", tamil = "மருதூர்", hindi = "मरुदूर", reference = "Mayiladuthurai Junction", kit = "mayiladuthurai", origin = Vector3(2540, 0, 0), platforms = [Rect2(2240, 1.9, PLATFORM_LENGTH, 8.2), Rect2(2240, -13.9, PLATFORM_LENGTH, 12)], building = Vector3(2540, 0, -22)},
		{code = "KDP", name = "Kadalur", tamil = "கடலூர்", hindi = "कडलूर", reference = "Thanjavur Junction", kit = "thanjavur", origin = Vector3(4570, 0, 0), platforms = [Rect2(4270, 1.9, PLATFORM_LENGTH, 12)], building = Vector3(4570, 0, 22)},
	]

	var t := Train.new("T1", train_length())
	w.place_train(t, "cpm_p1", ORIGIN_HEAD, 1)
	return w


## Two opposing eight-car services. Both wait for the dispatcher at red.
static func build_dispatch() -> RailWorld:
	var w := build()
	var east: Train = w.trains.T1
	east.automatic = true
	east.service_name = "66001 · Coast local"
	east.destination = "Kadalur"
	east.head_s = ORIGIN_HEAD
	east.controller = -1.0
	east.status = "Waiting for CPM-S1"
	var west := Train.new("T2", train_length())
	west.automatic = true
	west.service_name = "66002 · Valley local"
	west.destination = "Chennapuram"
	west.controller = -1.0
	west.status = "Waiting for KDP-S"
	w.place_train(west, "kdp_plat", 16.0, -1)
	var plan: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(TIMETABLE_FILE))
	w.clock_start = (int(plan.day) - 1) * Clock.DAY + Clock.parse_time(plan.world_start)
	for id in plan.services:
		var definition: Dictionary = plan.services[id]
		var result := w.set_timetable(id, definition)
		assert(result.ok, "Invalid %s timetable: %s" % [id, result.reason])
		w.trains[id].service_name = definition.name
	return w


## Standalone WAP-7 light-engine working; the existing MEMU meet remains available.
## Physics is deliberately a playable approximation, not a traction certification.
static func build_wap7() -> RailWorld:
	var w := build()
	var t: Train = w.trains.T1
	t.stock_kind = "wap7"
	t.length = 20.562
	t.mass = 108000.0
	t.max_power = 4500000.0
	t.max_accel = 1.0
	t.max_speed = 140.0 / 3.6
	t.service_name = "30306 · WAP-7 light engine"
	t.destination = "Kadalur"
	t.status = "Manual WAP-7 test drive"
	t.head_s = ORIGIN_HEAD
	t.controller = 0.0
	w.set_route("CPM-S1", "MRT-HE")
	w.set_route("MRT-HE", "MRT-SE1")
	return w


## Full-length AC special formation: 16 three-tier, 2 two-tier, 2 generator vans.
## A run-round is not simulated, so this service is an outbound working.
static func build_lhb() -> RailWorld:
	var profile := preload("res://sim/stock/lhb_consist.gd")
	var w := build_wap7()
	var t: Train = w.trains.T1
	t.stock_kind = "lhb"
	t.length = profile.LENGTH
	t.mass = profile.MASS
	t.max_accel = .65
	t.service_decel = .80
	t.can_change_ends = false
	t.service_name = "Southern Coast AC Special"
	t.status = "WAP-7 + 20 LHB coaches · 500.562 m"
	return w


# --- geometry helpers: points strictly between the ends ----------------------

const STEP := 5.0


## Interior points of a straight run from x0 to x1 at depth z.
static func straight(x0: float, x1: float, z: float) -> Array:
	var pts := []
	var n := int((x1 - x0) / 20.0)
	for i in range(1, n):
		pts.append(Vector3(lerpf(x0, x1, float(i) / n), 0, z))
	return pts


## Smooth sideways shift from z0 to z1 between x0 and x1 (zero slope at both ends).
static func ease_between(x0: float, x1: float, z0: float, z1: float) -> Array:
	var pts := []
	var n := int((x1 - x0) / STEP)
	for i in range(1, n):
		var t := float(i) / n
		pts.append(Vector3(lerpf(x0, x1, t), 0, lerpf(z0, z1, (1.0 - cos(PI * t)) * 0.5)))
	return pts


## A gentle bow of depth `depth` between x0 and x1 (straight at both ends).
static func bow(x0: float, x1: float, depth: float) -> Array:
	var pts := []
	var n := int((x1 - x0) / (STEP * 2))
	for i in range(1, n):
		var t := float(i) / n
		pts.append(Vector3(lerpf(x0, x1, t), 0, depth * (1.0 - cos(TAU * t)) * 0.5))
	return pts
