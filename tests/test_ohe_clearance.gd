extends RefCounted
const Layout := preload("res://game/geographic_ohe_layout.gd")

func tracks(offsets: Array,curved: bool=false) -> RailWorld:
	var w:=RailWorld.new()
	for i in offsets.size():
		var eid:="R"+str(i)
		w.graph.add_node(eid+"A",Vector3(0,0,offsets[i]))
		w.graph.add_node(eid+"B",Vector3(220,0,offsets[i]))
		w.graph.add_edge(eid,eid+"A",eid+"B",[Vector3(110,0,offsets[i]+12)] if curved else [])
		w.graph.edges[eid].merge({chainage_start=0.0,chainage_end=220.0})
	return w

func clear_of_segments(w: RailWorld,plan: Dictionary) -> bool:
	for post: Vector3 in plan.posts:
		for edge in w.graph.edges.values():
			for i in range(1,edge.points.size()):
				var a:=Vector2(edge.points[i-1].x,edge.points[i-1].z)
				var b:=Vector2(edge.points[i].x,edge.points[i].z)
				var p:=Vector2(post.x,post.z)
				if p.distance_to(Geometry2D.get_closest_point_to_segment(p,a,b))<3.0:return false
	return true

func test_double_track_supports_are_outside_both_lines():
	var w:=tracks([0.0,5.3])
	var layout:=Layout.new(w)
	if layout.clearance.clear_point(Vector3(55,0,3.6),3.0):return "Fixture must reproduce the old pillar collision"
	var plan: Dictionary=layout.plans("R0",0,220,Vector3.ZERO)[1]
	return plan.posts.size()==2 and plan.posts[0].z<0 and plan.posts[1].z>5.3 and clear_of_segments(w,plan)

func test_curved_parallel_track_supports_clear_actual_segments():
	var w:=tracks([0.0,4.8,10.4],true)
	var layout:=Layout.new(w)
	for plan in layout.plans("R0",0,w.graph.edges.R0.length,Vector3.ZERO):
		if not clear_of_segments(w,plan):return "Pillar inside curved track clearance"
	return true

func test_shared_yard_gantry_clears_tracks_and_outer_platforms():
	var w:=tracks([0.0,5.3,11.0,16.3,25.0,30.3])
	w.stations=[{s=110.0,platform_tracks=["R0","R5"],platform_details={
		R0={platform_width=8.0,platform_side=-1},R5={platform_width=7.0,platform_side=1}}}]
	var plan: Dictionary=Layout.new(w).plans("R0",0,220,Vector3.ZERO)[1]
	return plan.portal and plan.posts[0].z<-10 and plan.posts[1].z>39 and clear_of_segments(w,plan)

func test_chunk_and_parallel_road_boundaries_do_not_duplicate_supports():
	var w:=tracks([0.0,5.3])
	var layout:=Layout.new(w)
	var chains:=[]
	for eid in w.graph.edges:
		for limits in [[0.0,55.0],[55.0,110.0],[110.0,220.0]]:
			for plan in layout.plans(eid,limits[0],limits[1],Vector3.ZERO):
				if plan.chainage in chains:return "Duplicate mast row"
				chains.append(plan.chainage)
	return chains==[0.0,55.0,110.0,165.0]

func test_yard_support_row_avoids_the_passenger_footbridge():
	var w:=tracks([0.0,5.3,11.0])
	w.stations=[{s=50.0,through_halt=false,platform_tracks=[]}]
	var plans: Array=Layout.new(w).plans("R0",0,220,Vector3.ZERO)
	return plans.size()==4 and plans.all(func(p):return absf(p.chainage-110)>5)
