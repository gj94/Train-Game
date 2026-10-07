extends RefCounted
const Stock := preload("res://sim/stock/ported_stock.gd")
const Fleet := preload("res://sim/layouts/ported_fleet.gd")

func test_imported_formation_geometry():
	var expected := {"icf": [8, 34, 176.639], "lhb": [8, 34, 188.56], "vb8": [8, 32, 192.0], "vb16": [16, 64, 384.0]}
	for key in expected:
		var formation := Stock.formation(key)
		var data: Array = expected[key]
		if formation.size() != data[0] or Stock.sound_axles(key).size() != data[1]: return "wrong vehicle/axle count: " + key
		if absf(Stock.length_of(key) - data[2]) > .001: return "visible envelope: " + key
		for i in range(1, formation.size()):
			var a: Dictionary = formation[i - 1]
			var b: Dictionary = formation[i]
			if absf(a.center + a.pitch / 2 - (b.center - b.pitch / 2)) > .0001: return "coupling spacing: " + key
	return true

func test_imported_reversal_preserves_axle_locations():
	for key in Stock.CHOICES:
		var forward := Stock.sound_axles(key)
		var backward := Stock.sound_axles(key, true)
		for i in forward.size():
			if forward[i].x <= 0 or forward[i].x >= Stock.length_of(key): return "axle outside occupancy: " + key
			if absf(forward[i].x + backward[i].x - Stock.length_of(key)) > .0001: return "reverse geometry: " + key
	return true

func test_second_axle_stays_clang_in_either_travel_direction():
	for choice in Stock.CHOICES:
		for reversed in [false, true]:
			var axles := Stock.sound_axles(choice, reversed)
			axles.sort_custom(func(a,b): return a.x < b.x)
			var at := 0
			while at < axles.size():
				var car: int = axles[at].car
				var count: int = Stock.geometry(Stock.formation(choice)[car].model).axle_offsets.size()
				for k in count:
					if axles[at+k].cls % 2 != k % 2: return "wrong cling/clang order: " + choice
				at += count
	return true

func test_imported_consists_have_safe_station_capacity():
	for key in Stock.CHOICES:
		var world := Fleet.build(key)
		var train: Train = world.trains.T1
		if train.length >= 600: return "platform capacity: " + key
		if train.path.size() != 1 or train.head_s < train.length: return "initial full train placement: " + key
		if train.can_change_ends != (key not in ["icf", "lhb"]): return "run-round protection: " + key
		if world.speed_limit_for(train) > train.max_speed: return "stock speed cap: " + key
	return true

func test_imported_family_and_vb_handedness():
	for key in ["icf", "lhb"]:
		var cars := Stock.formation(key)
		for i in 7:
			if cars[i + 1].model != key + "_" + Stock.CLASSES[i]: return "missing coach class"
	for key in ["vb8", "vb16"]:
		var cars := Stock.formation(key)
		if cars.front().reverse or not cars.back().reverse: return "outer cabs must face outward"
	return true
