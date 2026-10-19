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
	var elapsed:=0.0
	if pad._operation_down:
		heading.text="HOLD X · TAKE CONTROL"
		detail.text="Release early to let AI drive." if not pad._operation_used else "Return to the pilot seat before taking control."
		elapsed=pad._operation_time
	elif pad._dpad_button!=-1:
		var horizontal: bool=pad._dpad_button in [JOY_BUTTON_DPAD_LEFT,JOY_BUTTON_DPAD_RIGHT]
		heading.text="HOLD · "+("RETURN TO PILOT" if horizontal else "RETURN TO LOCO STANDING")
		detail.text="Release early to "+("change view." if horizontal else "move one carriage.")
		elapsed=pad._dpad_time
	elif pad._view_down:
		heading.text="HOLD VIEW · JOURNEY PROGRESS"
		detail.text="Release early to open Dispatch."
		elapsed=pad._view_time
	else:hide();return
	progress.value=clampf(elapsed/.65,0,1)*100;progress.show();show()
