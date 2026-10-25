extends RefCounted
const Fixture := preload("res://tests/test_exit_capacity.gd")
const Planner := preload("res://sim/dispatch_planner.gd")

func fixture(full_exit: bool=true) -> RailWorld:
	var f:=Fixture.new();var w: RailWorld=f.fixture()
	f.add(w,"H",["NEM_P1","NYY_P1","PASA_P1","KZT_P1"],1)
	f.add(w,"S",["NYY_P1","PASA_P1","KZT_P1"],1)
	f.add(w,"N",["NYY_P2","NEM_P1","TVC_P2"],-1)
	f.add(w,"P1",["PASA_P1","NYY_P2","NEM_P1","TVC_P2"],-1)
	if full_exit:f.add(w,"P2",["PASA_P2","NYY_P2","NEM_P1","TVC_P2"],-1)
	f.add(w,"T",["TVC_P1","NEM_P2","NYY_P1","PASA_P1","KZT_P1"],1)
	return w

func available(w: RailWorld) -> bool:
	var t: Train=w.trains.T
	return Planner.new().candidates(w,t,w.next_signal(t).id).any(func(c):return c.available)

func test_same_direction_claim_cannot_clear_into_a_full_opposing_next_yard():
	return not available(fixture())

func test_free_downstream_berth_keeps_same_direction_drainage_available():
	return available(fixture(false))

func test_six_train_three_yard_queue_completes_without_a_cycle():
	var w:=fixture()
	w.dispatcher().future_clearances.enabled=true
	w.dispatcher().enabled=true
	for i in 5400:
		w.step(2.0)
		if not w.events.is_empty():return str(w.events)
		if w.trains.values().all(func(t):return t.service_complete):return true
	return "Downstream queue did not drain: "+str(w.dispatcher().states)
