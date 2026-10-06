extends RefCounted
## Spatially bounded instance batches let Godot cull scenery and its shadows.
## Every source transform survives unchanged in world space.
const SIZE := 256.0

static func split(transforms: Array,cell_size: float=SIZE) -> Dictionary:
	var groups := {}
	for transform: Transform3D in transforms:
		var cell := Vector2i(floori(transform.origin.x/cell_size),floori(transform.origin.z/cell_size))
		if not groups.has(cell):
			groups[cell]={origin=Vector3(cell.x*cell_size,0,cell.y*cell_size),transforms=[]}
		var local := transform
		local.origin-=groups[cell].origin
		groups[cell].transforms.append(local)
	return groups
