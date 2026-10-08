extends Control
## Interactive schematic; simulation coordinates stay independent of screen transforms.
signal signal_selected(id: String)
signal destination_selected(id: String)
signal train_selected(id: String)
signal station_selected(index: int)
signal view_changed
const Footprint := preload("res://sim/train_footprint.gd")
const PAPER := Color("#09131d")
const RAIL := Color("#577084")
const MINT := Color("#4be3bc")
const AMBER := Color("#ffbe69")
const RED := Color("#ff746e")
const TEXT := Color("#deebf3")
var world: RailWorld
var selected := ""
var destination := ""
var inspected_train := ""
var focus_index := -1
var center_s := 0.0
var span := 8000.0
var vertical_pan := 0.0
var full_start := 0.0
var full_end := 1.0
var follow_train := false
var _dragging := false
var _moved := false
var _press := Vector2.ZERO
var _hits: Array = []
var _focus_key := ""
var _timer := 0.0
var _edges := {}
var _mini := Rect2()
var last_footprints := {}
var show_blocks := true

func _ready() -> void:
	focus_mode=Control.FOCUS_ALL
	mouse_filter=Control.MOUSE_FILTER_STOP
	clip_contents=true
	size_flags_horizontal=Control.SIZE_EXPAND_FILL
	size_flags_vertical=Control.SIZE_EXPAND_FILL
	custom_minimum_size=Vector2(300,280)
	_index()
	if world.trains.has(inspected_train): focus_train(inspected_train)
	else: focus_station(0)
	focus_entered.connect(queue_redraw)
	focus_exited.connect(queue_redraw)

func _index() -> void:
	if world==null:return
	full_start=INF;full_end=-INF
	for id in world.graph.edges:
		var e: Dictionary=world.graph.edges[id]
		var a: Vector3=world.graph.position(id,0)
		var b: Vector3=world.graph.position(id,e.length)
		var start: float=e.get("chainage_start",a.x)
		var end: float=e.get("chainage_end",b.x)
		var lateral: float=e.get("lateral",(a.z+b.z)*.5)
		var la: float=world.graph.nodes[e.a].get("lateral",a.z)
		var lb: float=world.graph.nodes[e.b].get("lateral",b.z)
		_edges[id]={start=start,end=end,lateral=lateral,la=la,lb=lb}
		full_start=minf(full_start,minf(start,end));full_end=maxf(full_end,maxf(start,end))

func _s(edge: String,position_m: float) -> float:
	return lerpf(_edges[edge].start,_edges[edge].end,position_m/world.graph.edges[edge].length)

func _lateral_scale() -> float:
	return clampf(6.8*pow(6000.0/span,.13),1.5,10)

func _p(s: float,lateral: float=0) -> Vector2:
	return Vector2(size.x*.5+(s-center_s)*size.x/span,size.y*.48+lateral*_lateral_scale()+vertical_pan)

func _edge_p(edge: String,f: float) -> Vector2:
	var e: Dictionary=_edges[edge]
	var lateral: float=e.lateral
	if f<.2:lateral=lerpf(e.la,e.lateral,f/.2)
	elif f>.8:lateral=lerpf(e.lateral,e.lb,(f-.8)/.2)
	return _p(lerpf(e.start,e.end,f),lateral)

func _visible_edge(id: String) -> bool:
	var e: Dictionary=_edges[id]
	return maxf(e.start,e.end)>=center_s-span*.57 and minf(e.start,e.end)<=center_s+span*.57

func zoom_at(factor: float,anchor: Vector2=Vector2(-1,-1)) -> void:
	if anchor.x<0:anchor=size*.5
	var before: float=center_s+(anchor.x-size.x*.5)*span/maxf(1,size.x)
	span=clampf(span/factor,250,maxf(300,full_end-full_start)*1.08)
	center_s=before-(anchor.x-size.x*.5)*span/maxf(1,size.x)
	_clamp_view()
	follow_train=false
	queue_redraw();view_changed.emit()

