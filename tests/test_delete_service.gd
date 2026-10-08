extends RefCounted
const Fixture:=preload("res://tests/test_receiving_capacity.gd")

func test_delete_rejects_missing_current_and_last_service():
	var w:=Fixture.new().fixture();var e=w.dispatcher();e.manual_service="K1"
	if e.delete_service("K1").ok or e.delete_service("missing").ok or e.delete_service("K2","K2").ok:return "Protected service deleted"
	w.trains.erase("K1");w.trains.erase("K3");e.manual_service=""
	return not e.delete_service("K2").ok

func test_deleted_service_leaves_no_occupation_or_owned_route():
	var w:=Fixture.new().fixture();var e=w.dispatcher()
	w.signals["TUVR-N3"].owner="K2"
	w.signals["TUVR-N3"].route=[{edge="EZP_TUVR_M3",dir=-1,switch="",seen=false}]
	if not e.delete_service("K2","K1").ok:return "Delete refused"
	return not w.trains.has("K2") and "K2" not in w.occupancy().values() and w.signals["TUVR-N3"].route.is_empty() and w.signals["TUVR-N3"].owner.is_empty()

func test_deletion_preserves_other_train_authority():
	var w:=Fixture.new().fixture();var e=w.dispatcher();e.future_clearances.enabled=true;e.run_cycle(true)
	var before: Array=w.signals["ERS-S1"].route.duplicate(true)
	if not e.delete_service("K2","K1").ok:return "Delete refused"
	return w.signals["ERS-S1"].route==before and not before.is_empty()

func test_deletion_clears_crossing_holds_and_future_reservations():
	var w:=Fixture.new().fixture();var e=w.dispatcher();e.future_clearances.enabled=true;e.run_cycle(true)
	w.dispatch_holds.K1={other="K3",kind="crossing"}
	e.operator_holds.K3=true;e.platform_preferences.K3={block="TUVR_P2"}
	if not e.delete_service("K3","K1").ok:return "Delete refused"
	return e.future_clearances.plans.is_empty() and not w.dispatch_holds.has("K1") and not e.operator_holds.has("K3") and not e.platform_preferences.has("K3") and not e.states.has("K3")

func test_deleted_parked_service_can_unblock_a_receiving_platform():
	var w:=Fixture.new().fixture();var e=w.dispatcher()
	w.place_train(w.trains.K2,"KUMM_P2",400,-1)
	e.run_cycle(true)
	if not w.signals["ERS-S1"].route.is_empty():return "Initial platform obstruction absent"
	if not e.delete_service("K2","K1").ok:return "Delete refused"
	e.run_cycle(true)
	return not w.signals["ERS-S1"].route.is_empty() and w.events.is_empty()
