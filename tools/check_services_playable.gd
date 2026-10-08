extends SceneTree
const Pack := preload("res://sim/service_pack.gd")
var game
var failures := 0
var checks := 0

func _initialize() -> void:
	var pack := Pack.defaults()
	for i in pack.services.size(): pack.services[i].id="CUSTOM_%d" % i
	set_meta("service_pack",pack)
	set_meta("player_service","CUSTOM_0")
	call_deferred("run")

func check(value: bool, label: String) -> void:
	checks+=1
	if not value:
		failures+=1
		printerr("FAIL: "+label)

func frames(count: int = 3) -> void:
	for i in count: await process_frame

func key(code: int) -> void:
	var event := InputEventKey.new()
	event.physical_keycode=code; event.pressed=true
	event.shift_pressed=code==KEY_E
	game._unhandled_input(event)

func tap(button: int) -> void:
	for pressed in [true,false]:
		var event := InputEventJoypadButton.new()
		event.device=13; event.button_index=button; event.pressed=pressed
		game.controller._input(event)
		await frames()
		game.controller._process(.02)

func capture(name: String) -> void:
	if "--screenshots" not in OS.get_cmdline_user_args(): return
	await frames(5)
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://.local/services-"+name+".png")

func bind_game() -> void:
	game=current_scene
	game.set_physics_process(false)
	game.controller.set_process(false)
	game.controller.tsw_layout=false # Existing layout retains its camera shortcuts.
	for sound in game.train_audio.values(): sound.set_process(false)
	game.controller._adopt(13)
	game.controller.window_focus(true)
	game.controller._set_mode(true)
	game.controller._process(.02)

