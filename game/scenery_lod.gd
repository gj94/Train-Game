extends RefCounted
## One placement partition and one conservative AABB for every representation.
## Godot measures visibility ranges from the AABB centre, not the node origin.
const Cells:=preload("res://game/spatial_batches.gd")

static func groups(placements: Array,parts: Array,cell_size: float=64.0) -> Array:
	if parts.is_empty():return []
	var model_bounds:=AABB()
	var first:=true
	for part in parts:
		var box: AABB=part.mesh.get_aabb()
		if part.get("impostor",false):
			# The shader rotates the quad toward the eye. Its unrotated, planar
			# AABB cannot describe its silhouette from every camera direction.
			var radius: float=part.mesh.size.x*.5
			box=AABB(Vector3(-radius,box.position.y,-radius),Vector3(radius*2,box.size.y,radius*2))
		box=part.transform*box
		model_bounds=box if first else model_bounds.merge(box)
		first=false
	var result:=[]
	for group in Cells.split(placements,cell_size).values():
		first=true
		var bounds:=AABB()
		for pose: Transform3D in group.transforms:
			var box: AABB=pose*model_bounds
			bounds=box if first else bounds.merge(box)
			first=false
		group.bounds=bounds.grow(.25) # Covers .13 m foliage wind and scaled instances.
		result.append(group)
	return result

static func instance(group: Dictionary,part: Dictionary) -> MultiMeshInstance3D:
	var mm:=MultiMesh.new()
	mm.transform_format=MultiMesh.TRANSFORM_3D;mm.use_custom_data=true
	mm.mesh=part.mesh;mm.instance_count=group.transforms.size()
	for i in group.transforms.size():
		var pose: Transform3D=group.transforms[i]
		mm.set_instance_transform(i,pose*part.transform)
		var p: Vector3=group.origin+pose.origin
		var seed:=float(posmod(roundi(p.x*17+p.z*31),127))/126.0
		mm.set_instance_custom_data(i,Color(seed,.5,.5,1))
	# Explicit static bounds avoid repeated instance-bound scans and keep all
	# LOD/density variants at exactly the same distance from the observer.
	mm.custom_aabb=group.bounds
	var node:=MultiMeshInstance3D.new()
	node.multimesh=mm;node.position=group.origin
	node.custom_aabb=group.bounds
	return node
