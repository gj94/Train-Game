extends SceneTree
func _initialize() -> void:
	var started:=Time.get_ticks_msec()
	var world:=preload("res://sim/layouts/kerala_coast.gd").build()
	var bins:=preload("res://game/station_precinct_plan.gd").build(world)
	var count:=0;var links:=0
	for station in world.stations:
		var plans:=preload("res://game/station_precinct_plan.gd").entries(bins,station)
		for plan in plans:
			count+=1;links+=plan.access.size()
			print("PRECINCT ",station.code," extent=",plan.extent," access=",plan.access.size()," ground=",plan.height)
	print("PRECINCT plans=",count," links=",links," elapsed_ms=",Time.get_ticks_msec()-started)
	var clearances=preload("res://game/vegetation_clearance.gd").build(world)
	print("VEGETATION cells=",clearances.cells.size()," elapsed_ms=",Time.get_ticks_msec()-started)
	quit()
