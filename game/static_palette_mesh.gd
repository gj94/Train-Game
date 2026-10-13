extends RefCounted
## Consolidate untextured opaque PBR surfaces without reducing source geometry.
## Tools use this to bake material batches; textured surfaces and LODs survive.
const PALETTE:=preload("res://game/shaders/scenery_palette.gdshader")

static func eligible(material: Material) -> bool:
	if not material is StandardMaterial3D:return false
	if material.transparency!=BaseMaterial3D.TRANSPARENCY_DISABLED or material.cull_mode!=BaseMaterial3D.CULL_DISABLED:return false
	if material.shading_mode!=BaseMaterial3D.SHADING_MODE_PER_PIXEL or material.vertex_color_use_as_albedo:return false
	if material.metallic!=0 or not is_equal_approx(material.metallic_specular,.5):return false
	if material.emission_enabled or material.normal_enabled or material.rim_enabled or material.clearcoat_enabled or material.ao_enabled or material.subsurf_scatter_enabled or material.backlight_enabled:return false
	for texture in BaseMaterial3D.TEXTURE_MAX:
		if material.get_texture(texture)!=null:return false
	return true

static func indices_from_bytes(bytes: PackedByteArray,stride: int) -> PackedInt32Array:
	var indices:=PackedInt32Array();indices.resize(bytes.size()/stride)
	for i in indices.size():indices[i]=bytes.decode_u16(i*stride) if stride==2 else bytes.decode_u32(i*stride)
	return indices

static func lods(mesh: ArrayMesh,surface: int) -> Dictionary:
	# Godot 4.7.2 stores each imported LOD as an error threshold / packed index
	# pair. Preserve these instead of re-running an approximate simplifier.
	var stored: Array=mesh.get("_surfaces")[surface].get("lods",[])
	var stride:=RenderingServer.mesh_surface_get_format_index_stride(mesh.surface_get_format(surface),mesh.surface_get_array_len(surface))
	var result:={}
	for i in range(0,stored.size(),2):result[float(stored[i])]=indices_from_bytes(stored[i+1],stride)
	return result

static func shifted(indices: PackedInt32Array,offset: int) -> PackedInt32Array:
	var result:=indices.duplicate()
	for i in result.size():result[i]+=offset
	return result

static func merge(mesh: ArrayMesh) -> ArrayMesh:
	if mesh.get_blend_shape_count()>0:return mesh
	var selected:=[]
	for surface in mesh.get_surface_count():
		if mesh.surface_get_primitive_type(surface)!=Mesh.PRIMITIVE_TRIANGLES:return mesh
		var data:=mesh.surface_get_arrays(surface)
		if data[Mesh.ARRAY_BONES]!=null and not data[Mesh.ARRAY_BONES].is_empty():return mesh
		if eligible(mesh.surface_get_material(surface)) and data[Mesh.ARRAY_NORMAL]!=null and data[Mesh.ARRAY_COLOR]==null:selected.append(surface)
	if selected.size()<2:return mesh
	var output:=ArrayMesh.new()
	for surface in mesh.get_surface_count():
		if surface in selected:continue
		output.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,mesh.surface_get_arrays(surface),[],lods(mesh,surface))
		output.surface_set_material(output.get_surface_count()-1,mesh.surface_get_material(surface))
	var positions:=PackedVector3Array();var normals:=PackedVector3Array();var colours:=PackedColorArray()
	var full_indices:=PackedInt32Array();var sources:=[];var levels:={}
	for surface: int in selected:
		var data:=mesh.surface_get_arrays(surface)
		var vertices: PackedVector3Array=data[Mesh.ARRAY_VERTEX]
		var material: StandardMaterial3D=mesh.surface_get_material(surface)
		var offset:=positions.size()
		positions.append_array(vertices);normals.append_array(data[Mesh.ARRAY_NORMAL])
		var color:=material.albedo_color.srgb_to_linear();color.a=material.roughness
		var packed:=PackedColorArray();packed.resize(vertices.size());packed.fill(color);colours.append_array(packed)
		var indices: PackedInt32Array=data[Mesh.ARRAY_INDEX] if data[Mesh.ARRAY_INDEX]!=null else PackedInt32Array()
		if indices.is_empty():
			indices.resize(vertices.size())
			for i in indices.size():indices[i]=i
		var original_lods:=lods(mesh,surface)
		for threshold: float in original_lods:levels[threshold]=true
		sources.append({full=shifted(indices,offset),lods=original_lods,offset=offset})
		full_indices.append_array(sources[-1].full)
	var merged_lods:={};var thresholds: Array=levels.keys();thresholds.sort()
	for threshold: float in thresholds:
		var combined:=PackedInt32Array()
		for source in sources:
			var best:=-1.0
			for size: float in source.lods:
				if size<=threshold and size>best:best=size
			combined.append_array(source.full if best<0 else shifted(source.lods[best],source.offset))
		merged_lods[threshold]=combined
	var arrays:=[];arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX]=positions;arrays[Mesh.ARRAY_NORMAL]=normals
	arrays[Mesh.ARRAY_COLOR]=colours;arrays[Mesh.ARRAY_INDEX]=full_indices
	output.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays,[],merged_lods)
	var palette:=ShaderMaterial.new();palette.shader=PALETTE;palette.resource_name="TreeVertexPBR"
	output.surface_set_material(output.get_surface_count()-1,palette)
	output.set_meta("palette_source_surfaces",mesh.get_surface_count())
	output.set_meta("palette_merged_surfaces",selected.size())
	return output
