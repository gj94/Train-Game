extends RefCounted
const Deck=preload("res://game/geographic_bridge_deck.gd")
var world
var geo
var layout
class Road:
	var road_profiles=null
	var y:=2.0
	func ground_at(_x,_z):return y
	func tile(key):return {features=[{kind="road",id="footway",tags={highway="footway"},geometry={type="LineString",coordinates=[[0,10],[30,10]]}}]} if key==Vector2i.ZERO else {}
func setup():
	if world!=null:return
	world=preload("res://sim/layouts/kerala_coast.gd").build()
	geo=preload("res://game/geographic_data.gd").new(world.scenery.route)
	layout=preload("res://game/geographic_ohe_layout.gd").new(world)
func area(ring):
	var value:=0.0
	for i in ring.size():value+=ring[i].cross(ring[(i+1)%ring.size()])
	return absf(value)*.5
func test_interior_cut_produces_disjoint_pieces_and_never_fills_a_hole():
	var outer:=PackedVector2Array([Vector2(0,0),Vector2(20,0),Vector2(20,20),Vector2(0,20)])
	var inner:=PackedVector2Array([Vector2(8,8),Vector2(12,8),Vector2(12,12),Vector2(8,12)])
	var total:=0.0
	for part in Deck.subtract_convex(outer,inner):
		if Geometry2D.is_point_in_polygon(Vector2(10,10),part):return "Hole filled by standalone contour"
		total+=area(part)
	return absf(total-384)<.001
func test_shared_footprints_remove_duplicate_coplanar_deck_area():
	var graph:=TrackGraph.new()
	for row in [["a",Vector3(0,0,0)],["b",Vector3(20,0,0)],["c",Vector3(0,0,5)],["d",Vector3(20,0,5)]]:graph.add_node(row[0],row[1])
	graph.add_edge("A","a","b");graph.add_edge("B","c","d")
	var previous=Deck.strips(graph,"A",0,20,Vector3.ZERO);var total:=0.0
	for strip in Deck.strips(graph,"B",0,20,Vector3.ZERO):
		for part in Deck.visible_parts(strip,previous):total+=area(part)
	return absf(total-100)<.01
func test_real_kollam_outer_road_has_bridge_beneath_centre_and_shoulders():
	setup()
	var origin:=Vector3(34304,0,119296)
	var span: Dictionary=geo.bridge_at(140730)
	var decks:=[]
	for eid: String in world.graph.edges:
		var e: Dictionary=world.graph.edges[eid]
		for interval in preload("res://game/geographic_bridges.gd").intervals(e,0,e.length,[span]):
			var others=Deck.peers(world.graph,layout,eid,span,origin)
			for strip in Deck.strips(world.graph,eid,interval.start,interval.end,origin):
				for part in Deck.visible_parts(strip,others):decks.append({ring=part,strip=strip})
	for chain in range(140726,140741):
		var p: Vector3=layout.at_chainage("QLN_P4",chain,origin)
		var edge: Dictionary=world.graph.edges.QLN_P4
		var s: float=(chain-edge.chainage_start)/(edge.chainage_end-edge.chainage_start)*edge.length
		for offset in [-3.8,0.0,3.8]:
			var q: Vector3=p+world.graph.tangent("QLN_P4",s,1).cross(Vector3.UP)*offset
			var point:=Vector2(q.x,q.z);var supported:=false
			for deck in decks:
				if Geometry2D.is_point_in_polygon(point,deck.ring) and absf(Deck.height(deck.strip,point)-p.y)<.6:supported=true;break
			if not supported:return "Unsupported QLN_P4 at %s / %s" % [chain,offset]
	return true
func test_bending_strip_corners_and_chunk_boundary_match():
	var graph:=TrackGraph.new();graph.add_node("a",Vector3.ZERO);graph.add_node("b",Vector3(40,2,12))
	graph.add_edge("curve","a","b",[Vector3(20,1,0)])
	var s: float=graph.edges.curve.cum[1]
	var before=Deck.strips(graph,"curve",0,s,Vector3.ZERO)[-1]
	var after=Deck.strips(graph,"curve",s,graph.edges.curve.length,Vector3.ZERO)[0]
	return before.ring[1].is_equal_approx(after.ring[0]) and before.ring[2].is_equal_approx(after.ring[3])
func test_origin_rebase_keeps_actual_deck_footprints():
	setup()
	var a=Deck.strips(world.graph,"QLN_P4",450,460,Vector3(34304,0,119296))
	var b=Deck.strips(world.graph,"QLN_P4",450,460,Vector3(34048,0,119552))
	for i in a.size():
		for j in 4:
			if (a[i].ring[j]+Vector2(256,-256)).distance_to(b[i].ring[j])>.0001:return false
	return true
func test_yard_interior_guardrails_cannot_cross_another_track():
	setup()
	var origin:=Vector3(34304,0,119296)
	var a: Vector3=layout.at_chainage("QLN_P4",140728,origin)
	var b: Vector3=layout.at_chainage("QLN_P4",140736,origin)
	return not Deck.railing_clear(layout,a,b,origin)
func test_piers_clear_full_road_shoulders_and_keep_grade_separated_roads():
	var geo=Road.new()
	var ring:=PackedVector2Array([Vector2(10,11),Vector2(12,11),Vector2(12,13),Vector2(10,13)])
	if not preload("res://game/geographic_bridge_clearance.gd").clear(geo,ring,5,-2):return "Fixture must isolate the shoulder beyond the narrow carriageway"
	if Deck.pier_clear(geo,ring,5,-2):return "Pier occupies footway shoulder"
	geo.y=7
	return Deck.pier_clear(geo,ring,5,-2)
