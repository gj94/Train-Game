extends Node
## Rendering-free forward simulation, with a responsive 2D progress menu.
const Advance := preload("res://sim/time_skip.gd")
const EventAdvance := preload("res://sim/skip_to_event.gd")
const Options := preload("res://sim/skip_options.gd")
const MapState := preload("res://sim/skip_map_state.gd")
const Worker := preload("res://sim/time_skip_worker.gd")
const Clock := preload("res://sim/world_clock.gd")
var game
var trial
var selected_clock := 0.0
var _saved := {}
var _started := 0
var _refresh := 0.0
var _worker
var _preparing := false
var _cancel_requested := false
var _quit_requested := false
var _target := ""
var event_options := Options.DEFAULTS.duplicate()
var show_map := true
var return_passenger := true
var _passenger_return := {}
var settings_path := "user://time_skip.cfg"
var _dismissed: Array = []
var _world_id := 0
var _dismissed_service := ""

func _ready() -> void:
	process_mode=Node.PROCESS_MODE_ALWAYS
	load_settings()

func load_settings() -> void:
	var config:=ConfigFile.new();config.load(settings_path)
	var raw:={}
	for key in Options.DEFAULTS:raw[key]=config.get_value("events",key,Options.DEFAULTS[key])
	event_options=Options.normalized(raw)
	show_map=config.get_value("view","dispatcher",true)==true
	return_passenger=config.get_value("view","return_passenger",true)==true

func settings_page() -> void:
	game._set_paused(true);game.dispatcher.set_open(false)
	var choices: Array=[["Back","skip:open"]]
	for key in Options.DEFAULTS:
		choices.append([Options.LABELS[key]+": "+("ON" if event_options[key] else "OFF"),"skip:toggle:"+key])
	choices.append(["Show dispatcher while skipping: "+("ON" if show_map else "OFF"),"skip:toggle:map"])
	choices.append(["Return to passenger seat: "+("ON" if return_passenger else "OFF"),"skip:toggle:passenger"])
	show_page("TIME-SKIP SETTINGS","These events interrupt Next event only. Clock and future-stop targets stay explicit.\nStops: 1 km before the marker, or earlier for comfortable braking. Passes: about 60 seconds before the first side-by-side contact. Signal: red changes to yellow or green while holding your train.\nSafety interventions, service completion and the 24-hour search limit always stop Next event.",choices)

func save_settings() -> void:
	var config:=ConfigFile.new()
	for key in event_options:config.set_value("events",key,event_options[key])
	config.set_value("view","dispatcher",show_map)
	config.set_value("view","return_passenger",return_passenger)
	var error:=config.save(settings_path)
	if error!=OK:game.hud.toast("Could not save time-skip preferences",true)

func running() -> bool:
	# Main-thread ownership flag, never inspect worker-owned trial/world here.
	return not _saved.is_empty()

func show_page(title: String, body: String, options: Array, map_mode: bool=false) -> void:
	game.hud.save_menu={title=title,body=body,options=options,map_mode=map_mode}
	game.hud.show_modal("time_skip")

func open() -> void:
	game._set_paused(true);game.dispatcher.set_open(false);game._restore_ui()
	var options: Array=[["Back","skip:back"],["Skip to next event","skip:event"],["Choose which events interrupt…","skip:settings"],["Choose clock time…","skip:clock"]]
	options.append(["After skip: "+("return to passenger seat if seated" if return_passenger else "pilot view with AI driving"),"skip:return_mode"])
	var t: Train=game.train
	if t.timetable!=null and not t.service_complete:
		var next: int=t.timetable.index+1 if t.timetable.at_stop else t.timetable.index
		if next<t.timetable.stops.size():options.append(["Next stop · "+t.timetable.stops[next].name,"skip:stop:"+str(next)])
		options.append(["Choose a later stop…","skip:stops"])
	show_page("SKIP FORWARD","All trains run under AI while the live dispatcher follows your service. 3D and sound stop.\nNext event finds the earliest enabled interruption from the actual railway, including delays. An encounter search looks a minute ahead; its map shows the committed position you can return to.\nYou return paused with AI driving, ready to take over. Stop advancing here returns to the displayed position.",options)

