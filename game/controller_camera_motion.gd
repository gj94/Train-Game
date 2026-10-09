extends RefCounted
## Shared camera contexts for both controller layouts. Driving remains explicit.
const Shape:=preload("res://game/controller_math.gd")
static func is_free(camera) -> bool:
	return camera.mode==0 and not camera.follow
static func tick(pad, delta: float) -> void:
	if not pad._camera_down:return
	pad._camera_hold_time+=delta
	if pad._camera_hold_time<.65:return
	if is_free(pad.game.cam):
		pad._free_train_controls=not pad._free_train_controls
		pad.game.hud.toast("Free camera · triggers control "+("TRAIN · hold RS to switch to zoom" if pad._free_train_controls else "ZOOM · hold RS to switch to driving"))
		# The full neutral gate prevents a held zoom trigger becoming traction.
		pad.neutralize()
static func input(pad, left: Vector2, right: Vector2, delta: float) -> bool:
	var g=pad.game
	if pad._view_down:return false # Keep the held View/progress gesture in its router.
	if is_free(g.cam):
		var look: Vector2=right*pad.sensitivity
		if pad.invert_y:look.y=-look.y
		var zoom:=0.0
		if not pad._free_train_controls:
			zoom=Shape.trigger(pad._axes[5])-Shape.trigger(pad._axes[4])
			if g.cam.free_flight:
				g.cam.pivot.y+=(int(pad._buttons.has(JOY_BUTTON_RIGHT_SHOULDER))-int(pad._buttons.has(JOY_BUTTON_LEFT_SHOULDER)))*3.0*delta
		preload("res://game/controller_camera.gd").apply(g.cam,look,left,zoom,delta)
		return true
	if g.cam.mode==1 and left.length_squared()>.01 and not pad._camera_down and not pad._operation_down:
		# Reuse the baked cabin clearances rather than sliding through desks/walls.
		if g.walker.stand():
			pad._context="walk";pad._armed=true;g.walker.armed=true
		return true
	return false
static func hint(pad) -> String:
	return "LS move · RS look · "+("RT/LT drive" if pad._free_train_controls else "RT/LT zoom · LB/RB lower/raise")+" · hold RS switch triggers · L3 pilot"
