extends RefCounted
## Train-attached view cycle and disjoint tap/hold gestures.
const FOLLOW := ["head_right","follow_close","follow_far","follow_tail","head_left"]
static func presets(_g) -> Array:
	return FOLLOW.duplicate()
static func current(g) -> String:
	if g.cam.mode==0:return g.cam.follow_preset if g.cam.follow else "free"
	if g.cam.mode==3:return "head_left" if g.cam.head_out_side<0 else "head_right"
	return "pilot"
static func select(g, preset: String) -> void:
	if preset=="free":free_platform(g);return
	if preset=="pilot":
		g._pilot_camera();return
	if preset in ["head_left","head_right"]:
		if g.cam.mode==2 or g.walker.active:g._pilot_camera()
		g._head_out_camera(-1 if preset=="head_left" else 1,false)
		return
	if g.walker.active:g.walker.stop()
	g.cam.set_mode(0);g.cam.follow=true;g.cam._follow_anchor_valid=false
	g.cam.follow_preset=preset
	g.cam.distance=55 if preset=="follow_far" else (23 if preset=="follow_tail" else 16)
	g.cam.pitch=-.23
	g.cam.yaw=.65
	g.traffic_presentation.followed_service=""
	anchor(g)
	g._set_cab_visuals(false);g.dispatcher.set_open(false)

static func anchor(g) -> void:
	if g.cam.follow_preset=="follow_tail":
		var view=g.tv
		g.cam.follow_point=func():return view.cars[0 if view.train.cab_end==2 else view.cars.size()-1].global_position+Vector3.UP*2
	else:g.cam.follow_point=g.tv.overview_position

static func free_platform(g) -> void:
	if g.cam.mode==0 and g.cam.free_flight:return
	var origin: Vector3=g.wv.coordinate_origin if g.geographic_drive else Vector3.ZERO
	var observer: Vector3=g.cam._target().origin+origin
	var spot:=preload("res://game/platform_camera.gd").nearest(g.world,observer)
	var eye: Vector3=spot.get("eye",observer)-origin
	var forward: Vector3=spot.get("forward",-g.cam.global_basis.z)
	g.train.automatic=true
	g.cam.enter_free(eye,forward)
	g.traffic_presentation.followed_service=""
	g._set_cab_visuals(false);g.dispatcher.set_open(false)
	g.audio.reset_positions()

static func standing_loco(g) -> void:
	g._pilot_camera()
	g.walker.stand()

static func step_coach(g, direction: int) -> void:
	if not g._has_passengers():standing_loco(g);return
	var coaches: Array=g.tv.passenger_coaches()
	# The view already supplies coaches ordered from the driving end.
	var index: int=coaches.find(g.tv.passenger_coach) if g.cam.mode==2 or g._passenger_head_out() else -1
	if g.walker.active:index=coaches.find(g.walker.car)
	var next:=clampi(index+direction,-1,coaches.size()-1)
	if next<0:standing_loco(g);return
	g.train.automatic=true
	g.tv.passenger_coach=coaches[next];g.tv.passenger_bay=0
	g.tv.passenger_seat_index=-1;g.tv.passenger_seat=false
	g.cam._look=Vector2.ZERO;g._enter_passenger()
	g.walker.stand();g.audio.reset_positions()

static func hold(pad, delta: float) -> void:
	pad._dpad_time+=delta
	if pad._dpad_time<.65 or pad._dpad_used:return
	pad._dpad_used=true
	if pad._dpad_button in [JOY_BUTTON_DPAD_LEFT,JOY_BUTTON_DPAD_RIGHT]:select(pad.game,"pilot")
	else:standing_loco(pad.game)
	# Context changes and held triggers must not leak after teleporting.
	pad.neutralize()

static func button(pad, event: InputEventJoypadButton) -> bool:
	var id:=event.button_index
	if id not in [JOY_BUTTON_LEFT_STICK,JOY_BUTTON_RIGHT_STICK,JOY_BUTTON_DPAD_LEFT,JOY_BUTTON_DPAD_RIGHT,JOY_BUTTON_DPAD_UP,JOY_BUTTON_DPAD_DOWN]:return false
	if pad._operation_down:return true
	if pad._seat_hold_down and id!=JOY_BUTTON_RIGHT_STICK:return true
	var g=pad.game
	if id==JOY_BUTTON_LEFT_STICK:
		if event.pressed and g.walker.active:pad._running=not pad._running
		return true
	if id==JOY_BUTTON_RIGHT_STICK:
		if event.pressed:
			pad._seat_hold_down=true;pad._seat_hold_used=false;pad._seat_hold_time=0
		elif pad._seat_hold_down:
			pad._seat_hold_down=false
			if not pad._seat_hold_used:
				g.cam._look=Vector2.ZERO
				if g.cam.mode==0:g.cam.yaw=.65;g.cam.pitch=-.23
		return true
	if event.pressed:
		if pad._dpad_button==-1:
			pad._dpad_button=id;pad._dpad_time=0;pad._dpad_used=false
		return true
	if pad._dpad_button!=id:return true
	var used: bool=pad._dpad_used
	pad._dpad_button=-1
	if used:return true
	if id in [JOY_BUTTON_DPAD_UP,JOY_BUTTON_DPAD_DOWN]:
		step_coach(g,-1 if id==JOY_BUTTON_DPAD_UP else 1)
		return true
	var direction: int=-1 if id==JOY_BUTTON_DPAD_LEFT else 1
	if g._passenger_seated():
		var side: int=g.cam.head_out_side if g._passenger_head_out() else 0
		var next: int=posmod(side+direction+1,3)-1
		if next==0:g._enter_passenger()
		else:g._head_out_camera(next,false)
	elif not g.walker.active:
		var index: int=FOLLOW.find(current(g))
		select(g,("head_left" if direction<0 else "head_right") if index<0 else FOLLOW[posmod(index+direction,FOLLOW.size())])
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
		camera.distance = clampf(camera.distance*exp(-zoom*1.2*delta),3,preload("res://game/railway_render_budget.gd").ORBIT_DISTANCE)
		if not camera.follow and pan.length_squared()>0:
			camera.pivot+=(camera.global_basis.x*pan.x+camera.global_basis.z*pan.y)*camera.distance*.65*delta
	else:
		camera._look.x = wrapf(camera._look.x-look.x*2.2*delta,-PI,PI) if camera.mode==4 else clampf(camera._look.x-look.x*2.2*delta,-camera.cab_yaw_limit,camera.cab_yaw_limit)
		camera._look.y = clampf(camera._look.y-look.y*1.6*delta,-.95,.85)
		camera.cab_fov = clampf(camera.cab_fov-zoom*32*delta,38,82)
