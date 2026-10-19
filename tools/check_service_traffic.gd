extends SceneTree
## Native home-page fixture; no 3D world, distribution or player save changes.
var checks:=0
var failures:=0
var folder:="res://.local/service-traffic/ui"

func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(folder));call_deferred("run")

func check(value: bool,message: String) -> void:
	checks+=1
	if not value:failures+=1;printerr("FAIL: ",message)

func frames() -> void:await process_frame;await process_frame;await process_frame

func tap(page,button: int) -> void:
	var e:=InputEventJoypadButton.new();e.button_index=button;e.pressed=true;page._input(e);await frames()

func shot(name: String) -> void:
	if DisplayServer.get_name()=="headless":return
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(folder+"/"+name+".png")

func run() -> void:
	root.size=Vector2i(1600,900)
	var page:=preload("res://game/launch.gd").new()
	page.store=preload("res://persistence/save_store.gd").new(folder+"/isolated-saves")
	root.add_child(page);current_scene=page;await frames()
	var fixture: bool="--fixture" in OS.get_cmdline_user_args()
	if fixture:
		page.traffic_data={events=[]}
		for i in 30:page.traffic_data.events.append({a="K1",b="B001",kind="crossing" if i%3==0 else "overtake",overtaker="B001",time=30000+i*600,chainage_m=2000+i*2000,station="",location="Thiruvananthapuram Central → Thiruvananthapuram Pettah"})
		page.refresh()
	check(page.selected.id=="K1","default slow passenger selected")
	check(not page.traffic_data.is_empty(),"complete baseline preview loaded")
	check(page.detail_mode==0 and page.calls_grid.visible and not page.traffic_list.visible,"stops remain initial detail page")
	var worst_selection_usec:=0
	if not fixture:
		for index in page.shown.size():
			var began:=Time.get_ticks_usec();page._select(index)
			worst_selection_usec=maxi(worst_selection_usec,Time.get_ticks_usec()-began)
			check(page.traffic_rows.size()==page.Traffic.for_service(page.traffic_data,page.selected.id).size(),"complete traffic list for "+page.selected.id)
			await frames()
		page.selected={id="K1"};page.refresh();await frames()
	await tap(page,JOY_BUTTON_Y)
	check(page.detail_mode==1 and page.traffic_list.visible and not page.calls_grid.visible,"Y switches to traffic")
	check(root.gui_get_focus_owner()==page.roster and page.worker==null,"preview never starts service or steals roster focus")
	check(page.traffic_list.get_child_count()==page.traffic_rows.size()+1,"every K1 encounter shown without truncation")
	await shot("k1-traffic")
	page._scroll_axis=1.0
	for i in 10:page._process(.05)
	page._scroll_axis=0.0;await frames()
	check(page.detail_scroll.scroll_vertical>0,"right stick scrolls traffic")
	var prior: String=page.selected.id
	await tap(page,JOY_BUTTON_DPAD_DOWN)
	check(page.selected.id!=prior and page.detail_mode==1 and page.detail_scroll.scroll_vertical==0,"service switch preserves traffic tab, resets scroll")
	await tap(page,JOY_BUTTON_A)
	check(root.gui_get_focus_owner()==page.start_button and page.worker==null,"A still inspects before driving")
	await tap(page,JOY_BUTTON_B)
	check(root.gui_get_focus_owner()==page.roster,"B returns from drive action")
	page.search.text="B012";page.refresh();await frames()
	check(page.selected.id=="B012","northbound VB selected")
	await shot("vb-traffic")
	root.size=Vector2i(1280,720);await frames();await shot("traffic-720p")
	check(page.content.get_rect().end.x<=root.get_visible_rect().size.x+1,"1280px layout stays within scaled viewport")
	page.detail_scroll.scroll_vertical=100000;await frames();await shot("traffic-bottom-720p")
	if not fixture:
		page.search.text="";page.set_period(4)
		var overnight_index:=-1
		for i in page.shown.size():
			if page.Traffic.for_service(page.traffic_data,page.shown[i].id).any(func(e):return e.time>=86400):overnight_index=i;break
		check(overnight_index>=0,"overnight baseline contains day-2 encounters")
		if overnight_index>=0:
			page._select(overnight_index);page.roster.select(overnight_index);await frames()
			page.detail_scroll.scroll_vertical=100000;await frames();await shot("night-traffic")
			var last_card: Control=page.traffic_list.get_child(-1)
			check(last_card.get_global_rect().end.y<=page.detail_scroll.get_global_rect().end.y+1,"last overnight encounter can be fully scrolled into view")
	await tap(page,JOY_BUTTON_Y)
	check(page.calls_grid.visible and page.calls_grid.get_child_count()==(page.selected.calls.size()+1)*3,"all booked calls remain available")
	page.search.text="not a service";page.refresh();await frames()
	check(not page.detail_tabs.visible and not page.traffic_list.visible and page.start_button.disabled,"no stale traffic on empty search")
	page.search.text="";page.refresh();page.traffic_data={};page._select(0);page.set_detail_mode(1);await frames()
	check(not page.start_button.disabled and page.traffic_list.get_child_count()==2,"unavailable preview leaves driving usable with explanation")
	page.saves=[{id="test",name="Test save",service="K1",clock="09:00",saved_at="Today"}];page.page="saves";page.refresh();await frames()
	check(not page.detail_tabs.visible and not page.traffic_list.visible,"saved journeys never show unrelated baseline traffic")
	var report:={checks=checks,failures=failures,fixture=fixture,worst_selection_usec=worst_selection_usec}
	FileAccess.open(folder+"/result.json",FileAccess.WRITE).store_string(JSON.stringify(report,"\t"))
	page.queue_free();await frames();print("TRAFFIC UI ",JSON.stringify(report));quit(1 if failures else 0)
