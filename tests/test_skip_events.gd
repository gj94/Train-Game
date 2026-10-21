extends RefCounted
const EventSkip := preload("res://sim/skip_to_event.gd")
const Skip := preload("res://sim/time_skip.gd")
const History := preload("res://sim/skip_history.gd")
const Encounters := preload("res://sim/skip_encounters.gd")
const MapState := preload("res://sim/skip_map_state.gd")
const Options := preload("res://sim/skip_options.gd")
const Snapshot := preload("res://sim/world_snapshot.gd")
const Worker := preload("res://sim/time_skip_worker.gd")

func none() -> Dictionary:
	return {"stops":false,"crossing":false,"overtaking":false,"overtaken":false,"signal":false}

func pair(kind: String="crossing") -> RailWorld:
	var w:=RailWorld.new()
	for i in 2:
		var id:="road"+str(i)
		w.graph.add_node(id+"a",Vector3(0,0,i*6))
		w.graph.add_node(id+"b",Vector3(20000,0,i*6))
		w.graph.add_edge(id,id+"a",id+"b",[],45)
		var t:=Train.new("A" if i==0 else "B",200)
		t.speed=20 if i==0 else 30;t.max_speed=t.speed;t.max_accel=.6;t.controller=.1;t.automatic=true
		w.place_train(t,id,1000 if i==0 else (7000 if kind=="crossing" else 3000),-1 if i==1 and kind=="crossing" else 1)
	if kind=="overtaking":w.trains.A.max_speed=35;w.trains.A.speed=35;w.trains.B.max_speed=15;w.trains.B.speed=15
	if kind=="overtaken":w.place_train(w.trains.A,"road0",3000,1);w.place_train(w.trains.B,"road1",1000,1)
	return w

func run_to_end(skip,limit: int=12000) -> bool:
	for i in limit:
		if skip.done:return true
		skip.step()
	return skip.done

func test_real_crossing_returns_sixty_seconds_before_first_contact_and_preserves_train_identity():
	var w:=pair();var a: Train=w.trains.A;var start:=w.clock_seconds()
	var skip:=EventSkip.new(w);var options:=none();options.crossing=true
	skip.to_event("A",options)
	if not run_to_end(skip):return "No crossing found"
	if not skip.ok or skip.last_event.kind!="crossing" or absf(skip.last_event.time-w.clock_seconds()-60)>.001:return skip.report
	if w.trains.A!=a or w.clock_seconds()<=start:return "Identity or forward progress lost"
	var probe:=Encounters.new();probe.sample(w,"A");var found:=[]
	while found.is_empty() and w.clock_seconds()<skip.last_event.time+2:
		w.step(.2);found=probe.sample(w,"A")
	return not found.is_empty() and absf(found[0].time-skip.last_event.time)<.05 and w.events.is_empty()

func test_both_overtaking_roles_trigger_before_first_coach_not_after_tail_clearance():
	for kind in ["overtaking","overtaken"]:
		var w:=pair(kind);var options:=none();options[kind]=true
		var skip:=EventSkip.new(w);skip.to_event("A",options)
		if not run_to_end(skip) or not skip.ok:return "Did not detect "+kind
		if skip.last_event.kind!=kind or absf(skip.last_event.time-w.clock_seconds()-60)>.001:return skip.report
	return true

func test_disabled_encounter_does_not_interrupt():
	var w:=pair();var options:=none();options.overtaken=true
	var skip:=EventSkip.new(w);skip.to_event("A",options)
	for i in 1500:skip.step()
	var passed: bool=w.trains.A.head_s>w.trains.B.head_s
	skip.cancel()
	return passed and skip.last_event.is_empty()

func test_already_near_crossing_returns_now_without_rewinding_before_skip_start():
	var w:=pair();w.trains.B.head_s=2000
	var before:=w.clock_seconds();var options:=none();options.crossing=true
	var skip:=EventSkip.new(w);skip.to_event("A",options)
	return run_to_end(skip) and skip.ok and absf(w.clock_seconds()-before)<.001 and skip.last_event.time-before<60

