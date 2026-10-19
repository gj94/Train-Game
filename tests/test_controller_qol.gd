extends RefCounted
const Pad:=preload("res://game/controller_input.gd")
const Scheme:=preload("res://game/controller_tsw.gd")
class Hud extends RefCounted:
	var modal:="";var message:=""
	func toast(value: String,_critical:=false):message=value
	func show_modal(value: String,_labels:=false):modal=value
class Game extends RefCounted:
	var hud:=Hud.new()
	var train:={automatic=false,controller=.5,emergency=false,speed=0.0,lifecycle="active"}
	var walker:={active=false}
	var cam:={mode=1,follow=true}
	var dispatcher:={_root={visible=false}}
	var paused:=false;var labels_enabled:=false;var seated:=false
	func _passenger_seated():return seated
	func _set_paused(value: bool):paused=value
	func _ui_action(value: String):hud.modal=value
func event(id: int, pressed: bool=true) -> InputEventJoypadButton:
	var e:=InputEventJoypadButton.new();e.button_index=id;e.pressed=pressed;return e
func test_x_tap_hands_over_on_release_and_never_takes_control():
	var pad:=Pad.new();pad.game=Game.new()
	Scheme.button(pad,event(JOY_BUTTON_X))
	var before: bool=not pad.game.train.automatic
	Scheme.button(pad,event(JOY_BUTTON_X,false))
	var after: bool=pad.game.train.automatic and not pad._armed and pad.game.hud.modal==""
	Scheme.button(pad,event(JOY_BUTTON_X));Scheme.button(pad,event(JOY_BUTTON_X,false))
	var ok: bool=before and after and pad.game.train.automatic
	pad.free();return ok
func test_x_hold_takes_control_once_at_coast_and_cancels_tap():
	var pad:=Pad.new();pad.game=Game.new();pad.game.train.automatic=true;pad._armed=true
	Scheme.button(pad,event(JOY_BUTTON_X));Scheme.process(pad,Vector2.ZERO,Vector2.ZERO,.4)
	var early: bool=pad.game.train.automatic
	Scheme.process(pad,Vector2.ZERO,Vector2.ZERO,.3);Scheme.button(pad,event(JOY_BUTTON_X,false))
	var ok: bool=early and not pad.game.train.automatic and pad.game.train.controller==0 and not pad._armed
	pad.free();return ok
func test_takeover_is_blocked_on_foot_and_in_passenger_seat():
	var pad:=Pad.new();pad.game=Game.new();pad.game.train.automatic=true
	for kind in ["walking","seated","free","passenger"]:
		pad.game.walker.active=kind=="walking";pad.game.seated=kind=="seated"
		pad.game.cam.mode=0 if kind=="free" else (2 if kind=="passenger" else 1);pad.game.cam.follow=false
		Scheme.driver(pad,true)
		if not pad.game.train.automatic:pad.free();return kind+" stole control"
	pad.free();return true
func test_handover_cancels_pending_hold_and_held_triggers():
	var pad:=Pad.new();pad.game=Game.new();pad.active_device=13;pad._armed=true
	pad._axes[5]=1;Scheme.button(pad,event(JOY_BUTTON_X));pad.neutralize()
	Scheme.button(pad,event(JOY_BUTTON_X,false))
	var ok: bool=not pad.game.train.automatic and not pad._armed and not pad._operation_down
	pad.free();return ok
func test_nested_back_returns_to_caller_and_quick_actions_return_to_game():
	var pad:=Pad.new();pad.game=Game.new()
	pad.remember_menu_entry("controller_actions");pad.game.hud.modal="controller_actions"
	pad.remember_menu_entry("view_controls");pad.game.hud.modal="view_controls"
	pad.remember_menu_entry("passengers");pad.game.hud.modal="passengers"
	pad.menu_back();var ok: bool=pad.game.hud.modal=="view_controls"
	pad.menu_back();ok=ok and pad.game.hud.modal=="controller_actions"
	pad.game.paused=true;pad.menu_back();ok=ok and pad.game.hud.modal=="" and not pad.game.paused
	pad.free();return ok
func test_guide_and_settings_keep_parent_and_pause():
	var pad:=Pad.new();pad.game=Game.new();pad.game.hud.modal="pause";pad.game.paused=true
	pad.remember_menu_entry("controllers");pad.game.hud.modal="controllers"
	pad.remember_menu_entry("controller_guide");pad.game.hud.modal="controller_guide"
	pad.menu_back();var ok: bool=pad.game.hud.modal=="controllers"
	pad.remember_menu_entry("controllers");pad.menu_back()
	ok=ok and pad.game.hud.modal=="pause" and pad.game.paused
	pad.free();return ok
