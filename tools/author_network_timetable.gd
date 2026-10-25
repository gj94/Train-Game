extends SceneTree
func _initialize() -> void:call_deferred("run")
func run() -> void:
	var network=load("res://sim/timetables/kerala_network.gd")
	var w=load("res://sim/layouts/kerala_coast.gd").build(true)
	for mode in [false,true]:
		var data: Dictionary=network.pack(w,mode)
		var checked: Dictionary=load("res://sim/service_pack.gd").build(data)
		if not checked.ok:printerr(checked.reason);quit(1);return
		var path:="res://art/timetables/kerala-coast-network"+("-v2" if mode else "")+".json"
		FileAccess.open(path,FileAccess.WRITE).store_string(JSON.stringify(checked.data,"\t")+"\n")
		print("AUTHORED ",path," services=",checked.world.trains.size())
	quit()
