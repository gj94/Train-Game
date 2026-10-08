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
