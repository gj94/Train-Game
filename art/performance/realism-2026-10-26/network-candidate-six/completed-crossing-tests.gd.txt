extends RefCounted
const Fixture := preload("res://tests/test_exit_capacity.gd")
const Snapshot := preload("res://sim/world_snapshot.gd")

func _received_world() -> RailWorld:
	var f:=Fixture.new();var w: RailWorld=f.fixture()
	f.add(w,"I",["NYY_P1","PASA_P1","NCJ_P1"],1)
	f.add(w,"O",["NYY_P2","NEM_P2","TVC_P2"],-1)
	f.add(w,"V",["PASA_P1","ERL_P1","NCJ_P1"],1)
	w.dispatcher().future_clearances.plans=[{station="NYY",escape_station="PASA",incoming="I",opponent="O",vacater="V",
		future_road="NYY_P1",opponent_road="NYY_P2",escape_road="PASA_P1",approach_section="NEM_single",escape_section="NYY_single",
		direction=1,received=false,opponent_received=false,escaped=false,created=w.time}]
	return w

func test_completed_arrivals_release_virtual_claims_without_waiting_for_opponent_departure():
	var w:=_received_world();var e=w.dispatcher()
	var routes:=var_to_bytes(w.signals);var occupied:=w.occupancy().duplicate()
	e.future_clearances.update(w,e,false)
	if not e.future_clearances.plans.is_empty():return "Completed crossing still reserves the cleared escape corridor"
	if var_to_bytes(w.signals)!=routes or w.occupancy()!=occupied:return "Completing a promise changed physical protection"
	return e.future_clearances.owner("PASA_P1").is_empty() and e.future_clearances.owner("NYY_P1").is_empty() and w.occupancy().NYY_P2=="O"

func test_restored_completed_plan_cannot_reserve_an_escape_berth_the_vacater_has_left():
	var w:=_received_world();var p: Dictionary=w.dispatcher().future_clearances.plans[0]
	p.received=true;p.opponent_received=true;p.escaped=true
	w.place_train(w.trains.V,"ERL_P1",700,1)
	var restored: Dictionary=Snapshot.restore(Snapshot.capture(w))
	if not restored.ok:return restored.reason
	w=restored.world;var e=w.dispatcher()
	e.future_clearances.update(w,e,false)
	return e.future_clearances.plans.is_empty() and e.future_clearances.owner("PASA_P1").is_empty()

func test_escape_tail_must_arrive_before_the_crossing_promise_completes():
	var w:=_received_world();var e=w.dispatcher()
	w.trains.V.path=[{edge="PASA_P1",dir=1},{edge="DAVM_PASA_M5",dir=1}]
	e.future_clearances.update(w,e,false)
	if e.future_clearances.plans.is_empty():return "Released crossing while the vacater tail still occupied the approach"
	if e.future_clearances.plans[0].escaped:return "Tail on approach counted as fully berthed"
	w.trains.V.path=[{edge="PASA_P1",dir=1}]
	e.future_clearances.update(w,e,false)
	return e.future_clearances.plans.is_empty()
