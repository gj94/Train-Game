extends SceneTree
func _init() -> void:
	var suite=preload("res://tests/test_approach_routing.gd").new()
	var failed:=0
	for method in suite.get_method_list():
		if method.name.begins_with("test_"):
			var result=suite.call(method.name)
			if result!=true:failed+=1;printerr("FAIL ",method.name,": ",result)
	print("Approach routing: ",failed," failures")
	quit(1 if failed else 0)
