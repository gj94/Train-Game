extends RefCounted
const InputData:=preload("res://sim/dispatch_forecast_input.gd")
const Worker:=preload("res://sim/dispatch_forecast_worker.gd")
const Policy:=preload("res://sim/priority_dispatch.gd")
const Snapshot:=preload("res://sim/world_snapshot.gd")

func restored(time: int=41700) -> RailWorld:
	return preload("res://tests/predictive_fixture.gd").build(time)

func prepare(w: RailWorld) -> Dictionary:
	var e=w.dispatcher();e.predictive.configure(true,false)
	var frame:=InputData.frame(w);frame.generation=e.predictive._generation
	return Worker.new(InputData.topology(w)).synchronous(frame)

func test_classic_is_the_default_and_forecasts_never_grant_authority():
	var w:=restored();var e=w.dispatcher()
	if e.predictive.enabled:return "Classic default changed"
	var before:=var_to_bytes(w.signals);var result:=prepare(w)
	e.predictive.accept(w,e,result)
	return before==var_to_bytes(w.signals) and e.predictive.plan(w,w.trains.K1).get("station","")=="STKT"

func test_future_loop_suppresses_earlier_hold_and_keeps_express_on_main():
	var w:=restored();var e=w.dispatcher();e.predictive.accept(w,e,prepare(w))
	var slow: Train=w.trains.K1;var fast: Train=w.trains.B002
	var here:=Policy.station(w,"KPY_P1");var next:=Policy.station(w,"STKT_P3")
	if e.predictive.choice(w,slow,fast,here)!=0:return "Did not allow onward running"
	if e.predictive.choice(w,slow,fast,next)!=1:return "Lost planned pass"
	return e.predictive.road(w,slow,"STKT")=="STKT_P3" and e.predictive.road(w,fast,"STKT")=="STKT_P1"

func test_stale_generation_and_future_dated_results_are_rejected():
	for kind in ["stale","future","generation"]:
		var w:=restored();var e=w.dispatcher();var result:=prepare(w)
		if kind=="stale":w.time+=16
		elif kind=="future":result.time+=1
		else:result.generation-=1
		e.predictive.accept(w,e,result)
		if not e.predictive.plans.is_empty():return "Accepted "+kind
	return true

func test_changed_train_or_operator_action_rejects_worker_result():
	for kind in ["delete","reverse","priority","manual","emergency","hold","platform","teleport","call"]:
		var w:=restored();var e=w.dispatcher();var result:=prepare(w);var t: Train=w.trains.B002
		match kind:
			"delete":w.trains.erase(t.id)
			"reverse":t.path[0].dir=-t.path[0].dir
			"priority":t.dispatch_priority=1
			"manual":t.automatic=false
			"emergency":t.emergency=true
			"hold":e.operator_holds[t.id]=true
			"platform":e.platform_preferences[t.id]={block="KPY_P4"}
			"teleport":t.head_s+=100
			"call":t.timetable.index+=1
		e.predictive.accept(w,e,result)
		if e.predictive.plans.has("K1"):return "Accepted changed "+kind
	return true

func test_an_already_committed_express_cannot_be_reordered_to_later_station():
	var w:=restored(42000);var e=w.dispatcher();e.predictive.accept(w,e,prepare(w))
	return not e.predictive.can_defer(w,w.trains.K1,w.dispatch_holds.K1)

func test_arrived_overtake_keeps_its_order_when_newer_plan_changes():
	var w:=preload("res://tests/overtake_fixture.gd").build();var e=w.dispatcher()
	e.predictive.configure(true,false);e.run_cycle()
	return w.dispatch_holds.has("K1") and w.signals["TUVR-S2"].route.is_empty()

func test_mode_change_discards_pending_plans_but_never_cancels_routes():
	var w:=restored();var e=w.dispatcher();e.predictive.accept(w,e,prepare(w))
	var routes:=var_to_bytes(w.signals)
	e.predictive.configure(false)
	return e.predictive.plans.is_empty() and routes==var_to_bytes(w.signals)

