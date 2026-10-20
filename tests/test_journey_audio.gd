extends RefCounted
const Space:=preload("res://game/listening_space.gd")
const Air:=preload("res://game/train_air_audio.gd")
const Snapshot:=preload("res://sim/world_snapshot.gd")
const Store:=preload("res://persistence/save_store.gd")
const EngineSound:=preload("res://game/engine_audio.gd")
const Cues:=preload("res://sim/departure_cues.gd")

func test_manual_departure_consumes_both_horns_without_playback():
	var audio:=EngineSound.new();var t:=Train.new("H",200);audio.train=t;t.automatic=false
	Cues.update(t,100,true)
	var silent:=not audio._departure_horn_due(false,100)
	Cues.update(t,103.5,false)
	silent=silent and not audio._departure_horn_due(false,103.5)
	t.automatic=true
	silent=silent and not audio._departure_horn_due(false,103.6)
	audio.free();return silent

func test_ai_departure_keeps_two_calls_once_each():
	var audio:=EngineSound.new();var t:=Train.new("H",200);audio.train=t;t.automatic=true
	Cues.update(t,100,true)
	var first:=audio._departure_horn_due(false,100)
	var repeated:=audio._departure_horn_due(false,100.1)
	Cues.update(t,103.5,false)
	var second:=audio._departure_horn_due(false,103.5)
	audio.free();return first and second and not repeated

func test_takeover_cancels_queued_second_horn_even_after_handing_back():
	var audio:=EngineSound.new();var t:=Train.new("H",200);audio.train=t;t.automatic=true
	Cues.update(t,100,true);audio._departure_horn_due(false,100)
	t.automatic=false;audio._departure_horn_due(false,101)
	t.automatic=true
	Cues.update(t,103.5,false)
	var cancelled:=not audio._departure_horn_due(false,103.5)
	Cues.update(t,200,true)
	var next_departure:=audio._departure_horn_due(false,200)
	audio.free();return cancelled and next_departure

func test_paused_and_stale_horns_are_consumed_without_late_replay():
	var audio:=EngineSound.new();var t:=Train.new("H",200);audio.train=t;t.automatic=true
	Cues.update(t,100,true)
	var silent:=not audio._departure_horn_due(true,100)
	silent=silent and not audio._departure_horn_due(false,100.1)
	Cues.update(t,103.5,false)
	silent=silent and not audio._departure_horn_due(false,105)
	audio.free();return silent

func test_passing_train_doppler_accounts_for_listener_motion():
	var ear:=Vector3.ZERO;var incoming:=Vector3(0,0,-100)
	var source_v:=Vector3(0,0,30);var listener_v:=Vector3(0,0,-20)
	var approach:=Space.doppler(incoming,ear,source_v,listener_v)
	var recede:=Space.doppler(-incoming,ear,source_v,listener_v)
	return approach>1.14 and recede<.88 and is_equal_approx(Space.doppler(incoming,ear,source_v,source_v),1)
func test_compartments_attenuate_other_trains_and_open_at_doorways():
	var middle:=Space.compartment("vb_tc_cc",Vector3(0,2,0),24,0)
	var door:=Space.compartment("vb_tc_cc",Vector3(0,2,11),24,1)
	var outside:=Space.compartment("vb_tc_cc",Vector3.ZERO,24,0,true)
	var closed:=Space.response(middle,false,"track")
	var opened:=Space.response(door,false,"track")
	return closed.x<.2 and closed.y<2000 and opened.x>closed.x*4 and opened.y>closed.y*4 and Space.response(outside,false,"track")==Vector2(1,18000)
func test_own_car_body_is_not_muffled_like_other_train():
	var cabin:=Space.compartment("lhb_3a",Vector3.ZERO,24,0)
	return Space.response(cabin,true,"track").x>Space.response(cabin,false,"track").x*2
func test_open_icf_window_exposes_more_air_than_sealed_vb():
	var window:=Vector3(1.35,2,0)
	return Space.compartment("icf_sl",window,24,0).exposure>Space.compartment("vb_tc_cc",window,24,0).exposure*5
