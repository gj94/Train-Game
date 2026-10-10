extends Node
## Rendering-free forward simulation, with a responsive 2D progress menu.
const Advance := preload("res://sim/time_skip.gd")
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

func _ready() -> void:
	process_mode=Node.PROCESS_MODE_ALWAYS

func running() -> bool:
	# Main-thread ownership flag, never inspect worker-owned trial/world here.
	return not _saved.is_empty()

func show_page(title: String, body: String, options: Array) -> void:
	game.hud.save_menu={title=title,body=body,options=options}
	game.hud.show_modal("time_skip")

func open() -> void:
	game._set_paused(true);game.dispatcher.set_open(false);game._restore_ui()
	var options: Array=[["Back","skip:back"],["Choose clock time…","skip:clock"]]
	var t: Train=game.train
	if t.timetable!=null and not t.service_complete:
		var next: int=t.timetable.index+1 if t.timetable.at_stop else t.timetable.index
		if next<t.timetable.stops.size():options.append(["Next stop · "+t.timetable.stops[next].name,"skip:stop:"+str(next)])
		options.append(["Choose a later stop…","skip:stops"])
	show_page("SKIP FORWARD","All trains will run under AI and the dispatcher. 3D scenery, train rendering and sound stop during the advance.\nReturn to your train if it is available, otherwise to a station platform. You can stop the advance at any time; elapsed simulation is retained.",options)

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

func start(clock: float, stop: int=-1) -> void:
	if running():return
	trial=Advance.new(game.world)
	var result: Dictionary=trial.to_stop(game.train.id,stop) if stop>=0 else trial.to_time(clock)
	if not result.ok:
		trial=null;game.hud.toast(result.reason,true);return
	game._set_paused(true)
	game.dispatcher.set_open(false)
	game.dispatcher.auto_dispatch=true
	game.walker.stop()
	game.controller.neutralize()
	_saved={process=game.process_mode,hud_process=game.hud.process_mode,controller_process=game.controller.process_mode,disable_3d=game.get_viewport().disable_3d,mute=AudioServer.is_bus_mute(0)}
	game.process_mode=Node.PROCESS_MODE_DISABLED
	game.hud.process_mode=Node.PROCESS_MODE_ALWAYS
	game.controller.process_mode=Node.PROCESS_MODE_ALWAYS
	game.get_viewport().disable_3d=true
	AudioServer.set_bus_mute(0,true)
	_started=Time.get_ticks_msec();_refresh=0
	_target=Clock.format_time(trial.target_clock)
	if stop>=0:_target=game.train.timetable.stops[stop].name
	_cancel_requested=false;_quit_requested=false;_preparing=true
	show_page("ADVANCING THE RAILWAY","Finishing current scenery jobs before advancing…",[["Stop advancing here","skip:cancel"]])

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
		progress={clock=game.world.clock_seconds(),start_clock=trial.start_clock}
	_refresh-=delta
	if _refresh<=0:
		_refresh=.2
		var simulated: float=progress.clock-progress.start_clock
		var elapsed:=maxf(.001,(Time.get_ticks_msec()-_started)/1000.0)
		game.hud._body.text="Now: day %d · %s\nTarget: %s\n%.1f world minutes advanced · %.1f× real time\n\nAll services use AI. 3D rendering and sound are disabled.\n%s" % [Clock.day(progress.clock),Clock.format_time(progress.clock),_target,simulated/60,simulated/elapsed,"Stopping after the current simulation step…" if _cancel_requested else "Stopping keeps the simulation at its current time."]

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
	_saved.clear()
	for motion in game.train_motions.values():motion.reset()
	for sound in game.train_audio.values():sound.reset_positions();sound.set_paused(true)
	game.traffic_presentation.followed_service=""
	game.traffic_presentation._check_in=0
	game._journey_refresh=0
	game._set_time_scale(1)
	game._render_trains(1.0)
	var available: bool=game.train.lifecycle=="active" and not preload("res://sim/depot_workings.gd").finished(game.world,game.train)
	if available:
		game.world.dispatcher().manual_service=game.train.id
		game._pilot_camera()
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
	game.controller.neutralize();game._drive_keys_armed=false
	game._set_paused(true)
	var options: Array=[["Resume with AI driving","skip:resume"],["Open Dispatch","skip:dispatch"],["Skip further…","skip:open"]]
	if available:options.insert(1,["Take control of this train","skip:drive"])
	show_page("ADVANCE COMPLETE" if trial.ok else "ADVANCE STOPPED",trial.report+"\n"+("You are back in "+game.train.id+" with AI driving." if available else "Your service has finished or is unavailable. You are outside on a station platform; choose another active service in Dispatch.")+"\nPaused while you choose what to do next.",options)
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
		AudioServer.set_bus_mute(0,_saved.mute)
		get_viewport().disable_3d=_saved.disable_3d
		_saved.clear()