func test_repeated_skip_dismisses_the_same_upcoming_encounter():
	var w:=pair();var options:=none();options.crossing=true
	var first:=EventSkip.new(w);first.to_event("A",options)
	if not run_to_end(first):return false
	var second:=EventSkip.new(w);second.to_event("A",options,[first.last_event])
	for i in 900:second.step()
	var waiting:=not second.done and second.last_event.is_empty()
	second.cancel();return waiting

func test_spawn_overlap_reversal_and_depot_do_not_create_encounters():
	var w:=pair();var tracker:=Encounters.new();tracker.sample(w,"A")
	w.trains.B.lifecycle="stored";tracker.sample(w,"A")
	w.trains.B.lifecycle="active";w.trains.B.head_s=1100
	if not tracker.sample(w,"A").is_empty():return "Spawn overlap"
	w.trains.B.speed=0;w.trains.B.reverse(w.graph)
	if not tracker.sample(w,"A").is_empty():return "Reversal"
	w.trains.B.depot={phase="working"};w.trains.B.head_s=500
	return tracker.sample(w,"A").is_empty()

func test_signal_red_to_yellow_interrupts_but_already_clear_does_not():
	var w:=preload("res://tests/test_time_skip.gd").new().fixture();var options:=none();options.signal=true
	var skip:=EventSkip.new(w);skip.to_event("T1",options)
	if not run_to_end(skip,30) or skip.last_event.kind!="signal":return "Did not return on departure clearance"
	var ns:=w.next_signal(w.trains.T1)
	if w.aspect(ns.id)==RailWorld.Aspect.RED:return "Returned at red"
	var next:=EventSkip.new(w);next.to_event("T1",options)
	for i in 5:next.step()
	var accepted:=not next.done;next.cancel();return accepted

func test_booked_dwell_does_not_arm_signal_until_train_is_ready():
	var w:=preload("res://tests/test_timetable.gd").new()._world("08:10")
	var options:=none();options.signal=true
	var skip:=EventSkip.new(w);skip.to_event("T1",options)
	for i in 100:skip.step()
	var accepted:=not skip.done;skip.cancel();return accepted

func test_stop_approach_returns_at_one_km_or_comfort_braking_point():
	var w:=preload("res://tests/test_time_skip.gd").new().fixture();var options:=none();options.stops=true
	var skip:=EventSkip.new(w);skip.to_event("T1",options)
	if not run_to_end(skip) or skip.last_event.kind!="stops":return skip.report
	var t: Train=w.trains.T1
	var distance:=w._stop_distance(t.path[0].edge,t.path[0].dir,t.head_s,t.timetable.stop_ahead(),[])
	return not t.timetable.at_stop and distance>990 and distance<1001 and w.events.is_empty()

func test_stop_approach_inside_zone_reports_once_and_then_can_skip_on():
	var w:=preload("res://tests/test_time_skip.gd").new().fixture();var options:=none();options.stops=true
	var first:=EventSkip.new(w);first.to_event("T1",options);run_to_end(first)
	var second:=EventSkip.new(w);second.to_event("T1",options,[first.last_event])
	for i in 30:second.step()
	var accepted:=not second.done;second.cancel();return accepted

func test_earliest_selected_trigger_wins_even_if_a_later_event_is_discovered_first():
	var w:=pair();var skip:=EventSkip.new(w);var options:=none();options.crossing=true
	skip.to_event("A",options)
	# Earlier-discovered stop/signal must not mask an encounter's 60 s lead-in.
	skip._consider({kind="stops",stop=1,clock=w.clock_seconds()+100,text="later"})
	skip._consider({kind="crossing",other="B",time=w.clock_seconds()+140,clock=w.clock_seconds()+80,text="earlier"})
	var accepted: bool=skip._candidate.text=="earlier";skip.cancel();return accepted

func test_cancel_returns_the_committed_map_clock_and_retains_ai():
	var w:=pair();var options:=none();options.crossing=true
	var skip:=EventSkip.new(w);skip.configure_preview("A",MapState.geometry(w));skip.to_event("A",options)
	for i in 400:skip.step()
	var display:=skip.presentation()
	if display.clock>=w.clock_seconds()-59:return "Map leaked look-ahead"
	skip.cancel()
	return absf(display.clock-w.clock_seconds())<.001 and skip.done and not skip.ok and w.trains.A.automatic

