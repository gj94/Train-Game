extends SceneTree
func _initialize() -> void:
	var target := "res://export/TrainGame-Windows/ENGINE-LICENSES.txt"
	if not OS.get_cmdline_user_args().is_empty(): target = OS.get_cmdline_user_args()[0]
	var file := FileAccess.open(target, FileAccess.WRITE)
	if file == null:
		printerr("Cannot write engine notices")
		quit(1)
		return
	file.store_string("GODOT ENGINE\n\n" + Engine.get_license_text() + "\n\nTHIRD-PARTY COPYRIGHTS\n\n")
	for entry in Engine.get_copyright_info():
		file.store_string(str(entry) + "\n\n")
	var licenses := Engine.get_license_info()
	for key in licenses:
		file.store_string(str(key) + "\n" + str(licenses[key]) + "\n\n")
	file.close()
	quit()
