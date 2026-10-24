extends RefCounted
const Solver:=preload("res://sim/overtake_solver.gd")
const Worker:=preload("res://sim/dispatch_forecast_worker.gd")

func fixture() -> Dictionary:
	var edges:={}
	for item in [["F",-5000.0,0.0],["A_P1",0.0,1000.0],["A_P3",0.0,1000.0],["AB",1000.0,6000.0],["B_P1",6000.0,7000.0],["B_P3",6000.0,7000.0]]:
		edges[item[0]]={length=item[2]-item[1],limit=30.0,start=item[1],end=item[2],station=item[0].get_slice("_P",0) if "_P" in item[0] else "",next={"1":[],"-1":[]}}
	for pair in [["F","A_P1"],["F","A_P3"],["A_P1","AB"],["A_P3","AB"],["AB","B_P1"],["AB","B_P3"]]:
		edges[pair[0]].next["1"].append({edge=pair[1],dir=1});edges[pair[1]].next["-1"].append({edge=pair[0],dir=-1})
	edges.A_P3.limit=11.0;edges.B_P3.limit=11.0
	var stations:=[]
	for code in ["A","B"]:
		var roads:=[]
		for index in [1,3]:roads.append({id=code+"_P"+str(index),main=index==1,lane="D",storage=false,bounds=[50.0,950.0],platform=[100.0,900.0],passenger=true})
		stations.append({code=code,name=code,s=500.0 if code=="A" else 6500.0,half=500.0,halt=false,roads=roads})
	var slow:={id="S",edge="A_P1",head_s=700.0,direction=1,chainage=700.0,clock=0.0,speed=0.0,length=400.0,max_speed=30.0,accel=.6,power=5000000.0,mass=500000.0,decel=.9,
		calls=[{code="B",road="B_P3",s=700.0,chainage=6700.0,arrival=0.0,departure=0.0,dwell=120.0,final=false}],priority=20,at_stop=true,release=20.0,
		current_call={code="A",road="A_P1",dwell=120.0,departure=20.0,final=false},manual=false,emergency=false,missed=false,operator_hold=false,crossing=false,platform_override=false,call_index=1}
	var fast: Dictionary=slow.duplicate(true)
	fast.merge({id="F",edge="F",head_s=500.0,chainage=-4500.0,speed=25.0,priority=90,at_stop=false,release=0.0,
		calls=[{code="A",road="A_P1",s=700.0,chainage=700.0,arrival=0.0,departure=350.0,dwell=90.0,final=false}]},true)
	return {topology={edges=edges,stations=stations},frame={clock=0.0,time=0.0,trains=[slow,fast],occupied={A_P1="S"},claims={},holds={}}}

func test_booked_loop_stop_is_preferred_to_holding_on_main_one_station_earlier():
	var f:=fixture();var plans: Array=Solver.new(f.topology).solve(f.frame).plans
	return plans.size()==1 and plans[0].station=="B" and plans[0].road=="B_P3" and plans[0].passing_road=="B_P1" and not plans[0].express_stop and plans[0].margin>=0

func test_unavailable_or_short_next_loop_does_not_justify_departure():
	for occupied in [true,false]:
		var f:=fixture()
		if occupied:f.frame.occupied.B_P3="UNKNOWN"
		else:f.topology.stations[1].roads[1].platform=[400.0,600.0]
		var plans: Array=Solver.new(f.topology).solve(f.frame).plans
		if plans.is_empty() or plans[0].station!="A":return "Unusable B selected"
	return true

func test_close_express_cannot_be_sent_behind_slow_train_to_next_loop():
	var f:=fixture();var fast: Dictionary=f.frame.trains[1]
	fast.calls=[];fast.head_s=4500.0;fast.chainage=-500.0
	var plans: Array=Solver.new(f.topology).solve(f.frame).plans
	return plans.size()==1 and plans[0].station=="A"

func test_opposing_or_lower_priority_train_does_not_create_overtake():
	for key in ["direction","priority"]:
		var f:=fixture();f.frame.trains[1][key]=-1 if key=="direction" else 10
		if not Solver.new(f.topology).solve(f.frame).plans.is_empty():return "Invalid overtaker"
	return true

func test_operator_crossing_and_platform_commitments_are_respected():
	for key in ["operator_hold","crossing","platform_override","emergency","missed"]:
		var f:=fixture();f.frame.trains[0][key]=true
		if not Solver.new(f.topology).solve(f.frame).plans.is_empty():return "Overrode "+key
	return true

func test_a_second_closer_express_prevents_unsafe_defer():
	var f:=fixture();var second: Dictionary=f.frame.trains[1].duplicate(true)
	second.id="CLOSE";second.calls=[];second.head_s=4500.0;second.chainage=-500.0
	f.frame.trains.append(second)
	var plans: Array=Solver.new(f.topology).solve(f.frame).plans
	var own: Array=plans.filter(func(p):return p.train=="S")
	return own.size()==1 and own[0].station=="A" and own[0].other=="CLOSE"

