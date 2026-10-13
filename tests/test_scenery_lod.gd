extends RefCounted
const Lod:=preload("res://game/scenery_lod.gd")
const Collection:=preload("res://game/trackside_assets.gd")
const Graphics:=preload("res://game/graphics_options.gd")

class Library:
	var view: Dictionary={root=Node3D.new()}
	var placements:={}
	var meshes:={}
	var impostors:={}
	func asset(kind: String) -> Array:return meshes[kind]

func test_offset_rotated_parts_keep_the_same_group_membership_and_bounds():
	var box:=BoxMesh.new();box.size=Vector3(3,8,5)
	var quad:=QuadMesh.new();quad.size=Vector2(14,14);quad.center_offset=Vector3(0,6,0)
	var parts:=[{mesh=box,transform=Transform3D(Basis.IDENTITY,Vector3(5,2,-8))},
		{mesh=box,transform=Transform3D(Basis.IDENTITY,Vector3(-7,4,3))},
		{mesh=quad,transform=Transform3D(Basis.IDENTITY,Vector3(1,0,-2)),impostor=true}]
	var poses:=[]
	for p in [Vector3(63,3,63),Vector3(65,0,60),Vector3(-1,0,-1),Vector3(-65,2,20)]:
		poses.append(Transform3D(Basis(Vector3.UP,.7).scaled_local(Vector3(1.3,.8,.7)),p))
	var count:=0
	for group in Lod.groups(poses,parts):
		var previous: MultiMeshInstance3D
		for part in parts:
			var node:=Lod.instance(group,part)
			if previous!=null:
				if node.multimesh.instance_count!=previous.multimesh.instance_count or node.custom_aabb!=previous.custom_aabb:return "LOD group changed"
				for i in node.multimesh.instance_count:
					if node.multimesh.get_instance_custom_data(i)!=previous.multimesh.get_instance_custom_data(i):return "Density/palette identity changed"
				previous.free()
			for i in node.multimesh.instance_count:
				# Dummy renderer does not retain MultiMesh GPU transform buffers.
				var pose: Transform3D=group.transforms[i]*part.transform
				if not node.custom_aabb.encloses(pose*part.mesh.get_aabb()):
					var reason:="Part outside shared bounds: %s vs %s" % [node.custom_aabb,pose*part.mesh.get_aabb()]
					node.free();return reason
			previous=node
		count+=previous.multimesh.instance_count;previous.free()
	return count==poses.size()

func test_tree_shadows_survive_detail_changes_and_obey_shadow_settings():
	var library:=Library.new()
	var kind:="tf3_KL_LS_Coconut_Tall_A"
	library.placements[kind]=[Transform3D(Basis.IDENTITY,Vector3(63,0,63)),Transform3D(Basis.IDENTITY,Vector3(62,0,62))]
	for level in Collection.levels(kind):
		var mesh:=BoxMesh.new();mesh.size=Vector3(2,12,2)
		library.meshes[level.kind]=[{mesh=mesh,transform=Transform3D(Basis.IDENTITY,Vector3(3,6,0))}]
	Collection.flush(library,kind)
	var settings:=Graphics.new();settings.preset("Performance")
	var shadow_count:=0;var bounds:=AABB();var first:=true;var ok:=true
	for node in library.view.root.get_children():
		if first:bounds=node.custom_aabb;first=false
		ok=ok and node.custom_aabb==bounds
		settings.apply_geometry(node)
		ok=ok and node.multimesh.visible_instance_count==1
		if node.get_meta("scenery_shadow",false):
			shadow_count+=1
			ok=ok and node.cast_shadow==GeometryInstance3D.SHADOW_CASTING_SETTING_SHADOWS_ONLY and node.visibility_range_begin==0 and node.visibility_range_end==100
			settings.set_option("shadow_distance",300.0);settings.apply_geometry(node)
			ok=ok and node.visibility_range_end==300
			settings.set_option("shadows",0);settings.apply_geometry(node);ok=ok and not node.visible
			settings.preset("High");settings.apply_geometry(node);ok=ok and node.visible
		else:ok=ok and node.cast_shadow==GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	library.view.root.free()
	return ok and shadow_count==1

func test_shadow_batch_keeps_all_triangles_and_rejects_alpha_or_deformation():
	var cube:=BoxMesh.new();var material:=StandardMaterial3D.new();cube.material=material
	var parts:=[{mesh=cube,transform=Transform3D(Basis(Vector3.UP,.4),Vector3(4,2,-3))},
		{mesh=cube,transform=Transform3D.IDENTITY}]
	var result: Array=preload("res://game/scenery_shadow.gd").build(parts)
	if result.size()!=1 or result[0].mesh.get_surface_count()!=1:return "Shadow geometry was not consolidated"
	var data: Array=result[0].mesh.surface_get_arrays(0)
	if data[Mesh.ARRAY_INDEX].size()!=cube.surface_get_arrays(0)[Mesh.ARRAY_INDEX].size()*2:return "Source shadow triangles changed"
	var bounds: AABB=parts[0].transform*cube.get_aabb()
	if not result[0].mesh.get_aabb().grow(.001).encloses(bounds):return "Transformed source silhouette lost"
	material.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
	return preload("res://game/scenery_shadow.gd").build(parts)==parts
