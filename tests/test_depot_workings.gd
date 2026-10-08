extends RefCounted
const Depot:=preload("res://sim/depot_workings.gd")
const Kerala:=preload("res://sim/layouts/kerala_coast.gd")
const Berth:=preload("res://sim/berth_clearance.gd")

func fixture() -> RailWorld:
	var w:=RailWorld.new()
	for pair in [["a",0,0],["b",1000,0],["c",2000,0],["d",2000,100]]:
		w.graph.add_node(pair[0],Vector3(pair[1],0,pair[2]))
	w.graph.add_edge("platform","a","b")
	w.graph.add_edge("main","b","c")
	w.graph.add_edge("depot","b","d",[],15.0/3.6)
	w.graph.add_switch("b","platform","main","depot",50)
	w.add_signal("S","platform",1,100)
	w.depots.depot={name="Test depot",direction=1,station="TEST"}
	var t:=Train.new("T",500);w.place_train(t,"platform",700,1)
	t.timetable=preload("res://sim/timetable.gd").new()
	t.timetable.stops=[{block="platform",name="Origin",direction=1,s=500.0,minutes_from_origin=0.0,dwell_minutes=0.0},{block="platform",name="Terminal",direction=1,s=700.0,minutes_from_origin=10.0,dwell_minutes=0.0}]
	t.timetable.index=1;t.timetable.at_stop=true
	t.timetable.actual_arrivals.assign([0.0,100.0]);t.timetable.actual_departures.assign([10.0,-1.0])
	t.service_complete=true;t.controller=-1
	w.dispatcher().enabled=true
	return w

func test_unloading_does_not_teleport_or_clear_the_occupied_platform():
	var w:=fixture();var t: Train=w.trains.T
	var original=t.timetable
	Depot.update(w,t);w.time+=89;Depot.update(w,t)
	return t.depot.phase=="unloading" and t.path[0].edge=="platform" and w.occupancy().platform=="T" and t.completed_timetable==original and not Depot.active(t)

func test_empty_stock_obeys_signals_and_clears_full_tail_to_depot():
	var w:=fixture();var t: Train=w.trains.T
	Depot.update(w,t);w.time+=91;Depot.update(w,t)
	if not Depot.active(t) or not t.automatic or w.depot_reservations.depot!="T":return "No booked depot working"
	w.dispatcher().set_enabled(false)
	for i in 200:w.step(.1)
	if t.head_s>894.01 or t.path[0].edge!="platform":return "Moved through red"
	w.dispatcher().set_enabled(true)
	for i in 1800:
		w.step(.5)
		if not w.events.is_empty():return str(w.events)
		if Depot.finished(w,t):break
	if t.depot.phase!="stabled":return t.status
	if w.occupancy().has("platform") or w.occupancy().has("main"):return "Main remains occupied"
	if t.path.size()!=1 or w._train_near_switch(t,"b"):return "Tail fouls points"
	if not t.service_complete or t.completed_timetable.actual_arrivals[-1]!=100:return "Passenger result overwritten"
	var progress:=preload("res://sim/service_progress.gd").snapshot(w,t)
	return progress.complete and progress.total==2 and progress.completed==2

func test_no_free_depot_keeps_train_protected_and_retries_after_space_frees():
	var w:=fixture();var t: Train=w.trains.T
	w.depot_reservations.depot="OTHER"
	Depot.update(w,t);w.time+=91;Depot.update(w,t)
	if Depot.active(t) or not w.occupancy().has("platform"):return "Left without a berth"
	w.depot_reservations.clear();Depot.update(w,t)
	return Depot.active(t)

func test_passenger_timetable_cannot_book_a_depot_as_a_passenger_platform():
	var w:=fixture();var t: Train=w.trains.T;var original=t.timetable
	var result:=w.set_timetable("T",{departure="08:00",stops=[{block="platform",minutes_from_origin=0},{block="depot",minutes_from_origin=5}]})
	return not result.ok and t.timetable==original and result.reason.contains("Depot")

func test_depot_lease_is_released_when_operator_deletes_service():
	var w:=fixture();var t: Train=w.trains.T
	var other:=Train.new("OTHER",50);w.place_train(other,"main",700,1)
	Depot.update(w,t);w.time+=91;Depot.update(w,t)
	var result: Dictionary=w.dispatcher().delete_service("T","OTHER")
	return result.ok and not w.depot_reservations.has("depot")

func test_operator_hold_survives_handover_to_depot():
	var w:=fixture();var t: Train=w.trains.T
	w.dispatcher().operator_holds.T=true
	Depot.update(w,t);w.time+=91;Depot.update(w,t);w.dispatcher().run_cycle(true)
	return w.dispatcher().states.T.status=="held" and w.aspect("S")==RailWorld.Aspect.RED

func test_head_in_depot_does_not_mark_train_stabled_before_tail_clearance():
	var w:=fixture();var t: Train=w.trains.T
	Depot.update(w,t);w.time+=91;Depot.update(w,t)
	w.graph.switches.b.reversed=true
	w.place_train(t,"depot",300,1)
	t.timetable.index=1;t.timetable.at_stop=true
	Depot.update(w,t)
	return Depot.active(t) and t.path.size()>1 and w.occupancy().has("platform")

func test_depot_terrain_matches_tracks_and_excludes_mapped_buildings():
	var w:=Kerala.build()
	var geo=preload("res://game/geographic_data.gd").new(w.scenery.route)
	for road in w.depots:
		var p:=w.graph.position(road,w.graph.edges[road].length*.6)
		var rail: Dictionary=geo.nearest_rail(p.x,p.z)
		if rail.distance>1 or not rail.get("depot",false):return "Missing ground index "+road
		if absf(geo.ground_at(p.x,p.z)-(p.y-.15))>.02:return "Floating depot road "+road
	return true

func test_all_32_default_terminals_have_distinct_reachable_full_rake_depot_berths():
	var w:=Kerala.build_traffic()
	for t in w.trains.values():
		var stop: Dictionary=t.timetable.stops[-1]
		w.place_train(t,stop.block,stop.s,stop.direction)
		var choice:=Depot.choose(w,t)
		if choice.is_empty():return "No depot for "+t.id+" from "+stop.block
		if not Berth.fits(w,t,choice.road,choice.s,choice.direction,false):return "Short depot "+choice.road
		w.depot_reservations[choice.road]=t.id
		for st in w.stations:
			if choice.road in st.platform_tracks:return "Depot consumed a passenger road"
	return w.depot_reservations.size()==32

func test_delayed_arrival_orders_keep_depot_capacity_for_every_default_service():
	var w:=Kerala.build_traffic()
	var rng:=RandomNumberGenerator.new();rng.seed=194
	for t in w.trains.values():
		var stop: Dictionary=t.timetable.stops[-1]
		w.place_train(t,stop.block,stop.s,stop.direction)
	for iteration in 30:
		var pending: Array=w.trains.values().duplicate()
		w.depot_reservations.clear()
		while not pending.is_empty():
			var t: Train=pending.pop_at(rng.randi_range(0,pending.size()-1))
			var choice:=Depot.choose(w,t)
			if choice.is_empty():return "No depot for %s in arrival order %d" % [t.id,iteration]
			w.depot_reservations[choice.road]=t.id
		if w.depot_reservations.size()!=32:return "Arrival order lost a depot lease"
	return true