func test_async_matches_inline_uses_worker_thread_and_detaches_input():
	var f:=fixture();var worker:=Worker.new(f.topology)
	var expected:=worker.synchronous(f.frame)
	if not worker.submit(f.frame):return "Worker refused job"
	if worker.submit(f.frame):worker.close();return "Unbounded work queue"
	f.frame.trains[0].priority=100;f.topology.stations.clear()
	var result:={};var deadline:=Time.get_ticks_msec()+5000
	while result.is_empty() and Time.get_ticks_msec()<deadline:
		result=worker.take()
		if result.is_empty():OS.delay_msec(1)
	worker.close()
	return not result.is_empty() and result.plans==expected.plans and OS.get_thread_caller_id() not in result.worker_threads

func test_worker_shutdown_joins_pending_jobs_and_is_reusable():
	var f:=fixture();var worker:=Worker.new(f.topology)
	if not worker.submit(f.frame):return false
	worker.close()
	if worker.busy() or not worker.take().is_empty():return false
	var okay:=worker.submit(f.frame);worker.close();return okay

func test_offline_parallel_completion_preserves_order_and_uses_other_cores():
	var f:=fixture();var worker:=Worker.new(f.topology)
	var expected:=worker.synchronous(f.frame);var result:=worker.parallel_complete(f.frame,2)
	return result.plans==expected.plans and OS.get_thread_caller_id() not in result.worker_threads and not worker.busy()

func test_northbound_mirrored_railway_chooses_same_stop_with_equal_eta():
	var south:=fixture();var north:=fixture()
	for edge: Dictionary in north.topology.edges.values():
		var old_start: float=edge.start;edge.start=10000-edge.end;edge.end=10000-old_start
		var old_next: Dictionary=edge.next.duplicate(true)
		edge.next={"1":old_next["-1"],"-1":old_next["1"]}
		for entries: Array in edge.next.values():
			for entry: Dictionary in entries:entry.dir=-entry.dir
	for station: Dictionary in north.topology.stations:
		station.s=10000-station.s
		for road: Dictionary in station.roads:road.lane="U"
	for train_data: Dictionary in north.frame.trains:
		train_data.direction=-1;train_data.chainage=10000-train_data.chainage
		train_data.head_s=north.topology.edges[train_data.edge].length-train_data.head_s
		for call: Dictionary in train_data.calls:
			call.s=north.topology.edges[call.road].length-call.s;call.chainage=10000-call.chainage
	var a: Array=Solver.new(south.topology).solve(south.frame).plans
	var b: Array=Solver.new(north.topology).solve(north.frame).plans
	if a.size()!=1 or b.size()!=1:return "Missing directional plan"
	return b[0].station=="B" and b[0].road=="B_P3" and b[0].passing_road=="B_P1" and b[0].direction==-1 and is_equal_approx(a[0].margin,b[0].margin) and is_equal_approx(a[0].wait,b[0].wait)

func test_future_main_only_station_cannot_supply_an_imaginary_passing_loop():
	var f:=fixture();f.topology.stations[1].roads.resize(1)
	var plans: Array=Solver.new(f.topology).solve(f.frame).plans
	return plans.size()==1 and plans[0].station=="A"

func test_unresolved_third_follower_prevents_certifying_a_later_pass():
	var f:=fixture();var ghost: Dictionary=f.frame.trains[1].duplicate(true)
	ghost.id="STRANDED";ghost.edge="ISLAND";ghost.chainage=-1000.0
	f.topology.edges.ISLAND={length=1000.0,limit=30.0,start=-1500.0,end=-500.0,station="",next={"1":[],"-1":[]}}
	f.frame.trains.append(ghost)
	var plans: Array=Solver.new(f.topology).solve(f.frame).plans
	return plans.filter(func(p):return p.train=="S").is_empty()

func test_operator_held_road_owner_cannot_be_assumed_to_vacate():
	var f:=fixture();var occupant: Dictionary=f.frame.trains[0].duplicate(true)
	occupant.id="HELD";occupant.edge="B_P3";occupant.chainage=6700.0;occupant.operator_hold=true
	f.frame.trains.append(occupant);f.frame.occupied.B_P3="HELD"
	var own: Array=Solver.new(f.topology).solve(f.frame).plans.filter(func(p):return p.train=="S")
	return own.size()==1 and own[0].station=="A"

func test_express_ending_before_next_loop_cannot_be_projected_beyond_its_service():
	var f:=fixture();f.frame.trains[1].calls[0].final=true
	var plans: Array=Solver.new(f.topology).solve(f.frame).plans
	return plans.all(func(p):return p.station!="B")

func test_stationary_manual_passenger_has_no_assumed_departure_for_a_future_loop():
	var f:=fixture();f.frame.trains[0].manual=true
	var plans: Array=Solver.new(f.topology).solve(f.frame).plans
	return plans.all(func(p):return p.station=="A")

func test_stationary_manual_express_has_no_assumed_catch_up_time():
	var f:=fixture();f.frame.trains[1].manual=true;f.frame.trains[1].speed=0.0
	return Solver.new(f.topology).solve(f.frame).plans.is_empty()
