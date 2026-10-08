extends Node
## On-foot state lives in carriage coordinates; interpolated train poses carry it.
const Navigation := preload("res://game/interior_navigation.gd")
static var _profiles: Dictionary = {}
static var _navigation := {}
var game
var active := false
var car := 0
var position := Vector2.ZERO
var crouched := false
var eye_height := 1.58
var armed := false
var nav
var exits := []
var target := {}
var _train_id := ""
var _overlay: CanvasLayer
var _prompt: Label
var _reticle: Label
var _fade: ColorRect
var _fade_time := 0.0
var _lamp: SpotLight3D
var lamp_enabled := false

func _ready() -> void:
	if _profiles.is_empty():
		_profiles=JSON.parse_string(FileAccess.get_file_as_string("res://data/interiors/walkways.json"))
	_overlay=CanvasLayer.new()
	_overlay.layer=6
	add_child(_overlay)
	_reticle=Label.new()
	_reticle.text="·"
	_reticle.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	_reticle.add_theme_font_size_override("font_size",26)
	_reticle.add_theme_constant_override("outline_size",4)
	_reticle.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	_reticle.offset_left=-12;_reticle.offset_right=12
	_reticle.offset_top=-18;_reticle.offset_bottom=18
	_reticle.mouse_filter=Control.MOUSE_FILTER_IGNORE
	_overlay.add_child(_reticle)
	_prompt=Label.new()
	_prompt.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	_prompt.offset_left=20;_prompt.offset_right=-20
	_prompt.offset_top=-110;_prompt.offset_bottom=-44
	_prompt.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	_prompt.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
	_prompt.add_theme_font_size_override("font_size",18)
	_prompt.add_theme_constant_override("outline_size",6)
	_prompt.mouse_filter=Control.MOUSE_FILTER_IGNORE
	_overlay.add_child(_prompt)
	_fade=ColorRect.new()
	_fade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_fade.color=Color(0,0,0,0)
	_fade.mouse_filter=Control.MOUSE_FILTER_IGNORE
	_overlay.add_child(_fade)
	_overlay.hide()
	_lamp=SpotLight3D.new()
	_lamp.light_energy=1.6
	_lamp.spot_range=12.0
	_lamp.spot_angle=36.0
	_lamp.shadow_enabled=false
	_lamp.position=Vector3(.12,-.10,-.06)
	_lamp.visible=false
	game.cam.add_child(_lamp)

func toggle_lamp() -> void:
	if active:
		lamp_enabled=not lamp_enabled
		_lamp.visible=lamp_enabled

func navigation(index: int):
	var key: String=game.tv.formation[index].model
	if not _navigation.has(key): _navigation[key]=Navigation.new(_profiles[key])
	return _navigation[key]

func neutralize() -> void:
	armed=false
	game._drive_keys_armed=false

func _keyboard_move() -> Vector2:
	return Vector2(float(Input.is_physical_key_pressed(KEY_D))-float(Input.is_physical_key_pressed(KEY_A)),
		float(Input.is_physical_key_pressed(KEY_S))-float(Input.is_physical_key_pressed(KEY_W))).limit_length()

func toggle_seat() -> void:
	if active:
		sit()
	else:
		stand()

