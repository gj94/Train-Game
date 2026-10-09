extends RefCounted
## Controller camera movement uses elapsed real time, independent of train speed.

static func presets(g) -> Array[String]:
	var result: Array[String]=["pilot","head_right"]
	if g.tv.has_method("cycle_cab_position"):
		var car: int=g.tv.cars.size()-1 if g.train.cab_end==2 else 0
		if g.tv.formation[car].model=="wap7" and g.tv.specs[car].get("detailed_materials",false):
			result.append_array(["cab_1","cab_2","cab_3"])
	if g._has_passengers():
		var coaches: Array=g.tv.passenger_coaches()
		var seen:=[]
		for preset in 3:
			var index: int=0 if preset==0 else ((coaches.size()-1)/2 if preset==1 else coaches.size()-1)
			if index<0 or index in seen:continue
			seen.append(index);result.append("passenger_"+str(preset))
	result.append_array(["follow","free","head_left"])
	return result

static func current(g) -> String:
	match g.cam.mode:
		0: return "follow" if g.cam.follow else "free"
		1:
			var seat: int=g.tv.cab_position if g.tv.has_method("cycle_cab_position") else 0
			return "pilot" if seat==0 else "cab_"+str(seat)
		3: return "head_left" if g.cam.head_out_side<0 else "head_right"
		2:
			var coaches: Array=g.tv.passenger_coaches()
			if coaches.is_empty(): return "pilot"
			var index: int=coaches.find(g.tv.passenger_coach)
			var middle: int=(coaches.size()-1)/2
			if index==0:return "passenger_0"
			if index==coaches.size()-1:return "passenger_2"
			return "passenger_1" if absi(index-middle)<=mini(index,coaches.size()-1-index) else ("passenger_0" if index<middle else "passenger_2")
	return "pilot"

static func select(g, preset: String) -> void:
	if preset=="free":
		free_platform(g)
		return
	if preset=="pilot" or preset.begins_with("cab_"):
		g._pilot_camera()
		if preset.begins_with("cab_"): g.tv.cab_position=int(preset.trim_prefix("cab_"))
	elif preset=="head_left" or preset=="head_right":
		g._head_out_camera(-1 if preset=="head_left" else 1,false)
	elif preset.begins_with("passenger_"):
		g._passenger_preset(int(preset.trim_prefix("passenger_")))
	else:
		if g.cam.mode!=0:
			g.cam.pivot=g.cam._target().origin
			g.cam.distance=clampf(g.cam.distance,12,90)
		g.cam.set_mode(0)
		g.cam.follow=preset=="follow"
		g.cam._follow_anchor_valid=false
		if g.cam.follow:
			g.traffic_presentation.followed_service=""
			g.cam.follow_point=g.tv.overview_position
		g._set_cab_visuals(false)
		g.dispatcher.set_open(false)

static func free_platform(g) -> void:
	if g.cam.mode==0 and g.cam.free_flight:return
	var origin: Vector3=g.wv.coordinate_origin if g.geographic_drive else Vector3.ZERO
	var observer: Vector3=g.cam._target().origin+origin
	var spot:=preload("res://game/platform_camera.gd").nearest(g.world,observer)
	var eye: Vector3=spot.get("eye",observer)-origin
	var forward: Vector3=spot.get("forward",-g.cam.global_basis.z)
	g.cam.enter_free(eye,forward)
	g.traffic_presentation.followed_service=""
	g._set_cab_visuals(false);g.dispatcher.set_open(false)
	if g.controller!=null:g.controller._free_train_controls=false
	g.audio.reset_positions()

static func step_coach(g, direction: int) -> void:
	if not g._has_passengers():select(g,"pilot");return
	var coaches: Array=g.tv.passenger_coaches()
	var index: int=coaches.find(g.tv.passenger_coach) if g.cam.mode==2 else -1
	if g.walker.active:index=coaches.find(g.walker.car)
	var next:=clampi(index+direction,-1,coaches.size()-1)
	if next<0:select(g,"pilot");return
	g.tv.passenger_coach=coaches[next];g.tv.passenger_bay=0
	g.tv.passenger_seat_index=-1;g.tv.passenger_seat=false
	g.cam._look=Vector2.ZERO;g._enter_passenger();g.audio.reset_positions()

static func button(pad, event: InputEventJoypadButton) -> bool:
	var id:=event.button_index
	if id not in [JOY_BUTTON_LEFT_STICK,JOY_BUTTON_RIGHT_STICK,JOY_BUTTON_DPAD_LEFT,JOY_BUTTON_DPAD_RIGHT,JOY_BUTTON_DPAD_UP,JOY_BUTTON_DPAD_DOWN]:return false
	if pad._operation_down:return false
	if id==JOY_BUTTON_RIGHT_STICK:
		pad._camera_down=event.pressed;pad._camera_hold_time=0
	if not event.pressed:return true
	var g=pad.game
	var walking: bool=g.walker.active
	var was_free: bool=g.cam.mode==0 and not g.cam.follow
	if id==JOY_BUTTON_LEFT_STICK:
		pad._camera_down=false
		select(g,"pilot")
	elif id==JOY_BUTTON_RIGHT_STICK:select(g,"free")
	elif id in [JOY_BUTTON_DPAD_UP,JOY_BUTTON_DPAD_DOWN]:
		step_coach(g,-1 if id==JOY_BUTTON_DPAD_UP else 1)
	else:
		pad._camera_down=false
		var choices:=presets(g)
		var next:=posmod(choices.find(current(g))+(-1 if id==JOY_BUTTON_DPAD_LEFT else 1),choices.size())
		select(g,choices[next])
	if walking or (was_free and (g.cam.mode!=0 or g.cam.follow)):pad.neutralize()
	return true


static func apply(camera, look: Vector2, pan: Vector2, zoom: float, delta: float) -> void:
	if camera.mode == 0 and camera.free_flight:
		camera.yaw-=look.x*2.2*delta
		camera.pitch=clampf(camera.pitch-look.y*1.6*delta,-1.45,1.45)
		camera.free_fov=clampf(camera.free_fov-zoom*38*delta,18,85)
		var basis:=Basis.from_euler(Vector3(camera.pitch,camera.yaw,0))
		camera.pivot+=(basis.x*pan.x+basis.z*pan.y)*8.0*delta
	elif camera.mode == 0:
		camera.yaw -= look.x * 2.2 * delta
		camera.pitch = clampf(camera.pitch-look.y*1.6*delta,-1.5,-.05)
		camera.distance = clampf(camera.distance*exp(-zoom*1.2*delta),3,3000)
		if pan.length_squared() > 0:
			camera.follow = false
			var right: Vector3 = camera.global_basis.x
			var forward := Vector3(-camera.global_basis.z.x,0,-camera.global_basis.z.z).normalized()
			camera.pivot += (right*pan.x-forward*pan.y)*clampf(camera.distance*.65,2,1500)*delta
	else:
		camera._look.x = wrapf(camera._look.x-look.x*2.2*delta,-PI,PI) if camera.mode==4 else clampf(camera._look.x-look.x*2.2*delta,-camera.cab_yaw_limit,camera.cab_yaw_limit)
		camera._look.y = clampf(camera._look.y-look.y*1.6*delta,-.95,.85)
		camera.cab_fov = clampf(camera.cab_fov-zoom*32*delta,38,82)
