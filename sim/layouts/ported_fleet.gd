extends RefCounted
const Corridor := preload("res://sim/layouts/southern_corridor.gd")
const Stock := preload("res://sim/stock/ported_stock.gd")

static func build(choice: String) -> RailWorld:
	var world := Corridor.build_wap7()
	Stock.configure(world.trains.T1, choice)
	world.place_train(world.trains.T1, "CPM_P1", Corridor.ORIGIN_HEAD, 1)
	return world
