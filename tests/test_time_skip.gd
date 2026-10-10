extends RefCounted
const Skip := preload("res://sim/time_skip.gd")

func fixture() -> RailWorld:
	var w:=preload("res://tests/test_timetable.gd").new()._world("08:00")
	w.trains.T1.automatic=false
	w.dispatcher().manual_service="T1"
	return w

func test_skip_uses_real_motion_and_ai_dispatch_and_stops_at_exact_clock():
	var w:=fixture();var skip:=Skip.new(w)
	if not skip.to_time(w.clock_seconds()+30).ok:return false
	while not skip.done:skip.step()
	return skip.ok and absf(w.time-30)<.0001 and w.trains.T1.odometer>10 and w.trains.T1.automatic and w.dispatcher().enabled and w.dispatcher().manual_service.is_empty() and w.events.is_empty()

func test_stop_skip_waits_for_actual_arrival_not_the_booked_time():
	var w:=fixture();var skip:=Skip.new(w)
	# A long operator hold makes this service late. The skip must obey it.
	w.dispatcher().operator_holds.T1=true
	if not skip.to_stop("T1",1).ok:return false
	while w.time<300:skip.step()
	if skip.done or w.trains.T1.odometer>0:return "Skipped a held service to its booked arrival"
	w.dispatcher().operator_holds.clear()
	while not skip.done and w.time<1000:skip.step()
	var tt=w.trains.T1.timetable
	return skip.ok and tt.actual_arrivals[1]>tt.planned_arrival(1) and tt.at_stop and w.trains.T1.speed<.1 and w.events.is_empty()

func test_cancel_keeps_advanced_state_and_ai_driving():
	var w:=fixture();var skip:=Skip.new(w)
	skip.to_time(w.clock_seconds()+600);skip.step();skip.cancel()
	var time:=w.time;skip.step()
	return skip.done and not skip.ok and time>0 and w.time==time and w.trains.T1.automatic

func test_invalid_targets_leave_driving_and_dispatch_unchanged():
	var w:=fixture();var skip:=Skip.new(w)
	return not skip.to_time(w.clock_seconds()-1).ok and not skip.to_time(INF).ok and not skip.to_time(w.clock_seconds()+86401).ok and not skip.to_stop("MISSING",1).ok and not skip.to_stop("T1",99).ok and not w.trains.T1.automatic and w.dispatcher().manual_service=="T1"

func test_existing_safety_event_does_not_retrigger_but_new_event_stops_skip():
	var w:=fixture()
	w.events=[{seq=1,text="Earlier event"}];w._event_seq=1
	var skip:=Skip.new(w);skip.to_time(w.clock_seconds()+30);skip.step()
	if skip.done:return "Replayed historical event"
	w.events.append({seq=2,text="New protection intervention"});w._event_seq=2
	skip.step()
	return skip.done and not skip.ok and skip.report.contains("New protection")

func test_time_skip_across_midnight_keeps_day_and_live_scheduled_entry():
	var w:=preload("res://tests/test_service_lifecycle.gd").new().fixture()
	w.clock_start=86390
	for t in w.trains.values():t.timetable.departure=86405
	var skip:=Skip.new(w);skip.to_time(86410)
	while not skip.done:skip.step()
	return skip.ok and w.clock_day()==2 and w.clock_text()=="00:00:10" and not w.active_trains().is_empty()
