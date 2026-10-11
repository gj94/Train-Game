extends SceneTree
func _initialize() -> void:call_deferred("run")
func run() -> void:
	var timeline:="--timeline" in OS.get_cmdline_user_args()
	var directory:="res://data/railway_times/" if timeline else "res://data/service_starts/"
	var data=JSON.parse_string(FileAccess.get_file_as_string(directory+"catalogue.json"))
	var row: Dictionary=data.states[-1] if timeline else data.services[-1]
	var path: String=directory+row.file
	var before:=OS.get_static_memory_usage()
	var file:=FileAccess.open_compressed(path,FileAccess.READ,FileAccess.COMPRESSION_ZSTD)
	var raw_bytes:=file.get_length();var state=file.get_var(false);file.close()
	var decoded:=OS.get_static_memory_usage()
	var result:=preload("res://sim/world_snapshot.gd").restore(state)
	var restored:=OS.get_static_memory_usage()
	state=null
	var retained:=OS.get_static_memory_usage()
	var report:={id=row.id,clock=row.clock if timeline else row.start_clock,compressed_bytes=FileAccess.open(path,FileAccess.READ).get_length(),serialized_bytes=raw_bytes,
		decoded_heap_delta=decoded-before,restore_with_source_delta=restored-before,restored_heap_delta=retained-before,restore_ok=result.ok}
	var output:="res://.local/timeline-ui/memory.json" if timeline else "res://.local/service-selection/memory.json"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output.get_base_dir()))
	FileAccess.open(output,FileAccess.WRITE).store_string(JSON.stringify(report,"\t"))
	print(JSON.stringify(report));quit(0 if result.ok else 1)
