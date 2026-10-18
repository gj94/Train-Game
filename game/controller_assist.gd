extends PanelContainer
## A transient, non-interactive legend. Never pauses or touches railway state.
var heading: Label
var detail: RichTextLabel
var progress: ProgressBar

func _ready() -> void:
	mouse_filter=Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	offset_left=-300;offset_right=300;offset_top=-260;offset_bottom=-118
	var style:=StyleBoxFlat.new()
	style.bg_color=Color("102630f5");style.border_color=Color("6a929e")
	style.set_border_width_all(1);style.set_corner_radius_all(10);style.set_content_margin_all(16)
	add_theme_stylebox_override("panel",style)
	var column:=VBoxContainer.new();column.mouse_filter=Control.MOUSE_FILTER_IGNORE;add_child(column)
	heading=Label.new();heading.add_theme_font_size_override("font_size",21);column.add_child(heading)
	detail=RichTextLabel.new();detail.bbcode_enabled=true;detail.fit_content=true
	detail.scroll_active=false;detail.mouse_filter=Control.MOUSE_FILTER_IGNORE
	detail.add_theme_font_size_override("normal_font_size",18);detail.add_theme_font_size_override("bold_font_size",18)
	column.add_child(detail)
	progress=ProgressBar.new();progress.show_percentage=false;progress.custom_minimum_size.y=7
	progress.mouse_filter=Control.MOUSE_FILTER_IGNORE;column.add_child(progress)
	hide()

func update_pad(pad) -> void:
	if not pad.controller_mode or not pad._armed or pad.game.paused or pad._ui_open():hide();return
	if pad._operation_down and pad._operation_time>=.18:
		var locked: bool=pad.game._passenger_seated()
		heading.text="X HELD · TRAIN SHORTCUTS"
		detail.text="Passenger seat · AI drives. Stand with Y before using driving commands." if locked else (
			"[color=#8be39b][b]A[/b][/color]  "+("Take over driving" if pad.game.train.automatic else "Let AI drive")+
			"     [color=#ffda85][b]Y[/b][/color]  Horn\n[color=#ff9595][b]B[/b][/color]  "+("Release emergency" if pad.game.train.emergency else "Emergency brake")+"     [b]RB[/b]  Coast")
		if pad.game.walker.active:detail.text+="\n[b]D-pad Up[/b]  Headlamp"
		detail.text+="\nRelease X for the action menu · combinations still work"
		if pad._operation_used:detail.text=detail.text.replace("Release X for the action menu · combinations still work","Release controls to continue")
		progress.hide();show()
	elif pad._camera_down and preload("res://game/controller_camera_motion.gd").is_free(pad.game.cam):
		heading.text="HOLD RS · "+("USE TRIGGERS TO ZOOM" if pad._free_train_controls else "USE TRIGGERS TO DRIVE")
		detail.text="Release all controls after switching."
		progress.value=clampf(pad._camera_hold_time/.65,0,1)*100;progress.show();show()
	elif pad._view_down:
		heading.text="HOLD VIEW · JOURNEY PROGRESS"
		detail.text="Release early to open Dispatch."
		progress.value=clampf(pad._view_time/.55,0,1)*100;progress.show();show()
	else:hide()
