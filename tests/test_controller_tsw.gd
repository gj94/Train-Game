extends RefCounted
const TSW := preload("res://game/controller_tsw.gd")

func test_tsw_bumpers_do_not_cross_coast():
	var pad={_axes=[0,0,0,0,0,0],_buttons={JOY_BUTTON_LEFT_SHOULDER:true}}
	if TSW.handle(pad,-.2,.8)!=0 or TSW.handle(pad,.4,.8)!=.4: return "LB must release brake without adding traction"
	pad._buttons={JOY_BUTTON_RIGHT_SHOULDER:true}
	return TSW.handle(pad,.2,.8)==0 and TSW.handle(pad,-.4,.8)==-.4

func test_tsw_trigger_braking_overrides_power_and_release():
	var pad={_axes=[0,0,0,0,1,1],_buttons={JOY_BUTTON_LEFT_SHOULDER:true}}
	return is_equal_approx(TSW.handle(pad,.3,.8),-.5)

func test_tsw_trigger_analog_hold_and_limits():
	var pad={_axes=[0,0,0,0,0,.53],_buttons={}}
	if not is_equal_approx(TSW.handle(pad,0,.8),.4): return "RT no longer analog"
	pad._axes[5]=0
	if TSW.handle(pad,.37,.8)!=.37: return "released controls move the handle"
	pad._axes[5]=1
	return TSW.handle(pad,.9,.8)==1
