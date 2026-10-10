extends RefCounted
const Skip := preload("res://sim/time_skip.gd")
const Worker := preload("res://sim/time_skip_worker.gd")
const Snapshot := preload("res://sim/world_snapshot.gd")
const Fixtures := preload("res://tests/test_time_skip.gd")

func complete(worker) -> Dictionary:
	var until:=Time.get_ticks_msec()+10000
	while Time.get_ticks_msec()<until:
		var result: Dictionary=worker.take()
		if not result.is_empty():return result
		OS.delay_usec(1000)
	worker.close()
	return {}

func test_worker_matches_serial_physics_passengers_timetable_and_dispatch_exactly():
	var serial: RailWorld=Fixtures.new().fixture()
	var threaded: RailWorld=Fixtures.new().fixture()
	var a:=Skip.new(serial);var b:=Skip.new(threaded)
	a.to_time(serial.clock_seconds()+600);b.to_time(threaded.clock_seconds()+600)
	while not a.done:a.step()
	var worker:=Worker.new()
	if worker.start(b)!=OK:return "Worker failed to start"
	var result:=complete(worker)
	return not result.is_empty() and result.trial.ok==a.ok and result.trial.report==a.report and Snapshot.capture(serial)==Snapshot.capture(threaded)

func test_worker_stop_target_matches_serial_actual_arrival():
	var a:=Skip.new(Fixtures.new().fixture());var b:=Skip.new(Fixtures.new().fixture())
	a.to_stop("T1",1);b.to_stop("T1",1)
	while not a.done:a.step()
	var worker:=Worker.new()
	if worker.start(b)!=OK:return false
	var result:=complete(worker)
	return not result.is_empty() and result.trial.ok and Snapshot.capture(a.world)==Snapshot.capture(b.world)

func test_cancel_returns_owned_state_and_progress_is_detached():
	var skip:=Skip.new(Fixtures.new().fixture());skip.to_time(skip.world.clock_seconds()+86400)
	var worker:=Worker.new()
	if worker.start(skip)!=OK:return false
	var status:=worker.progress();status.clock=-100;status.report="changed UI copy"
	OS.delay_usec(10000)
	worker.request_cancel()
	var result:=complete(worker)
	if result.is_empty():return "Cancellation timed out"
	var time: float=result.trial.world.time
	OS.delay_usec(1000)
	return result.trial.done and not result.trial.ok and time>0 and result.trial.world.time==time and result.progress.clock>0 and result.progress.report!="changed UI copy" and worker.take().is_empty()

func test_worker_close_joins_and_can_be_reused():
	var worker:=Worker.new()
	for i in 3:
		var skip:=Skip.new(Fixtures.new().fixture());skip.to_time(skip.world.clock_seconds()+86400)
		if worker.start(skip)!=OK:return false
		if worker.start(skip)!=ERR_INVALID_PARAMETER:worker.close();return "Accepted concurrent world ownership"
		var result: Dictionary=worker.close()
		if result.is_empty() or not result.trial.done or not worker.close().is_empty():return false
	return true

func test_worker_midnight_scheduled_entry_matches_serial():
	var a:=preload("res://tests/test_service_lifecycle.gd").new().fixture()
	var b:=preload("res://tests/test_service_lifecycle.gd").new().fixture()
	for w in [a,b]:
		w.clock_start=86390
		for t in w.trains.values():t.timetable.departure=86405
	var serial:=Skip.new(a);var threaded:=Skip.new(b)
	serial.to_time(86410);threaded.to_time(86410)
	while not serial.done:serial.step()
	var worker:=Worker.new()
	if worker.start(threaded)!=OK:return false
	var result:=complete(worker)
	return not result.is_empty() and result.trial.ok and b.clock_day()==2 and Snapshot.capture(a)==Snapshot.capture(b)

func test_worker_stops_for_safety_intervention():
	var w:=Fixtures.new().fixture()
	var skip:=Skip.new(w);skip.to_time(w.clock_seconds()+300)
	# Inject before handing over ownership; no concurrent access from the test.
	w.events.append({seq=1,text="Protection intervention"});w._event_seq=1
	var worker:=Worker.new()
	if worker.start(skip)!=OK:return false
	var result:=complete(worker)
	return not result.is_empty() and not result.trial.ok and result.progress.report.contains("Protection intervention") and w.time<=.200001
