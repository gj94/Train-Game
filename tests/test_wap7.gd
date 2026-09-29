extends RefCounted
## Light-engine working and instruments using the actual exported cab.

const Line := preload("res://sim/layouts/first_line.gd")
const Cab := preload("res://game/wap7_cab_view.gd")


func test_light_engine_profile_and_starter():
	var w := Line.build_wap7()
	var t: Train = w.trains.T1
	return w.trains.size() == 1 and t.stock_kind == "wap7" and t.cab_end == 1 and \
		is_equal_approx(t.length, 20.562) and t.mass == 108000 and not t.automatic and \
		t.controller == 0 and w.aspect("CPM-S1") == RailWorld.Aspect.GREEN


func test_complete_outbound_and_cab_two_return():
	var w := Line.build_wap7()
	var t: Train = w.trains.T1
	for pair in [["MRT-SE1", "KDP-H"], ["KDP-H", "BUFFER:KDP_B"]]:
		var result := w.set_route(pair[0], pair[1])
		if not result.ok:
			return result.reason
	t.automatic = true
	w.step(600)
	if not t.service_complete or t.path[0].edge != "kdp_plat" or t.speed > .01:
		return "WAP-7 failed outbound arrival"
	var old_tail := t.locate_behind(w.graph, t.length)
	var reverse := w.reverse_train(t.id)
	if not reverse.ok or t.cab_end != 2 or not is_equal_approx(t.head_s, old_tail.s):
		return "Cab change must swap the physical head and tail: " + str(reverse)
	for pair in [["KDP-S", "MRT-HW"], ["MRT-HW", "MRT-SW1"], ["MRT-SW1", "CPM-H"], ["CPM-H", "BUFFER:CPM_B1"]]:
		var result := w.set_route(pair[0], pair[1])
		if not result.ok:
			return result.reason
	t.automatic = true
	w.step(650)
	if not t.service_complete or t.path[0].edge != "cpm_p1" or t.speed > .01:
		return "Cab 2 failed return arrival"
	return w.events.is_empty()


func test_cannot_change_cab_while_moving():
	var w := Line.build_wap7()
	var t: Train = w.trains.T1
	t.speed = 5
	return not w.reverse_train(t.id).ok and t.cab_end == 1


func test_wap7_ai_stops_at_uncleared_maruthur_starter():
	var w := Line.build_wap7()
	var t: Train = w.trains.T1
	t.automatic = true
	w.step(400)
	var signal_ahead := w.next_signal(t)
	return t.speed < .01 and t.path[0].edge == "mrt_main" and not signal_ahead.is_empty() and \
		signal_ahead.id == "MRT-SE1" and signal_ahead.distance >= 5 and w.events.is_empty()


func test_wap7_exported_speed_dial_and_digital_agree():
	var t := Train.new("test", 20.562)
	var cab := Cab.new()
	cab.setup(t, 2)
	var result = true
	for sample in [[0.0, Vector3(-.707107, 0, .707107)], [80.0, Vector3(0, 0, -1)], [160.0, Vector3(.707107, 0, .707107)]]:
		t.speed = sample[0] / 3.6
		cab.update_instruments()
		if (cab._speed.basis * Vector3.RIGHT).distance_to(sample[1]) > .001 or cab._digital.text != "%03d" % sample[0]:
			result = "WAP-7 speed needle and digital disagree at %s" % sample[0]
	if not "CAB 2" in cab._display.text:
		result = "DDU must show the physical cab number"
	cab.free()
	return result


func test_wap7_emergency_indications_override_power():
	var t := Train.new("test", 20.562)
	var cab := Cab.new()
	cab.setup(t)
	t.controller = .8
	cab.update_instruments()
	var powered: bool = cab._lamps.PowerLamp.material_override == cab._lit.PowerLamp
	t.emergency = true
	cab.update_instruments()
	var result: bool = powered and cab._lamps.PowerLamp.material_override == cab._dark and \
		cab._lamps.EmergencyLamp.material_override == cab._lit.EmergencyLamp and \
		"BRAKE 100%" in cab._display.text and "EMERGENCY" in cab._display.text and \
		(cab._brake.basis * Vector3.RIGHT).distance_to(Vector3(.707107, 0, .707107)) < .001
	cab.free()
	return result
