extends SceneTree
func _init() -> void:
	var suite=preload("res://tests/test_passenger_service.gd").new();var failed:=0;var passed:=0
	for m in suite.get_method_list():
		if not m.name.begins_with("test_"):continue
		var result=suite.call(m.name)
		if result is bool and result:passed+=1
		else:failed+=1;printerr("FAIL ",m.name," ",result)
	print("PASSENGER_TESTS ",passed," passed / ",failed," failed");quit(failed)
