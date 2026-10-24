extends RefCounted
const Join=preload("res://game/geographic_road_junctions.gd")
const Reserve=preload("res://game/geographic_road_reservations.gd")
const Profiles=preload("res://game/geographic_road_profiles.gd")
class Data:
	var road_profiles=null
	var tiles:={}
	func tile(key):return tiles.get(key,{})
class Ground:
	func _ground(_x,_z):return 0.0
func rectangle(a: Vector2,b: Vector2):return PackedVector2Array([a,Vector2(b.x,a.y),b,Vector2(a.x,b.y)])
func contains(parts,p):return parts.any(func(ring):return Geometry2D.is_point_in_polygon(p,ring))
func branch(id: String,a: Vector2,b: Vector2,tags: Dictionary={}):
	return {id=id,kind="road",tags={highway="residential"} if tags.is_empty() else tags,geometry={type="LineString",coordinates=[[a.x,a.y],[b.x,b.y]]}}
func test_low_parallel_road_cannot_use_the_level_crossing_exception():
	var reserve=Reserve.new();reserve.add(rectangle(Vector2(0,-2.8),Vector2(30,2.8)),9.05,.52,Vector2.RIGHT)
	var ring=rectangle(Vector2(10,1),Vector2(14,5))
	var parts=reserve.clip(ring,Vector3.ZERO,-.55,-.08,Vector2.RIGHT)
	return not contains(parts,Vector2(12,2)) and contains(parts,Vector2(12,4))
func test_true_crossings_underpasses_and_flyovers_are_retained():
	var reserve=Reserve.new();reserve.add(rectangle(Vector2(0,-2.8),Vector2(30,2.8)),9.05,.52,Vector2.RIGHT)
	var ring=rectangle(Vector2(10,-4),Vector2(14,4))
	for row in [[-.55,-.08,Vector2.UP],[-5.0,-4.5,Vector2.RIGHT],[10.0,10.4,Vector2.RIGHT],[-.55,-.08,Vector2(1,1)]]:
		if not contains(reserve.clip(ring,Vector3.ZERO,row[0],row[1],row[2]),Vector2(12,0)):return "Legitimate crossing/other level clipped"
	return true
func test_junction_shoulders_open_only_where_the_other_carriageway_meets():
	var data=Data.new();var join=Join.new(data,Vector3.ZERO,[branch("cross",Vector2(0,-10),Vector2(0,10))])
	var parts=join.clip(Ground.new(),"main",[rectangle(Vector2(-10,4),Vector2(10,4.65))],Vector3(-10,.045,4),Vector3(10,.045,4))
	return not contains(parts,Vector2(0,4.3)) and contains(parts,Vector2(8,4.3))
func test_grade_separated_road_does_not_erase_lower_road_markings():
	var data=Data.new();data.road_profiles=Profiles.new({segments=[["cross",0,-10,8,0,10,8,1]]})
	var join=Join.new(data,Vector3.ZERO,[branch("cross",Vector2(0,-10),Vector2(0,10))])
	return contains(join.clip(Ground.new(),"main",[rectangle(Vector2(-10,-.1),Vector2(10,.1))],Vector3(-10,.085,0),Vector3(10,.085,0)),Vector2.ZERO)
func test_own_road_continuation_never_clips_its_verge():
	var join=Join.new(Data.new(),Vector3.ZERO,[branch("main",Vector2(0,-10),Vector2(0,10))])
	return contains(join.clip(Ground.new(),"main",[rectangle(Vector2(-10,4),Vector2(10,4.65))],Vector3(-10,.045,4),Vector3(10,.045,4)),Vector2(0,4.3))
func test_joining_road_in_adjacent_tile_opens_the_same_mouth():
	var data=Data.new();data.tiles[Vector2i(1,0)]={features=[branch("cross",Vector2(1,0),Vector2(1,30))]}
	var join=Join.new(data,Vector3.ZERO,[])
	var parts=join.clip(Ground.new(),"main",[rectangle(Vector2(508,10),Vector2(512,10.65))],Vector3(508,.045,10),Vector3(512,.045,10))
	return not contains(parts,Vector2(511.5,10.3)) and contains(parts,Vector2(508.5,10.3)) and join.loaded.size()<=2
func test_unrendered_tunnel_and_unprofiled_bridge_never_cut_the_surface():
	for tags in [{highway="residential",layer="-1"},{highway="residential",bridge="yes"},{highway="residential",tunnel="yes"}]:
		var join=Join.new(Data.new(),Vector3.ZERO,[branch("cross",Vector2(0,-10),Vector2(0,10),tags)])
		if not contains(join.clip(Ground.new(),"main",[rectangle(Vector2(-10,4),Vector2(10,4.65))],Vector3(-10,.045,4),Vector3(10,.045,4)),Vector2(0,4.3)):return false
	return true
func test_point_road_features_are_not_treated_as_ribbons():
	var features=[{id="point",kind="road",tags={highway="crossing"},geometry={type="Point",coordinates=[1,2]}}]
	var join=Join.new(Data.new(),Vector3.ZERO,features)
	return join.cells.is_empty()

func test_short_crossing_apron_connects_the_trimmed_parallel_road():
	var reserve=Reserve.new();reserve.add(rectangle(Vector2(0,-2.8),Vector2(30,2.8)),9.05,.52,Vector2.RIGHT)
	var ring=rectangle(Vector2(5,1),Vector2(25,5))
	var crossing={axis=Vector2.UP,height=-.08,ring=rectangle(Vector2(10,-4),Vector2(14,5))}
	var parts=reserve.clip(ring,Vector3.ZERO,-.55,-.08,Vector2.RIGHT,[crossing])
	return contains(parts,Vector2(12,2)) and not contains(parts,Vector2(18,2)) and contains(parts,Vector2(18,4))
func test_high_crossroad_and_parallel_roads_cannot_exempt_rail_clearance():
	var reserve=Reserve.new();reserve.add(rectangle(Vector2(0,-2.8),Vector2(30,2.8)),9.05,.52,Vector2.RIGHT)
	var ring=rectangle(Vector2(5,1),Vector2(25,5))
	for crossing in [{axis=Vector2.UP,height=8,ring=ring},{axis=Vector2.RIGHT,height=-.08,ring=ring}]:
		if contains(reserve.clip(ring,Vector3.ZERO,-.55,-.08,Vector2.RIGHT,[crossing]),Vector2(12,2)):return false
	return true
func test_projected_road_edges_are_clipped_using_actual_height_and_keep_the_plane():
	var reserve=Reserve.new();reserve.add(rectangle(Vector2(0,-2.8),Vector2(30,2.8)),9.05,.52,Vector2.RIGHT)
	var triangle=PackedVector3Array([Vector3(10,-.1,1),Vector3(14,-.1,1),Vector3(10,-1,5)])
	var pieces=preload("res://game/geographic_road_surface.gd").clip_projected([triangle],reserve,Vector3.ZERO,Vector2.RIGHT)
	if pieces.is_empty():return false
	for piece in pieces:
		for p in piece:
			if p.z<2.799 or absf(p.y-(-.1-(p.z-1)*.225))>.0001:return false
	return true
