extends SceneTree
var checks:=0
var failures:=0
var page
const DIR:="res://.local/r45/home-preferences"
func _initialize() -> void:call_deferred("run")
func check(ok: bool,label: String) -> void:
	checks+=1
	if not ok:failures+=1;printerr("FAIL ",label)
func frames() -> void:
	for i in 5:await process_frame
func tap(button: int) -> void:
	for pressed in [true,false]:
		var event:=InputEventJoypadButton.new();event.device=16;event.button_index=button;event.pressed=pressed
		if "--event-pipeline" in OS.get_cmdline_user_args():Input.parse_input_event(event);Input.flush_buffered_events()
		else:page._input(event)
		await frames()
func choose(prefix: String) -> void:
	var found:=false
	for button in page.home.option_list.get_children():
		if button is Button and button.text.to_lower().begins_with(prefix.to_lower()):button.grab_focus();found=true;break
	if not found:check(false,"Action available: "+prefix);return
	await tap(JOY_BUTTON_A)
func shot(label: String) -> void:
	if DisplayServer.get_name()=="headless":return
	await RenderingServer.frame_post_draw;root.get_texture().get_image().save_png(DIR+"/"+label+".png")
func run() -> void:
	DirAccess.make_dir_recursive_absolute(DIR)
	for file in ["controller.cfg","audio.cfg","graphics.cfg"]:
		if FileAccess.file_exists(DIR+"/"+file):DirAccess.remove_absolute(DIR+"/"+file)
	page=preload("res://game/launch.gd").new();page.browser_preferences=DIR+"/browser.cfg"
	page.store=preload("res://persistence/save_store.gd").new(DIR+"/empty-saves")
	root.size=Vector2i(1280,720);root.content_scale_size=root.size;root.add_child(page);await frames()
	var home=page.home
	home.preferences.controller_path=DIR+"/controller.cfg";home.preferences.audio_path=DIR+"/audio.cfg";home.graphics.settings_path=DIR+"/graphics.cfg"
	home.buttons.settings.grab_focus();await tap(JOY_BUTTON_A);await choose("Controller preferences")
	check(home._settings_group=="controller","Home opens controller hardware preferences")
	await choose("Stick deadzone");await choose("Look sensitivity");await choose("Invert");await choose("Vibration")
	var pad:=preload("res://game/controller_input.gd").new();pad.settings_path=home.preferences.controller_path;pad._load_settings()
	check(is_equal_approx(pad.deadzone,.24) and pad.sensitivity==1.25 and pad.invert_y and is_equal_approx(pad.vibration,.7),"Home settings load in driving controller")
	pad.free()
	check(root.gui_get_focus_owner().text.begins_with("Vibration"),"Changed controller row retains focus")
	check(home.settings_status.text.begins_with("Saved"),"Successful write feedback visible inside menu")
	await shot("controller-720")
	await tap(JOY_BUTTON_B)
	check(home._settings_group.is_empty() and root.gui_get_focus_owner().text=="Controller preferences","Back returns to controller entry")
	await choose("Sound mixer");await choose("Rail & wheels");await choose("Rail-joint clacks")
	check(home._settings_group=="sound:impacts","Controller reaches individual sound layer")
	await choose("Louder");await choose("Louder")
	check(home.preferences.sound.levels.impacts==4 and home.preferences.sound.levels.wind==0,"Joint volume stays independent of wind")
	check(root.gui_get_focus_owner().text.begins_with("Louder"),"Changing a sound level retains focus")
	await choose("Mute")
	check(home.preferences.sound.muted.impacts and home.preferences.sound.levels.impacts==4,"Mute retains level")
	check(root.gui_get_focus_owner().text.begins_with("Unmute"),"Mute focuses replacement action")
	await shot("sound-layer-720")
	await tap(JOY_BUTTON_B)
	check(home._settings_group=="sound:rail" and root.gui_get_focus_owner().text.begins_with("Rail-joint"),"Layer back retains parent focus")
	await tap(JOY_BUTTON_B)
	check(home._settings_group=="sound" and root.gui_get_focus_owner().text.to_lower()=="rail & wheels","Category back retains parent focus")
	await choose("Listening preset");await choose("Headphones")
	check(home.preferences.sound.headphones and not home.preferences.sound.quiet and not home.preferences.sound.reference,"Headphones preset selects full game audio")
	check(home.preferences.sound.levels.impacts==0 and not home.preferences.sound.muted.impacts,"Preset resets prior mix explicitly")
	await choose("Approved track reference");await tap(JOY_BUTTON_B)
	check(home.option_list.get_children().any(func(c):return c is Label and c.text.contains("controls are bypassed")),"Reference mode warning is visible")
	await choose("Listening preset");await choose("Speakers");await tap(JOY_BUTTON_B)
	await choose("Master volume");await choose("Quieter")
	var stored:=preload("res://game/audio_preferences.gd").new(home.preferences.audio_path)
	check(stored.levels.master==-2 and not stored.reference,"Home audio persists to next journey")
	await tap(JOY_BUTTON_B)
	check(home._settings_group=="sound" and root.gui_get_focus_owner().text.begins_with("Master volume"),"Master back returns directly to mixer")
	await tap(JOY_BUTTON_B);await choose("Controller layout");await tap(JOY_BUTTON_RIGHT_SHOULDER)
	check(home.guide.visible and home.guide.page==1,"RB navigates guide from Home")
	await tap(JOY_BUTTON_LEFT_SHOULDER);check(home.guide.page==0,"LB navigates guide from Home")
	await tap(JOY_BUTTON_B)
	check(not home.guide.visible and root.gui_get_focus_owner().text=="Controller layout","Guide returns to its entry")
	await choose("Controller preferences");await choose("Restore")
	check(home.preferences.controls==preload("res://game/controller_preferences.gd").DEFAULTS,"Controller defaults restored")
	home.preferences.controller_path=DIR+"/missing-parent/controller.cfg";await choose("Stick deadzone")
	check(home.settings_status.text.begins_with("Could not save"),"Failed controller write is not shown as saved")
	home.preferences.controller_path=DIR+"/controller.cfg"
	await tap(JOY_BUTTON_B);await choose("Sound mixer");await choose("Master volume")
	home.preferences.audio_path=DIR+"/missing-parent/audio.cfg";home.show_settings("sound:master");await choose("Louder")
	check(home.settings_status.text.begins_with("Could not save"),"Failed audio write is shown inside the active panel")
	home.preferences.audio_path=DIR+"/audio.cfg"
	for resolution in [Vector2i(1280,720),Vector2i(1600,900)]:
		root.size=resolution;root.content_scale_size=resolution;home.show_settings("controller");await frames()
		check(root.get_visible_rect().encloses(home.settings_title.get_global_rect()),"Settings title fits "+str(resolution))
		check(root.get_visible_rect().encloses(home.settings_status.get_global_rect()),"Settings feedback fits "+str(resolution))
		home.focus_setting("Restore");await frames()
		check(root.get_visible_rect().encloses(root.gui_get_focus_owner().get_global_rect()),"Focused bottom action scrolls into view "+str(resolution))
		await shot("controller-"+str(resolution.y))
	home.show_settings();await tap(JOY_BUTTON_B)
	check(not home.options.visible and root.gui_get_focus_owner()==home.buttons.settings,"B returns Home with settings focused")
	page.queue_free();await frames()
	print("HOME_PREFERENCES ",checks," checks, ",failures," failures");quit(1 if failures else 0)
