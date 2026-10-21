extends SceneTree
const Snapshot:=preload("res://sim/world_snapshot.gd")
var checks:=0
var failures:=0
func _initialize() -> void:call_deferred("run")
func check(ok: bool,label: String) -> void:
	checks+=1
	if not ok:failures+=1;printerr("FAIL ",label)
func frames() -> void:
	for i in 4:await process_frame
func tap(page,button: int) -> void:
	var event:=InputEventJoypadButton.new();event.button_index=button;event.pressed=true;page._input(event);await frames()
func axis(page,which: int,value: float) -> void:
	var event:=InputEventJoypadMotion.new();event.axis=which;event.axis_value=value;page._input(event)
func loaded(page) -> bool:
	var began:=Time.get_ticks_msec()
	while page.worker!=null or page.loaded_index!=page.requested:
		await process_frame
		if Time.get_ticks_msec()-began>60000:check(false,"Preview load timeout");return false
	await frames();return page.world!=null
func run() -> void:
	DirAccess.make_dir_recursive_absolute("res://.local/r45/timeline-passenger")
	root.size=Vector2i(1280,720);root.content_scale_size=root.size
	var page:=preload("res://game/launch_timeline.gd").new();root.add_child(page);current_scene=page
	if not await loaded(page):quit(1);return
	var index:=-1
	for i in page.states.size():
		if page.states[i].clock==20*3600:index=i;break
	if index<0:check(false,"20:00 baseline available");quit(1);return
	page.choose(index)
	check(page.board_button.disabled and page.passenger_button.disabled,"Both boarding roles disabled while time changes")
	if not await loaded(page):quit(1);return
	var moving: Array=page.services.filter(func(t):return t.speed>3)
	if moving.is_empty():check(false,"Night baseline contains moving service");quit(1);return
	page._select_train(moving[0].id);var id:=page.selected_id
	var before:=Snapshot.capture(page.world);var original_time:=page.world.clock_seconds()
	page.roster.grab_focus();await tap(page,JOY_BUTTON_A)
	check(root.gui_get_focus_owner()==page.board_button,"A inspects the service before boarding")
	await tap(page,JOY_BUTTON_DPAD_RIGHT)
	check(root.gui_get_focus_owner()==page.passenger_button,"Right selects passenger boarding")
	await tap(page,JOY_BUTTON_DPAD_LEFT)
	check(root.gui_get_focus_owner()==page.board_button,"Left returns to pilot boarding")
	axis(page,JOY_AXIS_TRIGGER_LEFT,.8);axis(page,JOY_AXIS_TRIGGER_RIGHT,.8)
	check(is_zero_approx(page._zoom),"Equal triggers cancel zoom")
	axis(page,JOY_AXIS_TRIGGER_RIGHT,0)
	check(is_equal_approx(page._zoom,-.8),"Releasing RT preserves held LT zoom")
	page._notification(Control.NOTIFICATION_APPLICATION_FOCUS_OUT)
	check(page._triggers==Vector2.ZERO and page._zoom==0,"Focus loss releases both zoom axes")
	page._notification(Control.NOTIFICATION_APPLICATION_FOCUS_IN)
	for resolution in [Vector2i(1280,720),Vector2i(1600,900)]:
		root.size=resolution;root.content_scale_size=resolution;await frames()
		for label in [page.footer,page.version_label]:check(root.get_visible_rect().encloses(label.get_global_rect()),"Help/version fits "+str(resolution))
		for button in [page.board_button,page.passenger_button,page.visit_button]:
			check(root.get_visible_rect().encloses(button.get_global_rect()),"Boarding action fits "+str(resolution)+" "+button.text)
		if DisplayServer.get_name()!="headless":
			await RenderingServer.frame_post_draw;root.get_texture().get_image().save_png("res://.local/r45/timeline-passenger/preview-"+str(resolution.y)+".png")
	await tap(page,JOY_BUTTON_Y);await tap(page,JOY_BUTTON_X)
	check(page.map.inspected_train==id and page.map.span<10000,"X locates selected service after full-route view")
	check(var_to_bytes(before)==var_to_bytes(Snapshot.capture(page.world)),"Controller inspection preserves complete railway")
	if "--inspect-only" in OS.get_cmdline_user_args():
		page.choose(page.states.size()-1)
		if not await loaded(page):quit(1);return
		check(page.services.is_empty() and page.board_button.disabled and page.passenger_button.disabled and not page.visit_button.disabled,"Finished day offers station visits only")
		page.queue_free();await frames()
	else:
		# Freeze the newly entered source scene before its first render/update frame.
		# This fixture checks boarding state; headless Dummy cannot stream GPU meshes.
		scene_changed.connect(func():
			if current_scene!=null and current_scene.has_method("_start_as_passenger"):
				current_scene.set_physics_process(false);current_scene.set_process(false);current_scene.cam.set_process(false)
				current_scene.journey_tools.autosaves=false;current_scene.journey_tools.set_process(false))
		page.passenger_button.grab_focus();await tap(page,JOY_BUTTON_A)
		var began:=Time.get_ticks_msec()
		while current_scene==page or current_scene==null:
			await process_frame
			if Time.get_ticks_msec()-began>90000:check(false,"Passenger scene load timeout");quit(1);return
		var game=current_scene;game.set_physics_process(false);game.set_process(false);game.cam.set_process(false)
		game.journey_tools.autosaves=false;game.journey_tools.set_process(false);game.journey_tools.save_directory="res://.local/r45/timeline-passenger/saves"
		check(game.train.id==id and game.paused and game._passenger_seated() and game.train.automatic,"Moving service entered in passenger seat with AI")
		check(game._prepared_passenger and game._prepared_time==original_time,"Timeline start retains time and passenger role")
		check(not game.passenger_bookmark.current().is_empty(),"Time-browser passenger seat can be recalled")
		check(var_to_bytes(before)==var_to_bytes(Snapshot.capture(game.world)),"Passenger boarding preserves complete frozen railway")
		await game._return_to_landing();await frames()
	print("TIMELINE_PASSENGER ",checks," checks, ",failures," failures");quit(1 if failures else 0)
