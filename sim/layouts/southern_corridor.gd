extends RefCounted
## 21.64 km fictional Southern Railway corridor, metre-scale throughout.
## Four platform faces per station; double line, six-metre centres, left-hand running.
const Geometry := preload("res://sim/layouts/first_line.gd")
const Memu := preload("res://sim/stock/memu_consist.gd")
const Lhb := preload("res://sim/stock/lhb_consist.gd")
const Z := [-9.0, -21.0, 9.0, 21.0]
const CENTRES := [500.0, 11000.0, 21500.0]
const CODES := ["CPM", "MRT", "KDP"]
const ORIGIN_HEAD := 604.0 # distance from west buffer at x=180 to head at x=784

static func build() -> RailWorld:
	var w := RailWorld.new()
	var refs := Geometry.build().stations
	for i in 3:
		var st: Dictionary = refs[i].duplicate(true)
		var cx: float = CENTRES[i]
		st.origin = Vector3(cx, 0, 0)
		st.building = Vector3(cx, 0, 36 if i == 2 else -36)
		st.platforms = [Rect2(cx-300, -19.1, 600, 8.2), Rect2(cx-300, 10.9, 600, 8.2)]
		st.platform_numbers = [[2, 1], [3, 4]]
		st.track_z = Z.duplicate()
		st.platform_tracks = []
		st.asset_variant = "_yard"
		for p in range(1, 5):
			st.platform_tracks.append("%s_P%d" % [st.code, p])
		w.stations.append(st)
		_station(w, st, i)
	_terminal_throat(w, "CPM", CENTRES[0], 1)
	_terminal_throat(w, "KDP", CENTRES[2], -1)
	_mainline(w, "W", "CPM_OUT", "MRT_L", 2100, 10440, -150)
	_mainline(w, "E", "MRT_R", "KDP_OUT", 11560, 19900, 180)
	# Homes precede the first points by 250 m. Block stop signals have the same
	# setback, so the whole reserved edge includes 250 m beyond the next signal.
	w.add_signal("MRT-HE", "W_E3", 1, 250)
	w.add_signal("MRT-HW", "E_W0", -1, 250)
	w.add_signal("CPM-H", "W_W0", -1, 250)
	w.add_signal("KDP-H", "E_E3", 1, 250)
	w.scenery = {x_min = -500.0, x_max = 22200.0, corridor = true,
		villages = [3300.0, 7000.0, 14300.0, 18000.0], overbridges = [5400.0, 16500.0],
		canals = [7900.0, 14600.0]}
	w._update_automatic_blocks()
	return w

static func _node(w: RailWorld, id: String, x: float, z: float) -> void:
	w.graph.add_node(id, Vector3(x, 0, z))

static func _edge(w: RailWorld, id: String, a: String, b: String, speed: float = 60) -> void:
	if w.graph.nodes[a].pos.x > w.graph.nodes[b].pos.x:
		var swap := a
		a = b
		b = swap
	var p: Vector3 = w.graph.nodes[a].pos
	var q: Vector3 = w.graph.nodes[b].pos
	w.graph.add_edge(id, a, b, Geometry.ease_between(p.x, q.x, p.z, q.z), speed / 3.6)

static func _station(w: RailWorld, st: Dictionary, index: int) -> void:
	var c: String = st.code
	var cx: float = st.origin.x
	for end in ["L", "R"]:
		if (index == 0 and end == "L") or (index == 2 and end == "R"):
			continue
		for group in ["E", "W"]:
			_node(w, c+"_"+end+group, cx + (-560 if end == "L" else 560), -3 if group == "E" else 3)
	for p in range(1, 5):
		var group := "E" if p <= 2 else "W"
		var left := c+"_L"+group
		var right := c+"_R"+group
		var mids := Geometry.straight(cx-340, cx+340, Z[p-1])
		if index == 0:
			left = "%s_B%d" % [c, p]
			_node(w, left, cx-320, Z[p-1])
			mids = Geometry.straight(cx-320, cx+340, Z[p-1])
		else:
			mids = Geometry.ease_between(cx-560, cx-340, -3 if p <= 2 else 3, Z[p-1]) + [Vector3(cx-340,0,Z[p-1])] + mids
		if index == 2:
			right = "%s_B%d" % [c, p]
			_node(w, right, cx+320, Z[p-1])
			# Trim the straight before the buffer rather than doubling back.
			mids = mids.filter(func(v): return v.x < cx+320)
		else:
			mids += [Vector3(cx+340,0,Z[p-1])] + Geometry.ease_between(cx+340, cx+560, Z[p-1], -3 if p <= 2 else 3)
		var road := "%s_P%d" % [c,p]
		w.graph.add_edge(road, left, right, mids, (65.0 if p in [1,3] else 30.0)/3.6)
		if index < 2:
			w.add_signal("%s-E%d" % [c,p], road, 1, 270)
		if index > 0:
			w.add_signal("%s-W%d" % [c,p], road, -1, 270)
	# Switch registration follows once external trunk edges have been connected.

