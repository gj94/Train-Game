extends SceneTree
var failures:=0
var checks:=0
func _initialize() -> void:call_deferred("run")
func check(ok: bool, text: String) -> void:
	checks+=1
	if not ok:failures+=1;printerr("FAIL ",text)
func frames() -> void:
	for i in 5:await process_frame
func capture(label: String) -> void:
	await frames()
	if DisplayServer.get_name()=="headless":return
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://.local/r44/"+label+".png")
func run() -> void:
	root.size=Vector2i(1600,900)
	var launch:=preload("res://game/launch.gd").new();launch.browser_preferences="res://.local/r44/browser-test.cfg";root.add_child(launch)
	await frames()
	check(launch.home.visible and not launch.content.visible,"Home is initial page")
	for resolution in [Vector2i(1600,900),Vector2i(1280,720)]:
		root.size=resolution;root.content_scale_size=resolution;await frames()
		for b in launch.home.buttons.values():
			check(root.get_visible_rect().encloses(b.get_global_rect()),"Home action fits "+b.text+" at "+str(resolution))
		check(root.get_visible_rect().encloses(launch.home.footer.get_global_rect()),"Home footer fits")
		await capture("home-"+str(resolution.y))
	launch._home_action("services");await frames()
	check(not launch.home.visible and launch.content.visible,"Services opens browser")
	launch.period=0;launch.search.text="";launch.sort_mode=0;launch.selected={id="K1"};launch.refresh()
	check(launch.shown.size()==launch.services.size(),"All services retained")
	check(launch.selected.id=="K1" and launch.calls_grid.get_child_count()>3,"K1 stops retained")
	await capture("services-720")
	launch.set_detail_mode(1);await capture("traffic-720")
	launch._back();check(launch.home.visible,"Back returns home")
	launch.home.graphics.settings_path="res://.local/r44/graphics-test.cfg"
	launch.home.show_settings();await frames();await capture("options-720")
	launch.home.show_settings("display");await frames()
	check(launch.home.option_list.get_child_count()>6,"Detailed display settings before loading")
	var scale_before: float=launch.home.graphics.values.scale
	launch.home.option_list.get_child(1).pressed.emit();await frames()
	check(launch.home.graphics.values.scale!=scale_before,"Pre-journey graphics control applies selection")
	var prefs:=preload("res://game/graphics_options.gd").new();prefs.settings_path=launch.home.graphics.settings_path;prefs.restore()
	check(prefs.values.scale==launch.home.graphics.values.scale,"Pre-journey graphics selection persists")
	check(root.gui_get_focus_owner().text.begins_with("3D render scale"),"Settings retains changed row focus")
	launch.home.back();launch.home.back();check(not launch.home.options.visible,"Settings back hierarchy")
	launch.home.show_settings();launch.home.guide.show();launch.home.guide.open(2);await capture("guide-720")
	launch.home.back();check(not launch.home.guide.visible,"Guide back")
	launch.home.back();launch.show_browser();launch.search.text="Vande";launch.refresh()
	check(not launch.shown.is_empty() and launch.shown.all(func(r):return r.stock in ["vb8","vb16"]),"Search Vande Bharat")
	launch.sort_mode=2;launch._save_browser();launch.search.text="";launch.sort_mode=0;launch._restore_browser()
	check(launch.search.text=="Vande" and launch.sort_mode==2,"Browser remembers choices")
	launch.queue_free();await frames()
	print("R44_MENU ",checks," checks, ",failures," failures")
	quit(0 if failures==0 else 1)
