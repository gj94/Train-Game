extends RefCounted
const Plan:=preload("res://game/stream_lookahead.gd")
const View:=preload("res://game/geographic_world.gd")
class EmptyBoards:
	var jobs:=[]
class Geo:
	var route:={chainage=[0.0,5000.0,10000.0],alignment=[[0,0,0],[5000,0,0],[5000,0,5000]]}

func test_prediction_scales_with_time_speed_and_is_bounded():
	return Plan.distance(30,1,6000)==978 and Plan.distance(30,16,6000)==4128 and Plan.distance(50,32,6000)==6000 and Plan.distance(50,32,3000)==3000

func test_prediction_follows_bends_reverse_and_route_ends():
	var route:=Geo.new().route
	var edge:={chainage_start=0.0,chainage_end=10000.0,length=10000.0}
	var forward:=Plan.points(route,edge,4500,1,3000)
	var reverse:=Plan.points(route,edge,6000,-1,3000)
	return forward[-1].is_equal_approx(Vector3(5000,0,2500)) and reverse[-1].is_equal_approx(Vector3(3000,0,0)) and Plan.points(route,edge,9900,1,6000).size()==1 and Plan.points(route,edge,0,-1,6000).is_empty()

func fixture():
	var v:=View.new();v.root=Node3D.new();v.world=RailWorld.new();v.speed_boards=EmptyBoards.new();v.geo=Geo.new()
	v.world.graph.add_node("a",Vector3.ZERO);v.world.graph.add_node("b",Vector3(10000,0,0));v.world.graph.add_edge("ab","a","b")
	v.world.graph.edges.ab.merge({chainage_start=0.0,chainage_end=10000.0})
	v.performance={gpu_cache_ceiling=INF,prefetch_metres=6000.0,prefetch_jobs=100,activation_usec=100000,activation_children=100}
	v._loading_panel=Control.new();v.root.add_child(v._loading_panel)
	return v

func test_hidden_prefetch_never_widens_visible_footprint_or_blocks_play():
	var v=fixture();var t:=Train.new("test",100);t.path=[{edge="ab",dir=1}];t.head_s=1500;t.speed=40
	var eye:=Vector3(1500,0,0)
	v._request(eye);var baseline: Dictionary=v.wanted.duplicate(true)
	v.set_travel_context(t,32);v._request(eye)
	var ok: bool=v.prefetch_count>0 and v.prefetch_count<=100
	var predicted:=""
	for id in v.wanted:
		if v.wanted[id].get("prefetch",false):predicted=id;continue
		ok=ok and baseline.has(id)
		var node:=Node3D.new();v.root.add_child(node);v.loaded[id]={node=node}
	v._refresh_loading();ok=ok and not v.loading
	var source:=Node3D.new();source.add_child(Node3D.new())
	v._stage(predicted,{node=source,origin=Vector3.ZERO});v._activate()
	ok=ok and v.loaded.has(predicted) and not v.loaded[predicted].node.visible
	# Consecutive requests must not oscillate between zero and the job cap.
	v._request(eye);ok=ok and v.prefetch_count>0 and v.prefetch_count<=100
	# Only promotion into the normal request makes a prepared section visible.
	var destination: Vector3=v.wanted[predicted].get("point",eye)
	v._request(destination);ok=ok and v.loaded[predicted].node.visible
	v.root.free();return ok

func test_prediction_cancels_when_camera_detaches_or_direction_changes():
	var v=fixture();var t:=Train.new("test",100);t.path=[{edge="ab",dir=1}];t.head_s=4000;t.speed=40
	v.set_travel_context(t,32);v._request(Vector3(4000,0,0));var ahead: int=v.prefetch_count
	t.path[0].dir=-1;v.set_travel_context(t,32);var changed: bool=v._travel_dirty
	v._request(Vector3(4000,0,0));v.set_travel_context(null,32);v._request(Vector3(4000,0,0))
	var ok: bool=ahead>0 and changed and v.prefetch_count==0 and not v.wanted.values().any(func(j):return j.get("prefetch",false))
	v.root.free();return ok

func test_memory_pressure_drops_speculation_without_dropping_nearby_scenery():
	var v=fixture();var t:=Train.new("test",100);t.path=[{edge="ab",dir=1}];t.head_s=4000;t.speed=40
	v.performance.gpu_cache_ceiling=-1.0;v.set_travel_context(t,32);v._request(Vector3(4000,0,0))
	var ok: bool=v.prefetch_count==0 and not v.wanted.is_empty() and v.queue.size()==v.wanted.size()
	v.root.free();return ok

func test_spatial_index_keeps_station_signal_and_board_requests_at_boundaries():
	var v=fixture()
	v.world.stations=[{code="TEST",origin=Vector3(1999,0,0)}]
	v.world.signals={sig={edge="ab",s=1600.0}}
	v.speed_boards.jobs=[{id="board:near",kind="speed_board",point=Vector3(1649,0,0)},{id="board:far",kind="speed_board",point=Vector3(1651,0,0)}]
	v._request(Vector3.ZERO)
	var ok: bool=v.wanted.has("station:TEST") and v.wanted.has("signal:sig") and v.wanted.has("board:near") and not v.wanted.has("board:far")
	v._request(Vector3(5000,0,0));ok=ok and not v.wanted.has("station:TEST") and not v.wanted.has("signal:sig")
	v.root.free();return ok