func test_machinery_aisle_differs_from_pilot_seat():
	var aisle:=Space.response(Space.compartment("wap7",Vector3(0,2,0),21,0),true,"traction")
	var cab:=Space.response(Space.compartment("wap7",Vector3(0,2,8),21,0),true,"traction")
	return aisle.x>cab.x*2 and aisle.y>cab.y*2
func test_air_continues_to_increase_above_100_kmh_and_stops_at_rest():
	return Air.air_level(140/3.6,5,false,1)>Air.air_level(100/3.6,5,false,1)*1.5 and Air.air_level(0,5,false,1)==0 and Air.air_level(30,151,false,1)==0
func test_headphone_front_back_coloration_has_bounded_cutoffs():
	return Space.directional_cutoff(Vector3.FORWARD,Vector3.ZERO,Vector3.FORWARD)==18000 and Space.directional_cutoff(Vector3.BACK,Vector3.ZERO,Vector3.FORWARD)==6500
func test_arrival_and_departure_state_survives_save():
	var world:=preload("res://sim/layouts/traffic_service.gd").build()
	var t: Train=world.trains.values()[0]
	t.station_approach={key="approach",ceiling=7.5};t.horn_sequence=3;t.horn_emitted_at=28800.0;t.horn_pending_at=28803.5
	var saved:=Snapshot.capture(world);var loaded:=Snapshot.restore(saved)
	if not loaded.ok:return loaded.reason
	var other: Train=loaded.world.trains[t.id]
	return other.station_approach==t.station_approach and other.horn_pending_at==28803.5 and other.horn_sequence==3
func test_old_save_without_arrival_extension_still_restores():
	var world:=preload("res://sim/layouts/traffic_service.gd").build();var saved:=Snapshot.capture(world)
	for train in saved.trains:
		for key in Snapshot.ARRIVAL:train.erase(key)
	return Snapshot.restore(saved).ok
func test_invalid_saved_arrival_and_horn_values_are_rejected():
	var world:=preload("res://sim/layouts/traffic_service.gd").build();var saved:=Snapshot.capture(world)
	saved.trains[0].station_approach={key="bad",ceiling=NAN}
	if Snapshot.restore(saved).ok:return "NaN approach accepted"
	saved.trains[0].station_approach={};saved.trains[0].horn_sequence=-1
	return not Snapshot.restore(saved).ok
func test_recovery_rotation_keeps_manual_slots_and_newest_points():
	var folder:="res://.local/recovery-test-"+str(Time.get_ticks_usec());var store:=Store.new(folder)
	var data:=Snapshot.capture(preload("res://sim/layouts/traffic_service.gd").build())
	store.write_slot("1",data,{title="manual"})
	for i in 4:
		var result:=store.write_slot(store.next_auto(),data,{saved_at="2026-10-18 01:0%d:00"%i,title=str(i)})
		if not result.ok:return result.reason
	return store.read_slot("1").data.summary.title=="manual" and store.read_slot("auto1").data.summary.title=="3" and store.read_slot("auto1",true).data.summary.title=="0" and store.next_auto()=="auto2"

func test_passenger_door_cycle_does_not_open_wap_cab_acoustically():
	var position:=Vector3(0,3,9)
	return Space.compartment("wap7",position,20.4,0).exposure==Space.compartment("wap7",position,20.4,1).exposure
func test_machinery_transition_is_continuous_while_walking():
	var before:=Space.response(Space.compartment("wap7",Vector3(0,2,5.99),20.4,0),true,"traction")
	var after:=Space.response(Space.compartment("wap7",Vector3(0,2,6.01),20.4,0),true,"traction")
	return absf(before.x-after.x)<.01 and absf(before.y-after.y)<100

func test_passing_body_rush_does_not_jump_a_coach_length() -> bool:
	var air:=preload("res://game/train_air_audio.gd")
	var first:=Transform3D(Basis(Vector3.UP,.7),Vector3(100,0,50))
	var second:=first*Transform3D(Basis.IDENTITY,Vector3(0,0,24))
	var listener:=first*Vector3(8,3,12)
	var before:=air.body_position(first,24,listener)
	var after:=air.body_position(second,24,listener)
	return before.distance_to(after)<.21 and before.distance_to(listener)<9 and after.distance_to(listener)<9
