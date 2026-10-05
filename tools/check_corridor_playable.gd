extends SceneTree
## Full six-service UI test; writes a reproducible four-platform visual checkpoint.
const Dispatch := preload("res://sim/dispatch_plan.gd")
func _initialize():
	set_meta("imported_fleet", "") # Explicitly choose the six-MEMU dispatcher scenario.
	call_deferred("_check")
func _check():
	change_scene_to_file("res://game/main.tscn")
	await process_frame
	await process_frame
	var game = current_scene
	game.paused = true
	var w: RailWorld = game.world
	var desk = game.dispatcher
	if not _expect(w.trains.size()==6 and game.train_views.size()==6,"Six rendered services"): return
	desk._auto_button.pressed.emit()
	desk._hold_button.pressed.emit()
	if not _expect(desk.auto_dispatch and desk.hold_arrivals,"Traffic demo and hold buttons"): return
	desk._roster.T6.pressed.emit()
	if not _expect(game.train.id=="T6" and game.audio.train.id=="T6","Sixth roster entry selects train/cab/audio"): return
	desk.select_signal("MRT-HE",true)
	desk._select_destination("MRT-E2")
	if not _expect(desk._exit.item_count==2 and desk._map.destination=="MRT-E2","Route chooser lists both eastbound platforms once"): return
	desk._map.focus_station(1)
	desk.toggle_timetable()
	if not _expect(desk._timetable._items[1].get_text(1)=="MRT_P3","Timetable matches selected sixth service"): return
	desk.toggle_timetable()
	var berth_peak := 0
	for i in 430:
		Dispatch.update(w,desk.hold_arrivals)
		w.step(5)
		var count := 0
		for t in w.trains.values():
			if t.path[0].edge.begins_with("MRT_P") and t.speed<.01: count+=1
		berth_peak = maxi(count,berth_peak)
		if count==4 and w.trains.T5.speed<.01 and w.trains.T6.speed<.01:
			_save_checkpoint(w)
			break
	if not _expect(berth_peak==4,"Four actual platform arrivals"): return
	if not _expect(not w.set_route("MRT-HE","MRT-E1").ok,"Occupied platform route refused"): return
	desk._hold_button.pressed.emit()
	for i in 600:
		Dispatch.update(w,desk.hold_arrivals)
		w.step(5)
		if w.trains.values().all(func(t): return t.service_complete): break
	desk._refresh()
	if not _expect(w.events.is_empty() and w.trains.values().all(func(t):return t.service_complete),"All six finish without SPAD, collision intervention or point run-through"): return
	if not _expect(desk._restart.visible,"Restart available after all six services"): return
	for view in game.train_views.values(): view.update()
	print("Corridor integration: PASS (6 rendered trains, 4 simultaneous arrivals, following holds, occupied-route refusal, route chooser, roster, timetable, six completions)")
	quit()
func _save_checkpoint(w):
	var data := {time=w.time,signals=w.signals,switches={},trains={}}
	for id in w.graph.switches: data.switches[id] = w.graph.switches[id].reversed
	for t in w.trains.values():
		var values := {}
		for key in ["path","head_s","speed","odometer","controller","status","service_complete"]: values[key]=t.get(key)
		values.timetable = {}
		for key in ["index","at_stop","actual_arrivals","actual_departures","missed_stop"]: values.timetable[key]=t.timetable.get(key)
		data.trains[t.id]=values
	var f=FileAccess.open("res://.local/corridor-arrivals.json",FileAccess.WRITE)
	f.store_string(JSON.stringify(data))
func _expect(condition: bool, label: String) -> bool:
	if not condition:
		printerr("Corridor integration FAIL: ",label)
		quit(1)
	return condition
