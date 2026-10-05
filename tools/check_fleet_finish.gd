extends SceneTree
const Surface := preload("res://game/fleet_surface.gd")
var failures := 0
func _initialize() -> void: call_deferred("run")
func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		printerr("FAIL: "+message)
func run() -> void:
	var catalog: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/models/ported/manifest.json"))
	for key in catalog:
		var model: Node3D = (load("res://assets/models/ported/%s.glb"%key) as PackedScene).instantiate()
		root.add_child(model)
		var original := []
		for mesh in model.find_children("*","MeshInstance3D",true,false):
			for i in mesh.mesh.get_surface_count():
				var m: StandardMaterial3D = mesh.mesh.surface_get_material(i)
				original.append([m,m.albedo_color,m.roughness])
		var changed := Surface.apply(model,key.begins_with("vb_"))
		check(changed.paint>0,key+" receives exterior paint finishing")
		check(changed.metal>0,key+" receives metal finishing")
		for before in original:
			check(before[0].albedo_color==before[1] and before[0].roughness==before[2],key+" source materials unchanged")
		model.free()
	var world := RailWorld.new()
	world.graph.add_node("a",Vector3.ZERO)
	world.graph.add_node("b",Vector3(1000,0,0))
	world.graph.add_edge("main","a","b")
	var train := Train.new("T1",preload("res://sim/stock/memu_consist.gd").LENGTH)
	world.place_train(train,"main",800,1)
	var parent := Node3D.new()
	root.add_child(parent)
	var view := preload("res://game/train_view.gd").new()
	view.build(train,world.graph,parent,preload("res://game/world_view.gd").new())
	check(view._bogie_views.size()==16,"MEMU has 16 independently steering bogies")
	check(view._wheel_views.size()==32,"MEMU has 32 rolling axles")
	var axles := preload("res://game/axle_joint.gd").rake_axles(8,22.132,21.337,3.277,2.896)
	for axle in axles:
		var found := false
		for wheel in view._wheel_views:
			if absf(wheel.node.global_position.x-(800-axle.x))<.003:
				found = true
				check(absf(wheel.node.global_position.y-.96)<.001,"MEMU 460 mm tread rests on rail datum")
		check(found,"MEMU sound axle agrees with detailed running gear")
	train.odometer = 2.0
	view.update()
	check(absf(view._wheel_views[0].node.rotation.x)>1,"wheelsets rotate with distance")
	parent.free()
	print("Fleet finish and MEMU running gear: 25 models; %d failures"%failures)
	quit(1 if failures else 0)
