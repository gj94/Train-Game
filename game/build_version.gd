extends RefCounted
## Read the packaged build identity; source sessions never borrow a stale release.
static func describe(text: String) -> String:
	var name:=""
	var revision:=""
	for entry in text.split("\n"):
		var line: String=entry.trim_prefix(char(0xfeff))
		if line.begins_with("Build: "):name=line.trim_prefix("Build: ").strip_edges()
		elif line.begins_with("Source base: "):revision=line.trim_prefix("Source base: ").strip_edges()
	if name.is_empty():return "Development build"
	return name+(" · "+revision if not revision.is_empty() else "")

static func current() -> String:
	if OS.has_feature("editor"):return "Development build"
	var path:=OS.get_executable_path().get_base_dir().path_join("BUILD.txt")
	return describe(FileAccess.get_file_as_string(path)) if FileAccess.file_exists(path) else "Build identity unavailable"
