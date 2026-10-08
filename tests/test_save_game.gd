extends RefCounted
const Snapshot:=preload("res://sim/world_snapshot.gd")
const Store:=preload("res://persistence/save_store.gd")
const Traffic:=preload("res://sim/layouts/traffic_service.gd")
const Fixture:=preload("res://tests/overtake_fixture.gd")

func _same(a,b) -> bool:
	return var_to_bytes(a)==var_to_bytes(b)

func test_roundtrip_running_trains_continue_identically():
	var w:=Traffic.build();w.dispatcher().enabled=true
	for i in 60:w.step(1)
	var saved:=Snapshot.capture(w)
	var loaded:=Snapshot.restore(bytes_to_var(var_to_bytes(saved)))
	if not loaded.ok:return loaded.reason
	if not _same(saved,Snapshot.capture(loaded.world)):return "State changed while loading"
	for i in 30:w.step(.5);loaded.world.step(.5)
	return _same(Snapshot.capture(w),Snapshot.capture(loaded.world))

func test_turavur_overtake_wait_age_and_route_locks_survive():
	var w:=Fixture.build();var e=w.dispatcher();e._wait_since.K1=w.time-1801;e.run_cycle(true)
	var loaded:=Snapshot.restore(Snapshot.capture(w))
	if not loaded.ok:return loaded.reason
	var other: RailWorld=loaded.world
	other.dispatcher().run_cycle(true)
	return other.dispatch_holds.has("K1") and other.dispatch_holds.K1.arrived and other.signals["TUVR-S2"].route.is_empty() and not other.signals["TUVR-S1"].route.is_empty() and other.dispatcher()._wait_since.K1==e._wait_since.K1

func test_passenger_exchange_resumes_without_double_counting():
	var w:=Fixture.build();var t: Train=w.trains.K1
	var pax=preload("res://sim/passenger_service.gd")
	pax.update(w,t,0);pax.update(w,t,14)
	var loaded:=Snapshot.restore(Snapshot.capture(w))
	if not loaded.ok:return loaded.reason
	for i in 60:pax.update(w,t,1);pax.update(loaded.world,loaded.world.trains.K1,1)
	return _same(t.passengers,loaded.world.trains.K1.passengers) and t.timetable.passenger_release==loaded.world.trains.K1.timetable.passenger_release

func test_deleted_services_and_operator_changes_stay_deleted_and_set():
	var w:=Traffic.build();var e=w.dispatcher();var ids:=w.trains.keys()
	e.delete_service(ids[-1],ids[0]);e.operator_holds[ids[1]]=true;e.inhibited_signals[w.signals.keys()[0]]=true
	w.trains[ids[0]].dispatch_priority=99;w.trains[ids[0]].controller=.42;w.trains[ids[0]].automatic=false;w.protection=false
	var result:=Snapshot.restore(Snapshot.capture(w,{player=ids[0],time_scale=8}))
	if not result.ok:return result.reason
	return not result.world.trains.has(ids[-1]) and _same(Snapshot.capture(w),Snapshot.capture(result.world)) and result.session.time_scale==8

func test_complete_kerala_traffic_snapshot_restores_all_services():
	var w:=preload("res://sim/layouts/kerala_coast.gd").build_traffic()
	w.dispatcher().enabled=true;w.step(.1)
	var result:=Snapshot.restore(Snapshot.capture(w))
	if not result.ok:return result.reason
	return result.world.trains.size()==32 and _same(Snapshot.capture(w),Snapshot.capture(result.world))

func test_depot_unloading_keeps_shared_passenger_timetable():
	var w:=Fixture.build();var t: Train=w.trains.K1
	t.service_complete=true;t.completed_timetable=t.timetable;t.depot={phase="unloading",release=w.clock_seconds()+90}
	var result:=Snapshot.restore(Snapshot.capture(w))
	if not result.ok:return result.reason
	var other: Train=result.world.trains.K1
	return other.completed_timetable==other.timetable and _same(t.depot,other.depot)