func clock_page() -> void:
	if selected_clock<=game.world.clock_seconds():selected_clock=ceil(game.world.clock_seconds()/60.0)*60+900
	var options: Array=[["Back","skip:open"],["Advance to day %d · %s" % [Clock.day(selected_clock),Clock.format_time(selected_clock)],"skip:start_time"]]
	for minutes in [-60,-5,-1,1,5,60]:
		options.append([("%+d minute%s" % [minutes,"" if absi(minutes)==1 else "s"]),"skip:adjust:"+str(minutes)])
	show_page("CHOOSE TIME","Now: day %d · %s\nTarget: day %d · %s\nForward only, up to 24 hours. D-pad / stick selects a button; A adjusts or starts." % [game.world.clock_day(),game.world.clock_text(),Clock.day(selected_clock),Clock.format_time(selected_clock)],options)

func stop_page() -> void:
	var options: Array=[["Back","skip:open"]]
	var t: Train=game.train
	if t.timetable!=null and not t.service_complete:
		for i in range(t.timetable.index,t.timetable.stops.size()):
			if t.timetable.actual_arrivals[i]>=0:continue
			options.append(["%s · booked %s" % [t.timetable.stops[i].name,Clock.format_time(t.timetable.planned_arrival(i))],"skip:stop:"+str(i)])
	show_page("CHOOSE A FUTURE STOP","Advance until your service actually arrives, including dispatch waits and crossings. The booked time is a guide.",options)

func action(command: String) -> void:
	if running():
		if command in ["skip:cancel","skip:back"]:cancel()
		return
	var parts:=command.split(":")
	match parts[1]:
		"open":open()
		"event":start(-1,-1,true)
		"settings":settings_page()
		"toggle":
			if parts[2]=="map":show_map=not show_map
			elif parts[2]=="passenger":return_passenger=not return_passenger
			elif event_options.has(parts[2]):event_options[parts[2]]=not event_options[parts[2]]
			save_settings();settings_page();game.hud.focus_action(command)
		"return_mode":return_passenger=not return_passenger;save_settings();open();game.hud.focus_action(command)
		"passenger":
			if game.passenger_bookmark.restore(_passenger_return):game.hud.show_modal("");game._set_paused(false)
		"back":back()
		"clock":clock_page()
		"adjust":
			var minimum: float=floor(game.world.clock_seconds()/60.0)*60+60
			selected_clock=clampf(selected_clock+float(parts[2])*60,minimum,game.world.clock_seconds()+86400)
			clock_page()
			game.hud._buttons.get_child(2+[-60,-5,-1,1,5,60].find(int(parts[2]))).grab_focus()
		"stops":stop_page()
		"stop":start(-1,int(parts[2]))
		"start_time":start(selected_clock)
		"cancel":
			cancel()
		"resume":
			game.hud.show_modal("");game._set_paused(false)
		"drive":
			game.hud.show_modal("");game._set_paused(false);game._enter_cab()
		"dispatch":
			game.hud.show_modal("");game.dispatcher.set_open(true)

