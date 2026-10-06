extends RefCounted
const Traffic := preload("res://sim/layouts/traffic_service.gd")
const Dispatch := preload("res://sim/dispatch_plan.gd")
const Stock := preload("res://sim/stock/ported_stock.gd")

func test_assignment_is_reproducible_and_reaches_every_service():
	var seen := {}
	for value in 120:
		var id := Traffic.selected_service(value)
		if id != Traffic.selected_service(value) or id not in Traffic.SERVICES:
			return "Invalid or unstable random assignment"
		seen[id] = true
	return seen.size() == 6

func test_mixed_passenger_services_fit_their_platforms():
	var world := Traffic.build()
	if world.trains.size() != 6: return "Missing services"
	var directions := {1: 0, -1: 0}
	for i in Traffic.SERVICES.size():
		var train: Train = world.trains[Traffic.SERVICES[i]]
		if train.stock_kind != "ported:"+Traffic.FLEET[i] or not is_equal_approx(train.length, Stock.length_of(Traffic.FLEET[i])):
			return "Stock and physical occupancy differ"
		directions[train.path[0].dir] += 1
		if train.path.size() != 1 or not train.automatic or train.speed != 0:
			return "Unsafe initial placement"
		for stop in train.timetable.stops:
			if absf(stop.s-world.graph.entry_s(stop.block,stop.direction)) < train.length:
				return "Booked platform does not fit service"
	return directions[1] == 3 and directions[-1] == 3

func test_manual_player_gets_routes_without_ai_taking_the_controls():
	var world := Traffic.build()
	var player: Train = world.trains.T1
	for train in world.trains.values(): train.automatic = false
	player.automatic = false
	player.controller = -.4
	Dispatch.update(world)
	if world.aspect("CPM-E1") != RailWorld.Aspect.RED: return "Legacy dispatcher routed a manual service"
	Dispatch.update(world,false,"T1")
	return world.aspect("CPM-E1") != RailWorld.Aspect.RED and not player.automatic and player.controller == -.4

func test_real_departure_queue_releases_and_all_six_finish_safely():
	var world := Traffic.build()
	Dispatch.update(world)
	if world.aspect("CPM-E1") == RailWorld.Aspect.RED or world.aspect("KDP-W3") == RailWorld.Aspect.RED:
		return "Lead departures not dispatched"
	for id in ["T3","T4","T5","T6"]:
		var signal_ahead := world.next_signal(world.trains[id])
		if world.aspect(signal_ahead.id) != RailWorld.Aspect.RED:
			return "Conflicting simultaneous departure cleared: "+id
	var departed := {}
	for tick in 1800:
		Dispatch.update(world)
		world.step(2)
		for train in world.trains.values():
			if train.timetable.actual_departures[0] >= 0:
				departed[train.id] = train.timetable.actual_departures[0]
		if world.trains.values().all(func(t): return t.service_complete): break
	if not world.events.is_empty(): return "Traffic safety event: "+str(world.events)
	if departed.size() != 6 or not world.trains.values().all(func(t): return t.service_complete):
		return "Services deadlocked or did not finish"
	if departed.T3 <= departed.T1+20 or departed.T5 <= departed.T3+20:
		return "Trailing departures did not wait for the preceding trains"
	return true
