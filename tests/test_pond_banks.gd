extends RefCounted
const Chunk:=preload("res://game/geographic_scenery_chunk.gd")
const Banks:=preload("res://game/geographic_water_bank.gd")
const Streams:=preload("res://game/geographic_stream_surface.gd")
const Surface:=preload("res://game/geographic_road_support.gd")
class Ground:
	var station_sites:={}
	var formation_support=null
	var rail_distance:=100.0
	var curved:=false
	var tiles:={}
	func tile(key):return tiles.get(key,{})
	func ground_at(x,z):return 2.0+sin(x*.1)*2+cos(z*.15) if curved else 2.0
	func nearest_rail(_x,_z):return {distance=rail_distance}
func fixture(distance: float):
	var geo=Ground.new();geo.rail_distance=distance
	var c=Chunk.new(geo,{},null)
	c.water_levels=[{height=6.0,geometry={type="Polygon",coordinates=[[[30,30],[60,30],[60,60],[30,60],[30,30]]]}}]
	c._index_shores();return c
func test_low_pond_bank_rises_to_water_without_modifying_rail_corridor():
	return fixture(100)._ground(29,45)>6 and fixture(10)._ground(29,45)==2.0
func test_bank_rise_fades_gradually_away_from_rail_and_shore():
	var last:=2.0
	for distance in [16.0,18.0,22.0,26.0,28.0]:
		var h: float=fixture(distance)._ground(29,45)
		if h<last or h>6.22:return "Nonmonotonic rail transition"
		last=h
	var c=fixture(100)
	return c._ground(20,45)==2.0 and c._ground(25,45)<c._ground(29,45)
func test_confined_bank_has_grounded_face_and_clear_formation():
	var c=fixture(10);var water=c.water_levels[0];var faces:=Banks.faces(c,{geometry=water.geometry,water_height=water.height})
	if faces.is_empty():return "Missing confined pond face"
	for face in faces:
		if face.top<6.06 or face.low_a>2 or face.low_b>2:return "Suspended face"
	c.geo.rail_distance=2
	return Banks.faces(c,{geometry=water.geometry,water_height=water.height}).is_empty()
func test_no_retaining_face_on_artificial_tile_boundary():
	var c=fixture(10)
	var feature={geometry={type="Polygon",coordinates=[[[0,0],[512,0],[512,512],[0,512],[0,0]]]},water_height=6.0}
	return Banks.faces(c,feature).is_empty()
func test_stream_triangles_follow_actual_ground_including_bends():
	var c=Chunk.new(Ground.new(),{},null);c.geo.curved=true
	c.batch=preload("res://game/geographic_mesh.gd").new()
	Streams.draw(c,{tags={waterway="stream"},geometry={type="LineString",coordinates=[[10,10],[80,80],[100,30]]}})
	var arrays=c.batch.surfaces.water.commit().surface_get_arrays(0)
	var points: PackedVector3Array=arrays[Mesh.ARRAY_VERTEX]
	for i in range(0,points.size(),3):
		for p in [points[i],points[i+1],points[i+2],(points[i]+points[i+1]+points[i+2])/3]:
			if absf(p.y-Surface.surface_height(c,Vector2(p.x,p.z))-.04)>.0001:return "Stream leaves terrain plane"
	return true
func test_covered_stream_emits_no_water_mesh():
	var c=Chunk.new(Ground.new(),{},null);c.batch=preload("res://game/geographic_mesh.gd").new()
	Streams.draw(c,{tags={waterway="stream",covered="yes"},geometry={type="LineString",coordinates=[[10,10],[80,80]]}})
	return c.batch.surfaces.is_empty()

func test_retaining_faces_leave_adjacent_roads_open():
	var c=fixture(10)
	c.geo.tiles[Vector2i.ZERO]={features=[{kind="road",tags={highway="residential"},geometry={type="LineString",coordinates=[[30,20],[30,70]]}}]}
	var water=c.water_levels[0]
	var faces:=Banks.faces(c,{geometry=water.geometry,water_height=water.height})
	return not faces.is_empty() and faces.all(func(face):return minf(face.a.x,face.b.x)>33)