static func _terminal_throat(w: RailWorld, c: String, cx: float, side: int) -> void:
	var end := "R" if side > 0 else "L"
	for group in ["E", "W"]:
		var z := -3.0 if group == "E" else 3.0
		_node(w, c+"_OUT"+group, cx+side*1600, z)
		for j in [1,2]:
			var d: float = (800 if group == "E" else 980) if j == 1 else (1340 if group == "E" else 1160)
			_node(w, c+"_X"+group+str(j), cx+side*d, z)
		_edge(w, c+"_LEAD"+group, c+"_"+end+group, c+"_X"+group+"1")
		_edge(w, c+"_MID"+group, c+"_X"+group+"1", c+"_X"+group+"2")
		_edge(w, c+"_OUT_"+group, c+"_X"+group+"2", c+"_OUT"+group)
		var p := 1 if group == "E" else 3
		w.graph.add_switch(c+"_"+end+group, c+"_LEAD"+group, "%s_P%d"%[c,p], "%s_P%d"%[c,p+1], 195)
	for j in [1,2]:
		_edge(w, c+"_CROSS"+str(j), c+"_XE"+str(j), c+"_XW"+str(j), 30)
	w.graph.add_switch(c+"_XE1", c+"_LEADE", c+"_MIDE", c+"_CROSS1", 155)
	w.graph.add_switch(c+"_XW1", c+"_MIDW", c+"_LEADW", c+"_CROSS1", 155)
	w.graph.add_switch(c+"_XE2", c+"_OUT_E", c+"_MIDE", c+"_CROSS2", 155)
	w.graph.add_switch(c+"_XW2", c+"_MIDW", c+"_OUT_W", c+"_CROSS2", 155)

static func _mainline(w: RailWorld, section: String, left: String, right: String, x0: float, x1: float, depth: float) -> void:
	for group in ["E", "W"]:
		var z := -3.0 if group == "E" else 3.0
		var previous: String = left+group
		for i in 4:
			var x := lerpf(x0,x1,(i+1)/4.0)
			var next: String = right+group if i == 3 else "%s_%s_N%d"%[section,group,i]
			if i < 3:
				_node(w,next,x,z + depth*(1-cos(TAU*(i+1)/4.0))*.5)
			var start := lerpf(x0,x1,i/4.0)
			var mids := []
			for j in range(1, int((x-start)/20)):
				var px := lerpf(start,x,j/float(int((x-start)/20)))
				mids.append(Vector3(px,0,z+depth*(1-cos(TAU*(px-x0)/(x1-x0)))*.5))
			var eid := "%s_%s%d"%[section,group,i]
			w.graph.add_edge(eid,previous,next,mids,110.0/3.6,1 if group == "E" else -1)
			if (group == "E" and i < 3) or (group == "W" and i > 0):
				var sid := "%s-A%s%d"%[section,group,i+1 if group=="E" else 4-i]
				w.add_signal(sid,eid,1 if group=="E" else -1,250)
				w.automatic_signals.append(sid)
			previous = next
	# Only Maruthur has through platform roads at both ends.
	var end := "L" if section == "W" else "R"
	for group in ["E","W"]:
		var p := 1 if group == "E" else 3
		w.graph.add_switch("MRT_"+end+group, "%s_%s%d"%[section,group,3 if section=="W" else 0], "MRT_P%d"%p, "MRT_P%d"%(p+1),195)

static func build_dispatch() -> RailWorld:
	var w := build()
	var plan: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://sim/timetables/southern_corridor.json"))
	w.clock_start = (int(plan.day)-1)*86400 + preload("res://sim/world_clock.gd").parse_time(plan.world_start)
	for id in plan.services:
		var definition: Dictionary = plan.services[id]
		var t := Train.new(id,Memu.LENGTH)
		var first: Dictionary = definition.stops[0]
		var dir: int = first.direction
		var edge: String = first.block
		var origin := edge.get_slice("_",0)
		var marker: float = w.signals["%s-%s%s"%[origin,"E" if dir>0 else "W",edge.right(1)]].s - dir*6.0
		w.place_train(t,edge,marker,dir)
		t.automatic = true
		t.controller = -1
		t.service_name = definition.name
		var result := w.set_timetable(t.id,definition)
		assert(result.ok,result.reason)
	return w

static func build_wap7() -> RailWorld:
	var w := build()
	var t: Train = Geometry.build_wap7().trains.T1
	w.place_train(t,"CPM_P1",ORIGIN_HEAD,1)
	w.set_route("CPM-E1","W-AE1")
	w.set_route("MRT-HE","MRT-E1")
	return w

static func build_lhb() -> RailWorld:
	var w := build_wap7()
	var t: Train = w.trains.T1
	t.stock_kind = "lhb"
	t.length = Lhb.LENGTH
	t.mass = Lhb.MASS
	t.max_accel = .65
	t.service_decel = .80
	t.can_change_ends = false
	t.service_name = "Southern Coast AC Special"
	w.place_train(t,"CPM_P1",ORIGIN_HEAD,1)
	return w
