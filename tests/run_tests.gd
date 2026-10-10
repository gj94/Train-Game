extends SceneTree
## Headless test runner. Runs every tests/test_*.gd file.
## Each test file extends RefCounted and defines test_* methods that return
## true on pass, or a String describing the failure.
##
## Run: godot --headless --path . --script res://tests/run_tests.gd

func _initialize() -> void:
	# Scene fixtures need an initialized main loop and root viewport.
	call_deferred("run_tests")

func run_tests() -> void:
	var timings := []
	var filter := ""
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--filter="): filter=arg.trim_prefix("--filter=")
	var failures := 0
	var passes := 0
	var dir := DirAccess.open("res://tests")
	for file in dir.get_files():
		if not (file.begins_with("test_") and file.ends_with(".gd")):
			continue
		if not filter.is_empty() and not file.contains(filter): continue
		var script = load("res://tests/" + file)
		if script == null or not script.can_instantiate():
			failures += 1
			printerr("FAIL %s  does not compile" % file)
			continue
		var suite = script.new()
		for m in suite.get_method_list():
			var name: String = m.name
			if not name.begins_with("test_"):
				continue
			var start := Time.get_ticks_usec()
			var result = suite.call(name)
			timings.append({test=file+"::"+name,seconds=(Time.get_ticks_usec()-start)/1000000.0})
			if timings[-1].seconds>2: print("SLOW %s %.2fs" % [timings[-1].test,timings[-1].seconds])
			if typeof(result) == TYPE_BOOL and result:
				passes += 1
			else:
				failures += 1
				printerr("FAIL %s::%s  %s" % [file, name, str(result)])
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--timings="):
			timings.sort_custom(func(a,b):return a.seconds>b.seconds)
			FileAccess.open(arg.trim_prefix("--timings="),FileAccess.WRITE).store_string(JSON.stringify(timings,"\t"))
	print("Tests: %d passed, %d failed" % [passes, failures])
	quit(1 if failures > 0 else 0)