func stand() -> bool:
	if game.paused or not game.hud.modal.is_empty() or game.dispatcher._root.visible: return false
	if game.cam.mode not in [1,2,3]: game._pilot_camera()
	car=game.tv.passenger_coach if game.cam.mode==2 else (game.tv.cars.size()-1 if game.train.cab_end==2 else 0)
	nav=navigation(car)
	var eye: Vector3=game.tv.cars[car].to_local(game.cam._target().origin)
	var found: Dictionary=nav.nearest(Vector2(eye.x,eye.z),false,2.5,40)
	if found.is_empty():
		game.hud.toast("No standing clearance here. Choose another seat or aisle position.")
		return false
	var facing: Vector3=game.tv.cars[car].global_basis.inverse()*(-game.cam._target().basis.z)
	position=found.point
	crouched=false
	eye_height=clampf(eye.y-nav.floor_height(position),1.0,1.58)
	_train_id=game.train.id
	active=true
	_lamp.visible=lamp_enabled
	game.cam.set_mode(4)
	game.cam._blend=1
	game.cam._look=Vector2(atan2(-facing.x,-facing.z),0)
	game.tv.walk_car=car
	game.tv.walk_eye=Vector3(position.x,nav.floor_height(position)+eye_height,position.y)
	game.tv._apply_glass()
	game.audio.set_interior(true)
	game.wv.set_labels_visible(false)
	game.dispatcher.set_open(false)
	neutralize()
	if game.controller!=null: game.controller.neutralize()
	_refresh_exits()
	return true

func stop() -> void:
	if not active: return
	active=false
	_lamp.visible=false
	target={}
	game.tv.walk_car=-1
	game.tv._apply_glass()
	_overlay.hide()
	neutralize()

func camera_transform() -> Transform3D:
	if not active: return game.tv.cab_transform()
	var t: Transform3D=game.tv.cars[car].global_transform
	return Transform3D(t.basis,t*Vector3(position.x,nav.floor_height(position)+eye_height,position.y))

func audio_position() -> Vector2:
	return Vector2(game.tv._center(car)+game.tv._direction(car)*position.y,
		maxf(.8,nav.floor_height(position)+eye_height-.5))

func toggle_crouch() -> void:
	if not active: return
	if crouched and not nav.allowed(position,false):
		game.hud.toast("Not enough headroom to stand here.")
		return
	crouched=not crouched

func update(delta: float) -> void:
	if not active: return
	if game.train.id!=_train_id or game.cam.mode!=4:
		stop()
		return
	var blocked: bool=game.paused or not game.hud.modal.is_empty() or game.dispatcher._root.visible or (game.geographic_drive and game.wv.loading)
	_overlay.visible=not blocked and not game.hud.clean_view
	if blocked:
		neutralize()
		return
	var pad: Vector2=game.controller.walk_input() if game.controller!=null else Vector2.ZERO
	var keys:=_keyboard_move()
	if not armed:
		if keys==Vector2.ZERO and pad==Vector2.ZERO: armed=true
	else:
		var input: Vector2=(keys+pad).limit_length()
		var running: bool=Input.is_physical_key_pressed(KEY_SHIFT) or (game.controller!=null and game.controller.walk_running())
		var speed: float=.65 if crouched else (2.35 if running else 1.25)
		var direction:=Basis(Vector3.UP,game.cam._look.x)*Vector3(input.x,0,input.y)
		position=nav.move(position,Vector2(direction.x,direction.z)*speed*minf(delta,.1),crouched)
	eye_height=move_toward(eye_height,.94 if crouched else 1.58,delta*3.6)
	game.tv.walk_car=car
	game.tv.walk_eye=Vector3(position.x,nav.floor_height(position)+eye_height,position.y)
	game.tv._interior_light.global_position=camera_transform().origin+Vector3.UP*.25
	game.audio.interior_listener=audio_position()
	_fade_time=maxf(0,_fade_time-delta)
	_fade.color.a=clampf(_fade_time/.22,0,1)
	target=_interaction()
	var label: String=str(game.tv.formation[car].model).to_upper().replace("_"," ")
	var control: String="Y" if game.hud.controller_active else "E"
	var interact: String="A" if game.hud.controller_active else "Left click"
	var action: String=target.get("label","Look toward a seat or an interior doorway")
	if target.get("kind","") in ["seat","driver"]: action=control+" · "+action
	elif not target.is_empty(): action=interact+" · "+action
	_prompt.text=label+" · CAR "+str(car+1)+(" · CROUCHING" if crouched else " · ON FOOT")+"\n"+action

func _refresh_exits() -> void:
	exits=nav.room_exits(position)