func start(clock: float, stop: int=-1, next_event: bool=false) -> void:
	if running():return
	if _world_id!=game.world.get_instance_id() or _dismissed_service!=game.train.id:
		_dismissed.clear();_world_id=game.world.get_instance_id();_dismissed_service=game.train.id
	trial=EventAdvance.new(game.world) if next_event else Advance.new(game.world)
	var layout: Dictionary=MapState.geometry(game.world) if show_map else {}
	if show_map:trial.configure_preview(game.train.id,layout)
	var result: Dictionary=trial.to_event(game.train.id,event_options,_dismissed) if next_event else (trial.to_stop(game.train.id,stop) if stop>=0 else trial.to_time(clock))
	if not result.ok:
		trial=null;game.hud.toast(result.reason,true);return
	game.journey_tools.autosave("Before time skip",true)
	_passenger_return=game.passenger_bookmark.capture()
	game._set_paused(true)
	game.dispatcher.set_open(false)
	game.dispatcher.auto_dispatch=true
	game.walker.stop()
	game.controller.neutralize()
	_saved={process=game.process_mode,hud_process=game.hud.process_mode,controller_process=game.controller.process_mode,disable_3d=game.get_viewport().disable_3d,mute=AudioServer.is_bus_mute(0),fps=Engine.max_fps}
	Engine.max_fps=mini(30,Engine.max_fps) if Engine.max_fps>0 else 30
	game.process_mode=Node.PROCESS_MODE_DISABLED
	game.hud.process_mode=Node.PROCESS_MODE_ALWAYS
	game.controller.process_mode=Node.PROCESS_MODE_ALWAYS
	game.get_viewport().disable_3d=true
	AudioServer.set_bus_mute(0,true)
	_started=Time.get_ticks_msec();_refresh=0
	_target=Clock.format_time(trial.target_clock)
	if next_event:_target="Next selected event"
	if stop>=0:_target=game.train.timetable.stops[stop].name
	_cancel_requested=false;_quit_requested=false;_preparing=true
	game.hud.time_skip_map.layout=layout;game.hud.time_skip_map.state={}
	if show_map:game.hud.time_skip_map.update_state(trial.presentation().map)
	show_page("ADVANCING THE RAILWAY","Finishing current scenery jobs before advancing…",[["Stop advancing here · B / Esc","skip:cancel"]],show_map)

func _scenery_busy() -> bool:
	if not game.geographic_drive:return false
	# Do not join render workers here: their GPU uploads need the UI/render loop.
	# New jobs cannot start with game processing disabled. Finished results wait
	# for normal scenery activation after the simulation worker has returned.
	if game.wv._asset_worker!=null and game.wv._asset_worker.busy():return true
	return game.wv.workers.any(func(w):return w.runner.busy())

func _process(delta: float) -> void:
	if not running():return
	if _preparing:
		if _cancel_requested:
			trial.cancel();finish();return
		if _scenery_busy():return
		_preparing=false;_worker=Worker.new()
		var error: Error=_worker.start(trial)
		if error!=OK:
			_worker=null
			game.hud.toast("Simulation worker unavailable; advancing on the main thread",true)
	var progress: Dictionary
	if _worker!=null:
		var result: Dictionary=_worker.take()
		if not result.is_empty():
			trial=result.trial;_worker=null;finish();return
		progress=_worker.progress()
	else:
		# Fail safely on machines where creating a thread is unavailable.
		if _cancel_requested:trial.cancel()
		var until:=Time.get_ticks_usec()+12000
		while Time.get_ticks_usec()<until and not trial.done:trial.step()
		if trial.done:finish();return
		progress=trial.presentation();progress.start_clock=trial.start_clock
	_refresh-=delta
	if _refresh<=0:
		_refresh=.1
		var simulated: float=progress.clock-progress.start_clock
		var elapsed:=maxf(.001,(Time.get_ticks_msec()-_started)/1000.0)
		game.hud.time_skip_map.update_state(progress.get("map",{}))
		game.hud._body.text="Day %d · %s    |    %s\n%.1f world minutes advanced · %.1f× real time · All services on AI\n%s\n%s" % [Clock.day(progress.clock),Clock.format_time(progress.clock),_target,simulated/60,simulated/elapsed,progress.get("map",{}).get("status",""),"Stopping safely…" if _cancel_requested else ("Checking the next minute for encounters · map shows your committed position" if progress.get("forecasting",false) else "Live railway · 3D and sound disabled")]

func cancel() -> void:
	if not running():return
	_cancel_requested=true
	if _worker!=null:_worker.request_cancel()

