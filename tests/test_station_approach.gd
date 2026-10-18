extends RefCounted
const Fixtures := preload("res://tests/test_automatic_driving.gd")
const Cues := preload("res://sim/departure_cues.gd")

func approach(reverse: bool=false):
	var f:=Fixtures.new()
	var w:=f.straight([110,40,110],[3000,180,1000]) if not reverse else f.straight([110,40,110],[1000,180,3000])
	var origin:="E2" if reverse else "E0"
	var destination:="E0" if reverse else "E2"
	var direction:=-1 if reverse else 1
	var t:=f.train_at(w,origin,2300 if reverse else 700,direction,0)
	var assigned:=w.set_timetable(t.id,{departure="08:00",stops=[
		{block=origin,position_m=2300 if reverse else 700,direction=direction,minutes_from_origin=0},
		{block=destination,position_m=250 if reverse else 750,direction=direction,minutes_from_origin=5}]})
	if not assigned.ok:return assigned.reason
	t.speed=100.0/3.6
	t.timetable.at_stop=false;t.timetable.index=1
	var peak_increase:=0.0
	var previous:=t.speed
	var lowest:=INF
	var max_final_decel:=0.0
	var frames:=0
	for i in 14000:
		w.step(.05)
		if not t.station_approach.is_empty():
			lowest=minf(lowest,t.speed)
			peak_increase=maxf(peak_increase,t.speed-lowest)
			if t.speed>.5 and t.speed<2.0:max_final_decel=maxf(max_final_decel,(previous-t.speed)/.05)
			frames+=1
		previous=t.speed
		if t.timetable.complete():
			if peak_increase>.12:return "Approach accelerated again by %.3f m/s" % peak_increase
			if max_final_decel>.30:return "Final stop remained harsh: %.3f m/s2" % max_final_decel
			return frames>100 and absf(t.head_s-(250 if reverse else 750))<1.1 and w.events.is_empty()
	return "Arrival never completed"

func test_station_entry_restriction_does_not_trigger_reacceleration():return approach()
func test_reverse_station_approach_is_monotone():return approach(true)

func test_short_leg_can_accelerate_before_its_braking_phase():
	var f:=Fixtures.new();var w:=f.straight([90,90],[700,700])
	var t:=f.train_at(w,"E0",500,1,0)
	w.set_timetable(t.id,{departure="08:00",stops=[{block="E0",position_m=500,minutes_from_origin=0},{block="E1",position_m=600,minutes_from_origin=3}]})
	t.timetable.at_stop=false;t.timetable.index=1
	var peak:=0.0
	for i in 8000:
		w.step(.05);peak=maxf(peak,t.speed)
		if t.timetable.complete():return peak>8 and w.events.is_empty()
	return "Short leg stalled"

func test_two_departure_cues_use_simulation_time_and_do_not_repeat():
	var t:=Train.new("A",200)
	Cues.update(t,100,true)
	if t.horn_sequence!=1:return false
	for now in [100.0,101.0,103.49]:Cues.update(t,now,false)
	if t.horn_sequence!=1:return false
	Cues.update(t,103.5,false)
	if t.horn_sequence!=2 or t.horn_pending_at!=-1:return false
	Cues.update(t,200,false)
	if t.horn_sequence!=2:return false
	Cues.update(t,300,true);Cues.update(t,600,false)
	return t.horn_sequence==4 and t.horn_emitted_at==303.5

func test_held_approach_can_restart_after_clearance():
	var f:=Fixtures.new();var w:=f.straight([60,60],[1000,1000])
	var t:=f.train_at(w,"E0",700,1,0)
	w.set_timetable(t.id,{departure="08:00",stops=[{block="E0",position_m=700,minutes_from_origin=0},{block="E1",position_m=500,minutes_from_origin=4}]})
	t.timetable.at_stop=false;t.timetable.index=1
	t.station_approach={key="1:E1:1",ceiling=2.0}
	var peak:=0.0
	for i in 12000:
		w.step(.05);peak=maxf(peak,t.speed)
		if t.timetable.complete():return w.events.is_empty() and peak>8.0
	return "Stopped arrival ceiling prevented restart"
