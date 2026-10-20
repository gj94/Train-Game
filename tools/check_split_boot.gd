extends SceneTree
## Run with the matching Godot editor binary beside the private packs,
## --main-pack TrainGame.pck and an absolute --script path.
## Standard export templates do not provide the extended --script tool.
## Verifies pack mounting and the actual service browser; never starts driving.
func _initialize() -> void:
	call_deferred("_audit")

func _audit() -> void:
	if current_scene == null:
		var bootstrap = load("res://game/bootstrap.tscn").instantiate()
		root.add_child(bootstrap)
	for frame in range(3):
		await process_frame
	if current_scene == null or current_scene.scene_file_path != "res://game/launch.tscn":
		printerr("FAIL: split bootstrap did not reach service selection")
		quit(1)
		return
	var verified := 0
	for folder in ["service_starts", "railway_times"]:
		var base: String = "res://data/" + folder + "/"
		var catalogue = JSON.parse_string(FileAccess.get_file_as_string(base + "catalogue.json"))
		var rows: Array = catalogue.services if folder == "service_starts" else catalogue.states
		for row in rows:
			if FileAccess.get_sha256(base + row.file) != row.sha256:
				printerr("FAIL: prepared state " + row.id)
				quit(1)
				return
			verified += 1
	if verified != 333:
		printerr("FAIL: expected 333 prepared states")
		quit(1)
		return
	for asset in ["wap7", "lhb_sl", "icf_sl", "vb_dtc"]:
		var path: String = "res://assets/models/ported/" + asset + ".glb"
		if not ResourceLoader.load(path) is PackedScene:
			printerr("FAIL: cross-pack model dependencies " + path)
			quit(1)
			return
	if not ResourceLoader.load("res://assets/sounds/body_v2/impact-1.wav") is AudioStream:
		printerr("FAIL: cross-pack audio import")
		quit(1)
		return
	print("PASS: split bootstrap reached service selection; 333 prepared states, four fleet scenes and audio import verified; no driving session started.")
	quit()
