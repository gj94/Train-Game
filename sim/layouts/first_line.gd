extends RefCounted
## First layout: a fictional single line in South India, about 3.7 km.
##
##   Chennapuram (CPM) ── main_w ── Maruthur (MRT) ── main_e ── Kadalur (KDP)
##   2-platform terminus             passing loop               1-platform terminus
##
## x runs east, z south. Eastbound trains travel in +x.

const CAR_LENGTH := 21.3
const CAR_GAP := 0.6
const CARS := 1          # single car for sound testing (was 8)
const TRACK_SPACING := 9.0


static func train_length() -> float:
	return CARS * CAR_LENGTH + (CARS - 1) * CAR_GAP


static func build() -> RailWorld:
	var w := RailWorld.new()
	var g := w.graph
	var kmh := func(v: float) -> float: return v / 3.6

	g.add_node("CPM_B1", Vector3(0, 0, 0))
	g.add_node("CPM_B2", Vector3(0, 0, -TRACK_SPACING))
	g.add_node("CPM_1", Vector3(320, 0, 0))
	g.add_node("MRT_1", Vector3(1800, 0, 0))
	g.add_node("MRT_2", Vector3(2200, 0, 0))
	g.add_node("KDP_H", Vector3(3500, 0, 0))
	g.add_node("KDP_B", Vector3(3720, 0, 0))

	g.add_edge("cpm_p1", "CPM_B1", "CPM_1", straight(0, 320, 0), kmh.call(50))
	g.add_edge("cpm_p2", "CPM_B2", "CPM_1",
		straight(0, 200, -TRACK_SPACING) + ease_between(200, 320, -TRACK_SPACING, 0), kmh.call(30))
	g.add_edge("main_w", "CPM_1", "MRT_1", bow(320, 1800, -160), kmh.call(100))
	g.add_edge("mrt_main", "MRT_1", "MRT_2", straight(1800, 2200, 0), kmh.call(80))
	g.add_edge("mrt_loop", "MRT_1", "MRT_2",
		ease_between(1800, 1900, 0, TRACK_SPACING) + straight(1900, 2100, TRACK_SPACING)
		+ ease_between(2100, 2200, TRACK_SPACING, 0), kmh.call(30))
	g.add_edge("main_e", "MRT_2", "KDP_H", bow(2200, 3500, 120), kmh.call(100))
	g.add_edge("kdp_plat", "KDP_H", "KDP_B", straight(3500, 3720, 0), kmh.call(50))

	g.add_switch("CPM_1", "main_w", "cpm_p1", "cpm_p2")
	g.add_switch("MRT_1", "main_w", "mrt_main", "mrt_loop")
	g.add_switch("MRT_2", "main_e", "mrt_main", "mrt_loop")

	# Eastbound (+1)
	w.add_signal("CPM-S1", "cpm_p1", 1)    # starter, platform 1
	w.add_signal("CPM-S2", "cpm_p2", 1)    # starter, platform 2
	w.add_signal("MRT-HE", "main_w", 1)    # home, eastbound
	w.add_signal("MRT-SE1", "mrt_main", 1) # starter from main line
	w.add_signal("MRT-SE2", "mrt_loop", 1) # starter from loop
	w.add_signal("KDP-H", "main_e", 1)     # home
	# Westbound (-1)
	w.add_signal("KDP-S", "kdp_plat", -1)  # starter
	w.add_signal("MRT-HW", "main_e", -1)
	w.add_signal("MRT-SW1", "mrt_main", -1)
	w.add_signal("MRT-SW2", "mrt_loop", -1)
	w.add_signal("CPM-H", "main_w", -1)

	w.stations = [
		{code = "CPM", name = "Chennapuram", platforms = [Rect2(20, -7.2, 210, 5.4)], building = Vector3(120, 0, -16)},
		{code = "MRT", name = "Maruthur", platforms = [Rect2(1910, 1.8, 180, 5.4)], building = Vector3(2000, 0, -9)},
		{code = "KDP", name = "Kadalur", platforms = [Rect2(3505, 1.8, 205, 5.4)], building = Vector3(3610, 0, 13)},
	]

	var t := Train.new("T1", train_length())
	w.place_train(t, "cpm_p1", 300.0, 1)
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
