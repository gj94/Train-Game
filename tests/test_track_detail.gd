extends RefCounted
const Track:=preload("res://game/track_view.gd")
const Detail:=preload("res://game/track_detail.gd")

func test_distant_meshes_reduce_work_and_keep_sleeper_bounds():
	Detail.prepare()
	var full:=Track.new()._sleeper_mesh()
	var near_box:=full.get_aabb();var far_box: AABB=Detail.meshes.sleeper.get_aabb()
	var clips:=Track.new()._fastening_mesh()
	return near_box.position.is_equal_approx(far_box.position) and near_box.size.is_equal_approx(far_box.size) and Detail.meshes.sleeper.get_faces().size()<full.get_faces().size()/4 and Detail.meshes.fastening.get_faces().size()<clips.get_faces().size()/4

func test_track_reference_switch_restores_full_distance_and_far_replacement():
	Detail.prepare()
	var parent:=Node3D.new()
	var near_node:=MultiMeshInstance3D.new();parent.add_child(near_node)
	var mm:=MultiMesh.new();mm.transform_format=MultiMesh.TRANSFORM_3D
	mm.mesh=Track.new()._sleeper_mesh();mm.instance_count=1;near_node.multimesh=mm
	near_node.visibility_range_end=650
	Detail.attach(near_node,"Sleepers",650,[Transform3D.IDENTITY])
	var far=parent.get_node("HLOD_Sleepers")
	var valid: bool=near_node.visibility_range_end==far.visibility_range_begin and far.visibility_range_end==650
	Detail.set_reference(parent,true)
	valid=valid and near_node.visibility_range_end==650 and not far.visible
	Detail.set_reference(parent,false)
	valid=valid and near_node.visibility_range_end==125 and far.visible
	parent.free()
	return valid
