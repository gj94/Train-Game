extends Node
## Mount stable export packs before loading any game scene or asset preloads.
## Source/editor runs have no index and continue through the same launch scene.
func _ready() -> void:
	if FileAccess.file_exists("res://pack-index.json"):
		var index = JSON.parse_string(FileAccess.get_file_as_string("res://pack-index.json"))
		if not index is Dictionary or index.get("format") != 1 or not index.get("packs") is Array:
			_fail("The game pack list is damaged.")
			return
		for relative in index.packs:
			if not relative is String or not relative.begins_with("packs/") or not relative.ends_with(".pck") or ".." in relative:
				_fail("The game pack list contains an invalid path.")
				return
			if not ProjectSettings.load_resource_pack(OS.get_executable_path().get_base_dir().path_join(relative), false):
				_fail("Missing or damaged game assets: " + relative)
				return
	get_tree().change_scene_to_file.call_deferred("res://game/launch.tscn")

func _fail(message: String) -> void:
	push_error(message)
	var label := Label.new()
	label.text = message + "\nRun Update & Play to repair this installation, or extract the complete download."
	label.position = Vector2(32, 48)
	add_child(label)
