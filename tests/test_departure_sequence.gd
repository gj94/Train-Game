extends RefCounted
const Fixtures := preload("res://tests/test_automatic_driving.gd")
const Cues := preload("res://sim/departure_cues.gd")
const Audio := preload("res://game/engine_audio.gd")
const History := preload("res://sim/skip_history.gd")
const Snapshot := preload("res://sim/world_snapshot.gd")

func fixture() -> RailWorld:
	var f:=Fixtures.new();var w:=f.straight([100,100],[2000,4000])
	w.add_signal("START","E0",1,50);w.add_signal("NEXT","E1",1,50)
	var t:=f.train_at(w,"E0",1500,1,0)
	var result:=w.set_timetable(t.id,{departure="08:00",stops=[
		{block="E0",position_m=1500,minutes_from_origin=0},
		{block="E1",position_m=3000,minutes_from_origin=5}]})
	assert(result.ok,result.reason)
	assert(w.set_route("START","NEXT").ok)
	return w

func verify_departure(w: RailWorld):
	var t: Train=w.trains.AI;var audio:=Audio.new();audio.train=t
	var calls:=[];var first:=-1.0;var moved_at:=-1.0
	var origin:=t.odometer
	for tick in 200:
		w.step(.05)
		if audio._departure_horn_due(false,w.clock_seconds()):
			calls.append(t.horn_emitted_at)
			if t.speed>0 or t.odometer!=origin:
				audio.free();return "Automatic horn sounded after movement"
		if first<0 and not calls.is_empty():first=calls[0]
		if t.odometer>origin:
			moved_at=w.clock_seconds();break
	audio.free()
	if calls.size()!=2:return "Expected two audible calls, got "+str(calls)
	if absf(calls[1]-calls[0]-Cues.GAP)>.001:return "Wrong separation"
	if moved_at<first+Cues.GAP+Cues.CALL_SECONDS-.00001:return "Moved during second call"
	return moved_at>=0 and w.events.is_empty()

func test_both_horns_finish_before_first_wheel_movement():return verify_departure(fixture())

func test_selected_player_service_handed_to_ai_uses_same_sequence():
	var w:=fixture();var t: Train=w.trains.AI
	w.dispatcher().manual_service=t.id
	t.automatic=false;t.controller=-1
	w.step(2)
	if t.horn_sequence!=0:return "Manual driver received automatic horn"
	t.automatic=true
	return verify_departure(w)

func test_red_starter_and_booked_dwell_do_not_start_horns():
	var w:=fixture();var t: Train=w.trains.AI
	t.timetable.departure+=10
	w.step(9)
	if t.horn_sequence!=0:return "Horn before booked release"
	w.set_signal("START",false)
	w.step(20)
	if t.horn_sequence!=0 or t.odometer!=0:return "Departed or horned at red"
	w.set_route("START","NEXT")
	return verify_departure(w)

func test_lost_route_discards_pair_and_restarts_both_calls():
	var w:=fixture();var t: Train=w.trains.AI
	w.step(1)
	if t.horn_sequence!=1 or t.odometer!=0:return "First call missing"
	w.set_signal("START",false);w.step(5)
	if t.horn_pending_at>=0 or t.horn_ready_at>=0 or t.odometer!=0:return "Lost route did not reset ceremony"
	w.set_route("START","NEXT")
	return verify_departure(w)

func test_manual_takeover_releases_ceremony_but_never_fires_second_call():
	var w:=fixture();var t: Train=w.trains.AI
	w.step(1);t.automatic=false;t.controller=.5
	w.step(.05)
	if t.horn_pending_at>=0 or t.horn_ready_at>=0 or t.speed<=0:return "Manual takeover stuck behind ceremony"
	var sequence:=t.horn_sequence
	w.step(5)
	return t.horn_sequence==sequence and t.horn_emitted_at<0 and w.events.is_empty()

func test_passenger_release_and_emergency_hold_precede_horns():
	var w:=fixture();var t: Train=w.trains.AI
	t.timetable.passenger_release=w.clock_seconds()+8
	w.step(7)
	if t.horn_sequence!=0:return "Horn before passenger release"
	t.emergency=true;w.step(5)
	if t.horn_sequence!=0 or t.odometer!=0:return "Horn/movement under emergency"
	t.emergency=false
	return verify_departure(w)

func test_rollback_mid_pair_preserves_exact_departure():
	var w:=fixture();var t: Train=w.trains.AI;var history:=History.new()
	w.step(2);var checkpoint:=history.capture(w)
	w.step(8);var expected:=Snapshot.fields(t,Snapshot.TRAIN+Snapshot.ARRIVAL)
	history.restore(w,checkpoint)
	if w.trains.AI!=t or t.horn_sequence!=1:return "Rollback lost identity/cue state"
	w.step(8)
	return var_to_bytes(expected)==var_to_bytes(Snapshot.fields(t,Snapshot.TRAIN+Snapshot.ARRIVAL))

func test_render_free_skip_uses_identical_departure_time():
	var direct:=fixture();var skipped:=fixture()
	var advance:=preload("res://sim/time_skip.gd").new(skipped)
	advance.to_time(skipped.clock_seconds()+12)
	while not advance.done:advance.step(.2)
	for i in 60:direct.step(.2)
	return skipped.trains.AI.horn_sequence==2 and is_equal_approx(direct.trains.AI.timetable.actual_departures[0],skipped.trains.AI.timetable.actual_departures[0])