func test_future_clearance_commitments_resume_and_checkpoint_stays_immutable():
	var w:=preload("res://sim/layouts/kerala_coast.gd").build_traffic()
	for id in w.trains.keys():
		if id not in ["K1","K2","K3"]:w.trains.erase(id)
	w.dispatcher().enabled=true;w.dispatcher().run_cycle(true)
	if w.dispatcher().future_clearances.plans.is_empty():return "Fixture has no future-platform commitment"
	var data:=Snapshot.capture(w);var original:=var_to_bytes(data);var result:=Snapshot.restore(data)
	if not result.ok:return result.reason
	for i in 30:w.step(.5);result.world.step(.5)
	return original==var_to_bytes(data) and _same(Snapshot.capture(w),Snapshot.capture(result.world))

func test_empty_stock_and_reserved_depot_resume_with_passenger_results():
	var w:=Fixture.build();var t: Train=w.trains.K1;var depot=preload("res://sim/depot_workings.gd")
	var stop: Dictionary=t.timetable.stops[-1]
	w.place_train(t,stop.block,stop.s,stop.direction);t.timetable.index=1;t.timetable.at_stop=true;t.timetable.actual_arrivals[1]=w.clock_seconds();t.service_complete=true
	depot.update(w,t);w.time+=91;depot.update(w,t)
	if not depot.active(t):return "Fixture did not enter empty-stock working"
	var loaded:=Snapshot.restore(Snapshot.capture(w))
	if not loaded.ok:return loaded.reason
	return loaded.world.trains.K1.timetable!=loaded.world.trains.K1.completed_timetable and _same(Snapshot.capture(w),Snapshot.capture(loaded.world))

func test_invalid_version_geometry_and_reference_reject_without_mutation():
	var w:=Traffic.build();var saved:=Snapshot.capture(w);var before:=var_to_bytes(saved)
	for key in ["version","layout_signature","path","signal"]:
		var bad:=saved.duplicate(true)
		match key:
			"version":bad.version=999
			"layout_signature":bad.layout_signature="wrong"
			"path":bad.trains[0].path[0].edge="missing"
			"signal":bad.world.signals[bad.world.signals.keys()[0]].owner="missing"
		if Snapshot.restore(bad).ok:return "Accepted invalid "+key
	return before==var_to_bytes(Snapshot.capture(w))

func test_platform_inventory_change_invalidates_old_checkpoint():
	var w:=Fixture.build();var before:=Snapshot.signature(w)
	var st: Dictionary=w.stations.filter(func(s):return s.code=="TUVR")[0]
	st.platform_details.TUVR_P1.platform_width=3.5
	return before!=Snapshot.signature(w) and not Snapshot.restore(Snapshot.capture(w)).ok

func test_atomic_slot_overwrite_and_previous_backup():
	var store:=Store.new("res://.local/save-tests/rotation")
	var w:=Traffic.build();var before:=Snapshot.capture(w)
	var result:=store.write_slot("1",before,{title="first"})
	if not result.ok:return result.reason
	w.time=250;result=store.write_slot("1",Snapshot.capture(w),{title="second"})
	if not result.ok:return result.reason
	var first:=store.read_slot("1",true);var second:=store.read_slot("1")
	return first.ok and second.ok and first.data.summary.title=="first" and second.data.summary.title=="second" and _same(before,first.data.checkpoint)

func test_corrupt_slot_preserves_backup_and_cannot_escape_save_directory():
	var store:=Store.new("res://.local/save-tests/corrupt");var saved:=Snapshot.capture(Traffic.build())
	if not store.write_slot("quick",saved,{title="good"}).ok:return "Initial write failed"
	if not store.write_slot("quick",saved,{title="good"}).ok:return "Backup write failed"
	var f:=FileAccess.open(store.path("quick"),FileAccess.READ_WRITE);f.seek_end(-8);f.store_buffer(PackedByteArray([0,0,0,0,0,0,0,0]));f.close()
	if store.read_slot("quick").ok:return "Corruption accepted"
	if not store.write_slot("quick",saved,{title="new"}).ok:return "Recovery write failed"
	return store.read_slot("quick",true).data.summary.title=="good" and not store.write_slot("../escape",saved,{}).ok and not store.read_slot("../escape").ok
