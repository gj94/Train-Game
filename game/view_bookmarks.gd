extends RefCounted
const Save := preload("res://game/save_load.gd")
const FILE := "user://viewpoints.cfg"
var game
var slots := {}
var previous := {}
var _last := {}
var _key := ""
func _init(owner) -> void:
	game=owner
	var config:=ConfigFile.new()
	if config.load(FILE)==OK:
		for id in ["1","2","3"]:
			var entry=config.get_value("views",id,{})
			if entry is Dictionary:slots[id]=entry
func capture() -> Dictionary:
	var session: Dictionary=game.save_load.capture_session()
	return {service=game.train.id,stock=game.train.stock_kind,camera=session.camera,view=session.view,walk=session.walk,followed=session.followed}
func observe() -> void:
	var key:="%s/%s/%s/%s/%s/%s" % [game.train.id,game.cam.mode,game.tv.passenger_coach,game.cam.head_out_side,game.tv.passenger_seat,game.walker.platform.outside]
	if not _key.is_empty() and key!=_key and not _last.is_empty():previous=_last.duplicate(true)
	_key=key;_last=capture()
func remember(id: String) -> void:
	slots[id]=capture()
	var config:=ConfigFile.new()
	for key in slots:config.set_value("views",key,slots[key])
	var error:=config.save(FILE)
	game.hud.toast("View "+id+" saved for "+game.train.id if error==OK else "Could not save viewpoint",error!=OK)
func restore(entry: Dictionary) -> bool:
	if entry.get("service","")!=game.train.id or entry.get("stock","")!=game.train.stock_kind:
		game.hud.toast("This viewpoint belongs to a different service or formation.",true);return false
	var session: Dictionary=game.save_load.capture_session()
	for key in ["camera","view","walk","followed"]:
		if not entry.has(key):game.hud.toast("Viewpoint is incomplete",true);return false
		session[key]=entry[key]
	var issue:=Save.validate_session({world=game.world,session=session})
	if not issue.is_empty():game.hud.toast("Viewpoint unavailable: "+issue,true);return false
	var before:=capture()
	game.walker.stop()
	game.save_load.restore_view(session)
	previous=before;_key="";_last={}
	game.hud.toast("Viewpoint restored · Resume when ready")
	return true
