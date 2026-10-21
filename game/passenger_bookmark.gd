extends RefCounted
## Viewpoint-only bookmarks. They never alter passenger counts or railway state.
var game
var seats := {}

func _init(owner) -> void:
	game=owner

func capture() -> Dictionary:
	if not game._passenger_seated():return {}
	var view=game.tv
	var car: int=view.passenger_coach
	var entries: Array=view.specs[car].passengers
	if entries.is_empty():return {}
	var seat: int=view.passenger_seat_index
	if seat<0:seat=mini(view.passenger_bay*maxi(1,entries.size()/9),entries.size()-1)
	return {service=game.train.id,car=car,seat=seat,model=str(view.formation[car].model),look=game.cam._look}

func remember(notify: bool=false) -> bool:
	var point:=capture()
	if point.is_empty():
		if notify:game.hud.toast("Sit in a passenger seat to remember it")
		return false
	seats[game.train.id]=point
	if notify:game.hud.toast("Seat remembered · "+label(point)+" · hold R3 to return")
	return true

func valid(point: Dictionary) -> bool:
	if point.get("service","")!=game.train.id or game.train.lifecycle!="active" or not game._has_passengers():return false
	if typeof(point.get("car"))!=TYPE_INT or typeof(point.get("seat"))!=TYPE_INT:return false
	var car: int=point.car
	if car<0 or car>=game.tv.formation.size() or car>=game.tv.specs.size():return false
	return point.get("model","")==str(game.tv.formation[car].model) and point.seat>=0 and point.seat<game.tv.specs[car].passengers.size()

func current() -> Dictionary:
	var point: Dictionary=seats.get(game.train.id,{})
	return point.duplicate(true) if valid(point) else {}

func restore(point: Dictionary={}, notify: bool=true) -> bool:
	if point.is_empty():point=current()
	if not valid(point) or preload("res://sim/depot_workings.gd").finished(game.world,game.train):
		if notify:game.hud.toast("No available passenger seat saved for this service")
		return false
	game.walker.stop()
	game.traffic_presentation.followed_service=""
	game.train.automatic=true
	game.tv.passenger_coach=point.car;game.tv.passenger_seat_index=point.seat;game.tv.passenger_seat=true
	game._enter_passenger()
	game.cam._look=point.get("look",Vector2.ZERO) if typeof(point.get("look",Vector2.ZERO))==TYPE_VECTOR2 else Vector2.ZERO
	game.cam._blend=1;game.cam._follow_anchor_valid=false
	game.cam.global_transform=game.cam._target()
	remember()
	game.audio.reset_positions();game.controller.neutralize();game._drive_keys_armed=false
	if notify:game.hud.toast("Back in "+label(point)+" · AI driving")
	return true

func hold_shortcut() -> void:
	if game._passenger_seated():remember(true)
	else:restore()

static func label(point: Dictionary) -> String:
	return preload("res://game/coach_directory.gd").name(str(point.get("model","")),int(point.get("car",0)))+" · seat %d" % (int(point.get("seat",0))+1)

func load_saved(data: Variant) -> void:
	seats.clear()
	if not data is Dictionary:return
	for id in data:
		if id is String and data[id] is Dictionary and data[id].get("service","")==id:seats[id]=data[id].duplicate(true)
