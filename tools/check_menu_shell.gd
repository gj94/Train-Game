extends SceneTree
## UI-only contracts and native screenshots; no timetable advancement.
var failures: Array[String]=[]
var checks:=0
var hud
func _initialize() -> void:
	call_deferred("run")
func check(value: bool, message: String) -> void:
	checks+=1
	if not value:failures.append(message);printerr("FAIL: ",message)
func frames() -> void:
	for i in 4:await process_frame
func capture(file: String) -> void:
	await frames()
	if DisplayServer.get_name()=="headless":return
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://.local/r43-"+file+".png")
func run() -> void:
	root.size=Vector2i(1600,900)
	hud=preload("res://game/hud.gd").new();root.add_child(hud)
	hud.controller_active=true
	hud.graphics_options=preload("res://game/graphics_options.gd").new()
	hud._menu_context={train_id="K1",service_name="Coastal Stopping Passenger · Ernakulam → Nagercoil",world_day=1,world_clock="09:47:18",automatic=false,journey={scheduled=true,complete=false,next_name="Alappuzha",distance_m=2460.0,estimated_seconds=192.0}}
	hud.show_modal("pause")
	await frames()
	var shell=hud.pause_menu
	check(shell.tabs.size()==5,"Five logical pause sections")
	for i in shell.PAGES.size():
		shell.set_page(i);await frames()
		check(root.get_visible_rect().encloses(shell.get_global_rect()),"Pause fits viewport: "+shell.PAGES[i])
		for entry in shell.ENTRIES[i]:
			hud.focus_action(entry[0])
			await frames()
			var owner=root.gui_get_focus_owner()
			check(owner.get_meta("action","")==entry[0] and owner.is_visible_in_tree(),"Focus reaches: "+entry[0])
			check(owner.get_global_rect().intersects(shell.actions.get_parent().get_global_rect()),"Focus scrolls into view: "+entry[0])
	shell.set_page(2);hud.focus_action("controllers");shell.set_page(0);shell.set_page(2)
	check(root.gui_get_focus_owner().get_meta("action","")=="controllers","Section remembers selected action")
	shell.set_page(-1);check(shell.page==4,"Left section wrap")
	shell.set_page(5);check(shell.page==0,"Right section wrap")
	hud.focus_action("skip:open");await capture("pause-900")
	root.size=Vector2i(1280,720);root.content_scale_size=Vector2i(1280,720);await frames()
	shell.set_page(2);hud.focus_action("graphics");await capture("settings-720")
	hud.show_modal("game_speed");await capture("speed-720")
	check(not shell.visible and hud._dialog.visible,"Submenu replaces pause hub")
	hud.show_modal("graphics");await capture("graphics-720")
	check(root.get_visible_rect().encloses(hud._dialog.get_global_rect()),"Graphics fits 720p")
	hud.show_modal("graphics:lighting");await capture("graphics-lighting-720")
	check(root.get_visible_rect().encloses(hud._dialog.get_global_rect()),"Long graphics labels fit 720p")
	hud.show_modal("help");await capture("help-720")
	check(hud._dialog.get_global_rect().end.y<=720,"Submenu fits 720p vertically")
	hud.show_modal("controller_guide");await capture("controls-720")
	hud.save_menu={title="ADVANCING YOUR JOURNEY",body="AI is driving every service. Stop advancing to return to this moment.",map_mode=true,options=[["Stop advancing","skip:cancel"]]}
	hud.show_modal("time_skip");await capture("skip-map-720")
	check(hud.time_skip_map.size.x>900 and hud.time_skip_map.size.y>=210,"Skip diagram retains full-width usable area")
	check(root.get_visible_rect().encloses(hud._buttons.get_child(0).get_global_rect()),"Skip cancellation stays on screen")
	hud.show_modal("");hud.set_desk_open(true)
	var world=preload("res://sim/layouts/kerala_coast.gd").build_traffic()
	var desk=preload("res://game/dispatch_desk.gd").new();root.add_child(desk);desk.setup(world);desk.set_open(true)
	var assigned: String=desk.selected_train
	var driving: bool=world.trains[assigned].automatic
	desk.inspect_train("K2");desk._search.text="K2";desk.locate_player();await frames()
	check(desk.inspected_train==assigned and desk.selected_train==assigned,"Locate returns to assigned service")
	check(desk._search.text.is_empty(),"Locate clears hiding search filter")
	check(world.trains[assigned].automatic==driving,"Locate preserves driving ownership")
	check(desk._map.has_focus(),"Locate focuses map")
	desk.inspect_train("K2");desk.toggle_follow()
	check(desk._map.follow_train and desk._map.inspected_train=="K2","Follow targets inspected service")
	desk.toggle_follow();check(not desk._map.follow_train,"Follow toggles off")
	desk.locate_player();desk._map.focus_station(2)
	for i in 4:
		desk.focus_zone(1);await frames()
		check(root.gui_get_focus_owner()!=null and root.gui_get_focus_owner().is_visible_in_tree(),"Dispatcher zone has visible focus")
	await capture("dispatch-720")
	check(desk._map.size.x>=400,"Dispatcher map retains useful width at 720p")
	root.size=Vector2i(1600,900);root.content_scale_size=Vector2i(1600,900);await capture("dispatch-900")
	desk.locate_player();await capture("dispatch-own-train-900")
	desk.queue_free();hud.queue_free();await frames()
	var loading=preload("res://game/loading_screen.gd").new();root.add_child(loading)
	loading.report(137,140,"Ernakulam Junction",2,1,0);await capture("loading-900")
	loading.queue_free();await frames()
	var launch=preload("res://game/launch.gd").new()
	launch.store=preload("res://persistence/save_store.gd").new("res://.local/menu-ui-isolated-saves")
	root.add_child(launch);await frames();await capture("departures-900")
	launch.set_detail_mode(1);await capture("departures-traffic-900")
	launch.queue_free();await frames()
	print("MENU_SHELL ","PASS" if failures.is_empty() else "FAIL"," checks=",checks)
	quit(0 if failures.is_empty() else 1)
