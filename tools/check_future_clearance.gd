extends SceneTree
func _init() -> void:
	var suite=preload("res://tests/test_future_clearance.gd").new()
	var failures:=0;var passes:=0
	for method in suite.get_method_list():
		if not method.name.begins_with("test_"):continue
		var result=suite.call(method.name)
		if result is bool and result:passes+=1
		else:
			failures+=1
			printerr("FAIL ",method.name," ",result)
	print("Future clearance: ",passes," passed, ",failures," failed")
	quit(0 if failures==0 else 1)
