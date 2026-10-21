extends Node
## Main thread captures; one sleeping writer serializes detached recovery/export jobs.
const Snapshot := preload("res://sim/world_snapshot.gd")
const Store := preload("res://persistence/save_store.gd")
var game
var writer
var views
var autosaves := true
var clearance_alert := true
var normal_on_clear := true
var route_strip := true
var show_signal_aspect := true
var _elapsed := 0.0
var _refresh := 0.0
var _held := {}
var route_text := ""
var last_bundle := ""
var save_directory := "user://saves"
var diagnostic_directory := "user://diagnostics"
func _ready() -> void:
	var config:=ConfigFile.new();config.load("user://journey.cfg")
	for key in ["autosaves","clearance_alert","normal_on_clear","route_strip","show_signal_aspect"]:set(key,config.get_value("options",key,get(key))==true)
	views=preload("res://game/view_bookmarks.gd").new(game)
	writer=preload("res://game/stream_worker.gd").new();writer.start(_write)
func _write(job: Dictionary) -> Dictionary:
	if job.kind=="diagnostics":return preload("res://game/diagnostic_bundle.gd").write(job)
	var store:=Store.new(job.directory)
	return store.write_slot(store.next_auto(),job.checkpoint,job.summary)
func autosave(reason: String, required: bool=false) -> bool:
	if game.get_tree().get_meta("benchmark",false) or game.world==null or (game.time_skip!=null and game.time_skip.running()):return false
	if not autosaves and not required:return false
	if required:flush()
	elif not writer.job.is_empty():return false
	var summary:=preload("res://game/save_summary.gd").capture(game,reason)
	writer.submit({kind="save",directory=save_directory,checkpoint=Snapshot.capture(game.world,game.save_load.capture_session()),summary=summary})
	_elapsed=0
	return true
func flush() -> Dictionary:
	if writer==null:return {}
	while writer.busy():OS.delay_msec(1)
	var completed: Dictionary=writer.take();_complete(completed)
	return completed.get("result",{})
func safeguard(reason: String) -> Dictionary:
	# Required transitions keep this journey alive until its verified write succeeds.
	if game.get_tree().get_meta("benchmark",false):return {ok=true,reason="",skipped=true}
	if not autosave(reason,true):return {ok=false,reason="The railway is busy; finish the current time skip before leaving."}
	var result:=flush()
	return result if not result.is_empty() else {ok=false,reason="Recovery save did not complete. Your current journey is still open."}
func _complete(completed: Dictionary) -> void:
	if completed.is_empty():return
	var result: Dictionary=completed.result
	if not result.ok:game.hud.toast(result.get("reason","Background save failed"),true);return
	if completed.job.kind=="diagnostics":
		last_bundle=ProjectSettings.globalize_path(result.path)
		game.hud.toast("Diagnostic ZIP saved locally · Journey tools → Open diagnostics folder")
	else:game.hud.toast("Recovery saved · "+completed.job.summary.clock)
func _process(delta: float) -> void:
	_complete(writer.take())
	if game.time_skip!=null and game.time_skip.running():return
	if not game.paused and not game._geographic_loading:_elapsed+=delta
	if autosaves and _elapsed>=300:autosave("Five minutes of active play")
	_refresh-=delta
	if _refresh>0:return
	_refresh=.25;views.observe()
	route_text=preload("res://game/route_ahead.gd").describe(game.world,game.train) if route_strip else ""
	var ns: Dictionary=game.world.next_signal(game.train)
	if ns.is_empty():_held.clear();return
	var red: bool=game.world.aspect(ns.id)==RailWorld.Aspect.RED
	if game.train.speed<.5 and ns.distance<250 and red:
		if _held.get("signal","")!=ns.id or _held.get("service","")!=game.train.id:
			_held={"signal":ns.id,"service":game.train.id,"reason":preload("res://sim/priority_dispatch.gd").hold_reason(game.world,game.train,true),"since":game.world.clock_seconds()}
	elif not _held.is_empty():
		if _held.service==game.train.id and _held.signal==ns.id and not red and game.world.clock_seconds()-_held.since>2:
			if clearance_alert and show_signal_aspect:
				game.hud.toast("Proceed signal at "+ns.id+" · Hold resolved"+((" · "+_held.reason.replace("Expect a wait at ","At ").replace(" until "," for ")) if not _held.reason.is_empty() else ""))
				if game.interior_sound!=null:game.interior_sound.play("clearance",.45)
			if normal_on_clear and show_signal_aspect and game.time_scale!=1:game._set_time_scale(1)
		_held.clear()
func show() -> void:
	game.controller.remember_overlay_entry("journey")
	game._set_paused(true);game.dispatcher.set_open(false)
	var options:=[["Back","pad_return:journey"],["Next-signal HUD: "+("Aspect + distance" if show_signal_aspect else "Distance only"),"journey:toggle:show_signal_aspect"]]
	for item in [["autosaves","Five-minute recovery saves"],["clearance_alert","Proceed-signal notification"],["normal_on_clear","Return to ×1 when cleared"],["route_strip","Route-ahead information"]]:
		options.append([item[1]+": "+("ON" if get(item[0]) else "OFF"),"journey:toggle:"+item[0]])
	options.append(["Save a recovery point now","journey:save"])
	options.append(["Return to previous viewpoint","journey:previous"])
	for id in ["1","2","3"]:
		options.append(["Save viewpoint "+id,"journey:remember:"+id])
		if views.slots.has(id):options.append(["Restore viewpoint "+id+" · "+str(views.slots[id].get("service","")),"journey:restore:"+id])
	options.append(["Create local diagnostic ZIP","journey:diagnostics"])
	options.append(["Open diagnostics folder","journey:folder"])
	game.save_load.show("JOURNEY TOOLS","Distance-only signal HUD hides the aspect and suppresses proceed alerts / automatic speed reset. Read the actual lineside signals.\nRecovery saves rotate through three slots every five minutes of active play, and always before a time skip or scenario change. Load them from Load journey.\nViewpoints belong to their service; restoring a passenger seat still hands driving to AI.\nDiagnostics stay on this PC until you choose to share them.",options)
	game.hud.save_menu.back_action="pad_return:journey"
func action(command: String) -> void:
	var parts:=command.split(":")
	match parts[1]:
		"toggle":
			set(parts[2],not get(parts[2]));var config:=ConfigFile.new()
			for key in ["autosaves","clearance_alert","normal_on_clear","route_strip","show_signal_aspect"]:config.set_value("options",key,get(key))
			config.save("user://journey.cfg");show()
		"save":autosave("Player recovery point",true)
		"remember":views.remember(parts[2]);show()
		"restore":views.restore(views.slots.get(parts[2],{}))
		"previous":views.restore(views.previous)
		"diagnostics":
			if not writer.job.is_empty():game.hud.toast("A save is still writing; try again in a moment");return
			writer.submit({kind="diagnostics",directory=diagnostic_directory,checkpoint=Snapshot.capture(game.world,game.save_load.capture_session()),report={build=preload("res://game/build_version.gd").current(),engine=Engine.get_version_info(),service=game.train.id,clock=game.world.clock_text(),graphics=game.graphics_options.values,audio=game.audio_options.levels}.duplicate(true)})
			game.hud.toast("Writing a local diagnostic ZIP…")
		"folder":
			DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("user://diagnostics"))
			OS.shell_open(ProjectSettings.globalize_path("user://diagnostics"))
		_:show()
func close() -> void:
	if writer!=null:flush();writer.close();writer=null
func _exit_tree() -> void:close()
