extends RefCounted
func fixture() -> RailWorld:
	var w:=RailWorld.new()
	for i in 5:w.graph.add_node(str(i),Vector3(i*600,0,0))
	for i in 4:w.graph.add_edge("e"+str(i),str(i),str(i+1))
	w.add_signal("AUTO","e0",1);w.automatic_signals.append("AUTO")
	w.add_signal("HOME","e1",1);w.add_signal("STARTER","e2",1)
	var t:=Train.new("T",100);w.place_train(t,"e0",500,1)
	t.timetable=preload("res://sim/timetable.gd").new()
	t.timetable.configure({departure="08:00",stops=[{block="e0",minutes_from_origin=0},{block="e2",minutes_from_origin=2}]},w,t)
	t.timetable.index=1;t.timetable.at_stop=false;t.automatic=true
	w._update_automatic_blocks()
	return w

func test_free_home_is_prepared_before_passing_approach_signal():
	var w:=fixture();w.dispatcher().run_cycle(true)
	return w.aspect("HOME")==RailWorld.Aspect.YELLOW and w.aspect("AUTO")==RailWorld.Aspect.GREEN

func test_prepared_home_keeps_starter_red_for_booked_stop():
	var w:=fixture();w.dispatcher().run_cycle(true)
	return w.signals.STARTER.route.is_empty() and w.aspect("STARTER")==RailWorld.Aspect.RED

func test_occupied_platform_keeps_approach_yellow_and_home_red():
	var w:=fixture();w.place_train(Train.new("occupied",80),"e2",200,1)
	w.dispatcher().run_cycle(true)
	return w.aspect("AUTO")==RailWorld.Aspect.YELLOW and w.aspect("HOME")==RailWorld.Aspect.RED

func test_operator_red_and_train_hold_block_lookahead():
	var w:=fixture();w.dispatcher().inhibited_signals.HOME=true;w.dispatcher().run_cycle(true)
	if not w.signals.HOME.route.is_empty():return "Operator red overridden"
	w.dispatcher().inhibited_signals.clear();w.dispatcher().operator_holds.T=true;w.dispatcher().run_cycle(true)
	return w.signals.HOME.route.is_empty()

func test_no_speculative_route_beyond_red_or_occupied_approach():
	var w:=fixture();w.place_train(Train.new("ahead",80),"e1",200,1)
	w.dispatcher().run_cycle(true)
	return w.signals.HOME.route.is_empty()

func test_manual_player_gets_same_lookahead_but_unsupervised_manual_does_not():
	var w:=fixture();w.trains.T.automatic=false;w.dispatcher().run_cycle(true)
	if not w.signals.HOME.route.is_empty():return "Unassigned manual train routed"
	w.dispatcher().manual_service="T";w.dispatcher().run_cycle(true)
	return not w.signals.HOME.route.is_empty() and not w.trains.T.automatic

func test_read_only_assessment_does_not_prepare_route():
	var w:=fixture();w.dispatcher().run_cycle(false)
	return w.signals.HOME.route.is_empty()

func test_lookahead_cannot_skip_a_booked_call_on_approach():
	var w:=fixture();w.trains.T.timetable.stops[1].block="e1";w.trains.T.timetable.stops[1].s=300
	w.dispatcher().run_cycle(true)
	return w.signals.HOME.route.is_empty()

func long_approach(direction: int=1) -> RailWorld:
	var w:=RailWorld.new()
	for i in 7:w.graph.add_node(str(i),Vector3(i*1000,0,0))
	for i in 6:w.graph.add_edge("e"+str(i),str(i),str(i+1))
	for i in 4:
		w.add_signal("A"+str(i),"e"+str(i if direction==1 else 5-i),direction,60);w.automatic_signals.append("A"+str(i))
	var origin:="e0" if direction==1 else "e5"
	var platform:="e5" if direction==1 else "e0"
	w.add_signal("HOME","e4" if direction==1 else "e1",direction,60);w.add_signal("STARTER",platform,direction,60)
	var t:=Train.new("T",100);w.place_train(t,origin,800 if direction==1 else 200,direction)
	t.timetable=preload("res://sim/timetable.gd").new()
	t.timetable.configure({departure="08:00",stops=[{block=origin,direction=direction,minutes_from_origin=0},{block=platform,direction=direction,minutes_from_origin=6}]},w,t)
	t.timetable.index=1;t.timetable.at_stop=false;t.automatic=true;t.speed=25
	w._update_automatic_blocks()
	return w

func test_station_route_prepared_across_multiple_clear_automatic_blocks():
	var w:=long_approach();w.dispatcher().run_cycle(true)
	return w.aspect("HOME")==RailWorld.Aspect.YELLOW and w.aspect("A3")==RailWorld.Aspect.GREEN and w.aspect("STARTER")==RailWorld.Aspect.RED

func test_dispatch_advice_reports_the_full_clearance_to_the_platform_starter():
	var w:=long_approach();var e=w.dispatcher();e.run_cycle(true)
	return e.states.T.reason=="Authority to STARTER" and e.states.T.destination=="A1"

func test_prepared_platform_is_counted_once_for_its_distant_approaching_train():
	var w:=long_approach();w.dispatcher().run_cycle(true)
	var planner=preload("res://sim/dispatch_planner.gd").new()
	var committed: Array=planner._committed_routes(w,w.trains.T)
	var owners: Dictionary=planner._road_owners(w,{platform_tracks=["e5"]})
	return committed.filter(func(p):return p.edge=="e5").size()==1 and owners.get("e5","")=="T"

func test_approach_distance_includes_signal_setbacks():
	for direction in [1,-1]:
		var w:=long_approach(direction)
		var approach: Array=preload("res://sim/dispatch_planner.gd").new().approach_signals(w,w.trains.T)
		if approach.size()!=5 or approach[-1].id!="HOME" or not is_equal_approx(approach[-1].distance,4140.0):return "Incorrect distance in direction "+str(direction)
	return true

func test_future_forecast_cannot_replace_a_distant_prepared_platform():
	var w:=long_approach();w.dispatcher().run_cycle(true)
	return preload("res://sim/future_clearance.gd").new()._arrival_fixed(w,w.trains.T,{platform_tracks=["e5"]})

func test_early_preparation_cannot_look_past_a_leading_train():
	var w:=long_approach();w.place_train(Train.new("LEAD",100),"e2",500,1)
	w.dispatcher().run_cycle(true)
	return w.signals.HOME.route.is_empty()

func test_early_preparation_respects_intermediate_stop_and_operator_red():
	var w:=long_approach()
	w.trains.T.timetable.stops[1].block="e2";w.trains.T.timetable.stops[1].s=500
	w.dispatcher().run_cycle(true)
	if not w.signals.HOME.route.is_empty():return "Prepared past a booked stop"
	w=long_approach();w.dispatcher().inhibited_signals.A2=true
	w.dispatcher().run_cycle(true)
	return w.signals.HOME.route.is_empty()

func test_slow_or_standing_train_does_not_lock_a_distant_station():
	var w:=long_approach();w.trains.T.speed=0
	w.dispatcher().run_cycle(true)
	return w.signals.HOME.route.is_empty()
