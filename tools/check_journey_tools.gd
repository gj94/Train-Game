extends SceneTree
## Native source-scene integration, intentionally not an extracted-distribution test.
var failures:=0
var game
func _initialize() -> void:call_deferred("run")
func check(ok: bool,label: String) -> void:
	if not ok:failures+=1;printerr("FAIL ",label)
func run() -> void:
	root.size=Vector2i(1280,720)
	set_meta("route","southern_corridor");set_meta("imported_fleet","lhb");set_meta("traffic_drive",false)
	game=preload("res://game/main.gd").new();root.add_child(game);current_scene=game
	game._set_paused(true)
	game.journey_tools.save_directory="res://.local/r33/recovery-native-"+str(Time.get_ticks_usec())
	game.journey_tools.diagnostic_directory="res://.local/r33/diagnostics-native"
	await process_frame;await process_frame
	check(game.audio.game==game,"selected audio has gameplay context")
	check(game.audio_space.get("inside",false),"pilot uses interior transmission")
	game._ui_action("audio:open");await process_frame
	check(game.hud._heading.text=="AUDIO" and game.hud._buttons.get_child_count()==8,"audio settings focusable")
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://.local/r33/audio-menu.png")
	game._ui_action("audio:levels");await process_frame
	game._ui_action("audio:layer:rolling");await process_frame
	game.controller._back();await process_frame
	check(game.hud._heading.text=="AUDIO LAYERS","controller Back returns to layer list")
	game.controller._back();await process_frame
	check(game.hud._heading.text=="AUDIO","controller Back returns to audio settings")
	game._ui_action("journey:open");await process_frame
	check(game.hud._heading.text=="JOURNEY TOOLS","journey menu opens")
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://.local/r33/journey-menu.png")
	var original: Dictionary=game.journey_tools.views.capture()
	game.tv.passenger_coach=1;game._enter_passenger();await process_frame
	game.journey_tools.views.restore(original);await process_frame
	check(game.cam.mode==1 and not game.walker.active,"bookmark restores pilot and walking state")
	var state: Dictionary=game.save_load.capture_session()
	var issue: String=game.save_load.validate_session({world=game.world,session=state})
	check(issue.is_empty(),"current recovery session validates: "+issue)
	game.journey_tools.autosave("Native check",true)
	var saved_time: float=game.world.time
	game.world.time+=1
	while game.journey_tools.writer.busy():await process_frame
	game.journey_tools.flush()
	var store:=preload("res://persistence/save_store.gd").new(game.journey_tools.save_directory)
	var slots: Array=store.slots().filter(func(slot):return slot.ok)
	check(not slots.is_empty(),"asynchronous recovery written")
	if not slots.is_empty():
		var saved: Dictionary=store.read_slot(slots[-1].id)
		var loaded: Dictionary=preload("res://sim/world_snapshot.gd").restore(saved.data.checkpoint)
		check(loaded.ok and loaded.world.time==saved_time,"snapshot is detached from subsequent world changes")
	game.journey_tools.action("journey:diagnostics")
	while game.journey_tools.writer.busy():await process_frame
	game.journey_tools.flush()
	var zip:=ZIPReader.new()
	check(zip.open(game.journey_tools.last_bundle)==OK,"local diagnostic ZIP opens")
	check(zip.get_files().has("journey.bin") and zip.get_files().has("report.json"),"diagnostics contain checkpoint and build report")
	zip.close()
	game._set_paused(false);game.hud.show_modal("")
	await create_timer(1).timeout
	check(game.audio_space.get("service","")==game.train.id,"acoustic compartment follows player")
	game._set_paused(true)
	game.queue_free();current_scene=null;await process_frame;await process_frame
	print("JOURNEY_INTEGRATION failures=",failures);quit(failures)
