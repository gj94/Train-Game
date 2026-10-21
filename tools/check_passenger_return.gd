extends "res://tools/check_controller_playable.gd"
func _initialize() -> void:
	set_meta("route","southern_corridor");set_meta("imported_fleet","lhb");set_meta("traffic_drive",false)
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--fleet="):set_meta("imported_fleet",arg.trim_prefix("--fleet="))
	call_deferred("run")
func hold_r3() -> void:
	button(JOY_BUTTON_RIGHT_STICK,true);pad._process(.3);pad._process(.4);button(JOY_BUTTON_RIGHT_STICK,false);await frames()
func resume() -> void:
	game.hud.show_modal("");game._set_paused(false);await frames()
func skip_seconds(seconds: float, cancel_now: bool=false) -> void:
	game.time_skip.start(game.world.clock_seconds()+seconds)
	if cancel_now:game.time_skip.cancel()
	var began:=Time.get_ticks_msec()
	while game.time_skip.running() and Time.get_ticks_msec()-began<20000:await process_frame
	check(not game.time_skip.running(),"Skip joined within timeout")
func run() -> void:
	change_scene_to_file("res://game/main.tscn");await process_frame;await process_frame
	game=current_scene;pad=game.controller
	game.set_process(false);game.set_physics_process(false);game.cam.set_process(false);pad.set_process(false)
	game.journey_tools.autosaves=false;game.journey_tools.save_directory="res://.local/r44/test-saves"
	game.time_skip.settings_path="res://.local/r44/skip-test.cfg";game.time_skip.return_passenger=true;game.time_skip.show_map=false
	pad.window_focus(true);pad._adopt(DEVICE);pad._set_mode(true)
	await resume();game._passenger_preset(0);game.tv.passenger_seat=true;game.tv.passenger_seat_index=8;game._passenger_seating_changed();await frames()
	var car: int=game.tv.passenger_coach
	check(game.passenger_bookmark.current().seat==8,"Sitting remembers exact seat")
	game.cam._look=Vector2(.35,.12);await hold_r3()
	check(game.passenger_bookmark.current().look==Vector2(.35,.12),"Hold R3 remembers view direction without tap recenter")
	game._pilot_camera();game.train.automatic=false;await frames();await hold_r3()
	check(game._passenger_seated() and game.train.automatic and game.tv.passenger_coach==car and game.tv.passenger_seat_index==8,"Hold R3 returns from pilot, same coach/seat, AI owns controls")
	check(game.cam._look==Vector2(.35,.12),"Return restores view direction")
	await tap(JOY_BUTTON_RIGHT_STICK);check(game.cam._look==Vector2.ZERO and game._passenger_seated(),"Tap R3 only recenters")
	game.cam._look=Vector2(.25,.1)
	await skip_seconds(5)
	check(game._passenger_seated() and game.tv.passenger_seat_index==8 and game.paused and game.train.automatic,"Clock skip returns paused in seat with AI")
	check(game.cam._look==Vector2(.25,.1),"Clock skip preserves passenger view direction")
	await resume();await skip_seconds(30,true)
	check(game._passenger_seated() and game.tv.passenger_coach==car,"Cancelled skip returns to passenger seat")
	await resume();game.time_skip.return_passenger=false;await skip_seconds(5)
	check(game.cam.mode==1 and game.train.automatic,"Opt out returns pilot with AI")
	check(game.hud.save_menu.options.any(func(o):return o[1]=="skip:passenger"),"Result offers passenger choice when preference is off")
	game.time_skip.action("skip:passenger");await frames()
	check(game._passenger_seated() and not game.paused,"Result passenger action resumes in seat")
	var saved: Dictionary=game.save_load.capture_session()
	game.passenger_bookmark.seats.clear();game.save_load.restore_view(saved)
	check(game.passenger_bookmark.current().seat==8,"Save/load preserves bookmark")
	await resume();game._pilot_camera();await frames()
	var old: Dictionary=saved.duplicate(true);old.erase("passenger_bookmarks");game.save_load.restore_view(old)
	check(game._passenger_seated(),"Older saves still restore seat and seed bookmark")
	var bad: Dictionary=game.passenger_bookmark.current();bad.car=999
	check(not game.passenger_bookmark.restore(bad,false),"Invalid car safely rejected")
	bad=game.passenger_bookmark.current();bad.service="OTHER"
	check(not game.passenger_bookmark.restore(bad,false),"Bookmark never changes assigned service")
	# The completion path must refuse a bookmark after service storage.
	game.train.lifecycle="stored"
	check(not game.passenger_bookmark.restore({},false),"Finished/unavailable service cannot be boarded")
	game.train.lifecycle="active"
	await resume();game.time_skip.return_passenger=true
	game.time_skip.start(game.world.clock_seconds()+30);game.time_skip.cancel();game.train.lifecycle="stored"
	var began:=Time.get_ticks_msec()
	while game.time_skip.running() and Time.get_ticks_msec()-began<10000:await process_frame
	check(not game.time_skip.running() and game.cam.mode==0 and not game.cam.follow and game.paused,"Finished service returns to platform observer, not stale seat")
	game.train.lifecycle="active"
	game.journey_tools.flush();game.queue_free();await process_frame;await process_frame
	print("PASSENGER_RETURN ",checks," checks, ",failures," failures");quit(0 if failures==0 else 1)
