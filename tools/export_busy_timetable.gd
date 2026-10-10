extends SceneTree
## Export current built-in through services for the existing F5 import format.
func _init() -> void:
	var output := ".local/kerala-coast-100-through-services.json"
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--output="):output=arg.trim_prefix("--output=")
	var pack: Dictionary=preload("res://sim/service_pack.gd").defaults("kerala_coast",true)
	pack.name="Kerala Coast · 100 through and regional services"
	var encoded:=JSON.stringify(pack,"\t")
	var decoded: Dictionary=preload("res://sim/service_pack.gd").decode(encoded)
	if not decoded.ok:
		printerr(decoded.reason);quit(1);return
	var file:=FileAccess.open(output,FileAccess.WRITE)
	if file==null:
		printerr("Cannot write "+output);quit(1);return
	file.store_string(encoded+"\n")
	file.close()
	print("Exported and import-validated %d services to %s (%d bytes)" % [pack.services.size(),output,encoded.to_utf8_buffer().size()])
	quit(0)
