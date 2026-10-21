extends SceneTree
const Snapshot:=preload("res://sim/world_snapshot.gd")
var checks:=0
var failures:=0
func _initialize() -> void:call_deferred("run")
func check(ok: bool,label: String) -> void:
	checks+=1
	if not ok:failures+=1;printerr("FAIL ",label)
func frames() -> void:
	for i in 3:await process_frame
func run() -> void:
	DirAccess.make_dir_recursive_absolute("res://.local/r45/dispatcher-labels")
	root.size=Vector2i(1280,720);root.content_scale_size=root.size
	var world:=preload("res://sim/layouts/kerala_coast.gd").build_traffic()
	var desk:=preload("res://game/dispatch_desk.gd").new();root.add_child(desk);desk.setup(world);desk.set_open(true)
	var before:=var_to_bytes(Snapshot.capture(world));var assigned: String=desk.selected_train
	var map=desk._map
	for resolution in [Vector2i(1280,720),Vector2i(1600,900)]:
		root.size=resolution;root.content_scale_size=root.size;await frames()
		for station in [0,2,-1]:
			map.focus_station(station);await frames()
			if station==-1:
				var middle: Vector2=map._p(map.center_s,70)
				map.vertical_pan=80
				check(map._p(map.center_s,-70)==middle,"Overview stays on its corridor line regardless of station lateral offsets")
				map.vertical_pan=0
			var bounds:=Rect2(Vector2(8,62),map.size-Vector2(16,142))
			var clear:=true
			for i in map.last_labels.size():
				var entry: Dictionary=map.last_labels[i]
				clear=clear and bounds.encloses(entry.rect)
				for j in i:clear=clear and not entry.rect.grow(3).intersects(map.last_labels[j].rect)
				check(map._hit_at(entry.rect.get_center()).id==entry.id,"Each tag selects its own service")
			check(clear,"Tags and speed lines fit without overlap")
			var keys:={}
			for hit in map._navigation_targets():keys[hit.key]=true
			check(keys.size()==map._navigation_targets().size(),"Controller targets are unique")
			if DisplayServer.get_name()!="headless":
				await RenderingServer.frame_post_draw;root.get_texture().get_image().save_png("res://.local/r45/dispatcher-labels/map-%d-%d.png" % [resolution.y,station])
	map.focus_train(assigned);await frames()
	var own: Dictionary=map.last_labels.filter(func(entry):return entry.id==assigned)[0]
	# A train body beneath a displaced tag cannot steal the mouse click.
	map._hits.push_front({key="train:K2",kind="train",id="K2",rect=own.rect,p=own.rect.get_center()})
	map.select_at(own.rect.get_center())
	check(desk.inspected_train==assigned and desk.selected_train==assigned,"Topmost tag wins without driving handover")
	check(before==var_to_bytes(Snapshot.capture(world)),"Map layout and inspection preserve complete railway state")
	desk.queue_free();await frames()
	print("DISPATCH_LABELS_UI ",checks," checks, ",failures," failures");quit(1 if failures else 0)
