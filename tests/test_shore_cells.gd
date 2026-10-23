extends RefCounted
const Chunk=preload("res://game/geographic_scenery_chunk.gd")
const Shore=preload("res://game/geographic_shore_cells.gd")
const Ribbon=preload("res://game/geographic_ground_ribbon.gd")
const Streams=preload("res://game/geographic_stream_surface.gd")
class Ground:
	var station_sites:={}
	func ground_at(x: float,z: float) -> float:return 4+sin(x*.08)*.5+cos(z*.13)*.4
	func nearest_rail(_x: float,_z: float) -> Dictionary:return {distance=100.0}
class RecordedMesh:
	var points:=[]
	func quad(_kind,a,b,c,d,_normal,_colour=Color.WHITE,_uv=[]):points.append_array([a,b,c,d])
func bank():
	var c=Chunk.new(Ground.new(),{},null)
	c.water_levels=[{height=.8,geometry={type="Polygon",coordinates=[[[0,0],[105,0],[0,210],[0,0]]]}}]
	c._index_shores();return c
func corners(c,start: Vector2) -> PackedVector3Array:
	var result:=PackedVector3Array()
	for offset in [Vector2.ZERO,Vector2(8,0),Vector2(8,8),Vector2(0,8)]:
		var p: Vector2=start+offset;result.append(Vector3(p.x,c._ground(p.x,p.y),p.y))
	return result
func edge(c,start: Vector2,x: float) -> Dictionary:
	var result:={}
	for quad in Shore.quads(c,start,corners(c,start),true):
		for p in quad:
			if is_equal_approx(p.x,x):result[p.z]=p.y
	return result
func test_adjacent_shore_cells_use_actual_bank_heights_at_shared_edge():
	var c=bank()
	var left:=edge(c,Vector2(64,64),72);var right:=edge(c,Vector2(72,64),72)
	if left.size()!=5 or left!=right:return "Fine shoreline boundary splits"
	for z in [66.0,68.0,70.0]:
		if absf(left[z]-c._ground(72,z))>.00001:return "Bank still pinned to coarse edge"
	return true
func test_fine_to_coarse_transition_still_matches_coarse_triangle():
	var c=bank();var a:=Vector2(72,64)
	if not Shore.refined(c,a) or Shore.refined(c,a+Vector2(8,0)):return "Fixture lacks refinement transition"
	for z in edge(c,a,80):
		if absf(edge(c,a,80)[z]-lerpf(c._ground(80,64),c._ground(80,72),(z-64)/8))>.00001:return "Fine/coarse crack"
	return true
func test_dry_cells_beyond_the_shore_buffer_stay_coarse():
	var c=bank()
	return not Shore.refined(c,Vector2(256,256)) and Ribbon._cell(c,Vector2(256,256)).size()==2
func test_tile_boundary_retains_identical_coarse_edge_samples():
	var c=bank();var a:=Vector2(0,200)
	for z in edge(c,a,0):
		if absf(edge(c,a,0)[z]-lerpf(c._ground(0,200),c._ground(0,208),(z-200)/8))>.00001:return "Tile edge contract changed"
	return true
func test_road_projection_and_shore_mesh_share_every_triangle_vertex():
	var c=bank();c.batch=RecordedMesh.new();var a:=Vector2(64,64)
	c._shore_cell(a,8,Array(corners(c,a)))
	var vertices:={}
	for p in c.batch.points:vertices[Vector2(p.x,p.z)]=p.y
	for cell in Ribbon._cell(c,a):
		for p in cell.plane:
			if not vertices.has(Vector2(p.x,p.z)) or vertices[Vector2(p.x,p.z)]!=p.y:return "Road and bank use different surface heights"
	return true
func water(geometry: Dictionary) -> Dictionary:return {water_levels=[{geometry=geometry,height=1.0}]}
func total_length(pieces: Array) -> float:
	var value:=0.0
	for line in pieces:
		for i in range(1,line.size()):value+=line[i].distance_to(line[i-1])
	return value
func test_duplicate_canal_centreline_inside_mapped_water_is_omitted():
	var c=water({type="Polygon",coordinates=[[[0,0],[10,0],[10,10],[0,10],[0,0]]]})
	return Streams.uncovered(c,[[1,5],[9,5]]).is_empty() and absf(total_length(Streams.uncovered(c,[[-5,5],[15,5]]))-10)<.0001
func test_streams_through_water_polygon_holes_remain_visible():
	var c=water({type="Polygon",coordinates=[[[0,0],[10,0],[10,10],[0,10],[0,0]],[[4,4],[6,4],[6,6],[4,6],[4,4]]]})
	return absf(total_length(Streams.uncovered(c,[[-5,5],[15,5]]))-12)<.0001
func test_multipart_water_clips_each_body_without_duplicating_dry_stream():
	var c=water({type="MultiPolygon",coordinates=[[[[0,0],[3,0],[3,10],[0,10],[0,0]]],[[[7,0],[10,0],[10,10],[7,10],[7,0]]]]})
	return absf(total_length(Streams.uncovered(c,[[-5,5],[15,5]]))-14)<.0001 and absf(total_length(Streams.uncovered(c,[[-5,15],[15,15]]))-20)<.0001