func pan_pixels(offset: Vector2) -> void:
	center_s-=offset.x*span/maxf(1,size.x)
	vertical_pan+=offset.y
	var lo:=0.0;var hi:=0.0
	for id in _edges:
		if _visible_edge(id):lo=minf(lo,_edges[id].lateral);hi=maxf(hi,_edges[id].lateral)
	vertical_pan=clampf(vertical_pan,-size.y*.25-hi*_lateral_scale(),size.y*.25-lo*_lateral_scale())
	follow_train=false
	_clamp_view();queue_redraw();view_changed.emit()

func _clamp_view() -> void:
	center_s=clampf(center_s,full_start-span*.2,full_end+span*.2)

func focus_station(index: int) -> void:
	focus_index=index;vertical_pan=0;follow_train=false
	if index<0:
		center_s=(full_start+full_end)*.5;span=(full_end-full_start)*1.06
	elif index<world.stations.size():
		var st: Dictionary=world.stations[index]
		center_s=st.get("s",st.origin.x);span=3000
	queue_redraw();view_changed.emit()

func focus_train(id: String) -> void:
	if not world.trains.has(id):return
	inspected_train=id
	var t: Train=world.trains[id]
	center_s=_s(t.path[0].edge,t.head_s)-t.path[0].dir*t.length*.25
	span=maxf(2200,t.length*4);vertical_pan=-_edges[t.path[0].edge].lateral*_lateral_scale()
	_focus_key="train:"+id
	queue_redraw();view_changed.emit()

func focus_signal(id: String) -> void:
	if not world.signals.has(id):return
	var sig: Dictionary=world.signals[id]
	center_s=_s(sig.edge,sig.s);span=minf(span,3000);vertical_pan=-_edges[sig.edge].lateral*_lateral_scale()
	_focus_key="signal:"+id
	queue_redraw();view_changed.emit()

func _text(at: Vector2,value: String,color: Color=TEXT,font_size: int=13) -> void:
	draw_string(ThemeDB.fallback_font,at,value,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size,color)

