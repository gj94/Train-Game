extends Control
## Detached skip diagram: no live world access, asset streaming or dispatch commands.
const SPAN := 10000.0
const PAPER := Color("101e2b")
const RAIL := Color("526b7b")
const TEXT := Color("e7eff4")
const MINT := Color("76dfc2")
const AMBER := Color("ffd17a")
var layout := {}
var state := {}

func _ready() -> void:
	mouse_filter=Control.MOUSE_FILTER_IGNORE
	clip_contents=true
	custom_minimum_size=Vector2(0,210)
	size_flags_vertical=Control.SIZE_EXPAND_FILL
	resized.connect(queue_redraw)

func update_state(value: Dictionary) -> void:
	if value.is_empty():return
	if state.get("clock",-1)==value.get("clock",-2):return
	state=value;queue_redraw()

func _p(s: float,lateral: float) -> Vector2:
	return Vector2(24+(s-state.center.x+SPAN*.5)/SPAN*(size.x-48),size.y*.5+clampf(lateral-state.center.y,-90,90)*minf(3.0,(size.y-120)/180))

func _text(at: Vector2,value: String,color: Color=TEXT,font_size: int=13) -> void:
	draw_string(ThemeDB.fallback_font,at,value,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size,color)

func _edge_point(id: String,at: float) -> Vector2:
	var e: Dictionary=layout.edges[id]
	var f:=clampf(at/e.length,0,1)
	var lateral: float=lerpf(e.a.y,e.lane,f/.2) if f<.2 else (lerpf(e.lane,e.b.y,(f-.8)/.2) if f>.8 else e.lane)
	return _p(lerpf(e.a.x,e.b.x,f),lateral)

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO,size),PAPER)
	if state.is_empty() or layout.is_empty():
		_text(Vector2(24,40),"Preparing your live railway view…",RAIL,17);return
	var left: float=state.center.x-SPAN*.5;var right: float=state.center.x+SPAN*.5
	for km in range(floori(left/1000),ceili(right/1000)+1):
		var x:=_p(km*1000,0).x
		draw_line(Vector2(x,48),Vector2(x,size.y-32),Color("1c3040"))
		_text(Vector2(x+4,size.y-12),"%d km" % km,RAIL,12)
	for id in layout.edges:
		var e: Dictionary=layout.edges[id]
		if maxf(e.a.x,e.b.x)<left or minf(e.a.x,e.b.x)>right:continue
		var points:=PackedVector2Array()
		for f in [0.0,.2,.8,1.0]:points.append(_edge_point(id,e.length*f))
		draw_polyline(points,MINT.darkened(.25) if state.reserved.has(id) else RAIL,3.0,true)
	for st in layout.stations:
		if st.s<left or st.s>right:continue
		var x:=_p(st.s,0).x
		var width:=ThemeDB.fallback_font.get_string_size(st.name,HORIZONTAL_ALIGNMENT_LEFT,-1,16).x
		_text(Vector2(clampf(x-width*.5,12,maxf(12,size.x-width-12)),28),st.name,TEXT,16)
	for id in state.signals:
		var signal_info: Dictionary=layout.signals[id]
		var p:=_p(signal_info.p.x,signal_info.p.y)+Vector2(0,-13 if signal_info.direction>0 else 13)
		if p.x<12 or p.x>size.x-12:continue
		draw_circle(p,3.5,[Color("f46c72"),AMBER,MINT][state.signals[id]])
	var row:=0
	for t in state.trains:
		var own: bool=t.id==state.service
		for seg in t.segments:
			var a:=_edge_point(seg.edge,seg.from_s);var b:=_edge_point(seg.edge,seg.to_s)
			draw_line(a,b,TEXT if own else AMBER,11 if own else 8,true)
		var p:=_p(t.head.x,t.head.y)
		if p.x<12 or p.x>size.x-12:continue
		var label:="%s %s · %d km/h" % [t.id,"›" if t.direction>0 else "‹",roundi(t.speed*3.6)]
		if own:label="YOUR TRAIN · "+label
		var y: float=p.y-27 if own else p.y+28+float(row%2)*20
		var width:=ThemeDB.fallback_font.get_string_size(label,HORIZONTAL_ALIGNMENT_LEFT,-1,14).x
		var at:=Vector2(clampf(p.x-width*.5,12,maxf(12,size.x-width-12)),y)
		draw_rect(Rect2(at+Vector2(-4,-16),Vector2(width+8,22)),PAPER)
		_text(at,label,TEXT if own else AMBER,14);row+=1
	_text(Vector2(16,size.y-36),"FOLLOWING YOUR SERVICE   ·   10 km view   ·   train footprints / reserved routes / signals",RAIL,12)
