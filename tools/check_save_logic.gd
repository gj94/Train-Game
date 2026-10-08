extends SceneTree
func _init() -> void:
	var suite=preload("res://tests/test_save_game.gd").new();var count:=0;var failures:=0
	for m in suite.get_method_list():
		if not m.name.begins_with("test_"):continue
		var result=suite.call(m.name);count+=1
		print(m.name," ",result)
		if not result is bool or not result:failures+=1
	print("SAVE_TESTS ",count," / failed ",failures);quit(failures)