func _line_segment(id: String,from_s: float,to_s: float,width: float,color: Color) -> PackedVector2Array:
	var length: float=world.graph.edges[id].length
	var lo:=minf(from_s,to_s)/length;var hi:=maxf(from_s,to_s)/length
	var points:=PackedVector2Array([_edge_p(id,lo)])
	for f in [.2,.8]:
		if f>lo and f<hi:points.append(_edge_p(id,f))
	points.append(_edge_p(id,hi))
	if points[0].distance_to(points[-1])>.01:draw_polyline(points,color,width,true)
	return points

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO,size),PAPER)
	if world==null or _edges.is_empty():return
	_hits.clear();last_footprints.clear()
	var tick: float=pow(10,floor(log(span/6)/log(10)))
	if span/tick>12:tick*=2
	for s in range(floori((center_s-span*.5)/tick),ceili((center_s+span*.5)/tick)+1):
		var p:=_p(s*tick)
		draw_line(Vector2(p.x,0),Vector2(p.x,size.y-56),Color("#152635"))
		_text(Vector2(p.x+5,size.y-67),"%.1f km" % ((s*tick-full_start)/1000),RAIL,11)
	var reserved:={}
	var preview:={}
	for sig in world.signals.values():
		for r in sig.route:reserved[r.edge]=sig
	if world.signals.has(selected):
		for option in world.route_options(selected):
			if option.destination==destination:
				for r in option.edges:preview[r.edge]=true
	var occupancy:=world.occupancy()
	for id in _edges:
		if not _visible_edge(id):continue
		var length: float=world.graph.edges[id].length
		if preview.has(id):_line_segment(id,0,length,13,Color("#445568"))
		if occupancy.has(id) and show_blocks:_line_segment(id,0,length,8,Color("#683b3e"))
		if reserved.has(id):_line_segment(id,0,length,5,MINT.darkened(.22))
		else:_line_segment(id,0,length,2.5,RAIL)
		if span<8500:
			var midpoint:=_edge_p(id,.5)
			if "_P" in id:
				var name: String=id
				var st:=_station_for_edge(id)
				if not st.is_empty():
					var detail: Dictionary=st.get("platform_details",{}).get(id,{})
					if detail.get("platform_width",1)>0:
						var ends:=preload("res://sim/berth_clearance.gd").platform_span(world,id)
						var a:=_edge_p(id,ends.x/length);var b:=_edge_p(id,ends.y/length)
						for side in detail.get("platform_sides",[detail.get("platform_side",-1)]):
							var rect:=Rect2(Vector2(minf(a.x,b.x),midpoint.y+float(side)*11-4),Vector2(absf(b.x-a.x),8))
							draw_rect(rect,Color("#233a4a"))
					name+=" · "+("Platform" if detail.get("platform_width",0)>0 else ("Storage" if detail.get("storage",false) else "Through"))
				_text(midpoint+Vector2(-30,-14),name,RAIL,11)
	for index in world.stations.size():
		var st: Dictionary=world.stations[index]
		var p:=_p(st.get("s",st.origin.x))
		if p.x<0 or p.x>size.x:continue
		if span>18000 and not st.get("major",true):continue
		if span>100000 and index%4!=0 and not st.code in ["ERS","ALLP","QLN","TVC","NCJ"]:continue
		var caption: String=st.get("display_code",st.code) if span>18000 else st.name
		var width: float=ThemeDB.fallback_font.get_string_size(caption,HORIZONTAL_ALIGNMENT_LEFT,-1,16).x
		var x:=clampf(p.x-width*.5,8,maxf(8,size.x-width-8))
		draw_line(Vector2(p.x,56),Vector2(p.x,size.y*.30),Color("#243949"))
		_text(Vector2(x,30),caption,AMBER if index==focus_index else TEXT,16)
		if span<18000:
			var faces:=preload("res://sim/platform_faces.gd").entries(st).size()
			var inventory: String="%s · %d platform%s · %d tracks" % [st.get("display_code",st.code),faces,"" if faces==1 else "s",st.get("platform_tracks",[]).size()]
			if not st.get("passenger_open",true):inventory+=" · closed"
			_text(Vector2(x,48),inventory,RAIL,11)
		_hits.append({key="station:"+str(index),kind="station",id=str(index),rect=Rect2(Vector2(x,7),Vector2(maxf(width,40),46)),p=Vector2(p.x,29)})
	if span<10000:
		for id in world.graph.switches:
			var node: Dictionary=world.graph.nodes[id]
			var p:=_p(node.get("chainage",node.pos.x),node.get("lateral",node.pos.z))
			if not Rect2(Vector2.ZERO,size).has_point(p):continue
			var locked: bool=world.switch_lock_reason(id)!=""
			var diamond:=PackedVector2Array([p+Vector2(-4,0),p+Vector2(0,-4),p+Vector2(4,0),p+Vector2(0,4)])
			draw_colored_polygon(diamond,AMBER if locked else RAIL)
			if span<1600:_text(p+Vector2(6,18),id,RAIL,10)
	for sid in world.signals:
		var sig: Dictionary=world.signals[sid]
		if not _visible_edge(sig.edge):continue
		if span>18000 and sid!=selected and sid!=destination:continue
		if span>7000 and sid in world.automatic_signals and sid!=selected:continue
		var p:=_edge_p(sig.edge,sig.s/world.graph.edges[sig.edge].length)
		var lamp:=p+Vector2(0,-22 if sig.dir>0 else 22)
		if not Rect2(Vector2(8,60),size-Vector2(16,128)).has_point(lamp):continue
		var color: Color=[RED,AMBER,MINT][world.aspect(sid)]
		draw_line(p,lamp,RAIL,1)
		draw_circle(lamp,5,color)
		draw_line(lamp+Vector2(sig.dir*8,-4),lamp+Vector2(sig.dir*12,0),color,2)
		draw_line(lamp+Vector2(sig.dir*8,4),lamp+Vector2(sig.dir*12,0),color,2)
		if sid==selected or sid==destination:draw_arc(lamp,10,0,TAU,24,TEXT,2,true)
		if span<4000 or sid==selected:
			var caption: String=sid.get_slice("-",1) if "_P" in sig.edge else sid
			_text(lamp+Vector2(17 if sig.dir>0 else -62,4),caption,color,11)
		_hits.append({key="signal:"+sid,kind="signal",id=sid,rect=Rect2(lamp-Vector2(12,12),Vector2(24,24)),p=lamp})
	for id in world.graph.nodes:
		var node: Dictionary=world.graph.nodes[id]
		if node.edges.size()!=1:continue
		var p:=_p(node.get("chainage",node.pos.x),node.get("lateral",node.pos.z))
		if not Rect2(Vector2(8,60),size-Vector2(16,128)).has_point(p):continue
		draw_line(p-Vector2(0,8),p+Vector2(0,8),TEXT,3)
		var target: String="BUFFER:"+id
		_hits.append({key=target,kind="destination",id=target,rect=Rect2(p-Vector2(12,12),Vector2(24,24)),p=p})
	for t: Train in world.trains.values():
		var intervals:=Footprint.intervals(world.graph,t)
		last_footprints[t.id]=intervals
		var highlighted: bool=t.id==inspected_train
		for interval in intervals:
			if not _visible_edge(interval.edge):continue
			_line_segment(interval.edge,interval.from_s,interval.to_s,15 if highlighted else 11,TEXT if highlighted else AMBER.darkened(.3))
			var points:=_line_segment(interval.edge,interval.from_s,interval.to_s,9,AMBER)
			var box:=Rect2(points[0],Vector2.ZERO)
			for p in points:box=box.expand(p)
			_hits.append({key="train:"+t.id,kind="train",id=t.id,rect=box.grow(8),p=box.get_center()})
			if span<3500:
				var lo:=minf(interval.from_s,interval.to_s);var hi:=maxf(interval.from_s,interval.to_s)
				for s in range(ceili(lo/24)*24,int(hi),24):
					var p:=_edge_p(interval.edge,float(s)/world.graph.edges[interval.edge].length)
					draw_line(p+Vector2(0,-4),p+Vector2(0,4),PAPER,1.5)
		var head:=_edge_p(t.path[0].edge,t.head_s/world.graph.edges[t.path[0].edge].length)
		if head.x<0 or head.x>size.x:continue
		var label_pos:=head+Vector2(-33,-48 if t.path[0].dir>0 else 46)
		var rect:=Rect2(label_pos,Vector2(74,25))
		draw_style_box(_tag_style(highlighted),rect)
		_text(label_pos+Vector2(9,17),t.id+("  ›" if t.path[0].dir>0 else "  ‹"),TEXT,14)
		_hits.append({key="train:"+t.id,kind="train",id=t.id,rect=rect,p=rect.get_center()})
		if span<3000:_text(label_pos+Vector2(0,41),"%d m · %d km/h" % [roundi(t.length),roundi(t.speed*3.6)],AMBER,11)
	_draw_minimap()
	if has_focus():
		draw_rect(Rect2(Vector2(1,1),size-Vector2(2,2)),MINT,false,2)
		for hit in _hits:
			if hit.key==_focus_key:draw_rect(hit.rect.grow(3),MINT,false,2)
	_text(Vector2(12,size.y-7),"%.2f km visible  ·  occupied train = amber  /  locked route = mint" % (span/1000),RAIL,11)

