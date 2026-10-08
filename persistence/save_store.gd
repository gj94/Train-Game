extends RefCounted
## Data-only files with a checksum, verified temporary write and previous backup.
const Snapshot := preload("res://sim/world_snapshot.gd")
const MAX_BYTES := 32*1024*1024
const MAGIC := "TRAINGAME-SAVE-1\n"
const SLOTS := ["quick","1","2","3","4","5"]
var directory := "user://saves"

func _init(root: String="user://saves") -> void:
	directory=root

func path(slot: String, backup: bool=false) -> String:
	return directory.path_join("save-"+slot+".tgs"+(".bak" if backup else "")) if slot in SLOTS else ""

func read_slot(slot: String, backup: bool=false) -> Dictionary:
	if slot not in SLOTS:return Snapshot.error("Unknown save slot")
	return read_file(path(slot,backup))

func read_file(file_path: String) -> Dictionary:
	var f:=FileAccess.open(file_path,FileAccess.READ)
	if f==null:return Snapshot.error("No readable save in this slot")
	if f.get_length()>MAX_BYTES or f.get_length()<MAGIC.length()+65:return Snapshot.error("Save is incomplete or too large")
	if f.get_line()+"\n"!=MAGIC:return Snapshot.error("Unrecognised save file")
	var expected:=f.get_line()
	var bytes:=f.get_buffer(f.get_length()-f.get_position());f.close()
	var hash:=HashingContext.new();hash.start(HashingContext.HASH_SHA256);hash.update(bytes)
	if expected!=hash.finish().hex_encode():return Snapshot.error("Save checksum failed; try the previous backup")
	# Object decoding is disabled: a save can never instantiate scripts/resources.
	var data=bytes_to_var(bytes)
	if not data is Dictionary or not data.get("checkpoint") is Dictionary or not data.get("summary") is Dictionary:return Snapshot.error("Invalid save contents")
	return {ok=true,reason="",data=data}

func write_slot(slot: String, checkpoint: Dictionary, summary: Dictionary) -> Dictionary:
	if slot not in SLOTS:return Snapshot.error("Unknown save slot")
	var err:=DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(directory))
	if err!=OK:return Snapshot.error("Cannot create the saves folder: "+error_string(err))
	var bytes:=var_to_bytes({checkpoint=checkpoint,summary=summary})
	if bytes.size()>MAX_BYTES-128:return Snapshot.error("Save exceeds the file size limit")
	var hash:=HashingContext.new();hash.start(HashingContext.HASH_SHA256);hash.update(bytes)
	var target:=path(slot);var temp:=target+".tmp"
	var f:=FileAccess.open(temp,FileAccess.WRITE)
	if f==null:return Snapshot.error("Cannot write the save: "+error_string(FileAccess.get_open_error()))
	f.store_string(MAGIC+hash.finish().hex_encode()+"\n");f.store_buffer(bytes);f.flush()
	err=f.get_error();f.close()
	if err!=OK or not read_file(temp).ok:return Snapshot.error("Save could not be verified; previous save retained")
	# Never rotate a corrupt primary over the recoverable backup.
	if FileAccess.file_exists(target) and read_file(target).ok:
		err=DirAccess.copy_absolute(target,path(slot,true))
		if err!=OK:return Snapshot.error("Cannot keep the previous save; existing slot retained")
	err=DirAccess.rename_absolute(temp,target)
	if err!=OK:return Snapshot.error("Cannot replace this slot: "+error_string(err)+". Previous save retained")
	return {ok=true,reason="",path=target}

func slots() -> Array:
	var result:=[]
	for slot in SLOTS:
		var saved:=read_slot(slot);var backup:=read_slot(slot,true)
		result.append({id=slot,exists=FileAccess.file_exists(path(slot)),ok=saved.ok,reason=saved.reason,
			summary=saved.data.summary if saved.ok else {},backup=backup.ok})
	return result
