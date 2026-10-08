extends SceneTree
func _init() -> void:
	var suite=preload("res://tests/test_overtake_commitment.gd").new();var failures:=0;var count:=0
	for m in suite.get_method_list():
		if not m.name.begins_with("test_"):continue
		count+=1
		var result=suite.call(m.name)
		if not result is bool or not result:failures+=1;printerr("FAIL ",m.name," ",result)
	print("OVERTAKE_TESTS ",count," checks / ",failures," failed")
	var w=preload("res://tests/overtake_fixture.gd").build();var e=w.dispatcher();e._wait_since.K1=w.time-1801;e.run_cycle(true)
	print("OVERTAKE_TRACE ",JSON.stringify({holds=w.dispatch_holds,local=e.states.K1,express=e.states.K3,journal=e.journal}))
	quit(failures)