func _tag_style(active: bool) -> StyleBoxFlat:
	var style:=StyleBoxFlat.new()
	style.bg_color=Color("#345164") if active else Color("#182e40")
	style.border_color=AMBER
	style.set_border_width_all(1);style.set_corner_radius_all(4)
	return style

func _station_for_edge(id: String) -> Dictionary:
	for st in world.stations:
		if id in st.get("platform_tracks",[]):return st
	return {}

func _draw_minimap() -> void:
	_mini=Rect2(Vector2(16,size.y-48),Vector2(size.x-32,23))
	draw_rect(_mini,Color("#132636"))
	var total:=maxf(1,full_end-full_start)
	var view:=Rect2(Vector2(_mini.position.x+(center_s-span*.5-full_start)/total*_mini.size.x,_mini.position.y),Vector2(span/total*_mini.size.x,_mini.size.y))
	draw_rect(view.intersection(_mini),Color("#294a60"))
	draw_rect(view.intersection(_mini),MINT,false,1)
	for t: Train in world.trains.values():
		var x:=_mini.position.x+(_s(t.path[0].edge,t.head_s)-full_start)/total*_mini.size.x
		draw_line(Vector2(x,_mini.position.y+5),Vector2(x,_mini.end.y-5),AMBER,2)

func select_at(pos: Vector2) -> void:
	for hit in _hits:
		if hit.rect.has_point(pos):
			_focus_key=hit.key;_activate(hit);return