func test_new_road_claim_invalidates_advice_without_overriding_interlocking():
	var w:=restored();var e=w.dispatcher();e.predictive.accept(w,e,prepare(w))
	if e.predictive.plan(w,w.trains.K1).is_empty():return "No original plan"
	# Mimic the owner's refreshed reservation map after another service wins.
	e.predictive._road_owners.STKT_P3="B013";e.predictive._claims_dirty=false
	return e.predictive.plan(w,w.trains.K1).is_empty()

func test_predictive_mode_and_validated_plans_round_trip_without_worker_handles():
	var w:=restored();var e=w.dispatcher();e.predictive.accept(w,e,prepare(w))
	var saved:=Snapshot.capture(w);var loaded:=Snapshot.restore(saved)
	if not loaded.ok:return loaded.reason
	if not loaded.world.dispatcher().predictive.enabled:return "Lost V2 mode"
	return var_to_bytes(saved)==var_to_bytes(Snapshot.capture(loaded.world)) and loaded.world.dispatcher().predictive._worker==null

func test_missing_extension_stays_classic_and_malformed_plans_are_rejected():
	var w:=restored();var e=w.dispatcher();e.predictive.accept(w,e,prepare(w))
	var saved:=Snapshot.capture(w);saved.erase("predictive")
	var loaded:=Snapshot.restore(saved)
	if not loaded.ok or loaded.world.dispatcher().predictive.enabled:return "Old save was silently changed to V2"
	saved=Snapshot.capture(w);saved.predictive.plans.K1.passing_road="missing"
	return not Snapshot.restore(saved).ok

func test_event_rollback_restores_plans_and_keeps_offline_execution():
	var w:=restored();var e=w.dispatcher();e.predictive.accept(w,e,prepare(w))
	e.predictive.execution(false,2)
	var history:=preload("res://sim/skip_history.gd").new()
	var state:=history.capture(w);var plans: Dictionary=e.predictive.checkpoint()
	w.time+=2;e.predictive.plans.clear()
	history.restore(w,state)
	return e.predictive.checkpoint()==plans and not e.predictive.asynchronous and e.predictive.offline_workers==2

func test_worker_time_skip_matches_inline_v2_and_restores_live_async_mode():
	var a:=restored();var b:=restored()
	a.dispatcher().predictive.configure(true,false);b.dispatcher().predictive.configure(true,true)
	var serial:=preload("res://sim/time_skip.gd").new(a)
	var background:=preload("res://sim/time_skip.gd").new(b)
	serial.to_time(a.clock_seconds()+20);background.to_time(b.clock_seconds()+20)
	while not serial.done:serial.step()
	var worker:=preload("res://sim/time_skip_worker.gd").new()
	if worker.start(background)!=OK:return "Could not start predictive time skip"
	var completed:={};var deadline:=Time.get_ticks_msec()+20000
	while completed.is_empty() and Time.get_ticks_msec()<deadline:
		completed=worker.take()
		if completed.is_empty():OS.delay_msec(1)
	if completed.is_empty():worker.close();return "Predictive skip timed out"
	return b.dispatcher().predictive.asynchronous and Snapshot.capture(a)==Snapshot.capture(b)

func test_every_accepted_contender_is_revalidated_until_plan_expires():
	for change in ["manual","hold","priority","delete","call","speed_cap"]:
		var w:=restored();var e=w.dispatcher()
		var other:=Train.new("RELIEF",1);preload("res://sim/stock/ported_stock.gd").configure(other,"lhb","express")
		other.automatic=true;other.dispatch_priority=70
		w.place_train(other,"KYJ_P1",preload("res://sim/berth_clearance.gd").marker(w,other,"KYJ_P1",1),1)
		other.timetable=preload("res://sim/timetable.gd").new()
		Snapshot.apply(other.timetable,Snapshot.fields(w.trains.B002.timetable,Snapshot.TIMETABLE),Snapshot.TIMETABLE)
		e.predictive.accept(w,e,prepare(w))
		if not e.predictive.plans.has("K1") or "RELIEF" not in e.predictive.plans.K1.participants:return "No multi-contender certificate"
		match change:
			"manual":other.automatic=false
			"hold":e.operator_holds.RELIEF=true
			"priority":other.dispatch_priority=90
			"delete":w.trains.erase(other.id)
			"call":other.timetable.index+=1
			"speed_cap":other.max_speed=20
		if not e.predictive.plan(w,w.trains.K1).is_empty():return "Ignored changed third contender: "+change
	return true
