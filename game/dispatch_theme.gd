extends RefCounted
const TEXT := Color("#e0eaf3")
const MUTED := Color("#849bae")
const MINT := Color("#4be3bc")
const AMBER := Color("#ffbe69")

static func panel(color: String="#111f2d",padding: int=14) -> StyleBoxFlat:
	var s:=StyleBoxFlat.new()
	s.bg_color=Color(color);s.border_color=Color("#294052")
	s.set_border_width_all(1);s.set_corner_radius_all(8);s.set_content_margin_all(padding)
	return s

static func label(parent: Node,text: String,font_size: int=14,color: Color=TEXT) -> Label:
	var l:=Label.new()
	l.text=text;l.add_theme_font_size_override("font_size",font_size)
	l.add_theme_color_override("font_color",color);parent.add_child(l)
	return l

static func button(parent: Node,text: String,action: Callable) -> Button:
	var b:=Button.new()
	b.text=text;style_button(b);parent.add_child(b);b.pressed.connect(action)
	return b

static func style_button(b: Button) -> void:
	b.focus_mode=Control.FOCUS_ALL
	b.custom_minimum_size.y=36
	b.add_theme_font_size_override("font_size",14)
	b.add_theme_color_override("font_color",TEXT)
	b.add_theme_color_override("font_disabled_color",Color("#667c8c"))
	for state in ["normal","hover","pressed","focus","disabled"]:
		var s:=panel("#263f52" if state in ["hover","pressed"] else "#182c3c",9)
		if state=="focus":s.border_color=MINT;s.set_border_width_all(2);s.bg_color=Color(0,0,0,0)
		if state=="disabled":s.bg_color=Color("#12202c")
		b.add_theme_stylebox_override(state,s)
	b.size_flags_horizontal=Control.SIZE_EXPAND_FILL

static func section(parent: Node,title: String) -> VBoxContainer:
	var p:=PanelContainer.new();p.add_theme_stylebox_override("panel",panel());parent.add_child(p)
	var v:=VBoxContainer.new();v.add_theme_constant_override("separation",10);p.add_child(v)
	if not title.is_empty():label(v,title,12,MUTED)
	return v

static func wrap(parent: Node,text: String,font_size: int=14,color: Color=TEXT) -> Label:
	var l:=label(parent,text,font_size,color)
	l.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	l.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	return l