func request_quit() -> void:
	_quit_requested=true
	cancel()

func finish() -> void:
	assert(_worker==null) # World ownership must be joined before presentation reads it.
	_preparing=false
	game.process_mode=_saved.process
	game.hud.process_mode=_saved.hud_process
	game.controller.process_mode=_saved.controller_process
	game.get_viewport().disable_3d=_saved.disable_3d
	AudioServer.set_bus_mute(0,_saved.mute)
	Engine.max_fps=_saved.fps
	_saved.clear()
	if trial is EventAdvance and not trial.last_event.is_empty() and trial.ok:
		_dismissed.append(trial.last_event.duplicate(true))
		if _dismissed.size()>32:_dismissed.pop_front()
	game.hud.time_skip_map.state={};game.hud.time_skip_map.layout={}
	for motion in game.train_motions.values():motion.reset()
	for sound in game.train_audio.values():sound.reset_positions();sound.set_paused(true)
	game.traffic_presentation.followed_service=""
	game.traffic_presentation._check_in=0
	game._journey_refresh=0
	game._set_time_scale(1)
	game._render_trains(1.0)
	var available: bool=game.train.lifecycle=="active" and not preload("res://sim/depot_workings.gd").finished(game.world,game.train)
	var passenger_restored:=false
	if available:
		game.world.dispatcher().manual_service=game.train.id
		if return_passenger and not _passenger_return.is_empty():passenger_restored=game.passenger_bookmark.restore(_passenger_return,false)
		if not passenger_restored:game._pilot_camera()
		game.cam._blend=1;game.cam._follow_anchor_valid=false
		game.cam.global_transform=game.cam._target()
	else:
		var head: Dictionary=game.train.path[0]
		var observer: Vector3=game.world.graph.position(head.edge,game.train.head_s)
		var spot: Dictionary=preload("res://game/platform_camera.gd").nearest(game.world,observer)
		var origin: Vector3=game.wv.coordinate_origin if game.geographic_drive else Vector3.ZERO
		game.cam.enter_free(spot.get("eye",observer+Vector3.UP*2)-origin,spot.get("forward",Vector3.FORWARD))
		game._set_cab_visuals(false)
		game.controller._free_train_controls=false
	game.train.automatic=true
	game.wv.update_environment(true) # Joined worker: restore the destination sky before the next draw.
	game.controller.neutralize();game._drive_keys_armed=false
	game._set_paused(true)
	var options: Array=[["Resume with AI driving","skip:resume"],["Open Dispatch","skip:dispatch"],["Skip further…","skip:open"]]
	if available:options.insert(1,["Take control of this train","skip:drive"])
	if available and not passenger_restored and game.passenger_bookmark.valid(_passenger_return):options.insert(1,["Return to passenger seat","skip:passenger"])
	show_page("ADVANCE COMPLETE" if trial.ok else "ADVANCE STOPPED",trial.report+"\n"+(("Back in "+preload("res://game/passenger_bookmark.gd").label(_passenger_return)+" · AI driving." if passenger_restored else "You are back in "+game.train.id+" with AI driving.") if available else "Your service has finished or is unavailable. You are outside on a station platform; choose another active service in Dispatch.")+"\nPaused while you choose what to do next.",options)
	if _quit_requested:game._request_action("quit")

func back() -> void:
	if running():cancel()
	else:game.hud.show_modal("pause",game.labels_enabled)

func _unhandled_input(event: InputEvent) -> void:
	if game.hud.modal=="time_skip" and event.is_action_pressed("ui_cancel"):
		back();get_viewport().set_input_as_handled()

func _exit_tree() -> void:
	if _worker!=null:_worker.close();_worker=null
	if not _saved.is_empty():
		Engine.max_fps=_saved.fps
		AudioServer.set_bus_mute(0,_saved.mute)
		get_viewport().disable_3d=_saved.disable_3d
		_saved.clear()
