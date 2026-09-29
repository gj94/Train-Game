extends RefCounted

const Line := preload("res://sim/layouts/first_line.gd")
const Profile := preload("res://sim/stock/lhb_consist.gd")
const Audio := preload("res://game/train_audio.gd")


func test_passenger_audio_is_local_to_the_selected_coach():
	var ear := Vector2(Profile.coach_center(4), 1.5)
	return is_equal_approx(Audio.driver_distance(ear.x, ear), 1.5) and \
		Audio.driver_distance(ear.x) > 100 and Audio.driver_distance(2) == 1.5


func test_passenger_formation_fits_platforms():
	var w := Line.build_lhb()
	var t: Train = w.trains.T1
	if t.stock_kind != "lhb" or t.length != Profile.LENGTH or t.mass != Profile.MASS or t.can_change_ends:
		return "Incorrect passenger consist profile"
	for station in w.stations:
		for platform in station.platforms:
			if platform.size.x < t.length:
				return "Rake does not fit " + station.name
	return w.trains.size() == 1 and w.aspect("CPM-S1") == RailWorld.Aspect.GREEN


func test_loaded_rake_accelerates_slower_than_light_engine():
	var light := Line.build_wap7()
	var loaded := Line.build_lhb()
	light.trains.T1.controller = 1
	loaded.trains.T1.controller = 1
	light.step(20)
	loaded.step(20)
	return loaded.trains.T1.speed > 5 and loaded.trains.T1.speed < light.trains.T1.speed * .8


func test_lhb_red_signal_stop_with_tail_clear():
	var w := Line.build_lhb()
	var t: Train = w.trains.T1
	t.automatic = true
	w.step(450)
	var ns := w.next_signal(t)
	var tail := t.locate_behind(w.graph, t.length)
	return t.speed < .01 and ns.id == "MRT-SE1" and ns.distance >= 5 and \
		tail.edge == "mrt_main" and w.events.is_empty()


func test_lhb_arrives_with_all_coaches_inside_kadalur():
	var w := Line.build_lhb()
	var t: Train = w.trains.T1
	for pair in [["MRT-SE1", "KDP-H"], ["KDP-H", "BUFFER:KDP_B"]]:
		if not w.set_route(pair[0], pair[1]).ok:
			return "Could not set passenger route"
	t.automatic = true
	w.step(750)
	var tail := t.locate_behind(w.graph, t.length)
	return t.service_complete and t.speed < .01 and t.path.size() == 1 and \
		t.path[0].edge == "kdp_plat" and tail.edge == "kdp_plat" and tail.s > 5 and w.events.is_empty()


func test_lhb_cannot_magically_reverse_locomotive_and_coaches():
	var w := Line.build_lhb()
	var t: Train = w.trains.T1
	var before := t.path.duplicate(true)
	var result := w.reverse_train(t.id)
	return not result.ok and "run-round" in result.reason and not t.reverse(w.graph) and \
		t.path == before and t.head_s == 304 and t.cab_end == 1


func test_thirty_audio_axles_match_formation():
	var axles := Profile.sound_axles()
	if axles.size() != 30:
		return "Expected six locomotive and 24 coach axles"
	for i in range(1, axles.size()):
		if axles[i].x <= axles[i-1].x or axles[i].x > Profile.LENGTH:
			return "Axles must be in physical order inside the rake"
	for coach in 6:
		var first: Dictionary = axles[6 + coach * 4]
		var second: Dictionary = axles[7 + coach * 4]
		if first.car != coach + 1 or not is_equal_approx(second.x - first.x, 2.56):
			return "FIAT axle spacing or car assignment is wrong"
	return true
