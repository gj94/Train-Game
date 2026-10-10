extends RefCounted
const Snapshot := preload("res://sim/world_snapshot.gd")
const Advance := preload("res://sim/time_skip.gd")
const Fixture := preload("res://tests/test_time_skip.gd")

func test_multicore_and_serial_preparation_match_original_complete_state():
	var expected:={}
	for workers in [0,1,2,4]:
		var w: RailWorld=Fixture.new().fixture();w.simulation_workers=workers
		var advance:=Advance.new(w);advance.to_time(w.clock_seconds()+650)
		while not advance.done:advance.step()
		var state: Dictionary=Snapshot.capture(w)
		if workers==0:expected=state
		elif state!=expected:return "State diverged with %d workers" % workers
	return true

func test_pool_runs_lookahead_off_owner_without_world_mutations():
	var w:=preload("res://sim/layouts/southern_corridor.gd").build_dispatch()
	for t in w.trains.values():t.automatic=true;t.timetable=null;t.speed=12
	var before: Dictionary=Snapshot.capture(w)
	var frame:=preload("res://sim/parallel_lookahead.gd").new()
	var results:=frame.prepare(w,w.active_trains(),4,true)
	var identities:={}
	for result in results:
		if not result.is_empty():identities[result.thread]=true
	# The pool may schedule all six tiny jobs on one available worker. Verify
	# worker ownership here; sustained native/benchmark runs record distribution.
	return Snapshot.capture(w)==before and not identities.is_empty() and not identities.has(OS.get_main_thread_id()) and frame.world==null

func test_live_signal_aspects_override_precomputed_candidates():
	var w: RailWorld=Fixture.new().fixture()
	var t: Train=w.trains.T1
	t.timetable=null;t.automatic=true;t.speed=12;t.controller=.2
	w.set_route("CPM-S1","MRT-HE")
	var frame:=preload("res://sim/parallel_lookahead.gd").new()
	var prepared:=frame.prepare(w,[t],2)[0]
	# Revoke authority AFTER the read-only phase. Both paths must see the red.
	w.signals["CPM-S1"].cleared=false
	w._drive_automatic(t,.05,prepared)
	var result:=[t.controller,t.status]
	t.controller=.2
	w._drive_automatic(t,.05)
	return result==[t.controller,t.status]

func test_new_occupancy_after_preparation_still_brakes_the_driver():
	var w:=RailWorld.new()
	for i in 3:w.graph.add_node(str(i),Vector3(i*1000,0,0))
	w.graph.add_edge("approach","0","1");w.graph.add_edge("ahead","1","2")
	var t:=Train.new("FOLLOW",50);w.place_train(t,"approach",900,1)
	t.automatic=true;t.speed=15
	var frame:=preload("res://sim/parallel_lookahead.gd").new()
	var prepared:=frame.prepare(w,[t],2)[0]
	# Another train enters the next block after this driver's look-ahead task.
	w.place_train(Train.new("LEAD",50),"ahead",100,1)
	w._drive_automatic(t,.05,prepared)
	var result:=[t.controller,t.status]
	t.controller=0
	w._drive_automatic(t,.05)
	return t.controller==-1 and result==[t.controller,t.status]

func test_switching_execution_strategy_keeps_existing_world_state():
	var expected:={}
	for multicore in [false,true]:
		var w: RailWorld=Fixture.new().fixture();w.simulation_workers=0
		var advance:=Advance.new(w);advance.to_time(w.clock_seconds()+650)
		while not advance.done:
			if multicore:w.simulation_workers=4 if int(w.time/100)%2==1 else 0
			advance.step()
		var state: Dictionary=Snapshot.capture(w)
		if not multicore:expected=state
		elif state!=expected:return "Changing the worker count altered the railway"
	return true

func test_six_service_crossings_and_passengers_match_with_parallel_workers():
	var expected:={}
	for count in [0,2,4]:
		var w:=preload("res://sim/layouts/southern_corridor.gd").build_dispatch()
		w.simulation_workers=count
		var advance:=Advance.new(w);advance.to_time(w.clock_seconds()+900)
		while not advance.done:advance.step()
		var state: Dictionary=Snapshot.capture(w)
		if count==0:expected=state
		elif state!=expected:return "Six-service state diverged with %d workers" % count
	return true

func test_passenger_release_is_committed_only_at_the_original_train_turn():
	var w:=preload("res://tests/test_passenger_service.gd").new().fixture()
	var t: Train=w.trains.PAX
	var before: float=t.timetable.passenger_release
	var frame:=preload("res://sim/parallel_lookahead.gd").new()
	var result:=frame.prepare(w,[t],2,false,.05)[0]
	if t.timetable.passenger_release!=before or result.passenger_release<=w.clock_seconds():return "Worker exposed a new timetable dwell before commit"
	preload("res://sim/passenger_service.gd").commit_release(t,result.passenger_release)
	return t.timetable.passenger_release==result.passenger_release and t.passengers.phase=="opening"

func test_pool_can_run_inside_skip_worker_and_cancel_without_deadlock():
	var w:=RailWorld.new();w.simulation_workers=4;w.trace_parallel=true
	for i in 4:
		var id:=str(i)
		w.graph.add_node("a"+id,Vector3(0,0,i*10));w.graph.add_node("b"+id,Vector3(100000,0,i*10))
		w.graph.add_edge(id,"a"+id,"b"+id)
		var t:=Train.new(id,100);w.place_train(t,id,200,1);t.speed=10
	var advance:=Advance.new(w);advance.to_time(w.clock_seconds()+86400)
	var worker:=preload("res://sim/time_skip_worker.gd").new()
	if worker.start(advance)!=OK:return false
	OS.delay_msec(40)
	worker.request_cancel()
	var result: Dictionary=preload("res://tests/test_time_skip_worker.gd").new().complete(worker)
	return not result.is_empty() and result.trial.done and not result.trial.ok and w.parallel_threads.size()>1 and w.events.is_empty()