func test_safety_and_completion_cannot_be_disabled():
	for kind in ["safety","complete"]:
		var w:=pair();var skip:=EventSkip.new(w);skip.to_event("A",none())
		if kind=="safety":w.events.append({seq=1,text="New safety event"});w._event_seq=1
		else:w.trains.A.service_complete=true
		skip.step()
		if not skip.done or skip.last_event.kind!=kind:return "Ignored "+kind
	return true

func test_history_restores_every_saved_field_and_exact_future_evolution():
	var w:=preload("res://tests/test_time_skip.gd").new().fixture()
	var skip:=Skip.new(w);skip.to_time(w.clock_seconds()+400)
	for i in 50:skip.step()
	var history:=History.new();var checkpoint:=history.capture(w);var initial:=Snapshot.capture(w)
	var train: Train=w.trains.T1;var tt=train.timetable
	for i in 500:w.step(.2)
	var future:=Snapshot.capture(w)
	history.restore(w,checkpoint)
	if w.trains.T1!=train or train.timetable!=tt or Snapshot.capture(w)!=initial:return "Restore changed saved state or identity"
	for i in 500:w.step(.2)
	return Snapshot.capture(w)==future

func test_passenger_checkpoint_sharing_is_detached_and_exchanges_are_restored():
	var w:=pair();var t: Train=w.trains.A;t.stock_kind="ported:icf";t.rake_profile="passenger"
	preload("res://sim/passenger_service.gd").setup(t)
	var history:=History.new();var a:=history.capture(w);var b:=history.capture(w)
	var count: int=a.trains.A.passengers.cars[1].seats[0]
	t.passengers.cars[1].seats[0]=999;t.passengers.elapsed=1.0
	var c:=history.capture(w)
	if a.trains.A.passengers.cars[1].seats[0]!=count or c.trains.A.passengers.cars[1].seats[0]!=999:return "History aliases live passengers"
	history.restore(w,b)
	return t.passengers.cars[1].seats[0]==count

func test_preview_data_is_detached_from_the_live_world():
	var w:=pair();var geometry:=MapState.geometry(w)
	var view:=MapState.capture(w,"A",geometry)
	view.trains[0].segments[0].edge="changed";geometry.edges.road0.a=Vector2(-999,0)
	return w.trains.A.path[0].edge=="road0" and w.graph.nodes.road0a.pos.x==0

func test_options_validate_booleans_and_all_can_be_disabled():
	var value:=Options.normalized({"signal":"false","stops":false,"unknown":true})
	return value.signal and not value.stops and not value.has("unknown") and not Options.encounters(none())

func test_worker_and_serial_event_skips_restore_identical_railways():
	var a:=EventSkip.new(pair());var b:=EventSkip.new(pair());var options:=none();options.crossing=true
	a.to_event("A",options);b.to_event("A",options);run_to_end(a)
	var worker:=Worker.new()
	if worker.start(b)!=OK:return false
	var result: Dictionary=preload("res://tests/test_time_skip_worker.gd").new().complete(worker)
	return not result.is_empty() and a.report==b.report and Snapshot.capture(a.world)==Snapshot.capture(b.world)

func test_high_speed_returns_before_one_km_for_comfortable_braking():
	var w:=pair();var t: Train=w.trains.A
	t.speed=42;t.service_decel=.6
	t.timetable=preload("res://sim/timetable.gd").new()
	t.timetable.stops=[{name="Origin",block="road0",s=1000,direction=1},{name="Next",block="road0",s=3000,direction=1}]
	t.timetable.index=1;t.timetable.at_stop=false
	var options:=none();options.stops=true
	var skip:=EventSkip.new(w);skip.to_event("A",options);skip.step()
	return skip.done and skip.ok and w.time==0 and skip.report.contains("early braking")

func test_no_selected_event_is_bounded_and_does_not_change_default_settings():
	var w:=pair();var skip:=EventSkip.new(w);skip.to_event("A",none())
	skip.target_clock=w.clock_seconds()+.6
	return run_to_end(skip,10) and not skip.ok and skip.last_event.kind=="timeout" and Options.DEFAULTS.crossing