func _activate(hit: Dictionary) -> void:
	match hit.kind:
		"train": train_selected.emit(hit.id)
		"signal": signal_selected.emit(hit.id)
		"station": station_selected.emit(int(hit.id))
		"destination": destination_selected.emit(hit.id)
	queue_redraw()

func activate_focus() -> void:
	for hit in _hits:
		if hit.key==_focus_key:_activate(hit);return
	if not _hits.is_empty():_focus_key=_hits[0].key;_activate(_hits[0])

func navigate_target(direction: Vector2) -> void:
	var origin:=size*.5
	for hit in _hits:
		if hit.key==_focus_key:origin=hit.p;break
	var best:={};var score:=INF
	for hit in _hits:
		if hit.key==_focus_key:continue
		var delta: Vector2=hit.p-origin
		var forward:=delta.dot(direction)
		if forward<1:continue
		var value:=delta.length()+absf(delta.cross(direction))*2
		if value<score:best=hit;score=value
	if not best.is_empty():_focus_key=best.key
	queue_redraw()

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.pressed and event.button_index in [MOUSE_BUTTON_WHEEL_UP,MOUSE_BUTTON_WHEEL_DOWN]:
			zoom_at(1.3 if event.button_index==MOUSE_BUTTON_WHEEL_UP else 1.0/1.3,event.position);accept_event()
		elif event.button_index in [MOUSE_BUTTON_LEFT,MOUSE_BUTTON_MIDDLE,MOUSE_BUTTON_RIGHT]:
			grab_focus()
			if event.pressed:
				_dragging=true;_moved=false;_press=event.position
				if _mini.has_point(event.position):
					center_s=lerpf(full_start,full_end,(event.position.x-_mini.position.x)/_mini.size.x);queue_redraw();_moved=true
			else:
				if _dragging and not _moved and event.button_index==MOUSE_BUTTON_LEFT:select_at(event.position)
				_dragging=false
			accept_event()
	elif event is InputEventMouseMotion:
		if _dragging:
			if event.position.distance_to(_press)>4:_moved=true
			if _moved:pan_pixels(event.relative)
			accept_event()
		else:
			tooltip_text=""
			for hit in _hits:
				if hit.rect.has_point(event.position):
					tooltip_text=hit.id+" · inspect / actions" if hit.kind=="train" else hit.id
					break
	elif event is InputEventKey and event.pressed:
		match event.physical_keycode:
			KEY_LEFT:pan_pixels(Vector2(100,0));accept_event()
			KEY_RIGHT:pan_pixels(Vector2(-100,0));accept_event()
			KEY_UP:pan_pixels(Vector2(0,50));accept_event()
			KEY_DOWN:pan_pixels(Vector2(0,-50));accept_event()
			KEY_EQUAL,KEY_KP_ADD:zoom_at(1.3);accept_event()
			KEY_MINUS,KEY_KP_SUBTRACT:zoom_at(1.0/1.3);accept_event()
			KEY_HOME:focus_station(-1);accept_event()
			KEY_ENTER:activate_focus();accept_event()
	elif event.is_action_pressed("ui_accept"):activate_focus();accept_event()

func _process(delta: float) -> void:
	if not is_visible_in_tree():return
	_timer+=delta
	if _timer<.1:return
	_timer=0
	if follow_train and world.trains.has(inspected_train):
		var t: Train=world.trains[inspected_train]
		center_s=_s(t.path[0].edge,t.head_s)-t.path[0].dir*t.length*.25
	queue_redraw()
