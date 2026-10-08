extends RefCounted
## Immersive TSW-style contexts, adapted to this game's combined traction handle.
const Shape := preload("res://game/controller_math.gd")
const Camera := preload("res://game/controller_camera.gd")
const HELP := """[b]XBOX CONTROLLER · TSW-STYLE IMMERSIVE[/b]
Driving: RT increase power · RB reduce power · LT apply brake · LB release brake.
The combined handle holds its position when released. Braking takes priority.
RS look · LS up/down zoom in cab, move camera outside · LS click horn.
Hold LS click + D-pad left always selects left head-out, from any camera.
RS click switches cab/exterior. Hold RS for camera shift:
D-pad left cycles pilot, head-out and passenger views; right exterior; up pilot;
down middle passenger coach. LS zooms; LS click recentres.
Y stand up / sit down · A context interaction · B back.
D-pad up/down selects driving direction when change-ends is available at rest.
Tap X for Train & view actions. Hold X+A AI/manual, X+B emergency, X+RB coast.
View/Back opens dispatch; hold View for service progress. Menu/Start pauses.

[b]ON FOOT[/b]
LS walk/strafe · RS look · RT run · LS click crouch/stand.
Y sit in a nearby seat · A use the displayed seat/doorway/gangway interaction.
D-pad right toggles your headlamp. X opens train/view actions.
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
	pad._left_shift_down=false
	pad._left_shift_used=false
	pad._camera_down=false
	pad._operation_down=false
	pad._view_down=false

static func left_shift(pad, event: InputEventJoypadButton) -> bool:
	var g=pad.game
	if event.button_index==JOY_BUTTON_LEFT_STICK:
		if event.pressed:
			pad._left_shift_down=true
			pad._left_shift_used=false
			if down(pad,JOY_BUTTON_DPAD_LEFT):
				pad._left_shift_used=true
				g._head_out_camera(-1,false)
		else:
			var tapped: bool=pad._left_shift_down and not pad._left_shift_used
			pad._left_shift_down=false
			if tapped:
				if g.walker.active: g.walker.toggle_crouch()
				elif pad._camera_down: g.cam._look=Vector2.ZERO;g.cam.cab_fov=76;g.cam.follow=true
				elif pad.tsw_layout: pad.shortcut("horn")
				else: pad.shortcut("dispatch")
		return true
	if event.button_index==JOY_BUTTON_DPAD_LEFT and pad._left_shift_down:
		if event.pressed:
			pad._left_shift_used=true
			g._head_out_camera(-1,false)
		return true
	return false

static func button(pad, event: InputEventJoypadButton) -> void:
	var g=pad.game
	var id:=event.button_index
	if id==JOY_BUTTON_RIGHT_STICK:
		if event.pressed:
			pad._camera_down=true;pad._camera_used=false;pad._camera_time=0
		elif pad._camera_down:
			if not pad._camera_used and pad._camera_time<.5:
				if g.walker.active: g.cam._look=Vector2.ZERO
				else: pad.shortcut("view")
			pad._camera_down=false
		return
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
		return
	if pad._camera_down:
		pad._camera_used=true
		match id:
			JOY_BUTTON_DPAD_LEFT:
				pad._camera_index=(pad._camera_index+1)%6
				match pad._camera_index:
					0:g._pilot_camera()
					1:g._head_out_camera(-1)
					2:g._head_out_camera(1)
					_:g._passenger_preset(pad._camera_index-3)
			JOY_BUTTON_DPAD_RIGHT:
				g.cam.set_mode(0);g._set_cab_visuals(false)
			JOY_BUTTON_DPAD_UP:g._pilot_camera()
			JOY_BUTTON_DPAD_DOWN:g._passenger_preset(1)
			JOY_BUTTON_LEFT_STICK:
				g.cam._look=Vector2.ZERO
				g.cam.cab_fov=76
				g.cam.follow=true
		return
	if g.walker.active:
		match id:
			JOY_BUTTON_A:g.walker.interact()
			JOY_BUTTON_Y:g.walker.toggle_seat()
			JOY_BUTTON_LEFT_STICK:g.walker.toggle_crouch()
			JOY_BUTTON_DPAD_RIGHT:g.walker.toggle_lamp()
		return
	match id:
		JOY_BUTTON_Y:g.walker.toggle_seat()
		JOY_BUTTON_A:
			if g.cam.mode==2:g.walker.toggle_seat()
		JOY_BUTTON_LEFT_STICK:pad.shortcut("horn")
		JOY_BUTTON_DPAD_UP,JOY_BUTTON_DPAD_DOWN:
			var end:=1 if id==JOY_BUTTON_DPAD_UP else 2
			if g.train.cab_end!=end:pad.shortcut("reverse")

static func process(pad, left: Vector2, right: Vector2, delta: float) -> void:
	var g=pad.game
	if pad._camera_down: pad._camera_time+=delta
	if pad._view_down:
		pad._view_time+=delta
		if pad._view_time>.55 and not pad._view_used:
			pad._view_used=true;g._toggle_progress()
			return
	var look: Vector2=right*pad.sensitivity
	if pad.invert_y: look.y=-look.y
	var zoom: float=-left.y if g.cam.mode!=0 or pad._camera_down else 0.0
	if g.walker.active and not pad._camera_down: zoom=0
	if pad._camera_down and left.length()>.1: pad._camera_used=true
	Camera.apply(g.cam,look,left if g.cam.mode==0 and not pad._camera_down else Vector2.ZERO,zoom,delta)

static func hint(pad) -> String:
	if pad._left_shift_down:return "LS click held · D-pad left selects left head-out"
	if pad._operation_down:return "X held · A AI/manual · B emergency brake · RB coast"
	if pad._camera_down:return "RS held · D-pad left internal views · right exterior · up pilot · down passenger · LS zoom"
	if pad.game.walker.active and pad.game.walker.platform.outside:return "LS walk · RS look · RT run · A board · LS click crouch · RS held + D-pad up pilot · View map"
	if pad.game.walker.active:return "LS walk · RS look · RT run · LS click crouch · Y sit · A interact · View map · Menu pause"
	return "RT/RB power · LT/LB brake · Y stand · LS click horn · RS camera/hold views · X actions · View map · Menu pause"
