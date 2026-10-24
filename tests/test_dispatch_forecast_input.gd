extends RefCounted
const InputData:=preload("res://sim/dispatch_forecast_input.gd")
const Solver:=preload("res://sim/overtake_solver.gd")

func test_karunagappalli_baseline_has_safe_sasthamkotta_candidate():
	var w:=preload("res://tests/predictive_fixture.gd").build(42000)
	var network:=InputData.topology(w);var frame:=InputData.frame(w)
	var solver:=Solver.new(network)
	var slow: Dictionary=frame.trains.filter(func(t):return t.id=="K1")[0]
	var fast: Dictionary=frame.trains.filter(func(t):return t.id=="B002")[0]
	var choice:=solver.pair(frame,slow,fast)
	if choice.get("station","")!="STKT" or choice.road!="STKT_P3" or choice.passing_road!="STKT_P1":return "Baseline did not compare the natural STKT loop call"
	if choice.margin<45 or choice.wait>300:return "No useful headway/wait improvement"
	if not data_only(network) or not data_only(frame):return "Live engine object escaped into worker input"
	var before: float=slow.speed;w.trains.K1.speed=12
	return slow.speed==before and network.edges.KPY_P1.limit==w.graph.edges.KPY_P1.speed_limit

func data_only(value) -> bool:
	if value is Object:return false
	if value is Dictionary:
		for key in value:
			if not data_only(key) or not data_only(value[key]):return false
	if value is Array:
		for child in value:
			if not data_only(child):return false
	return true
