extends RefCounted
## Immersive TSW-style contexts, adapted to this game's combined traction handle.
const Shape := preload("res://game/controller_math.gd")
const Camera := preload("res://game/controller_camera.gd")
const HELP := """[b]XBOX CONTROLLER · TSW-STYLE IMMERSIVE[/b]
Driving: RT increase power · RB reduce power · LT apply brake · LB release brake.
The combined handle holds its position when released. Braking takes priority.
RS look · LS up/down zoom in cab, move camera outside.
D-pad left/right cycles all cameras backwards/forwards, without a modifier.
LS click returns to pilot · RS click selects external FREE camera.
Free camera stays in the world; LS pans, RS orbits; hold RS + LS up/down zooms.
The cycle includes cab positions, both head-outs, first/middle/last coach and exterior views.
Y stand up / sit down · A context interaction · B back.
D-pad up/down selects driving direction when change-ends is available at rest.
Tap X for Train & view actions. Hold X+A AI/manual, X+B emergency, X+RB coast, X+Y horn.
View/Back opens dispatch; hold View for service progress. Menu/Start pauses.

[b]ON FOOT[/b]
LS walk/strafe · RS look · RT run · B crouch/stand.
Y sit in a nearby seat · A use the displayed seat/doorway/gangway interaction.
D-pad up toggles your headlamp. X opens train/view actions.
Camera shortcuts stay the same on foot; LS click returns to the pilot.
The walking controls do not operate traction. The current driver/handle stays set.
Doorway and gangway prompts move you through with a brief transition.
At a stop beside a platform, A leaves through an exterior door or boards a coach.

[b]MENUS & DISPATCH[/b]
D-pad / LS navigate · A select · B cancel · LB/RB focus areas · RS scroll.
Dispatch: LS pan, LT/RT zoom, D-pad targets, A inspect, X locate, Y fit route.
View another train without giving up your service; Take control asks first.
Disconnect/focus loss pauses; release controls after reconnecting or closing UI.
Settings also offers the previous Train Game controller layout."""
static func down(pad, button: int) -> bool:
	return pad._buttons.has(button)

static func handle(pad, current: float, travel: float) -> float:
	var brake := Shape.trigger(pad._axes[4])
	var power := Shape.trigger(pad._axes[5])
	if brake>0: return maxf(-1,current-brake*travel)
	if down(pad,JOY_BUTTON_LEFT_SHOULDER): return minf(0,current+travel) if current<0 else current
	if down(pad,JOY_BUTTON_RIGHT_SHOULDER): return maxf(0,current-travel) if current>0 else current
	if power>0: return minf(1,current+power*travel)
	return current

static func reset(pad) -> void:
	pad._camera_down=false
	pad._operation_down=false
	pad._view_down=false

static func button(pad, event: InputEventJoypadButton) -> void:
	var g=pad.game
	var id:=event.button_index

	if id==JOY_BUTTON_X:
		if event.pressed:
			pad._operation_down=true;pad._operation_used=false
		elif pad._operation_down:
			pad._operation_down=false
			if not pad._operation_used: g._ui_action("controller_actions")
		return
	if id==JOY_BUTTON_BACK:
		if event.pressed: pad._view_down=true;pad._view_used=false;pad._view_time=0
		elif pad._view_down:
			pad._view_down=false
			if not pad._view_used: pad.shortcut("dispatch")
		return
	if not event.pressed: return
	if pad._operation_down:
		pad._operation_used=true
		match id:
			JOY_BUTTON_A: g.dispatcher.toggle_driver()
			JOY_BUTTON_B:
				pad.shortcut("emergency")
				if g.train.emergency: pad._rumble()
			JOY_BUTTON_RIGHT_SHOULDER: pad.shortcut("coast")
			JOY_BUTTON_Y: pad.shortcut("horn")
		return
	if g.walker.active:
		match id:
			JOY_BUTTON_A:g.walker.interact()
			JOY_BUTTON_Y:g.walker.toggle_seat()
			JOY_BUTTON_B:g.walker.toggle_crouch()
			JOY_BUTTON_DPAD_UP:g.walker.toggle_lamp()
		return
	match id:
		JOY_BUTTON_Y:g.walker.toggle_seat()
		JOY_BUTTON_A:
			if g.cam.mode==2:g.walker.toggle_seat()

		JOY_BUTTON_DPAD_UP,JOY_BUTTON_DPAD_DOWN:
			var end:=1 if id==JOY_BUTTON_DPAD_UP else 2
			if g.train.cab_end!=end:pad.shortcut("reverse")

static func process(pad, left: Vector2, right: Vector2, delta: float) -> void:
	var g=pad.game

	if pad._view_down:
		pad._view_time+=delta
		if pad._view_time>.55 and not pad._view_used:
			pad._view_used=true;g._toggle_progress()
			return
	var look: Vector2=right*pad.sensitivity
	if pad.invert_y: look.y=-look.y
	var zoom: float=-left.y if g.cam.mode!=0 or pad._camera_down else 0.0
	if g.walker.active and not pad._camera_down: zoom=0

	Camera.apply(g.cam,look,left if g.cam.mode==0 and not pad._camera_down else Vector2.ZERO,zoom,delta)

static func hint(pad) -> String:

	if pad._operation_down:return "X held · A AI/manual · B emergency brake · RB coast · Y horn"
	if pad._camera_down:return "External free · LS zoom · release RS to pan · LS click pilot"
	if pad.game.walker.active and pad.game.walker.platform.outside:return "LS walk · RS look · RT run · A board · B crouch · D-pad up lamp · LS click pilot · RS click free"
	if pad.game.walker.active:return "LS walk · RS look · RT run · B crouch · Y sit · A interact · D-pad left/right cameras · LS click pilot"
	return "RT/RB power · LT/LB brake · D-pad left/right cameras · LS click pilot · RS click free · Y stand · X actions · View map"
