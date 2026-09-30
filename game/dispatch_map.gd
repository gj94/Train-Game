extends Control
## Topology-driven panel. Every road, signal, turnout and train comes from the sim.
signal signal_selected(id: String)
signal destination_selected(id: String)
signal train_selected(id: String)
var world: RailWorld
var selected := ""
var destination := ""
var focus_index := -1
var _hits := {}
var _train_hits := {}
const INK := Color("789098")
const TEAL := Color("52dcc4")
const GOLD := Color("ffca72")
const RED := Color("ff7868")

func _ready() -> void:
	custom_minimum_size = Vector2(0, 310)
	clip_contents = true
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

func focus_station(index: int) -> void:
	focus_index = index
	queue_redraw()

func _chainage_x(x: float) -> float:
	if not world.scenery.get("corridor", false):
		return 45 + x / 4890.0 * 1410
	var knots := [180.0, 2100.0, 10440.0, 11560.0, 19900.0, 21820.0]
	var mapped := [45.0, 390.0, 555.0, 915.0, 1080.0, 1455.0]
	for i in range(1, knots.size()):
		if x <= knots[i]:
			return lerpf(mapped[i-1],mapped[i],(x-knots[i-1])/(knots[i]-knots[i-1]))
	return mapped[-1]

func _project(p: Vector3, edge: String = "") -> Vector2:
	var px := _chainage_x(p.x)
	var py := p.z
	if edge != "" and world.graph.edges[edge].allowed_dir != 0:
		py = -3.0 if world.graph.edges[edge].allowed_dir > 0 else 3.0
	var lo := 0.0
	var span := 1500.0
	if focus_index >= 0:
		var cx: float = world.stations[focus_index].origin.x
		lo = _chainage_x(cx - 1750) - 30
		span = _chainage_x(cx + 1750) - lo + 30
	return Vector2((px-lo)/span*size.x, 158 + clampf(py, -25, 25)*4.0)

func _point(edge: String, fraction: float) -> Vector2:
	return _project(world.graph.position(edge,world.graph.edges[edge].length*fraction),edge)

func _text(pos: Vector2, content: String, color: Color, font_size: int = 12) -> void:
	draw_string(ThemeDB.fallback_font,pos,content,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size,color)

func _draw() -> void:
	if world == null:
		return
	_hits.clear()
	_train_hits.clear()
	var occ := world.occupancy()
	var reserved := {}
	var preview := {}
	for sig in world.signals.values():
		for r in sig.route:
			reserved[r.edge] = true
	if world.signals.has(selected):
		for option in world.route_options(selected):
			if option.destination == destination:
				for r in option.edges:
					preview[r.edge] = true
	for st in world.stations:
		var p := _project(st.origin)
		_text(Vector2(p.x-65,22), st.code + " / " + st.name.to_upper(),GOLD,14)
		_text(Vector2(p.x-60,40),"%.1f km · %d platform roads"%[st.origin.x/1000.0,st.get("platform_tracks",st.platforms).size()],INK,11)
		for i in st.platforms.size():
			var r: Rect2 = st.platforms[i]
			var a := _project(Vector3(r.position.x,0,r.position.y))
			var b := _project(Vector3(r.end.x,0,r.end.y))
			draw_rect(Rect2(a, b-a),Color("162e39"))
			if st.has("platform_numbers"):
				for j in 2:
					_text(Vector2((a.x+b.x)/2-22,a.y+10 if j == 0 else b.y-3),"P%d · 600 m"%st.platform_numbers[i][j],INK,10)
	for eid in world.graph.edges:
		var pts := PackedVector2Array()
		for p in world.graph.edges[eid].points:
			pts.append(_project(p,eid))
		draw_polyline(pts,Color("203a46"),8,true)
		if preview.has(eid):
			draw_polyline(pts,Color("dbeff4"),7,true)
		draw_polyline(pts,RED if occ.has(eid) else (TEAL if reserved.has(eid) else INK),3,true)
		var e: Dictionary = world.graph.edges[eid]
		if e.allowed_dir != 0:
			var p := _point(eid,.5)
			_text(p+Vector2(-10,-5),">>" if e.allowed_dir>0 else "<<",INK,11)
	for nid in world.graph.switches:
		var p := _project(world.graph.nodes[nid].pos)
		draw_circle(p,3.8,GOLD if world.switch_lock_reason(nid) != "" else INK)
	for sid in world.signals:
		var sig: Dictionary = world.signals[sid]
		var p := _project(world.graph.position(sig.edge,sig.s),sig.edge)
		var lamp := p + Vector2(0,-13 if sig.dir > 0 else 13)
		var color: Color = [RED,GOLD,TEAL][world.aspect(sid)]
		draw_line(p,lamp,INK,1)
		draw_circle(lamp,4.5,color)
		draw_line(lamp+Vector2(sig.dir*7,-3),lamp+Vector2(sig.dir*11,0),color,1.5)
		draw_line(lamp+Vector2(sig.dir*7,3),lamp+Vector2(sig.dir*11,0),color,1.5)
		if sid == selected or sid == destination:
			draw_arc(lamp,9,0,TAU,24,Color.WHITE if sid == selected else TEAL,1.5,true)
		if not sid in world.automatic_signals or focus_index >= 0 or sid == selected:
			_text(lamp+Vector2(-20,-8 if sig.dir>0 else 19),sid,Color("d5e2e5"),10)
		_hits[sid] = Rect2(lamp-Vector2(9,9),Vector2(18,18))
	for nid in world.graph.nodes:
		if world.graph.nodes[nid].edges.size() != 1:
			continue
		var p := _project(world.graph.nodes[nid].pos)
		draw_line(p+Vector2(0,-6),p+Vector2(0,6),GOLD,3)
		_hits["BUFFER:"+nid] = Rect2(p-Vector2(9,9),Vector2(18,18))
	for t in world.trains.values():
		var e: String = t.path[0].edge
		var p := _project(world.graph.position(e,t.head_s),e)
		var r := Rect2(p+Vector2(-35 if t.path[0].dir>0 else 3,-6),Vector2(32,13))
		draw_rect(r,GOLD)
		_text(r.position+Vector2(3,10),t.id+(">" if t.path[0].dir>0 else "<"),Color("10252d"),10)
		_train_hits[t.id] = r
	_text(Vector2(6,296),"Click a signal, then its exit · white = proposed route · amber points = locked · arrows = running direction",INK,11)

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		tooltip_text = ""
		for id in _hits:
			if _hits[id].has_point(event.position):
				tooltip_text = id
				if world.signals.has(id):
					var s: Dictionary = world.signals[id]
					tooltip_text += " · "+["RED","YELLOW","GREEN"][world.aspect(id)]+(" · automatic block" if id in world.automatic_signals else " · controlled")
					if s.destination != "": tooltip_text += "\nTo "+s.destination
				break
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		for id in _train_hits:
			if _train_hits[id].has_point(event.position):
				train_selected.emit(id)
				accept_event()
				return
		for id in _hits:
			if _hits[id].has_point(event.position):
				if id.begins_with("BUFFER:"): destination_selected.emit(id)
				else: signal_selected.emit(id)
				accept_event()
				return
