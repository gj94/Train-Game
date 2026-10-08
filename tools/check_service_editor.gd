extends SceneTree
const Editor := preload("res://game/service_editor.gd")
const Pack := preload("res://sim/service_pack.gd")
var failures := 0
var checks := 0
func _initialize() -> void:
	call_deferred("run")
func check(value: bool, message: String) -> void:
	checks+=1
	if not value:
		failures+=1
		printerr("FAIL: "+message)
func run() -> void:
	var editor := Editor.new()
	root.add_child(editor)
	editor.save_path="res://.local/editor-only-draft.json"
	var pack := Pack.defaults()
	var live := Pack.build(pack).world as RailWorld
	editor.open(live,pack)
	check(editor.rake_field.item_count==2,"WAP rake picker offers express and seated profiles")
	editor.rake_field.item_selected.emit(1)
	check(editor.draft.services[0].rake=="passenger" and Pack.build(editor.draft).world.trains.T1.length<live.trains.T1.length,"rake selection updates simulation length")
	editor.rake_field.item_selected.emit(0)
	editor.selected=2;editor._load_service()
	check(editor.rake_field.disabled and editor.rake_field.item_count==1,"Vande Bharat retains fixed car count")
	editor.selected=0;editor._load_service()
	editor._test_traffic()
	check(editor._trial!=null,"rehearsal starts on validated draft")
	var started := Time.get_ticks_msec()
	while editor._trial!=null and Time.get_ticks_msec()-started<120000: await process_frame
	check(editor._trial==null and "All 6 services arrived safely" in editor.status.text,"incremental GUI rehearsal completes")
	check(live.time==0 and live.trains.T1.odometer==0,"GUI rehearsal never moves live trains")
	check(editor._tested_json==JSON.stringify(editor.draft),"successful rehearsal belongs to exact draft")
	editor._changed()
	check(editor._tested_json.is_empty(),"editing invalidates rehearsal")
	editor._test_traffic()
	editor._test_traffic()
	check(editor._trial==null,"rehearsal cancellation")
	editor._request_play()
	check("not passed" in editor.confirm_play.dialog_text,"unrehearsed launch has clear status")
	editor.confirm_play.hide()
	editor._save_draft()
	var saved := Pack.decode(FileAccess.get_file_as_string(editor.save_path))
	check(saved.ok,"valid draft persists")
	var reloaded := Editor.new()
	root.add_child(reloaded)
	reloaded.save_path=editor.save_path
	reloaded.open(live)
	check(JSON.stringify(reloaded.draft)==JSON.stringify(saved.data),"saved draft reloads on fresh editor")
	editor.dismiss()
	reloaded.dismiss()
	editor.queue_free(); reloaded.queue_free()
	await process_frame
	print("Service editor: %d checks, %d failures" % [checks,failures])
	quit(1 if failures else 0)
