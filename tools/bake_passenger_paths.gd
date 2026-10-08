extends SceneTree
func _init() -> void:
	var profiles: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/interiors/walkways.json"))
	var doors: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/interiors/exterior_doors.json"))
	var catalog: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://assets/models/ported/manifest.json"))
	var result:={}
	for model in preload("res://sim/passenger_service.gd").CAPACITY:
		var baked: Dictionary=preload("res://game/passenger_paths.gd").bake(profiles[model],catalog[model].passengers,doors[model].doors)
		baked.source_sha256=profiles[model].source_sha256
		result[model]=baked
		print("PAX_PATH ",model," unreachable=",baked.unreachable," / ",catalog[model].passengers.size()*doors[model].doors.size())
	var file:=FileAccess.open("res://data/interiors/passenger_paths.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(result));file.close();quit()
