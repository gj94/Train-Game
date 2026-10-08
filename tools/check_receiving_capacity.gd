extends SceneTree
func _init() -> void:
	var suite=preload("res://tests/test_receiving_capacity.gd").new()
	var failures:=0
	for method in suite.get_method_list():
		if not method.name.begins_with("test_"): continue
		var result=suite.call(method.name)
		print(method.name,": ",result)
		if result!=true: failures+=1
	quit(1 if failures else 0)
