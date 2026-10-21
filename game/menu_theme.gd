extends RefCounted
## Shared presentation palette. No railway state or settings live here.
const INK := Color("0b1119")
const SURFACE := Color("141e2a")
const RAISED := Color("1d2b3a")
const LINE := Color("304153")
const TEXT := Color("edf1f5")
const MUTED := Color("9caebe")
const ACCENT := Color("82d8cd")
const GOLD := Color("e6bc7a")
const DANGER := Color("ef928b")

static func box(color: Color=SURFACE, padding: int=16, border: Color=LINE) -> StyleBoxFlat:
	var s:=StyleBoxFlat.new()
	s.bg_color=color;s.border_color=border;s.set_border_width_all(1)
	s.set_corner_radius_all(5);s.set_content_margin_all(padding)
	return s

static func focus() -> StyleBoxFlat:
	var s:=box(Color(0,0,0,0),0,ACCENT)
	s.set_border_width_all(2)
	return s

static func theme() -> Theme:
	var t:=Theme.new();t.default_font_size=16
	for kind in ["Label","Button","OptionButton","CheckButton","LineEdit","ItemList","PopupMenu","RichTextLabel"]:
		t.set_color("font_color",kind,TEXT)
		t.set_color("font_hover_color",kind,TEXT)
		t.set_color("font_focus_color",kind,TEXT)
		t.set_color("font_pressed_color",kind,TEXT)
		t.set_color("font_disabled_color",kind,Color("647587"))
	for kind in ["Button","OptionButton"]:
		t.set_stylebox("normal",kind,box(SURFACE,12))
		t.set_stylebox("hover",kind,box(RAISED,12,ACCENT.darkened(.3)))
		t.set_stylebox("pressed",kind,box(Color("253d48"),12,ACCENT))
		t.set_stylebox("disabled",kind,box(INK,12,Color("202d3a")))
		t.set_stylebox("focus",kind,focus())
	for kind in ["LineEdit","ItemList","PopupMenu"]:
		t.set_stylebox("normal" if kind=="LineEdit" else "panel",kind,box(INK,12))
		t.set_stylebox("focus",kind,focus())
	t.set_stylebox("selected","ItemList",box(RAISED,10,ACCENT))
	t.set_stylebox("selected_focus","ItemList",box(RAISED,10,ACCENT))
	t.set_stylebox("panel","PanelContainer",box())
	t.set_stylebox("panel","TabContainer",box(INK,10))
	for kind in ["TabBar","TabContainer"]:
		t.set_stylebox("tab_selected",kind,box(RAISED,12,ACCENT))
		t.set_stylebox("tab_unselected",kind,box(INK,12))
		t.set_color("font_selected_color",kind,TEXT)
		t.set_color("font_unselected_color",kind,MUTED)
	t.set_color("default_color","RichTextLabel",TEXT)
	t.set_color("font_placeholder_color","LineEdit",MUTED)
	return t

static func label(parent: Node, text: String, size: int=16, color: Color=TEXT) -> Label:
	var l:=Label.new();l.text=text;l.add_theme_font_size_override("font_size",size)
	l.add_theme_color_override("font_color",color);l.mouse_filter=Control.MOUSE_FILTER_IGNORE
	parent.add_child(l);return l

static func button(b: Button, height: float=44) -> void:
	b.custom_minimum_size.y=height;b.focus_mode=Control.FOCUS_ALL
	b.add_theme_font_size_override("font_size",16)
	b.add_theme_stylebox_override("focus",focus())

static func divider(parent: Node) -> void:
	var line:=HSeparator.new();line.modulate=LINE;parent.add_child(line)
