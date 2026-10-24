extends RefCounted
const Context:=preload("res://game/geographic_shore_context.gd")
const Chunk:=preload("res://game/geographic_scenery_chunk.gd")
class Ground:
	var shore_context=Context.new()
	var station_sites:={}
	var tiles:={}
	func ground_at(_x,_z):return 8.5
	func nearest_rail(_x,_z):return {distance=100.0}
	func tile(key):return tiles.get(key,{})
func lake(ring,holes=[]):return {kind="water",water_height=.2,geometry={type="Polygon",coordinates=[ring]+holes}}
func chunk(geo,key):
	var c=Chunk.new(geo,{},null);c.origin=Vector3(key.x*512,0,key.y*512)
	for f in geo.tile(key).get("features",[]):c.water_levels.append({geometry=f.geometry,height=f.water_height})
	c._index_shores();return c
func test_bank_continues_into_neighbour_without_own_water_polygon():
	var geo=Ground.new()
	geo.tiles[Vector2i(1,0)]={features=[lake([[2,0],[32,0],[32,512],[2,512],[2,0]])]}
	var a=chunk(geo,Vector2i.ZERO);var b=chunk(geo,Vector2i(1,0))
	return a.water_levels.is_empty() and a._ground(512,256)<2 and absf(a._ground(512,256)-b._ground(0,256))<.00001
func test_diagonal_neighbours_share_the_corner_bank():
	var geo=Ground.new()
	geo.tiles[Vector2i(1,1)]={features=[lake([[2,2],[32,2],[32,32],[2,32],[2,2]])]}
	var a=chunk(geo,Vector2i.ZERO);var b=chunk(geo,Vector2i(1,1))
	return a._ground(512,512)<3 and absf(a._ground(512,512)-b._ground(0,0))<.00001
func test_polygon_holes_supply_shores_but_clipped_borders_do_not():
	var waters=[{height=.2,geometry=lake([[0,0],[512,0],[512,512],[0,512],[0,0]],[[[20,20],[40,20],[40,40],[20,40],[20,20]]]).geometry}]
	var segments=Context.segments(waters)
	return segments.size()==4 and segments.all(func(s):return s.a.x>=20 and s.a.y>=20 and s.b.x<=40 and s.b.y<=40)
func test_context_cache_and_halo_are_bounded_and_do_not_edit_source_geometry():
	var geo=Ground.new()
	var source=lake([[2,2],[20,2],[20,20],[2,20],[2,2]])
	geo.tiles[Vector2i(1,0)]={features=[source]}
	var before=JSON.stringify(source)
	var segments=geo.shore_context.around(geo,Vector2i.ZERO,[])
	if segments.is_empty():return "Missing immediate neighbour"
	if not geo.shore_context.around(geo,Vector2i(5,0),[]).is_empty():return "Unbounded shore influence"
	for i in 100:geo.shore_context.around(geo,Vector2i(i,8),[])
	return geo.shore_context.entries.size()<=64 and geo.shore_context.order.size()<=64 and JSON.stringify(source)==before
func test_actual_4100_m_canal_border_uses_the_same_bank_height():
	var geo=preload("res://game/geographic_data.gd").new()
	var chunks=[]
	for key in [Vector2i(1,4),Vector2i(2,4)]:
		var c=Chunk.new(geo,{},null);c.origin=Vector3(key.x*512,0,key.y*512)
		for f in geo.tile(key).get("features",[]):
			if f.kind=="water":c.water_levels.append({geometry=f.geometry,height=f.get("water_height",0)})
		c._index_shores();chunks.append(c)
	var a=chunks[0]._ground(512,400);var b=chunks[1]._ground(0,400)
	return true if absf(a-b)<.001 and a<3 else "Canal boundary mismatch: %s / %s"%[a,b]
func test_each_worker_owns_its_own_mutable_shore_cache():
	var a=preload("res://game/geographic_data.gd").new()
	var b=preload("res://game/geographic_data.gd").new(a.route)
	b.share_railway(a)
	a.shore_context.around(a,Vector2i(1,4),[])
	return not a.shore_context.entries.is_empty() and b.shore_context.entries.is_empty()

func test_water_polygon_boundary_classification_matches_at_real_tile_edges():
	var geo=preload("res://game/geographic_data.gd").new()
	for row in [{key=Vector2i(2,18),point=Vector2(512,0)},
		{key=Vector2i(78,246),point=Vector2(512,8)}]:
		var chunks=[]
		for key in [row.key,row.key+Vector2i.RIGHT]:
			var c=Chunk.new(geo,{},null);c.origin=Vector3(key.x*512,0,key.y*512)
			for f in geo.tile(key).get("features",[]):
				if f.kind=="water":c.water_levels.append({geometry=f.geometry,height=f.get("water_height",0)})
			c._index_shores();chunks.append(c)
		if absf(chunks[0]._ground(row.point.x,row.point.y)-chunks[1]._ground(0,row.point.y))>.001:
			return "Water classification still differs at "+str(row.key)
	return true

func test_reused_corner_water_survives_eviction_while_context_is_built():
	var geo=Ground.new()
	var water={height=.2,geometry=lake([[510,510],[512,510],[512,512],[510,512],[510,510]]).geometry}
	geo.shore_context._remember(Vector2i(-1,-1),[water])
	geo.shore_context._remember(Vector2i.ZERO,[])
	for i in 62:geo.shore_context._remember(Vector2i(100+i,100),[])
	var c=chunk(geo,Vector2i.ZERO)
	# A road/terrain projection one metre into the shared halo stays wet even
	# when missing neighbours require evicting older cache entries mid-build.
	return absf(c._ground(-1,-1)+.3)<.0001 and geo.shore_context.entries.size()==64