func _seat_target(require_facing: bool=true) -> Dictionary:
	var best:=1.65
	var found:={}
	var forward:=Basis(Vector3.UP,game.cam._look.x)*Vector3.FORWARD
	var seats: Array=game.tv.specs[car].passengers
	for i in seats.size():
		var s: Array=seats[i].position
		var delta:=Vector2(s[0],s[2])-position
		if require_facing and delta.length()>.3 and Vector2(forward.x,forward.z).dot(delta.normalized())<.25: continue
		if delta.length()<best:
			best=delta.length();found={kind="seat",seat=i,label="Sit in passenger seat"}
	var leading: int=game.tv.cars.size()-1 if game.train.cab_end==2 else 0
	if car==leading:
		var cab: Vector3=game.tv.cars[car].to_local(game.tv.cab_transform().origin)
		var d:=Vector2(cab.x,cab.z)-position
		if d.length()<1.5 and (not require_facing or d.length()<.3 or Vector2(forward.x,forward.z).dot(d.normalized())>.25):
			found={kind="driver",label="Return to driver's seat"}
	return found

func _interaction() -> Dictionary:
	var forward:=Basis(Vector3.UP,game.cam._look.x)*Vector3.FORWARD
	for entry in exits:
		var facing: Vector2=(entry.bridge.point-entry.point).normalized() if not entry.bridge.is_empty() else Vector2(0,entry.direction)
		if position.distance_to(entry.point)>1.05 or Vector2(forward.x,forward.z).dot(facing)<.45: continue
		if not entry.bridge.is_empty():
			return {kind="door",point=entry.bridge.point,label="Pass through interior doorway"}
		var reverse: int=-1 if game.tv.formation[car].reverse else 1
		var next: int=car+entry.direction*reverse
		if next<0 or next>=game.tv.cars.size(): continue
		if game.tv.formation[car].model=="wap7" or game.tv.formation[next].model=="wap7": continue
		# Do not label a short furniture alcove as the end of the carriage.
		if absf(entry.point.y)<float(game.tv.specs[car].pitch)*.5-3.0: continue
		return {kind="gangway",car=next,label="Through gangway to coach "+str(next+1)}
	return _seat_target()

func interact() -> void:
	if not active: return
	target=_interaction()
	match target.get("kind",""):
		"seat","driver": sit(target)
		"door":
			var found: Dictionary=nav.nearest(target.point,crouched,.3)
			if found.is_empty(): return
			position=found.point
			_refresh_exits()
			_fade_time=.22
		"gangway": _gangway(target.car)

func sit(selected: Dictionary = {}) -> bool:
	var seat: Dictionary=selected if not selected.is_empty() else _seat_target()
	if seat.is_empty(): seat=_seat_target(false)
	if seat.is_empty():
		game.hud.toast("Move closer to a seat to sit down.")
		return false
	stop()
	if seat.kind=="driver":
		game._pilot_camera()
	else:
		game.tv.passenger_coach=car
		game.tv.passenger_seat=true
		game.tv.passenger_seat_index=seat.seat
		game._enter_passenger()
	game.cam._blend=1
	if game.controller!=null: game.controller.neutralize()
	return true

func _gangway(next: int) -> void:
	var next_nav=navigation(next)
	var reverse: int=-1 if game.tv.formation[next].reverse else 1
	var entry_end: int=(-1 if next>car else 1)*reverse
	var found: Dictionary=next_nav.nearest(Vector2(0,entry_end*(float(game.tv.specs[next].pitch)*.5-1.0)),crouched,3.5,40)
	if found.is_empty():
		game.hud.toast("The next vestibule has no walking clearance.")
		return
	car=next;nav=next_nav;position=found.point
	game.tv.passenger_coach=car
	game.tv.walk_car=car
	game.tv._apply_glass()
	game.cam._look=Vector2(0 if entry_end>0 else PI,0)
	_refresh_exits()
	_fade_time=.22
	game.audio.reset_positions()
