extends RefCounted
const Pad := preload("res://game/controller_math.gd")

func test_stick_drift_is_silent_and_diagonal_is_bounded():
	if Pad.stick(Vector2(.05,-.07),.18) != Vector2.ZERO: return "Drift moves the camera"
	if Pad.stick(Vector2.ZERO,.18) != Vector2.ZERO: return "Zero stick is not neutral"
	if absf(Pad.stick(Vector2.ONE,.18).length()-1) > .000001: return "Diagonal exceeds unit speed"
	return Pad.stick(Vector2(.59,0),.18).is_equal_approx(Vector2(.5,0))

func test_trigger_brake_priority_and_analog_range():
	if Pad.handle(1,1) != -1: return "Power overrides simultaneous braking"
	if Pad.handle(.05,.05) != 0: return "Trigger drift changes the handle"
	if absf(Pad.handle(.53,0)-.5) > .000001: return "Partial power is not analog"
	if absf(Pad.handle(1,.53)+.5) > .000001: return "Partial brake loses priority"
	return Pad.handle(2,-1) == 1 and Pad.handle(-1,2) == -1

func test_menu_stick_uses_one_direction_and_requires_deliberate_deflection():
	if Pad.cardinal(Vector2(.3,.3)) != Vector2i.ZERO: return "Menu drift moves focus"
	return Pad.cardinal(Vector2(.9,-.8)) == Vector2i.RIGHT and Pad.cardinal(Vector2(.1,-1)) == Vector2i.UP
