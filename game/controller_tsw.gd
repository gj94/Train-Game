extends RefCounted
## Context controls. Tap actions run on release; holds never fire a tap first.
const Shape := preload("res://game/controller_math.gd")
const Camera := preload("res://game/controller_camera.gd")
const HOLD := .65
const COAST_PAUSE := .24
const HELP := """[b]XBOX · DRIVING[/b]
RT increase handle · LT decrease handle. Release to hold; a short detent pauses at coast.
B horn · A interact · Y stand (AI takes over).
Tap X gives driving to AI; hold X takes manual control at coast. Sit at the controls first.
Right/left D-pad starts with the matching head-out, then cycles following exterior views.
Hold left/right D-pad to return to pilot; exterior views keep your current driver.
Up/down D-pad moves one carriage toward loco/tail, standing with AI driving.
Hold up/down to return to the loco standing. Y takes the nearby driver's seat.
RB reduces power to coast · LB releases brake to coast; neither crosses into the opposite range.
RS look · R3 recenter · LS adjusts following camera distance/angle.

[b]WALKING & PASSENGERS[/b]
LS walk · L3 toggle run · RS look · A interact or sit · RB torch.
Y stands from a seat, or sits at nearby driving controls. AI stays in control until hold X.
In a passenger seat, left/right D-pad cycles the same row's head-outs and interior.
At a stopped platform, A at a doorway boards/alights. Moving between WAP and coaches uses D-pad.

[b]MENUS[/b]
View tap: dispatch · View hold: progress · Menu: pause, save/load, settings and actions.
A confirm · B back · D-pad/LS navigate · RS scroll · LB/RB focus areas.
Dispatch: LS pan, LT/RT zoom, A inspect, X locate, Y fit, View timetable.
Emergency brake remains in Train & view actions and on keyboard Space.
Release controls after a menu, handover or reconnect before operating again."""

static func down(pad, button: int) -> bool:
	return pad._buttons.has(button)

static func direction(pad, current: float) -> float:
	# Bumpers only relax the matching range. They never cross coast, add
	# traction/braking or let a held trigger undo a reduction simultaneously.
	if down(pad,JOY_BUTTON_RIGHT_SHOULDER) or down(pad,JOY_BUTTON_LEFT_SHOULDER):
		if current>0 and down(pad,JOY_BUTTON_RIGHT_SHOULDER):return -1.0
		if current<0 and down(pad,JOY_BUTTON_LEFT_SHOULDER):return 1.0
		return 0.0
	return Shape.handle(pad._axes[5],pad._axes[4])

static func handle(pad, current: float, travel: float) -> float:
	var direction := direction(pad,current)
	if down(pad,JOY_BUTTON_RIGHT_SHOULDER) or down(pad,JOY_BUTTON_LEFT_SHOULDER):
		return move_toward(current,0.0,travel) if direction!=0 else current
	if direction==0:return current
	if current==0 and pad._coast_direction==signf(direction) and pad._coast_time<COAST_PAUSE:return 0
	var target:=clampf(current+direction*travel,-1,1)
	if current!=0 and signf(current)!=signf(target):
		pad._coast_direction=signf(direction);pad._coast_time=0
		pad.coast_tick()
		return 0
	return target

static func reset(pad) -> void:
	pad._camera_down=false;pad._camera_hold_time=0
	pad._operation_down=false;pad._operation_time=0
	pad._view_down=false;pad._dpad_button=-1;pad._dpad_time=0
	pad._coast_direction=0;pad._coast_time=0;pad._running=false

static func driver(pad, manual: bool) -> void:
	var g=pad.game
	if manual:
		if g.walker.active or g._passenger_seated() or g.cam.mode==2 or (g.cam.mode==0 and not g.cam.follow):
			g.hud.toast("Return to the pilot seat before taking control");return
		if g.train.lifecycle!="active":return
		g.train.controller=0.0
		g.train.automatic=false
		g.hud.toast("You are driving · handle at coast")
	else:
		g.train.automatic=true
		g.hud.toast("AI driving · hold X from the pilot or following camera to take over")
	pad.neutralize()

static func button(pad, event: InputEventJoypadButton) -> void:
	var g=pad.game
	var id:=event.button_index
	if id==JOY_BUTTON_X:
		if event.pressed:
			pad._operation_down=true;pad._operation_used=false;pad._operation_time=0
		elif pad._operation_down:
			var used: bool=pad._operation_used
			pad._operation_down=false
			if not used:driver(pad,false)
		return
	if id==JOY_BUTTON_BACK:
		if event.pressed:pad._view_down=true;pad._view_used=false;pad._view_time=0
		elif pad._view_down:
			pad._view_down=false
			if not pad._view_used:pad.shortcut("dispatch")
		return
	if not event.pressed or pad._operation_down or pad._dpad_button!=-1:return
	match id:
		JOY_BUTTON_A:
			if g.walker.active:g.walker.interact()
			elif g.cam.mode==2:g.walker.toggle_seat()
		JOY_BUTTON_B:
			if not g.walker.active and not g._passenger_seated() and g.cam.mode!=2 and not (g.cam.mode==0 and not g.cam.follow):pad.shortcut("horn")
		JOY_BUTTON_Y:
			if not g.walker.active:g.walker.stand()
			else:
				var seat: Dictionary=g.walker._seat_target(false) if not g.walker.platform.outside else {}
				if seat.get("kind","")=="driver":g.walker.sit(seat)
				else:g.hud.toast("A sits in a passenger seat · hold D-pad up/down to return to the loco")
		JOY_BUTTON_RIGHT_SHOULDER:
			if g.walker.active:g.walker.toggle_lamp()


static func process(pad, left: Vector2, right: Vector2, delta: float) -> void:
	var g=pad.game
	if Shape.handle(pad._axes[5],pad._axes[4])==0:pad._coast_direction=0
	else:pad._coast_time+=delta
	if pad._operation_down:
		pad._operation_time+=delta
		if pad._operation_time>=HOLD and not pad._operation_used:
			pad._operation_used=true;driver(pad,true)
		return
	if pad._dpad_button!=-1:
		Camera.hold(pad,delta)
		return
	if pad._view_down:
		pad._view_time+=delta
		if pad._view_time>=HOLD and not pad._view_used:
			pad._view_used=true;g._toggle_progress()
		return
	var look: Vector2=right*pad.sensitivity
	if pad.invert_y:look.y=-look.y
	if g.cam.mode==0 and not g.cam.follow:
		Camera.apply(g.cam,look,left,Shape.trigger(pad._axes[5])-Shape.trigger(pad._axes[4]),delta)
	elif g.cam.mode==0:
		# Following cameras stay attached while the stick adjusts the composition.
		look.x+=left.x*.6
		Camera.apply(g.cam,look,Vector2.ZERO,-left.y,delta)
	else:Camera.apply(g.cam,look,Vector2.ZERO,0,delta)

static func hint(pad) -> String:
	if pad.game._passenger_seated():return "AI driving · D-pad left/right row head-outs · Y stand · A interact · hold Up/Down loco"
	if pad.game.walker.active:return "AI driving · LS walk · L3 run · RS look · A interact/sit · Y driver seat · RB torch · hold Up/Down loco"
	return "RT/LT handle · B horn · Y stand · X AI / hold X manual · D-pad cameras / hold Left/Right pilot · RB power down / LB brake release · Menu controls"
