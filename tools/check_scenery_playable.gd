extends SceneTree
## Verify runtime scenery resources, pause behaviour and release on scene reload.
var checks:=0
var failures:=0
func _initialize() -> void: call_deferred("run")
func check(condition: bool,message: String) -> void:
	checks+=1
	if not condition:
		failures+=1
		printerr("FAIL scenery: ",message)
func run() -> void:
	set_meta("traffic_seed",0)
	change_scene_to_file("res://game/main.tscn")
	await process_frame
	await process_frame
	var game=current_scene
	game._set_paused(true)
	var plan=game.wv.scenery_plan
	var library=game.wv.scenery_library
	check(plan.buildings.size()>1800,"town and village buildings loaded")
	check(plan.fields.size()>800,"agricultural plots loaded")
	check(plan.bus_bays.size()==3,"station bus bays present")
	check(library.placements.is_empty(),"staging transforms released after flush")
	var catalog=JSON.parse_string(FileAccess.get_file_as_string("res://assets/models/scenery/manifest.json"))
	for kind in catalog:
		var parts: Array=library.asset(kind)
		check(not parts.is_empty(),"load "+kind)
		for part in parts:
			check(part.mesh.get_surface_count()==int(catalog[kind].surfaces),"surface budget "+kind)
	var atlas=JSON.parse_string(FileAccess.get_file_as_string("res://assets/models/scenery/impostors/catalog.json"))
	for kind in library.TREES:
		check(absf(library.TREES[kind].x-float(atlas[kind].width))<.00001 and absf(library.TREES[kind].y-float(atlas[kind].centre_y))<.00001,"impostor dimensions match "+kind)
	var traffic=game.wv.root.get_node("RoadTraffic")
	check(traffic.vehicles.size()==36,"decorative traffic fleet loaded")
	var time: float=game.world.time
	var position: Vector3=traffic.vehicles[0].node.position
	for frame in 5: await process_frame
	check(game.world.time==time and traffic.vehicles[0].node.position==position,"pause freezes road traffic")
	check(library.counts.get("passenger_man",0)+library.counts.get("passenger_sari",0)>60,"platform and street passengers placed")
	var old_world=weakref(game.wv)
	var old_library=weakref(library)
	plan=null
	library=null
	traffic=null
	game=null
	reload_current_scene()
	await process_frame
	await process_frame
	game=current_scene
	game._set_paused(true)
	check(old_world.get_ref()==null and old_library.get_ref()==null,"reload releases old world and asset cache")
	print("Scenery runtime checks: ",checks-failures," passed, ",failures," failed")
	quit(1 if failures else 0)
