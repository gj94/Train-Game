extends RefCounted
## Fingerprints only inputs that define the prepared railway; presentation is free
## to change without replaying the timetable.
const ROOTS:=["res://sim","res://data/routes/kerala_coast"]
static func digest(path: String) -> String:
	return FileAccess.get_sha256(path) if path.ends_with(".bin") else FileAccess.get_file_as_string(path).replace("\r\n","\n").sha256_text()
static func collect() -> Dictionary:
	var result:={}
	for path in ROOTS:_walk(path,result)
	return result
static func _walk(path: String,result: Dictionary) -> void:
	var dir:=DirAccess.open(path)
	for name in dir.get_files():
		if name.get_extension() in ["gd","json","bin","csv"]:result[path.path_join(name).trim_prefix("res://")]=digest(path.path_join(name))
	for name in dir.get_directories():_walk(path.path_join(name),result)
