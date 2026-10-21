extends RefCounted
const Picker:=preload("res://game/menu_picker_input.gd")

func test_picker_focus_skips_disabled_choices_without_committing_selection():
	var control:=OptionButton.new()
	for i in 12:control.add_item("Choice %d" % i)
	control.select(1);control.get_popup().set_focused_item(1);control.set_item_disabled(2,true)
	var pad:=Picker.new();pad.move(control,1)
	var ok:=control.get_popup().get_focused_item()==3 and control.selected==1
	pad.move(control,8);ok=ok and control.get_popup().get_focused_item()==11 and control.selected==1
	pad.move(control,8);ok=ok and control.get_popup().get_focused_item()==11
	control.free();return ok

func test_closed_picker_does_not_consume_gameplay_controller_input():
	var control:=OptionButton.new();control.add_item("Choice")
	var pad:=Picker.new();var event:=InputEventJoypadButton.new();event.button_index=JOY_BUTTON_A;event.pressed=true
	var ok:=not pad.handle(event,[control])
	control.free();return ok
