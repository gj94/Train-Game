extends SceneTree
func _init() -> void:
	var suite=preload("res://tests/test_depot_workings.gd").new()
	var failures:=0
	for m in suite.get_method_list():
		if not str(m.name).begins_with("test_"):continue
		var result=suite.call(m.name)
		print(m.name,": ",result)
		if not (result is bool and result):failures+=1
	quit(failures)
