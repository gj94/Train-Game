extends SceneTree
var checks:=0
var failures:=0
var page
var folder:="res://.local/r45/home-resume"
func _initialize() -> void:call_deferred("run")
func check(ok: bool,label: String) -> void:
	checks+=1
	if not ok:failures+=1;printerr("FAIL ",label)
func frames() -> void:
	for i in 5:await process_frame
func tap(button: int) -> void:
	for pressed in [true,false]:
		var event:=InputEventJoypadButton.new();event.device=16;event.button_index=button;event.pressed=pressed
		Input.parse_input_event(event);Input.flush_buffered_events();await frames()
func idle() -> void:
	var began:=Time.get_ticks_msec()
	while page.worker!=null or page.save_worker!=null:
		await process_frame
		if Time.get_ticks_msec()-began>30000:check(false,"Read timeout");return
	await frames()
func shot(name: String) -> void:
	if DisplayServer.get_name()=="headless":return
	await RenderingServer.frame_post_draw;root.get_texture().get_image().save_png(folder+"/"+name+".png")
func run() -> void:
	DirAccess.make_dir_recursive_absolute(folder)
	root.size=Vector2i(1280,720);root.content_scale_size=root.size
	page=preload("res://game/launch.gd").new();page.browser_preferences=folder+"/browser.cfg"
	page.store=preload("res://persistence/save_store.gd").new(folder+"/empty-saves")
	root.add_child(page);current_scene=page;await idle()
	var home=page.home
	check(home.buttons.continue.disabled,"Empty save library disables Continue")
	var entry: Dictionary={id="1-backup",slot="1",backup=true,readable=true,name="Manual slot 1 · backup · Coastal Stopping Passenger",service="K1",clock="Day 1 · 11:25",saved_at="2026-10-22 04:00:00",summary={title="Coastal Stopping Passenger · Ernakulam to Nagercoil",viewpoint="Passenger seat · Coach 5 · Sleeper",control="AI driving",stops=12,total=42,saved_at="2026-10-22 04:00:00"}}
	var broken: Dictionary={id="2",slot="2",backup=false,readable=false,name="Unreadable save",clock="",saved_at="2026-10-22 05:00:00",summary={}}
	page.saves=[broken,entry];home.update_saves(page.saves);home.buttons.continue.grab_focus();await frames()
	check(not home.buttons.continue.disabled and home.info_heading.text=="RESUME PREVIOUS BACKUP","Continue preview skips unreadable primary and identifies backup")
	check(home.info_title.text.contains("Coastal") and home.info.text.contains("K1") and home.info.text.contains("11:25"),"Preview identifies actual service and railway time")
	check(home.info.text.contains("Coach 5") and home.info.text.contains("AI driving") and home.info.text.contains("12 / 42") and home.info.text.contains("resumes paused"),"Preview shows passenger role, control, stop progress and paused entry")
	for resolution in [Vector2i(1280,720),Vector2i(1600,900)]:
		root.size=resolution;root.content_scale_size=resolution;await frames()
		check(root.get_visible_rect().encloses(home.info.get_global_rect()) and root.get_visible_rect().encloses(home.footer.get_global_rect()),"Resume card and footer fit "+str(resolution))
		await shot("resume-"+str(resolution.y))
	root.size=Vector2i(1280,720);root.content_scale_size=root.size;await frames()
	# The row points only at an isolated empty fixture directory; it must fail.
	await tap(JOY_BUTTON_A);await idle()
	check(current_scene==page and home.visible and not page.content.visible and not page.busy_panel.visible,"Failed Continue returns to Home instead of departures")
	check(home.info_heading.text=="COULD NOT OPEN JOURNEY" and home.info.text.contains("readable save"),"Home shows actual read failure")
	check(root.gui_get_focus_owner()==home.buttons.continue,"Failed Continue restores initiating controller focus")
	await shot("resume-failure-720")
	home.buttons.continue.grab_focus();page._begin("save",entry);page._cancel();await idle()
	check(home.visible and not page.content.visible and home.info.text=="Loading cancelled.","Cancelled Continue returns to Home with feedback")
	check(root.gui_get_focus_owner()==home.buttons.continue,"Cancelled Continue restores focus")
	home.buttons.services.grab_focus();await frames()
	check(home.info_heading.text=="ONE RAILWAY. YOUR WAY TO TRAVEL." and home.info.text.contains("Departures"),"Navigating away clears transient load feedback")
	page.show_browser(true);await frames();page.roster.grab_focus();page._begin("save",entry);page._cancel();await idle()
	check(not home.visible and page.content.visible and page.page=="saves" and root.gui_get_focus_owner()==page.roster,"Saved-browser cancellation stays in its original browser")
	page._show_home();home.update_saves([],true);await frames()
	check(home.buttons.continue.disabled and home._resume_entry.is_empty(),"Rechecking saves clears stale resume preview")
	check(not DirAccess.dir_exists_absolute(folder+"/empty-saves"),"Resume/error/cancel checks never write save files")
	page.queue_free();await frames()
	print("HOME_RESUME ",checks," checks, ",failures," failures");quit(1 if failures else 0)
