extends RefCounted
const Stock := preload("res://sim/stock/ported_stock.gd")
const Fleet := preload("res://sim/layouts/ported_fleet.gd")

func test_imported_formation_geometry():
	var expected := {"icf": [23, 94, 511.094], "lhb": [23, 94, 548.56], "vb8": [8, 32, 192.0], "vb16": [16, 64, 384.0]}
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
		for profile in Stock.profiles(key):
			var cars := Stock.formation(key,profile)
			if cars[0].model != "wap7": return "missing locomotive"
			for i in range(1,cars.size()):
				if not cars[i].model.begins_with(key+"_"): return "mixed incompatible coach families"
	for key in ["vb8", "vb16"]:
		var cars := Stock.formation(key)
		if cars.front().reverse or not cars.back().reverse: return "outer cabs must face outward"
	return true

func test_long_rake_mass_traction_and_stopping_passenger_geometry():
	for key in ["icf","lhb"]:
		var express := Train.new("E",1)
		var local := Train.new("P",1)
		Stock.configure(express,key)
		Stock.configure(local,key,"passenger")
		if express.mass != 123000+22*(45000 if key=="icf" else 54000): return "rake mass omits vehicles"
		if local.length >= express.length or local.mass >= express.mass: return "passenger profile is not shared by mass/geometry"
		if absf(express.max_accel*express.mass-322600)>1 or express.max_accel>=local.max_accel: return "WAP tractive effort not respected"
		if Stock.formation(key,"passenger").size()!=21 or Stock.sound_axles(key,false,"passenger").size()!=86: return "wrong stopping rake"
		for car in Stock.formation(key,"passenger").slice(1):
			if car.model not in [key+"_gs",key+"_2s"]: return "sleeper/AC showcase in stopping passenger"
		for reversed in [false,true]:
			for axle in Stock.sound_axles(key,reversed,"passenger"):
				if axle.x<=0 or axle.x>=local.length: return "passenger axle outside occupied body"
	return true
