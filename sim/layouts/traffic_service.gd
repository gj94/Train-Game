extends RefCounted
## Six real scheduled movements share the existing interlocked corridor.
const Corridor := preload("res://sim/layouts/southern_corridor.gd")
const Stock := preload("res://sim/stock/ported_stock.gd")
const SERVICES := ["T1", "T2", "T3", "T4", "T5", "T6"]
const FLEET := ["lhb", "icf", "vb8", "lhb", "icf", "vb16"]

static func selected_service(seed_value: int) -> String:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	return SERVICES[rng.randi_range(0, SERVICES.size()-1)]

static func build() -> RailWorld:
	var world := Corridor.build_dispatch()
	for index in SERVICES.size():
		var train: Train = world.trains[SERVICES[index]]
		var edge: String = train.path[0].edge
		var direction: int = train.path[0].dir
		Stock.configure(train, FLEET[index])
		world.place_train(train, edge, train.head_s, direction)
		# All are ready at 08:00. Conflicting departures wait for actual tail
		# clearance and block release; no artificial player hold or green light.
		train.timetable.departure = world.clock_start
		train.automatic = true
		train.controller = -1.0
		train.status = "Awaiting departure route"
	return world
