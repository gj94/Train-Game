extends RefCounted
const Pax:=preload("res://sim/passenger_service.gd")
const Stock:=preload("res://sim/stock/ported_stock.gd")

func fixture() -> RailWorld:
	var w:=RailWorld.new();w.graph.add_node("a",Vector3.ZERO);w.graph.add_node("b",Vector3(1200,0,0));w.graph.add_edge("P","a","b")
	w.scenery.geographic=true
	w.stations=[{code="TEST",name="Test",major=true,platform_tracks=["P"],platform_details={P={platform_width=5.0,platform_side=1}}}]
	var t:=Train.new("PAX",192);Stock.configure(t,"vb8");w.place_train(t,"P",696,1)
	t.timetable=preload("res://sim/timetable.gd").new()
	t.timetable.departure=w.clock_seconds()
	t.timetable.stops=[{block="P",name="Origin",direction=1,s=696.0,minutes_from_origin=0,dwell_minutes=0},{block="P",name="Middle",direction=1,s=696.0,minutes_from_origin=5,dwell_minutes=1},{block="P",name="Terminal",direction=1,s=696.0,minutes_from_origin=10,dwell_minutes=0}]
	t.timetable.actual_arrivals.assign([-1.0,-1.0,-1.0]);t.timetable.actual_departures.assign([-1.0,-1.0,-1.0])
	return w

func test_origin_has_destination_bound_passengers_and_exact_model_capacity():
	var w:=fixture();var t: Train=w.trains.PAX;Pax.update(w,t,.05)
	var catalog: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://assets/models/ported/manifest.json"))
	for model in Pax.CAPACITY:
		if Pax.CAPACITY[model]!=catalog[model].passengers.size():return "Capacity mismatch "+model
	return t.passengers.onboard>0 and t.passengers.events.all(func(e):return e.kind=="board" and e.destination>0)

func test_exchange_interlocks_manual_traction_until_every_door_closes():
	var w:=fixture();var t: Train=w.trains.PAX
	w.step(.05);t.controller=1;w.step(1)
	if t.speed!=0 or not Pax.departure_blocked(t):return "Departed during boarding"
	Pax.update(w,t,120)
	return not Pax.departure_blocked(t) and t.passengers.door_open==0 and t.passengers.boarded>0

func test_unscheduled_free_drive_has_riders_without_a_departure_hold():
	var w:=fixture();var t: Train=w.trains.PAX;t.timetable=null
	Pax.update(w,t,1)
	return t.passengers.onboard>0 and not Pax.departure_blocked(t) and conservation(t)

func test_alight_before_boarding_and_never_sell_the_same_seat_twice():
	var w:=fixture();var t: Train=w.trains.PAX;Pax.update(w,t,.05);Pax.update(w,t,120)
	t.timetable.index=1;Pax.update(w,t,.05)
	for board in t.passengers.events:
		if board.kind!="board":continue
		for off in t.passengers.events:
			if off.kind=="alight" and off.car==board.car and off.door==board.door and off.end>board.begin:return "Boarding before alighting"
	Pax.update(w,t,180)
	return conservation(t)

func test_dispatch_departure_forecast_includes_the_door_closing_time():
	var w:=fixture();var t: Train=w.trains.PAX;Pax.update(w,t,0)
	return is_equal_approx(t.timetable.release_time(),w.clock_seconds()+t.passengers.duration)

func test_terminal_unloads_everyone_and_never_boards_depot_passengers():
	var w:=fixture();var t: Train=w.trains.PAX;Pax.update(w,t,.05);Pax.update(w,t,120)
	t.timetable.index=2;t.service_complete=true;Pax.update(w,t,.05)
	if t.passengers.events.any(func(e):return e.kind=="board"):return "Terminal boarding"
	Pax.update(w,t,180)
	return t.passengers.onboard==0 and conservation(t) and t.passengers.cars.all(func(c):return c.seats.all(func(d):return d<0))

func test_no_exchange_while_moving_at_signals_or_without_a_platform():
	var w:=fixture();var t: Train=w.trains.PAX;t.speed=1;Pax.update(w,t,1)
	if Pax.departure_blocked(t):return "Moving exchange"
	t.speed=0;w.stations[0].platform_details.P.platform_width=0;Pax.update(w,t,1)
	if Pax.departure_blocked(t):return "Through-road boarding"
	w.stations[0].platform_details.P.platform_width=5;t.head_s=100;Pax.update(w,t,1)
	return not Pax.departure_blocked(t)

func test_paused_time_and_fast_forward_preserve_the_same_journeys():
	var a:=fixture();var b:=fixture();var ta: Train=a.trains.PAX;var tb: Train=b.trains.PAX
	Pax.update(a,ta,0);Pax.update(b,tb,0)
	var before:=ta.passengers.duplicate(true);Pax.update(a,ta,0)
	if ta.passengers!=before:return "Pause changed passengers"
	for i in 2400:Pax.update(a,ta,.05)
	Pax.update(b,tb,120)
	return ta.passengers.cars==tb.passengers.cars and ta.passengers.onboard==tb.passengers.onboard and conservation(ta)

func test_mid_exchange_interruption_does_not_duplicate_or_lose_people():
	var w:=fixture();var t: Train=w.trains.PAX;Pax.update(w,t,0);Pax.update(w,t,120)
	t.timetable.index=1;Pax.update(w,t,0);Pax.update(w,t,7);t.speed=2;Pax.update(w,t,.05)
	return t.passengers.phase=="interrupted" and conservation(t)

func test_station_layout_paths_cover_every_model_seat_and_door():
	var routes: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/interiors/passenger_paths.json"))
	for model in Pax.CAPACITY:
		if not routes.has(model) or routes[model].unreachable!=0:return "Missing route "+model
		for door in routes[model].paths:
			if door.size()!=Pax.CAPACITY[model] or door.any(func(path):return path.is_empty()):return "Missing seat access "+model
	return true

func conservation(t: Train):
	var p:=t.passengers;var seated:=0;var transferring:=0
	for car in p.cars:
		for d in car.seats:seated+=int(d>=0)
	for e in p.events:transferring+=int(e.kind=="alight" and e.state==1)
	return seated+transferring==p.onboard and p.initial+p.boarded-p.alighted==p.onboard
