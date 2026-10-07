extends RefCounted
const Progress := preload("res://sim/service_progress.gd")
const Layout := preload("res://sim/layouts/first_line.gd")

func test_origin_is_counted_and_next_stop_is_not_origin():
	var w:=Layout.build_dispatch()
	var t: Train=w.trains.T1
	var p:=Progress.snapshot(w,t)
	return p.completed==1 and p.remaining==p.total-1 and p.next_name==t.timetable.stops[1].name and p.estimated_seconds>0

func test_arrival_counts_once_and_selects_following_stop():
	var w:=Layout.build_dispatch()
	var t: Train=w.trains.T1
	var tt=t.timetable
	tt.index=1;tt.at_stop=true;tt.actual_arrivals[1]=w.clock_seconds()
	w.place_train(t,tt.stops[1].block,tt.stops[1].s,1)
	var p:=Progress.snapshot(w,t)
	return p.completed==2 and p.remaining==p.total-2 and p.next_name==tt.stops[2].name

func test_completed_journey_has_no_next_stop():
	var w:=Layout.build_dispatch()
	var t: Train=w.trains.T1
	t.timetable.index=t.timetable.stops.size()-1;t.timetable.at_stop=true
	for i in t.timetable.actual_arrivals.size():t.timetable.actual_arrivals[i]=w.clock_seconds()
	var p:=Progress.snapshot(w,t)
	return p.complete and p.remaining==0 and p.completed==p.total and not p.has("next_name")

func test_solo_drive_has_no_fictitious_schedule():
	return not Progress.snapshot(Layout.build(),Train.new("SOLO",100)).scheduled
