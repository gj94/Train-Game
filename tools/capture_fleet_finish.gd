extends SceneTree
## Inspect real game assets and materials with the game's light/railway, at useful distances.
const Stock := preload("res://sim/stock/ported_stock.gd")
var camera: Camera3D
func _initialize() -> void: call_deferred("capture")
func capture() -> void:
	var world := RailWorld.new()
	world.graph.add_node("a",Vector3.ZERO)
	world.graph.add_node("b",Vector3(1500,0,0))
	world.graph.add_edge("main","a","b")
	world.scenery = {x_min=0,x_max=1500}
	var scene := Node3D.new()
	root.add_child(scene)
	var wv := preload("res://game/world_view.gd").new()
	wv.build(world,scene)
	camera = Camera3D.new()
	camera.near = .05
	camera.far = 3000
	camera.fov = 52
	scene.add_child(camera)
	camera.make_current()
	DirAccess.make_dir_recursive_absolute("res://.local/fleet-finish")
	for choice in ["memu","wap7","wag9","wag12","icf","lhb","vb8"]:
		var parent := Node3D.new()
		scene.add_child(parent)
		var train := Train.new("T1",176.261)
		if choice!="memu": Stock.configure(train,choice)
		world.place_train(train,"main",813,1)
		var view = preload("res://game/train_view.gd").new() if choice=="memu" else preload("res://game/ported_train_view.gd").new()
		view.build(train,world.graph,parent,wv)
		var p: Vector3 = view.cars[0].global_position
		await shot(choice+"_front",p+Vector3(17,4,11),p+Vector3(1,2.1,0))
		await shot(choice+"_bogie",p+Vector3(7,1.15,3.8),p+Vector3(6,.70,0))
		if choice in ["icf","lhb","vb8","memu"]:
			var coach: Vector3 = view.cars[1].global_position
			await shot(choice+"_coach",coach+Vector3(10,3.5,18),coach+Vector3.UP*2)
		view.set_cab_view(true)
		camera.global_transform = view.cab_transform()
		await save(choice+"_cab")
		view.set_cab_view(false)
		parent.queue_free()
		await process_frame
	print("Fleet finish captures complete")
	quit()
func shot(label: String, position: Vector3, target: Vector3) -> void:
	camera.global_position=position
	camera.look_at(target)
	await save(label)
func save(label: String) -> void:
	for i in 5: await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://.local/fleet-finish/"+label+".png")
	print("CAPTURE ",label)
