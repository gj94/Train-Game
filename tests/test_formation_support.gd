extends RefCounted
const Support=preload("res://game/geographic_formation_support.gd")
const Bridges=preload("res://game/geographic_bridges.gd")
const Chunk=preload("res://game/geographic_scenery_chunk.gd")
const Surface=preload("res://game/geographic_road_support.gd")
class BridgeData:
	var open:=false
	func bridge_at(_s):return {start=0,end=100} if open else {}
class RoadData:
	var road_profiles=null
	var height:=5.0
	var grade:=0.0
	func ground_at(x,_z):return height+grade*x
	func tile(key):
		return {features=[{kind="road",id="fixture",tags={highway="residential"},geometry={type="LineString",coordinates=[[0,10],[30,10]]}}]} if key==Vector2i.ZERO else {}
var world
var geo
func fixture():
	var support=Support.new()
	support.bins[Vector2i.ZERO]=[{a=Vector3(10,10,10),b=Vector3(110,10,10),start=0.0,end=100.0}]
	return support
func setup():
	if world!=null:return
	world=preload("res://sim/layouts/kerala_coast.gd").build()
	geo=preload("res://game/geographic_data.gd").new(world.scenery.route)
	geo.install_railway(world);geo.station_sites=preload("res://game/coastal_station_sites.gd").build(world,geo)
func test_mapped_water_does_not_excavate_a_nonbridge_operating_formation():
	return absf(fixture().water_ground(BridgeData.new(),Vector2(50,12),9.85,2)-9.85)<.0001
func test_water_formation_batter_tapers_back_to_the_water_bed():
	var s=fixture();var g=BridgeData.new();var last:=10.0
	for offset in [0.0,7.0,12.0,20.0,27.0,40.0]:
		var h: float=s.water_ground(g,Vector2(50,10+offset),9.85,2)
		if h>last or h<2:return "Nonmonotonic water bank"
		last=h
	return last==2
func test_actual_bridge_chainage_keeps_the_water_open():
	var g=BridgeData.new();g.open=true
	return fixture().water_ground(g,Vector2(50,10),9.85,2)==2
func test_abutments_stay_landward_and_clip_to_the_requested_chunk():
	var edge={chainage_start=0.0,chainage_end=100.0,length=100.0}
	var spans=[{start=30.0,end=50.0}]
	return Bridges.approaches(edge,0,100,spans)==[Vector2(27,30),Vector2(50,53)] and Bridges.approaches(edge,28,51,spans)==[Vector2(28,30),Vector2(50,51)]
func test_abutments_never_fill_an_adjacent_bridge_opening():
	var edge={chainage_start=0.0,chainage_end=100.0,length=100.0}
	var spans=[{start=30.0,end=50.0},{start=51.0,end=60.0}]
	for approach in Bridges.approaches(edge,0,100,spans):
		for span in spans:
			if minf(approach.y,span.end)-maxf(approach.x,span.start)>.00001:return "Abutment blocks another opening"
	return true
func test_abutment_clipping_rejects_float32_boundary_slivers():
	var edge={chainage_start=172000.0,chainage_end=173000.0,length=1000.01}
	for span in Bridges.approaches(edge,0,edge.length,[{start=172117.88,end=172200.231},{start=172200.23,end=172300.34}]):
		if span.y-span.x<=.05:return "Degenerate bridge wall"
	return true
func test_landward_wall_preserves_lower_road_and_allows_road_above_it():
	var g=RoadData.new();var ring:=PackedVector2Array([Vector2(10,8),Vector2(13,8),Vector2(13,12),Vector2(10,12)])
	var clearance=preload("res://game/geographic_bridge_clearance.gd")
	if clearance.clear(g,ring,7,1):return "Wall blocks lower road"
	g.height=7.2
	return clearance.clear(g,ring,7,1)
func test_abutment_checks_the_whole_road_overlap_on_a_gradient():
	var g=RoadData.new();g.height=1.5;g.grade=.5
	var ring:=PackedVector2Array([Vector2(10,8),Vector2(13,8),Vector2(13,12),Vector2(10,12)])
	# The overlap centre is above the wall, but its lower end is obstructed.
	return not preload("res://game/geographic_bridge_clearance.gd").clear(g,ring,7,1)
func test_existing_terminal_extensions_receive_ground_at_their_actual_position():
	setup()
	for id in ["ERS_END_D","ERS_END_U","NCJ_END_D","NCJ_END_U"]:
		for fraction in [.05,.25,.5,.75,.95]:
			var p: Vector3=world.graph.position(id,world.graph.edges[id].length*fraction)
			if absf(geo.ground_at(p.x,p.z)-(p.y-.15))>.15:return "Unsupported terminal "+id
	return true
func qln_landward_position() -> float:
	# Keep this regression at the physical bridge end when yard turnouts move.
	var end: float=geo.bridges.filter(func(b):return b.end>140730 and b.end<140750)[0].end
	var e: Dictionary=world.graph.edges.QLN_P4
	return (end+2.0-e.chainage_start)/(e.chainage_end-e.chainage_start)*e.length
func test_outer_approach_uses_its_actual_chainage_beyond_the_bridge():
	setup()
	var p: Vector3=world.graph.position("QLN_P4",qln_landward_position())
	var q: Vector3=p+world.graph.tangent("QLN_P4",qln_landward_position(),1).cross(Vector3.UP)*3.95
	var rail: Dictionary=geo.nearest_rail(q.x,q.z)
	return not rail.bridge and absf(geo.ground_at(q.x,q.z)-(p.y-.15))<.05
func test_confirmed_bridge_end_and_terminal_gaps_have_terrain_or_abutment_support():
	setup()
	for sample in [["QLN_P4",qln_landward_position()],["AMY_P2",910],["TVC_P4",310],["TVC_P5",310],["TZH_KVTA_D3",310],["OCR_KPY_U3",685],["NYY_AMVA_M0",535],["KZTW_KZT_M0",910],["ERS_END_U",10],["ERS_END_U",85],["NCJ_END_D",235],["NCJ_END_U",235]]:
		var edge: Dictionary=world.graph.edges[sample[0]]
		var p: Vector3=world.graph.position(sample[0],sample[1]);var tile:=Vector2i(floori(p.x/512),floori(p.z/512))
		var c=Chunk.new(geo,{},null);c.origin=Vector3(tile.x*512,0,tile.y*512)
		for f in geo.tile(tile).get("features",[]):
			if f.kind=="water":c.water_levels.append({geometry=f.geometry,height=f.get("water_height",0)})
		c._index_shores()
		var q: Vector3=p-c.origin;var h: float=Surface.surface_height(c,Vector2(q.x,q.z))
		if h>p.y+.1:return "Terrain buries rail "+sample[0]
		if h<p.y-.6 and not Bridges.approaches(edge,0,edge.length,geo.bridges).any(func(span):return sample[1]>=span.x and sample[1]<=span.y):return "Gap remains on "+sample[0]
	return true
func test_workers_share_the_immutable_actual_formation_index():
	setup()
	var worker=preload("res://game/geographic_data.gd").new(world.scenery.route);worker.share_railway(geo)
	return worker.formation_support==geo.formation_support and not geo.formation_support.fine_cells.is_empty()
