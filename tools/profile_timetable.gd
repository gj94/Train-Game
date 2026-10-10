extends SceneTree
## Pure simulation throughput: no rendering, sleeping or frame-rate throttle.
func _init() -> void:
	var began := Time.get_ticks_usec()
	var w := preload("res://sim/layouts/kerala_coast.gd").build_traffic("--busy" in OS.get_cmdline_user_args())
	var built := Time.get_ticks_usec()
	w.dispatcher().enabled = true
	w.profile_enabled = true
	var seconds := 600
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--seconds="): seconds = int(arg.trim_prefix("--seconds="))
	for tick in seconds / 2: w.step(2.0)
	var wall := (Time.get_ticks_usec() - built) / 1000000.0
	var result := {services=w.trains.size(),simulation_seconds=seconds,build_seconds=(built-began)/1000000.0,wall_seconds=wall,speedup=seconds/wall,phases_usec=w.profile_usec,events=w.events}
	print(JSON.stringify(result))
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--output="):
			var file := FileAccess.open(arg.trim_prefix("--output="), FileAccess.WRITE)
			file.store_string(JSON.stringify(result,"\t"))
	quit(0 if w.events.is_empty() else 1)
