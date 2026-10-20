extends SceneTree
## Read-only source UI check against the regenerated traffic catalogue.
const Traffic:=preload("res://persistence/service_traffic.gd")
var failures:=0
var checks:=0

func _initialize() -> void:call_deferred("run")
func check(ok: bool,label: String) -> void:
	checks+=1
	if not ok:failures+=1;printerr("FAIL: ",label)

func run() -> void:
	var day:="standard"
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--day="):day=arg.trim_prefix("--day=")
	var definition:=preload("res://persistence/operating_days.gd").definition(day)
	if definition.id!=day:printerr("Unknown operating day");quit(1);return
	set_meta("timetable_id",day)
	root.size=Vector2i(1600,900)
	var page:=preload("res://game/launch.gd").new()
	page.store=preload("res://persistence/save_store.gd").new("res://.local/traffic-ui-isolated-saves")
	root.add_child(page);current_scene=page
	await process_frame;await process_frame
	check(page.services.size()==definition.count and not page.traffic_data.is_empty(),"Complete current service/traffic catalogues")
	var roles:={}
	var total:=0
	for i in page.shown.size():
		page._select(i);page.set_detail_mode(1)
		await process_frame
		check(page.traffic_list.visible and not page.calls_grid.visible,"Traffic tab visible for "+page.selected.id)
		var labels:=page.traffic_list.find_children("*","Label",true,false).map(func(node):return node.text)
		var cards:=page.traffic_list.get_children().filter(func(node):return node is PanelContainer)
		check(cards.size()==page.traffic_rows.size(),"Every encounter has a card for "+page.selected.id)
		check(page.traffic_summary.text=="AI baseline · "+Traffic.summary(page.traffic_rows),"Summary uses selected service perspective")
		for row in page.traffic_rows:
			roles[row.role]=roles.get(row.role,0)+1;total+=1
			check(row.role in labels and Traffic.time_text(row.time) in labels,"Role and approximate time appear")
			check(labels.any(func(text):return text.begins_with(row.other+" · ")),"Other service appears")
			check(labels.any(func(text):return text.begins_with(row.location)),"Encounter location appears")
	check(roles.has("Crossing") and roles.has("You overtake") and roles.has("Overtakes you"),"All three encounter types are displayed")
	check(roles.get("You overtake",0)==roles.get("Overtakes you",0),"Both perspectives of every overtake are displayed")
	check(total==page.traffic_data.events.size()*2,"Both services can see every encounter")
	root.size=Vector2i(1280,720)
	page.roster.grab_focus()
	var event:=InputEventJoypadButton.new();event.button_index=JOY_BUTTON_Y;event.pressed=true
	page._input(event);await process_frame
	check(page.detail_mode==0 and page.calls_grid.visible,"Controller Y returns to stops")
	page._input(event);await process_frame
	check(page.detail_mode==1 and page.traffic_list.visible,"Controller Y opens traffic")
	print("TRAFFIC_UI ",JSON.stringify({checks=checks,failures=failures,operating_day=day,services=page.services.size(),encounter_cards=total,roles=roles}))
	page.queue_free();await process_frame;await process_frame
	quit(1 if failures else 0)
