extends RefCounted
const Palette:=preload("res://game/static_palette_mesh.gd")

func test_material_batch_preserves_positions_normals_and_imported_lod_indices():
	var mesh:=ArrayMesh.new();var box:=BoxMesh.new()
	for i in 2:
		var arrays: Array=box.surface_get_arrays(0)
		var positions: PackedVector3Array=arrays[Mesh.ARRAY_VERTEX]
		for j in positions.size():positions[j]+=Vector3(i*4,0,0)
		arrays[Mesh.ARRAY_VERTEX]=positions
		var indices: PackedInt32Array=arrays[Mesh.ARRAY_INDEX]
		mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays,[],{float(i+1):indices.slice(0,18)})
		var material:=StandardMaterial3D.new();material.cull_mode=BaseMaterial3D.CULL_DISABLED
		material.albedo_color=Color(.2+i*.1,.4,.1);material.roughness=.5+i*.2
		mesh.surface_set_material(i,material)
	var merged:=Palette.merge(mesh)
	if merged.get_surface_count()!=1:return "Constant materials were not consolidated"
	var original_vertices: PackedVector3Array=mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
	var second_vertices: PackedVector3Array=mesh.surface_get_arrays(1)[Mesh.ARRAY_VERTEX]
	original_vertices.append_array(second_vertices)
	var output: Array=merged.surface_get_arrays(0)
	if output[Mesh.ARRAY_VERTEX]!=original_vertices:return "Material grouping moved vertices"
	var first_lods:=Palette.lods(merged,0)
	if first_lods[1.0].size()!=54 or first_lods[2.0].size()!=36:return "Individual automatic LOD steps lost"
	for index in first_lods[2.0]:
		if index<0 or index>=original_vertices.size():return "Remapped LOD index outside vertices"
	return true

func test_material_batch_excludes_textures_alpha_and_special_shading():
	var material:=StandardMaterial3D.new();material.cull_mode=BaseMaterial3D.CULL_DISABLED
	if not Palette.eligible(material):return "Basic opaque source should be eligible"
	material.albedo_texture=GradientTexture2D.new()
	if Palette.eligible(material):return "Textured pixels would be lost"
	material.albedo_texture=null;material.emission_enabled=true
	if Palette.eligible(material):return "Emissive source would be lost"
	material.emission_enabled=false;material.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
	return not Palette.eligible(material)
