extends SceneTree
## Source-only native smoke test: five full trains, settings, real pad events, reload.
var game
var failed:=0
var output:={cases=[]}
const DEVICE:=14

func _initialize() -> void:
	set_meta("benchmark",true);set_meta("traffic_seed",0)
	call_deferred("run")

func check(ok: bool,label: String) -> void:
	print("PASS " if ok else "FAIL ",label)
	if not ok:failed+=1

func frames(count: int=8) -> void:
	for i in count:await process_frame

func settle() -> void:
	var began:=Time.get_ticks_msec()
	var stable:=0
	while Time.get_ticks_msec()-began<180000:
		await process_frame
		var busy: bool=game.wv.loading or not game.wv.queue.is_empty() or not game.wv._activating.is_empty() or not game.traffic_presentation.builds.pending.is_empty()
		for worker in game.wv.workers:busy=busy or not worker.runner.job.is_empty()
		stable=0 if busy else stable+1
		if stable>=20:return
	check(false,"scenery settles within three minutes")

func tap(button: int) -> void:
	var event:=InputEventJoypadButton.new();event.device=DEVICE;event.button_index=button;event.pressed=true
	Input.parse_input_event(event);await frames(3)
	event=InputEventJoypadButton.new();event.device=DEVICE;event.button_index=button;event.pressed=false
	Input.parse_input_event(event);await frames(3)

func screenshot(label: String) -> void:
	await frames(3)
	if DisplayServer.get_name()!="headless":
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://.local/graphics-"+label+".png")

func run() -> void:
	change_scene_to_file("res://game/main.tscn");await frames(2)
	game=current_scene;game._set_paused(true);game.hud.show_modal("")
	game.graphics_options.settings_path="res://.local/graphics-playable.cfg"
	game.controller.settings_path="res://.local/graphics-pad.cfg"
	var fixture:=preload("res://game/traffic_benchmark.gd").new()
	output.fixture=fixture.setup(game)
	await settle()
	game.controller.window_focus(true);game.controller._adopt(DEVICE);game.controller._set_mode(true)
	await frames()
	game._ui_action("graphics");await frames()
	check(game.paused and game.hud.modal=="graphics","graphics menu pauses driving")
	await screenshot("menu")
	game.hud.focus_action("graphics:scenery")
	await tap(JOY_BUTTON_A)
	check(game.hud.modal=="graphics:scenery","controller opens scenery group")
	game.hud.focus_action("graphics:option:vegetation_density")
	await tap(JOY_BUTTON_A)
	check(game.hud.modal=="graphics:option:vegetation_density","controller opens individual setting")
	await screenshot("option")
	game.hud.focus_action("graphics:set:vegetation_density:0")
	await tap(JOY_BUTTON_A)
	check(game.graphics_options.values.vegetation_density==.5 and game.hud.modal=="graphics:scenery","controller applies option and returns to group")
	check(root.gui_get_focus_owner().get_meta("action","")=="graphics:option:vegetation_density","focus stays on changed setting")
	await tap(JOY_BUTTON_B)
	check(game.hud.modal=="graphics","controller B returns one level")
	await tap(JOY_BUTTON_B)
	check(game.hud.modal=="pause","controller B returns to pause")
	var before: float=game.world.time
	for preset in ["High","Balanced","Performance","High"]:
		game.graphics_options.preset(preset);game.graphics_options.apply();game.hud.show_modal("")
		Engine.max_fps=0
		for mode in ["pilot","passenger","overview"]:
			fixture.set_view(mode);await settle();await frames(12)
			var counters: Dictionary=fixture.counters()
			check(counters.resident_trains==5 and counters.simulated_passengers==output.fixture.passengers,preset+" / "+mode+" keeps five full passenger services")
			if mode=="pilot":check(counters.rendered_seated==0,"pilot has no hidden seated passengers")
			if mode=="passenger":check(counters.rendered_seated>0 and counters.rendered_seated<=floori(140*game.graphics_options.values.passengers),"occupied coach retains passengers within selected cap")
			output.cases.append({preset=preset,view=mode,counters=counters,scale=root.scaling_3d_scale,msaa=root.msaa_3d,far=game.cam.far})
			if mode=="overview":await screenshot(preset.to_lower())
	check(game.world.time==before,"graphics changes preserve simulation clock")
	game.graphics_options.preset("Balanced");game.graphics_options.save()
	var saved:=preload("res://game/graphics_options.gd").new();saved.settings_path=game.graphics_options.settings_path;saved.restore()
	check(saved.preset_name()=="Balanced","preferences reload correctly")
	output.failures=failed;output.adapter=RenderingServer.get_video_adapter_name()
	var file:=FileAccess.open("res://.local/graphics-playable.json",FileAccess.WRITE);file.store_string(JSON.stringify(output,"\t"));file.close()
	game.graphics_options.preset("High");game.graphics_options.apply()
	DirAccess.remove_absolute(game.graphics_options.settings_path)
	quit(1 if failed else 0)
