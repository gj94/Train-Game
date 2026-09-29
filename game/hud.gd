extends CanvasLayer
## Driver/dispatcher HUD, built in code.
const Clock := preload("res://sim/world_clock.gd")

const HELP := """[b]Driving[/b] (works in both views)
W / ↑   more power      S / ↓   less power / more brake
X   coast (handle to 0)     Space   emergency brake (again at a stand: release)
C   open next signal's route desk     R   change ends (stopped)     H   horn

[b]View[/b]
Tab   cab ⇄ overview      F   follow train      1 / 2 / 3   jump to station
Overview: right-drag orbit · left-drag pan · wheel zoom
Cab: right-drag to look around · wheel zoom
F2   switch between WAP-7 light engine and MEMU meet (restarts scenario)

[b]Dispatching[/b] (overview)
Choose entrance + exit, then SET ROUTE · PUT TO RED cancels safely
D   dispatch board · A   selected train AI/manual · select a service to follow
M   timetable: blocks, minutes from origin, planned/actual times and dwell
Tab takes manual control of the selected train. A hands it back to AI.

T   time ×1 / ×2 / ×4      Esc   pause      P   protection on/off      F1   help
[ / ]   track sound quieter / louder (2 dB steps)      J   rail-joint markers (flash red on each hit)
, / .   clang (2nd wheel of each bogie) quieter / louder than the cling (1st wheel)"""

var _info: RichTextLabel
var _speed: Label
var _mode: Label
var _toast: Label
var _log: RichTextLabel
var _help: RichTextLabel
var _toast_time := 0.0
var _log_lines: Array = []


func _ready() -> void:
	_info = _rich(Vector2(16, 16), Vector2(430, 0), 18)
	_mode = _label(Vector2(0, 14), 17)
	_mode.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	_mode.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_mode.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_toast = _label(Vector2(0, 52), 16)
	_toast.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	_toast.offset_top = 52
	_toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_toast.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_toast.add_theme_color_override("font_color", Color(1.0, 0.85, 0.4))
	_speed = _label(Vector2.ZERO, 54)
	_speed.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	_speed.offset_top = -86
	_speed.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_speed.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_log = _rich(Vector2(16, 0), Vector2(560, 150), 16)
	_log.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	_log.offset_top = 240
	_log.offset_bottom = 370
	_log.set_anchor(SIDE_TOP, 0)
	_log.set_anchor(SIDE_BOTTOM, 0)
	_log.offset_right = 576
	_help = _rich(Vector2.ZERO, Vector2(640, 0), 16)
	_help.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	_help.offset_left = -656
	_help.offset_right = -16
	_help.offset_bottom = -16
	_help.grow_vertical = Control.GROW_DIRECTION_BEGIN   # fit_content grows it upward
	_help.text = HELP
	_help.visible = false
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0.025, 0.062, 0.086, 0.90)
	bg.set_content_margin_all(10)
	bg.set_corner_radius_all(6)
	for c in [_info, _help]:
		c.add_theme_stylebox_override("normal", bg)


func _label(pos: Vector2, size: int) -> Label:
	var l := Label.new()
	l.position = pos
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_constant_override("outline_size", 6)
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
	add_child(l)
	return l


func _rich(pos: Vector2, size: Vector2, font: int) -> RichTextLabel:
	var r := RichTextLabel.new()
	r.bbcode_enabled = true
	r.position = pos
	r.size = size
	r.fit_content = true
	r.scroll_active = false
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	r.add_theme_font_size_override("normal_font_size", font)
	r.add_theme_font_size_override("bold_font_size", font)
	r.add_theme_constant_override("outline_size", 5)
	r.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
	add_child(r)
	return r


func toggle_help() -> void:
	_help.visible = not _help.visible


func toast(text: String) -> void:
	_toast.text = text
	_toast_time = 3.5


func log_event(e: Dictionary) -> void:
	var color := "ff6655" if e.kind == "spad" else "ffcc55"
	var stamp := Clock.format_time(e.get("clock", e.t))
	_log_lines.append("[color=#aaaaaa]%s[/color]  [color=#%s]%s[/color]" % [stamp, color, e.text])
	if _log_lines.size() > 6:
		_log_lines.pop_front()
	_log.text = "\n".join(_log_lines)


func _process(delta: float) -> void:
	if _toast_time > 0.0:
		_toast_time -= delta
		_toast.modulate.a = clampf(_toast_time, 0.0, 1.0)


## `s` is a snapshot dictionary assembled by main.gd.
func refresh(s: Dictionary) -> void:
	var kmh := roundi(s.speed * 3.6)
	var lim := roundi(s.limit * 3.6)
	var over: bool = s.speed > s.limit + 3.0 / 3.6
	_speed.text = "%d km/h" % kmh
	_speed.visible = false
	_speed.add_theme_color_override("font_color", Color(1, 0.35, 0.3) if over else Color.WHITE)
	_mode.text = ("CAB · %s" if s.cab else "DISPATCH · %s") % s.train_id + "   D%d %s   ×%d" % [s.world_day, s.world_clock, s.time_scale] + ("   PAUSED" if s.paused else "")

	var handle := "Coast"
	if s.emergency:
		handle = "[color=#ff5544][b]EMERGENCY BRAKE[/b][/color]"
	elif s.controller > 0.001:
		handle = "[color=#88ff88]Power %d%%[/color]" % roundi(s.controller * 100)
	elif s.controller < -0.001:
		handle = "[color=#ffaa55]Brake %d%%[/color]" % roundi(-s.controller * 100)
	var lines := []
	var stock := "WAP-7 30306 · CAB %d" % s.cab_end if s.get("stock_kind", "memu") == "wap7" else "%d-CAR MEMU" % s.cars
	lines.append("[color=#ffca72][b]%s  /  %s[/b][/color]   %s" % [s.train_id, stock, "AI DRIVER" if s.automatic else "MANUAL"])
	lines.append("Speed [b]%d[/b] km/h   Limit %d km/h%s" % [kmh, lim, "  [color=#ff5544]OVERSPEED[/color]" if over else ""])
	lines.append("Handle  " + handle)
	if s.next_signal.is_empty():
		lines.append("Next signal  —")
	else:
		var names := ["[color=#ff4433]RED[/color]", "[color=#ffcc22]YELLOW[/color]", "[color=#44ff66]GREEN[/color]"]
		lines.append("Next signal  [b]%s[/b]  %s  in %d m" % [s.next_signal.id, names[s.next_aspect], roundi(s.next_signal.distance)])
	if s.buffer < 500.0:
		lines.append("Buffer stop in %d m" % roundi(s.buffer))
	lines.append("Protection %s    [color=#94aeb8]F1 controls · D dispatch[/color]" % ("on" if s.protection else "[color=#ffaa55]off[/color]"))
	_info.text = "\n".join(lines)
