extends RefCounted
const Normals=preload("res://game/geographic_terrain_normals.gd")
func test_plane_normals_match_analytic_slope_at_coarse_and_fine_vertices():
	var n=Normals.new(func(x,z):return .2*x-.35*z)
	var expected=Vector3(-.2,1,.35).normalized()
	for p in [Vector2.ZERO,Vector2(8,16),Vector2(2,6),Vector2(512,512),Vector2(-2,0)]:
		if n.at(p).distance_to(expected)>.00001:return false
	return true
func test_curved_normals_are_finite_unit_vectors_and_cache_shared_vertices():
	var n=Normals.new(func(x,z):return sin(x*.1)*3+cos(z*.07))
	for x in range(0,40,2):
		for z in range(0,40,2):
			var result=n.at(Vector2(x,z))
			if not result.is_finite() or absf(result.length()-1)>.00001 or result.y<=0:return false
	var size=n.grid.size();n.at(Vector2(4,8));return n.grid.size()==size
func test_adjacent_tiles_have_identical_shared_edge_normals():
	var sample=func(x,z):return sin(x*.01)*4+cos(z*.04)*2
	var a=Normals.new(sample);var b=Normals.new(func(x,z):return sample.call(x+512,z))
	for z in range(0,513,2):
		if a.at(Vector2(512,z)).distance_to(b.at(Vector2(0,z)))>.00001:return false
	return true
func test_shore_derivative_halo_matches_the_neighbouring_tile():
	var fixture=preload("res://tests/test_shore_context.gd").new()
	var geo=preload("res://tests/test_shore_context.gd").Ground.new()
	geo.tiles[Vector2i(1,0)]={features=[fixture.lake([[16,0],[32,0],[32,512],[16,512],[16,0]])]}
	var a=fixture.chunk(geo,Vector2i.ZERO);var b=fixture.chunk(geo,Vector2i(1,0))
	var na=Normals.new(a._ground).at(Vector2(512,256));var nb=Normals.new(b._ground).at(Vector2(0,256))
	return na.distance_to(nb)<.00001 and na.x>.01 and a._ground(512,256)==8.5
func test_temporary_normals_do_not_keep_finished_chunks_alive():
	var fixture=preload("res://tests/test_shore_context.gd").new()
	var c=fixture.chunk(preload("res://tests/test_shore_context.gd").Ground.new(),Vector2i.ZERO)
	c.batch=preload("res://game/geographic_mesh.gd").new()
	var reference=weakref(c);c._terrain(16,2,false);c=null
	return reference.get_ref()==null
