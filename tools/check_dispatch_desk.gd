extends SceneTree
## Native render + safety contract for the standalone control desk.
var failed := false
func _initialize() -> void:
	call_deferred("_check")
func _check() -> void:
	root.size=Vector2i(1600,900)
	var w=preload("res://sim/layouts/kerala_coast.gd").build_traffic()
	var desk=preload("res://game/dispatch_desk.gd").new()
	root.add_child(desk);desk.setup(w);desk.set_open(true)
	var assigned: String=desk.selected_train
	var original: bool=w.trains.K2.automatic
	desk._roster.K2.pressed.emit()
	_expect(desk.inspected_train=="K2" and desk.selected_train==assigned,"Click only inspects")
	desk._view.pressed.emit()
	_expect(desk.selected_train==assigned and w.trains.K2.automatic==original,"Viewing preserves driver")
	desk.set_open(true);desk._prompt_handover()
	_expect(desk._confirm.visible and desk.selected_train==assigned,"Handover requires confirmation")
	desk.cancel_handover()
	_expect(not desk._confirm.visible and desk.selected_train==assigned,"Cancel preserves assignment")
	desk.inspect_train(assigned);desk._map.focus_station(2)
	_expect(desk._platform.item_count==1 and desk._platform.get_item_metadata(0)=="KUMM_P3","Kumbalam offers only its CSV passenger platform")
	await process_frame
	await process_frame
	_expect(desk._map.size.x>=400 and desk._map.size.y>=280,"Map has useful area")
	var map=desk._map
	var anchor:=Vector2(map.size.x*.7,map.size.y*.4)
	var before: float=map.center_s+(anchor.x-map.size.x*.5)*map.span/map.size.x
	map.zoom_at(2,anchor)
	var after: float=map.center_s+(anchor.x-map.size.x*.5)*map.span/map.size.x
	_expect(absf(before-after)<.001,"Zoom keeps pointed track location fixed")
	map.focus_train("K3")
	await process_frame
	await process_frame
	var length:=0.0
	for interval in map.last_footprints.K3:length+=interval.length
	_expect(absf(length-w.trains.K3.length)<.01,"Map depicts full physical train footprint")
	for hit in map._hits:
		if hit.kind=="train" and hit.id=="K3":map.select_at(hit.rect.get_center());break
	_expect(desk.inspected_train=="K3" and desk.selected_train==assigned,"Map click inspects without taking over")
	desk.inspect_train(assigned);map.focus_station(2)
	print("DESK_MAP_RECT ",desk._map.get_global_rect()," root=",root.size)
	if DisplayServer.get_name()!="headless":
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://.local/dispatch-desk.png")
	root.size=Vector2i(1280,720)
	await process_frame
	await process_frame
	_expect(desk._map.get_global_rect().end.x<1280 and desk._map.size.x>=400,"Desk remains usable at 1280x720")
	if DisplayServer.get_name()!="headless":
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://.local/dispatch-desk-720.png")
	print("DISPATCH_DESK ","FAIL" if failed else "PASS")
	quit(1 if failed else 0)
func _expect(value: bool, message: String) -> void:
	if not value:failed=true;printerr("FAIL: ",message)
