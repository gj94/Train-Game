extends SceneTree
## Headless test runner. Runs every tests/test_*.gd file.
## Each test file extends RefCounted and defines test_* methods that return
## true on pass, or a String describing the failure.
##
## Run: godot --headless --path . --script res://tests/run_tests.gd

func _init() -> void:
	var failures := 0
	var passes := 0
	var dir := DirAccess.open("res://tests")
	for file in dir.get_files():
		if not (file.begins_with("test_") and file.ends_with(".gd")):
			continue
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
			var result = suite.call(name)
			if typeof(result) == TYPE_BOOL and result:
				passes += 1
			else:
				failures += 1
				printerr("FAIL %s::%s  %s" % [file, name, str(result)])
	print("Tests: %d passed, %d failed" % [passes, failures])
	quit(1 if failures > 0 else 0)
