extends RefCounted
## Explicit controller support for native OptionButton popup windows. Keyboard
## and mouse retain their normal engine behavior; B cancels without committing.
var direction:=0
var delay:=0.0
var held_picker: OptionButton

static func use_explicit_controller_navigation() -> void:
	# Match the in-journey controller router: native ui_* pad bindings must not
	# also move/activate a control after the page has handled that same press.
	# Preserve every keyboard/mouse binding.
	for action in InputMap.get_actions():
		if not str(action).begins_with("ui_"):continue
		for event in InputMap.action_get_events(action):
			if event is InputEventJoypadButton or event is InputEventJoypadMotion:InputMap.action_erase_event(action,event)

func connect_pickers(pickers: Array) -> void:
	for picker: OptionButton in pickers:
		var popup:=picker.get_popup()
		popup.window_input.connect(_native_input.bind(pickers,popup))
		popup.about_to_popup.connect(_opened.bind(picker))

func _opened(picker: OptionButton) -> void:
	reset();held_picker=picker
	picker.get_popup().set_focused_item(picker.selected)

func _native_input(event: InputEvent,pickers: Array,popup: PopupMenu) -> void:
	if not (event is InputEventJoypadButton or event is InputEventJoypadMotion):return
	# A native popup is a separate Viewport; its events do not reach the page's
	# _input. Consume before handling so native ui_accept cannot also activate it.
	popup.set_input_as_handled()
	handle(event,pickers)

func active(pickers: Array) -> OptionButton:
	for picker in pickers:
		if picker.get_popup().visible:return picker
	return null

func reset() -> void:
	direction=0;delay=0;held_picker=null

func handle(event: InputEvent,pickers: Array) -> bool:
	var picker:=active(pickers)
	if picker==null:reset();return false
	if held_picker!=picker:reset();held_picker=picker
	if event is InputEventJoypadMotion:
		if event.axis==JOY_AXIS_LEFT_Y:
			var next:=int(signf(event.axis_value)) if absf(event.axis_value)>.55 else 0
			if next!=direction:
				direction=next;delay=.35
				if direction!=0:move(picker,direction)
		return true
	if not event is InputEventJoypadButton:return false
	if not event.pressed:return true
	match event.button_index:
		JOY_BUTTON_B:picker.get_popup().hide();picker.grab_focus();reset()
		JOY_BUTTON_A:
			var index:=picker.get_popup().get_focused_item()
			if index<0:index=picker.selected
			if index>=0 and not picker.is_item_disabled(index):
				picker.select(index);picker.get_popup().hide();picker.grab_focus();reset();picker.item_selected.emit(index)
		JOY_BUTTON_DPAD_UP:move(picker,-1)
		JOY_BUTTON_DPAD_DOWN:move(picker,1)
		JOY_BUTTON_LEFT_SHOULDER:move(picker,-8)
		JOY_BUTTON_RIGHT_SHOULDER:move(picker,8)
	return true

func update(delta: float,pickers: Array) -> bool:
	var picker:=active(pickers)
	if picker==null:reset();return false
	if held_picker!=picker:reset();held_picker=picker
	if direction!=0:
		delay-=delta
		if delay<=0:move(picker,direction);delay=.13
	return true

func move(picker: OptionButton,step: int) -> void:
	if picker.item_count==0:return
	var current:=picker.get_popup().get_focused_item()
	if current<0:current=picker.selected
	var target:=clampi(current+step,0,picker.item_count-1)
	while picker.is_item_disabled(target):
		var next:=target+signi(step)
		if next<0 or next>=picker.item_count:return
		target=next
	picker.get_popup().set_focused_item(target)
