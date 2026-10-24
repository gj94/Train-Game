extends RefCounted
const Details:=preload("res://game/dispatch_forecast_details.gd")
const Snapshot:=preload("res://sim/world_snapshot.gd")

func test_etas_across_midnight_include_the_correct_operating_day():
	return Details.time_label(86430,86300)=="00:00:30 · day 2" and Details.time_label(86430,86400)=="00:00:30"

func railway() -> RailWorld:
	var fixture:=preload("res://tests/test_predictive_dispatch.gd").new()
	var w: RailWorld=fixture.restored();var engine=w.dispatcher()
	engine.predictive.accept(w,engine,fixture.prepare(w));engine.enabled=true
	return w

func test_both_participants_see_the_same_current_pass_without_mutation():
	var w:=railway();var before:=var_to_bytes(Snapshot.capture(w))
	var slow:=Details.describe(w,"K1");var fast:=Details.describe(w,"B002")
	return slow.available and fast.available and slow.text==fast.text and slow.station_code=="STKT" and slow.other_id=="B002" and fast.other_id=="K1" and before==var_to_bytes(Snapshot.capture(w))

func test_expired_forecast_does_not_remain_visible_as_a_current_plan():
	var w:=railway();w.time+=16
	var result:=Details.describe(w,"K1")
	return not result.available and result.text.contains("No current passing proposal") and not result.text.contains("clear in receiving road")

func test_disabled_dispatch_does_not_present_saved_advice_as_an_active_plan():
	var w:=railway();w.dispatcher().enabled=false
	var result:=Details.describe(w,"B002")
	return not result.available and result.text.contains("Automatic dispatch is off")

func test_following_choice_does_not_claim_a_receiving_road_or_an_overtake():
	var w:=railway();w.dispatcher().predictive.plans.K1.action="follow"
	var result:=Details.describe(w,"K1")
	return result.available and result.text.contains("Keep following order") and result.text.contains("No overtake is proposed") and not result.text.contains("receiving road:") and result.text.contains("Signals still govern movement")
