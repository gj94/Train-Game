extends RefCounted
const Journey := preload("res://game/journey_hud.gd")

func test_distance_is_metres_and_eta_is_in_game_minutes():
	var p:={scheduled=true,next_name="Kumbalam",distance_m=3127.4,estimated_seconds=124.0}
	return Journey.text(p)=="Kumbalam · 3,127 m · ~3 min"

func test_signal_wait_is_not_presented_as_a_promised_arrival_time():
	var p:={scheduled=true,next_name="Turavur",distance_m=470,estimated_seconds=32,waiting="Wait for K3"}
	return Journey.text(p)=="Turavur · 470 m · <1 min + signal wait"

func test_missing_route_and_missed_stop_never_format_infinity_as_minutes():
	var p:={scheduled=true,next_name="Alappuzha",distance_m=INF,estimated_seconds=INF}
	if Journey.text(p)!="Alappuzha · Awaiting route": return false
	p.missed=true
	return Journey.text(p)=="Alappuzha · Stop missed · F12 for options"

func test_no_schedule_and_completed_service_are_distinct():
	return Journey.text({scheduled=false})=="No scheduled stops" and Journey.text({scheduled=true,complete=true})=="All scheduled stops completed"
