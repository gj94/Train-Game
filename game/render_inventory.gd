extends RefCounted
## Diagnostic source-geometry estimate; actual GPU counters remain authoritative.
static func collect(parent: Node, camera: Camera3D) -> Array:
	var totals:={}
	var counts:={}
	for node in parent.find_children("*","GeometryInstance3D",true,false):
		if not node.is_visible_in_tree():continue
		var distance: float=node.global_position.distance_to(camera.global_position)
		if node.visibility_range_end>0 and distance>node.visibility_range_end+40:continue
		if distance+40<node.visibility_range_begin:continue
		var mesh: Mesh
		var instances:=1
		if node is MultiMeshInstance3D:
			if node.multimesh==null:continue
			mesh=node.multimesh.mesh;instances=node.multimesh.instance_count
		elif node is MeshInstance3D:mesh=node.mesh
		else:continue
		if mesh==null:continue
		var rid:=mesh.get_rid().get_id()
		if not counts.has(rid):
			var triangles:=0
			for surface in mesh.get_surface_count():
				var arrays:=mesh.surface_get_arrays(surface)
				var indices: PackedInt32Array=arrays[Mesh.ARRAY_INDEX] if arrays[Mesh.ARRAY_INDEX]!=null else PackedInt32Array()
				triangles+=(indices.size() if not indices.is_empty() else arrays[Mesh.ARRAY_VERTEX].size())/3
			counts[rid]=triangles
		var key: String=node.get_meta("scenery_kind",str(node.name).split("@")[0])
		if node is MultiMeshInstance3D and node.get_meta("impostor",false):key+=" (impostor)"
		if not totals.has(key):totals[key]={kind=key,source_triangles=0,instances=0,batches=0}
		totals[key].source_triangles+=counts[rid]*instances
		totals[key].instances+=instances;totals[key].batches+=1
	var rows:=totals.values()
	rows.sort_custom(func(a,b):return a.source_triangles>b.source_triangles)
	return rows.slice(0,30)
