extends RefCounted
const Pad := preload("res://game/controller_input.gd")
const Scheme := preload("res://game/controller_tsw.gd")
func test_handle_stops_at_coast_from_both_sides_then_crosses_after_detent():
	var pad:=Pad.new()
	pad._axes[4]=1
	var first:=Scheme.handle(pad,.2,.8)
	var held:=Scheme.handle(pad,first,.8)
	pad._coast_time=.25
	var crossed:=Scheme.handle(pad,held,.3)
	pad._axes[4]=0;pad._axes[5]=1
	var reverse:=Scheme.handle(pad,-.2,.8)
	var ok:=first==0 and held==0 and crossed<0 and reverse==0
	pad.free();return ok
func test_coast_release_and_repull_bypasses_wait_and_brake_wins():
	var pad:=Pad.new()
	pad._axes[4]=1;pad._axes[5]=1
	var first:=Scheme.handle(pad,.2,.8)
	pad._coast_direction=0 # Router observes trigger neutral even between render frames.
	var second:=Scheme.handle(pad,first,.3)
	var ok:=first==0 and second<0
	pad.free();return ok
func test_handle_is_analog_holds_on_release_and_bumpers_never_drive():
	var pad:=Pad.new();pad._axes[5]=.53
	var partial:=Scheme.handle(pad,0,.8)
	pad._axes[5]=0;pad._buttons={JOY_BUTTON_LEFT_SHOULDER:true,JOY_BUTTON_RIGHT_SHOULDER:true}
	var hold:=Scheme.handle(pad,.37,.8)
	pad._axes[5]=1
	var limit:=Scheme.handle(pad,.9,.8)
	pad.free();return is_equal_approx(partial,.4) and hold==.37 and limit==1
