extends RefCounted
const Batches := preload("res://game/spatial_batches.gd")
const Acoustics := preload("res://game/platform_acoustics.gd")
const Scenery := preload("res://game/corridor_scenery.gd")

func test_scenery_boxes_share_material_batch_without_changing_corners():
	var scenery := Scenery.new()
	var material := StandardMaterial3D.new()
	var rotation := Vector3(.1,.7,-.2)
	var position := Vector3(21500,3,-21)
	var cube := BoxMesh.new()
	cube.size = Vector3.ONE
	var unit: PackedVector3Array = cube.get_mesh_arrays()[Mesh.ARRAY_VERTEX]
	for size in [Vector3(200,.12,.5),Vector3(.2,8.8,.2),Vector3(4,2,1)]:
		scenery._box(size,position,material,rotation)
		var original := BoxMesh.new()
		original.size = size
		var vertices: PackedVector3Array = original.get_mesh_arrays()[Mesh.ARRAY_VERTEX]
		var batch: Dictionary = scenery.batches.values()[0]
		var transform: Transform3D = batch.transforms[-1]
		for i in vertices.size():
			var before := Basis.from_euler(rotation)*vertices[i]+position
			if before.distance_to(transform*unit[i]) > .002: return "Scaled instance changed a scenery corner"
	return scenery.batches.size() == 1 and scenery.batches.values()[0].transforms.size() == 3

func test_spatial_batches_preserve_every_world_transform():
	var transforms := []
	for position in [Vector3(-256.1,2,-1),Vector3(-256,0,0),Vector3(-.1,4,.1),Vector3(0,0,0),Vector3(255.9,-2,256),Vector3(21500,3,-21)]:
		transforms.append(Transform3D(Basis.from_euler(Vector3(.1,.7,-.2)).scaled(Vector3(1,2,3)),position))
	var chunks := Batches.split(transforms)
	var recovered := []
	for chunk in chunks.values():
		for local: Transform3D in chunk.transforms:
			if local.origin.x < 0 or local.origin.x >= Batches.SIZE or local.origin.z < 0 or local.origin.z >= Batches.SIZE: return "Instance assigned outside its spatial cell"
			local.origin += chunk.origin
			recovered.append(local)
	if recovered.size() != transforms.size() or chunks.size() < 4: return "Instances lost or whole route still in one batch"
	for original in transforms:
		if not recovered.any(func(candidate): return candidate.is_equal_approx(original)): return "World transform changed during chunking"
	return true

func test_arrival_convergence_matches_original_twelve_iteration_solver():
	for distance in [3.0,60.0,700.0,1600.0,2600.0]:
		for speed in [-55.0,0.0,55.0]:
			var at := func(t: float): return Vector3(distance+sin(t*.03)*speed/.03,3,2+cos(t*.03)*5)
			var delay := 0.0
			for i in 12: delay=(at.call(.035+delay) as Vector3).length()/343.0
			if absf(Acoustics.curved_arrival(Vector3.ZERO,.035,at)-(.035+delay)) > 1e-8: return "Converged arrival differs from reference"
	return true

func test_stationary_arrival_does_not_repeat_identical_route_queries():
	var calls := [0]
	var at := func(_t: float):
		calls[0] += 1
		return Vector3(343,0,0)
	var arrival := Acoustics.curved_arrival(Vector3.ZERO,.5,at)
	return absf(arrival-1.5)<1e-12 and calls[0] == 2
