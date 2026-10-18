extends RefCounted
const Pad:=preload("res://game/controller_input.gd")
const TSW:=preload("res://game/controller_tsw.gd")

class Hud extends RefCounted:
	var modal:=""
	var message:=""
	func toast(value: String,_critical:=false):message=value
	func show_modal(value: String,_labels:=false):modal=value

class Game extends RefCounted:
	var hud:=Hud.new()
	var train:={automatic=true,controller=.5,emergency=false,speed=0.0}
	var walker:={active=false}
	var dispatcher:={_root={visible=false}}
	var paused:=false
	var labels_enabled:=false
	var seated:=false
	var keys:=[]
	func _passenger_seated():return seated
	func _set_paused(value: bool):paused=value
	func _ui_action(value: String):hud.modal=value
	func _unhandled_input(event):
		keys.append(event.physical_keycode)
		if seated:return
		if event.physical_keycode==KEY_A:train.automatic=not train.automatic;train.controller=0.0

func event(id: int, pressed: bool=true) -> InputEventJoypadButton:
	var e:=InputEventJoypadButton.new();e.button_index=id;e.pressed=pressed;return e

func test_ai_chord_uses_guarded_input_and_announces_handover():
	var pad:=Pad.new();pad.game=Game.new();pad._armed=true
	TSW.button(pad,event(JOY_BUTTON_X));TSW.button(pad,event(JOY_BUTTON_A))
	var ok: bool=pad.game.keys==[KEY_A] and not pad.game.train.automatic and "You are driving" in pad.game.hud.message
	pad.game.seated=true;pad.game.train.automatic=true
	TSW.button(pad,event(JOY_BUTTON_A))
	ok=ok and pad.game.train.automatic and pad.game.keys.size()==2
	pad.free();return ok

func test_modifier_blocks_walking_and_release_rearms_held_trigger():
	var pad:=Pad.new();pad.game=Game.new();pad.active_device=13;pad._armed=true
	pad._axes[0]=1;pad._axes[5]=1
	var walking: bool=pad.walk_input().length()>.9
	TSW.button(pad,event(JOY_BUTTON_X))
	var blocked: bool=pad.walk_input()==Vector2.ZERO
	TSW.button(pad,event(JOY_BUTTON_A));TSW.button(pad,event(JOY_BUTTON_X,false))
	var ok: bool=walking and blocked and not pad._armed and not pad._operation_down and pad.game.hud.modal==""
	pad.free();return ok

func test_unmodified_x_opens_actions_and_neutralize_cancels_pending_tap():
	var pad:=Pad.new();pad.game=Game.new()
	TSW.button(pad,event(JOY_BUTTON_X));TSW.button(pad,event(JOY_BUTTON_X,false))
	var ok: bool=pad.game.hud.modal=="controller_actions"
	pad.game.hud.modal="";TSW.button(pad,event(JOY_BUTTON_X));pad.neutralize()
	TSW.button(pad,event(JOY_BUTTON_X,false))
	ok=ok and pad.game.hud.modal==""
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

func test_settings_refresh_does_not_erase_parent_and_pause_stays_paused():
	var pad:=Pad.new();pad.game=Game.new();pad.game.hud.modal="pause";pad.game.paused=true
	pad.remember_menu_entry("controllers");pad.game.hud.modal="controllers"
	pad.remember_menu_entry("controllers");pad.menu_back()
	var ok: bool=pad.game.hud.modal=="pause" and pad.game.paused
	pad.free();return ok
