extends RefCounted
## Local-only export. The caller captures detached state before any worker starts.
static func write(job: Dictionary) -> Dictionary:
	var directory: String=job.get("directory","user://diagnostics")
	var error:=DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(directory))
	if error!=OK:return {ok=false,reason="Cannot create diagnostics folder"}
	var path:=directory.path_join("TrainGame-"+Time.get_datetime_string_from_system().replace(":","-")+"-"+str(Time.get_ticks_msec())+".zip")
	var archive:=ZIPPacker.new();error=archive.open(path)
	if error!=OK:return {ok=false,reason="Cannot create diagnostic bundle"}
	var files:={"journey.bin":var_to_bytes(job.checkpoint),"report.json":JSON.stringify(job.report,"  ").to_utf8_buffer(),"README.txt":"Local diagnostic bundle: saved railway, settings and bounded recent logs. It is not sent anywhere automatically. Logs may contain local paths. Share it only when you choose to.\n".to_utf8_buffer()}
	for name in ["audio.cfg","graphics.cfg","controller.cfg"]:
		if FileAccess.file_exists("user://"+name):files[name]=FileAccess.get_file_as_bytes("user://"+name)
	for name in ["godot.log","journey-current.jsonl","journey-previous.jsonl"]:
		var file:=FileAccess.open("user://logs/"+name,FileAccess.READ)
		if file!=null:
			file.seek(maxi(0,file.get_length()-2*1024*1024));files["logs/"+name]=file.get_buffer(file.get_length()-file.get_position());file.close()
	for name in files:
		if archive.start_file(name)!=OK or archive.write_file(files[name])!=OK or archive.close_file()!=OK:
			archive.close();return {ok=false,reason="Diagnostic ZIP write failed"}
	error=archive.close()
	return {ok=error==OK,reason="" if error==OK else "Diagnostic ZIP could not close",path=path}
