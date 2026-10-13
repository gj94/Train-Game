extends RefCounted
## One position-only shadow surface from static, entirely opaque source parts.
## Keep the source triangles; material changes do not split a depth-only draw.

static func build(parts: Array) -> Array:
	var vertices:=PackedVector3Array();var indices:=PackedInt32Array()
	for part in parts:
		var mesh: Mesh=part.mesh
		if mesh is ArrayMesh and mesh.get_blend_shape_count()>0:return parts
		for surface in mesh.get_surface_count():
			if mesh is ArrayMesh and mesh.surface_get_primitive_type(surface)!=Mesh.PRIMITIVE_TRIANGLES:return parts
			var material: Material=mesh.surface_get_material(surface)
			if material!=null and (not material is StandardMaterial3D or material.transparency!=BaseMaterial3D.TRANSPARENCY_DISABLED):return parts
			var data:=mesh.surface_get_arrays(surface)
			if data.is_empty() or data[Mesh.ARRAY_VERTEX]==null:return parts
			if data[Mesh.ARRAY_BONES]!=null and not data[Mesh.ARRAY_BONES].is_empty():return parts
			var source: PackedVector3Array=data[Mesh.ARRAY_VERTEX]
			var first:=vertices.size()
			if part.transform==Transform3D.IDENTITY:vertices.append_array(source)
			else:
				for vertex in source:vertices.append(part.transform*vertex)
			var source_indices: PackedInt32Array=data[Mesh.ARRAY_INDEX] if data[Mesh.ARRAY_INDEX]!=null else PackedInt32Array()
			if source_indices.is_empty():
				for i in source.size():indices.append(first+i)
			else:
				for i in source_indices:indices.append(first+i)
	if vertices.is_empty():return parts
	var arrays:=[];arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX]=vertices;arrays[Mesh.ARRAY_INDEX]=indices
	var merged:=ArrayMesh.new();merged.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
	var material:=StandardMaterial3D.new();material.cull_mode=BaseMaterial3D.CULL_DISABLED
	material.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
	merged.surface_set_material(0,material)
	return [{mesh=merged,transform=Transform3D.IDENTITY}]
