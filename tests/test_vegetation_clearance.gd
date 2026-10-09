extends RefCounted
const Clearance:=preload("res://game/vegetation_clearance.gd")
func world() -> RailWorld:
	var w:=RailWorld.new()
	w.graph.add_node("A",Vector3(-550,0,0));w.graph.add_node("B",Vector3(550,0,0))
	w.graph.add_edge("P1","A","B")
	w.stations=[{code="TEST",platform_tracks=["P1"],platform_details={P1={offset=0,platform_width=5,platform_side=-1}},platform_half=50}]
	return w

func test_new_grass_can_grow_beside_track_without_entering_ballast():
	var mask=Clearance.build(world())
	if mask.clear(Vector2(0,4),2):return "Grass can overhang ballast"
	return mask.clear(Vector2(0,7),2)

func test_platform_exclusion_uses_outer_edge_not_route_centreline():
	var w:=world()
	var mask=Clearance.build(w)
	if mask.clear(Vector2(0,-5),2):return "Grass grows on platform"
	return mask.clear(Vector2(0,-10),2)

func test_clearance_preserves_other_running_lines_and_depot_spurs():
	var w:=world()
	w.graph.add_node("C",Vector3(-60,0,22));w.graph.add_node("D",Vector3(60,0,22))
	w.graph.add_edge("DEPOT","C","D")
	var mask=Clearance.build(w)
	return not mask.clear(Vector2(0,22),2) and mask.clear(Vector2(0,14),2)

func test_grass_mesh_is_bounded_bent_geometry_with_fixed_triangle_budget():
	var mesh:=preload("res://game/coastal_groundcover.gd").mesh(StandardMaterial3D.new())
	var arrays:=mesh.surface_get_arrays(0)
	var points: PackedVector3Array=arrays[Mesh.ARRAY_VERTEX]
	var bounds:=mesh.get_aabb()
	if arrays[Mesh.ARRAY_INDEX].size()/3!=1152:return "Ground cover exceeds agreed per-instance budget"
	if bounds.size.y<.25 or bounds.size.y>.40:return "Grass is flat or implausibly tall"
	for p in points:
		if Vector2(p.x,p.z).length()>2.01:return "Grass exceeds exclusion radius"
	return true