func run() -> void:
	change_scene_to_file("res://game/main.tscn")
	await frames()
	bind_game()
	check(game.train.id=="CUSTOM_0" and not game.train.automatic,"custom service ID selected without T1")
	check(game.world.trains.size()==6 and game.world.trains.values().filter(func(t): return t.automatic).size()==5,"other five are AI")
	check(game.dispatcher.auto_dispatch and game.traffic_drive,"automatic dispatcher includes manual service")
	game.train.controller=-.65
	key(KEY_Q); await frames(20)
	check(game.cam.mode==3 and game.cam.head_out_side==-1,"Q left head-out")
	check(game.train.controller==-.65 and not game.train.automatic,"head-out preserves brake and manual driver")
	check(not game.audio._cab,"head-out uses exterior acoustics")
	var left: Transform3D=game.tv.head_out_transform(-1)
	var right: Transform3D=game.tv.head_out_transform(1)
	check(absf(left.origin.distance_to(right.origin)-3.8)<.001,"head-out eyes clear both body sides")
	check(left.basis.z.dot(right.basis.z)>.999,"both head-out cameras face travel direction")
	await capture("head-left")
	key(KEY_E); await frames(20)
	check(game.cam.head_out_side==1 and game.cam.mode==3,"E changes head-out side")
	await capture("head-right")
	key(KEY_E); await frames()
	check(game.cam.mode==1 and game.audio._cab,"same side returns to pilot with cab acoustics")
	game.train.automatic=true
	game.tv.cab_position=3
	key(KEY_4)
	check(game.tv.cab_position==0 and game.train.automatic and game.train.controller==-.65,"pilot returns to driver without cancelling AI or handle")
	await tap(JOY_BUTTON_DPAD_LEFT)
	check(game.cam.mode==3 and game.cam.head_out_side==-1,"controller left head-out")
	await tap(JOY_BUTTON_DPAD_UP)
	check(game.cam.mode==1,"controller up returns pilot")
	var previous=game.train
	game._select_train("CUSTOM_1")
	check(previous.automatic and not game.train.automatic and game.train.id=="CUSTOM_1","handover leaves previous service AI and takes selected service")
	var west: Transform3D=game.tv.head_out_transform(-1)
	var direction: Vector3=game.world.graph.tangent(game.train.path[0].edge,game.train.head_s,game.train.path[0].dir)
	check((-west.basis.z).dot(direction)>.99,"westbound head-out faces west")
	var elapsed: float=game.world.time
	key(KEY_F5); await frames()
	var editor=game.service_editor
	editor.save_path="res://.local/service-editor-draft.json"
	check(editor.visible and game.paused and game.hud.modal=="services","F5 opens paused authoring screen")
	game._physics_process(1)
	check(game.world.time==elapsed,"designer freezes live clock")
	check(editor.draft.services[0].id=="CUSTOM_0","designer loads active service pack")
	await capture("editor")
	var original: String=JSON.stringify(editor.draft)
	var live_clock: float=game.world.clock_start
	editor.clock_field.text="07:59:00"
	editor.clock_field.text_changed.emit(editor.clock_field.text)
	check(editor.draft.world_start=="07:59:00" and game.world.clock_start==live_clock,"editing world start leaves live world unchanged")
	check(editor.export_file("res://.local/service-roundtrip.json"),"export writes portable JSON")
	editor.draft.services[0].name="temporary"
	check(editor.import_file("res://.local/service-roundtrip.json"),"valid import")
	check(editor.draft.services[0].name!="temporary","import restores exported definition")
	var before_bad: String=JSON.stringify(editor.draft)
	var file:=FileAccess.open("res://.local/service-invalid.json",FileAccess.WRITE)
	file.store_string("{bad")
	file.close()
	check(not editor.import_file("res://.local/service-invalid.json") and JSON.stringify(editor.draft)==before_bad,"failed import leaves draft intact")
	editor._add_service(true)
	check(editor.draft.services.size()==7,"duplicate adds editable service")
	editor._validate()
	check("already occupied" in editor.status.text,"duplicate origin validation is visible")
	editor._remove_service()
	check(editor.draft.services.size()==6,"remove restores valid service count")
	game.controller._set_mode(true)
	editor.stock_field.grab_focus()
	await tap(JOY_BUTTON_A)
	check(editor.stock_field.get_popup().visible,"controller opens stock dropdown")
	await tap(JOY_BUTTON_B)
	check(not editor.stock_field.get_popup().visible and editor.visible,"controller B closes dropdown only")
	editor.selected=2
	editor._load_service()
	editor._request_play()
	await frames()
	check(editor.confirm_play.visible and editor._pending_service=="CUSTOM_2","play confirms chosen service")
	await tap(JOY_BUTTON_B)
	check(not editor.confirm_play.visible and editor.visible,"controller cancels restart without dismissing draft")
	await tap(JOY_BUTTON_B)
	check(not editor.visible and game.hud.modal=="pause","controller back returns to pause")
	# Reload from the real launcher and retain the assignment on restart.
	game._play_services(Pack.decode(FileAccess.get_file_as_string("res://.local/service-roundtrip.json")).data,"CUSTOM_2")
	await frames(6)
	bind_game()
	check(game.train.id=="CUSTOM_2" and not game.train.automatic,"real launch selects requested service")
	check(game.world.clock_text()=="07:59:00" and game.dispatcher.auto_dispatch,"real launch uses edited clock and dispatcher")
	check(game.world.trains.values().filter(func(t): return t.automatic).size()==5,"real launch assigns all others to AI")
	game.dispatcher.set_open(true)
	await frames()
	check(game.dispatcher._roster.has("CUSTOM_5"),"custom IDs render in dispatch roster")
	await capture("custom-dispatch")
	game._request_action("restart"); game._confirm_action()
	await frames(6)
	bind_game()
	check(game.train.id=="CUSTOM_2" and not game.authored_pack.is_empty(),"restart retains pack and player assignment")
	game._request_action("traffic"); game._confirm_action()
	await frames(6)
	bind_game()
	check(game.authored_pack.is_empty() and game.world.trains.has("T1"),"choosing built-in traffic clears authored pack")
	print("Services/cameras: %d checks, %d failures" % [checks,failures])
	current_scene.queue_free()
	await frames()
	quit(1 if failures else 0)
