extends SceneTree
var checks:=0
var failures:=0
var folder:="res://.local/r45"
func _initialize() -> void:call_deferred("run")
func check(ok: bool,label: String) -> void:
	checks+=1
	if not ok:failures+=1;printerr("FAIL ",label)
func frames() -> void:
	for i in 4:await process_frame
func tap(page,button: int) -> void:
	for pressed in [true,false]:
		var event:=InputEventJoypadButton.new();event.device=16;event.button_index=button;event.pressed=pressed
		if "--event-pipeline" in OS.get_cmdline_user_args():Input.parse_input_event(event);Input.flush_buffered_events()
		else:page._input(event)
		await frames()
func shot(name: String) -> void:
	if DisplayServer.get_name()=="headless":return
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(folder+"/"+name+".png")
func run() -> void:
	DirAccess.make_dir_recursive_absolute(folder)
	var prefs:=folder+"/journey-ui.cfg"
	if FileAccess.file_exists(prefs):DirAccess.remove_absolute(prefs)
	var page:=preload("res://game/launch.gd").new();page.browser_preferences=prefs
	page.store=preload("res://persistence/save_store.gd").new(folder+"/empty-saves")
	root.size=Vector2i(1280,720);root.content_scale_size=root.size;root.add_child(page);await frames()
	page.show_browser();page.reset_filters();page.selected={id="K1"};page.refresh()
	await frames()
	check(page.shown.size()==100,"Unfiltered Standard services")
	for button in [page.stock_picker,page.favourites_button,page.through_button,page.favourite_button,page.start_button,page.ride_button]:
		check(root.get_visible_rect().encloses(button.get_global_rect()),"Browser action fits at 720p: "+button.text)
	await shot("library-720")
	await tap(page,JOY_BUTTON_LEFT_STICK)
	check(page.library.favourite("standard","K1") and page.favourite_button.text=="★","L3 favourites selected service")
	page.favourites_button.pressed.emit();await frames()
	check(page.shown.size()==1 and page.selected.id=="K1","Favourite filter")
	page.select_timetable(1);await frames()
	check(page.shown.is_empty() and page.start_button.disabled and page.ride_button.disabled,"Favourites do not cross operating days")
	page.reset_filters();page.selected={id="B042"};page.refresh();page.toggle_favourite()
	check(page.library.favourite("intensive","B042") and page.library.favourite("standard","K1"),"Both operating days retain independent favourites")
	page.select_timetable(0);page.reset_filters();await frames()
	page.stock_picker.grab_focus();await tap(page,JOY_BUTTON_A)
	check(page.stock_picker.get_popup().visible,"Controller opens train filter")
	page.stock_picker.get_popup().hide();page.stock_picker.item_selected.emit(3);await frames()
	check(not page.shown.is_empty() and page.shown.all(func(r):return r.stock=="vb8"),"Train filter uses actual formation")
	page.stock_picker.item_selected.emit(0);page.through_button.pressed.emit();await frames()
	check(not page.shown.is_empty() and page.shown.all(func(r):return r.origin in ["Ernakulam Junction","Nagercoil Junction"] and r.destination in ["Ernakulam Junction","Nagercoil Junction"]),"Full route filter")
	page.reset_filters();page.search.text="ICF Alappuzha";page.refresh()
	check(not page.shown.is_empty() and page.shown.all(func(r):return r.stock=="icf"),"Multiple search terms")
	page.reset_filters();page.selected={id="K1"};page.refresh();await frames()
	# Inspect before starting; confirm only the explicit Drive/Ride button.
	page.roster.grab_focus();await tap(page,JOY_BUTTON_A)
	check(root.gui_get_focus_owner()==page.start_button and page.worker==null,"A on roster inspects instead of launching")
	page._navigate(Vector2i.RIGHT)
	check(root.gui_get_focus_owner()==page.ride_button,"Right from Drive reaches Ride")
	page._navigate(Vector2i.LEFT)
	check(root.gui_get_focus_owner()==page.start_button,"Left from Ride reaches Drive")
	await tap(page,JOY_BUTTON_B)
	check(root.gui_get_focus_owner()==page.roster and page.content.visible,"B from details returns to roster before Home")
	var row: Dictionary=page.selected.duplicate(true);row.passenger_start=true
	var choice: Dictionary=page._read_request("service",row)
	check(choice.ok and choice.passenger_start and choice.world.trains.K1.automatic,"Passenger read retains baseline AI")
	page.search.text="Vande";page.refresh();page.sort_mode=2;page._show_home()
	var restored:=preload("res://game/journey_library.gd").new();restored.restore(prefs)
	check(restored.favourite("standard","K1") and restored.favourite("intensive","B042"),"Favourites persist when leaving browser")
	page.show_browser(true);await frames()
	check(not page.ride_button.visible and not page.favourite_button.visible,"Saved journeys do not offer new-service actions")
	page._toggle_saves();await frames()
	check(page.search.text=="Vande" and page.sort_mode==2,"Saved journeys round trip retains service browsing choices")
	page.queue_free();await frames()
	print("JOURNEY_LIBRARY_UI ",checks," checks, ",failures," failures")
	quit(1 if failures else 0)
