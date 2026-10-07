extends RefCounted
const Distances := preload("res://sim/route_distances.gd")

func test_long_directed_route_has_no_64_edge_limit():
	var graph := TrackGraph.new()
	for i in 201: graph.add_node(str(i),Vector3(i*1500,0,0))
	for i in 200: graph.add_edge("E"+str(i),str(i),str(i+1),[],30,1)
	var distances := Distances.new(graph)
	var stop := {block="E199",direction=1,s=1000.0}
	if absf(distances.distance("E0",1,100,stop)-299400)>0.01: return "Long route unreachable or wrong distance"
	if not is_inf(distances.distance("E10",-1,500,stop)): return "Wrong-way path became reachable"
	return true

func test_turnout_branches_cannot_shortcut_across_the_toe():
	var graph := TrackGraph.new()
	for pair in [["A",Vector3.ZERO],["B",Vector3(100,0,0)],["C",Vector3(200,0,0)],["D",Vector3(200,0,8)]]:
		graph.add_node(pair[0],pair[1])
	graph.add_edge("trunk","A","B")
	graph.add_edge("normal","B","C")
	graph.add_edge("reverse","B","D")
	graph.add_switch("B","trunk","normal","reverse")
	var distances := Distances.new(graph)
	var stop := {block="reverse",direction=1,s=50.0}
	if distances.distance("trunk",1,20,stop)!=130: return "Facing route missing"
	if not is_inf(distances.distance("normal",-1,50,stop)): return "Illegal branch-to-branch shortcut"
	graph.switches.B.reversed=true
	return distances.distance("trunk",1,20,stop)==130

func test_geographic_interpolation_preserves_subcentimetre_steps():
	var graph := TrackGraph.new()
	graph.add_metric_node("A",[123456.123456,20.0,278000.234567])
	graph.add_metric_node("B",[123456.123456,20.0,279000.234567])
	graph.add_metric_edge("AB","A","B",[],30)
	var origin := Vector3(123392,0,278528)
	var a := graph.position_relative("AB",300,origin)
	var b := graph.position_relative("AB",300.003,origin)
	if absf(a.x-64.123456)>.0001: return "Origin subtraction lost coordinate precision"
	if absf(b.z-a.z-.003)>.0001: return "Nearby movement quantised at large map coordinates"
	return graph.edges.AB.length==1000.0 and graph.tangent("AB",300,1).is_equal_approx(Vector3.BACK)
