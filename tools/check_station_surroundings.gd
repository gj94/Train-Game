extends SceneTree
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var passes:=0;var failures:=0
	for path in ["test_coastal_station_sites","test_station_precinct","test_vegetation_clearance"]:
		var suite=load("res://tests/"+path+".gd").new()
		for method in suite.get_method_list():
			if not str(method.name).begins_with("test_"):continue
			var result=suite.call(method.name)
			if result is bool and result:passes+=1
			else:failures+=1;printerr("FAIL ",path,"::",method.name," ",result)
	print("STATION_SURROUNDINGS ",passes," passed, ",failures," failed")
	quit(failures)
