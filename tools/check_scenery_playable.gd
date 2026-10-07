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
	var service_edges:={}
	for edge in game.world.graph.edges.values():
		if edge.allowed_dir!=1: continue
		for offset in [14.0,-7.0,-10.0]:
			var points:=PackedVector3Array()
			for p in edge.points: points.append(p+Vector3(0,0,offset))
			service_edges[str(edge.id)+":"+str(offset)]={points=points}
	var services=load("res://game/scenery_clearance.gd").new({edges=service_edges})
	var patches:=0
	var clear:=true
	for node in game.wv.root.get_children():
		if not node is MultiMeshInstance3D or node.get_meta("scenery_kind","")!="verge_patch": continue
		for i in node.multimesh.instance_count:
			patches+=1
			# Dummy RenderingServer cannot read back MultiMesh transforms.
			if DisplayServer.get_name()=="headless": continue
			var p: Vector3=node.position+node.multimesh.get_instance_transform(i).origin
			var valid: bool=services.clear_point(p,3.79) and plan.clearance.clear_point(p,5.99) and plan.clear_land_point(p,2.79)
			if clear and not valid: print("Ground cover first rejected position: ",p," / service ",services.clear_point(p,3.79)," rail ",plan.clearance.clear_point(p,5.99)," land ",plan.clear_land_point(p,2.79))
			clear=clear and valid
	print("Ground cover: ",patches," patches")
	check(patches>500,"near-track ground cover loaded")
	if DisplayServer.get_name()!="headless":
		check(clear,"ground-cover footprints clear rails, paths, drains, fields and buildings")
	else: print("Ground-cover transform readback skipped on Dummy; run natively for clearance audit")
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
